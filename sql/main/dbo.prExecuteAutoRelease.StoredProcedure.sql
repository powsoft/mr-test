USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prExecuteAutoRelease]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Joshua Kiracofe
-- Create date: 12/8/2014
-- Description:	Evaluates if there are Auto-Release payments to be created or not
-- =============================================
CREATE PROCEDURE [dbo].[prExecuteAutoRelease] 
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    
Declare @ChainsForPayment int
Select @ChainsForPayment = COUNT(distinct chainname)
							From DataTrue_EDI..ProcessStatus
							Where ChainName in (select EntityIdentifier 
												from ProcessStepEntities 
												where ProcessStepName in ('prBilling_Inbound820Payments_From_Billing_Create_Newspaper',
															'prBilling_Inbound820Payments_From_Billing_Create_SBT' ) and IsActive = 1
												)
							And Date = CONVERT(date, getdate())
							and BillingComplete = 0
							and BillingIsRunning = 1
							and AllFilesReceived = 1
												
If @ChainsForPayment > 0

Begin	
												
												
Declare @NewsPaymentsToCreate int
Select @NewsPaymentsToCreate = count(distinct P.ChainName)
From DataTrue_EDI..ProcessStatus P
where P.ChainName in (
					select EntityIdentifier
					from ProcessStepEntities 
					where ProcessStepName in ('prBilling_Inbound820Payments_From_Billing_Create_Newspaper') and IsActive = 1
					)
and P.Date = CONVERT(date, Getdate())
and P.AllFilesReceived = 1
and P.BillingIsRunning = 1
and P.BillingComplete = 0
and P.RecordTypeID = 2

If @NewsPaymentsToCreate > 0
	
	Begin

		exec dbo.prBilling_Inbound820Payments_From_Billing_Create_Newspaper
		exec dbo.prBilling_Payment_Create_LG

	End

Declare @SBTPaymentsToCreate int
Select @SBTPaymentsToCreate = count(distinct P.ChainName)
From DataTrue_EDI..ProcessStatus P
where P.ChainName in (
					select EntityIdentifier
					from ProcessStepEntities 
					where ProcessStepName in ('prBilling_Inbound820Payments_From_Billing_Create_SBT') and IsActive = 1
					)
and P.Date = CONVERT(date, Getdate())
and P.AllFilesReceived = 1
and P.BillingIsRunning = 1
and P.BillingComplete = 0
and P.RecordTypeID = 2

If @SBTPaymentsToCreate > 0 

	Begin

		exec dbo.prBilling_Inbound820Payments_From_Billing_Create_SBT
		exec dbo.prBilling_Payment_Create_SBT

	End
END
End
GO
