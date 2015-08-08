USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UPCLookupStoreCount_New]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- usp_UPCLookupStoreCount_new '-1',44199,'Dollar General','','','Stores.Custom1 ASC',1,5000,0

--usp_UPCLookupStoreCount_new '74767',65726,'Tiger Tote Food Store Inc','2','089826230105','','','Stores.Custom1 ASC',1,25,0

CREATE procedure [dbo].[usp_UPCLookupStoreCount_New]
 @SupplierId varchar(10),
 @ChainId as Varchar(10),
 @custom1 varchar(255),
 @ProductIdentifierType varchar(100),
 @ProductIdentifierContains varchar(20),
 @ProductIdentifierValue varchar(250),
 @SupplierIdentifierValue varchar(20),
 @RetailerIdentifierValue varchar(20),
 @OrderBy varchar(100),
 @StartIndex int,
 @PageSize int,
 @DisplayMode int
 
 -- exec usp_UPCLookupStoreCount_New '-1','40393','-1','2','','','','Stores.Custom1 ASC','1',25,0
as

Begin
 Declare @sqlQuery varchar(4000)

 set @sqlQuery = ' SELECT C.ChainName AS [Retailer Name]
							 , dbo.Suppliers.SupplierName AS [Supplier Name]
							 , Stores.Custom1 AS Banner
							 , B.BrandName AS Brand
							 , dbo.Products.ProductName
							 , ProductIdentifiers.IdentifierValue AS UPC
							 , DataTrue_CustomResultSets.dbo.tmpProductsSuppliersItemsConversion.SupplierProductID AS [Vendor Item Number]
							 , count(dbo.StoreSetup.StoreID) AS [# of Stores Setup]
							 , dbo.NoOfStoresByBanner.[No of Stores] AS [TTL Stores In Banner] 
							 FROM  dbo.StoreSetup with(NOLOCK) 
							INNER JOIN Stores with(NOLOCK) ON dbo.StoreSetup.StoreID = Stores.StoreID AND Stores.ActiveStatus = ''Active''
							INNER JOIN Chains C with(NOLOCK) ON C.ChainId = Stores.ChainId
							INNER JOIN ProductIdentifiers with(NOLOCK) ON dbo.StoreSetup.ProductID = ProductIdentifiers.ProductID AND ProductIdentifiers.ProductIdentifierTypeID in (2,8)
							INNER JOIN dbo.NoOfStoresByBanner with(NOLOCK) ON Stores.Custom1 = dbo.NoOfStoresByBanner.Banner AND Stores.ChainID = dbo.NoOfStoresByBanner.ChainID
							INNER JOIN dbo.Products with(NOLOCK) ON ProductIdentifiers.ProductID = dbo.Products.ProductID
							INNER JOIN SupplierBanners SB with(NOLOCK) ON SB.SupplierId = StoreSetup.SupplierId AND SB.Status = ''Active'' AND SB.Banner = Stores.Custom1
							INNER JOIN dbo.Suppliers with(NOLOCK) ON dbo.StoreSetup.SupplierID = dbo.Suppliers.SupplierID
							LEFT JOIN ProductIdentifiers PD with(NOLOCK) ON dbo.StoreSetup.ProductID = PD.ProductID AND PD.ProductIdentifierTypeID = 3 AND PD.OwnerEntityId = dbo.StoreSetup.SupplierID
							LEFT JOIN ProductBrandAssignments PB with(NOLOCK) ON PB.ProductID = dbo.Products.ProductID 
							AND (PB.CustomOwnerEntityID=C.ChainID OR PB.CustomOwnerEntityID=dbo.StoreSetup.SupplierID)
							LEFT JOIN Brands B with(NOLOCK) ON PB.BrandID = B.BrandID
							left join DataTrue_CustomResultSets..tmpProductsSuppliersItemsConversion with(NOLOCK) on DataTrue_CustomResultSets..tmpProductsSuppliersItemsConversion.ProductID=dbo.StoreSetup.ProductID	and DataTrue_CustomResultSets..tmpProductsSuppliersItemsConversion.SupplierId=dbo.StoreSetup.SupplierId
						    WHERE  1=1 and dbo.Products.ProductId > 0'

	if(@ChainId<>'-1') 
		set @sqlQuery = @sqlQuery +  ' and Stores.ChainId=' + @ChainId
		
	if(@SupplierId<>'-1') 
		set @sqlQuery = @sqlQuery +  ' and Suppliers.SupplierId=' + @SupplierId

	if(@custom1='') 
		set @sqlQuery = @sqlQuery + ' and Stores.custom1 is Null'

	else if(@custom1<>'-1') 
		set @sqlQuery = @sqlQuery + ' and Stores.custom1=''' + @custom1 + ''''
	
	if(@ProductIdentifierValue<>'')
	begin
		-- 2 = UPC, 3 = Product Name ,8=bipad
		if(@ProductIdentifierContains <> '')
			BEGIN
				IF(	@ProductIdentifierContains= 'LIKE')
					BEGIN
						 if (@ProductIdentifierType=2)
							   set @sqlQuery = @sqlQuery + ' and ProductIdentifiers.IdentifierValue ' + @ProductIdentifierContains + ' ''%' + @ProductIdentifierValue + '%'''
						 else if (@ProductIdentifierType=3)
							   set @sqlQuery = @sqlQuery + ' and Products.ProductName ' + @ProductIdentifierContains + ' ''%' + @ProductIdentifierValue + '%'''
						 else if (@ProductIdentifierType=8)
							   set @sqlQuery = @sqlQuery + ' and ProductIdentifiers.Bipad ' + @ProductIdentifierContains + ' ''%' + @ProductIdentifierValue + '%'''
					 END
				ELSE
					BEGIN
						 if (@ProductIdentifierType=2)
							   set @sqlQuery = @sqlQuery + ' and ProductIdentifiers.IdentifierValue ' + @ProductIdentifierContains + ' '''  + @ProductIdentifierValue +''''
						 else if (@ProductIdentifierType=3)
							   set @sqlQuery = @sqlQuery + ' and Products.ProductName ' + @ProductIdentifierContains +' '''  + @ProductIdentifierValue +''''
						 else if (@ProductIdentifierType=8)
							   set @sqlQuery = @sqlQuery + ' and ProductIdentifiers.Bipad ' + @ProductIdentifierContains + ' '''  + @ProductIdentifierValue +''''
					END
			  END

	end	

	
	if(@SupplierIdentifierValue<>'')
			set @sqlQuery = @sqlQuery + ' and dbo.Suppliers.SupplierIdentifier like ''%' + @SupplierIdentifierValue + '%'''
			
	if(@RetailerIdentifierValue<>'')
			set @sqlQuery = @sqlQuery + ' and C.ChainIdentifier like ''%' + @RetailerIdentifierValue + '%'''	

	 set @sqlQuery = @sqlQuery +  '	 group by C.ChainName, dbo.Suppliers.SupplierName, Stores.Custom1,B.BrandName, ProductIdentifiers.IdentifierValue, 
									 DataTrue_CustomResultSets.dbo.tmpProductsSuppliersItemsConversion.SupplierProductID, dbo.NoOfStoresByBanner.[No of Stores], dbo.Products.ProductName'
	 print (@sqlQuery);
	set @sqlQuery = [dbo].GetPagingQuery_new(@sqlQuery, @orderby, @StartIndex ,@PageSize ,@DisplayMode)
	
	  print (@sqlQuery);
    EXEC (@sqlQuery);

End
GO
