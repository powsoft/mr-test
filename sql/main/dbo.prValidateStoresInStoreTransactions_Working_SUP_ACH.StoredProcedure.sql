USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateStoresInStoreTransactions_Working_SUP_ACH]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateStoresInStoreTransactions_Working_SUP_ACH]

as

declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 53828

begin try

DECLARE @ProcessID INT

SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobName = 'DailyRegulatedBilling'

DECLARE @tempStoreTransaction TABLE
(
	StoreTransactionID INT,
	ChainIdentifier VARCHAR(120),
	StoreIdentifier VARCHAR(120)
);

--select distinct StoreTransactionID, ChainIdentifier, StoreIdentifier
--into @tempStoreTransaction
insert into @tempStoreTransaction (StoreTransactionID, ChainIdentifier, StoreIdentifier)
--select LEFT(Banner , CHARINDEX('#',Banner)-2), Banner as BNR, workingstatus as status, *
--select Banner as BNR, *
select distinct StoreTransactionID, ChainIdentifier, StoreIdentifier
from [dbo].[StoreTransactions_Working]
where WorkingStatus = 0
and WorkingSource in ('SUP-S', 'SUP-U', 'SUP-X')
--and EDIName in (select EDIName from Suppliers where IsRegulated = 1 and EDIName is not null)
and ProcessID = @ProcessID

--no point to continuing if there are no records
If (Select count(StoreTransactionID) From @tempStoreTransaction) < 1
Begin
	--VM 05/29/2013
		exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'Billing_Regulated_NewInvoiceData'
			
		Update 	DataTrue_Main.dbo.JobRunning
		Set JobIsRunningNow = 0
		Where JobName = 'DailyRegulatedBilling'	

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated Job Stopped'
				,'No valid transactions Found in prValidateStoresInStoreTransactions_Working_SUP_ACH.'
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'--'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
		--End VM
	return;
End

--begin transaction

set @loadstatus = 1

update t set t.WorkingStatus = -1
from [dbo].[StoreTransactions_Working] t
inner join @tempStoreTransaction tmp
on t.StoreTransactionID = tmp.StoreTransactionID
where WorkingStatus = 0
and WorkingSource in ('SUP-X')

if @@ROWCOUNT > 0
	begin

		set @errormessage = 'Unknown Supplier Transactions Types Found'
		set @errorlocation = 'prValidateStoresInStoreTransactions_Working_SUP'
		set @errorsenderstring = 'prValidateStoresInStoreTransactions_Working_SUP'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
		exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'Billing_Regulated_NewInvoiceData'
		
		--VM 05/29/2013
		--exec [msdb].[dbo].[sp_stop_job] 
		--	@job_name = 'Billing_Regulated'
			
		--Update 	DataTrue_Main.dbo.JobRunning
		--Set JobIsRunningNow = 0
		--Where JobName = 'DailyRegulatedBilling'	

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated_NewInvoiceData Job Stopped'
				,'Unknown Supplier Transactions Types Found in prValidateStoresInStoreTransactions_Working_SUP_ACH.'
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'--'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
		--End VM
		
	end


update storetransactions_working 
set EDIBanner = LTRIM(rtrim(chainidentifier))
where 1 = 1
and workingstatus = 0
and workingsource in ('SUP-S', 'SUP-U')
--and EDIName in(select EDIName from Suppliers where IsRegulated = 1 and EDIName is not null
	--Select SupplierName 
	--From DataTrue_EDI.dbo.ProcessStatus_ACH 
	--Where BillingIsRunning = 1
	--and BillingComplete = 0
	--)
and EDIBanner is null
and ProcessID = @ProcessID
	
update t set t.ChainID = c.ChainID
from @tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Chains] c
on t.ChainIdentifier = c.ChainIdentifier

update t set t.WorkingStatus = -1
from [dbo].[StoreTransactions_Working] t
inner join @tempStoreTransaction tmp
on t.StoreTransactionID = tmp.StoreTransactionID
where WorkingStatus = 0
and ChainID is null
if @@ROWCOUNT > 0
	begin

		--declare @errormessage varchar(4500)
		--declare @errorlocation varchar(255)

		set @errormessage = 'Unknown Chain Identifiers Found'
		set @errorlocation = 'prValidateStoresInStoreTransactions_Working_SUP'
		set @errorsenderstring = 'prValidateStoresInStoreTransactions_Working_SUP'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
		--VM 05/29/2013
		exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'Billing_Regulated_NewInvoiceData'
			
		Update 	DataTrue_Main.dbo.JobRunning
		Set JobIsRunningNow = 0
		Where JobName = 'DailyRegulatedBilling'	

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated Job Stopped'
				,'Unknown Chain Identifiers Found in prValidateStoresInStoreTransactions_Working_SUP_ACH.'
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'--'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
		--End VM
		
	end

update t set t.WorkingStatus = -1
from [dbo].[StoreTransactions_Working] t
inner join @tempStoreTransaction tmp
on t.StoreTransactionID = tmp.StoreTransactionID
where WorkingStatus = 0
and StoreID is null
and ISNUMERIC(t.StoreIdentifier) < 1

if @@ROWCOUNT > 0
	begin

		--declare @errormessage varchar(4500)
		--declare @errorlocation varchar(255)

		set @errormessage = 'Invalid Store Identifiers Found'
		set @errorlocation = 'prValidateStoresInStoreTransactions_Working_SUP'
		set @errorsenderstring = 'prValidateStoresInStoreTransactions_Working_SUP'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
		--VM 05/29/2013
		exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'Billing_Regulated_NewInvoiceData'
			
		Update 	DataTrue_Main.dbo.JobRunning
		Set JobIsRunningNow = 0
		Where JobName = 'DailyRegulatedBilling'	

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated Job Stopped'
				,'Invalid Store Identifiers Found in prValidateStoresInStoreTransactions_Working_SUP_ACH.'
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'--'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
		--End VM
		
	end

update t set t.StoreID = s.StoreID
from @tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Stores] s
on t.ChainID = s.ChainID 
and cast(t.StoreIdentifier as int) = cast(s.StoreIdentifier as int)
and ltrim(rtrim(s.Custom3)) = ltrim(rtrim(EDIBanner))
where 1 = 1
and WorkingStatus = 0
and workingsource in ('SUP-S', 'SUP-U')
and t.StoreID is null

update t set t.WorkingStatus = -1
from [dbo].[StoreTransactions_Working] t
inner join @tempStoreTransaction tmp
on t.StoreTransactionID = tmp.StoreTransactionID
where WorkingStatus = 0
and StoreID is null

if @@ROWCOUNT > 0
	begin

		--declare @errormessage varchar(4500)
		--declare @errorlocation varchar(255)

		set @errormessage = 'Unknown Store Identifiers Found'
		set @errorlocation = 'prValidateStoresInStoreTransactions_Working_SUP'
		set @errorsenderstring = 'prValidateStoresInStoreTransactions_Working_SUP'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
		--VM 05/29/2013
		exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'Billing_Regulated_NewInvoiceData'
			
		Update 	DataTrue_Main.dbo.JobRunning
		Set JobIsRunningNow = 0
		Where JobName = 'DailyRegulatedBilling'	

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated Job Stopped'
				,'Unknown Store Identifiers Found in prValidateStoresInStoreTransactions_Working_SUP_ACH.'
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'--'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
		--End VM
	end


--update t set t.UnAuthorizedAssignment = 0
--from @tempStoreTransaction tmp
--inner join [dbo].[StoreTransactions_Working] t
--on tmp.StoreTransactionID = t.StoreTransactionID
--inner join [dbo].[StoreSetup] s
--on t.StoreID = s.StoreID
--and t.SupplierID = s.SupplierID
--and t.SaleDateTime between s.ActiveStartDate and s.ActiveLastDate

--update t set t.UnAuthorizedAssignment = 1
--from @tempStoreTransaction tmp
--inner join [dbo].[StoreTransactions_Working] t
--on tmp.StoreTransactionID = t.StoreTransactionID
--and t.UnAuthorizedAssignment is null

--commit transaction
	
end try
	
begin catch

		rollback transaction
		
		set @loadstatus = -9998
		
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
			@job_name = 'Billing_Regulated_NewInvoiceData'
			
		--exec [msdb].[dbo].[sp_stop_job] 
		--	@job_name = 'Billing_Regulated'
			
		--Update 	DataTrue_Main.dbo.JobRunning
		--Set JobIsRunningNow = 0
		--Where JobName = 'DailyRegulatedBilling'	

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated_NewInvoiceData Job Stopped'
				,'An exception was encountered in prValidateStoresInStoreTransactions_Working_SUP_ACH.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'--'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
		
end catch
	
update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID
from @tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.WorkingStatus = 0

	
return
GO
