USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prExecuteInvoicingCheck_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Joshua Kiracofe
-- Create date: 12/19/2014
-- Description:	Check to make sure we didn't receive a process status record for a chain we've not yet started to invoice
-- =============================================
CREATE PROCEDURE [dbo].[prExecuteInvoicingCheck_PRESYNC_20150329]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	Declare @InvQty int
	Declare @JobRunning Varchar (50)

	Select @InvQty = COUNT(InvoiceDetailID)
	from InvoiceDetails with(nolock)
	where ProcessID = (Select LastProcessID from JobRunning where JobRunningID = 14)
	and CONVERT(date, datetimecreated) = CONVERT(Date, getdate())

	If @InvQty = 0 

		Begin
			
			Select @JobRunning = ChainName
								From DataTrue_EDI..ProcessStatus
								Where Date = CONVERT(date, GETDATE())
								and BillingIsRunning = 1
								and AllFilesReceived = 1
								and BillingComplete = 0
								and RecordTypeID = 2
			
		
			Declare @ErrorMessage as Varchar(1000)
			Set @ErrorMessage = 'Retailer and supplier invoicing has been stopped because there are no invoice details to process. A process status record was inserted for chain ' + @JobRunning 
		
			exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'DailyPOSBilling_NEW'
			
			exec dbo.prSendEmailNotification_PassEmailAddresses 'No Records to Invoice'
					, @ErrorMessage
					,'DataTrue System', 0, 'josh.kiracofe@icucsolutions.com; charlie.clark@icucsolutions.com'--'Datatrueit@icucsolutions.com; gilad.keren@icucsolutions.com'
		
		End
END
GO
