USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_ServiceFees]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC amb_DcrAdjPending 40393
CREATE PROCEDURE [dbo].[amb_ServiceFees]
    (
      @ChainID VARCHAR(20)
    )
AS 
  BEGIN

DECLARE @sqlQuery VARCHAR(8000)

SET @sqlQuery = ' SELECT ST.LegacySystemStoreIdentifier AS [StoreID], 
					 Convert(varchar(12),ID.SaleDate,101) AS [WeekEnding],
					 S.SupplierIdentifier AS [WholesalerID],
					 sum(SF.ServiceFeeFactorValue) AS [TotalDeliveryFees]
			         
			
				  FROM InvoiceDetails ID
				       INNER JOIN ServiceFees SF ON SF.SupplierID=ID.SupplierID AND SF.StoreID=ID.StoreID AND SF.ProductID=ID.ProductID
                       INNER JOIN Suppliers S ON S.SupplierID=ID.SupplierID
                       INNER JOIN Stores ST ON ST.StoreID=ID.StoreID
                       
				  GROUP BY ST.LegacySystemStoreIdentifier,ID.SaleDate,S.SupplierIdentifier,ID.TotalCost,ID.ChainID
				  HAVING ID.ChainID='+@ChainID
			
EXEC(@sqlQuery);		
			
  END
GO
