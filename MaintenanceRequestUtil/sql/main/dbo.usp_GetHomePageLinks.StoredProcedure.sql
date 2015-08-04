USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetHomePageLinks]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_GetHomePageLinks]
	@LoginName varchar(50)
as
begin
	
	Select W.MenuId, case when RoleTypeId=9 then SupplierPageURL when RoleTypeId=17 then RetailerPageURl else ManufacturerPageURL end  + '?vid=' + cast(W.VerticalId as varchar) + '&mid=' + cast(W.MenuId as varchar) 
	from Logins L 
	inner join AssignUserRoles_New AR on AR.UserID=L.OwnerEntityId
	inner join RoleMenus_New RM on RM.RoleID=AR.RoleID
	inner join webmenus_new W on W.MenuId=RM.MenuID
	inner join UserRoles_New R on R.RoleID=AR.RoleId
	where L.Login=@LoginName and W.MenuId in (2,3,4,30,38,43,51,61)
	order by MenuId
	
end
GO
