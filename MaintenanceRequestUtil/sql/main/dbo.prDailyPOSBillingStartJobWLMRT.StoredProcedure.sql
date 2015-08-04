USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prDailyPOSBillingStartJobWLMRT]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prDailyPOSBillingStartJobWLMRT]
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
--where JobName = 'DailyPOS'

set @currentdate = CAST(getdate() as DATE)

set @allfilesreceived = 0

select @allfilesreceived = count(ChainName)
from [DataTrue_EDI].[dbo].[ProcessStatus]
where upper(ltrim(rtrim(ChainName))) = 'WLMRT'
and CAST(date as date) = @currentdate
and isnull(BillingComplete, 0) = 0
and ISNULL(BillingIsRunning, 0) = 0
and isnull(AllFilesReceived, 0) = 1

If @allfilesreceived > 0 and @anotherjobisrunning = 0
	begin
			
		--select @mindateinPOS = MIN(SaleDate)
		----select MIN(SaleDate)
		--from datatrue_edi.dbo.Inbound852Sales [No Lock]
		--where 1 = 1
		--and RecordStatus = 0
		--and Qty <> 0
		--and upper(ltrim(rtrim(ChainIdentifier))) = 'WLMRT'
			
		--If DATEDIFF(day, @mindateinPOS, GETDATE()) > 30
		--	begin
		--		set @thereisanissue = 1
		--	end

		if @thereisanissue = 0
			begin
			
				update s set s.BillingIsRunning = 1
				from [DataTrue_EDI].[dbo].[ProcessStatus] s
				where upper(ltrim(rtrim(ChainName))) = 'WLMRT'
				and CAST(date as date) = @currentdate
				--and CAST(date as date) = CAST(GETDATE() as date)
				and isnull(BillingComplete, 0) = 0
				and ISNULL(BillingIsRunning, 0) = 0
				and isnull(AllFilesReceived, 0) = 1
							
				update j
				set JobIsRunningNow = 1
				from JobRunning j
				where JobName = 'DailyPOSBilling_WLMRT'
			
				exec [msdb].[dbo].[sp_start_job] 
					 @job_name = 'DailyPOSBilling_WLMRT'
					 
				--exec [msdb].[dbo].[sp_start_job] 
				--	 @job_name = 'zUtil_POSBillingWithNoStartEmail'
			 end
		else
			begin
				exec dbo.prSendEmailNotification_PassEmailAddresses 'Daily Billing Job Held'
				,'Retailer and supplier invoicing has been held'
				,'DataTrue System', 0, 'charlie@icontroldsd.com'		
			end
     end
     
return
GO
