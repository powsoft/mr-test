USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_AddShrinkRules]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_AddShrinkRules]
 @SID int,
 @ChainID varchar(50),
 @SupplierID varchar(50),
 @Banner varchar(100),
 @ShrinkCalculation varchar(100),
 @OtherOptions varchar(100),
 @UserID int
        
as
begin
		
	if(@SID=0)		
		INSERT INTO [ShrinkRules]
           ([ChainID]
           ,[SupplierID]
           ,[Banner]
           ,[ShrinkCalculationMethod]
           ,[NoCountSubmittedOnUPCWithinStoreCount]
           ,[DateTimeCreated]
           ,[DateTimeUpdated]
           ,[LastUpdateUserID]
           ,[IsDelete])
		VALUES
           (@ChainID
           ,@SupplierID
           ,@Banner
           ,@ShrinkCalculation
           ,@OtherOptions
           ,getdate()
           ,getdate()
           ,NULL
           ,0)
           
	else 
		begin
			UPDATE [ShrinkRules]
		   SET [ChainID] = @ChainID
			  ,[SupplierID] = @SupplierID
			  ,[Banner] = @Banner
			  ,[ShrinkCalculationMethod] = @ShrinkCalculation
			  ,[NoCountSubmittedOnUPCWithinStoreCount] = @OtherOptions
			  ,[DateTimeUpdated] = getdate()
			  ,[LastUpdateUserID] = @UserID
			 WHERE [SID] = @SID
		end	 
end
GO
