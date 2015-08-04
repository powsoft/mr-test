USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_PerpetualInventoryPage]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_PerpetualInventoryPage]
	@ChainId varchar(10),
	@SupplierId varchar(10),
	@StoreNo varchar(50),
	@UPC varchar(50),
	@ProductName varchar(50),
	@StockUnitsLessThan varchar(50),
	@StockUnitsGreaterThan varchar(50),
	@SupplierIdentifierValue varchar(50),
    @RetailerIdentifierValue varchar(50)
as
--exec [usp_PerpetualInventoryPage] 44199, '44246','13896','013120012518','','','','',''
--exec [usp_PerpetualInventoryPage] 79380, '79385','','','','','','',''

Begin
	
	IF(@StockUnitsLessThan='')
		set @StockUnitsLessThan='10000'
	
	IF(@StockUnitsGreaterThan='')
		set @StockUnitsGreaterThan='-10000'
				
	Select distinct S.SupplierId, S.StoreId, S.ProductId,S.TransactionTypeId, Max(SaleDateTime) as LastCountDate
	into #tmpLastCountDate
		From StoreTransactions S with(nolock)
		where TransactionTypeId in (10,11) and S.SupplierId=@SupplierId and S.ChainId=@ChainId
		group by S.SupplierId, S.StoreId, S.ProductId,S.TransactionTypeId

	Select distinct S.SupplierId, S.StoreId, S.ProductId, Sum(Qty) as LastCountUnits
	into #tmpLastCountUnits
		From StoreTransactions S with(nolock)
		inner join #tmpLastCountDate T on T.SupplierId=S.SupplierId and T.StoreId=S.StoreId and T.ProductId=S.ProductId and S.SaleDateTime=T.LastCountDate
		where S.TransactionTypeId in (10,11) and S.SupplierId=@SupplierId and S.ChainId=@ChainId 
		group by S.SupplierId, S.StoreId, S.ProductId

	Select distinct S.SupplierId, S.StoreId, S.ProductId, Sum(Qty*QtySign) as SaleUnits
	into #tmpSales
		From StoreTransactions S with(nolock)
		inner join TransactionTypes TT with(nolock) on TT.TransactionTypeId=S.TransactionTypeId
		inner join #tmpLastCountDate T on T.SupplierId=S.SupplierId and T.StoreId=S.StoreId and T.ProductId=S.ProductId and S.SaleDateTime> case when T.TransactionTypeId=10 then T.LastCountDate else dateadd(d,-1,T.LastCountDate) end
		where BucketType=1 and S.SupplierId=@SupplierId and S.ChainId=@ChainId 
		group by S.SupplierId, S.StoreId, S.ProductId
	
	Select distinct S.SupplierId, S.StoreId, S.ProductId, max(SaleDateTime) as LastSaleDate
	into #tmpSaleDates
		From StoreTransactions S with(nolock)
		inner join TransactionTypes TT with(nolock) on TT.TransactionTypeId=S.TransactionTypeId
		where BucketType=1 and S.SupplierId=@SupplierId and S.ChainId=@ChainId 
		group by S.SupplierId, S.StoreId, S.ProductId 
		
	Select distinct S.SupplierId, S.StoreId, S.ProductId, Sum(Qty*QtySign) as DeliveryUnits
	into #tmpDeliveries
		From StoreTransactions S with(nolock)
		inner join TransactionTypes TT with(nolock) on TT.TransactionTypeId=S.TransactionTypeId
		inner join #tmpLastCountDate T on T.SupplierId=S.SupplierId and T.StoreId=S.StoreId and T.ProductId=S.ProductId and S.SaleDateTime> case when T.TransactionTypeId=10 then T.LastCountDate else dateadd(d,-1,T.LastCountDate) end
		where BucketType=2 and S.SupplierId=@SupplierId and S.ChainId=@ChainId 
		group by S.SupplierId, S.StoreId, S.ProductId 

	Select distinct S.SupplierId, S.StoreId, S.ProductId, max(SaleDateTime) as LastDeliveryDate
	into #tmpDeliveryDates
		From StoreTransactions S with(nolock)
		inner join TransactionTypes TT with(nolock) on TT.TransactionTypeId=S.TransactionTypeId
		where BucketType=2 and S.SupplierId=@SupplierId and S.ChainId=@ChainId 
		group by S.SupplierId, S.StoreId, S.ProductId 
	
	select c.ChainID,ST.StoreID,p.ProductID, SP.SupplierName as [Supplier Name], ST.StoreIdentifier as StoreNumber, PD.IdentifierValue as UPC, P.ProductName,
	 convert(varchar,T.LastCountDate,101) as [Last Count Date], 
	 convert(varchar,D1.LastDeliveryDate,101) as [Last Delivery Date], 
	 convert(varchar,S1.LastSaleDate,101) as [Last POS Date],
	 isnull(LastCountUnits,0) as [Last Inventory Count], isnull(SaleUnits,0) as [Units Sold],
	 isnull(DeliveryUnits,0) as [Net Units Delivered Confirmed], 
	 (isnull(LastCountUnits,0)- isnull(SaleUnits,0)+ isnull(DeliveryUnits,0)) as StockUnits
		into #tmpPerpetualInventory
		from #tmpLastCountUnits A
		inner join Suppliers SP with(nolock) on SP.SupplierId=A.SupplierId
		inner join Stores ST with(nolock) on ST.StoreId=A.StoreId
		inner join Chains C with(nolock) on C.ChainID=ST.ChainID
		inner join Products P with(nolock) on P.ProductId=A.ProductId
		inner join ProductIdentifiers PD with(nolock) on PD.ProductId=A.ProductId and PD.ProductIdentifierTypeId in (2,8)
		inner join StoreSetup SS with(nolock) on SS.SupplierId=A.SupplierId and SS.ChainId=ST.ChainId and SS.StoreId=A.StoreId and SS.ProductId=A.ProductId
		inner join #tmpLastCountDate T on T.SupplierId=A.SupplierId and T.StoreId=A.StoreId and T.ProductId=A.ProductId
		left join #tmpSales S on A.SupplierId=S.SupplierId and A.StoreId=S.StoreId and A.ProductId=S.ProductId
		left join #tmpSaleDates S1 on S1.SupplierId=A.SupplierId and S1.StoreId=A.StoreId and S1.ProductId=A.ProductId 
		left join #tmpDeliveries D on D.SupplierId=A.SupplierId and D.StoreId=A.StoreId and D.ProductId=A.ProductId
		left join #tmpDeliveryDates D1 on D1.SupplierId=A.SupplierId and D1.StoreId=A.StoreId and D1.ProductId=A.ProductId 
		left join ProductIdentifiers PD1 with(nolock) on PD1.ProductId=A.ProductId and PD1.ProductIdentifierTypeId =8 and PD1.Bipad like '%' + @UPC + '%'
		where ST.StoreIdentifier like '%'+ @StoreNo +'%' 
		and PD.IdentifierValue like '%'+ @UPC + '%'  
		and P.ProductName like '%'+ @ProductName + '%'
		--and D1.LastDeliveryDate is not null
		and SP.SupplierIdentifier like '%' + @SupplierIdentifierValue + '%'
		and C.ChainIdentifier like '%' + @RetailerIdentifierValue + '%'
		
		
		select t.[Supplier Name], t.StoreNumber, t.UPC, t.ProductName,
			t.[Last Count Date], t.[Last Delivery Date], t.[Last POS Date],
			t.[Last Inventory Count], t.[Units Sold],t.[Net Units Delivered Confirmed], 
			t.StockUnits,MinCapacity,MaxCapacity
		from #tmpPerpetualInventory t 
		left join (select distinct N.RetailerID, P.ProductID, A.StoreId  ,MinCapacity,MaxCapacity
					from PlanogramNames N
					inner join PlanogramAssignments a with (nolock)on N.PlanogramID=a.PlanogramID and A.Active=1
					inner join PlanogramReplenishment p with (nolock)on P.PlanogramID=a.PlanogramID and P.Active=1
					where N.Active=1
				   ) P on P.RetailerID=t.ChainID and P.StoreID=t.StoreID and P.ProductID=T.ProductID
		where 1=1 
		and cast(StockUnits as numeric) betweeN @StockUnitsGreaterThan AND @StockUnitsLessThan
           
end
GO
