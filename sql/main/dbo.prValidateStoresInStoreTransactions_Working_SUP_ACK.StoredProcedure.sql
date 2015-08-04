USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateStoresInStoreTransactions_Working_SUP_ACK]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateStoresInStoreTransactions_Working_SUP_ACK]

as

declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 7582

begin try

select distinct StoreTransactionID, ChainIdentifier, StoreIdentifier
into #tempStoreTransaction
--select LEFT(Banner , CHARINDEX('#',Banner)-2), Banner as BNR, workingstatus as status, *
--select workingstatus, Banner as BNR, *
--update w set w.workingstatus = 0
--update w set w.storeidentifier = '10067211'
from [dbo].[StoreTransactions_Working] w
where 1 = 1
and WorkingStatus = 0
and WorkingSource in ('SUP-S', 'SUP-U', 'SUP-X', 'SUP-O')
--and EDIName = 'NST'
--and CHARINDEX('#',Banner) = 0
--order by len(Banner)
and ChainIdentifier = 'DG'
--and w.storeidentifier = '10007935'

begin transaction

set @loadstatus = 1

update t set t.WorkingStatus = -5
from [dbo].[StoreTransactions_Working] t
inner join #tempStoreTransaction tmp
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
		
	end


/*
drop table #tempStoreTransaction
select * from #tempStoreTransaction
select * from Stores where StoreIdentifier = '02804'
*/
		
update t set t.ChainID = c.ChainID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Chains] c
on t.ChainIdentifier = c.ChainIdentifier

update t set t.WorkingStatus = -1
from [dbo].[StoreTransactions_Working] t
inner join #tempStoreTransaction tmp
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
		
	end

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
		set @errorlocation = 'prValidateStoresInStoreTransactions_Working_SUP'
		set @errorsenderstring = 'prValidateStoresInStoreTransactions_Working_SUP'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
	end

--select * from datatrue_edi.[dbo].[translationmaster]
update t set t.StoreID = s.TranslationCriteria1
--select t.*
from [dbo].[StoreTransactions_Working] t
inner join datatrue_edi.[dbo].[translationmaster] s
on ltrim(rtrim(t.StoreIdentifier)) = LTRIM(rtrim(TranslationValueOutside))
and ltrim(rtrim(s.TranslationTradingPartnerIdentifier)) = ltrim(rtrim(t.EDIName))
where 1 = 1
and ChainIdentifier = 'DG'
and WorkingStatus = 0
and workingsource in ('SUP-S', 'SUP-U', 'SUP-O')
and EDIName = 'ACK'
--and t.StoreID is null


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
declare @rec cursor
declare @chainIdentifier nvarchar(50)
declare @StoreIdentifier nvarchar(50)
declare @StoreTransactionID int
declare @chainid int
declare @storeid int

set @rec = CURSOR local fast_forward for
select distinct tmp.ChainID, tmp.StoreIdentifier, tmp.StoreTransactionID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.StoreID is null

open @rec

fetch next from @rec into @chainid, @StoreIdentifier, @StoreTransactionID

while @@FETCH_STATUS = 0
	begin
		--select @chainid = ChainID from Chains where ChainName = @chainIdentifier
		
		INSERT INTO [dbo].[SystemEntities]
           ([EntityTypeID]
           ,[LastUpdateUserID])
		VALUES
           (4
           ,@MyID)

		set @storeid = Scope_Identity()
		
		INSERT INTO [dbo].[Stores]
           ([StoreID]
           ,[ChainID]
           ,[StoreName]
           ,[StoreIdentifier]
           ,[ActiveFromDate]
           ,[ActiveLastDate]
           ,[LastUpdateUserID])
		VALUES
           (@storeid
           ,@chainid
           ,'UNKNOWN'
           ,@storeidentifier
           ,'1/1/2011'
           ,'1/1/2025'
           ,@MyID)

		fetch next from @rec into @chainid, @StoreIdentifier, @StoreTransactionID	
	end
	
close @rec
deallocate @rec
*/

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
			@job_name = 'DailySUPLoadDeliveriesAndPickups_THIS_IS_CURRENT_ONE'

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Load Deliveries and Pickups Job Stopped at [prValidateStoresInStoreTransactions_Working_SUP_ACK]'
				,'Deliveries and pickup loading has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;edi@icontroldsd.com;mandeep@amebasoftwares.com'	
		
end catch
	
update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.WorkingStatus = 0


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
