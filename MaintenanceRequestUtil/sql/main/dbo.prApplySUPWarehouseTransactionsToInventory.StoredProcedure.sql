USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prApplySUPWarehouseTransactionsToInventory]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prApplySUPWarehouseTransactionsToInventory]

as

declare @MyID int
set @MyID = 0

begin transaction

--delivery records
select distinct WarehouseTransactionID
into #tempWarehouseTransaction
--select *
from [dbo].[WarehouseTransactions]
where TransactionStatus in (0)
--where TransactionStatus in (1, 11)
and TransactionTypeID in (5)
and RuleCost is not null


--**************************************************************
MERGE INTO [dbo].[InventoryPerpetual_WHS] i

USING (SELECT [ChainID]
	  ,[WarehouseID]
      ,[ProductID]
      ,[BrandID]
      ,sum([Qty]) as Qty
      ,max([RuleCost]) as Cost
      ,max(isnull([RuleRetail], 0.00)) as Retail
      ,max([EffectiveDateTime]) as EffectiveDateTime
  FROM [dbo].[WarehouseTransactions] t
  inner join #tempWarehouseTransaction tmp
	on t.WarehouseTransactionID = tmp.WarehouseTransactionID
	group by t.chainid, t.Warehouseid, t.productid, t.brandid) S
	on i.ChainID = s.ChainID
	and i.WarehouseID = s.WarehouseID 
	and i.ProductID = s.ProductID
	and i.BrandID = s.BrandID

WHEN MATCHED THEN

update set  Deliveries = Deliveries + S.Qty
	,CurrentOnHandQty = CurrentOnHandQty + s.Qty 
	,LastUpdateUserID = @MyID
	,DateTimeLastUpdate = getdate()
	,EffectiveDateTime = case when s.EffectiveDateTime > i.EffectiveDateTime then s.EffectiveDateTime else i.EffectiveDateTime end
	,Cost = 
		case when i.CurrentOnHandQty > 0 then ((s.Cost * s.Qty) + (i.Cost * i.CurrentOnHandQty))/(s.Qty + i.CurrentOnHandQty) else s.Cost end
	,Retail = 
		case when i.CurrentOnHandQty > 0 then ((s.Retail * s.Qty) + (i.Retail * i.CurrentOnHandQty))/(s.Qty + i.CurrentOnHandQty) else s.Retail end

WHEN NOT MATCHED 

THEN INSERT 
           ([ChainID]
           ,[WarehouseID]
           ,[ProductID]
           ,[BrandID]
           ,[OriginalQty]
           ,[Deliveries]
           ,[SBTSales]
           ,[ShrinkRevision]
           ,[CurrentOnHandQty]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[EffectiveDateTime]
           ,[Cost]
           ,[Retail])
     VALUES
           (s.[ChainID]
           ,s.[WarehouseID]
			,s.[ProductID]
			,s.[BrandID]
			,0
			,s.[Qty]
			,0
			,0
			,s.[Qty]
			,@MyID
			,getdate()
			,s.EffectiveDateTime
			,s.Cost
			,s.Retail);
--**************************************************************
update t set TransactionStatus = case when transactionstatus = 0 then 2 
else 0 end --@loadstatus
	,LastUpdateUserID = @MyID
	,DateTimeLastUpdate = GETDATE()
	from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID


/*
--delivery records
select distinct WarehouseTransactionID
into #tempWarehouseTransaction3
--select *
from [dbo].[WarehouseTransactions]
where TransactionStatus in (0, 1, 811)
--where TransactionStatus in (1, 11)
and TransactionTypeID in (9)
and RuleCost is not null
--and CostMisMatch = 0
--and RetailMisMatch = 0
--and TrueCost is not null
and CAST(EffectiveDateTime as date) >= '12/1/2011'
and SupplierID in (40558, 40562, 40561, 40557, 41464, 41465)

--**************************************************************
MERGE INTO [dbo].[InventoryPerpetual_WHS] i

USING (SELECT [ChainID]
	  ,[WarehouseID]
      ,[ProductID]
      ,[BrandID]
      ,sum([Qty]) as Qty
      ,max([RuleCost]) as Cost
      ,max(isnull([RuleRetail], 0.00)) as Retail
      ,max([EffectiveDateTime]) as EffectiveDateTime
  FROM [dbo].[WarehouseTransactions] t
  inner join #tempWarehouseTransaction3 tmp
	on t.WarehouseTransactionID = tmp.WarehouseTransactionID
	group by t.chainid, t.Warehouseid, t.productid, t.brandid) S
	on i.ChainID = s.ChainID
	and i.WarehouseID = s.WarehouseID 
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
           ,[WarehouseID]
           ,[ProductID]
           ,[BrandID]
           ,[OriginalQty]
           ,[Deliveries]
           ,[SBTSales]
           ,[ShrinkRevision]
           ,[CurrentOnHandQty]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[EffectiveDateTime]
           ,[Cost]
           ,[Retail])
     VALUES
           (s.[ChainID]
           ,s.[WarehouseID]
			,s.[ProductID]
			,s.[BrandID]
			,0
			,s.[Qty]
			,0
			,0
			,s.[Qty]
			,@MyID
			,getdate()
			,s.EffectiveDateTime
			,s.Cost
			,s.Retail);
--**************************************************************
update t set TransactionStatus = case when transactionstatus = 0 then 2 
when transactionstatus = 1 then 2 
									else 810 end --@loadstatus
	,LastUpdateUserID = @MyID
	,DateTimeLastUpdate = GETDATE()
	from #tempWarehouseTransaction3 tmp
inner join [dbo].[WarehouseTransactions] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
*/
--waitfor delay '0:0:5'

--exec DataTrue_Report..prCDCGetINVWarehouseTransactions

--pickup records
select distinct WarehouseTransactionID
into #tempWarehouseTransaction2
--select *
from [dbo].[WarehouseTransactions]
where TransactionStatus in (0)
--where TransactionStatus in (1, 11)
and TransactionTypeID in (8)
and RuleCost is not null

--**************************************************************
MERGE INTO [dbo].[InventoryPerpetual_WHS] i

USING (SELECT [ChainID]
	  ,[WarehouseID]
      ,[ProductID]
      ,[BrandID]
      ,sum([Qty]) as Qty
      ,max([RuleCost]) as Cost
      ,max(isnull([RuleRetail], 0.00)) as Retail
      ,max([EffectiveDateTime]) as EffectiveDateTime
  FROM [dbo].[WarehouseTransactions] t
  inner join #tempWarehouseTransaction2 tmp
	on t.WarehouseTransactionID = tmp.WarehouseTransactionID
	group by t.chainid, t.Warehouseid, t.productid, t.brandid) S
	on i.ChainID = s.ChainID
	and i.WarehouseID = s.WarehouseID 
	and i.ProductID = s.ProductID
	and i.BrandID = s.BrandID

WHEN MATCHED THEN

update set  Pickups = Pickups + S.Qty
	,CurrentOnHandQty = CurrentOnHandQty - s.Qty 
	,LastUpdateUserID = @MyID
	,DateTimeLastUpdate = getdate()
	--,EffectiveDateTime = case when s.EffectiveDateTime > i.EffectiveDateTime then s.EffectiveDateTime else i.EffectiveDateTime end
	
WHEN NOT MATCHED 

THEN INSERT 
           ([ChainID]
           ,[WarehouseID]
           ,[ProductID]
           ,[BrandID]
           ,[OriginalQty]
           ,[Pickups]
           ,[SBTSales]
           ,[ShrinkRevision]
           ,[CurrentOnHandQty]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[EffectiveDateTime]
           ,[Cost]
           ,[Retail])
     VALUES
           (s.[ChainID]
           ,s.[WarehouseID]
			,s.[ProductID]
			,s.[BrandID]
			,0
			,s.[Qty]
			,0
			,0
			,0 - s.[Qty]
			,@MyID
			,getdate()
			,s.EffectiveDateTime
			,s.Cost
			,s.Retail);
--**************************************************************
update t set TransactionStatus = case when transactionstatus = 0 then 2
else 0 end --@loadstatus
	,LastUpdateUserID = @MyID
	,DateTimeLastUpdate = GETDATE()
	from #tempWarehouseTransaction2 tmp
inner join [dbo].[WarehouseTransactions] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID


if @@ERROR = 0
	commit transaction
else
	rollback transaction
	
return
GO
