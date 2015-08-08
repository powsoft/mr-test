USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_Regulated_CompareInvoiceDetailsToFile]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Vince Moore
-- Create date: 05/02/2013
-- Description:	Used by job Billing_Regulated. Compares totals in payments table
--              to amount in EDI_LoadStatus_ACH and stops job and sends email if they don't match
-- =============================================
CREATE PROCEDURE [dbo].[prBilling_Regulated_CompareInvoiceDetailsToFile]
	@match bit OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
--for debug mode- remove for production: declare @match bit


declare @InvoiceDetailsTotal decimal(10,4), @FilesTotal decimal(10,4)
	
Begin Try	

	Set @InvoiceDetailsTotal = (
		Select Round(SUM(TotalCost),2)
		From DataTrue_Main.dbo.InvoiceDetails id with (nolock)
		Inner Join Source s On s.SourceID = id.SourceId 
		Inner Join DataTrue_EDI.dbo.EDI_LoadStatus_ACH ls on ls.[FileName] = s.SourceName 
		Where CAST(id.DateTimeCreated as Date) = CAST(GETDATE() as Date)
	)

	Set @FilesTotal = (	
		select Round(isnull(sum(totalamt),0),2) 
		from datatrue_edi.dbo.EDI_LoadStatus_ACH  ls
		inner join datatrue_edi.dbo.ProcessStatus_ACH ps 
			on ps.SupplierName = ls.Chain and cast(ps.Date as date) = CAST(ls.DateLoaded as date)
		Where BillingIsRunning = 1
		and BillingComplete = 0
		and CAST(ps.[Date] as date) = CAST(getdate() as date)
	)

	if ABS(isnull(@InvoiceDetailsTotal,0) -ISNULL(@FilesTotal,0)) > .01 
		or isnull(@InvoiceDetailsTotal,0) = 0 Or ISNULL(@FilesTotal,0) = 0
	Begin
		exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'Billing_Regulated'
			
		Update 	DataTrue_Main.dbo.JobRunning
		Set JobIsRunningNow = 0
		Where JobName = 'DailyRegulatedBilling'		

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated Job Stopped'
			,'InvoiceDetails total does not match value in EDI_LoadStatus_ACH. or totals were zero.'
			,'DataTrue System', 0, 'vince.moore@icontroldsd.com'--''datatrueit@icontroldsd.com;edi@icontroldsd.com'	
			
		Set @match = 0
		return
	End	
	Else
	begin
		Set @match = 1
		return
	end
End Try
Begin Catch

	exec [msdb].[dbo].[sp_stop_job] 
		@job_name = 'Billing_Regulated'
			
	Update 	DataTrue_Main.dbo.JobRunning
	Set JobIsRunningNow = 0
	Where JobName = 'DailyRegulatedBilling'		

	exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated Job Stopped'
		,'An exception was encountered in prBilling_Regulated_CompareInvoiceDetailsToFile. The cause of the error should be investigated and the totals verified manually'
		,'DataTrue System', 0, 'vince.moore@icontroldsd.com'--'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
	Set @match = 0
	return
End Catch	

END
GO
