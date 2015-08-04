USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SetTopMenus]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_SetTopMenus]
( 
 @LoginID varchar(100)
)
AS
BEGIN
--select * from AssignUserRoles
	Select distinct W.verticalid,V.VerticalName 
	from AssignUserRoles_New A
	inner join UserRoles_New U on U.RoleID=A.RoleID
	inner JOIN RoleMenus_New M ON M.RoleID=A.RoleID
	inner JOIN WebMenus_New W ON W.MenuId=M.MenuID
	LEFT JOIN Verticals_New V ON V.VerticalID=W.VerticalID
	where UserId=@LoginID
	order BY W.verticalid
		
END
GO
