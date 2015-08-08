USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateStoresInStoreTransactions_Working_RC_RULES]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateStoresInStoreTransactions_Working_RC_RULES]

as

declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @rec cursor
declare @rec2 cursor
declare @rec3 cursor
declare @ruleid int
declare @supplierid int
declare @ediname nvarchar(50)
declare @MyID int
set @MyID = 7582

begin try

select distinct top 50000 StoreTransactionID, ChainIdentifier, StoreIdentifier
into #tempStoreTransaction
--select LEFT(Banner , CHARINDEX('#',Banner)-2), Banner as BNR, workingstatus as status, *
--select Banner as BNR, *
from [dbo].[StoreTransactions_Working]
where WorkingStatus = 0
and WorkingSource in ('R-DB','R-CR')
--and EDIName = 'NST'
--and CHARINDEX('#',Banner) = 0
--order by len(Banner)

begin transaction

set @loadstatus = 1


update t set t.ChainID = c.ChainID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Chains] c
on t.ChainIdentifier = c.ChainIdentifier
where t.WorkingStatus = 0 and WorkingSource in ('R-DB','R-CR')

update t set t.WorkingStatus = -1
from [dbo].[StoreTransactions_Working] t
inner join #tempStoreTransaction tmp
on t.StoreTransactionID = tmp.StoreTransactionID
where WorkingStatus = 0 and WorkingSource in ('R-DB','R-CR')
and ChainID is null



if @@ROWCOUNT > 0
	begin

		--declare @errormessage varchar(4500)
		--declare @errorlocation varchar(255)

		set @errormessage = 'Unknown Chain Identifiers Found'
		set @errorlocation = '[prValidateStoresInStoreTransactions_Working_RC_RULES]'
		set @errorsenderstring = '[prValidateStoresInStoreTransactions_Working_RC_RULES]'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
	end

update t set t.SupplierID = (select SupplierID from Suppliers where UniqueEDIName=t.EDIName)
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID



update w set w.StoreID=s.StoreID,w.WorkingStatus=1
from StoreTransactions_Working w with (nolock)
join Stores s with (nolock) on w.StoreIdentifier=s.StoreIdentifier
and w.ChainID=s.ChainID and WorkingSource in ('R-DB','R-CR')

update t set t.WorkingStatus = -1
from [dbo].[StoreTransactions_Working] t
inner join #tempStoreTransaction tmp
on t.StoreTransactionID = tmp.StoreTransactionID
where WorkingStatus = 0
and StoreID is null

and ISNUMERIC(t.StoreIdentifier) < 1

if @@ROWCOUNT > 0
	begin

		--declare @errormessage varchar(4500)
		--declare @errorlocation varchar(255)

		set @errormessage = 'Invalid Store Identifiers Found'
		set @errorlocation = 'prValidateStoresInStoreTransactions_Working_RC_RULES'
		set @errorsenderstring = 'prValidateStoresInStoreTransactions_Working_RC_RULES'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
	end

update t set t.WorkingStatus = -1
from [dbo].[StoreTransactions_Working] t
inner join #tempStoreTransaction tmp
on t.StoreTransactionID = tmp.StoreTransactionID
where WorkingStatus = 0
and StoreID is null

if @@ROWCOUNT > 0
	begin

		--declare @errormessage varchar(4500)
		--declare @errorlocation varchar(255)

		set @errormessage = 'Unknown Store Identifiers Found'
		set @errorlocation = 'prValidateStoresInStoreTransactions_Working_RC_RULES'
		set @errorsenderstring = 'prValidateStoresInStoreTransactions_Working_RC_RULES'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
	end

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
		
		--exec [msdb].[dbo].[sp_stop_job] 
		--	@job_name = 'DailySUPLoadDeliveriesAndPickups_THIS_IS_CURRENT_ONE'

		--exec dbo.prSendEmailNotification_PassEmailAddresses 'Load Deliveries and Pickups Job Stopped at Store validate step'
		--		,'Deliveries and pickup loading has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
		--		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;edi@icontroldsd.com;mandeep@amebasoftwares.com'	
		
end catch
	
update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.WorkingStatus = 0

return
GO
