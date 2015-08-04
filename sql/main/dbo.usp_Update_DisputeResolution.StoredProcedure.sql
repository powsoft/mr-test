USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Update_DisputeResolution]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_Update_DisputeResolution]
	@PaymentId VARCHAR(50),
	@PaymentBasedOn varchar(20),
	@StoreId VARCHAR(50),
	@ProductId VARCHAR(50),
	@CorrectRecord VARCHAR(50),
	@PostOffValue varchar(20),
	@DifferenceAmount VARCHAR(50),
	@Comments VARCHAR(50),
	@UserId VARCHAR(50),
	@Old_Qnt varchar(20),
	@Old_Cost VARCHAR(50),
	@New_Qnt varchar(20),
	@New_Cost VARCHAR(50)
	
AS
BEGIN

	Delete from [DataTrue_Main].[dbo].[DisputeResolution] where PaymentId=@PaymentId and StoreId=@StoreId and ProductId=@ProductId 	
	
	IF(@PostOffValue='')
		set @PostOffValue=NULL
	
	IF(@DifferenceAmount='')
		set @DifferenceAmount=NULL
			
	INSERT INTO [DataTrue_Main].[dbo].[DisputeResolution]
           ([ReconcileDate],[PaymentId],[PaymentBasedOn],[StoreId],[ProductId],[CorrectRecord],[PostOffValue],[DifferenceAmount],[Comments],[LastUpdateUserId],[PaymentProcessed],Old_Qnt,Old_Cost,New_Qnt,New_Cost)
     VALUES
           (getdate(), @PaymentId, @PaymentBasedOn, @StoreId, @ProductId,@CorrectRecord,@PostOffValue, @DifferenceAmount,@Comments,@UserId,0,@Old_Qnt,@Old_Cost,@New_Qnt,@New_Cost )
END
GO
