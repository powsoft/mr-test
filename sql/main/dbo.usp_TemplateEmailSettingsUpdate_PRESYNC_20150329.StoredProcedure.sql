USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_TemplateEmailSettingsUpdate_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[usp_TemplateEmailSettingsUpdate_PRESYNC_20150329]
@ID INT,
@TemplateName NVARCHAR(100),
@ContactPersonName NVARCHAR(50),
@ContactPersonEmail NVARCHAR(1000),
@UserID INT

AS

BEGIN
	IF(@ID = 0)
		BEGIN
			INSERT INTO [dbo].[TemplateEmailSettings]
				   ([TemplateName]
				   ,[ContactPersonName]
				   ,[ContactPersonEmail]
				   ,[UserID]
				   ,[DateTimeUpdated])
			 VALUES
				   (@TemplateName
				   ,@ContactPersonName
				   ,@ContactPersonEmail
				   ,@UserID
				   ,GETDATE())
		END
	ELSE 
		BEGIN
			UPDATE [dbo].[TemplateEmailSettings]
			   SET [TemplateName] = @TemplateName
				  ,[ContactPersonName] = @ContactPersonName
				  ,[ContactPersonEmail] = @ContactPersonEmail
				  ,[UserID] = @UserID
				  ,[DateTimeUpdated] = GETDATE()
			 WHERE [ID] = @ID
		END
END
GO
