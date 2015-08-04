USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Generate_No_Store_Feed_Data]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--No Feed Data
CREATE  procedure [dbo].[usp_Generate_No_Store_Feed_Data]
as
Begin
	--Drop the temp tables at the begining
	begin try
		Drop Table   #tmpNoFeedData   
		Drop Table #tmpDates 
	end try
	begin catch
	end catch
	
	DECLARE @StartDate datetime,  @EndDate datetime, @ChainId varchar(10)
    
    set @ChainId=40393
    
    SELECT @StartDate=GETDATE()-90, --Set Days to look for POS data
           @EndDate=GETDATE() - 3 
	
	Select distinct SS.SupplierID, S.StoreId, S.ChainID, S.Custom1 as Banner, S.StoreIdentifier
	into #tmpNoFeedData
	from Stores S
			inner join StoreSetup SS on SS.StoreID=S.StoreID and SS.ChainID=S.ChainID and GETDATE() between SS.ActiveStartDate and SS.ActiveLastDate
	where ActiveStatus='Active' and GETDATE() between S.ActiveFromDate and S.ActiveLastDate
			and S.ChainID=40393	
	order by 1,2,3
		           
	;with alldates as
	(
		select @StartDate DateVal
		union all
		select DateVal + 1 from alldates where DateVal + 1 <= @EndDate
	 )	

	select convert(varchar(10), DateVal, 101) as ForDate into #tmpDates from alldates

	OPTION (MAXRECURSION 0)
	
	--Truncate Table tmpNoStoreFeed
	Delete from DataTrue_CustomResultSets.dbo.tmpNoStoreFeed where OnSaleDate>=@StartDate
	
	Declare @ForDate date
	DECLARE date_cursor CURSOR FOR 
	
	select ForDate from #tmpDates		
	
	OPEN date_cursor;
		FETCH NEXT FROM date_cursor INTO @ForDate
			while @@FETCH_STATUS = 0
			begin
			
		--POS
			Insert into DataTrue_CustomResultSets.dbo.tmpNoStoreFeed
			Select distinct T.SupplierId, T.ChainId, T.Banner, T.StoreId, convert(varchar(10),@ForDate, 101), 'POS', '01/01/2000' 
			from #tmpNoFeedData T 
			Left Join DataTrue_Report.dbo.StoreTransactions S on S.SupplierID=T.SupplierID and S.ChainID=T.ChainID and S.StoreID=T.StoreID and S.SaleDateTime=@ForDate
			Left join TransactionTypes TT on TT.TransactionTypeID=S.TransactionTypeID and BucketType=1  
			where  S.Qty is null
			
		--Deliveries
			Insert into DataTrue_CustomResultSets.dbo.tmpNoStoreFeed
			Select distinct T.SupplierId, T.ChainId, T.Banner, T.StoreId, convert(varchar(10),@ForDate, 101), 'Deliveries', '01/01/2000' 
			from #tmpNoFeedData T 
			Left Join DataTrue_Report.dbo.StoreTransactions S on S.SupplierID=T.SupplierID and S.ChainID=T.ChainID and S.StoreID=T.StoreID and S.SaleDateTime=@ForDate
			Left join TransactionTypes TT on TT.TransactionTypeID=S.TransactionTypeID and BucketType=2  
			where  S.Qty is null
			
		--Inventory Count
			Insert into DataTrue_CustomResultSets.dbo.tmpNoStoreFeed
			Select distinct T.SupplierId, T.ChainId, T.Banner, T.StoreId, convert(varchar(10),@ForDate, 101), 'Inventory Count', '01/01/2000' 
			from #tmpNoFeedData T 
			Left Join DataTrue_Report.dbo.StoreTransactions S on S.SupplierID=T.SupplierID and S.ChainID=T.ChainID and S.StoreID=T.StoreID  and S.SaleDateTime=@ForDate and TransactionTypeID in (10,11) 
			where S.Qty is null
				
			FETCH NEXT FROM date_cursor INTO  @ForDate
			end
	CLOSE date_cursor;
	DEALLOCATE date_cursor;
	
	
	Select S.Supplierid, S.ChainID, S.StoreId, 
	case when BucketType=1 then 'POS' when BucketType=2 then 'Deliveries' 
	when S.TransactionTypeID in (10,11) then 'Inventory Count' 
	end as TransactionType,	 MAX(S.SaleDateTime) as lastDate 
	into #tmpLastTransactionDate 
	from DataTrue_Report.dbo.StoreTransactions S 
	inner join TransactionTypes TT on TT.TransactionTypeID=S.TransactionTypeID 
	Group by S.Supplierid, S.ChainID, S.StoreId, BucketType, S.TransactionTypeID
	
	Update t
	set t.LastSaleDate=convert(date, S.lastDate, 101)
	--select t.LastSaleDate,S.lastDate
	from 	DataTrue_CustomResultSets.dbo.tmpNoStoreFeed t
	inner join #tmpLastTransactionDate S on S.SupplierID=T.SupplierID and S.ChainID=T.ChainID and S.StoreID=T.StoreID 
	where T.TransactionType=S.TransactionType
	
	
End
GO
