USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_Regulated_Start_Job]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prBilling_Regulated_Start_Job]
as

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @recordstoprocess int

begin try

	IF (SELECT COUNT(HolidayID) FROM DataTrue_Main.dbo.Holidays WHERE HolidayDate = CONVERT(DATE, GETDATE())) > 0
		BEGIN
			Declare @holidaymsg varchar(200)
			set @holidaymsg = 'Regulated Billing will not run today due to a bank holiday.  Today is '
			select @holidaymsg =+ HolidayDesc FROM DataTrue_Main.dbo.Holidays WHERE HolidayDate = CONVERT(DATE, GETDATE())
			set @holidaymsg = @holidaymsg + '.'
			Exec dbo.prSendEmailNotification_PassEmailAddresses 'Bank Holiday Notice for Regulated Billing.'
			, @holidaymsg
			,'DataTrue System', 0, 'datatrueit@icontroldsd.com;edi@icontroldsd.com'
			
			return
		END
	
	exec DataTrue_Main.dbo.prValidateJobRunning
	
	--If (Select COUNT(JobIsRunningNow) From DataTrue_Main.dbo.JobRunning Where JobIsRunningNow = 1) > 0
	--Begin
	--	Declare @JobNames VARCHAR(500)
	--	SELECT @JobNames += JobName + ', '
	--	FROM DataTrue_Main.dbo.JobRunning
	--	Where JobIsRunningNow = 1
		
	--	Declare @msg varchar(200)
	--	Set @msg = 'Job Billing_Regulated was not started because the following Job(s) is currently running: ' + @JobNames
		
	--	Exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated_Start failed due to other jobs running'
	--	, @msg
	--	,'DataTrue System', 0, 'datatrueit@icontroldsd.com;edi@icontroldsd.com'
		
	--	return
	--End
	
			
	Update DataTrue_EDI.dbo.ProcessStatus_ach
	Set BillingIsRunning = 1
	Where [Date] = CONVERT(DATE,GETDATE())
	and isnull(BillingIsRunning, 0) <> 1
	--------------------------------------------------
	-- 9/10/2013 PT REMOVED BY TATIANA'S REQUEST 
	--------------------------------------------------
	--and SupplierName in (
	--	Select SupplierIdentifier 
	--	From datatrue_edi.dbo.Inbound846Inventory_ACH_Approval 
	--	)--Where RecordStatus = 0)
	
	exec DataTrue_Main.dbo.prValidateJobRunning
		
	Update 	DataTrue_Main.dbo.JobRunning
	Set JobIsRunningNow = 1, JobLastStartDateTime = GETDATE()
	Where JobName = 'DailyRegulatedBilling'
	
	exec msdb..sp_update_job @job_name = 'Billing_Regulated_NewEDIData', @enabled = 0
	exec msdb..sp_update_job @job_name = 'Billing_Regulated_NewInvoiceData', @enabled = 0
	
	Exec [msdb].[dbo].[sp_start_job] 
	 @job_name = 'Billing_Regulated'
			 
		
end try
begin Catch
		
		

		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,0
		
		
		exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'Billing_Regulated_Start'
			
		Update 	DataTrue_Main.dbo.JobRunning
		Set JobIsRunningNow = 0
		Where JobName = 'DailyRegulatedBilling'			

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated Start Job'
				,'An exception was encountered in prBilling_Regulated_Start_Job].  It is unlikely that Regulated Billing was started. Identify the error and restart this scheduled job'
				,'DataTrue System', 0, 'charlie.clark@icontrol.com'--'datatrueit@icontroldsd.com;edi@icontroldsd.com'		

end catch
     
     
return
GO
