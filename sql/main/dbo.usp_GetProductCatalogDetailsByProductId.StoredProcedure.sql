USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetProductCatalogDetailsByProductId]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC usp_GetProductCatalogDetailsByUPC '3592109','50726',''

CREATE PROCEDURE [dbo].[usp_GetProductCatalogDetailsByProductId]
@ProductId varchar(50),
@OwnerEntityId varchar(20),
@ChainId varchar(20)
AS
BEGIN
DECLARE @sqlQuery VARCHAR(4000)

SET @sqlQuery = '
									SELECT
										PC.ProductID, 
										PackDesc,
										PackUOM,
										PackTotalQty,
										PackInnerQty,
										PackInnerQtyUOM,
										Purchasable,
										Sellable,
										ProductCatalogHierarchyID, 
										ProductCatalogHierarchyID.ToString() AS HierarchyText, 
										ProductCatalogID,
										MasterProductCatalogID,
										PD1.IdentifierValue as UPC,
										PD2.IdentifierValue as VIN,
										PD3.IdentifierValue as PLU
									FROM ProductCatalog_Test PC 
									LEFT JOIN ProductIdentifiers PD1 ON PD1.ProductID=PC.ProductID and PD1.ProductIdentifierTypeID=2
									LEFT JOIN ProductIdentifiers PD2 ON PD2.ProductID=PC.ProductID and PD2.ProductIdentifierTypeID=3 and PD2.OwnerEntityId=PC.OwnerEntityID
									LEFT JOIN ProductIdentifiers PD3 ON PD3.ProductID=PC.ProductID and PD3.ProductIdentifierTypeID=2
									WHERE
									1=1 							
								'				
								
	IF(@ProductId <> '')
		SET @sqlQuery += ' AND PC.ProductId = ' +@ProductId
							
	IF(@OwnerEntityId <> '50726')
		SET @sqlQuery += ' and PC.OwnerEntityID NOT IN (0,50726)'
									
	IF(@OwnerEntityId <> '-1' and @OwnerEntityId<> '')
		SET @sqlQuery += ' and PC.OwnerEntityID = ' + @OwnerEntityId
	
	IF(@ChainId <> '-1' and @ChainId <> '')
		SET @sqlQuery += ' and PC.ChainId=' + @ChainId
	ELSE	
		SET @sqlQuery += ' and PC.ChainId=0'
		
	SET @sqlQuery += ' Order by ProductCatalogHierarchyID'
		
	PRINT(@sqlQuery)	
	
	EXEC(@sqlQuery)		

END
GO
