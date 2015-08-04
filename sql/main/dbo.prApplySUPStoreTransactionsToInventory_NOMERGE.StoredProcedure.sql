USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prApplySUPStoreTransactionsToInventory_NOMERGE]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prApplySUPStoreTransactionsToInventory_NOMERGE]

as

declare @MyID int
set @MyID = 7592

begin transaction

--delivery records
select distinct StoreTransactionID
into #tempStoreTransaction
--select *
from [dbo].[StoreTransactions]
where TransactionStatus in (0, 1, 811)
and TransactionTypeID in (4,5,20)
and RuleCost is not null
and CAST(Saledatetime as date) >= '12/1/2011'
and SupplierID in (select SupplierID from Suppliers
where InventoryIsActive=1)
--InventoryIsActive bit default 0 on 71 box


--**************************************************************
	Declare @tempStoreTransactions table(ChainID int,StoreID int,BrandID int, ProductID int);
	
	update i set 
	i.Deliveries = i.Deliveries + s.Qty
	,i.CurrentOnHandQty = i.CurrentOnHandQty + s.Qty 
	,i.LastUpdateUserID = @MyID
	,i.DateTimeLastUpdate = getdate()
	,i.EffectiveDateTime = case when s.EffectiveDateTime > i.EffectiveDateTime 
				then s.EffectiveDateTime else i.EffectiveDateTime end
	,i.Cost = case when i.CurrentOnHandQty > 0 then 
		((s.Cost * s.Qty) + (i.Cost * i.CurrentOnHandQty))/(s.Qty + i.CurrentOnHandQty) else s.Cost end
	,i.Retail = case when i.CurrentOnHandQty > 0 then 
		((s.Retail * s.Qty) + (i.Retail * i.CurrentOnHandQty))/(s.Qty + i.CurrentOnHandQty) else s.Retail end
	OUTPUT inserted.ChainID,inserted.StoreID,inserted.BrandID,inserted.ProductID 
	into  @tempStoreTransactions
	from InventoryPerpetual i join 
	(SELECT [ChainID]
	  ,[StoreID]
      ,[ProductID]
      ,[BrandID]
      ,sum([Qty]) as Qty
      ,max([RuleCost]) as Cost
      ,max(isnull([RuleRetail], 0.00)) as Retail
      ,max([SaleDateTime]) as EffectiveDateTime
  FROM [dbo].[StoreTransactions] t
  inner join #tempStoreTransaction tmp
	on t.StoreTransactionID = tmp.StoreTransactionID
	group by t.chainid, t.storeid, t.productid, t.brandid) s
	on i.ChainID = s.ChainID
	and i.StoreID = s.StoreID 
	and i.ProductID = s.ProductID
	and i.BrandID = s.BrandID


	INSERT  into InventoryPerpetual
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
           ,[EffectiveDateTime]
           ,[Cost]
           ,[Retail])
     SELECT	t.[ChainID]
		  ,t.[StoreID]
		  ,t.[ProductID]
		  ,t.[BrandID]
		  ,0
		  ,sum([Qty]) as Qty
		  ,0
		  ,0
		  ,sum([Qty])
		  ,@MyID
		  ,getdate()
		  ,max([SaleDateTime]) as EffectiveDateTime
		  ,max([RuleCost]) as Cost
		  ,max(isnull([RuleRetail], 0.00)) as Retail
	FROM [dbo].[StoreTransactions] t
	inner join #tempStoreTransaction tmp
	on t.StoreTransactionID = tmp.StoreTransactionID
	left join @tempStoreTransactions s 
	on t.ChainID=s.ChainID
	and t.StoreID=s.StoreID
	and t.BrandID=s.BrandID
	and t.ProductID=s.ProductID
	where s.ChainID is null
	group by t.chainid, t.storeid, t.productid, t.brandid


--**************************************************************
/*
--**************************************************************
MERGE INTO [dbo].[InventoryPerpetual] i

USING (SELECT [ChainID]
	  ,[StoreID]
      ,[ProductID]
      ,[BrandID]
      ,sum([Qty]) as Qty
      ,max([RuleCost]) as Cost
      ,max(isnull([RuleRetail], 0.00)) as Retail
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
	,Cost = 
		case when i.CurrentOnHandQty > 0 then ((s.Cost * s.Qty) + (i.Cost * i.CurrentOnHandQty))/(s.Qty + i.CurrentOnHandQty) else s.Cost end
	,Retail = 
		case when i.CurrentOnHandQty > 0 then ((s.Retail * s.Qty) + (i.Retail * i.CurrentOnHandQty))/(s.Qty + i.CurrentOnHandQty) else s.Retail end

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
           ,[EffectiveDateTime]
           ,[Cost]
           ,[Retail])
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
			,s.EffectiveDateTime
			,s.Cost
			,s.Retail);
--**************************************************************
*/
update t set TransactionStatus = case when transactionstatus = 0 then 2 
when transactionstatus = 1 then 2 
									else 810 end --@loadstatus
	,LastUpdateUserID = @MyID
	,DateTimeLastUpdate = GETDATE()
	from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions] t
on tmp.StoreTransactionID = t.StoreTransactionID



--delivery records
select distinct StoreTransactionID
into #tempStoreTransaction3
--select *
from [dbo].[StoreTransactions]
where TransactionStatus in (0, 1, 811)
--where TransactionStatus in (1, 11)
and TransactionTypeID in (9)
and RuleCost is not null
--and CostMisMatch = 0
--and RetailMisMatch = 0
--and TrueCost is not null
and CAST(Saledatetime as date) >= '12/1/2011'
and SupplierID in (40558, 40562, 40561, 40557, 41464, 41465, 40559)
--**************************************************************
	Declare @tempStoreTransactions1 table(ChainID int,StoreID int,BrandID int,ProductID int);
	
	update i set 
		i.Deliveries = i.Deliveries + s.Qty
		,i.CurrentOnHandQty = i.CurrentOnHandQty + s.Qty 
		,i.LastUpdateUserID = @MyID
		,i.DateTimeLastUpdate = getdate()
		,i.EffectiveDateTime = case when s.EffectiveDateTime > i.EffectiveDateTime then s.EffectiveDateTime else i.EffectiveDateTime end
	OUTPUT inserted.ChainID,inserted.StoreID,inserted.BrandID,inserted.ProductID
	into @tempStoreTransactions1
	from InventoryPerpetual i
	join (SELECT [ChainID]
	  ,[StoreID]
      ,[ProductID]
      ,[BrandID]
      ,sum([Qty]) as Qty
      ,max([RuleCost]) as Cost
      ,max(isnull([RuleRetail], 0.00)) as Retail
      ,max([SaleDateTime]) as EffectiveDateTime
  FROM [dbo].[StoreTransactions] t
  inner join #tempStoreTransaction3 tmp
	on t.StoreTransactionID = tmp.StoreTransactionID
	group by t.chainid, t.storeid, t.productid, t.brandid) s
	on i.ChainID = s.ChainID
	and i.StoreID = s.StoreID 
	and i.ProductID = s.ProductID
	and i.BrandID = s.BrandID


	INSERT into InventoryPerpetual
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
           ,[EffectiveDateTime]
           ,[Cost]
           ,[Retail])
     SELECT t.[ChainID]
	  ,t.[StoreID]
      ,t.[ProductID]
      ,t.[BrandID]
      ,0
      ,sum([Qty]) as Qty
      ,0
      ,0
      ,SUM(QTY) 
      ,@MyID
      ,GETDATE()
      ,max([SaleDateTime]) as EffectiveDateTime
      ,max([RuleCost]) as Cost
      ,max(isnull([RuleRetail], 0.00)) as Retail
	FROM [dbo].[StoreTransactions] t
    inner join #tempStoreTransaction3 tmp
	on t.StoreTransactionID = tmp.StoreTransactionID
	left join @tempStoreTransactions1 s
	on t.ChainID=s.ChainID
	and t.StoreID=s.StoreID
	and t.BrandID=s.BrandID
	and t.ProductID=s.ProductID
	group by t.chainid, t.storeid, t.productid, t.brandid
--**************************************************************
/*
--**************************************************************
MERGE INTO [dbo].[InventoryPerpetual] i

USING (SELECT [ChainID]
	  ,[StoreID]
      ,[ProductID]
      ,[BrandID]
      ,sum([Qty]) as Qty
      ,max([RuleCost]) as Cost
      ,max(isnull([RuleRetail], 0.00)) as Retail
      ,max([SaleDateTime]) as EffectiveDateTime
  FROM [dbo].[StoreTransactions] t
  inner join #tempStoreTransaction3 tmp
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
           ,[EffectiveDateTime]
           ,[Cost]
           ,[Retail])
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
			,s.EffectiveDateTime
			,s.Cost
			,s.Retail);
--**************************************************************
*/
update t set TransactionStatus = case when transactionstatus = 0 then 2 
when transactionstatus = 1 then 2 
									else 810 end --@loadstatus
	,LastUpdateUserID = @MyID
	,DateTimeLastUpdate = GETDATE()
	from #tempStoreTransaction3 tmp
inner join [dbo].[StoreTransactions] t
on tmp.StoreTransactionID = t.StoreTransactionID

--waitfor delay '0:0:5'

--exec DataTrue_Report..prCDCGetINVStoreTransactions

--pickup records
select distinct StoreTransactionID
into #tempStoreTransaction2
--select *
from [dbo].[StoreTransactions]
where TransactionStatus in (0, 1, 811)
--where TransactionStatus in (1, 11)
and TransactionTypeID in (8,13,14,21)
and RuleCost is not null
--and CostMisMatch = 0
--and RetailMisMatch = 0
--and TrueCost is not null
and CAST(Saledatetime as date) >= '12/1/2011'
--and SupplierID in (40561)
and SupplierID in (40558, 40562, 40561, 40557, 41464, 41465, 40559)
--**************************************************************
MERGE INTO [dbo].[InventoryPerpetual] i

USING (SELECT [ChainID]
	  ,[StoreID]
      ,[ProductID]
      ,[BrandID]
      ,sum([Qty]) as Qty
      ,max([RuleCost]) as Cost
      ,max(isnull([RuleRetail], 0.00)) as Retail
      ,max([SaleDateTime]) as EffectiveDateTime
  FROM [dbo].[StoreTransactions] t
  inner join #tempStoreTransaction2 tmp
	on t.StoreTransactionID = tmp.StoreTransactionID
	group by t.chainid, t.storeid, t.productid, t.brandid) S
	on i.ChainID = s.ChainID
	and i.StoreID = s.StoreID 
	and i.ProductID = s.ProductID
	and i.BrandID = s.BrandID

WHEN MATCHED THEN

update set  Pickups = Pickups + S.Qty
	,CurrentOnHandQty = CurrentOnHandQty - s.Qty 
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
           ,s.[StoreID]
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
when transactionstatus = 1 then 2  
									else 810 end --@loadstatus
	,LastUpdateUserID = @MyID
	,DateTimeLastUpdate = GETDATE()
	from #tempStoreTransaction2 tmp
inner join [dbo].[StoreTransactions] t
on tmp.StoreTransactionID = t.StoreTransactionID

--waitfor delay '0:0:5'

--exec DataTrue_Report..prCDCGetINVStoreTransactions


if @@ERROR = 0
	commit transaction
else
	rollback transaction


/*
select * into import.dbo.inventoryperpetual_BeforeGopherSync_20120126 from inventoryperpetual

select storeid, productid
--select *
from storetransactions
where supplierid = 40558
and transactiontypeid = 11

select t.qty, p.originalqty, p.*
--update p set p.originalqty = t.qty
from inventoryperpetual p
inner join
(
select storeid, productid, qty
from storetransactions
where supplierid = 40558
and transactiontypeid = 11
) t
on p.storeid = t.storeid
and p.productid = t.productid
where t.qty <> p.originalqty

*/
	
return
GO
