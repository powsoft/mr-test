USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_AssignMenusToRoles_New]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create procedure [dbo].[usp_AssignMenusToRoles_New]
(
@RoleID int,
@MenuID int,
@ParentID int,
@OrderID int
)
as
begin

Declare @MenuOldID Varchar(20)
	Insert INTO RoleMenus_New
		(RoleId,
		MenuID,
		ParentMenuID,
		MenuOrder)
		values
		(@RoleID,
		@MenuID,
		@ParentID,
		@OrderID)		
END
GO
