USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_PerpetualInventoryTest]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_PerpetualInventoryTest]
	@ChainId varchar(10),
	@SupplierId varchar(10),
	@StoreNo varchar(50),
	@UPC varchar(50),
	@ProductName varchar(50),
	@StockUnitsLessThan varchar(50),
	@StockUnitsGreaterThan varchar(50)
as
--exec [usp_PerpetualInventoryTest] 62348, 50721,'1686','015700177013','','',''
Begin
	Declare @StoreId as numeric
	Declare @ProductId as numeric
	
	set @StoreId=63368
	set @ProductId=3285910
	
	IF(@StockUnitsLessThan='')
		set @StockUnitsLessThan='10000'
	
	IF(@StockUnitsGreaterThan='')
		set @StockUnitsGreaterThan='-10000'
				
	Select distinct S.SupplierId, S.StoreId, S.ProductId,S.TransactionTypeId, Max(SaleDateTime) as LastCountDate
	into #tmpLastCountDate
		From Datatrue_Report.dbo.StoreTransactions S
		where TransactionTypeId in (10,11) and S.SupplierId=@SupplierId and S.ChainId=@ChainId and S.ProductID=@ProductId and S.StoreID=@StoreId
		group by S.SupplierId, S.StoreId, S.ProductId,S.TransactionTypeId

SELECT * FROM #tmpLastCountDate

	Select distinct S.SupplierId, S.StoreId, S.ProductId, Sum(Qty) as LastCountUnits
	into #tmpLastCountUnits
		From Datatrue_Report.dbo.StoreTransactions S
		inner join #tmpLastCountDate T on T.SupplierId=S.SupplierId and T.StoreId=S.StoreId and T.ProductId=S.ProductId and S.SaleDateTime=T.LastCountDate
		where S.TransactionTypeId in (10,11) and S.SupplierId=@SupplierId and S.ChainId=@ChainId and S.ProductID=@ProductId and S.StoreID=@StoreId
		group by S.SupplierId, S.StoreId, S.ProductId

--SELECT * FROM #tmpLastCountUnits

	Select distinct S.SupplierId, S.StoreId, S.ProductId, Sum(Qty*QtySign) as SaleUnits
	into #tmpSales
		From Datatrue_Report.dbo.StoreTransactions S
		inner join Datatrue_Report.dbo.TransactionTypes TT on TT.TransactionTypeId=S.TransactionTypeId
		inner join #tmpLastCountDate T on T.SupplierId=S.SupplierId and T.StoreId=S.StoreId and T.ProductId=S.ProductId and S.SaleDateTime> case when T.TransactionTypeId=10 then T.LastCountDate else dateadd(d,-1,T.LastCountDate) end
		where BucketType=1 and S.SupplierId=@SupplierId and S.ChainId=@ChainId and S.ProductID=@ProductId and S.StoreID=@StoreId
		group by S.SupplierId, S.StoreId, S.ProductId

--SELECT * FROM #tmpSales

	Select distinct S.SupplierId, S.StoreId, S.ProductId, Sum(Qty*QtySign) as DeliveryUnits
	into #tmpDeliveries
		From Datatrue_Report.dbo.StoreTransactions S
		inner join Datatrue_Report.dbo.TransactionTypes TT on TT.TransactionTypeId=S.TransactionTypeId
		inner join #tmpLastCountDate T on T.SupplierId=S.SupplierId and T.StoreId=S.StoreId and T.ProductId=S.ProductId and S.SaleDateTime> case when T.TransactionTypeId=10 then T.LastCountDate else dateadd(d,-1,T.LastCountDate) end
		where BucketType=2 and S.SupplierId=@SupplierId and S.ChainId=@ChainId and S.ProductID=@ProductId and S.StoreID=@StoreId
		group by S.SupplierId, S.StoreId, S.ProductId 

SELECT * FROM #tmpDeliveries

Select distinct S.SupplierId, S.StoreId, S.ProductId, max(SaleDateTime) as LastDeliveryDate
	into #tmpDeliveryDates
		From Datatrue_Report.dbo.StoreTransactions S
		inner join Datatrue_Report.dbo.TransactionTypes TT on TT.TransactionTypeId=S.TransactionTypeId
		where BucketType=2 and S.SupplierId=@SupplierId and S.ChainId=@ChainId and S.ProductID=@ProductId and S.StoreID=@StoreId
		group by S.SupplierId, S.StoreId, S.ProductId 
	
SELECT * FROM #tmpDeliveryDates	
	
	select SP.SupplierName as [Supplier Name], ST.StoreIdentifier as StoreNumber, PD.IdentifierValue as UPC, P.ProductName,
	 convert(varchar,T.LastCountDate,101) as [Last Count Date], convert(varchar,D1.LastDeliveryDate,101) as [Last Delivery Date], 
	 isnull(LastCountUnits,0) as [Last Inventory Count], isnull(SaleUnits,0) as [Units Sold],
	 isnull(DeliveryUnits,0) as [Net Units Delivered Confirmed], 
	 (isnull(LastCountUnits,0)- isnull(SaleUnits,0)+ isnull(DeliveryUnits,0)) as StockUnits
		into #tmpPerpetualInventory
		from #tmpLastCountUnits A
			inner join Datatrue_Report.dbo.Suppliers SP on SP.SupplierId=A.SupplierId
			inner join Datatrue_Report.dbo.Stores ST on ST.StoreId=A.StoreId
			inner join Datatrue_Report.dbo.Products P on P.ProductId=A.ProductId
			inner join Datatrue_Report.dbo.ProductIdentifiers PD on PD.ProductId=A.ProductId and PD.ProductIdentifierTypeId in (2,8)
			inner join Datatrue_Report.dbo.StoreSetup SS on SS.SupplierId=A.SupplierId and SS.ChainId=ST.ChainId and SS.StoreId=A.StoreId and SS.ProductId=A.ProductId
			inner join #tmpLastCountDate T on T.SupplierId=A.SupplierId and T.StoreId=A.StoreId and T.ProductId=A.ProductId
			left join #tmpSales S on A.SupplierId=S.SupplierId and A.StoreId=S.StoreId and A.ProductId=S.ProductId
			left join #tmpDeliveries D on D.SupplierId=A.SupplierId and D.StoreId=A.StoreId and D.ProductId=A.ProductId
			left join #tmpDeliveryDates D1 on D1.SupplierId=A.SupplierId and D1.StoreId=A.StoreId and D1.ProductId=A.ProductId
		
		where 
		ST.StoreIdentifier like '%'+ @StoreNo +'%' 
		and PD.IdentifierValue like '%'+ @UPC + '%' 
			 
		--	  D1.LastDeliveryDate is not null
			
		select * from  #tmpPerpetualInventory 
		where cast(StockUnits as numeric) betweeN @StockUnitsGreaterThan AND @StockUnitsLessThan
end

--exec [usp_PerpetualInventoryTest] 62348, 50721,'1686','015700177013','','',''
GO
