USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_RetailerPushRequest_879_889_Save]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[usp_RetailerPushRequest_879_889_Save]  
	 @ChainID int,
	 @PersonId int,
	 @RequestDate datetime , 
     @SupplierId int, 
     @Banner varchar(50),
     @ProductId int,
     @UPC varchar(50), 
     @CostFlag bit, 
     @PromoFlag bit,
     @Processed char(1)
     
     as 

      INSERT INTO [DataTrue_Main].[dbo].[Retailer879-889Requests]
			(
			   [ChainId]
			   ,[PersonId]
			   ,[RequestDate]
			   ,[SupplierId]
			   ,[Banner]
			   ,[ProductId]
			   ,[UPC]
			   ,[CostFlag]
			   ,[PromoFlag]
			   ,[Processed]
			)
     VALUES (
				@ChainID ,
				@PersonId ,
				@RequestDate  , 
				@SupplierId , 
				@Banner ,
				@ProductId ,
				@UPC , 
				@CostFlag , 
				@PromoFlag ,
				@Processed 
			)
        
		
Declare @iErrorCode as int
-- Get the Error Code for the statement just executed.
SELECT @iErrorCode=@@ERROR
GO
