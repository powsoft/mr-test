USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetProductCatalogNodes]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec usp_GetProductCatalogNodes 2,0,'50726',''

CREATE PROCEDURE [dbo].[usp_GetProductCatalogNodes]
@NodeLevel int,
@ProductCatalogID int,
@OwnerEntityId varchar(20),
@ChainId varchar(20)
AS
BEGIN
DECLARE @sqlQuery VARCHAR(4000)
SET @sqlQuery = '
									SELECT 
										ProductCatalogHierarchyID.GetLevel() AS NodeLevel, 
										ProductCatalogHierarchyID, 
										ProductCatalogHierarchyID.ToString() AS HierarchyText, 
										ProductCatalogID,
										MasterProductCatalogID,
										ProductID,
										PackDesc
									FROM ProductCatalog_Test
									WHERE ProductCatalogHierarchyID.GetLevel() = ' + cast(@NodeLevel as VARCHAR(20)) + '
									'
	
	IF(@ProductCatalogID <> 0)
		SET @sqlQuery += 'AND ProductCatalogHierarchyID.IsDescendantOf((SELECT ProductCatalogHierarchyID FROM ProductCatalog WHERE ProductCatalogID = ' + cast(@ProductCatalogID as VARCHAR(20)) + ')) = 1'
									
	IF(@OwnerEntityId <> '50726')
		SET @sqlQuery += ' and OwnerEntityID NOT IN (0,50726)'
									
	IF(@OwnerEntityId <> '-1')
		SET @sqlQuery += ' and OwnerEntityID=' + @OwnerEntityId
	
	IF(@ChainId <> '-1' and @ChainId <> '')
		SET @sqlQuery += ' and ChainId=' + @ChainId
	
	PRINT(@sqlQuery)	
	
	EXEC(@sqlQuery)	

END
GO
