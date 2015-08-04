USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateSourceInStoreTransactions_Working_RC_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateSourceInStoreTransactions_Working_RC_PRESYNC_20150415]
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
set @loadstatus = 4
	--set @CallingJob = 'Billing_Regulated'
	Create Table #tempStoreTransaction2(StoreTransactionID int)

	--If @CallingJob = 'Billing_Regulated'
	--Begin
	--	insert into #tempStoreTransaction2 (StoreTransactionID)
	--	select StoreTransactionID
	--	from [dbo].[StoreTransactions_Working] t
	--	where WorkingStatus <> 3
	--	and WorkingSource in ('SUP-S', 'SUP-U', 'SUP-O')
	--	and EDIName in(
	--	Select SupplierName 
	--	From DataTrue_EDI.dbo.ProcessStatus_ACH 
	--	Where BillingIsRunning = 1
	--	and BillingComplete = 1)
	--End
	--Else
	--Begin
		insert into #tempStoreTransaction2 (StoreTransactionID)
		select StoreTransactionID
		from [dbo].[StoreTransactions_Working] t
		where WorkingStatus = 3
		and WorkingSource in ('R-DB','R-CR')
		--and cast(saledatetime as date) = '05/14/2013'
		--and EDIName in(
		--Select SupplierName 
		--From DataTrue_EDI.dbo.ProcessStatus_ACH 
		--Where BillingIsRunning = 1
		--and BillingComplete = 0)
	--End
/*
select * from StoreTransactions_Working 
where WorkingStatus = 3
and WorkingSource in ('SUP-S', 'SUP-U', 'SUP-O')
and cast(saledatetime as date) = '05/14/2013'
and EDIName in(
		Select SupplierName 
		From DataTrue_EDI.dbo.ProcessStatus_ACH 
		Where BillingIsRunning = 1
		and BillingComplete = 0)
*/
begin transaction


select distinct StoreTransactionID, SourceIdentifier, DateTimeSourceReceived
	into #tempStoreTransaction
	from [dbo].[StoreTransactions_Working] t
	where WorkingStatus = 3
	and WorkingSource in ('R-DB','R-CR')
	and t.SourceIdentifier not in (select SourceName from [Source])


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
           from #tempStoreTransaction
           --where SourceIdentifier not in
			--(select SourceName from Source)
 
Update t Set t.SourceID = s.SourceID
from #tempStoreTransaction2 tmp
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
		
		print @errormessage
		--exec dbo.prLogExceptionAndNotifySupport
		--1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		--,@errorlocation
		--,@errormessage
		--,@errorsenderstring
		--,@MyID
		
		--If @CallingJob = 'Billing_Regulated'
		--Begin
		--	exec [msdb].[dbo].[sp_stop_job] 
		--		@job_name = 'Billing_Regulated'
				
		--	Update 	DataTrue_Main.dbo.JobRunning
		--	Set JobIsRunningNow = 0
		--	Where JobName = 'DailyRegulatedBilling'	
		
		--exec [msdb].[dbo].[sp_stop_job] 
		--	@job_name = 'Billing_Regulated_NewInvoiceData'
				

		--exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated_NewInvoiceData Job Stopped'
		--	,'An exception occurred in prValidateSourceInStoreTransactions_Working_SUP. Manual review, resolution, and re-start will be required for the job to continue.'
		--	,'DataTrue System', 0, 'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
		----End
		
				
end catch

update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID
from #tempStoreTransaction2 tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID


return
GO
