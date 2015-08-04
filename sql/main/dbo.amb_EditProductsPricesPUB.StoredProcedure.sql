USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_EditProductsPricesPUB]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec amb_EditProductsPricesPUB 'DOWJ','35321','STC','BAM'  (OLD)
--exec amb_EditProductsPricesPUB 'DEFAULT','0','STC','BN' (NEW)
--exec amb_EditProductsPricesPUB 'DOWJ','35321','STC','-1' (Both)

CREATE procedure [dbo].[amb_EditProductsPricesPUB]
(
@PublisherIdentifier varchar(10),
@PublisherId varchar(50),
@WholesalerID varchar(10),
@ChainID varchar(50)
)

AS 
BEGIN

	DECLARE @sqlQuery varchar(8000)
	Declare @sqlQueryNew varchar(8000)
	Declare @Dbtype int --0 for Old DataBase,1 for New DataBase,2 for Mixed
	DECLARE @chain_migrated Varchar(20)
	
	If(@ChainID<>'-1')
		BEGIN
			Select 	@Chain_Migrated=ChainID FROM dbo.chains_migration WHERE   chainid = @ChainID;
			If(@chain_migrated is null)
				SET @Dbtype=0
			Else
				SET @Dbtype=1
		END
	ELSE
		SET @Dbtype=2

		IF(@Dbtype=0 OR @Dbtype=2)
			BEGIN
				SET @sqlQuery=' SELECT distinct P.PublisherID, PP.WholesalerID, PP.Bipad, PP.ChainID,P.TitleName,PP.CostToStore, PP.CostToStore4Wholesaler, 
								PP.CostToWholesaler, PP.SuggRetail,WL.WholesalerName ,''0'' as dbType
								FROM [IC-HQSQL2].iControl.dbo.ProductsPrices PP
								INNER JOIN [IC-HQSQL2].iControl.dbo.Products P ON PP.Bipad = P.Bipad 
								INNER JOIN [IC-HQSQL2].iControl.dbo.Wholesalerslist WL ON PP.WholesalerID = WL.WholesalerID
								WHERE 1=1 and PP.ChainId not in (Select chainid from chains_migration) and P.PublisherID= '''+ @PublisherIdentifier +''''
								
				IF(@WholesalerID<>'-1')
					SET @sqlQuery= @sqlQuery+ ' AND PP.WholesalerID = ''' + @WholesalerID+''''
       
				IF(@ChainID<>'-1')
					SET @sqlQuery= @sqlQuery+ ' AND PP.ChainID = ''' + @ChainID+''''
			END
    
    IF(@Dbtype=1 OR @Dbtype=2)
			BEGIN   
				SET @sqlQueryNew='SELECT distinct M.ManufacturerIdentifier as  PublisherID,SUP.SupplierIdentifier as WholesalerID,PI.Bipad,
									C.ChainIdentifier as ChainID,
									P.ProductName as TitleName,PP.UnitPrice as CostToStore,0 as CostToStore4Wholesaler,0 as CostToWholesaler ,
									PP.UnitRetail as SuggRetail,SUP.SupplierName,''1'' as dbType
									FROM  dbo.ProductPrices PP  
									INNER JOIN dbo.Products P ON P.ProductID=PP.ProductID
									INNER JOIN dbo.Brands B ON PP.BrandID=B.BrandID
									INNER JOIN dbo.Manufacturers M ON M.ManufacturerID=B.ManufacturerID
									INNER JOIN dbo.ProductIdentifiers PI ON PI.ProductID=P.ProductID AND PI.ProductIdentifierTypeID=8
									INNER JOIN dbo.Suppliers SUP ON SUP.SupplierID=PP.SupplierID
									INNER JOIN dbo.Chains C ON C.ChainID=PP.ChainID	
									WHERE 1=1 AND C.ChainIdentifier in (Select chainid from chains_migration)
									AND B.ManufacturerId=' + @PublisherId
				
				IF(@WholesalerID<>'-1')
				   SET @sqlQueryNew= @sqlQueryNew+ ' AND SUP.SupplierIdentifier = ''' + @WholesalerID+''''
			       
				IF(@ChainID<>'-1')
				   SET @sqlQueryNew= @sqlQueryNew+ ' AND C.ChainIdentifier = ''' + @ChainID+''''
			END
	
	IF(@Dbtype=0)
		BEGIN
			EXEC(@sqlQuery)
		END
	
	IF(@Dbtype=1)
		BEGIN
			EXEC(@sqlQueryNew)	
		END
	IF(@Dbtype=2)
		BEGIN
			EXEC(@sqlQuery +' union '+ @sqlQueryNew )
		End				
			
End
GO
