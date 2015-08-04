USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateSourceInStoreTransactions_Working_ACH]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateSourceInStoreTransactions_Working_ACH]
	--@CallingJob varchar(100) = null --using this optional parameter to easily identify calling job
as

--select distinct supplierid from [dbo].[StoreTransactions_Working] where workingstatus = 3
declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 7587

begin try

DECLARE @ProcessID INT

SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobName = 'DailyRegulatedBilling'

DECLARE @tempStoreTransaction TABLE
(
	StoreTransactionID INT,
	SourceIdentifier VARCHAR(240), 
	DateTimeSourceReceived DATE
);

DECLARE @tempStoreTransaction2 TABLE
(
	StoreTransactionID INT
);

set @loadstatus = 4
	
	--Create Table @tempStoreTransaction2(StoreTransactionID int)
	insert into @tempStoreTransaction2 (StoreTransactionID)
	select StoreTransactionID
	--select *
	--update t set t.workingstatus = 3
	from [dbo].[StoreTransactions_Working] t
	where WorkingStatus = 3
	and WorkingSource in ('SUP-S', 'SUP-U', 'SUP-O')
	and ProcessID = @ProcessID
	--and EDIName in (select EDIName from Suppliers where IsRegulated = 1)
	--and cast(saledatetime as date) = cast(DATEADD(day, -1, getdate()) as date)
	--and EDIName in(
	--Select SupplierName 
	--From DataTrue_EDI.dbo.ProcessStatus_ACH 
	--Where BillingIsRunning = 1
	--and BillingComplete = 0)
	

begin transaction

	--select distinct StoreTransactionID, SourceIdentifier, DateTimeSourceReceived
	--into @tempStoreTransaction
	insert into @tempStoreTransaction (StoreTransactionID, SourceIdentifier, DateTimeSourceReceived)
	select distinct StoreTransactionID, SourceIdentifier, DateTimeSourceReceived
	from [dbo].[StoreTransactions_Working] t
	where WorkingStatus = 3
	and WorkingSource in ('SUP-S', 'SUP-U', 'SUP-O')
	and t.SourceIdentifier not in (select SourceName from [Source])
	and ProcessID = @ProcessID
	--and ChainID in (select distinct ChainID from @RegulatedChains)


INSERT INTO [dbo].[Source]
           ([SourceTypeID]
           ,[SourceName]
           ,[SourceLocation]
           ,[DateTimeReceived]
           ,[LastUpdateUserID])
     select distinct 1 --File Source is Type 1
           ,SourceIdentifier
           ,'UNKNOWN'
           ,DateTimeSourceReceived
           ,@MyID
           from @tempStoreTransaction
           --where SourceIdentifier not in
			--(select SourceName from Source)
 
Update t Set t.SourceID = s.SourceID
from @tempStoreTransaction2 tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join Source s
on t.SourceIdentifier = s.SourceName
--and t.DateTimeSourceReceived = s.DateTimeReceived


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
		@job_name = 'Billing_Regulated_NewInvoiceData'
			
		Update 	DataTrue_Main.dbo.JobRunning
		Set JobIsRunningNow = 0
		Where JobName = 'DailyRegulatedBilling'	
				

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated Job Stopped'
			,'An exception occurred in prValidateSourceInStoreTransactions_Working_SUP. Manual review, resolution, and re-start will be required for the job to continue.'
			,'DataTrue System', 0, ''--'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
			
			
		
		
				
end catch

update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID
from @tempStoreTransaction2 tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID


return
GO
