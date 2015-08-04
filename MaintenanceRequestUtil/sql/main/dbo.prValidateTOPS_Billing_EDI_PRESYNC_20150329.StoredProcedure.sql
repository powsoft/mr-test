USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateTOPS_Billing_EDI_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Joshua Kiracofe
-- Create date: 9/24/2014
-- Description:	Validation for TOPS billing
-- =============================================

CREATE Procedure [dbo].[prValidateTOPS_Billing_EDI_PRESYNC_20150329]

	AS
	BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
Declare @rec cursor
Declare @ChainName varchar(50)
Declare @CurrentDate date = Convert(date, getdate())

Set @Rec = CURSOR Local Fast_Forward For

Select ChainName
from DataTrue_EDI..ProcessStatus
where 1=1
and Date = CONVERT(date, GETDATE())
and BillingComplete = 0
and BillingIsRunning = 1
and AllFilesReceived = 1

Open @Rec
Fetch From @Rec Into @ChainName

While @@FETCH_STATUS = 0

Begin

Declare @INVQty Int
Select @INVQty =  SUM(TotalQty) 
from InvoiceDetails I with(nolock)
where 1=1 
and InvoiceDetailTypeID = 1
and RetailerInvoiceID in (Select RetailerInvoiceID
							From InvoicesRetailer
							where convert(date, DateTimeCreated) = @CurrentDate)
and ProcessID in (Select ProcessID from JobProcesses where JobRunningID = 14)
and I.ChainID = (Select ChainID from Chains Where ChainIdentifier = @ChainName)

Declare @EDIQty2 Int
Select @EDIQty2 =  SUM(TotalQty) 
from Datatrue_edi..InvoiceDetails I with(nolock)
where 1=1 
and InvoiceDetailTypeID = 1
and RetailerInvoiceID in (Select RetailerInvoiceID
							From InvoicesRetailer
							where convert(date, DateTimeCreated) = @CurrentDate)
and ProcessID in (Select ProcessID from JobProcesses where JobRunningID = 14)
and I.ChainID = (Select ChainID from Chains Where ChainIdentifier = @ChainName)


IF @EDIQty2 <> @INVQty
	
	Begin
		
		Declare @ErrorMessage as Varchar(1000)
		Set @ErrorMessage = 'Retailer and supplier invoicing has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue. EDI Invoice Detail Quantity = ' + Cast(@EDIQty2 as varchar) +  ' Invoice Detail Quantity = ' + cast(@INVQty as Varchar) + 'For Chain ' + @ChainName
		
		exec [msdb].[dbo].[sp_stop_job] 
		@job_name = 'DailyPOSBilling_NEW'

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Post-Invoicing Validation Failed'
				, @ErrorMessage
				,'DataTrue System', 0, 'Datatrueit@icucsolutions.com; gilad.keren@icucsolutions.com'	
	
	End

Fetch From @Rec Into @ChainName
	
End

Close @Rec
Deallocate @Rec
END
GO
