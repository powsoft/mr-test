USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateSourceInStoreTransactions_Working_DebugA_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateSourceInStoreTransactions_Working_DebugA_PRESYNC_20150415]

as

declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 7419

begin try

--/*------------------------------------------------------------
--select * from #tempstoretransactions2
--drop table #tempstoretransactions2

CREATE TABLE #tempstoretransactions2(
	[StoreTransactionID] [bigint] NULL--,
	--[SourceIdentifier] [nvarchar](50) NULL
) ON [PRIMARY]

/*
/****** Object:  Index [IX_temptransactions_sourceidentifier]    Script Date: 08/09/2011 10:21:10 ******/
CREATE NONCLUSTERED INDEX [IX_temptransactions_sourceidentifier] ON #tempstoretransactions2
(
	[SourceIdentifier] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
*/

/****** Object:  Index [IX_temptransactions_storetransactionid]    Script Date: 08/09/2011 10:21:36 ******/
CREATE NONCLUSTERED INDEX [IX_temptransactions_storetransactionid] ON #tempstoretransactions2
(
	[StoreTransactionID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]

--*/
-------------------------------------------------------------------------------------------------------
--drop table #tempStoreTransaction2
insert #tempStoreTransactions2
select StoreTransactionID
--into #tempStoreTransactions2
--select *
from [dbo].[StoreTransactions_Working] t
where 1 = 1
and WorkingStatus = 4
and WorkingSource in ('POS')
and Banner = 'hag'
--and t.ChainID not in (select ChainID from chains where PDITradingPartner = 1)
--and ISNULL(Processid, 0) = 0

begin transaction

set @loadstatus = 4

--insert into #tempstoretransactions
select distinct StoreTransactionID, SourceIdentifier, DateTimeSourceReceived
into #tempStoreTransaction
--select *
from [dbo].[StoreTransactions_Working] t
where WorkingStatus = 3
and WorkingSource in ('POS')
and t.SourceIdentifier not in (select SourceName from [Source])
and t.ChainID not in (select ChainID from chains where PDITradingPartner = 1)
and isnull(t.ProcessID, 0) = 0

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
from #tempStoreTransactions2 tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [Source] s
on t.SourceIdentifier = s.SourceName
--and t.DateTimeSourceReceived = s.DateTimeReceived

		
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
			@job_name = 'DailyPOSBilling_THIS_IS_CURRENT_ONE'

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Daily Billing Job Stopped'
				,'Retailer and supplier invoicing has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'datatrueit@icontroldsd.com;edi@icontroldsd.com'		
		
end catch
	



update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID
from #tempStoreTransactions2 tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID


	
return
GO
