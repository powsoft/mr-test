USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UpdateProductCatalogPackage]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_UpdateProductCatalogPackage]
@CatalogId int,
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

		UPDATE ProductCatalog_Test
		SET
			ChainID=@ChainId, 
			SupplierID=@SupplierId, 
			OwnerEntityID=@OwnerEntityId, 
			ProductID=@ProductId, 
			Purchasable=@Purchasable, 
			Sellable=@Sellable, 
			PackDesc=@PackDesc, 
			PackUOM=@PackUOM, 
			PackTotalQty=@PackTotalQty, 
			PackInnerQty=@PackInnerQty, 
			PackInnerQtyUOM=@PackInnerQtyUOM
		WHERE
			ProductCatalogID=@CatalogId

End
GO
