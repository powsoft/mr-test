USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_Regulated_CompareInvoiceRetailerToFile]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Vince Moore
-- Create date: 05/16/2013
-- Description:	Used by job Billing_Regulated. Compares totals in payments table
--              to amount in EDI_LoadStatus_ACH and stops job and sends email if they don't match
-- =============================================
CREATE PROCEDURE [dbo].[prBilling_Regulated_CompareInvoiceRetailerToFile]
	@match bit OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
--declare @match bit
declare @InvoiceRetailerTotal decimal(10,4), @FilesTotal decimal(10,4)	
	
Begin Try	
	
	Set @InvoiceRetailerTotal = (
		
		Select  Round(isnull(SUM(OriginalAmount),0),2)
		From DataTrue_Main.dbo.InvoicesRetailer ir
		inner join chains c on ir.chainid = c.chainid
		Inner Join DataTrue_EDI.dbo.EDI_LoadStatus_ACH ls 
			on rtrim(ltrim(ls.chain)) = rtrim(ltrim(c.chainidentifier))
		inner join datatrue_edi.dbo.ProcessStatus_ACH ps 
			on rtrim(ltrim(ps.SupplierName)) = rtrim(ltrim(ls.PartnerID))	
		Where CAST(ir.InvoiceDate as Date) = '05/24/2013'--CAST(getdate() as date)
		and cast(ps.Date as date) = '05/24/2013'--CAST(ls.DateLoaded as date)

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
	
	if ABS(isnull(@InvoiceRetailerTotal,0) -ISNULL(@FilesTotal,0)) > .01 
		or isnull(@InvoiceRetailerTotal,0) = 0 Or ISNULL(@FilesTotal,0) = 0
	Begin
		exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'Billing_Regulated'
			
		Update 	DataTrue_Main.dbo.JobRunning
		Set JobIsRunningNow = 0
		Where JobName = 'DailyRegulatedBilling'		

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated Job Stopped'
			,'InvoiceRetailer total does not match value in EDI_LoadStatus_ACH. or totals were zero.'
			,'DataTrue System', 0, 'vince.moore@icontroldsd.com'--'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
			
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
