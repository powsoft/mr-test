USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetMenueList]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec usp_GetMenueList '11','1'
CREATE procedure [dbo].[usp_GetMenueList]
	@RoleId varchar(20)
as
begin

declare @RoleTypeID varchar(20)
declare @VerticalId varchar(20)

	Select @RoleTypeID = RoleTypeID, @VerticalId=VerticalID	 from UserRoles where RoleID = @RoleId 

	Select W.MenuID, 
	case when isnull(W.ParentMenuId,0)=0 then W.MenuName ELSE '-->' + W.MenuName END as MenuName
	from WebMenus W 
	where W.ActiveStatus=1 and VerticalID=@VerticalId	
		and W.MenuId not in (SELECT MenuId from RoleMenus where RoleID=@RoleId AND W.ParentMenuId>0)
		and isnull(case when @RoleTypeID=9 then W.SupplierPageURL when @RoleTypeID=17 then W.RetailerPageURL ELSE W.ManufacturerPageURL end,1) <> ''
	order BY W.MenuId
													
end
GO
