USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateDeliveryFeeCreation]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Joshua Kiracofe
-- Create date: 2014-12-09
-- Description:	Validates if there is the need to run the Delivery Fee step
-- =============================================
CREATE PROCEDURE [dbo].[prValidateDeliveryFeeCreation]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    Declare @DeliveryFeesNeeded int
	Select @DeliveryFeesNeeded = COUNT(distinct P.ChainName)
	from DataTrue_EDI..ProcessStatus P
	Inner Join Chains C
	on C.ChainIdentifier = P.ChainName
	Where P.Date = CONVERT(date, getdate())
	and P.AllFilesReceived = 1
	and P.BillingIsRunning = 1
	and P.BillingComplete = 0
	and C.ChainID in (Select EntityIdToInclude 
								from ProcessStepEntities 
								where ProcessStepName in ('prBilling_ServiceFees_Retailer_ByStoreByWeek_InvoiceDetails_Create_VersionOne'))
	--and C.ChainID Not in (65232, 60624)
	If @DeliveryFeesNeeded > 0
		Begin
			exec [dbo].[prBilling_ServiceFees_Retailer_ByStoreByWeek_InvoiceDetails_Create_VersionTwo_Test]
		END
END
GO
