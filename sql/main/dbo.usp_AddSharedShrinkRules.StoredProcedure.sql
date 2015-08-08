USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_AddSharedShrinkRules]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_AddSharedShrinkRules]
 @SSID int,
 @ChainID varchar(50),
 @SupplierID varchar(50),
 @Banner varchar(100),
 @SharedShrinkMax varchar(100),
 @MaxShrinkCap varchar(100),
 @UserID int
        
as
begin
		
	if(@SSID=0)		
		INSERT INTO [SharedShrinkRules]
           ([ChainID]
           ,[SupplieriD]
           ,[Banner]
           ,[SharedShrinkMaxCalculated]
           ,[MaxShrinkCapAppliedToMaxPercentages]
           ,[DateTimeCreated]
           ,[DateTimeUpdated]
           ,[LastUpdateUserID]
           ,[IsDelete])
		VALUES
           (@ChainID
           ,@SupplierID
           ,@Banner
           ,@SharedShrinkMax
           ,@MaxShrinkCap
           ,getdate()
           ,getdate()
           ,NULL
           ,0)
           
	else 
		begin
			UPDATE [SharedShrinkRules]
		   SET [ChainID] = @ChainID
			  ,[SupplieriD] = @SupplierID
			  ,[Banner] = @Banner
			  ,[SharedShrinkMaxCalculated] = @SharedShrinkMax
			  ,[MaxShrinkCapAppliedToMaxPercentages] = @MaxShrinkCap
			  ,[DateTimeUpdated] = getdate()
			  ,[LastUpdateUserID]= @UserID
			 WHERE [SSID] = @SSID
		end	 
end
GO
