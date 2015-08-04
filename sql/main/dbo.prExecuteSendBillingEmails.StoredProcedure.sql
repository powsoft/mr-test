USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prExecuteSendBillingEmails]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Joshua Kiracofe
-- Create date: 2014-12-09
-- Description:	Executes the Send Billing Emails routine if there's a chain billed for Newspapers or Non-Newspapers
-- =============================================
CREATE PROCEDURE [dbo].[prExecuteSendBillingEmails]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	Declare @NewspaperChains INT
	Declare @NonNewspaperChains INT



	select @NewspaperChains = COUNT(Distinct C.Chainid)
	from InvoiceDetails d with (nolock) 
	inner join Chains C on 
	C.ChainID = d.ChainID
	Inner join InvoicesRetailer R on
	d.RetailerInvoiceID = R.RetailerInvoiceID
	Inner Join DataTrue_EDI..ProcessStatus P
	on P.ChainName = C.ChainIdentifier
	where d.ChainID  in (
		SELECT DISTINCT ENTITYIDTOINCLUDE 
		FROM ProcessStepEntities 
		WHERE ProcessStepName = 'prSendBillingEmail'
	 )
	and CAST(InvoiceDate as date) = CONVERT(date, getdate())
	and InvoiceDetailTypeID in (1)
	and P.Date = CONVERT(date, getdate())
	and P.AllFilesReceived = 1
	and P.BillingIsRunning = 1
	and P.BillingComplete = 0
	and InvoiceDetailTypeID in (1)
	and RecordType = 2
	and P.RecordTypeID = 2

	If @NewspaperChains > 0
		Begin
			exec dbo.prSendBillingTotalsEmail_Newspaper
		End


	select @NonNewspaperChains = COUNT(Distinct C.Chainid)
	from InvoiceDetails d with (nolock) 
	inner join Chains C on 
	C.ChainID = d.ChainID
	Inner join InvoicesRetailer R on
	d.RetailerInvoiceID = R.RetailerInvoiceID
	Inner Join DataTrue_EDI..ProcessStatus P
	on P.ChainName = C.ChainIdentifier
	where d.ChainID  in (
		SELECT DISTINCT ENTITYIDTOINCLUDE 
		FROM ProcessStepEntities 
		WHERE ProcessStepName = 'prSendBillingEmail'
	 )
	and CAST(InvoiceDate as date) = CONVERT(date, getdate())
	and InvoiceDetailTypeID in (1)
	and P.Date = CONVERT(date, getdate())
	and P.AllFilesReceived = 1
	and P.BillingIsRunning = 1
	and P.BillingComplete = 0
	and InvoiceDetailTypeID in (1)
	and RecordType = 0
	and P.RecordTypeID = 2

	If @NonNewspaperChains > 0
		Begin
			Exec dbo.prSendBillingTotalsEmail_SBT
		End
END
GO
