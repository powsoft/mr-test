USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateStoresInStoreTransactions_Working_INV_NST]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateStoresInStoreTransactions_Working_INV_NST]

as

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus int
declare @MyID int
set @MyID = 7594

begin try

select distinct StoreTransactionID, ChainIdentifier, StoreIdentifier
into #tempStoreTransaction
--select *
--select count(*)
--update w set EDIName = 'PEP'
from [dbo].[StoreTransactions_Working] w
where WorkingStatus = 0
and WorkingSource in ('INV')
--and SupplierIdentifier = '6034243'

begin transaction

set @loadstatus = 1

/*
update t set t.WorkingStatus = -2
from [dbo].[StoreTransactions_Working] t
inner join #tempStoreTransaction tmp
on t.StoreTransactionID = tmp.StoreTransactionID
where WorkingStatus = 0
and WorkingSource not in ('INV')

if @@ROWCOUNT > 0
	begin
--****************************
@subjectpassed nvarchar(255),
@bodypassed nvarchar(4000),
@fromstring nvarchar(255)='',
@fromid int=0
--****************************
		set @errormessage = 'Unknown Transactions Types Found'
		set @errorlocation = 'prValidateStoresInStoreTransactions_Working_INV'
		
		exec dbo.prSendEmailNotification
		@errorlocation,
		@errormessage,
		@errorlocation,
		@MyID
	end
*/

/*
drop table #tempStoreTransaction
select * from #tempStoreTransaction
select * from Stores where StoreIdentifier = '02804'
*/
update storetransactions_working 
set EDIBanner =
case when ltrim(rtrim(ediname)) = 'GOP' then 'SV'
else null
end
where 1 = 1
and workingstatus = 0
and workingsource in ('INV')
and EDIName = 'GOP'
	
/*
0032326880002       
0069271807700       
0242503670000       
1939636180000       
8008812780000       
*/
update storetransactions_working 
set EDIBanner =
case when ltrim(rtrim(corporateidentifier)) = '0032326880002' then 'SV'
	when ltrim(rtrim(corporateidentifier)) = '0242503670000' then 'SV'
	when ltrim(rtrim(corporateidentifier)) = '1939636180000' then 'SV'
	when ltrim(rtrim(corporateidentifier)) = '0069271877700' then 'ABS'
	when ltrim(rtrim(corporateidentifier)) = '0069271807700' then 'ABS'
	when ltrim(rtrim(corporateidentifier)) = '8008812780000' then 'SS'
else null
end
where 1 = 1
and workingstatus = 0
and workingsource in ('INV')
and EDIName = 'PEP'


/*
TOBACCO ROW
CUB FOODS
FARM FRESH
ALBRTSNS
ALBERTSONS
SHOP N SAVE
SHOPPERS
MARKETPLACE
LUCKY
*/
update storetransactions_working 
set EDIBanner =
case 
	when LEFT(Banner , CHARINDEX('#',Banner)-2) = 'TOBACCO ROW' then 'SV'
	when LEFT(Banner , CHARINDEX('#',Banner)-2) = 'ACME       ' then 'ABS'
	when LEFT(Banner , CHARINDEX('#',Banner)-2) = 'ALBRTSNS   ' then 'ABS'
	when LEFT(Banner , CHARINDEX('#',Banner)-2) = 'CUB        ' then 'SV'
	when LEFT(Banner , CHARINDEX('#',Banner)-2) = 'CUB FOODS  ' then 'SV'
	when LEFT(Banner , CHARINDEX('#',Banner)-2) = 'FARM FRESH ' then 'SV'
	when LEFT(Banner , CHARINDEX('#',Banner)-2) = 'MARKETPLACE' then 'SV'
	when LEFT(Banner , CHARINDEX('#',Banner)-2) = 'ALBERTSON''S' then 'ABS'
	when LEFT(Banner , CHARINDEX('#',Banner)-2) = 'LUCKY      ' then 'ABS'
	when LEFT(Banner , CHARINDEX('#',Banner)-2) = 'ALBERTSONS ' then 'ABS'
	when LEFT(Banner , CHARINDEX('#',Banner)-2) = 'SHOP N SAVE' then 'SS'
	when LEFT(Banner , CHARINDEX('#',Banner)-2) = 'SHOPPERS   ' then 'SV'
	else null
	end
where 1 = 1
and workingstatus = 0
and workingsource in ('INV')
and EDIName = 'NST'

update t set t.ChainID = c.ChainID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Chains] c
on t.ChainIdentifier = c.ChainIdentifier
where t.WorkingStatus = 0

update t set t.WorkingStatus = -1
from [dbo].[StoreTransactions_Working] t
inner join #tempStoreTransaction tmp
on t.StoreTransactionID = tmp.StoreTransactionID
where WorkingStatus = 0
and ChainID is null

if @@ROWCOUNT > 0
	begin
--declare @errorsenderstring nvarchar(255)
		set @errormessage = 'Unknown Chain Identifiers Found.  Records in the StoreTransactions_Working have been pended to a status of -1.'
		set @errorlocation = 'Invalid EDI data found during execution of prValidateStoresInStoreTransactions_Working_INV'
		set @errorsenderstring = 'prValidateStoresInStoreTransactions_Working_INV'
		
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
--and StoreID is null
and ISNUMERIC(t.StoreIdentifier) < 1

if @@ROWCOUNT > 0
	begin

		set @errormessage = 'Unknown Store Identifiers Found.  Records in the StoreTransactions_Working have been pended to a status of -1.'
		set @errorlocation = 'Invalid EDI data found during execution of prValidateStoresInStoreTransactions_Working_INV'
		set @errorsenderstring = 'prValidateStoresInStoreTransactions_Working_INV'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
	end
/*
select distinct custom1
from stores
where StoreID in
(select distinct StoreID from StoreTransactions 
where SupplierID = 41465 and TransactionTypeID in (2,5,8))
*/

update t set t.StoreID = s.StoreID
from [dbo].[StoreTransactions_Working] t
inner join [dbo].[Stores] s
on t.ChainID = s.ChainID 
and cast(t.StoreIdentifier as int) = cast(s.StoreIdentifier as int)
and ltrim(rtrim(s.Custom3)) = ltrim(rtrim(EDIBanner))
where 1 = 1
and WorkingStatus = 0
and workingsource in ('INV')
and EDIName = 'PEP'
and t.StoreID is null

update t set t.StoreID = s.StoreID
from [dbo].[StoreTransactions_Working] t
inner join [dbo].[Stores] s
on t.ChainID = s.ChainID 
and cast('55' + right(ltrim(rtrim(t.StoreIdentifier)), 3) as int) = cast(ltrim(rtrim(s.custom2)) as int)
and ltrim(rtrim(s.Custom3)) = ltrim(rtrim(EDIBanner))
where 1 = 1
and WorkingStatus = 0
and workingsource in ('INV')
and EDIName = 'PEP'
and t.StoreID is null	
	
	
--/*
update t set t.StoreID = c.StoreID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Stores] c
on t.ChainID = c.ChainID
and CAST(t.StoreIdentifier as int) = CAST(c.StoreIdentifier as int)
and ltrim(rtrim(c.Custom1)) = 'Cub Foods'
and t.EDIName in ('GOP')
where t.WorkingStatus = 0

update t set t.StoreID = c.StoreID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Stores] c
on t.ChainID = c.ChainID
and CAST(t.StoreIdentifier as int) = CAST(c.StoreIdentifier as int)
and ltrim(rtrim(c.Custom1)) = 'Shoppers Food and Pharmacy'
and t.EDIName in ('SHM')
where t.WorkingStatus = 0



update t set t.StoreID = s.StoreID
--select s.StoreID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Stores] s
on t.ChainID = s.ChainID 
and cast(t.StoreIdentifier as int) = cast(s.Custom2 as int)
--and ltrim(rtrim(s.Custom1)) in ('Farm Fresh Markets')
and ltrim(rtrim(s.Custom1)) in ('Farm Fresh Markets','Albertsons - SCAL')
where 1 = 1
and EDIName in ('BIM')
and WorkingStatus = 0
and workingsource in ('INV')
and t.StoreID is null

update t set t.StoreID = s.StoreID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Stores] s
on t.ChainID = s.ChainID 
and cast('55' + right(ltrim(rtrim(t.StoreIdentifier)), 3) as int) = cast(ltrim(rtrim(s.custom2)) as int)
and ltrim(rtrim(s.Custom1)) in ('Farm Fresh Markets','Albertsons - SCAL')
--and ltrim(rtrim(s.Custom1)) in ('Farm Fresh Markets')
where 1 = 1
and WorkingStatus = 0
and workingsource in ('INV')
and EDIName in ('BIM')
and t.StoreID is null

update t set t.StoreID = s.StoreID
from [dbo].[StoreTransactions_Working] t
inner join [dbo].[Stores] s
on t.ChainID = s.ChainID 
and cast(t.StoreIdentifier as int) = cast(s.StoreIdentifier as int)
--and cast(t.StoreIdentifier as int) = cast(s.custom2 as int)
and ltrim(rtrim(s.Custom3)) = ltrim(rtrim(EDIBanner))
where 1 = 1
and WorkingStatus = 0
and workingsource in ('INV')
and EDIName = 'NST'
and t.StoreID is null

update t set t.StoreID = s.StoreID
from [dbo].[StoreTransactions_Working] t
inner join [dbo].[Stores] s
on t.ChainID = s.ChainID 
and cast('55' + right(ltrim(rtrim(t.StoreIdentifier)), 3) as int) = cast(ltrim(rtrim(s.custom2)) as int)
and ltrim(rtrim(s.Custom3)) = ltrim(rtrim(EDIBanner))
where 1 = 1
and WorkingStatus = 0
and workingsource in ('INV')
and EDIName = 'NST'
and t.StoreID is null
/*



update t set t.StoreID = s.StoreID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Stores] s
on t.ChainID = s.ChainID 
and cast(t.StoreIdentifier as int) = cast(s.StoreIdentifier as int)
--and ltrim(rtrim(s.Custom1)) in ('Albertsons - SCAL')
and ltrim(rtrim(s.Custom1)) in ('Farm Fresh Markets')
where 1 = 1
and WorkingStatus = 0
and workingsource in ('INV')
and EDIName = 'NST'
and t.StoreID is null

update t set t.StoreID = s.StoreID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Stores] s
on t.ChainID = s.ChainID 
and cast(t.StoreIdentifier as int) = cast(s.Custom2 as int)
--and ltrim(rtrim(s.Custom1)) in ('Albertsons - SCAL')
and ltrim(rtrim(s.Custom1)) in ('Farm Fresh Markets')
where 1 = 1
and WorkingStatus = 0
and workingsource in ('INV')
and EDIName = 'NST'
and t.StoreID is null
*/
update t set t.StoreID = c.StoreID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Stores] c
on t.ChainID = c.ChainID
and CAST(t.StoreIdentifier as int) = CAST(c.StoreIdentifier as int)
and c.Custom3 = 'SS'
and t.EDIName in ('LWS')
where t.WorkingStatus = 0

update t set t.StoreID = c.StoreID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Stores] c
on t.ChainID = c.ChainID
and CAST(t.StoreIdentifier as int) = CAST(c.StoreIdentifier as int)
and ltrim(rtrim(c.Custom1)) in ('Shop N Save Warehouse Foods Inc')
and t.EDIName in ('SAR')
where t.WorkingStatus = 0

--*/
update t set t.WorkingStatus = -1
from [dbo].[StoreTransactions_Working] t
inner join #tempStoreTransaction tmp
on t.StoreTransactionID = tmp.StoreTransactionID
where WorkingStatus = 0
and StoreID is null

if @@ROWCOUNT > 0
	begin

		set @errormessage = 'Unknown Store Identifiers Found.  Records in the StoreTransactions_Working have been pended to a status of -1.'
		set @errorlocation = 'Invalid EDI data found during execution of prValidateStoresInStoreTransactions_Working_INV'
		set @errorsenderstring = 'prValidateStoresInStoreTransactions_Working_INV'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
	end
	
/*
--select t.StoreIdentifier, s.StoreIdentifier, s.StoreID, c.ChainID
update t set t.StoreID = s.StoreID
--select s.StoreID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Stores] s
on t.ChainID = s.ChainID and cast(t.StoreIdentifier as int) = cast(s.StoreIdentifier as int)
where 1 = 1
and WorkingStatus = 0
and t.StoreID is null
*/

/*
declare @rec cursor
declare @chainIdentifier nvarchar(50)
declare @StoreIdentifier nvarchar(50)
declare @StoreTransactionID int
declare @chainid int
declare @storeid int

set @rec = CURSOR local fast_forward for
select distinct t.ChainID, tmp.StoreIdentifier, tmp.StoreTransactionID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.workingstatus = 0
and t.StoreID is null

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

update t set t.StoreID = s.StoreID
--select s.StoreID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Stores] s
on t.ChainID = s.ChainID and cast(t.StoreIdentifier as int) = cast(s.StoreIdentifier as int)
where 1 = 1
and WorkingStatus = 0
and t.StoreID is null
*/

commit transaction
	
end try
	
begin catch

		rollback transaction
		
		set @loadstatus = -9997

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
		
end catch
	
--print 'got here'
--print @loadstatus
	
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
