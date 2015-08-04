USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateStoresInStoreTransactions_Working_New_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Joshua Kiracofe
-- Create date: 8/25/2014
-- Description:	Validates the Stores in Store Transactions Working
-- =============================================
CREATE PROCEDURE [dbo].[prValidateStoresInStoreTransactions_Working_New_PRESYNC_20150415]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @storeentitytypeid int
declare @MyID int
set @MyID = 7416

begin try

DECLARE @ProcessID INT

SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobRunningID = 14

Update t Set WorkingStatus = 0, ProcessID = @ProcessID
--Select t.*
from StoreTransactions_Working t
inner join [dbo].[Stores] s
on t.ChainID = s.ChainID
and ltrim(rtrim(t.Banner)) = ltrim(rtrim(s.Custom3))
where cast(t.StoreIdentifier as int) = cast(s.Custom2 as int) --t.StoreIdentifier = s.StoreIdentifier
and t.ChainID is not null
and t.WorkingStatus = -1
and t.WorkingSource = 'POS'
and t.ProcessID in (Select ProcessID from JobProcesses where JobRunningID in (9,13, 14))

Update t Set WorkingStatus = 0, ProcessID = @ProcessID
--Select t.*
from StoreTransactions_Working t
inner join DataTrue_EDI..TranslationMaster M
On M.TranslationChainID = t.ChainID
and rtrim(ltrim(M.TranslationCriteria2)) = rtrim(ltrim(t.Banner))
and t.ChainID is not null
and t.WorkingStatus = -1
and t.WorkingSource = 'POS'
and t.ProcessID in (Select ProcessID from JobProcesses where JobRunningID in (9,13, 14))

If OBJECT_ID('[datatrue_main].[dbo].[GetStoreTransactionID]') Is Not Null Drop Table [datatrue_main].[dbo].[GetStoreTransactionID]

select distinct StoreTransactionID, ChainID, StoreIdentifier
into [GetStoreTransactionID]
--Select *
from [dbo].[StoreTransactions_Working]
where WorkingStatus = 0
and WorkingSource in ('POS')
and ProcessID = @ProcessID

Create clustered index IDX_StoretransactionID on DataTRue_Main..[GetStoreTransactionID](StoreTransactionID) With(MaxDop = 0)


begin transaction

set @loadstatus = 1

select @storeentitytypeid = EntityTypeID from EntityTypes where EntityTypeName = 'Store'

update t set t.ChainID = c.ChainID
from [GetStoreTransactionID] tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Chains] c
on t.ChainIdentifier = c.ChainIdentifier

--New banner update added 20141205 by charlie
Update w Set w.Banner = t.TranslationCriteria1
--Select t.*
from datatrue_main.dbo.StoreTransactions_Working w
inner join datatrue_edi.dbo.TranslationMaster t
on w.chainid = t.translationchainid
and ltrim(rtrim(w.CorporateName)) = ltrim(rtrim(t.TranslationValueOutside))
and t.TranslationTypeID = 30
Inner Join GetStoreTransactionID tmp
on tmp.StoreTransactionID = w.StoreTransactionID

--New Banner Update Added by Josh Kiracofe on 1/9/2015
update t set t.Banner = t.EDIBanner
--Select *
from [GetStoreTransactionID] tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
and (t.Banner is null or len(t.Banner) < 1 or LTRIM(rtrim(t.banner)) = '0')

update t set t.Banner = t.ChainIdentifier
--Select *
from [GetStoreTransactionID] tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
and (t.Banner is null or len(t.Banner) < 1 or LTRIM(rtrim(t.banner)) = '0')


update t set t.WorkingStatus = -1
from [dbo].[StoreTransactions_Working] t
inner join [GetStoreTransactionID] tmp
on t.StoreTransactionID = tmp.StoreTransactionID
where WorkingStatus = 0
and t.ChainID is null

if @@ROWCOUNT > 0
	begin

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
inner join [GetStoreTransactionID] tmp
on t.StoreTransactionID = tmp.StoreTransactionID
where WorkingStatus = 0
and ISNUMERIC(t.storeidentifier) < 1

if @@ROWCOUNT > 0
	begin

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
and ProcessID = @ProcessID

update t set t.StoreID = s.StoreID, t.SBTNumber = ltrim(rtrim(s.Custom2))
from [dbo].[StoreTransactions_Working] t
inner join [dbo].[Stores] s
on t.ChainID = s.ChainID
and ltrim(rtrim(t.Banner)) = ltrim(rtrim(s.Custom3))
where cast(t.StoreIdentifier as int) = cast(s.Custom2 as int) --t.StoreIdentifier = s.StoreIdentifier
and t.ChainID is not null
and t.WorkingStatus = 0
and t.WorkingSource = 'POS'
and ProcessID = @ProcessID

Update t Set t.StoreID = convert(int, M.TranslationCriteria1), t.SBTNumber = CONVERT(int, M.TranslationCriteria3)
--Select t.*
from StoreTransactions_Working t
inner join DataTrue_EDI..TranslationMaster M
On M.TranslationChainID = t.ChainID
and rtrim(ltrim(M.TranslationCriteria2)) = rtrim(ltrim(t.Banner))
and M.TranslationValueOutside = t.StoreIdentifier
and t.ChainID is not null
and t.WorkingStatus = 0
and t.WorkingSource = 'POS'
and M.TranslationTypeID = 32
and t.ProcessID = @ProcessID

update t set t.WorkingStatus = -1
--Select *
from [dbo].[StoreTransactions_Working] t
where 1=1
and t.ChainID is not null
and t.StoreID is null
and t.WorkingStatus = 0
and t.WorkingSource = 'POS'
and t.ProcessID = @ProcessID

commit transaction
	
end try
	
begin catch

		set @loadstatus = -9999
		
		rollback transaction

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
			@job_name = 'DailyPOSBilling_New'

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Daily Billing Job Stopped -Test'
				,'Retailer and supplier invoicing has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'josh.kiracofe@icucsolutions.com'		
		
end catch
	

update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID, DateTimeLastUpdate = GETDATE()
from [GetStoreTransactionID] tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where workingstatus = 0
and WorkingSource = 'POS'
and StoreID is not null


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

END
GO
