USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[UpdateProcessStatusForSBT_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Joshua Kiracofe
-- Create date: 2/2/2015
-- Description:	Update Process Status Record Type Id to 0 in order to allow for ease of EDI Outbound process
-- =============================================
CREATE PROCEDURE [dbo].[UpdateProcessStatusForSBT_PRESYNC_20150415]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
		
Update P Set P.RecordTypeID = 0
--Select *
from DataTrue_EDI..ProcessStatus P
Where 1=1
and P.RecordTypeID = 2
and P.AllFilesReceived = 1
and P.BillingComplete = 1
and P.BillingIsRunning = 1
and P.Date = CONVERT(date, getdate())
And P.ChainName Not in ('SV')

END
GO
