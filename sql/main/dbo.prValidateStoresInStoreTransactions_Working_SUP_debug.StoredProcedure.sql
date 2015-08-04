USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateStoresInStoreTransactions_Working_SUP_debug]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateStoresInStoreTransactions_Working_SUP_debug]

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
--select Banner as BNR, *
from [dbo].[StoreTransactions_Working]
where WorkingStatus = 0
and WorkingSource in ('SUP-S', 'SUP-U', 'SUP-X')
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
and workingsource in ('SUP-S', 'SUP-U')
and EDIName = 'PEP'

update storetransactions_working 
set EDIBanner =
case 
	when CHARINDEX('CUB',Banner) > 0  then 'SV'
	else null
	end
where 1 = 1
and workingstatus = 0
and workingsource in ('SUP-S', 'SUP-U')
and EDIName = 'NST'
and EDIBanner is null
and CHARINDEX('#',Banner) = 0

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
and workingsource in ('SUP-S', 'SUP-U')
and EDIName = 'NST'
and CHARINDEX('#',Banner)>0
and EDIBanner is null
		

update storetransactions_working 
set EDIBanner =
case 
	when LEFT(Banner , CHARINDEX(' ',Banner)) = 'TOBACCO ROW' then 'SV'
	when LEFT(Banner , CHARINDEX(' ',Banner)) = 'ACME       ' then 'ABS'
	when LEFT(Banner , CHARINDEX(' ',Banner)) = 'ALBRTSNS   ' then 'ABS'
	when LEFT(Banner , CHARINDEX(' ',Banner)) = 'CUB        ' then 'SV'
	when LEFT(Banner , CHARINDEX(' ',Banner)) = 'CUB FOODS  ' then 'SV'
	when LEFT(Banner , CHARINDEX(' ',Banner)) = 'FARM FRESH ' then 'SV'
	when LEFT(Banner , CHARINDEX(' ',Banner)) = 'MARKETPLACE' then 'SV'
	when LEFT(Banner , CHARINDEX(' ',Banner)) = 'ALBERTSON''S' then 'ABS'
	when LEFT(Banner , CHARINDEX(' ',Banner)) = 'LUCKY      ' then 'ABS'
	when LEFT(Banner , CHARINDEX(' ',Banner)) = 'ALBERTSONS ' then 'ABS'
	when LEFT(Banner , CHARINDEX(' ',Banner)) = 'SHOP N SAVE' then 'SS'
	when LEFT(Banner , CHARINDEX(' ',Banner)) = 'SHOPPERS   ' then 'SV'
	else null
	end
where 1 = 1
and workingstatus = 0
and workingsource in ('SUP-S', 'SUP-U')
and EDIName = 'NST'
and CHARINDEX(' ',Banner)>0
and EDIBanner is null
		
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
and cast(t.StoreIdentifier as int) = cast(s.StoreIdentifier as int)
and ltrim(rtrim(s.Custom3)) = ltrim(rtrim(EDIBanner))
where 1 = 1
and WorkingStatus = 0
and workingsource in ('SUP-S', 'SUP-U')
and EDIName = 'PEP'
and t.StoreID is null

update t set t.StoreID = s.StoreID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Stores] s
on t.ChainID = s.ChainID 
and cast(t.StoreIdentifier as int) = cast(s.Custom2 as int)
and ltrim(rtrim(s.Custom3)) = ltrim(rtrim(EDIBanner))
where 1 = 1
and WorkingStatus = 0
and workingsource in ('SUP-S', 'SUP-U')
and EDIName = 'NST'
and t.StoreID is null


update t set t.StoreID = s.StoreID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Stores] s
on t.ChainID = s.ChainID 
and cast('55' + right(ltrim(rtrim(t.StoreIdentifier)), 3) as int) = cast(ltrim(rtrim(s.custom2)) as int)
and ltrim(rtrim(s.Custom3)) = ltrim(rtrim(EDIBanner))
where 1 = 1
and WorkingStatus = 0
and workingsource in ('SUP-S', 'SUP-U')
and EDIName in ('PEP','NST')
and t.StoreID is null

update t set t.StoreID = c.StoreID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join dbo.tUtil_SupplierStoreCrossReference c
on ltrim(rtrim(t.StoreIdentifier)) = ltrim(rtrim(c.storeidentifier))
and LTRIM(rtrim(t.EDIBanner)) = LTRIM(rtrim(c.edibanner))
and LTRIM(rtrim(t.EdiName)) = LTRIM(rtrim(c.EdiName))
where 1 = 1
and WorkingStatus = 0 ---1
and workingsource in ('SUP-S', 'SUP-U')
and t.EDIName in ('NST')
and (t.StoreID is null or t.StoreID = 0)


--select t.StoreIdentifier, s.StoreIdentifier, s.StoreID, c.ChainID
update t set t.StoreID = s.StoreID
--select s.StoreID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Stores] s
on t.ChainID = s.ChainID 
and cast(t.StoreIdentifier as int) = cast(s.StoreIdentifier as int)
--and ltrim(rtrim(s.Custom3)) = 'SS' --LWS
--and ltrim(rtrim(s.Custom3)) <> 'SS' --Bimbo
and ltrim(rtrim(s.Custom1)) = 'Cub Foods'
where 1 = 1
and EDIName in ('GOP')
and WorkingStatus = 0
and t.StoreID is null

update t set t.StoreID = s.StoreID
--select s.StoreID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Stores] s
on t.ChainID = s.ChainID 
and cast(t.StoreIdentifier as int) = cast(s.StoreIdentifier as int)
--and ltrim(rtrim(s.Custom3)) = 'SS' --LWS
--and ltrim(rtrim(s.Custom3)) <> 'SS' --Bimbo
and ltrim(rtrim(s.Custom1)) = 'Shoppers Food and Pharmacy'
where 1 = 1
and EDIName in ('SHM')
and WorkingStatus = 0
and t.StoreID is null


update t set t.StoreID = s.StoreID
--select s.StoreID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Stores] s
on t.ChainID = s.ChainID 
and cast(t.StoreIdentifier as int) = cast(s.StoreIdentifier as int)
and ltrim(rtrim(s.Custom1)) in ('Farm Fresh Markets','Albertsons - SCAL')
where 1 = 1
and EDIName in ('BIM')
and WorkingStatus = 0
and t.StoreID is null

update t set t.StoreID = s.StoreID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Stores] s
on t.ChainID = s.ChainID 
and cast('55' + right(ltrim(rtrim(t.StoreIdentifier)), 3) as int) = cast(ltrim(rtrim(s.custom2)) as int)
and ltrim(rtrim(s.Custom1)) in ('Farm Fresh Markets','Albertsons - SCAL')
where 1 = 1
and WorkingStatus = 0
and workingsource in ('SUP-S', 'SUP-U')
and EDIName = 'BIM'
and t.StoreID is null


--select t.StoreIdentifier, s.StoreIdentifier, s.StoreID, c.ChainID
update t set t.StoreID = s.StoreID
--select s.StoreID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Stores] s
on t.ChainID = s.ChainID 
and cast(t.StoreIdentifier as int) = cast(s.StoreIdentifier as int)
and ltrim(rtrim(s.Custom3)) = 'SS' --LWS
where 1 = 1
and EDIName in ('LWS')
and WorkingStatus = 0
and t.StoreID is null

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

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Load Deliveries and Pickups Job Stopped'
				,'Deliveries and pickup loading has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;edi@icontroldsd.com'	
		
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
