USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SaleForecastReport_test]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec  [usp_SaleForecastReport] 40393, 40557, 'Albertsons - SCAL', 60, 2, 2, '', 2, ''
Create procedure [dbo].[usp_SaleForecastReport_test]
 @ChainId varchar(5),
 @SupplierID varchar(5),
 @custom1 varchar(255),
 @OldDays int,
 @POSWeeks int,
 @ProductIdentifierType int,
 @ProductIdentifierValue varchar(50),
 @StoreIdentifierType int,
 @StoreIdentifierValue varchar(50)
as
Begin

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
	begin try
			Drop  table [@tmpSaleForecast]
	end try
	begin catch
	end catch
	
	Declare @wkday varchar(10), @wkdate date, @oldwkdate date
	DECLARE date_cursor CURSOR FOR 
	
	select * from #tmpDates		
	OPEN date_cursor;
		FETCH NEXT FROM date_cursor INTO @wkday, @wkdate, @oldwkdate
			while @@FETCH_STATUS = 0
			begin
				Insert into [@tmpSaleForecast]
				SELECT  distinct SS.SupplierID, SS.ChainID, SS.Storeid, SS.ProductID, @wkday as [week day], 
				@oldwkdate as [Old Transaction Date], ST2.saleqty as OldSaleUnits, 
				@wkdate as [Transaction Date], ST1.saleqty as SaleUnits, ST1.saleqty as [Forecast Units],(ST1.saleqty- ST2.saleqty) as [Var Units], 
				NULL as [Var Per],NULL as PromoDay
				from StoreSetup SS 
					Inner Join Stores ST on ST.StoreID = SS.StoreID and ST.ActiveStatus='Active'
					Left Join (select SupplierId, ChainId, StoreId, ProductId, sum(qty) as saleqty from StoreTransactions S 
					Inner Join TransactionTypes TT on TT.TransactionTypeID=S.TransactionTypeID and TT.BucketType=1
					where S.SaleDateTime=@wkdate group by SupplierId, ChainId, StoreId, ProductId) ST1 on ST1.SupplierID=SS.SupplierID 
					and ST1.ChainID=SS.ChainID and ST1.StoreID=SS.StoreID and ST1.ProductID=SS.ProductID 
					Left Join (select SupplierId, ChainId, StoreId, ProductId, sum(qty) as saleqty from StoreTransactions S 
					Inner Join TransactionTypes TT on TT.TransactionTypeID=S.TransactionTypeID and TT.BucketType=1
					where S.SaleDateTime=@oldwkdate group by SupplierId, ChainId, StoreId, ProductId) ST2 on ST2.SupplierID=SS.SupplierID 
					and ST2.ChainID=SS.ChainID and ST2.StoreID=SS.StoreID and ST2.ProductID=SS.ProductID 
				where 	SS.SupplierID=@SupplierID and SS.ChainID=@ChainId and ST.Custom1=@custom1 --and ST.StoreID=@StoreID
				
				FETCH NEXT FROM date_cursor INTO  @wkday, @wkdate, @oldwkdate
			end
	CLOSE date_cursor;
	DEALLOCATE date_cursor;
	
	--Updating Var Percentage values in tmp table for dated older than tomorrow
	update t
	set [Var Per] =  cast(([Var Units]/OldSaleUnits * 100) as numeric(5,1)),
	PromoDay=case when P.UnitPrice IS null then '0' else '1' end
	from [@tmpSaleForecast] t
	left join ProductPrices P on P.SupplierID=t.SupplierID and P.StoreID=t.Storeid and P.ProductID=t.ProductID and P.ProductPriceTypeID=8 
	and t.[Old Transaction Date] between  P.ActiveStartDate and P.ActiveLastDate
	where [Transaction Date]<=GETDATE() and isnull(OldSaleUnits,0) <>0
	
	-- Calculating the Base Avg Variation based on Old Sales
	Select SupplierID,ChainID,Storeid, ProductID, [week day], 
	(sum(SaleUnits-OldSaleUnits)*100/sum(OldSaleUnits)) as [Base avg var%]
	into #tmpSaledata
	from [@tmpSaleForecast] t 
	where SaleUnits>0 and [Transaction Date]<=GETDATE()
	group by SupplierID,ChainID,Storeid, ProductID, [week day] having sum(OldSaleUnits)>0
	
	-- Update Forecast values with the calculated results
	update t
	set t.[Forecast Units] = t.OldSaleUnits + (t.OldSaleUnits * t1.[Base avg var%] / 100), t.[Var Per]=t1.[Base avg var%], t.[Var Units]=(t.OldSaleUnits * t1.[Base avg var%] / 100)
	from [@tmpSaleForecast] t inner join
	#tmpSaledata t1 on t1.SupplierID=t.SupplierID and t.ChainID=t1.ChainID and t.Storeid =t1.Storeid and t.ProductID=t1.ProductID and t.[week day]=t1.[week day]
	where t.[Transaction Date]>GETDATE()

	Delete t from [@tmpSaleForecast] t
	inner join  (
	select SupplierID, Storeid, productid from [@tmpSaleForecast] where [Transaction Date]>GETDATE()
	GROUP by productid, SupplierID, Storeid
	having sum(isnull([Forecast Units],0))=0) as s on s.SupplierID=t.SupplierID and s.Storeid=t.Storeid and s.ProductID=t.ProductID
	
	
	Declare @TransDate varchar(2000)
	Declare @sqlQuery varchar(8000), @recCount numeric(10)
	select @recCount=COUNT([Transaction Date]) from [@tmpSaleForecast]
	
	if(@recCount=0)
		select COUNT([Transaction Date]) from [@tmpSaleForecast]
	else
	begin
		
		select @TransDate = COALESCE(@TransDate+'],[' ,'') + CAST( [Transaction Date] as varchar(10))
		from tmpSaleForecast group by [Transaction Date] order by [Transaction Date] desc
		
		begin try
			Drop Table [@tmpSaleData]
		end try
		begin catch
		end catch
			
		set @sqlQuery='
					SELECT * into [@tmpSaleData] FROM
					(
					  SELECT ChainID, SupplierId, StoreID, ProductID,[Transaction Date], ''Current Dates'' as Dates, [Forecast Units]
					  FROM [@tmpSaleForecast] 
					) TableDate

					PIVOT 
					(
					  sum([Forecast Units])  FOR [Transaction Date] IN ([' + @TransDate + '])
					) PivotTable
					
					Union All
					
					SELECT * FROM 
					(
					  SELECT ChainID, SupplierId, StoreID, ProductID,[Transaction Date], ''Prior Dates'' as Dates, OldSaleUnits
					  FROM [@tmpSaleForecast] 
					) TableDate
					PIVOT 
					(
					  sum(OldSaleUnits)  FOR [Transaction Date] IN ([' + @TransDate + '])
					) PivotTable
					
					Union All
					
					SELECT * FROM 
					(
					  SELECT ChainID, SupplierId, StoreID, ProductID, [Transaction Date], ''Promo Day'' as Dates, PromoDay
					  FROM [@tmpSaleForecast] 
					) TableDate
					PIVOT 
					(
					  sum(PromoDay)  FOR [Transaction Date] IN ([' + @TransDate + '])
					) PivotTable
					
					Union All
					
					SELECT * FROM 
					(
					  SELECT ChainID, SupplierId, StoreID, ProductID, [Transaction Date], ''VAR Units'' as Dates,  [Var Units]
					  FROM [@tmpSaleForecast] 
					) TableDate
					PIVOT 
					(
					  sum([Var Units])  FOR [Transaction Date] IN ([' + @TransDate + '])
					) PivotTable
					
					Union All
					
					SELECT * FROM 
					(
					  SELECT ChainID, SupplierId, StoreID, ProductID,[Transaction Date], ''VAR(%)'' as Dates,  [Var Per]
					  FROM [@tmpSaleForecast] 
					) TableDate
					PIVOT 
					(
					  sum([Var Per])  FOR [Transaction Date] IN ([' + @TransDate + '])
					) PivotTable
					
					order by ChainID, SupplierId, StoreID, ProductID, Dates	'
		
		exec(@sqlQuery)
		
			
		set @sqlQuery = 'select C.ChainName as [Retailer Name], SP.SupplierName as [Supplier Name],
						S.Custom1 as Banner, S.StoreIdentifier as [Store Number], P.ProductName as [Product Name],
						PD.IdentifierValue as [UPC], t.* 
						from  [@tmpSaleData] t 
						INNER JOIN Stores S ON S.StoreID = t.StoreID and S.ActiveStatus=''Active'' 
						INNER JOIN Products P ON P.ProductId = t.ProductId 
						INNER JOIN Suppliers SP ON SP.SupplierId = t.SupplierId
						INNER JOIN Chains C ON C.ChainId = t.ChainId
						INNER JOIN ProductIdentifiers PD ON PD.ProductID = P.ProductID 
						where 1=1 '
		
		if(@ChainId <>'-1') 
			set @sqlQuery = @sqlQuery +  ' and C.ChainID=' + @ChainId

		if(@SupplierID <>'-1') 
			set @sqlQuery = @sqlQuery +  ' and t.supplierid=' + @SupplierId
		
		if(@ProductIdentifierType<>3)
				set @sqlQuery = @sqlQuery + ' and PD.ProductIdentifierTypeId =' + cast(@ProductIdentifierType as varchar)
		else
				set @sqlQuery = @sqlQuery + ' and PD.ProductIdentifierTypeId = 2'
				
		if(@ProductIdentifierValue<>'')
		begin
			-- 2 = UPC, 3 = Product Name 
			if (@ProductIdentifierType=2)
				 set @sqlQuery = @sqlQuery + ' and PD.IdentifierValue like ''%' + @ProductIdentifierValue + '%'''
		         
			else if (@ProductIdentifierType=3)
				set @sqlQuery = @sqlQuery + ' and P.ProductName like ''%' + @ProductIdentifierValue + '%'''
		end
	 
		if(@StoreIdentifierValue<>'')
		begin
			-- 1 = Store Number, 2 = SBT Number, 3 = Store Name
			if (@StoreIdentifierType=1)
				set @sqlQuery = @sqlQuery + ' and S.storeidentifier like ''%' + @StoreIdentifierValue + '%'''
			else if (@StoreIdentifierType=2)
				set @sqlQuery = @sqlQuery + ' and S.Custom2 like ''%' + @StoreIdentifierValue + '%'''
			else if (@StoreIdentifierType=3)
				set @sqlQuery = @sqlQuery + ' and S.StoreName like ''%' + @StoreIdentifierValue + '%'''
		end
		
		set @sqlQuery = @sqlQuery + ' ORDER BY 1,2,3,4,5,6'
		exec(@sqlQuery); 
	end
End
GO
