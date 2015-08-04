USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_AddProductCatalogPackage]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_AddProductCatalogPackage]
@ParentCatalogId int,
@ProductId int,
@ChainId int,
@SupplierId int,
@OwnerEntityId int,
@Purchasable bit,
@Sellable bit,
@PackDesc nvarchar(255),
@PackUOM nvarchar(255),
@PackTotalQty int,
@PackInnerQty int,
@PackInnerQtyUOM nvarchar(50)
As
Begin

		DECLARE @last_child hierarchyid
		DECLARE @last_masterproductcatalogid varchar(20)
		SELECT @last_child = max(ProductCatalogHierarchyID),@last_masterproductcatalogid=max(MasterProductCatalogID) FROM ProductCatalog_Test
		WHERE ProductCatalogHierarchyID.GetAncestor(1) =(Select ProductCatalogHierarchyID from ProductCatalog_Test where ProductCatalogID=@ParentCatalogId)

		DECLARE @parent_hierarchy_id hierarchyid
		Select @parent_hierarchy_id=ProductCatalogHierarchyID from ProductCatalog_Test where ProductCatalogID=@ParentCatalogId

		DECLARE @next_hierarchy_id hierarchyid
		SELECT @next_hierarchy_id = @parent_hierarchy_id.GetDescendant(@last_child, NULL)

		INSERT INTO ProductCatalog_Test
		(
			MasterProductCatalogID, 
			ProductCatalogHierarchyID, 
			ChainID, 
			SupplierID, 
			OwnerEntityID, 
			ProductID, 
			Purchasable, 
			Sellable, 
			PackDesc, 
			PackUOM, 
			PackTotalQty, 
			PackInnerQty, 
			PackInnerQtyUOM
		)
		VALUES
		(
			@last_masterproductcatalogid,
			@next_hierarchy_id,
			@ChainId,
			@SupplierId,
			@OwnerEntityId,
			@ProductId,
			@Purchasable,
			@Sellable,
			@PackDesc,
			@PackUOM,
			@PackTotalQty,
			@PackInnerQty,
			@PackInnerQtyUOM
		)

End
GO
