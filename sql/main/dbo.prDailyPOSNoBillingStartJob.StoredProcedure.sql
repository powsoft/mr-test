USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prDailyPOSNoBillingStartJob]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prDailyPOSNoBillingStartJob]
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


--select * from [DataTrue_EDI].[dbo].[ProcessStatus]
/*
select * from storetransactions_working where workingsource = 'POS' and workingstatus = 1
update  storetransactions_working set workingstatus =  -991 where workingsource = 'POS' and workingstatus = 4
select distinct workingstatus  from storetransactions_working order by workingstatus
*/

set @allfilesreceived = 0

select @allfilesreceived = count(ChainName)
--select *
from [DataTrue_EDI].[dbo].[ProcessStatus]
where upper(ltrim(rtrim(ChainName))) = 'DG'
and CAST(date as date) = @currentdate
and isnull(BillingComplete, 0) = 0
and ISNULL(BillingIsRunning, 0) = 0
and isnull(AllFilesReceived, 0) = 1

If @allfilesreceived > 0 and @anotherjobisrunning = 0
	begin
	
		
		if @thereisanissue = 0
			begin
			
				update s set s.BillingIsRunning = 1
				from [DataTrue_EDI].[dbo].[ProcessStatus] s
				where upper(ltrim(rtrim(ChainName))) in ('DG')
				and CAST(date as date) = @currentdate
				--and CAST(date as date) = CAST(GETDATE() as date)
				and isnull(BillingComplete, 0) = 0
				and ISNULL(BillingIsRunning, 0) = 0
				and isnull(AllFilesReceived, 0) = 1
							
				update j
				set JobIsRunningNow = 1
				from JobRunning j
				where JobName = 'DailyPOSNoBilling'
			
				exec [msdb].[dbo].[sp_start_job] 
					 @job_name = 'DailPOSBILoadNoBilling_THIS_IS_CURRENT_ONE'
					 
				--exec [msdb].[dbo].[sp_start_job] 
				--	 @job_name = 'zUtil_POSBillingWithNoStartEmail'
					 
					 

			 end
		else
			begin
				exec dbo.prSendEmailNotification_PassEmailAddresses 'Daily Billing Job Held'
				,'Retailer and supplier invoicing has been held due to dupes or old saledate or invalid store data received or new EDI_SupplierCrossReference record without SupplierID'
				,'DataTrue System', 0, 'datatrueit@icontroldsd.com'		
			end
     end
     
return
GO
