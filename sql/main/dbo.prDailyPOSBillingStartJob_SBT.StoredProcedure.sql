USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prDailyPOSBillingStartJob_SBT]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prDailyPOSBillingStartJob_SBT]
as

declare @currentdate date
declare @allfilesreceived smallint
declare @mindateinPOS date
declare @thereisanissue bit=0
declare @anotherjobisrunning tinyint


exec dbo.prValidateJobRunning

select @anotherjobisrunning = COUNT(*)
--select *
from JobRunning
where JobIsRunningNow = 1

set @currentdate = CAST(getdate() as DATE)

set @allfilesreceived = 0

select @allfilesreceived = count(Distinct ChainIdentifier)
--select *
from [DataTrue_EDI].[dbo].[Inbound852Sales] 
where upper(ltrim(rtrim(ChainIdentifier))) in (select EntityIdentifier 
								from dbo.ProcessStepEntities 
								where ProcessStepName In ('prGetInboundPOSTransactions_SBT'))
and CAST(DateTimeReceived  as date) = @currentdate
and RecordType = 0
and Qty <> 0
AND (RecordStatus = 0)

If @allfilesreceived > 0 and @anotherjobisrunning = 0
	begin
			
		if @thereisanissue = 0
			begin
			
				--update s set s.BillingIsRunning = 1
				--from [DataTrue_EDI].[dbo].[ProcessStatus] s
				--where upper(ltrim(rtrim(ChainName))) in (Select EntityIdentifier From ProcessStepEntities where ProcessStepName = 'prStartSBTJob')
				--and CAST(date as date) = @currentdate
				--and isnull(BillingComplete, 0) = 0
				--and ISNULL(BillingIsRunning, 0) = 0
				--and isnull(AllFilesReceived, 0) = 1
							
				update j
				set JobIsRunningNow = 1
				from JobRunning j
				where JobName = 'Daily SBT Move Job'
			
				exec [msdb].[dbo].[sp_start_job] 
					 @job_name = 'Daily SBT Move Job'


			 end
		else
			begin
				exec dbo.prSendEmailNotification_PassEmailAddresses 'Daily SBT Move Job Job Held'
				,'The Daily SBT move has been held due to another job running'
				,'DataTrue System', 0, 'datatrueit@icucsolutions.com; edi@icucsolutions.com'		
			end
     end
     
return
GO
