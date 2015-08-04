USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_UpdateRetailerCheckNos]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  Procedure [dbo].[amb_UpdateRetailerCheckNos]
 @PaymentID int,
 @CurrentCheckNo varchar(50),
 @NewCheckNo varchar(50),
 @CheckDate varchar(10),
 @CurrentUserId varchar(10)
        
as
begin
		UPDATE PaymentHistory
		   SET CheckNoReceived = @NewCheckNo
			  ,DatePaymentReceived=@CheckDate
			  ,[LastUpdateUserID] = @CurrentUserId
		 WHERE [PaymentID] = @PaymentID and CheckNoReceived=@CurrentCheckNo

end
GO
