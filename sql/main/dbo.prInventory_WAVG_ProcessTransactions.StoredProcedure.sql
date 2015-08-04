USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInventory_WAVG_ProcessTransactions]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prInventory_WAVG_ProcessTransactions]

as

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @MyID int
set @MyID = 0

declare @rec cursor
declare @transactionid bigint
declare @storeid int
declare @productid int
declare @brandid int
declare @rec1qty int
declare @rec1cost money
declare @rec1availableqty int
declare @saledate date
declare @inventorycostid int
declare @receivedatthiscostdate datetime
declare @nextinventorycostid int
declare @lastinventorycostid int
declare @nextcost money
declare @nextqtyavailable int
declare @nextMaxQtyAvailableAtThisCost int
declare @updatenextinventoryrecordasactive tinyint
declare @transactionidtoupdate bigint

begin try

begin transaction

--drop table #tempStoreTransaction
--delivery records
select distinct StoreTransactionID
into #tempStoreTransaction
--select *
--update t set transactionstatus = 812
from [dbo].[StoreTransactions] t
--inner join StoreSetup ss
--on t.storeid = ss.storeid
--and t.productid = ss.productid
--and t.brandid = ss.brandid
where TransactionStatus in (0, 811)
--and TransactionTypeID in (2,6,7,16)
--and TransactionTypeID not in (11)
and TransactionTypeID in (2,6,7,16,17,18,22)
--and CostMisMatch = 0
--and RetailMisMatch = 0
and RuleCost is not null
and Qty <> 0
--and t.saledatetime between ss.ActiveStartDate and ss.ActiveLastDate
--and ss.InventoryCostMethod in ('FIFO', 'WAVG')
and cast(t.SaleDateTime as date) >= '12/1/2011'
--and t.SupplierID in (40557, 40562, 40561)
and t.SupplierID in --(40562, 40561, 40558, 40557, 41464, 41465, 40559, 41440, 40569)
(select supplierid from Suppliers where InventoryIsActive = 1)
--and ss.ChainID = 40393


	
update t
set t.InventoryCost = cost
from #tempStoreTransaction tmp
inner join StoreTransactions t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join InventoryPerpetual p
on t.storeid = p.storeid
and t.productid = p.productid
and t.brandid = p.brandid
where t.InventoryCost is null

update t
set t.InventoryCost = rulecost
from #tempStoreTransaction tmp
inner join StoreTransactions t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.InventoryCost is null

update t set TransactionStatus = case when transactionstatus = 0 then 1 else 11 end
	,LastUpdateUserID = @MyID
	,DateTimeLastUpdate = GETDATE()
	from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions] t
on tmp.StoreTransactionID = t.StoreTransactionID



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
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;edi@icontroldsd.com;mandeep@amebasoftwares.com'	
end catch
GO
