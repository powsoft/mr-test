USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_AddUserRoles_New]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_AddUserRoles_New]
  @RoleId varchar(10),
  @RoleName varchar(50),
  @RoleTypeID varchar(10),
  @ActiveStatus varchar(10),
  @UserId varchar(10),
  @VerticalId varchar(10),
  @ShowTabView varchar(10),
  @AdminType varchar(10),
  @IsRegulated int
AS

BEGIN
	if(@RoleId>0)
		Update UserRoles_New set 
			RoleName=@RoleName, 
			LastModifiedDate=GETDATE(), 
			LastUpdatedBy=@UserID, 
			ActiveStatus=@ActiveStatus, 
			RoleTypeID=@RoleTypeID,
			VerticalID=@VerticalId,
			ShowTabView=@ShowTabView,
			IsAdmin = case when @AdminType=1 then 1 else 0 end,
			IsPDIAdmin = case when @AdminType=2 then 1 else 0 end,
			IsRegulated = @IsRegulated
		where RoleID=@RoleId
	else
		Insert INTO UserRoles_New
		(
			RoleName,
			RoleTypeID,
			ActiveStatus,
			LastUpdatedBy,
			LastModifiedDate,
			VerticalID,
			ShowTabView,
			IsAdmin,
			IsPDIAdmin,
			IsRegulated
		) 
		values
		(
			@RoleName,
			@RoleTypeID,
			@ActiveStatus,
			@UserId,
			getdate(),
			@VerticalId,
			@ShowTabView,
			case when @AdminType=1 then 1 else 0 end,
			case when @AdminType=2 then 1 else 0 end,
			@IsRegulated
		)
END
GO
