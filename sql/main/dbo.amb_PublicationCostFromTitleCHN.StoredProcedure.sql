USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_PublicationCostFromTitleCHN]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter date: <alter Date,,>
-- Description:	<Description,,>
-- =============================================
--exec amb_PublicationCostFromTitleCHN 'BN','42493','-1',0
CREATE PROCEDURE [dbo].[amb_PublicationCostFromTitleCHN]
     @ChainIdentifier NVARCHAR(100) ,
     @ChainID NVARCHAR(100) ,
     @ProductName NVARCHAR(250)
      
AS 
BEGIN
    DECLARE @sqlQuery VARCHAR(4000)

    SET @sqlQuery = ' SELECT distinct
							P.ProductName AS TitleName, 
							PP.UnitPrice AS CostToStore,
							PP.UnitRetail AS SuggRetail,
							(PP.UnitRetail-PP.UnitPrice) AS ProfitPerUnit 
							
					FROM DataTrue_Report.dbo.ProductPrices PP 
						 INNER JOIN DataTrue_Report.dbo.Products P ON P.ProductID=PP.ProductID'

    SET @sqlQuery = @sqlQuery + ' Where PP.Chainid ='''+ @ChainID + ''''
    
    IF ( @ProductName <> '-1' ) 
        SET @sqlQuery = @sqlQuery + ' AND P.ProductName = '''+ @ProductName + ''''
        
    SET @sqlQuery = @sqlQuery + 'ORDER BY P.ProductName ASC '
    
    EXEC(@sqlQuery);
      
END
GO
