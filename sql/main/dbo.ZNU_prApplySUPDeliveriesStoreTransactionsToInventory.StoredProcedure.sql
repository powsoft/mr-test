USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[ZNU_prApplySUPDeliveriesStoreTransactionsToInventory]    Script Date: 06/25/2015 18:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[ZNU_prApplySUPDeliveriesStoreTransactionsToInventory]

as

declare @MyID int
set @MyID = 7592

begin transaction

--delivery records
select distinct StoreTransactionID
into #tempStoreTransaction
from [dbo].[StoreTransactions]
where TransactionStatus = 0
and TransactionTypeID in (5)
and CostMisMatch = 0
and RetailMisMatch = 0

--**************************************************************
MERGE INTO [dbo].[InventoryPerpetual] i

USING (SELECT [ChainID]
	  ,[StoreID]
      ,[ProductID]
      ,[BrandID]
      ,sum([Qty]) as Qty
      ,max([SaleDateTime]) as EffectiveDateTime
  FROM [dbo].[StoreTransactions] t
  inner join #tempStoreTransaction tmp
	on t.StoreTransactionID = tmp.StoreTransactionID
	group by t.chainid, t.storeid, t.productid, t.brandid) S
	on i.ChainID = s.ChainID
	and i.StoreID = s.StoreID 
	and i.ProductID = s.ProductID
	and i.BrandID = s.BrandID

WHEN MATCHED THEN

update set  Deliveries = Deliveries + S.Qty
	,CurrentOnHandQty = CurrentOnHandQty + s.Qty 
	,LastUpdateUserID = @MyID
	,DateTimeLastUpdate = getdate()
	,EffectiveDateTime = case when s.EffectiveDateTime > i.EffectiveDateTime then s.EffectiveDateTime else i.EffectiveDateTime end
	
WHEN NOT MATCHED 

THEN INSERT 
           ([ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[BrandID]
           ,[OriginalQty]
           ,[Deliveries]
           ,[SBTSales]
           ,[ShrinkRevision]
           ,[CurrentOnHandQty]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[EffectiveDateTime])
     VALUES
           (s.[ChainID]
           ,s.[StoreID]
			,s.[ProductID]
			,s.[BrandID]
			,0
			,s.[Qty]
			,0
			,0
			,s.[Qty]
			,@MyID
			,getdate()
			,s.EffectiveDateTime);
--**************************************************************
update t set TransactionStatus = 1
	,LastUpdateUserID = @MyID
	,DateTimeLastUpdate = GETDATE()
	from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions] t
on tmp.StoreTransactionID = t.StoreTransactionID


if @@ERROR = 0
	commit transaction
else
	rollback transaction
	
return
GO
