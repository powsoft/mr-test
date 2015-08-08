USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Update_DisputeResolution_New]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_Update_DisputeResolution_New]
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
	@New_Cost VARCHAR(50),
	@PONo varchar(50),
	@InvoiceNumber varchar(50)
	
AS
BEGIN

	Delete from [DataTrue_Main].[dbo].[DisputeResolution_New] where InvoiceNumber=@InvoiceNumber and StoreId=@StoreId and ProductId=@ProductId 	
	
	IF(@PostOffValue='')
		set @PostOffValue=NULL
	
	IF(@DifferenceAmount='')
		set @DifferenceAmount=NULL
			
	INSERT INTO [DataTrue_Main].[dbo].[DisputeResolution_New]
           ([ReconcileDate],[InvoiceNumber],[PaymentId],[PaymentBasedOn],[StoreId],[ProductId],[CorrectRecord],[PostOffValue],[DifferenceAmount],[Comments],[LastUpdateUserId],[PaymentProcessed],Old_Qnt,Old_Cost,New_Qnt,New_Cost,PONo)
     VALUES
           (getdate(),@InvoiceNumber, @PaymentId, @PaymentBasedOn, @StoreId, @ProductId,@CorrectRecord,@PostOffValue, @DifferenceAmount,@Comments,@UserId,0,@Old_Qnt,@Old_Cost,@New_Qnt,@New_Cost,@PONo)
END
GO
