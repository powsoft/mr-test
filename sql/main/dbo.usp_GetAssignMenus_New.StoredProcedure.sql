USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetAssignMenus_New]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create procedure [dbo].[usp_GetAssignMenus_New]
	@RoleId varchar(20),
	@VerticalId varchar(20)
as
begin

Select W.MenuID, case when M.ParentMenuID=0 then W.MenuName ELSE '-->' + W.MenuName END as MenuName
	from RoleMenus_New M
	inner JOIN WebMenus_New W ON W.MenuId=M.MenuID
	where M.RoleID=@RoleId and W.ActiveStatus=1 and W.VerticalId=@VerticalId
	order BY M.MenuOrder
end
GO
