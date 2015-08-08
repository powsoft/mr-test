USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SaveAssignUserRoles]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_SaveAssignUserRoles]
     @UserID varchar(50),
     @RoleID int
as
begin
			DELETE FROM AssignUserRoles where UserID = @UserID
			
			INSERT INTO [dbo].[AssignUserRoles]
					   ([UserID],
					    [RoleID]
					   )
				 VALUES
						 (
						 @UserID,
						 @RoleID
						 )
end
GO
