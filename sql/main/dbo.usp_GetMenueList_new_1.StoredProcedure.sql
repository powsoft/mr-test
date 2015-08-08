USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetMenueList_new_1]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec usp_GetMenueList_new_1 '21','2','20'
CREATE procedure [dbo].[usp_GetMenueList_new_1]
	@RoleId varchar(20),
	@VerticalId varchar(20),
	@CurrentRoleId varchar(20)
as
begin

declare @RoleTypeID varchar(20)
	
	if(@VerticalId='0')
		Select @RoleTypeID = RoleTypeID, @VerticalId=VerticalID	 from UserRoles_New where RoleID = @RoleId 
	else
		Select @RoleTypeID = RoleTypeID from UserRoles_New where RoleID = @RoleId 

	Declare @sqlQuery varchar(4000)
	set @sqlQuery = 'Select W.MenuID, 
										case when isnull(W.ParentMenuId,0)=0 then W.MenuName ELSE ''-->'' + W.MenuName END as MenuName
										from WebMenus_New W 
										where W.ActiveStatus=1 and VerticalID=' + @VerticalId + '	
											and W.MenuId not in (SELECT MenuId from RoleMenus_New where RoleID=' +@RoleId+ ' AND W.ParentMenuId>0)
											and isnull(case when '+@RoleTypeID+'=9 then W.SupplierPageURL when '+@RoleTypeID+'=17 then W.RetailerPageURL ELSE W.ManufacturerPageURL end,1) <> ''''
										 '
										 
 IF(@CurrentRoleId <> '')
	set @sqlQuery = @sqlQuery + ' and W.MenuId in (SELECT MenuId from RoleMenus_New where RoleID=' +@CurrentRoleId+ ')'	
	
 set @sqlQuery = @sqlQuery + ' order BY W.MenuId '	
 
 exec(@sqlQuery); 
 print(@sqlQuery); 
													
end
GO
