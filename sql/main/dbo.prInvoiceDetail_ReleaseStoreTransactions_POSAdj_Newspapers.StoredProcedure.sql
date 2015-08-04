USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoiceDetail_ReleaseStoreTransactions_POSAdj_Newspapers]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prInvoiceDetail_ReleaseStoreTransactions_POSAdj_Newspapers]

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
--update t set rulecost = reportedcost 
from StoreTransactions t
where 1 = 1
--and ChainID in (60624,74628) --60624) --64010) --62362)--select EntityIDToInclude from ProcessStepEntities where ProcessStepName In ('prInvoiceDetail_ReleaseStoreTransactions_Newspapers', 'prInvoiceDetail_ReleaseStoreTransactions_PDI_Newspapers')) 
--and t.ChainID in (select EntityIDToInclude from ProcessStepEntities where ltrim(rtrim(ProcessStepName)) in ('prUtil_Price_Corrections_Adjustments_Newspapers','prGetInboundPOSTransactions_Newspapers','prGetInboundPOSTransactions_PDI_Newspapers'))
and TransactionTypeID in (7,16)
and ProductID in (select ProductID from ProductIdentifiers where ProductIdentifierTypeID = 8)
--and TransactionTypeID in (16)
and Qty <> 0
and InvoiceBatchID is null
and RuleCost is not null
and RuleRetail is not null
and RuleCost <> 0
and Isnull(StoreID,0) <> 0
and Isnull(ProductID,0) <> 0
--and SupplierID in (24209) --28722, 34884)
and CAST(datetimecreated as date) = CAST(GETDATE() as date)
--and CAST(datetimecreated as date) >= '7/13/2014'
--and Isnull(SupplierID,0) <> 0
--and productid = 37905 --37390 --37906 --41320
--and storeid = 62401
--and cast(saledatetime as date) = '7/14/2014'
order by saledatetime, StoreID, productid
--select * from chains where chainid = 74628

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
				,'DataTrue System', 0, 'datatrueit@icontroldsd.com'		
		
end catch
GO
