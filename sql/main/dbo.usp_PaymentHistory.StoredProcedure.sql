USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_PaymentHistory]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_PaymentHistory]
@PaymentId varchar(10)
as
-- [usp_PaymentHistory] '642'
BEGIN

	Select STAT.StatusName, PH.PaymentStatusChangeDateTime AS [Status Date], 
	PH.AmountPaid AS [Payment Amount], ISNULL(PH.CheckNoReceived,'-') AS [Check No Received], 
	(PH.DatePaymentReceived) AS [Payment Date], ISNULL(PH.Comments,'-') AS Comments 
	from PaymentHistory PH
	Left join Statuses STAT on STAT.StatusIntValue = PH.PaymentStatus and STAT.StatusTypeID = 14 --STAT.statusid=PM.PaymentStatus
	where PH.PaymentID=@PaymentId 
	ORDER BY PH.PaymentStatus

END
GO
