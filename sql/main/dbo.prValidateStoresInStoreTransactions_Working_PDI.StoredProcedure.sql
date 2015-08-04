USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateStoresInStoreTransactions_Working_PDI]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateStoresInStoreTransactions_Working_PDI]

as

declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @storeentitytypeid int
declare @MyID int
set @MyID = 7416

begin try

select distinct StoreTransactionID, ChainID, StoreIdentifier
into #tempStoreTransaction
--select *
--select count(*)
--update w set chainid = 59973, Banner = 'VAL'
--select distinct storeidentifier
--select distinct chainidentifier
--select top 10000 *
from [dbo].[StoreTransactions_Working] w
where WorkingStatus = 0
and WorkingSource in ('POS')
--and ltrim(rtrim(ChainIdentifier)) = 'MILE'
--and CHARINDEX('PDI', chainidentifier) > 0
--and SupplierIdentifier = '5188734'
--and CAST(saledatetime as date) = '12/1/2011'
--and Banner = 'SS'
--and ChainIdentifier = 'SV'
--and SaleDateTime = '11/7/2011'

begin transaction

set @loadstatus = 1

select @storeentitytypeid = EntityTypeID from EntityTypes where EntityTypeName = 'Store'

/*
update t set t.ChainID = c.ChainID
from [dbo].[StoreTransactions_Working] t
inner join Chains c
on t.ChainIdentifier = c.ChainName
where WorkingStatus = 0
and WorkingSource in ('POS')
drop table #tempStoreTransaction
select * from chains
update chains set chainidentifier = 'CTM_PDI' where chainid = 44285
select * from stores where chainid = 44285
update stores set custom3 = 'CTM_PDI' where chainid = 44285
*/

update t set t.ChainID = c.ChainID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Chains] c
on ltrim(rtrim(replace(t.ChainIdentifier, 'CTB_PDI', 'CST'))) = c.ChainIdentifier

update t set t.ChainID = c.ChainID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Chains] c
on ltrim(rtrim(replace(t.ChainIdentifier, '_PDI', ''))) = c.ChainIdentifier


update t set t.Banner = ltrim(rtrim(replace(t.ChainIdentifier, '_PDI', '')))
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
--and (t.Banner is null or len(t.Banner) < 1)


update t set t.WorkingStatus = -1
from [dbo].[StoreTransactions_Working] t
inner join #tempStoreTransaction tmp
on t.StoreTransactionID = tmp.StoreTransactionID
where WorkingStatus = 0
and t.ChainID is null

if @@ROWCOUNT > 0
	begin

		--declare @errormessage varchar(4500)
		--declare @errorlocation varchar(255)

		set @errormessage = 'Unknown Chain Identifiers Found'
		set @errorlocation = 'prValidateStoresInStoreTransactions_Working'
		set @errorsenderstring = 'prValidateStoresInStoreTransactions_Working'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
	end

--update t set t.WorkingStatus = -1
--from [dbo].[StoreTransactions_Working] t
--inner join #tempStoreTransaction tmp
--on t.StoreTransactionID = tmp.StoreTransactionID
--where WorkingStatus = 0
--and ISNUMERIC(t.storeidentifier) < 1

--if @@ROWCOUNT > 0
--	begin

--		--declare @errormessage varchar(4500)
--		--declare @errorlocation varchar(255)

--		set @errormessage = 'Invalid Store Identifiers Found'
--		set @errorlocation = 'prValidateStoresInStoreTransactions_Working'
--		set @errorsenderstring = 'prValidateStoresInStoreTransactions_Working'
		
--		exec dbo.prLogExceptionAndNotifySupport
--		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
--		,@errorlocation
--		,@errormessage
--		,@errorsenderstring
--		,@MyID
		
--	end

--update t set t.StoreIdentifier = left(ltrim(rtrim(t.storeidentifier)), LEN(ltrim(rtrim(t.storeidentifier))) - 3)
----select *
--from [dbo].[StoreTransactions_Working] t
--where 1 = 1
--and ltrim(rtrim(t.ChainIdentifier)) = 'KR'
--and t.WorkingSource = 'POS'
--and t.WorkingStatus = 0

--select t.StoreIdentifier, s.StoreIdentifier, s.StoreID, c.ChainID
update t set t.StoreID = s.StoreID, t.SBTNumber = ltrim(rtrim(s.Custom2))
--from [dbo].[StoreTransactions_Working] t
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
--inner join [dbo].[Chains] c
--on t.ChainID = c.ChainID
inner join [dbo].[Stores] s
on t.ChainID = s.ChainID
--and ltrim(rtrim(t.Banner)) = ltrim(rtrim(s.Custom3))
where cast(t.StoreIdentifier as int) = cast(s.Custom2 as int) --t.StoreIdentifier = s.StoreIdentifier
--where cast(t.StoreIdentifier as int) = cast(s.StoreIdentifier as int) --t.StoreIdentifier = s.StoreIdentifier
--------and t.ChainID is not null
--------and t.WorkingStatus = 0
--------and t.WorkingSource = 'POS'
--and ISNUMERIC(t.storeidentifier) > 0

/*
update t set WorkingStatus = -1
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Stores] s
on t.ChainID = s.ChainID
and t.StoreID = s.storeid
and t.WorkingStatus = 0
and t.SaleDateTime > s.ActiveLastDate
*/

declare @rec cursor
declare @chainIdentifier nvarchar(50)
declare @StoreIdentifier nvarchar(50)
declare @StoreTransactionID int
declare @chainid int
declare @storeid int
declare @storename nvarchar(50)

/*
set @rec = CURSOR local fast_forward for
select distinct t.ChainID, tmp.StoreIdentifier, t.ChainIdentifier--, tmp.StoreTransactionID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.StoreID is null
and t.WorkingStatus = 0
--and ISNUMERIC(t.storeidentifier) > 0

open @rec

fetch next from @rec into @chainid, @StoreIdentifier, @chainIdentifier--, @StoreTransactionID

while @@FETCH_STATUS = 0
	begin
		--select @chainid = ChainID from Chains where ChainName = @chainIdentifier
		
		INSERT INTO [dbo].[SystemEntities]
           ([EntityTypeID]
           ,[LastUpdateUserID])
		VALUES
           (@storeentitytypeid
           ,@MyID)

		set @storeid = Scope_Identity()

--select * from datatrue_edi.dbo.EDI_Storecrossreference

		set @storename = ''
		
		select @storename = ISNULL(StoreName, '')
		from datatrue_edi.dbo.EDI_Storecrossreference
		where ChainIdentifier = @chainIdentifier
		and CAST(StoreIdentifier as int) = CAST(@storeidentifier as int)
		
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
           ,@storename
           ,@storeidentifier
           ,'1/1/2011'
           ,'1/1/2025'
           ,@MyID)

		fetch next from @rec into @chainid, @StoreIdentifier, @chainIdentifier--, @StoreTransactionID	
	end
	
close @rec
deallocate @rec
*/

commit transaction
	
end try
	
begin catch

		set @loadstatus = -9999
		
		rollback transaction
		--declare @errormessage varchar(4500)
		--declare @errorlocation varchar(255)

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
	

update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID
--Select *
--update t set workingstatus = 1, LastUpdateUserID = 7416
--from [dbo].[StoreTransactions_Working] t
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where workingstatus = 0
and WorkingSource = 'POS'
--and t.StoreID is not null


/*
select *
--select count(*)
--update w set w.chainid = c.chainid
from storetransactions_working w
inner join chains c
on ltrim(rtrim(w.chainidentifier)) = ltrim(rtrim(c.chainidentifier))
and w.chainid is null

select *
--select count(*)
--update w set w.storeid = c.storeid, w.workingstatus = 1
from storetransactions_working w
inner join stores c
on w.chainid = c.chainid
and cast(ltrim(rtrim(w.storeidentifier)) as int) = cast(ltrim(rtrim(c.custom2)) as int)
and w.storeid is null
and w.workingstatus = 0

select *
from storetransactions_working w
where 1 = 1
and w.storeid is null
and w.workingstatus = 0
*/
return
GO
