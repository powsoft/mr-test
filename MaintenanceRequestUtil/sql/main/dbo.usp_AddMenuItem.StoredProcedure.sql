USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_AddMenuItem]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_AddMenuItem]
  @MenuId varchar(10),
  @MenuName varchar(50),
  @ParentMenuId varchar(10),
  @SupplierPageURL varchar(50),
  @RetailerPageURL varchar(50),
  @ManufacturerPageURL varchar(50),
  @VerticalId varchar(20),
  @ActiveStatus varchar(10),
  @UserId varchar(10)
  
AS

BEGIN
	if(@ParentMenuId='-1')
	Begin
		set @ParentMenuId = NULL
		set @SupplierPageURL = NULL
		set @RetailerPageURL = NULL
		set @ManufacturerPageURL = NULL
	End
	
	if(@MenuId>0)
		Update WebMenus set 
			MenuName=@MenuName, 
			LastModifiedDate=GETDATE(), 
			LastUpdatedBy=@UserID, 
			ActiveStatus=@ActiveStatus, 
			ParentMenuId=@ParentMenuId,
			SupplierPageURL=@SupplierPageURL,
			RetailerPageURL=@RetailerPageURL,
			ManufacturerPageURL = @ManufacturerPageURL,
			VerticalId=@VerticalId
		where MenuID=@MenuId
	else
		Insert INTO WebMenus
		(
			MenuName,
			ParentMenuId,
			ActiveStatus,
			LastUpdatedBy,
			LastModifiedDate,
			SupplierPageURL,
			RetailerPageURL,
			ManufacturerPageURL,
			VerticalId
		) 
		values
		(
			@MenuName,
			@ParentMenuId,
			@ActiveStatus,
			@UserId,
			getdate(),
			@SupplierPageURL,
			@RetailerPageURL,
			@ManufacturerPageURL,
			@VerticalId
		)
END
GO
