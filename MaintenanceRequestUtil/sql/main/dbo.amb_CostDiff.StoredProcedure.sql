USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_CostDiff]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[amb_CostDiff]
    (
      @ChainID VARCHAR(20)
    )
AS 
  BEGIN

DECLARE @sqlQuery VARCHAR(8000)

SET @sqlQuery = ' SELECT top 10000 '''' AS [txtInvoiceNumber],
                     '''' AS [WeekEndingDate],
                     Convert(varchar(12),ID.SaleDate,101) AS [SaleDate],
                     S.SupplierName AS [DistributorName],
                     S.SupplierIdentifier AS [WholesalerID],
                     PD.IdentifierValue AS [UPC],
                     PT.ProductName AS [TitleName],
                     ST.StoreIdentifier  AS [StoreNumber],
                     '''' AS [Amount],
                     ST.LegacySystemStoreIdentifier AS [StoreID],
                     S.SupplierIdentifier  AS [WholesalerID],
                     '''' AS [Difference]
			
				  FROM InvoiceDetails ID
					   INNER JOIN Suppliers S ON S.SupplierID=ID.SupplierID 
					   INNER JOIN Products PT ON PT.ProductID=ID.ProductID 
                       INNER JOIN ProductIdentifiers PD ON PD.ProductID=PT.ProductID AND PD.ProductID=ID.ProductID
                       INNER JOIN Stores ST ON ST.StoreID=ID.StoreID

				   GROUP BY S.SupplierName,S.SupplierIdentifier,PD.IdentifierValue,PT.ProductName,ST.StoreIdentifier,
				   ST.LegacySystemStoreIdentifier,ID.ChainID,ID.SaleDate
				   HAVING ID.ChainID='+@ChainID
			
EXEC(@sqlQuery);		
			
  END
GO
