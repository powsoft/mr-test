USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GenerateSaleForecastData]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--Sale Forecast Report
--exec [usp_GenerateSaleForecastData] 40393, 40557, 'Albertsons - SCAL', 60, 2
CREATE procedure [dbo].[usp_GenerateSaleForecastData]
@ChainId varchar(5),
@SupplierID varchar(5),
@Banner varchar(50),
@OldDays int,
@POSWeeks int
as
Begin
	--Drop the temp tables at the begining
	begin try
		Drop Table #tmpAllProducts   
		Drop Table #tmpDates 
	end try
	begin catch
	end catch
	
	DECLARE @StartDate datetime,  @EndDate datetime
	--DECLARE @OldDays int, @POSWeeks int
    
    --POSWeeks : The no of weeks to calculate the Avg POS
    --OldDayes : The POS data for comparision and forecasting, ex: for previous year, set this to 365 for previous year, 180 for 6 months old data
    
   -- Set @POSWeeks =2
   -- Set @OldDays = 60 
    
    -- Preparing a dataset of dates for POS
    SELECT @StartDate=GETDATE()-(@POSWeeks * 7) + 1, --Set Days to look back for POS data
           @EndDate=GETDATE()+ 7 ,
           @OldDays = @OldDays - (@OldDays%7)
 
     ;with alldates as
	(
		select datename(WEEKDAY, @StartDate) wkday, convert(date,@StartDate ,101) as wkdate , 
		convert(date,@StartDate-@OldDays,101) as oldwkdate, @StartDate as dat
		union all
		select datename(WEEKDAY, dat + 1), convert(date,dat +1,101),convert(date, dat + 1 -@OldDays,101), dat + 1  from alldates where dat + 1 <= @EndDate
	 )
	select  wkday, wkdate, oldwkdate into #tmpDates from alldates

	OPTION (MAXRECURSION 0)
	
	--Calculate the sales for last @POSWeeks and OldDates and store in a table
	Delete from DataTrue_CustomResultSets.dbo.tmpSaleForecast 
	where SupplierID=@SupplierID and ChainID=@ChainId and [Transaction Date] >= cast(@StartDate as date) and [Transaction Date]<=cast(@EndDate as date)
	
	
	Declare @wkday varchar(10), @wkdate date, @oldwkdate date
	DECLARE date_cursor CURSOR FOR 
	
	select * from #tmpDates		
	OPEN date_cursor;
		FETCH NEXT FROM date_cursor INTO @wkday, @wkdate, @oldwkdate
			while @@FETCH_STATUS = 0
			begin
				Insert into DataTrue_CustomResultSets.dbo.tmpSaleForecast
				SELECT  distinct SS.SupplierID, SS.ChainID, SS.Storeid, SS.ProductID, @wkday as [week day], 
				@oldwkdate as [Old Transaction Date], isnull(ST2.saleqty,0) as OldSaleUnits, 
				@wkdate as [Transaction Date], isnull(ST1.saleqty,0) as SaleUnits, isnull(ST1.saleqty,0) as [Forecast Units],(isnull(ST1.saleqty,0)- isnull(ST2.saleqty,0)) as [Var Units], 
				NULL as [Var Per],NULL as PromoDay
				from StoreSetup SS 
					Inner Join Stores ST on ST.StoreID = SS.StoreID and ST.ActiveStatus='Active'
					Left Join (select SupplierId, ChainId, StoreId, ProductId, sum(qty) as saleqty from DataTrue_Report.dbo.StoreTransactions S 
					Inner Join TransactionTypes TT on TT.TransactionTypeID=S.TransactionTypeID and TT.BucketType=1
					where S.SaleDateTime=@wkdate group by SupplierId, ChainId, StoreId, ProductId) ST1 on ST1.SupplierID=SS.SupplierID 
					and ST1.ChainID=SS.ChainID and ST1.StoreID=SS.StoreID and ST1.ProductID=SS.ProductID 
					Left Join (select SupplierId, ChainId, StoreId, ProductId, sum(qty) as saleqty from DataTrue_Report.dbo.StoreTransactions S 
					Inner Join TransactionTypes TT on TT.TransactionTypeID=S.TransactionTypeID and TT.BucketType=1
					where S.SaleDateTime=@oldwkdate group by SupplierId, ChainId, StoreId, ProductId) ST2 on ST2.SupplierID=SS.SupplierID 
					and ST2.ChainID=SS.ChainID and ST2.StoreID=SS.StoreID and ST2.ProductID=SS.ProductID 
				where 	SS.SupplierID=@SupplierID and SS.ChainID=@ChainId and ST.Custom1=@Banner --and ST.StoreID=@StoreID
				
				FETCH NEXT FROM date_cursor INTO  @wkday, @wkdate, @oldwkdate
			end
	CLOSE date_cursor;
	DEALLOCATE date_cursor;
	
	
	
	--Updating Var Percentage values in tmp table for dated older than tomorrow
	update t
	set	PromoDay=case when P.UnitPrice IS null then '0' else '1' end
	from DataTrue_CustomResultSets.dbo.tmpSaleForecast t
	left join ProductPrices P on P.SupplierID=t.SupplierID and P.StoreID=t.Storeid and P.ProductID=t.ProductID and P.ProductPriceTypeID=8 
	and t.[Old Transaction Date] between  P.ActiveStartDate and P.ActiveLastDate
	where [Transaction Date]<=GETDATE()-2 
	
	-- Calculating the Base Avg Variation based on Old Sales
	Select SupplierID,ChainID,Storeid, ProductID, [week day], 
	AVG(SaleUnits-OldSaleUnits) as [Base avg var%]
	into #tmpSaledata
	from DataTrue_CustomResultSets.dbo.tmpSaleForecast t 
	where [Transaction Date]<=GETDATE()-2 
	group by SupplierID,ChainID,Storeid, ProductID, [week day] 
	
	-- Update Forecast values with the calculated results
	update t
	set t.[Forecast Units] = t.OldSaleUnits +  t1.[Base avg var%], t.[Var Units]=t1.[Base avg var%] 
	from DataTrue_CustomResultSets.dbo.tmpSaleForecast t inner join
	#tmpSaledata t1 on t1.SupplierID=t.SupplierID and t.ChainID=t1.ChainID and t.Storeid =t1.Storeid and t.ProductID=t1.ProductID and t.[week day]=t1.[week day]
	where t.[Transaction Date]>GETDATE() and t.OldSaleUnits +  t1.[Base avg var%]>=0

	--Select  * from tmpSaleForecast where Storeid= 41064		and productId=5390 	order by productid,[Transaction Date]

	Delete t from DataTrue_CustomResultSets.dbo.tmpSaleForecast t
	inner join  (
	select SupplierID, Storeid, productid from DataTrue_CustomResultSets.dbo.tmpSaleForecast where [Transaction Date]>GETDATE()
	GROUP by productid, SupplierID, Storeid
	having sum(isnull([Forecast Units],0))=0) as s on s.SupplierID=t.SupplierID and s.Storeid=t.Storeid and s.ProductID=t.ProductID
	
End
GO
