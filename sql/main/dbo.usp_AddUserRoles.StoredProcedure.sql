USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_AddUserRoles]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_AddUserRoles]
  @RoleId varchar(10),
  @RoleName varchar(50),
  @RoleTypeID varchar(10),
  @ActiveStatus varchar(10),
  @UserId varchar(10),
  @VerticalId varchar(10),
  @ShowTabView varchar(10)
  
AS

BEGIN
	if(@RoleId>0)
		Update UserRoles set 
		RoleName=@RoleName, 
		LastModifiedDate=GETDATE(), 
		LastUpdatedBy=@UserID, 
		ActiveStatus=@ActiveStatus, 
		RoleTypeID=@RoleTypeID,
		VerticalID=@VerticalId,
		ShowTabView=@ShowTabView
		where RoleID=@RoleId
	else
		Insert INTO UserRoles
		(RoleName,
		 RoleTypeID,
		 ActiveStatus,
		 LastUpdatedBy,
		 LastModifiedDate,
		 VerticalID,
		 ShowTabView
		) 
		values
		(
		@RoleName,
		@RoleTypeID,
		@ActiveStatus,
		@UserId,
		getdate(),
		@VerticalId,
		@ShowTabView
		)
END
GO
