USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_Payment_Disbursements_Create_manually]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[prBilling_Payment_Disbursements_Create_manually] 
	@PayeeEntityID VARCHAR(50),
	@PaymentStatus VARCHAR(10),
	@MyID VARCHAR(50),
	@StartCheckno VARCHAR(50),
	@TotalPaid MONEY
AS
BEGIN
	DECLARE @maxcheckno AS int
	DECLARE @disbursementid AS int
	
	INSERT INTO [DataTrue_Main].[dbo].[PaymentDisbursements]
				   ([DisbursementAmount]
				   ,[CheckNo]
				   ,[LastUpdateUserID])
		select SUM(p.AmountOriginallyBilled)
					,@StartCheckno
					,@MyID
					from Payments p
		where p.PaymentStatus =@PaymentStatus
		and p.PayeeEntityID = @payeeentityid
					
		set @disbursementid = SCOPE_IDENTITY()
		
		
		update p set p.PaymentStatus = 10 --DisbursedByCheck
		from Payments p where p.PayeeEntityID = @payeeentityid
		
		
		
		INSERT INTO [DataTrue_Main].[dbo].[PaymentHistory]
				   ([PaymentID]
				   ,[LastUpdateUserID]
				   ,[PaymentStatus]
				   ,[PaymentStatusChangeDateTime]
				   ,[DisbursementID]
				   ,[AmountPaid]
				   )
			select PaymentID, @MyID, 10, GETDATE(), @disbursementid,@TotalPaid
			from Payments p where p.PayeeEntityID = @payeeentityid
			
			
			update d set d.LastDisbursementDateTime = GETDATE()
			,d.NextDisbursementDateTime = dateadd(day, d.PaymentDisbursementReleaseControlPeriodInDays + d.PaymentDisbursementReleaseControlAdjDelayInDays, d.LastDisbursementDateTime)
			,d.datetimelastupdate = GETDATE(), d.LastUpdateUserID = @MyID--DisbursedByCheck
		from Payments p inner join PaymentDisbursementReleaseControl d on p.PayeeEntityID = d.PaymentDisbursementPayeeEntityID where p.PayeeEntityID = @payeeentityid
			 
		
	
END
GO
