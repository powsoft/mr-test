USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_AssignMenusToRoles]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_AssignMenusToRoles]
(
@RoleID int,
@MenuID int,
@ParentID int,
@OrderID int
)
as
begin

Declare @MenuOldID Varchar(20)
	Insert INTO RoleMenus
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
