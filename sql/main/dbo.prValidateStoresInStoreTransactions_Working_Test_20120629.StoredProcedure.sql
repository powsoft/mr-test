USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateStoresInStoreTransactions_Working_Test_20120629]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateStoresInStoreTransactions_Working_Test_20120629]

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
from [dbo].[StoreTransactions_Working]
where CAST(datetimecreated as date) = '6/28/2012'
and CAST(SaleDateTime as date) = '6/27/2012'
and WorkingSource in ('POS')
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

update t set t.WorkingStatus = -1
from [dbo].[StoreTransactions_Working] t
inner join #tempStoreTransaction tmp
on t.StoreTransactionID = tmp.StoreTransactionID
where WorkingStatus = 0
and ISNUMERIC(t.storeidentifier) < 1

if @@ROWCOUNT > 0
	begin

		--declare @errormessage varchar(4500)
		--declare @errorlocation varchar(255)

		set @errormessage = 'Invalid Store Identifiers Found'
		set @errorlocation = 'prValidateStoresInStoreTransactions_Working'
		set @errorsenderstring = 'prValidateStoresInStoreTransactions_Working'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
	end

--select t.StoreIdentifier, s.StoreIdentifier, s.StoreID, c.ChainID
update t set t.StoreID = s.StoreID, t.SBTNumber = ltrim(rtrim(s.Custom2))
--select *
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
--inner join [dbo].[Chains] c
--on t.ChainID = c.ChainID
inner join [dbo].[Stores] s
on t.ChainID = s.ChainID
and ltrim(rtrim(t.Banner)) = ltrim(rtrim(s.Custom3))
where cast(t.StoreIdentifier as int) = cast(s.Custom2 as int) --t.StoreIdentifier = s.StoreIdentifier
--where cast(t.StoreIdentifier as int) = cast(s.StoreIdentifier as int) --t.StoreIdentifier = s.StoreIdentifier
and t.ChainID is not null
and t.WorkingStatus = 0
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
		
end catch
	

update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where workingstatus = 0
--and t.StoreID is not null

INSERT INTO [DataTrue_EDI].[dbo].[Stores]
           ([StoreID]
           ,[ChainID]
           ,[StoreName]
           ,[StoreIdentifier]
           ,[ActiveFromDate]
           ,[ActiveLastDate]
           ,[Comments]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[EconomicLevel]
           ,[StoreSize]
           ,[Custom1]
           ,[Custom2]
           ,[Custom3]
           ,[DunsNumber])
SELECT [StoreID]
      ,[ChainID]
      ,[StoreName]
      ,[StoreIdentifier]
      ,[ActiveFromDate]
      ,[ActiveLastDate]
      ,[Comments]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[EconomicLevel]
      ,[StoreSize]
      ,[Custom1]
      ,[Custom2]
      ,[Custom3]
      ,[DunsNumber]
  FROM [DataTrue_Main].[dbo].[Stores]
where StoreID not in
(select StoreID from [DataTrue_EDI].[dbo].[Stores])

--select * into import.dbo.EDIstores_20111221 from [DataTrue_EDI].[dbo].[Stores]

update es set es.GroupNumber = ms.GroupNumber
,es.Custom1 = ms.Custom1
,es.Custom2 = ms.Custom2
,es.Custom3 = ms.Custom3
,es.Custom4 = ms.Custom4
,es.SBTNumber = ms.SBTNumber
,es.DunsNumber = ms.DunsNumber
,es.StoreName = ms.StoreName
,es.EconomicLevel = ms.EconomicLevel
from [DataTrue_EDI].[dbo].[Stores] es
inner join [DataTrue_Main].[dbo].[Stores] ms
on es.StoreID = ms.storeid



INSERT INTO [DataTrue_Report].[dbo].[Stores]
           ([StoreID]
           ,[ChainID]
           ,[StoreName]
           ,[StoreIdentifier]
           ,[ActiveFromDate]
           ,[ActiveLastDate]
           ,[Comments]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[EconomicLevel]
           ,[StoreSize]
           ,[Custom1]
           ,[Custom2]
           ,[Custom3]
           ,[DunsNumber])
SELECT [StoreID]
      ,[ChainID]
      ,[StoreName]
      ,[StoreIdentifier]
      ,[ActiveFromDate]
      ,[ActiveLastDate]
      ,[Comments]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[EconomicLevel]
      ,[StoreSize]
      ,[Custom1]
      ,[Custom2]
      ,[Custom3]
      ,[DunsNumber]
  FROM [DataTrue_Main].[dbo].[Stores]
where StoreID not in
(select StoreID from [DataTrue_Report].[dbo].[Stores])

--select * into import.dbo.Reportstores_20111221 from [DataTrue_Report].[dbo].[Stores]

update es set es.GroupNumber = ms.GroupNumber
,es.Custom1 = ms.Custom1
,es.Custom2 = ms.Custom2
,es.Custom3 = ms.Custom3
,es.Custom4 = ms.Custom4
,es.SBTNumber = ms.SBTNumber
,es.DunsNumber = ms.DunsNumber
,es.StoreName = ms.StoreName
,es.EconomicLevel = ms.EconomicLevel
from [DataTrue_Report].[dbo].[Stores] es
inner join [DataTrue_Main].[dbo].[Stores] ms
on es.StoreID = ms.storeid

return
GO
