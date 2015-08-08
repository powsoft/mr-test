USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_DcrAdjPending]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC amb_DcrAdjPending 40393
CREATE PROCEDURE [dbo].[amb_DcrAdjPending]
    (
      @ChainID VARCHAR(20)
    )
AS 
  BEGIN

DECLARE @sqlQuery VARCHAR(8000)

SET @sqlQuery = ' SELECT Top 10000 C.ChainIdentifier AS [ChainID],
                     Convert(varchar(12),ID.SaleDate,101) AS [EndWeek],
                     ST.StoreIdentifier AS [Store Number],
					 SUM(isnull(ID.TotalQty,0)*ID.UnitCost) AS [TotalDCRADJ],
					 S.SupplierName AS [DistributorName]
			         
			
				  FROM InvoiceDetails ID
                       INNER JOIN Chains C ON C.ChainID=ID.ChainID and ID.InvoiceDetailTypeID=5
                       INNER JOIN Stores ST ON ST.StoreID=ID.StoreID
                       INNER JOIN Suppliers S ON S.SupplierID=ID.SupplierID 
                       
				  GROUP BY C.ChainIdentifier,ID.SaleDate,ID.ChainID,ST.StoreIdentifier,S.SupplierName
				  HAVING ID.ChainID='+@ChainID
			
EXEC(@sqlQuery);		
			
  END
GO
