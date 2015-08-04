USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SetUserMenus_New]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_SetUserMenus_New]
( 
 @LoginID varchar(100),
 @VerticalID varchar(250)
)
AS
BEGIN
--exec usp_SetUserMenus_New 40384,4
Declare @verticalIDTem varchar(250)
IF(@VerticalID=-1)
begin
	Select TOP 1 @verticalIDTem=W1.verticalid
	from AssignUserRoles_New A
	inner join UserRoles_New U on U.RoleID=A.RoleID
	inner JOIN RoleMenus_New M ON M.RoleID=A.RoleID
	inner JOIN WebMenus_New W ON W.MenuId=M.MenuID
	Inner JOIN WebMenus_New W1 ON W1.MenuId=M.ParentMenuID
	LEFT JOIN Verticals_New V ON V.VerticalID=W1.VerticalID
	where UserId=@LoginID
	order BY W1.verticalid 
	END
else
	Set @verticalIDTem=@VerticalID
	Select W1.MenuName as ParentMenu,W1.MainIcon, W.MenuName, W.MenuID,M.MenuOrder,W1.verticalid,
	Case WHEN U.RoleTypeID=17 THEN W.RetailerPageURL WHEN U.RoleTypeID=9 THEN W.SupplierPageURL WHEN U.RoleTypeID=23 THEN W.ManufacturerPageURL END as  PageURL
	from AssignUserRoles_New A
	inner join UserRoles_New U on U.RoleID=A.RoleID
	inner JOIN RoleMenus_New M ON M.RoleID=A.RoleID
	inner JOIN WebMenus_New W ON W.MenuId=M.MenuID
	Inner JOIN WebMenus_New W1 ON W1.MenuId=M.ParentMenuID
	--where UserId=@LoginID and W1.verticalid=@verticalIDTem
	where UserId=@LoginID 
	order BY M.MenuOrder
		
END
GO
