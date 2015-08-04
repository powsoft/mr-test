USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_CheckAlcoholHomePage]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_CheckAlcoholHomePage]
	@UserId NVARCHAR(100)
AS 
BEGIN
	select distinct (W.verticalId) from AssignUserRoles_New A 
	inner join UserRoles_New R on R.RoleID=A.RoleID 
	inner join Logins L on L.OwnerEntityId=A.UserID 
	inner join RoleMenus_New RM on RM.RoleId=R.RoleId
	inner join webmenus_new w on W.Menuid=RM.MenuId
	where L.Login=@UserId and W.VerticalId<>8

End
GO
