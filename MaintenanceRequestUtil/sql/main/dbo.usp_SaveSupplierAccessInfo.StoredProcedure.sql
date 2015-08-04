USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SaveSupplierAccessInfo]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_SaveSupplierAccessInfo]
 @PersonId varchar(50),
 @SupplierId varchar(50),
 @OldSupplierId varchar(50),
 @EditRights varchar(20),
 @Banner varchar(50)
       
as
begin
    if(@OldSupplierId='0')
		INSERT INTO [DataTrue_Main].[dbo].[SupplierAccess]
		([PersonId],[SupplierId],[EditRights],[BannerAccess])
		VALUES(@PersonId, @SupplierId, @EditRights, @Banner)
    else
		UPDATE [DataTrue_Main].[dbo].[SupplierAccess]
		SET [SupplierId] = @SupplierId,
		[EditRights] = @EditRights,
		[BannerAccess] = @Banner
		WHERE PersonId=@PersonId and SupplierId=@OldSupplierId
end
GO
