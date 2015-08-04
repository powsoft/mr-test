USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Payment_Disbursements]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_Payment_Disbursements]
	@PaymentId VARCHAR(50),
	@MyID VARCHAR(50),
	@StartCheckno VARCHAR(50),
	@BatchNo varchar(20),
	@DisbursementDate varchar(50)
AS
BEGIN

	DECLARE @disbursementid AS int
	
	if not Exists(SELECT  * from PaymentHistory where PaymentID=@PaymentId and DisbursementID>0)
	begin 
		INSERT INTO [DataTrue_Main].[dbo].[PaymentDisbursements]
					   ([DisbursementAmount]
					   ,[CheckNo]
					   ,[LastUpdateUserID]
					   ,[BatchNo]
					   ,[DisbursementDate])
			select SUM(p.AmountOriginallyBilled)
						,@StartCheckno
						,@MyID
						,@BatchNo
						,@DisbursementDate
						from Payments p
			where p.PaymentID =@PaymentId					
			set @disbursementid = SCOPE_IDENTITY()
		
		update p set p.PaymentStatus = 10 --DisbursedByCheck
		from Payments p where p.PaymentID =@PaymentId
		
		
		
		INSERT INTO [DataTrue_Main].[dbo].[PaymentHistory]
				   ([PaymentID]
				   ,[LastUpdateUserID]
				   ,[PaymentStatus]
				   ,[PaymentStatusChangeDateTime]
				   ,[DisbursementID]
				   ,[AmountPaid]
				   ,CheckNoReceived
				   ,DatePaymentReceived
				   )
			select P.PaymentID, @MyID, 10, GETDATE(), @disbursementid, M.AmountOriginallyBilled, CheckNoReceived, DatePaymentReceived
			from PaymentHistory P
			inner join Payments M on M.PaymentID=P.PaymentId
			where p.PaymentID =@PaymentId and P.PaymentStatus in (3,4)
			
			update d set d.LastDisbursementDateTime = @DisbursementDate ,d.NextDisbursementDateTime = dateadd(day, d.PaymentDisbursementReleaseControlPeriodInDays + d.PaymentDisbursementReleaseControlAdjDelayInDays, @DisbursementDate) ,d.datetimelastupdate = GETDATE(), d.LastUpdateUserID = @MyID from Payments p inner join PaymentDisbursementReleaseControl d on p.PayeeEntityID = d.PaymentDisbursementPayeeEntityID where p.PaymentID =@PaymentId
		end 
	
END
GO
