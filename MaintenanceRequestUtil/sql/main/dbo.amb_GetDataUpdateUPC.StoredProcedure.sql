USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_GetDataUpdateUPC]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC amb_GetDataUpdateUPC '28720','KNG','','08/10/2012','-1','false'
-- EXEC amb_GetDataUpdateUPC '28720','KNG','','2012-10-08','-1','false'
CREATE PROCEDURE [dbo].[amb_GetDataUpdateUPC]
    (
      @WholesalerID VARCHAR(20) ,
      @ChainID VARCHAR(10) ,
      @StoreID VARCHAR(50) ,
      @SaleDate VARCHAR(50) ,
      @UPC VARCHAR(20) ,
      @GroupBySaleDate VARCHAR(20)
    )
AS 
BEGIN
    DECLARE @sqlQuery VARCHAR(4000)
    IF ( @GroupBySaleDate = 'False' ) 
        BEGIN
            SET @sqlQuery = 'SELECT DISTINCT SUP.SupplierIdentifier AS WholesalerID,C.ChainIdentifier AS ChainID,
					Sup.SupplierName AS WholesalerName, C.ChainName AS ChainName,ST.LegacySystemStoreIdentifier	AS StoreID,PD.Bipad,S.UPC,
					S.SaleDateTime as SaleDate,ST.StoreIdentifier AS StoreNumber
                      
				  FROM dbo.StoreTransactions S
					  INNER JOIN dbo.TransactionTypes T ON T.TransactionTypeID=S.TransactionTypeID
					  INNER JOIN dbo.Suppliers SUP ON SUP.SupplierID=S.SupplierID
					  INNER JOIN dbo.Chains C ON C.ChainID=S.ChainID
					  INNER JOIN dbo.Stores ST ON ST.StoreID=S.StoreID
					  INNER JOIN dbo.ProductIdentifiers PD ON PD.ProductID=S.ProductID 
							 AND PD.ProductIdentifierTypeID=8 '

            SET @sqlQuery = @sqlQuery + ' WHERE BucketType=1 ' 

            IF ( @WholesalerID <> '-1' ) 
                SET @sqlQuery = @sqlQuery+ ' AND SUP.SupplierIdentifier = '''+ @WholesalerID +''''
                
            IF ( @ChainID <> '-1' ) 
                SET @sqlQuery = @sqlQuery + '  AND C.ChainIdentifier = '''+ @ChainID + ''''
                
            IF ( @StoreID <> '' ) 
                SET @sqlQuery = @sqlQuery+ ' AND ST.LegacySystemStoreIdentifier like ''%'+ @StoreID + '%'''
                
            IF(CAST(@SaleDate as DATE ) <> CAST('1900-01-01' as DATE))
				SET @sqlQuery = @sqlQuery + ' AND S.SaleDateTime = '''+ Convert(Varchar,+ @SaleDate,101)+''''
				
            IF ( @UPC <> '-1' ) 
                SET @sqlQuery = @sqlQuery + '  AND S.UPC = ''' + @UPC + '''' 	  

            SET @sqlQuery = @sqlQuery + ' Group By SUP.SupplierIdentifier, C.ChainIdentifier, 
								          ST.LegacySystemStoreIdentifier,Sup.SupplierName,C.ChainName,
								          PD.Bipad,S.UPC,S.SaleDateTime,ST.StoreIdentifier '
            EXEC(@sqlQuery);
            print(@sqlQuery); 
        END
    ELSE 
        BEGIN
            SET @sqlQuery ='SELECT DISTINCT SUP.SupplierIdentifier AS WholesalerID,C.ChainIdentifier AS ChainID,
					  Sup.SupplierName AS WholesalerName,C.ChainName AS ChainName,ST.LegacySystemStoreIdentifier AS StoreID,
					  PD.Bipad,S.UPC,ST.StoreIdentifier AS StoreNumber
                      
					 FROM dbo.StoreTransactions S
					 INNER JOIN dbo.TransactionTypes T  ON T.TransactionTypeID=S.TransactionTypeID
					 INNER JOIN dbo.Suppliers SUP ON SUP.SupplierID=S.SupplierID
					 INNER JOIN dbo.Chains C  ON C.ChainID=S.ChainID
					 INNER JOIN dbo.Stores ST ON ST.StoreID=S.StoreID
					 INNER JOIN dbo.ProductIdentifiers PD  ON PD.ProductID=S.ProductID 
							 AND PD.ProductIdentifierTypeID=8 '

            SET @sqlQuery = @sqlQuery + ' WHERE BucketType=1 ' 

            IF ( @WholesalerID <> '-1' ) 
                SET @sqlQuery = @sqlQuery+ ' AND SUP.SupplierIdentifier = ''' + @WholesalerID + ''''
                
            IF ( @ChainID <> '-1' ) 
                SET @sqlQuery = @sqlQuery + '  AND C.ChainIdentifier = '''+ @ChainID + ''''
                
            IF ( @StoreID <> '' ) 
                SET @sqlQuery = @sqlQuery + '  AND ST.LegacySystemStoreIdentifier like ''%'+@StoreID+ '%'''
                
            IF(CAST(@SaleDate as DATE ) <> CAST('1900-01-01' as DATE))
				SET @sqlQuery = @sqlQuery + ' AND S.SaleDateTime = '''+ CONVERT(VARCHAR,+@SaleDate,101)+''''
				
            IF ( @UPC <> '-1' ) 
                SET @sqlQuery = @sqlQuery + '  AND S.UPC = ''' + @UPC+ '''' 	  

            SET @sqlQuery = @sqlQuery + ' Group By SUP.SupplierIdentifier, C.ChainIdentifier, 
										ST.LegacySystemStoreIdentifier,Sup.SupplierName,C.ChainName,
										PD.Bipad,S.UPC,ST.StoreIdentifier '
            EXEC(@sqlQuery);	
        END	
    END
GO
