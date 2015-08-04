USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_Regulated_Start_Job_Debug]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prBilling_Regulated_Start_Job_Debug]
as

declare @recordstoprocess int

Select @recordstoprocess = Count(ChainName)
From  datatrue_edi.dbo.Inbound846Inventory_ACH_Approval 
where RecordStatus = 0

--print @recordstoprocess


If @recordstoprocess > 0
Begin
	
	exec DataTrue_Main.dbo.prValidateJobRunning
	
	If (Select COUNT(JobIsRunningNow) From DataTrue_Main.dbo.JobRunning Where JobIsRunningNow = 1) > 0
	Begin
		Declare @JobNames VARCHAR(500)
		SELECT @JobNames = @JobNames + ', ' + JobName
		FROM DataTrue_Main.dbo.JobRunning
		Where JobIsRunningNow = 1
		
		Declare @msg varchar(200)
		Set @msg = 'Job Billing_Regulated was not started because the following Job(s) is currently running: ' + @JobNames
		
		Exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated_Start'
		, @msg
		,'DataTrue System', 0, 'vince.moore@icontroldsd.com'--'datatrueit@icontroldsd.com'
		
		return
	End
	
	/*
	Exec dbo.prSendEmailNotification_PassEmailAddresses 'Regulated Invoices Approved'
		,'Regulated invoices have been approved'
		,'DataTrue System', 0, 'datatrueit@icontroldsd.com'
	*/	
		
	Update DataTrue_EDI.dbo.ProcessStatus_ach
	Set BillingIsRunning = 1
	Where [Date] = CONVERT(DATE,GETDATE())
	and isnull(BillingIsRunning, 0) <> 1
	and SupplierName in (
		Select SupplierIdentifier 
		From datatrue_edi.dbo.Inbound846Inventory_ACH_Approval 
		)--Where RecordStatus = 0)
	
	exec DataTrue_Main.dbo.prValidateJobRunning
		
	Update 	DataTrue_Main.dbo.JobRunning
	Set JobIsRunningNow = 1
	Where JobName = 'DailyRegulatedBilling'
	
	--Exec [msdb].[dbo].[sp_start_job] 
	-- @job_name = 'Billing_Regulated'
	
	--testing only
	
	--Exec dbo.prSendEmailNotification_PassEmailAddresses 'Regulated Invoices Approved'
	--	,'not starting job. ready to run manually'
	--	,'DataTrue System', 0, 'vince.moore@icontroldsd.com'
	/*	
	exec dbo.prSendEmailNotification_PassEmailAddresses 'Daily Regulated Billing Started'
		,'Daily Regulated Billing Started'
		,'DataTrue System', 0, 'datatrueit@icontroldsd.com; edi@icontroldsd.com'	
	*/				
End					 
		
     
return
GO
