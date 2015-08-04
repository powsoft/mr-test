USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoiceDetail_ReleaseStoreTransactions_SUP_ACH_Debug]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prInvoiceDetail_ReleaseStoreTransactions_SUP_ACH_Debug]

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
from StoreTransactions
where 1 = 1
--and chainid = 44285
and SupplierID in 
(
50731,51068
	--Select SupplierID 
	--From Suppliers s
	--inner join DataTrue_EDI.dbo.ProcessStatus_ACH p
	--	on p.SupplierName = s.ediname
	--Where BillingIsRunning = 1
	--and BillingComplete = 0
	--and CAST([date] as date) = CAST(getdate() as date)
)
and TransactionStatus in (0, 2)
and TransactionTypeID in (5,8)
and InvoiceBatchID is null
and Qty <> 0
and RuleCost is not null
and RuleRetail is not null
and RuleCost <> 0
/*
(
(TransactionStatus = 2 and TransactionTypeID not in (10,11))
or
(TransactionStatus = 0 and TransactionTypeID in (2,4,5,6,7,8,9,14,16,17,18,19,20,21,22,23))
)
--select top 22000 * from storetransactions order by storetransactionid desc
*/
--***************************Look for Multiple Instances***************************************
declare @recremovedupes cursor
declare @reconeassignmentsaledate cursor
declare @remtransactionid bigint
declare @remstoreid int
declare @remproductid int
declare @rembrandid int
declare @remsaledate date
declare @curstoreid int
declare @curproductid int
declare @curbrandid int
declare @cursaledate date
declare @firstrowpassed bit
declare @transactiontypeid int
declare @storetransactionid bigint
declare @reportedcostcompare money
declare @setupcostcompare money
declare @rulecostcompare money
declare @rulecosthold money
declare @setupcosthold money
declare @reportedcosthold money
declare @truecostcompare money
declare @rulecostdiffers bit
declare @reportedcostdiffers bit
declare @costdifferenceresolved bit



--begin transaction

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
			@job_name = 'Billing_Regulated'
			
		Update 	DataTrue_Main.dbo.JobRunning
		Set JobIsRunningNow = 0
		Where JobName = 'DailyRegulatedBilling'		

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated Job Stopped'
			,'An exception occurred in prInvoiceDetail_ReleaseStoreTransactions_SUP_ACH.  Manual review, resolution, and re-start will be required for the job to continue.'
			,'DataTrue System', 0, 'vince.moore@icontroldsd.com'--'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
		
end catch
GO
