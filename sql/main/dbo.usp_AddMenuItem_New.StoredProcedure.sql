USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_AddMenuItem_New]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_AddMenuItem_New]
  @MenuId varchar(10),
  @MenuName varchar(50),
  @ParentMenuId varchar(10),
  @SupplierPageURL varchar(50),
  @RetailerPageURL varchar(50),
  @ManufacturerPageURL varchar(50),
  @VerticalId varchar(20),
  @ActiveStatus varchar(10),
  @UserId varchar(10),
  @imagePath varchar(500),
  @MenuDescription varchar(500),
  @DefaultPageImage varchar(500),
  @ParamName varchar(500)
  
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
		  Update WebMenus_New set 
			   MenuName=@MenuName
			   , LastModifiedDate=GETDATE()
			   , LastUpdatedBy=@UserID
			   , ActiveStatus=@ActiveStatus
			   , ParentMenuId=@ParentMenuId
			   , SupplierPageURL=@SupplierPageURL
			   , RetailerPageURL=@RetailerPageURL
			   , ManufacturerPageURL = @ManufacturerPageURL
			   , VerticalId=@VerticalId
			   , MainIcon=case WHEN @imagePath IS NOT NULL THEN @imagePath ELSE MainIcon end
			   , MenuDescription=@MenuDescription
			   , DefaultPageIcon=case WHEN @DefaultPageImage IS NOT NULL THEN @DefaultPageImage ELSE DefaultPageIcon end
			   ,ParamName=@ParamName
		  where MenuID=@MenuId
 else
		  Insert INTO WebMenus_New
		  (
			   MenuName
			   , ParentMenuId
			   , ActiveStatus
			   , LastUpdatedBy
			   , LastModifiedDate
			   , SupplierPageURL
			   , RetailerPageURL
			   , ManufacturerPageURL
			   , VerticalId
			   , MainIcon
			   , MenuDescription
			   , DefaultPageIcon
			   ,ParamName
		  ) 
		  values
		  (
			   @MenuName
			   , @ParentMenuId
			   , @ActiveStatus
			   , @UserId
			   , getdate()
			   , @SupplierPageURL
			   , @RetailerPageURL
			   , @ManufacturerPageURL
			   , @VerticalId
			   , @imagePath
			   , @MenuDescription
			   , @DefaultPageImage
			   ,@ParamName
		  )
END
GO
