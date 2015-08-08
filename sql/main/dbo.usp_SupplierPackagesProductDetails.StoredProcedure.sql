USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SupplierPackagesProductDetails]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_SupplierPackagesProductDetails]
	@UPC varchar(100),
	@ChainId varchar(10)
as
begin
SELECT 
	P.IdentifierValue as UPC,
	S.SupplierPackageID as PackageId,
	S.VIN,
	S.Purchasable,
	S.Sellable,
	S.OwnerPackageIdentifier,
	S.OwnerPackageDescription,
	S.OwnerPackageSizeDescription,
	S.OwnerPackageQty,
	S.ThisPackageUOMBasis,
	S.ThisPackageUOMBasisQty,
	S.ThisPackageEACHBasisQty,
	S.AllowReorder,
	S.AllowReclaim
FROM SupplierPackages S
LEFT OUTER JOIN ProductIdentifiers P ON S.ProductID=P.ProductID AND P.ProductIdentifierTypeID=2
Where 
	S.OwnerEntityID=@ChainId
	and P.IdentifierValue=@UPC
end
GO
