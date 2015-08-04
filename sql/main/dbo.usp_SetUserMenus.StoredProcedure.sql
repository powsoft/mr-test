USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SetUserMenus]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_SetUserMenus]
( 
 @LoginID varchar(100)
)
AS
BEGIN

	Select W1.MenuName as ParentMenu, W.MenuName, W.MenuID,M.MenuOrder,
	Case WHEN U.RoleTypeID=17 THEN W.RetailerPageURL WHEN U.RoleTypeID=9 THEN W.SupplierPageURL WHEN U.RoleTypeID=23 THEN W.ManufacturerPageURL END as  PageURL
	from AssignUserRoles A
	inner join UserRoles U on U.RoleID=A.RoleID
	inner JOIN RoleMenus M ON M.RoleID=A.RoleID
	inner JOIN WebMenus W ON W.MenuId=M.MenuID
	Inner JOIN WebMenus W1 ON W1.MenuId=M.ParentMenuID
	where UserId=@LoginID
	order BY M.MenuOrder
		
END
GO
