USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateStoresInStoreTransactions_Working_INV_Old_20110526]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create procedure [dbo].[prValidateStoresInStoreTransactions_Working_INV_Old_20110526]

as

declare @MyID int
set @MyID = 7594

begin transaction

/*
update t set t.WorkingStatus = -1
from [DataTrue_Main].[dbo].[StoreTransactions_Working] t
where WorkingStatus = 0
and WorkingSource in ('SUP-X')

if @@ROWCOUNT > 0
	begin
		-- send db_email
		set @MyID = 7582
	end
*/

select distinct StoreTransactionID, ChainIdentifier, StoreIdentifier
into #tempStoreTransaction
from [DataTrue_Main].[dbo].[StoreTransactions_Working]
where WorkingStatus = 0
and WorkingSource in ('INV')
/*
drop table #tempStoreTransaction
select * from #tempStoreTransaction
select * from Stores where StoreIdentifier = '02804'
*/

--select t.StoreIdentifier, s.StoreIdentifier, s.StoreID, c.ChainID
update t set t.StoreID = s.StoreID
from #tempStoreTransaction tmp
inner join [DataTrue_Main].[dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [DataTrue_Main].[dbo].[Chains] c
on t.ChainIdentifier = c.ChainName
inner join [DataTrue_Main].[dbo].[Stores] s
on c.ChainID = s.ChainID
where cast(t.StoreIdentifier as int) = cast(s.StoreIdentifier as int)

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
inner join [DataTrue_Main].[dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.StoreID is null

open @rec

fetch next from @rec into @chainid, @StoreIdentifier, @StoreTransactionID

while @@FETCH_STATUS = 0
	begin
		--select @chainid = ChainID from Chains where ChainName = @chainIdentifier
		
		INSERT INTO [DataTrue_Main].[dbo].[SystemEntities]
           ([EntityTypeID]
           ,[LastUpdateUserID])
		VALUES
           (4
           ,@MyID)

		set @storeid = Scope_Identity()
		
		INSERT INTO [DataTrue_Main].[dbo].[Stores]
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

update t set WorkingStatus = 1, LastUpdateUserID = @MyID
from #tempStoreTransaction tmp
inner join [DataTrue_Main].[dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.StoreID is not null

update t set WorkingStatus = -2, LastUpdateUserID = @MyID
from #tempStoreTransaction tmp
inner join [DataTrue_Main].[dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.StoreID is null

if @@ROWCOUNT > 0
	begin
		--Call db-email here
		set @MyID = 7594
	end

if @@ERROR = 0
	commit transaction
else
	rollback transaction
	
return
GO
