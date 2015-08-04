USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[ZNU_prApplySUPPickupShrinkReversalToInventory]    Script Date: 06/25/2015 18:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[ZNU_prApplySUPPickupShrinkReversalToInventory]

as

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 24132

begin try

select distinct StoreTransactionID
into #tempStoreTransaction
from [dbo].[StoreTransactions]
where TransactionStatus = 0
and TransactionTypeID in (18)
and CostMisMatch = 0
and RetailMisMatch = 0

begin transaction


set @loadstatus = 1

--**************************************************************
MERGE INTO [dbo].[InventoryPerpetual] i

USING (SELECT [ChainID], [StoreID]
      ,[ProductID]
      ,[BrandID]
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

update set  CurrentOnHandQty = CurrentOnHandQty - s.Qty 
	,LastUpdateUserID = @MyID
	,DateTimeLastUpdate = getdate()
	,EffectiveDateTime = case when s.EffectiveDateTime > i.EffectiveDateTime then s.EffectiveDateTime else i.EffectiveDateTime end
--	,EffectiveDateTime = s.EffectiveDateTime
	
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
           ,[EffectiveDateTime])
     VALUES
           (s.[ChainID], s.[StoreID]
			,s.[ProductID]
			,s.[BrandID]
			,0
			,0
			,0
			,0
			,0 - s.[Qty]
			,@MyID
			,getdate()
			,s.EffectiveDateTime);
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
	


update t set TransactionStatus = @loadstatus
	,LastUpdateUserID = @MyID
	,DateTimeLastUpdate = GETDATE()
	from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions] t
on tmp.StoreTransactionID = t.StoreTransactionID


return
GO
