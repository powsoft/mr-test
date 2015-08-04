USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prWeeklyPOSBillingStartJob]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prWeeklyPOSBillingStartJob]
as

declare @currentdate date
declare @allfilesreceived smallint
declare @mindateinPOS date
declare @thereisanissue bit=0
declare @DailyBillingComplete smallint=0
declare @anotherbillingjobisrunning tinyint

set @currentdate = CAST(getdate() as DATE)



/*
select * from [DataTrue_EDI].[dbo].[ProcessStatus]
select * from storetransactions_working where workingsource = 'POS' and workingstatus = 1
update  storetransactions_working set workingstatus =  -991 where workingsource = 'POS' and workingstatus = 4
select distinct workingstatus  from storetransactions_working order by workingstatus
				update s set s.BillingIsRunning = 2
				from [DataTrue_EDI].[dbo].[ProcessStatus] s
				where upper(ltrim(rtrim(ChainName))) = 'SV'
				and CAST(date as date) = cast(getdate() as date)
				and isnull(BillingComplete, 0) = 1
				and ISNULL(BillingIsRunning, 0) = 1
				and isnull(AllFilesReceived, 0) = 1
*/

exec [dbo].[prValidateJobRunning]

--select * from JobRunning

select @anotherbillingjobisrunning = count(JobRunningID)
from JobRunning
where JobIsRunningNow = 1

select @DailyBillingComplete = count(ChainName)
from [DataTrue_EDI].[dbo].[ProcessStatus]
where upper(ltrim(rtrim(ChainName))) = 'SV'
and CAST(date as date) = @currentdate
and isnull(BillingComplete, 0) = 1
and ISNULL(BillingIsRunning, 0) = 2
and isnull(AllFilesReceived, 0) = 1

set @allfilesreceived = 0

select @allfilesreceived = count(ChainName)
--select *
from [DataTrue_EDI].[dbo].[ProcessStatus]
where upper(ltrim(rtrim(ChainName))) = 'KNG'
and CAST(date as date) = cast(getdate() as date) --@currentdate
and isnull(BillingComplete, 0) = 0
and ISNULL(BillingIsRunning, 0) = 0
and isnull(AllFilesReceived, 0) = 1

select @allfilesreceived = isnull(@allfilesreceived, 0) + count(ChainName)
--select *
from [DataTrue_EDI].[dbo].[ProcessStatus]
where upper(ltrim(rtrim(ChainName))) = 'DCS'
and CAST(date as date) = cast(getdate() as date)
and isnull(BillingComplete, 0) = 0
and ISNULL(BillingIsRunning, 0) = 0
and isnull(AllFilesReceived, 0) = 1

--If (@allfilesreceived = 2)
If (@allfilesreceived = 2 or  @allfilesreceived > 0 and datepart(hour, GETDATE()) >=4)
and @anotherbillingjobisrunning = 0
	--and @DailyBillingComplete > 0
	begin
				
		select ChainIdentifier, storeidentifier, ProductIdentifier, cast(SaleDate as date), ltrim(rtrim(PONO)), COUNT(recordid)
		from datatrue_edi.dbo.Inbound852Sales [No Lock]
		where 1 = 1
		and RecordStatus = 0
		and RecordType = 0
		and ChainIdentifier in ('KNG', 'DCS')
		group by ChainIdentifier, storeidentifier, ProductIdentifier, cast(SaleDate as date), ltrim(rtrim(PONO))
		having COUNT(recordid) > 1
		
		if @@ROWCOUNT > 0
			begin
				set @thereisanissue = 1
			end
			
		select *
		from datatrue_edi.dbo.EDI_SupplierCrossReference
		where DataTrueSupplierID is null
		
		if @@ROWCOUNT > 15
			begin
				set @thereisanissue = 1
			end
			
		select @mindateinPOS = MIN(SaleDate)
		--select MIN(SaleDate)
		from datatrue_edi.dbo.Inbound852Sales [No Lock]
		where 1 = 1
		and RecordStatus = 0
		and Qty <> 0
		and ChainIdentifier in ('KNG', 'DCS')
			
		If DATEDIFF(day, @mindateinPOS, GETDATE()) > 60
			begin
				set @thereisanissue = 1
			end


 
	 --select *
	 --from storetransactions
	 --where StoreID = 41235
	 --and SupplierID = 41440
	 
	 --if @@ROWCOUNT > 0
		--begin
		--	set @thereisanissue = 1
		--	exec dbo.prSendEmailNotification_PassEmailAddresses 'Daily Billing Job Held'
		--		,'Retailer and supplier invoicing has been held due to Source store 7723 pos data received'
		--		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'		
		--end
	
	
		if @thereisanissue = 0
			begin
			
				update JobRunning
				set JobIsRunningNow = 1
				where JobName = 'WeeklyPOSBilling'
			

					 
					 
				update s set s.BillingIsRunning = 1
				from [DataTrue_EDI].[dbo].[ProcessStatus] s
				where upper(ltrim(rtrim(ChainName))) in ('KNG', 'DCS')
				and CAST(date as date) = @currentdate
				and isnull(BillingComplete, 0) = 0
				and ISNULL(BillingIsRunning, 0) = 0
				and isnull(AllFilesReceived, 0) = 1
				
				exec [msdb].[dbo].[sp_start_job] 
					 @job_name = 'WeeklyPOSBilling_THIS_IS_CURRENT_ONE'
					 
				--exec [msdb].[dbo].[sp_start_job] 
				--	 @job_name = 'zUtil_POSBillingWithNoStartEmail'				
				
			 end
		else
			begin
				exec dbo.prSendEmailNotification_PassEmailAddresses 'Weekly Billing Job Held'
				,'Weekly retailer and supplier invoicing has been held due to dupes or old saledate or invalid store data received or new EDI_SupplierCrossReference record without SupplierID'
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'		
			end
     end
     
return
GO
