USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetProductCatalogParentPackageDetails]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_GetProductCatalogParentPackageDetails]
@ProductCatalogID int
AS
BEGIN

SELECT 
	PC.PackDesc,
	PC.PackUOM,
	PC.PackTotalQty,
	PC.PackInnerQty,
	PC.PackInnerQtyUOM,
	PC.Purchasable,
	PC.Sellable,
	PC.ProductCatalogHierarchyID, 
	PC.ProductCatalogHierarchyID.ToString() AS HierarchyText, 
	PC.ProductCatalogID,
	PC.MasterProductCatalogID,
	PC.ProductID,
	PD1.IdentifierValue as UPC,
	PD2.IdentifierValue as VIN,
	PD3.IdentifierValue as PLU
FROM ProductCatalog_Test PC
	LEFT JOIN ProductIdentifiers PD1 ON PD1.ProductID=PC.ProductID and PD1.ProductIdentifierTypeID=2
	LEFT JOIN ProductIdentifiers PD2 ON PD2.ProductID=PC.ProductID and PD2.ProductIdentifierTypeID=3 and PD2.OwnerEntityId=PC.OwnerEntityID
	LEFT JOIN ProductIdentifiers PD3 ON PD3.ProductID=PC.ProductID and PD3.ProductIdentifierTypeID=2
WHERE ProductCatalogHierarchyID=(SELECT ProductCatalogHierarchyID.GetAncestor(1) from ProductCatalog_Test where ProductCatalogID=@ProductCatalogID )

END
GO
