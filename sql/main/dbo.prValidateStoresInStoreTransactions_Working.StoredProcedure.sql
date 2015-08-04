USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateStoresInStoreTransactions_Working]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateStoresInStoreTransactions_Working]

as

declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @storeentitytypeid int
declare @MyID int
set @MyID = 7416

begin try

--update w set workingstatus = 0
----select workingstatus, *
--from [dbo].[StoreTransactions_Working] w
--where 1 = 1
----and WorkingStatus = 0
--and WorkingSource in ('POS')
--and Banner = 'KNG'
--and cast(StoreIdentifier as int) = 1650

select distinct StoreTransactionID, ChainID, StoreIdentifier
into #tempStoreTransaction
--select *
from [dbo].[StoreTransactions_Working]
where WorkingStatus = 0
--and ChainID = 40393
and WorkingSource in ('POS')
--and charindex('PDI', ChainIdentifier)<1
and ChainIdentifier in (select EntityIdentifier from ProcessStepEntities where ProcessStepName = 'prValidateStoresInStoreTransactions_Working')
--and ChainID not in (44199, 44285, 58873)
--and SupplierIdentifier = '5188734'
--and CAST(saledatetime as date) = '12/1/2011'
--and Banner = 'SS'
--and ChainIdentifier = 'SV'
--and SaleDateTime = '11/7/2011'
--select * from chains
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


update t set t.Banner = t.ChainIdentifier
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
and (t.Banner is null or len(t.Banner) < 1 or LTRIM(rtrim(t.banner)) = '0')


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

update t set t.StoreIdentifier = left(ltrim(rtrim(t.storeidentifier)), LEN(ltrim(rtrim(t.storeidentifier))) - 3)
--select *
from [dbo].[StoreTransactions_Working] t
where 1 = 1
and ltrim(rtrim(t.ChainIdentifier)) = 'KR'
and t.WorkingSource = 'POS'
and t.WorkingStatus = 0

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
and ltrim(rtrim(t.Banner)) = ltrim(rtrim(s.Custom3))
where cast(t.StoreIdentifier as int) = cast(s.Custom2 as int) --t.StoreIdentifier = s.StoreIdentifier
--where cast(t.StoreIdentifier as int) = cast(s.StoreIdentifier as int) --t.StoreIdentifier = s.StoreIdentifier
and t.ChainID is not null
--and t.WorkingStatus = 0
--and t.WorkingSource = 'POS'
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
--where workingstatus = 0
--and WorkingSource = 'POS'
--and t.StoreID is not null


INSERT INTO [DataTrue_EDI].[dbo].[Chains]
           ([ChainID]
           ,[ChainName]
           ,[ChainIdentifier]
           ,[ActiveStartDate]
           ,[ActiveEndDate]
           ,[Comments]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate])
SELECT [ChainID]
      ,[ChainName]
      ,[ChainIdentifier]
      ,[ActiveStartDate]
      ,[ActiveEndDate]
      ,[Comments]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
  FROM [DataTrue_Main].[dbo].[Chains]
	where ChainID not in
	(select ChainID from [DataTrue_EDI].[dbo].[Chains])








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
           ,[DunsNumber]
           ,[ActiveStatus])
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
      ,[ActiveStatus]
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
,es.StoreIdentifier = ms.StoreIdentifier
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
           ,[DunsNumber]
           ,[ActiveStatus])
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
      ,[ActiveStatus]
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
,es.StoreIdentifier = ms.StoreIdentifier
from [DataTrue_Report].[dbo].[Stores] es
inner join [DataTrue_Main].[dbo].[Stores] ms
on es.StoreID = ms.storeid

INSERT INTO [DataTrue_EDI].[dbo].[CostZones]
           ([CostZoneID]
           ,[CostZoneName]
           ,[CostZoneDescription]
           ,[SupplierId])
SELECT [CostZoneID]
      ,[CostZoneName]
      ,[CostZoneDescription]
      ,[SupplierId]
  FROM [DataTrue_Main].[dbo].[CostZones]
  where CostZoneID not in (select CostZoneID from [DataTrue_EDI].[dbo].[CostZones])

INSERT INTO [DataTrue_EDI].[dbo].[CostZoneRelations]
           ([CostZoneRelationID]
           ,[StoreID]
           ,[SupplierID]
           ,[CostZoneID])
SELECT [CostZoneRelationID]
      ,[StoreID]
      ,[SupplierID]
      ,[CostZoneID]
  FROM [DataTrue_Main].[dbo].[CostZoneRelations]
	where CostZoneRelationID not in (select CostZoneRelationID from [DataTrue_EDI].[dbo].[CostZoneRelations])







return
GO
