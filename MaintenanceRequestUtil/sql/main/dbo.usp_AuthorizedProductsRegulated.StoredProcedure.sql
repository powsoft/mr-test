USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_AuthorizedProductsRegulated]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- usp_AuthorizedProductsRegulated '75407','80496','E-Z Mart','-1',2,'Like','',1,'Like','','1','Like','','','','-1','[SupplierName] ASC',11,200,0
CREATE PROC [dbo].[usp_AuthorizedProductsRegulated]
 @ChainId varchar(5),
 @supplierID varchar(5),
 @custom1 varchar(255),
 @BrandId varchar(5),
 @ProductIdentifierType int,
 @ProductIdentifierContains varchar(20),
 @ProductIdentifierValue varchar(250),
 @StoreIdentifierType int,
 @StoreIdentifierContains varchar(20),
 @StoreIdentifierValue varchar(250),
 @OtherOption int,
 @OthersContains varchar(20),
 @Others varchar(50),
 @SupplierIdentifierValue varchar(50),
 @RetailerIdentifierValue varchar(50),
 @Category varchar(20),
 @OrderBy varchar(100),
 @StartIndex int,
 @PageSize int,
 @DisplayMode int

AS

BEGIN
	DECLARE @sqlQuery VARCHAR(4000)
 
	SET @sqlQuery = ' SELECT Sup.SupplierIdentifier,
							C.ChainIdentifier, 
							B.BrandId, 
							PD1.Bipad, 
							S.Custom2, 
							S.StoreName,
							WH.WarehouseName, 
							SUV.RegionalMgr, 
							SUV.SalesRep, 
							PID.ProductIdentifierTypeID,
							C.ChainName as [Retailer Name], 
							Sup.SupplierName as [Supplier Name],
							S.StoreIdentifier as [Store Number],
							S.Custom1 AS Banner,
							B.BrandName as Brand, 
							P.ProductName as Product, 
							PID.IdentifierValue AS UPC,					
							CV.SupplierProductID as [Vendor Item Number],
							SUV.SupplierAccountNumber as  [Supplier Acct Number], 
							SUV.DriverName as [Driver Name], 
							SUV.RouteNumber as [Route Number],
							S.Custom4 AS [Alternative Store #]
			
				  FROM  ProductPrices_Retailer PPR WITH(NOLOCK)
					INNER JOIN Products P WITH(NOLOCK) ON P.ProductID = PPR.ProductID AND PPR.IsActive=1
					INNER JOIN Stores S WITH(NOLOCK) ON S.StoreID = PPR.StoreID
					INNER JOIN Suppliers Sup WITH(NOLOCK) ON Sup.SupplierID = PPR.SupplierID
					INNER JOIN Chains C WITH(NOLOCK) ON C.ChainID=PPR.ChainID
					INNER JOIN dbo.ProductIdentifiers PID WITH(NOLOCK) ON PPR.ProductID = PID.ProductID AND PID.ProductIdentifierTypeID in (2,8)
					LEFT JOIN ProductBrandAssignments PB WITH(NOLOCK)  ON PB.ProductID=P.ProductID AND PB.CustomOwnerEntityID=C.ChainID 
					LEFT JOIN dbo.ProductIdentifiers PD  WITH(NOLOCK) ON P.ProductID = PD.ProductID AND PD.ProductIdentifierTypeID=3 AND PD.OwnerEntityId=Sup.SupplierID
					LEFT JOIN dbo.ProductIdentifiers PD1  WITH(NOLOCK) ON P.ProductID = PD1.ProductID AND PD1.ProductIdentifierTypeID=8
					LEFT JOIN dbo.Brands B WITH(NOLOCK) ON PB.BrandID = B.BrandID 
					LEFT JOIN DataTrue_CustomResultSets..tmpProductsSuppliersItemsConversion CV  with(nolock) on CV.ProductID=P.ProductID AND CV.SupplierID=Sup.SupplierID
					LEFT OUTER JOIN dbo.StoresUniqueValues SUV WITH(NOLOCK) ON Sup.SupplierID = SUV.SupplierID  AND S.StoreID=SUV.StoreID
					LEFT JOIN Warehouses WH  WITH(NOLOCK) ON WH.ChainID=C.ChainID AND WH.WarehouseId=SUV.DistributionCenter
			
				WHERE 1=1  '
				
		IF(@ChainId<>'-1')
			SET @sqlQuery = @sqlQuery +  ' AND C.ChainID=' + @ChainID

		IF(@supplierID<>'-1')
			SET @sqlQuery = @sqlQuery +  ' AND Sup.SupplierID=' + @supplierID

		IF(@SupplierIdentifierValue<>'')
			SET @sqlQuery = @sqlQuery + '  AND Sup.SupplierIdentifier like ''%' + @SupplierIdentifierValue + '%'''

		IF(@RetailerIdentifierValue<>'')
			SET @sqlQuery = @sqlQuery + ' AND C.ChainIdentifier like ''%' + @RetailerIdentifierValue + '%'''

		IF(@custom1='')
			SET @sqlQuery = @sqlQuery + ' AND S.Custom1 is Null'

		ELSE IF(@custom1<>'-1')
			SET @sqlQuery = @sqlQuery + ' AND S.Custom1=''' + @custom1 + ''''

		IF(@BrandId<>'-1')
			SET @sqlQuery = @sqlQuery + ' AND B.BrandId= ' + @BrandId
 
IF(@ProductIdentifierValue<>'')
	BEGIN-- 2 = UPC, 3 = Product Name , 7 = Vendor Item Number
		IF(@ProductIdentifierContains <> '')
			BEGIN
				IF(@ProductIdentifierContains = 'LIKE')
					BEGIN
						IF (@ProductIdentifierType=2)
							SET @sqlQuery = @sqlQuery + ' AND PID.IdentifierValue ' + @ProductIdentifierContains +' ''%' + @ProductIdentifierValue + '%'''
						ELSE IF (@ProductIdentifierType=3)
							SET @sqlQuery = @sqlQuery + ' AND P.ProductName ' + @ProductIdentifierContains +' ''%' + @ProductIdentifierValue + '%'''
						ELSE IF (@ProductIdentifierType=7)
							SET @sqlQuery = @sqlQuery + ' AND CV.SupplierProductID ' + @ProductIdentifierContains +' ''%' + @ProductIdentifierValue + '%'''
						ELSE IF (@ProductIdentifierType=8)
							SET @sqlQuery = @sqlQuery + ' AND PD1.Bipad ' + @ProductIdentifierContains +' ''%' + @ProductIdentifierValue + '%'''
					END
				ELSE
					BEGIN
						IF (@ProductIdentifierType=2)
							SET @sqlQuery = @sqlQuery + ' AND PID.IdentifierValue ' + @ProductIdentifierContains +' ''' + @ProductIdentifierValue + ''''
						ELSE IF (@ProductIdentifierType=3)
							SET @sqlQuery = @sqlQuery + ' AND P.ProductName ' + @ProductIdentifierContains +' ''' + @ProductIdentifierValue + ''''
						ELSE IF (@ProductIdentifierType=7)
							SET @sqlQuery = @sqlQuery + ' AND CV.SupplierProductID ' + @ProductIdentifierContains +' ''' + @ProductIdentifierValue + ''''
						ELSE IF (@ProductIdentifierType=8)
							SET @sqlQuery = @sqlQuery + ' AND PD1.Bipad ' + @ProductIdentifierContains +' ''' + @ProductIdentifierValue + ''''
					END
			END
	END

	IF(@StoreIdentifierValue<>'')
		BEGIN
		--1 = Store Number, 2 = SBT Number, 3 = Store Name
			IF (@StoreIdentifierType=1)
				BEGIN
					IF(@StoreIdentifierContains = 'Like')
						SET @sqlQuery = @sqlQuery + ' AND S.StoreIdentifier '+ @StoreIdentifierContains + '''%' + @StoreIdentifierValue + '%'''
					ELSE 
						SET @sqlQuery = @sqlQuery + ' AND S.StoreIdentifier '+ @StoreIdentifierContains + '''' + @StoreIdentifierValue + ''''
				END
			ELSE IF (@StoreIdentifierType=2)
				BEGIN
					IF(@StoreIdentifierContains = 'Like')
						SET @sqlQuery = @sqlQuery + ' AND S.Custom2 '+ @StoreIdentifierContains + '''%' + @StoreIdentifierValue + '%'''
					ELSE
						SET @sqlQuery = @sqlQuery + ' AND S.Custom2 '+ @StoreIdentifierContains + '''' + @StoreIdentifierValue + ''''
				END
			ELSE IF (@StoreIdentifierType=3)
				BEGIN
					IF(@StoreIdentifierContains = 'Like')
						SET @sqlQuery = @sqlQuery + ' AND S.StoreName '+ @StoreIdentifierContains + '''%' + @StoreIdentifierValue + '%'''
					ELSE
						SET @sqlQuery = @sqlQuery + ' AND S.StoreName '+ @StoreIdentifierContains + '''' + @StoreIdentifierValue + ''''
				END
		END
	
 IF(@Others<>'')
    BEGIN
        -- 1 = Distribution Center, 2 = Regional Manager, 3 = Sales Representative
        -- 4 = Supplier Account No, 5 = Driver Name, 6 = Route No
		IF(@OthersContains <> '')
			BEGIN
				IF(@OthersContains = 'LIKE')
					BEGIN
						IF (@OtherOption=1)
							SET @sqlQuery = @sqlQuery + ' AND WH.WarehouseName ' + @OthersContains +' ''%' + @Others + '%'''
						ELSE IF (@OtherOption=2)
							SET @sqlQuery = @sqlQuery + ' AND SUV.RegionalMgr ' + @OthersContains +' ''%' + @Others + '%'''
						ELSE IF (@OtherOption=3)
							SET @sqlQuery = @sqlQuery + ' AND SUV.SalesRep ' + @OthersContains +' ''%' + @Others + '%'''
						ELSE IF (@OtherOption=4)
							SET @sqlQuery = @sqlQuery + ' AND SUV.SupplierAccountNumber ' + @OthersContains +' ''%' + @Others + '%'''
						ELSE IF (@OtherOption=5)
							SET @sqlQuery = @sqlQuery + ' AND SUV.DriverName ' + @OthersContains +' ''%' + @Others + '%'''
						ELSE IF (@OtherOption=6)
							SET @sqlQuery = @sqlQuery + ' AND SUV.RouteNumber ' + @OthersContains +' ''%' + @Others + '%'''
					END
				ELSE
					BEGIN
						IF (@OtherOption=1)
							SET @sqlQuery = @sqlQuery + ' AND WH.WarehouseName ' + @OthersContains + ' ''' + @Others + ''''
						ELSE IF (@OtherOption=2)
							SET @sqlQuery = @sqlQuery + ' AND SUV.RegionalMgr ' + @OthersContains + ' ''' + @Others + ''''
						ELSE IF (@OtherOption=3)
							SET @sqlQuery = @sqlQuery + ' AND SUV.SalesRep ' + @OthersContains + ' ''' + @Others + ''''
						ELSE IF (@OtherOption=4)
							SET @sqlQuery = @sqlQuery + ' AND SUV.SupplierAccountNumber ' + @OthersContains + ' ''' + @Others + ''''
						ELSE IF (@OtherOption=5)
							SET @sqlQuery = @sqlQuery + ' AND SUV.DriverName ' + @OthersContains + ' ''' + @Others + ''''
						ELSE IF (@OtherOption=6)
							SET @sqlQuery = @sqlQuery + ' AND SUV.RouteNumber ' + @OthersContains + ' ''' + @Others + ''''
					END
			END  
    END
    
		IF(@Category='1')
			SET @sqlQuery = @sqlQuery +  ' AND PID.ProductIdentifierTypeID = 8'
		ELSE IF(@Category='2')
			SET @sqlQuery = @sqlQuery +  ' AND PID.ProductIdentifierTypeID <> 8'	

 
  SET @sqlQuery = [dbo].GetPagingQuery_New(@sqlQuery, @OrderBy, @StartIndex ,@PageSize ,@DisplayMode)
  EXEC(@sqlQuery)
  PRINT(@sqlQuery)
 
END
GO
