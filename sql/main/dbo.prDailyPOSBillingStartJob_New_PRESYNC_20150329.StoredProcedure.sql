USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prDailyPOSBillingStartJob_New_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prDailyPOSBillingStartJob_New_PRESYNC_20150329]
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

Select RecordID into #TempRecordID
from DataTrue_EDI..Inbound852Sales S
Where Banner = 'sv_jwl'
and RecordStatus = 0
and Qty <> 0
and CONVERT(date, S.DateTimeReceived) >= dateadd(day, -3, CONVERT(date, @currentdate))

Select Distinct S.ChainIdentifier, S.RecordType into #TempInbound852Sales
From DataTrue_EDI..Inbound852Sales S
Inner join Chains C on S.ChainIdentifier = C.ChainIdentifier
Where S.ChainIdentifier in (select Distinct EntityIdentifier 
								from dbo.ProcessStepEntities 
								where ProcessStepName In ('prGetInboundPOSTransactions_New'))
and Qty <> 0
AND (RecordStatus = 0)
and Saledate >= C.ActiveStartDate
and RecordID not in (Select RecordID from #TempRecordID)
and CONVERT(date, S.DateTimeReceived) >= dateadd(day, -3, CONVERT(date, @currentdate))
								
Delete
From #TempInbound852Sales
Where ChainIdentifier = 'sv'
and RecordType = 0

--Select *
--from #TempInbound852Sales

select @allfilesreceived = count(distinct S.ChainIdentifier)
From #TempInbound852Sales S

If @allfilesreceived > 0 and @anotherjobisrunning = 0
	begin
			
		if @thereisanissue = 0
			begin
			
				--update s set s.BillingIsRunning = 1
				--from [DataTrue_EDI].[dbo].[ProcessStatus] s
				--where upper(ltrim(rtrim(ChainName))) in (Select EntityIdentifier 
				--											From ProcessStepEntities 
				--											where ProcessStepName = 'prGetInboundPOSTransactions_New')
				--and CAST(date as date) = @currentdate
				--and isnull(BillingComplete, 0) = 0
				--and ISNULL(BillingIsRunning, 0) = 0
				--and isnull(AllFilesReceived, 0) = 1
							
				update j
				set JobIsRunningNow = 1
				from JobRunning j
				where JobName = 'New Daily POS Job'
			
				exec [msdb].[dbo].[sp_start_job] 
					 @job_name = 'DailyPOSBilling_New'


			 end
		else
			begin
				exec dbo.prSendEmailNotification_PassEmailAddresses 'New Daily POS Job Held'
				,'The New Daily POS Job has been held due to another job running'
				,'DataTrue System', 0, 'datatrueit@icucsolutions.com; edi@icucsolutions.com'		
			end
     end
  
  Drop Table #TempInbound852Sales
     
return
GO
