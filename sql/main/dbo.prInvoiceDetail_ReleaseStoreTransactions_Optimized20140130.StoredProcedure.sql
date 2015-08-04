USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoiceDetail_ReleaseStoreTransactions_Optimized20140130]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prInvoiceDetail_ReleaseStoreTransactions_Optimized20140130]

As
/*
select distinct sourceid from storetransactions order by sourceid desc
*/
declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @MyID int

set @MyID = 24134

begin try 

begin transaction

select StoreTransactionID 
into #tempStoreTransactions 
--select *
--select count(storetransactionid)
--update t set rulecost = reportedcost 
from StoreTransactions t
where 1 = 1
--and ChainID
and CAST(DateTimeCreated as date) >= DATEADD(day, -30, getdate()) 
and ChainID in (select [EntityIDToInclude] from ProcessStepEntities where ProcessStepName = 'prInvoiceDetail_ReleaseStoreTransactions')
and TransactionStatus in (0, 2)
and TransactionTypeID in (2,6)
--and SourceID in (1466) --1379, 1380, 1383)
and CAST(saledatetime as date) >= '1/1/2013'
and Qty <> 0
and InvoiceBatchID is null
and RuleRetail is not null
and isnull(RuleCost,0) <> 0
and Isnull(StoreID,0) <> 0
and Isnull(ProductID,0) <> 0
and Isnull(SupplierID,0) <> 0


update t
set transactionstatus = case when transactionstatus = 2 then 800 else 801 end
from  StoreTransactions t
inner join #tempStoreTransactions tmp
on t.StoreTransactionID = tmp.StoreTransactionID
where TransactionStatus <> -801
and 
(
(TransactionStatus = 2 and TransactionTypeID not in (10,11))
or
(TransactionStatus = 0 and TransactionTypeID in (2,4,5,6,7,8,9,14,16,17,18,19,20,21,22,23))
)     
     
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
			@job_name = 'DailyPOSBilling_THIS_IS_CURRENT_ONE'

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Daily Billing Job Stopped'
				,'Retailer and supplier invoicing has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;edi@icontroldsd.com'		
		
end catch
GO
