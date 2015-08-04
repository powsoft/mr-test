USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SaveUserMenus]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_SaveUserMenus]
     @UserID int,
     @MenuID int
as
begin

			INSERT INTO [dbo].[UserMenus]
					   ([UserId]
					   ,[MenuId]
					   )
				 VALUES
						 (
						 @UserID,
						 @MenuID
						 )
end
GO
