USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_PublicationCostStoresCHN]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter date: <alter Date,,>
-- Description:	<Description,,>
-- =============================================
--exec amb_PublicationCostStoresCHN 'DQ','62362','-1','-1'
CREATE PROCEDURE [dbo].[amb_PublicationCostStoresCHN]

    @ChainIdentifier NVARCHAR(100) ,
    @ChainID NVARCHAR(100) ,
    @ProductName NVARCHAR(250),
    @Cost VARCHAR(10)
    
AS 
BEGIN
	DECLARE @sqlQuery VARCHAR(4000)

    SET @sqlQuery = 'SELECT DISTINCT 
                            P.ProductName AS TitleName,                        
                            PP.UnitPrice AS CostToStore,
                            PP.UnitRetail AS SuggRetail,
                            SUP.SupplierIdentifier AS WholesalerID,
                            SUP.SupplierName AS WholesalerName ,
                            S.StoreIdentifier AS StoreNumber 
                            
			   FROM DataTrue_Report.dbo.ProductPrices PP 
					  INNER JOIN DataTrue_Report.dbo.Products P 
							 ON P.ProductID=PP.ProductID
					  INNER JOIN DataTrue_Report.dbo.StoreSetup SS 
							ON SS.ProductID=PP.ProductID
					  INNER JOIN DataTrue_Report.dbo.Stores S 
							ON S.ChainID=PP.ChainID AND SS.StoreID=S.StoreID
					  INNER JOIN DataTrue_Report.dbo.Suppliers SUP 
							ON SUP.SupplierID=SS.SupplierID AND SUP.SupplierID=PP.SupplierID 
    
					Where 1=1 AND SS.ChainId =''' + @ChainID + ''' AND PP.ProductPriceTypeID=3 '
                        
    IF (@ProductName <> '-1' ) 
        SET @sqlQuery = @sqlQuery + '  AND P.ProductName = ''' + @ProductName + ''''
    IF ( @Cost <> '-1' ) 
        SET @sqlQuery = @sqlQuery + '  AND PP.UnitPrice = ''' + @Cost + '''
										Order by P.ProductName,Sup.SupplierIdentifier,SUP.SupplierName'
    EXEC(@sqlQuery);

END
GO
