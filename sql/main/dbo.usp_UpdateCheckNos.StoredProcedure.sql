USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UpdateCheckNos]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_UpdateCheckNos]

 @BatchNo varchar(20),
 @CurrentCheckNo varchar(50),
 @StartCheckNo varchar(50),
 @EndCheckNo varchar(50),
 @NewCheckNo varchar(50),
 @ApplyTo varchar(50),
 @CurrentUserId varchar(10)
        
as
begin
	if(@ApplyTo=1)		
		UPDATE [PaymentDisbursements]
		   SET [CheckNo] = @NewCheckNo
			  ,[LastUpdateUserID] = @CurrentUserId
		 WHERE [BatchNo] = @BatchNo and CheckNo=@CurrentCheckNo
	else
		WHILE (@StartCheckNo <= @EndCheckNo)
		BEGIN
			UPDATE [PaymentDisbursements]
			SET [CheckNo] = @NewCheckNo
			  ,[LastUpdateUserID] = @CurrentUserId
			WHERE [BatchNo] = @BatchNo and CheckNo=@StartCheckNo
		 
			Set @StartCheckNo = @StartCheckNo + 1
			Set @NewCheckNo = @NewCheckNo + 1
		END 
end
GO
