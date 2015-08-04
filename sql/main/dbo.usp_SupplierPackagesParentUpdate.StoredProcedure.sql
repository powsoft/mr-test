USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SupplierPackagesParentUpdate]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_SupplierPackagesParentUpdate]
	@ParentPackageId varchar(100),
	@ChildPackageId varchar(100),
	@OwnerPackageIdentifier varchar(100),
	@OwnerPackageDescription varchar(200),
	@OwnerPackageSizeDescription varchar(200),
	@OwnerPackageQty varchar(10),
	@ThisPackageUOMBasis varchar(100),
	@ThisPackageUOMBasisQty varchar(10),
	@ThisPackageEACHBasisQty varchar(10),
	@AllowReorder bit,
	@AllowReclaim bit
as
begin
	--Update Parent UPC
	Update
	 SupplierPackages
	SET
		OwnerPackageIdentifier=@OwnerPackageIdentifier,
		OwnerPackageDescription=@OwnerPackageDescription,
		OwnerPackageSizeDescription=@OwnerPackageSizeDescription,
		OwnerPackageQty=@OwnerPackageQty,
		ThisPackageUOMBasis=@ThisPackageUOMBasis,
		ThisPackageUOMBasisQty=@ThisPackageUOMBasisQty,
		ThisPackageEACHBasisQty=@ThisPackageEACHBasisQty,
		AllowReorder=@AllowReorder,
		AllowReclaim=@AllowReclaim,
		InnerPackageID=@ChildPackageId
	Where 
		SupplierPackageID=@ParentPackageId
		
end
GO
