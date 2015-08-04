USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Reorder]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_Report_Reorder]
    @ChainId varchar(500),
	@PersonID int,
	@Banner varchar(50),
	@ProductUPC varchar(20),
	@SupplierId varchar(500),
	@StoreId varchar(10),
	@LastxDays int,
	@StartDate varchar(20),
	@EndDate varchar(20), @MaxRowsCount varchar(20) = ' Top 2500000 '
as
-- exec [usp_Report_Reorder] 79380,'','','','79385','','','',''
Begin
	
	Select distinct S.ChainId, S.SupplierId, S.StoreId, S.ProductId, Max(SaleDateTime) as LastCountDate
	into #tmpLastCountDate
		From StoreTransactions S with(nolock)
		where TransactionTypeId in (10,11) and S.SupplierId=@SupplierId and S.ChainId=@ChainId
		group by S.ChainId, S.SupplierId, S.StoreId, S.ProductId
		
	Select distinct S.ChainId, S.SupplierId, S.StoreId, S.ProductId, Sum(Qty) as LastCountUnits
	into #tmpLastCountUnits
		From StoreTransactions S with(nolock)
		inner join #tmpLastCountDate T on T.ChainId=S.ChainID and T.SupplierId=S.SupplierId and T.StoreId=S.StoreId and T.ProductId=S.ProductId and S.SaleDateTime=T.LastCountDate
		where S.TransactionTypeId in (10,11) and S.SupplierId=@SupplierId and S.ChainId=@ChainId 
		group by S.ChainId, S.SupplierId, S.StoreId, S.ProductId

	Select distinct S.ChainId, S.SupplierId, S.StoreId, S.ProductId, Sum(Qty*QtySign) as SaleUnits
	into #tmpSales
		From StoreTransactions S with(nolock)
		inner join TransactionTypes TT with(nolock) on TT.TransactionTypeId=S.TransactionTypeId
		inner join #tmpLastCountDate T on T.ChainId=S.ChainID and T.SupplierId=S.SupplierId and T.StoreId=S.StoreId and T.ProductId=S.ProductId 
		and S.SaleDateTime> case when S.TransactionTypeId=10 then T.LastCountDate else dateadd(d,-1,T.LastCountDate) end
		where BucketType=1 and S.SupplierId=@SupplierId and S.ChainId=@ChainId 
		group by S.ChainId, S.SupplierId, S.StoreId, S.ProductId

	Select distinct S.ChainId, S.SupplierId, S.StoreId, S.ProductId, Sum(Qty*QtySign) as DeliveryUnits
	into #tmpDeliveries
		From StoreTransactions S with(nolock)
		inner join TransactionTypes TT with(nolock) on TT.TransactionTypeId=S.TransactionTypeId
		inner join #tmpLastCountDate T on T.ChainId=S.ChainID and T.SupplierId=S.SupplierId and T.StoreId=S.StoreId and T.ProductId=S.ProductId 
		and S.SaleDateTime> case when S.TransactionTypeId=10 then T.LastCountDate else dateadd(d,-1,T.LastCountDate) end
		where BucketType=2 and S.SupplierId=@SupplierId and S.ChainId=@ChainId 
		group by S.ChainId, S.SupplierId, S.StoreId, S.ProductId 

	Select distinct S.ChainId, S.SupplierId, S.StoreId, S.ProductId, max(SaleDateTime) as LastDeliveryDate
	into #tmpDeliveryDates
		From StoreTransactions S with(nolock)
		inner join TransactionTypes TT with(nolock) on TT.TransactionTypeId=S.TransactionTypeId
		where BucketType=2 and S.SupplierId=@SupplierId and S.ChainId=@ChainId 
		group by S.ChainId, S.SupplierId, S.StoreId, S.ProductId 
	
	select C.ChainId, SP.SupplierId, ST.StoreID, P.ProductID, C.ChainName, SP.SupplierName, ST.StoreIdentifier,PD.IdentifierValue, P.Description,
	(isnull(LastCountUnits,0)- isnull(SaleUnits,0)+ isnull(DeliveryUnits,0)) as StockUnits
	into #tmpPerpetualInventory
		from #tmpLastCountUnits A
		inner join Suppliers SP with(nolock) on SP.SupplierId=A.SupplierId
		inner join Stores ST with(nolock) on ST.StoreId=A.StoreId
		inner join Chains C with(nolock) on C.ChainID=ST.ChainID
		inner join Products P with(nolock) on P.ProductId=A.ProductId
		inner join ProductIdentifiers PD with(nolock) on PD.ProductId=A.ProductId and PD.ProductIdentifierTypeId in (2,8)
		inner join StoreSetup SS with(nolock) on SS.SupplierId=A.SupplierId and SS.ChainId=ST.ChainId and SS.StoreId=A.StoreId and SS.ProductId=A.ProductId
		inner join #tmpLastCountDate T on T.ChainId=C.ChainID and T.SupplierId=A.SupplierId and T.StoreId=A.StoreId and T.ProductId=A.ProductId
		left join #tmpSales S on S.ChainId=C.ChainID and A.SupplierId=S.SupplierId and A.StoreId=S.StoreId and A.ProductId=S.ProductId
		left join #tmpDeliveries D on D.ChainId=C.ChainID and D.SupplierId=A.SupplierId and D.StoreId=A.StoreId and D.ProductId=A.ProductId
		left join #tmpDeliveryDates D1 on D1.ChainId=C.ChainID and D1.SupplierId=A.SupplierId and D1.StoreId=A.StoreId and D1.ProductId=A.ProductId
		left join ProductIdentifiers PD1 with(nolock) on PD1.ProductId=A.ProductId and PD1.ProductIdentifierTypeId =8 
		where D1.LastDeliveryDate is not null	
		
	select P.ChainName as [Retailer Name],
		   P.SupplierName as [Supplier Name],
		   P.StoreIdentifier as [Store Number],
		   P.IdentifierValue as UPC,
		   P.Description as [Product Desc],
		   convert(varchar(10),getdate(),101) as Date,
		   P.StockUnits as [Perpetual Qty],
		   A.MinStockLevel as [Trigger Qty],
		   A.ReorderQuantity as [Reorder Qty]
		from  #tmpPerpetualInventory P
		INNER JOIN StockAlerts A ON P.ChainId=A.ChainID and P.SupplierId=A.SupplierId 
		and P.StoreId like CASE WHEN A.StoreId ='-1' then '%' else A.StoreId end AND P.ProductId=A.ProductId
		where cast(StockUnits as numeric) < A.MinStockLevel          
end
GO
