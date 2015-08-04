USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetAssignMenus]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_GetAssignMenus]
	@RoleId varchar(20)
as
begin

Select W.MenuID, case when M.ParentMenuID=0 then W.MenuName ELSE '-->' + W.MenuName END as MenuName
	from RoleMenus M
	inner JOIN WebMenus W ON W.MenuId=M.MenuID
	where M.RoleID=@RoleId and W.ActiveStatus=1
	order BY M.MenuOrder
end
GO
