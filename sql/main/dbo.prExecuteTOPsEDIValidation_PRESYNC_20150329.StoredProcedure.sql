USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prExecuteTOPsEDIValidation_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Joshua Kiracofe
-- Create date: 2014-12-10
-- Description:	Checks to see if TOPs is running, and executes the validation
-- =============================================
CREATE PROCEDURE [dbo].[prExecuteTOPsEDIValidation_PRESYNC_20150329] 
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    
    Declare @TopsRunning int
    Select @TopsRunning = COUNT(Distinct ChainName)
						From DataTrue_EDI..ProcessStatus
						Where ChainName = 'TOP'
						and BillingComplete = 0
						and BillingIsRunning = 1
						and AllFilesReceived = 1
						and RecordTypeID = 2
						
	If @TopsRunning = 0
		Begin
			exec dbo.prValidateTOPS_Billing_EDI
		End
END
GO
