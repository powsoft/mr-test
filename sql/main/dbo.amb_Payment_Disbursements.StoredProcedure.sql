USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_Payment_Disbursements]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[amb_Payment_Disbursements]
	@PaymentId VARCHAR(50),
	@MyID VARCHAR(50),
	@StartCheckno VARCHAR(50),
	@BatchNo varchar(20)
AS
BEGIN

	DECLARE @disbursementid AS int
	
	INSERT INTO [PaymentDisbursements]
				   ([DisbursementAmount]
				   ,[CheckNo]
				   ,[LastUpdateUserID],[BatchNo])
		select SUM(p.AmountOriginallyBilled)
					,@StartCheckno
					,@MyID,@BatchNo
					from Payments p
		where p.PaymentID =@PaymentId
						
		set @disbursementid = SCOPE_IDENTITY()
		
		
	UPDATE p set p.PaymentStatus = 10 --DisbursedByCheck
	from Payments p where p.PaymentID =@PaymentId
		
	INSERT INTO [PaymentHistory]
				   ([PaymentID]
				   ,[LastUpdateUserID]
				   ,[PaymentStatus]
				   ,[PaymentStatusChangeDateTime]
				   ,[DisbursementID]
				   ,[AmountPaid]
				   ,CheckNoReceived
				   ,DatePaymentReceived
				   )
			select P.PaymentID, @MyID, 10, GETDATE(), @disbursementid, AmountPaid, CheckNoReceived, DatePaymentReceived
			from PaymentHistory P
			where p.PaymentID =@PaymentId and P.PaymentStatus in (3,4)
			
			
			
	UPDATE d set d.LastDisbursementDateTime = GETDATE(), 
				 d.NextDisbursementDateTime = dateadd(day, d.PaymentDisbursementReleaseControlPeriodInDays + d.PaymentDisbursementReleaseControlAdjDelayInDays, d.LastDisbursementDateTime),
				 d.datetimelastupdate = GETDATE(), 
				 d.LastUpdateUserID = @MyID--DisbursedByCheck
	from Payments p 
		inner join PaymentDisbursementReleaseControl d on p.PayeeEntityID = d.PaymentDisbursementPayeeEntityID 
	where p.PaymentID =@PaymentId

END
GO
