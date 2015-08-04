USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateSuppliersInStoreTransactions_Working_RC_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateSuppliersInStoreTransactions_Working_RC_PRESYNC_20150329]

as

declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 7485

begin try

select distinct StoreTransactionID, StoreID, ProductID
into #tempStoreTransaction
--select *
from [dbo].[StoreTransactions_Working]
where WorkingStatus = 2
and WorkingSource in ('RC')

begin transaction

set @loadstatus = 3
--select SupplierID from Suppliers where UniqueEDIName='JJTAYLOR'
update t set t.SupplierID = (select SupplierID from Suppliers where EDIName=t.SupplierIdentifier)
--select t.SupplierID	,t.Ediname,(select SupplierID from Suppliers where UniqueEDIName=t.EDIName)
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID



update t set WorkingStatus = -3
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where SupplierID is null

if @@ROWCOUNT > 0
	begin

		set @errormessage = 'UNKNOWN Supplier Identifiers Found'
		set @errorlocation = '[prValidateSuppliersInStoreTransactions_Working_RC]'
		set @errorsenderstring = '[prValidateSuppliersInStoreTransactions_Working_RC]'
		
		--exec dbo.prLogExceptionAndNotifySupport
		--2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		--,@errorlocation
		--,@errormessage
		--,@errorsenderstring
		--,@MyID
		
	end

commit transaction
	
end try
	
begin catch
		rollback transaction
		
		set @loadstatus = -9998
		
		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		--exec dbo.prLogExceptionAndNotifySupport
		--1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		--,@errorlocation
		--,@errormessage
		--,@errorsenderstring
		--,@MyID
		
		--exec [msdb].[dbo].[sp_stop_job] 
		--	@job_name = 'DailySUPLoadDeliveriesAndPickups_THIS_IS_CURRENT_ONE'

		----exec dbo.prSendEmailNotification_PassEmailAddresses 'Load Deliveries and Pickups Job Stopped'
		----		,'Deliveries and pickup loading has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
		----		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;edi@icontroldsd.com;mandeep@amebasoftwares.com'	
				
end catch
	
update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where SupplierID is not null
	
	
/*
select distinct supplierid
from storetransactions_working
where workingstatus = 3

*/
return
GO
