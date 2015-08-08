USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_ChangeAccountPassword_API]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[usp_ChangeAccountPassword_API]
(
 @CurrentUserId nvarchar(50),
 @LoginId nvarchar(50),
 @LoginPassword nvarchar(50),
 @PasswordSalt nvarchar(100)
)

as 
begin
	
	UPDATE ASPNETDB.dbo.aspnet_Membership
    SET    Password = @LoginPassword,
           LastPasswordChangedDate = GETDATE(),
           PasswordSalt = @PasswordSalt
    WHERE  UserId =@LoginId
    
	UPDATE dbo.Logins SET Password = @LoginPassword, LastUpdateUserID=@CurrentUserId, DateTimeLastUpdate=GETDATE() WHERE OwnerEntityId=@LoginId 
end
GO
