USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateSuppliersInStoreTransactions_Working_SUP_ACH]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateSuppliersInStoreTransactions_Working_SUP_ACH]

as

declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 7485

begin try

DECLARE @ProcessID INT

SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobName = 'DailyRegulatedBilling'

DECLARE @tempStoreTransaction TABLE
(
	StoreTransactionID INT,
	StoreID INT,
	ProductID INT
);

--select distinct StoreTransactionID, StoreID, ProductID
--into @tempStoreTransaction
insert into @tempStoreTransaction
select distinct StoreTransactionID, StoreID, ProductID
--select *
from [dbo].[StoreTransactions_Working]
where WorkingStatus = 2
and WorkingSource in ('SUP-S', 'SUP-U')
--and EDIName in (select EDIName from Suppliers where IsRegulated = 1)
and ProcessID = @ProcessID

begin transaction

set @loadstatus = 3

update t set t.SupplierID = s.supplierid
from @tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join Suppliers s
on t.EDIName = s.UniqueEDIName


update w set w.SupplierID = s.DataTrueSupplierID
from  @tempStoreTransaction tmp
inner join StoreTransactions_Working w
on tmp.StoreTransactionID = w.StoreTransactionID
inner join datatrue_edi.dbo.EDI_SupplierCrossReference s
on ltrim(rtrim(w.SupplierIdentifier)) = ltrim(rtrim(s.SupplierIdentifier))
where w.SupplierID is null or w.SupplierID = 0


update t set WorkingStatus = -3
from @tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where SupplierID is null

if @@ROWCOUNT > 0
	begin

		set @errormessage = 'UNKNOWN Supplier Identifiers Found'
		set @errorlocation = 'prValidateSuppliersInStoreTransactions_Working_SUP'
		set @errorsenderstring = 'prValidateSuppliersInStoreTransactions_Working_SUP'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
	end
	
update t set t.UnAuthorizedAssignment = 0
from @tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[StoreSetup] s
on t.StoreID = s.StoreID
and t.SupplierID = s.SupplierID
and t.SaleDateTime between s.ActiveStartDate and s.ActiveLastDate

update t set t.UnAuthorizedAssignment = 1
from @tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
and t.UnAuthorizedAssignment is null

commit transaction
	
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
				,'An exception occured in prValidateSuppliersInStoreTransactions_Working_SUP_ACH.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, ''--'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
				
end catch
	
update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID
from @tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where SupplierID is not null
	
return
GO
