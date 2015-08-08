USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prExecuteSendInvoiceDetailsEmail_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Joshua Kiracofe
-- Create date: 2015-01-07
-- Description:	Checks if invoice details have been inserted, and sends invoice detail insertion email
-- =============================================
CREATE PROCEDURE [dbo].[prExecuteSendInvoiceDetailsEmail_PRESYNC_20150329] 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
Declare @STQty int
Declare @currentDate Date
Set @currentDate = convert(date, GETDATE())	
	
	
	Select @STQty = COUNT(distinct T.ChainID)
	from InvoiceDetails T with(nolock) inner join 
	(Select C.Chainid 
	From  Chains C 
	Inner Join DataTrue_EDI..ProcessStatus P
	on P.ChainName = C.ChainIdentifier
	Where P.AllFilesReceived = 1
	and P.BillingComplete = 0
	and P.BillingIsRunning = 1
	and P.RecordTypeID = 2
	and P.Date = @currentDate
	) D
	on D.ChainID = T.ChainID
	where ProcessID = (Select LastProcessID from JobRunning where JobRunningID = 14)
	and CONVERT(date, T.DateTimeCreated) = @currentDate
	and InvoiceDetailTypeID in (1, 16)

	--Print @StQty

	If @STQty = 0

		Begin
		
			update s set s.BillingIsRunning = 0
			from [DataTrue_EDI].[dbo].[ProcessStatus] s
			where upper(ltrim(rtrim(ChainName))) in (Select EntityIdentifier 
														From ProcessStepEntities 
														where ProcessStepName = 'prGetInboundPOSTransactions_New')
			and CAST(date as date) = @currentdate
			and isnull(BillingComplete, 0) = 0
			and ISNULL(BillingIsRunning, 0) = 1
			and isnull(AllFilesReceived, 0) = 1
			and RecordTypeID = 2
			
			exec [msdb].[dbo].[sp_stop_job] 
					@job_name = 'DailyPOSBilling_New'

		End
	
	Else
	
		Begin
			exec dbo.prSendEmail_InvoiceDetail_MoveTotals_New
		End
END
GO
