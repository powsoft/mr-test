USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoiceDetail_ReleaseStoreTransactions_Newspapers_WithStoreTransIDView]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prInvoiceDetail_ReleaseStoreTransactions_Newspapers_WithStoreTransIDView]

As

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @MyID int

set @MyID = 24134

begin try 

update t set t.supplierid = s.supplierid
--select *
from StoreTransactions t
inner join storesetup s
on t.StoreID = s.StoreID
and t.ProductID = s.ProductID
and CAST(t.saledatetime as date) between s.ActiveStartDate and s.ActiveLastDate
and t.SupplierID = 0
and t.ChainID in (select EntityIDToInclude  
					from ProcessStepEntities 
					where ProcessStepName = 'prGetInboundPOSTransactions_Newspapers')


update t set t.rulecost = s.UnitPrice, t.RuleRetail = s.UnitRetail
--select *
from StoreTransactions t
inner join productprices s
on t.StoreID = s.StoreID
and t.ProductID = s.ProductID
and t.SupplierID = s.supplierid
and CAST(t.saledatetime as date) between s.ActiveStartDate and s.ActiveLastDate
and s.ProductPriceTypeID = 3
and t.RuleCost is null
and t.ChainID in (select EntityIDToInclude  
					from ProcessStepEntities 
					where ProcessStepName = 'prGetInboundPOSTransactions_Newspapers')

begin transaction

select StoreTransactionID 
into #tempStoreTransactions 
--select *
--update t set rulecost = reportedcost 
from StoreTransactions t
where 1 = 1
and ChainID in (select EntityIDToInclude  
					from ProcessStepEntities 
					where ProcessStepName = 'prGetInboundPOSTransactions_Newspapers')
and TransactionTypeID in (2, 6)
and Qty <> 0
and InvoiceBatchID is null
and RuleCost is not null
and RuleRetail is not null
and RuleCost <> 0
and Isnull(StoreID,0) <> 0
and Isnull(ProductID,0) <> 0
and Isnull(SupplierID,0) <> 0


update t
set transactionstatus = case when transactionstatus = 2 then 800 else 801 end
from  StoreTransactions t
inner join [dbo].[GetStoreTrans_Main] tmp
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
