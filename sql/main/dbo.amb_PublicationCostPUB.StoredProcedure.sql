USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_PublicationCostPUB]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC [amb_PublicationCostPUB] 'DOWJ','35321','-1','-1'
-- EXEC [amb_PublicationCostPUB] 'DEFAULT','0','WR347','ALTOONA MIRROR'

CREATE procedure [dbo].[amb_PublicationCostPUB]
(
	@PublisherIdentifier varchar(20),
	@PublisherId varchar(20),
	@WholesalerID varchar(20),
	@Title varchar(100)
)

as 
BEGIN

	Declare @SqlQueryOld varchar(4000)
	Declare @SqlQueryNew varchar(4000)
	Declare @SqlQueryFinal varchar(4000)

/* (STEP 1)--------- GET DATA FROM THE OLD DATABASE (iControl)---------*/
	SET @SqlQueryOld='  SELECT   PP.WholesalerID, P.AbbrvName AS Title,  PP.CostToStore, 
						 PP.CostToStore4Wholesaler, PP.CostToWholesaler, PP.SuggRetail 

					    FROM    [IC-HQSQL2].iControl.dbo.PublishersList  PL
					    INNER JOIN (  [IC-HQSQL2].iControl.dbo.Products P 
					    INNER JOIN  [IC-HQSQL2].iControl.dbo.ProductsPrices PP ON P.Bipad =  PP.Bipad) 
					    ON  PL.PublisherID =P.PublisherID  ' 

	SET @SqlQueryOld += ' Where 1=1 AND  PP.ChainID Not IN (Select ChainId from Chains_Migration)  
							AND P.Active=1 AND  PL.PublisherID='''+@PublisherIdentifier+''' '
	 
	IF(@WholesalerID<>'-1')
	   SET @SqlQueryOld += ' AND  PP.WholesalerID = ''' + @WholesalerID+''' '
	IF(@Title<>'-1')
	   SET @SqlQueryOld +=  ' AND P.AbbrvName = ''' + @Title+''' '
	        
	        
/* (STEP 2)--------- GET DATA FROM THE NEW DATABASE (DataTrue_Main)---------*/
    SET @SqlQueryNew ='  SELECT DISTINCT S.SupplierIdentifier AS WholesalerID,P.ProductName AS Title,PP.UnitPrice AS CostToStore,
						 0 AS CostToStore4Wholesaler,0 AS CostToWholesaler,PP.UnitRetail AS SuggRetail
						
						FROM dbo.ProductPrices PP 
						INNER JOIN dbo.Brands B ON B.BrandID=PP.BrandID
						INNER JOIN dbo.Manufacturers M ON M.ManufacturerId=B.ManufacturerID
						INNER JOIN dbo.Products P ON P.ProductID=PP.ProductID
						INNER JOIN dbo.Suppliers S ON S.SupplierID=PP.SupplierID 
						INNER JOIN dbo.Chains C ON C.ChainID=PP.ChainID '
						
    SET @SqlQueryNew += ' Where 1=1 AND C.ChainIdentifier IN (Select ChainId from Chains_Migration)  
							AND M.ManufacturerId='+@PublisherId
	 
    IF(@WholesalerID<>'-1')
		SET @SqlQueryNew += ' AND S.SupplierIdentifier = ''' + @WholesalerID+''' '
	   
    IF(@Title<>'-1')
		SET @SqlQueryNew +=  ' AND P.ProductName = ''' + @Title+''''	
	
	SET @SqlQueryNew+=' Order By 2,1'
	 
	 
/* (STEP 3)--------- Exec Final Query ---------*/
	 EXEC(@SqlQueryOld + 'UNION ' + @SqlQueryNeW);			
End
GO
