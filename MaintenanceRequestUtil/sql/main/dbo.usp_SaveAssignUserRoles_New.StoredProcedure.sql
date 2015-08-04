USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SaveAssignUserRoles_New]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[usp_SaveAssignUserRoles_New]
     @UserID varchar(50),
     @RoleID int
as
begin
	DELETE FROM AssignUserRoles_New where UserID = @UserID
	
	INSERT INTO [dbo].[AssignUserRoles_New]
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
