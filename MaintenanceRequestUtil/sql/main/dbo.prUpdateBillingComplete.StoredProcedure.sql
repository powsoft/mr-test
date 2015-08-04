USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUpdateBillingComplete]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Joshua Kiracofe
-- Create date: 11/25/2014
-- Description:	Updates the Billing Complete field on the Process Status table on EDI.
-- =============================================
CREATE PROCEDURE [dbo].[prUpdateBillingComplete]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

			Update J Set BillingComplete = 1
			--Select *
			from DataTrue_EDI..ProcessStatus J
			where 1=1
			and AllFilesReceived = 1
			and BillingIsRunning = 1
			and BillingComplete = 0
			and Date = convert(date, getdate())
			and RecordTypeID = 2

END
GO
