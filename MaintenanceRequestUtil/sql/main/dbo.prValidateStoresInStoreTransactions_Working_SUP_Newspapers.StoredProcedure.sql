USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateStoresInStoreTransactions_Working_SUP_Newspapers]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateStoresInStoreTransactions_Working_SUP_Newspapers]

as

declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 7582
DECLARE @ProcessID INT
SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobName = 'NewspaperShrink'

begin try

select distinct StoreTransactionID, ChainIdentifier, StoreIdentifier
into #tempStoreTransaction
--select LEFT(Banner , CHARINDEX('#',Banner)-2), Banner as BNR, workingstatus as status, *
--select Banner as BNR, *
from [dbo].[StoreTransactions_Working]
where WorkingStatus = 0
and WorkingSource in ('SUP-S', 'SUP-U', 'SUP-X')
and ProcessID = @ProcessID
--and EDIName = 'NST'
--and CHARINDEX('#',Banner) = 0
--order by len(Banner)

begin transaction

set @loadstatus = 1

update t set t.WorkingStatus = -5
from [dbo].[StoreTransactions_Working] t
inner join #tempStoreTransaction tmp
on t.StoreTransactionID = tmp.StoreTransactionID
where WorkingStatus = 0
and WorkingSource in ('SUP-X')
and t.ProcessID = @ProcessID

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
		
	end


/*
drop table #tempStoreTransaction
select * from #tempStoreTransaction
select * from Stores where StoreIdentifier = '02804'
select * from Stores where chainid = 64010
*/


update storetransactions_working 
set EDIBanner = LTRIM(rtrim(ChainIdentifier))
where 1 = 1
and workingstatus = 0
and workingsource in ('SUP-S', 'SUP-U')
and ProcessID = @ProcessID
	

update t set t.ChainID = c.ChainID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Chains] c
on LTRIM(rtrim(t.ChainIdentifier)) = LTRIM(rtrim(c.ChainIdentifier))
where t.ProcessID = @ProcessID

update t set t.WorkingStatus = -1
from [dbo].[StoreTransactions_Working] t
inner join #tempStoreTransaction tmp
on t.StoreTransactionID = tmp.StoreTransactionID
where WorkingStatus = 0
and ChainID is null
and t.ProcessID = @ProcessID

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
		
	end

update t set t.WorkingStatus = -1
from [dbo].[StoreTransactions_Working] t
inner join #tempStoreTransaction tmp
on t.StoreTransactionID = tmp.StoreTransactionID
where WorkingStatus = 0
and StoreID is null
and ISNUMERIC(t.StoreIdentifier) < 1
and t.ProcessID = @ProcessID

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
		
	end


/*
update t set t.StoreID = s.StoreID
from [dbo].[StoreTransactions_Working] t
inner join [dbo].[Stores] s
on t.ChainID = s.ChainID 
and cast(t.StoreIdentifier as int) = cast(s.custom2 as int)
--and ltrim(rtrim(s.Custom3)) = ltrim(rtrim(EDIBanner))
where 1 = 1
and WorkingStatus = 0
and workingsource in ('SUP-S','SUP-U')
and EDIName = 'SOUR'
and t.StoreID is null
*/

update t set t.StoreID = s.StoreID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Stores] s
on t.ChainID = s.ChainID 
and cast(t.StoreIdentifier as int) = cast(s.Custom2 as int)
and ltrim(rtrim(ISNULL(s.Custom3, ''))) = ltrim(rtrim(ISNULL(EDIBanner, '')))
where t.StoreID is null
and t.ProcessID = @ProcessID
--where 1 = 1
--and WorkingStatus = 0
--and workingsource in ('SUP-S', 'SUP-U')
--and t.StoreID is null
--and t.ChainIdentifier = 'DQ'

update t set t.WorkingStatus = -1
from [dbo].[StoreTransactions_Working] t
inner join #tempStoreTransaction tmp
on t.StoreTransactionID = tmp.StoreTransactionID
where WorkingStatus = 0
and StoreID is null
and t.ProcessID = @ProcessID

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

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Load Deliveries and Pickups Job Stopped'
				,'Deliveries and pickup loading has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'	
		
end catch
	
update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.WorkingStatus = 0
and t.ProcessID = @ProcessID


/*
update t set WorkingStatus = -2, LastUpdateUserID = @MyID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.StoreID is null

if @@ROWCOUNT > 0
	begin
		--Call db-email here
		set @MyID = 7582
	end
*/

	
return
GO
