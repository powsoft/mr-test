USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateSourceInStoreTransactions_Working_Newspapers]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateSourceInStoreTransactions_Working_Newspapers]

as

declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 7419

begin try

--DECLARE @ProcessID INT

--SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobName = 'Daily Move EDI to Main'



CREATE TABLE #tempstoretransactions2(
	[StoreTransactionID] [bigint] NULL
) ON [PRIMARY]


CREATE NONCLUSTERED INDEX [IX_temptransactions_storetransactionid] ON #tempstoretransactions2
(
	[StoreTransactionID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]


insert #tempStoreTransactions2
select StoreTransactionID
from [dbo].[StoreTransactions_Working] t
where WorkingStatus = 3
and WorkingSource in ('POS')
and t.ChainID in (select EntityIDToInclude from ProcessStepEntities where ProcessStepName In ('prValidateSourceInStoreTransactions_Working_Newpapers','prValidateSourceInStoreTransactions_Working_Newspapers_PDI'))
--and t.ProcessID = @ProcessID

begin transaction

set @loadstatus = 4

select distinct StoreTransactionID, SourceIdentifier, DateTimeSourceReceived
into #tempStoreTransaction
from [dbo].[StoreTransactions_Working] t
where WorkingStatus = 3
and WorkingSource in ('POS')
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

           
Update t Set t.SourceID = s.SourceID
from #tempStoreTransactions2 tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [Source] s
on t.SourceIdentifier = s.SourceName

		
commit transaction
	
end try
	
begin catch
		rollback transaction
		
		set @loadstatus = -9999
		
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
			@job_name = 'Daily Move EDI to Main'

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Daily Move EDI to Main'
				,'Retailer and supplier invoicing has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'edi@icucsolutions.com; datatrueit@icucsolutions.com'		
		
end catch
	



update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID
from #tempStoreTransactions2 tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID


	
return
GO
