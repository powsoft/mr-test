USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prApplyPOSStoreTransactionsToInventory_NOMERGE]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prApplyPOSStoreTransactionsToInventory_NOMERGE]

as

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 7591

begin try

select distinct StoreTransactionID
into #tempStoreTransaction
--select *
from [dbo].[StoreTransactions]
where TransactionStatus in (1, 11)
and TransactionTypeID in (2, 6, 7, 16)
and RuleCost is not null
and CAST(Saledatetime as date) >= '12/1/2011'

begin transaction


set @loadstatus = 2

declare @tempStoreTransactions table(ChainID int,StoreID int,ProductID int,BrandID int);


update i set  i.SBTSales = i.SBTSales + s.Qty
	,i.CurrentOnHandQty = i.CurrentOnHandQty - s.Qty 
	,i.LastUpdateUserID = @MyID
	,i.DateTimeLastUpdate = getdate()
	output inserted.ChainID,inserted.StoreID,inserted.ProductID,inserted.BrandID
	into @tempStoreTransactions
from InventoryPerpetual i
join (Select [ChainID]
	  ,[StoreID]
      ,[ProductID]
      ,[BrandID]
      ,max([RuleCost]) as Cost
      ,max(isnull([RuleRetail],0)) as Retail
      ,sum([Qty]) as Qty
      ,max(SaleDateTime) as EffectiveDateTime
  FROM [dbo].[StoreTransactions] t
  inner join #tempStoreTransaction tmp
	on t.StoreTransactionID = tmp.StoreTransactionID
	group by t.chainid, t.storeid, t.productid, t.brandid) s
	on i.ChainID = s.ChainID
	and i.StoreID = s.StoreID 
	and i.ProductID = s.ProductID
	and i.BrandID = s.BrandID

	INSERT into InventoryPerpetual
           ([ChainID], [StoreID]
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
		 Select t.[ChainID]
		  ,t.[StoreID]
		  ,t.[ProductID]
		  ,t.[BrandID]
		  ,0
		  ,0
		  ,sum(t.[Qty]) as Qty
		  ,0
		  ,0 - t.Qty
		  ,@MyID
		  ,GETDATE()
		  ,max(SaleDateTime) as EffectiveDateTime
		  ,max([RuleCost]) as Cost
		  ,max(isnull([RuleRetail],0)) as Retail
	FROM [dbo].[StoreTransactions] t
	inner join #tempStoreTransaction tmp
	on t.StoreTransactionID = tmp.StoreTransactionID
	left join @tempStoreTransactions s on
	t.ChainID=s.ChainID
	and t.StoreID=s.StoreID
	and t.BrandID=s.BrandID
	and t.ProductID=s.ProductID
	Where s.ChainID is null
	group by t.chainid, t.storeid, t.productid, t.brandid 


/*
--**************************************************************
MERGE INTO [dbo].[InventoryPerpetual] i

USING (SELECT [ChainID], [StoreID]
      ,[ProductID]
      ,[BrandID]
      ,max([RuleCost]) as Cost
      --,max([TrueCost]) as Cost
      ,max(isnull([RuleRetail],0)) as Retail
      ,sum([Qty]) as Qty
      ,max(SaleDateTime) as EffectiveDateTime
  FROM [dbo].[StoreTransactions] t
  inner join #tempStoreTransaction tmp
	on t.StoreTransactionID = tmp.StoreTransactionID
	group by t.chainid, t.storeid, t.productid, t.brandid) S
	on i.ChainID = s.ChainID
	and i.StoreID = s.StoreID 
	and i.ProductID = s.ProductID
	and i.BrandID = s.BrandID

WHEN MATCHED THEN

update set  SBTSales = SBTSales + S.Qty
	,CurrentOnHandQty = CurrentOnHandQty - s.Qty 
	,LastUpdateUserID = @MyID
	,DateTimeLastUpdate = getdate()
	
WHEN NOT MATCHED 

THEN INSERT 
           ([ChainID], [StoreID]
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
           (s.[ChainID], s.[StoreID]
			,s.[ProductID]
			,s.[BrandID]
			,0
			,0
			,s.[Qty]
			,0
			,0 - s.[Qty]
			,@MyID
			,getdate()
			,s.EffectiveDateTime
			,s.Cost
			,s.Retail);
--**************************************************************
*/

commit transaction
	
end try
	
begin catch
		rollback transaction
		
		set @loadstatus = -9999
		

		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
end catch
	


update t set TransactionStatus = case when @loadstatus = -9999 then -9999
									when @loadstatus <> -9999 and transactionstatus = 1 then 2 
									else 810 end --@loadstatus
	,LastUpdateUserID = @MyID
	,DateTimeLastUpdate = GETDATE()
	from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions] t
on tmp.StoreTransactionID = t.StoreTransactionID


return
GO
