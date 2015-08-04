USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GenerateZeroPOSExceptionData]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--Zero POS exception Report
CREATE procedure [dbo].[usp_GenerateZeroPOSExceptionData]
as
Begin
	--Drop the temp tables at the begining
	begin try
		Drop Table #tmpNoFeedData   
		Drop Table #tmpDates 
	end try
	begin catch
	end catch
	
	DECLARE @StartDate datetime,  @EndDate datetime
    
    SELECT @StartDate=GETDATE()-3, --Set Days to look for POS data
           @EndDate=GETDATE()-1
           
	SELECT DISTINCT
				   SP.SupplierId, C.ChainID, S.StoreID, SP.SupplierName as [Supplier Name], C.ChainName as [Chain Name], S.Custom2 as [SBT Number], 
				   S.StoreIdentifier as [Store Number],P.ProductID,
					S.Custom1 AS Banner,  P.ProductName,  PD.IdentifierValue AS UPC, 
					PP.UnitPrice as [Default Cost], PP1.UnitPrice as [Allowance],
					convert(date, PP1.ActiveStartDate, 101)  as [Promo Start Date], 
					convert(date, PP1.ActiveLastDate, 101) as [Promo End Date],
					SUV.supplieraccountnumber as [Supplier Acct Number], 
					SUV.DriverName as [Driver Name],  SUV.RouteNumber as [Route Number]
	Into #tmpNoFeedData                
	FROM   Suppliers SP
	INNER JOIN      StoreSetup SS ON  SP.SupplierID =  SS.SupplierID 
	INNER JOIN      Stores S ON  SS.StoreID =  S.StoreID and S.ActiveStatus='Active' 
	INNER JOIN      Chains C ON  C.ChainID=  S.ChainID
	INNER JOIN      Products P ON  SS.ProductID =  P.ProductID 
	Inner join      SupplierBanners SB on SB.SupplierId = SS.SupplierId and SB.Status='Active' and SB.Banner=S.Custom1
	INNER JOIN      ProductIdentifiers PD ON  SS.ProductID =  PD.ProductID and PD.ProductIdentifierTypeID=2
	Left Join ProductPrices PP on PP.SupplierID=SP.SupplierID and PP.ChainID=C.ChainID and PP.StoreID=S.StoreID and PP.ProductID=P.ProductID and PP.ProductPriceTypeID=3 
	and @StartDate between  PP.ActiveStartDate and PP.ActiveLastDate and @EndDate between  PP.ActiveStartDate and PP.ActiveLastDate
	Left Join ProductPrices PP1 on PP1.SupplierID=SP.SupplierID and PP1.ChainID=C.ChainID and PP1.StoreID=S.StoreID and PP1.ProductID=P.ProductID and PP1.ProductPriceTypeID=8 
	and @StartDate between  PP1.ActiveStartDate and PP1.ActiveLastDate and @EndDate between  PP1.ActiveStartDate and PP1.ActiveLastDate
	LEFT OUTER JOIN StoresUniqueValues SUV ON  SS.SupplierID =  SUV.SupplierID AND  SS.StoreID= SUV.StoreID

	WHERE   SS.ActiveLastDate>=GETDATE() --and SP.SupplierID=40557 and C.ChainID=40393 --165128

    ;with alldates as
	(
		select @StartDate DateVal
		union all
		select DateVal + 1 from alldates where DateVal + 1 <= @EndDate
	 )	

	select convert(varchar(10), DateVal, 101) as ForDate into #tmpDates from alldates

	OPTION (MAXRECURSION 0)

	--Truncate table [tmpZeroPOSException]
	
	Delete from DataTrue_CustomResultSets.dbo.tmpZeroPOSException where [Transaction Date]>=@StartDate
	
	Declare @ForDate date
	DECLARE date_cursor CURSOR FOR 
	
	select ForDate from #tmpDates		
	OPEN date_cursor;
		FETCH NEXT FROM date_cursor INTO @ForDate
			while @@FETCH_STATUS = 0
			begin
				Insert into DataTrue_CustomResultSets.dbo.tmpZeroPOSException
				SELECT  T.*, @ForDate as [Transaction Date], isnull(S.Qty,0) as SaleUnits
				from #tmpNoFeedData T 
					Left Join  DataTrue_Report.dbo.StoreTransactions S on S.SupplierID=T.SupplierID and S.ChainID=T.ChainID and S.StoreID=T.StoreID and S.ProductID=T.ProductID 
					and S.SaleDateTime=@ForDate
					Left Join TransactionTypes TT on TT.TransactionTypeID=S.TransactionTypeID and BucketType=1
				where isnull(S.Qty,0)=0 and @ForDate between T.[Promo Start Date] and T.[Promo End Date]
				FETCH NEXT FROM date_cursor INTO  @ForDate
			end
	CLOSE date_cursor;
	DEALLOCATE date_cursor;
    
End
GO
