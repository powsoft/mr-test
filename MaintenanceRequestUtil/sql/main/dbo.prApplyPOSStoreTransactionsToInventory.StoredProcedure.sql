USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prApplyPOSStoreTransactionsToInventory]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prApplyPOSStoreTransactionsToInventory]

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
--and TransactionTypeID in (2, 6)
and TransactionTypeID in (2, 6, 7, 16)
--and CostMisMatch = 0
--and RetailMisMatch = 0
and RuleCost is not null
--and TrueCost is not null
--and SupplierID in (40557, 40562, 40561)
--and cast(SaleDateTime as date) = '12/1/2011'
and CAST(Saledatetime as date) >= '12/1/2011'
--and StoreID = 41340
--and ProductID = 5135
--and SaleDateTime > '11/29/2011'

begin transaction

/*
waitfor delay '0:0:5'
delete from cdc.dbo_StoreTransactions_CT
where StoreTransactionID in (select StoreTransactionID from #tempStoreTransaction)
*/

set @loadstatus = 2

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
	--,EffectiveDateTime = case when s.EffectiveDateTime > i.EffectiveDateTime then s.EffectiveDateTime else i.EffectiveDateTime end
	--,Cost = 
	--	case when S.Qty < 0 then ((s.Cost * abs(s.Qty)) + (i.Cost * i.CurrentOnHandQty))/(abs(s.Qty) + i.CurrentOnHandQty) else i.Cost end
	--,Retail = 
	--	case when i.CurrentOnHandQty > 0 then ((s.Retail * abs(s.Qty)) + (i.Retail * i.CurrentOnHandQty))/(abs(s.Qty) + i.CurrentOnHandQty) else i.Retail end

	--,Cost = s.Cost
	--,Retail = s.Retail
	--,EffectiveDateTime = s.EffectiveDateTime
	
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
