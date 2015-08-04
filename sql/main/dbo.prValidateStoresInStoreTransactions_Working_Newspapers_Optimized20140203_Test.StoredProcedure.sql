USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateStoresInStoreTransactions_Working_Newspapers_Optimized20140203_Test]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create procedure [dbo].[prValidateStoresInStoreTransactions_Working_Newspapers_Optimized20140203_Test]

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
where WorkingStatus = 0
and WorkingSource in ('POS')
and ChainIdentifier in ('DQ')

begin transaction

set @loadstatus = 1

select @storeentitytypeid = EntityTypeID from EntityTypes where EntityTypeName = 'Store'

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

update t set t.StoreID = s.StoreID, t.SBTNumber = ltrim(rtrim(s.Custom2))
from [dbo].[StoreTransactions_Working] t
inner join [dbo].[Stores] s
on t.ChainID = s.ChainID
and ltrim(rtrim(t.Banner)) = ltrim(rtrim(s.Custom3))
where cast(t.StoreIdentifier as int) = cast(s.Custom2 as int) --t.StoreIdentifier = s.StoreIdentifier
and t.ChainID is not null
and t.WorkingStatus = 0
and t.WorkingSource = 'POS'

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
from [dbo].[StoreTransactions_Working] t
where workingstatus = 0
and WorkingSource = 'POS'


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
