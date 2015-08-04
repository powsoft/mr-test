USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[USP_CheckDaily_BillingControlRecords]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Joshua Kiracofe
-- Create date: 4/3/2015
-- Description:	Check Daily Billing Control Records for unbilled chains, and update if needed.
-- =============================================
CREATE PROCEDURE [dbo].[USP_CheckDaily_BillingControlRecords] 
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	Declare @ChainsToUpdate int

Select @ChainsToUpdate = COUNT(Distinct Billingcontrolid)
from BillingControl B
Inner Join Chains C On C.ChainID = B.ChainID
where BusinessTypeID in (1, 4)
and BillingControlFrequency = 'Daily'
And IsActive = 1
and ChainIdentifier not in (Select ChainName from DataTrue_EDI..ProcessStatus Where Date = CONVERT(date, getdate()) and BillingComplete = 1)
and convert(date, NextBillingPeriodRunDateTime) <> CONVERT(date, getdate())

If @ChainsToUpdate > 0
	Begin
	
	Update B Set NextBillingPeriodRunDateTime = CONVERT(date, getdate()), 
	NextBillingPeriodEndDateTime = DATEADD(day, -1, Convert(date, getdate())),
	LastBillingPeriodEndDateTime = DATEADD(Day, -2, Convert(date, getdate()))
	from BillingControl B
	Inner Join Chains C On C.ChainID = B.ChainID
	where BusinessTypeID in (1, 4)
	and BillingControlFrequency = 'Daily'
	And IsActive = 1
	and ChainIdentifier not in (Select ChainName from DataTrue_EDI..ProcessStatus Where Date = CONVERT(date, getdate()) and BillingComplete = 1)
	and convert(date, NextBillingPeriodRunDateTime) <> CONVERT(date, getdate())
	
	
	End

END
GO
