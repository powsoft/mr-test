USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateStoresInStoreTransactions_Working_SUP_X12]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateStoresInStoreTransactions_Working_SUP_X12]

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
from [dbo].[StoreTransactions_Working]
where WorkingStatus = 0
and WorkingSource in ('SUP-S', 'SUP-U', 'SUP-X')

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

--select t.StoreIdentifier, s.StoreIdentifier, s.StoreID, c.ChainID
update t set t.StoreID = s.StoreID
--select s.StoreID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Stores] s
on t.ChainID = s.ChainID 
and cast(t.StoreIdentifier as int) = cast(s.StoreIdentifier as int)
and ltrim(rtrim(s.Custom1)) <> 'Shop N Save Warehouse Foods Inc'
--and cast(t.StoreIdentifier as int) = cast(s.custom2 as int)
where 1 = 1
and WorkingStatus = 0

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
