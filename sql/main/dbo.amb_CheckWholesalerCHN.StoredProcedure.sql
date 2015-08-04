USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_CheckWholesalerCHN]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC amb_CheckWholesalerCHN 'BN','42493','FL','BARRONS','1'
CREATE PROCEDURE [dbo].[amb_CheckWholesalerCHN]
(
	@ChainIdentifier NVARCHAR(100) ,
  @ChainID NVARCHAR(100) ,
  @StateName NVARCHAR(100) ,
  @ProductName NVARCHAR(100),
  @ChainMigrated VARCHAR(1) --0 for Old DB, 1 for New DB, 2 for Both 
)
AS 
BEGIN
  DECLARE @sqlQuery VARCHAR(1000)
  
 
			SET @sqlQuery = ' SELECT DISTINCT P.ProductName AS Title,SUP.SupplierIdentifier as WholesalerID,
					SUP.SupplierName as WholesalerName,C.ChainIdentifier as  ChainID,A.State,
					CI.FirstName+ '' '' +CI.LastName as Contact,CI.Email as Email,CI.DeskPhone as Tel
					FROM DataTrue_Report.dbo.StoreSetup SS
					INNER JOIN DataTrue_Report.dbo.Products P  ON SS.ProductID=p.ProductID
					INNER JOIN DataTrue_Report.dbo.Suppliers SUP ON SUP.SupplierID=SS.SupplierID 
					INNER JOIN DataTrue_Report.dbo.Chains C ON C.ChainID =SS.ChainID
					INNER JOIN DataTrue_Report.dbo.Addresses A ON A.OwnerEntityID=SS.SupplierID
					INNER JOIN DataTrue_Report.dbo.ContactInfo CI on CI.OwnerEntityId=sup.SupplierID  '
			SET @sqlQuery = @sqlQuery + ' Where 1=1 AND SS.Chainid=''' + @ChainID+ ''''

			IF ( @StateName <> '-1' ) 
				SET @sqlQuery = @sqlQuery + ' AND A.State= '''+ @StateName+ ''''
			IF ( @ProductName <> '-1' ) 
				SET @sqlQuery = @sqlQuery + ' AND P.ProductName = '''+ @ProductName + ''''
				
			SET @sqlQuery = @sqlQuery + ' Order By A.State,P.ProductName,SUP.SupplierIdentifier'
			EXEC(@sqlQuery);
   
END
GO
