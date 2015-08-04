USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prDailyPOSBillingStartJob]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prDailyPOSBillingStartJob]
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
from [DataTrue_EDI].[dbo].[ProcessStatus]
where upper(ltrim(rtrim(ChainName))) = 'SV'
and CAST(date as date) = @currentdate
and isnull(BillingComplete, 0) = 0
and ISNULL(BillingIsRunning, 0) = 0
and isnull(AllFilesReceived, 0) = 1
and ISNULL(RecordTypeID, 0) = 0

If @allfilesreceived > 0 and @anotherjobisrunning = 0
	begin
	
		update s set recordstatus = -5
		from datatrue_edi.dbo.Inbound852Sales s
		where RecordStatus = 0
		and Banner = 'SYNC'
				
		select storeidentifier, ProductIdentifier, cast(SaleDate as date), ltrim(rtrim(PONO)), COUNT(recordid)
		from datatrue_edi.dbo.Inbound852Sales [No Lock]
		where 1 = 1
		and RecordStatus = 0
		and RecordType = 0
		and banner not in ('SV_JWL','SV_SHW','SYNC')
		group by storeidentifier, ProductIdentifier, cast(SaleDate as date), ltrim(rtrim(PONO))
		having COUNT(recordid) > 1
		
		if @@ROWCOUNT > 0
			begin
				set @thereisanissue = 0 --1
			end
			
		select *
		from datatrue_edi.dbo.EDI_SupplierCrossReference
		where DataTrueSupplierID is null
		and chainidentifier = 'SV'
		
		if @@ROWCOUNT > 0
			begin
				set @thereisanissue = 0 --1
			end
			
		select @mindateinPOS = MIN(SaleDate)
		--select MIN(SaleDate)
		from datatrue_edi.dbo.Inbound852Sales [No Lock]
		where 1 = 1
		and RecordStatus = 0
		and Qty <> 0
		and chainidentifier = 'SV'
		and Banner not in ('SV_JWL','KNG')
			
		If DATEDIFF(day, @mindateinPOS, GETDATE()) > 90
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
			
				update s set s.BillingIsRunning = 1
				from [DataTrue_EDI].[dbo].[ProcessStatus] s
				where upper(ltrim(rtrim(ChainName))) = 'SV'
				and CAST(date as date) = @currentdate
				--and CAST(date as date) = CAST(GETDATE() as date)
				and isnull(BillingComplete, 0) = 0
				and ISNULL(BillingIsRunning, 0) = 0
				and isnull(AllFilesReceived, 0) = 1
				and ISNULL(RecordTypeID, 0) = 0
							
				update j
				set JobIsRunningNow = 1
				from JobRunning j
				where JobName = 'DailyPOSBilling'
			
				exec [msdb].[dbo].[sp_start_job] 
					 @job_name = 'DailyPOSBilling_THIS_IS_CURRENT_ONE'
					 
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
