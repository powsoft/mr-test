USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prApplySUPStoreTransactionsToInventoryCost_NOMERGE]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prApplySUPStoreTransactionsToInventoryCost_NOMERGE]

as

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @MyID int
set @MyID = 0

declare @storeid int
declare @productid int
declare @brandid int
declare @inventorycostid int
declare @receivedatthiscostdate datetime
declare @nextinventorycostid int
declare @lastinventorycostid int
declare @nextcost money
declare @nextqtyavailable int
declare @nextMaxQtyAvailableAtThisCost int
declare @MaxQtyAvailableAtThisCostAtZeroQty int
declare @updatenextinventoryrecordasactive tinyint
declare @transactionidtoupdate bigint
declare @rec cursor
declare @rec1qty int

begin try

--exec prInventoryCost_NewRecords_Collapse
exec prInventoryCost_ActiveCost_Sync

begin transaction

--delivery records
select distinct StoreTransactionID
into #tempStoreTransaction
--select *
from [dbo].[StoreTransactions]
where TransactionStatus in (0, 811)
and TransactionTypeID in (4,5,8,9,20)
and RuleCost is not null
--and CostMisMatch = 0
--and RetailMisMatch = 0
--and TrueRetail is not null
--and TrueCost is not null
--and InventoryCost is not null
and CAST(Saledatetime as date) >= '12/1/2011'
and SupplierID in (select distinct SupplierID from Suppliers where InventoryIsActive=1)--(40561, 40562, 40558, 40557, 41464, 41465,41440)
--**************************************************************
--select distict SupplierID from Suppliers where InventoryIsActive=1
declare @tempInventoryCost table(ChainID int,StoreID int,ProductID int,BrandID int); --,Cost money,ReceivedAtThisCostDate datetime);

	
	update i set  QtyAvailableAtThisCost =  QtyAvailableAtThisCost + s.Qty
	,MaxQtyAvailableAtThisCost =  MaxQtyAvailableAtThisCost + s.Qty
	,LastUpdateUserID = @MyID
	,DateTimeLastUpdate = getdate()
	output inserted.ChainID,inserted.StoreID,inserted.ProductID,inserted.BrandID
	into @tempInventoryCost
	from [InventoryCost] i
	join (SELECT [ChainID]
			  ,[StoreID]
			  ,[ProductID]
			  ,[BrandID]
			  ,cast([SaleDateTime] as date) as EffectiveDate
			  ,sum(case when transactiontypeid in (8) then [Qty] * -1 else [Qty] end) as Qty
			  ,[RuleCost] as Cost
			  ,max(isnull([RuleRetail], 0.00)) as Retail
			  ,max([SaleDateTime]) as EffectiveDateTime
			  --,transactiontypeid
		  FROM [dbo].[StoreTransactions] t
			  inner join #tempStoreTransaction tmp
				on t.StoreTransactionID = tmp.StoreTransactionID
				--where t.CostMisMatch = 0 and t.RetailMisMatch = 0 and t.InventoryCost is not null
				group by t.chainid, t.storeid, t.productid, t.brandid, t.rulecost, t.saledatetime) s
				on i.ChainID = s.ChainID
				and i.StoreID = s.StoreID 
				and i.ProductID = s.ProductID
				and i.BrandID = s.BrandID
				and i.Cost = s.Cost
				and cast(i.ReceivedAtThisCostDate as date) = cast(s.EffectiveDateTime as date)
			
			
		INSERT into [dbo].[InventoryCost] 
           ([ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[BrandID]
           ,[QtyAvailableAtThisCost]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[ReceivedAtThisCostDate]
           ,[Cost]
           ,[Retail]
           ,[MaxQtyAvailableAtThisCost])
        SELECT t.[ChainID]
		,t.[StoreID]
		,t.[ProductID]
		,t.[BrandID]
		,sum(case when transactiontypeid in (8) then [Qty] * -1 else [Qty] end)
		,@MyID
		,max([SaleDateTime])
		,max([SaleDateTime])
		,[RuleCost] 
		,max(isnull([RuleRetail], 0.00))
		,sum(case when transactiontypeid in (8) then [Qty] * -1 else [Qty] end)
      --,transactiontypeid
	FROM [dbo].[StoreTransactions] t
		inner join #tempStoreTransaction tmp
		on t.StoreTransactionID = tmp.StoreTransactionID
		left join @tempInventoryCost s
		on t.ChainID=s.ChainID
		and t.StoreID=s.StoreID
		and t.BrandID=s.BrandID
		and t.ProductID=s.ProductID
		Where s.ChainID is null
		--where t.CostMisMatch = 0 and t.RetailMisMatch = 0 and t.InventoryCost is not null
		group by t.chainid, t.storeid, t.productid, t.brandid, t.rulecost, t.saledatetime
	


	
--**************************************************************
/*
MERGE INTO [dbo].[InventoryCost] i

USING (SELECT [ChainID]
	  ,[StoreID]
      ,[ProductID]
      ,[BrandID]
      ,cast([SaleDateTime] as date) as EffectiveDate
      ,sum(case when transactiontypeid in (8) then [Qty] * -1 else [Qty] end) as Qty
      ,[RuleCost] as Cost
      ,max(isnull([RuleRetail], 0.00)) as Retail
      ,max([SaleDateTime]) as EffectiveDateTime
      --,transactiontypeid
  FROM [dbo].[StoreTransactions] t
  inner join #tempStoreTransaction tmp
	on t.StoreTransactionID = tmp.StoreTransactionID
	--where t.CostMisMatch = 0 and t.RetailMisMatch = 0 and t.InventoryCost is not null
	group by t.chainid, t.storeid, t.productid, t.brandid, t.rulecost, t.saledatetime) S
	on i.ChainID = s.ChainID
	and i.StoreID = s.StoreID 
	and i.ProductID = s.ProductID
	and i.BrandID = s.BrandID
	and i.Cost = s.Cost
	and cast(i.ReceivedAtThisCostDate as date) = cast(s.EffectiveDateTime as date)

WHEN MATCHED THEN

update set  QtyAvailableAtThisCost =  QtyAvailableAtThisCost + s.Qty
	,MaxQtyAvailableAtThisCost =  MaxQtyAvailableAtThisCost + s.Qty
	,LastUpdateUserID = @MyID
	,DateTimeLastUpdate = getdate()
--	,EffectiveDateTime = case when s.EffectiveDateTime > i.EffectiveDateTime then s.EffectiveDateTime else i.EffectiveDateTime end

	
WHEN NOT MATCHED 

THEN INSERT 
           ([ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[BrandID]
           ,[QtyAvailableAtThisCost]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[ReceivedAtThisCostDate]
           ,[Cost]
           ,[Retail]
           ,[MaxQtyAvailableAtThisCost])
     VALUES
           (s.[ChainID]
           ,s.[StoreID]
			,s.[ProductID]
			,s.[BrandID]
			,s.Qty
			,@MyID
			,s.[EffectiveDateTime] --getdate()
			,s.EffectiveDateTime
			,s.Cost
			,s.Retail
			,s.Qty);
		*/
--**************************************************************
--exec prInventoryCost_NewRecords_Collapse
--exec prInventoryCost_ActiveCost_Sync
--***************************************************************

--***************************************************************
--exec prInventoryCost_NewRecords_Collapse
exec prInventoryCost_ActiveCost_Sync

update t set TransactionStatus = case when transactionstatus = 0 then 1 else 11 end
	,LastUpdateUserID = @MyID
	,DateTimeLastUpdate = GETDATE()
	,Inventorycost = case when costmismatch = 0 and InventoryCost IS null then truecost else InventoryCost end
	from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions] t
on tmp.StoreTransactionID = t.StoreTransactionID
where TransactionStatus not in (1, 11)

		commit transaction
	
end try
	
begin catch
		rollback transaction
		
		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
		exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'DailySUPLoadDeliveriesAndPickups_THIS_IS_CURRENT_ONE'

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Load Deliveries and Pickups Job Stopped'
				,'Deliveries and pickup loading has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;edi@icontroldsd.com'	
end catch
GO
