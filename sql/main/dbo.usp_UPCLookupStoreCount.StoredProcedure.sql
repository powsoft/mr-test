USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UPCLookupStoreCount]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_UPCLookupStoreCount]
 @SupplierId varchar(10),
 @ChainId as Varchar(10),
 @custom1 varchar(255),
 @UPC varchar(100),
 @ProductDescription varchar(255)
 
as

Begin
 Declare @sqlQuery varchar(4000)

 set @sqlQuery = '  SELECT dbo.Suppliers.SupplierName as [Supplier Name], dbo.Stores.Custom1 AS Banner,B.BrandName as Brand, dbo.Products.ProductName, 
						   dbo.ProductIdentifiers.IdentifierValue AS UPC, PD.IdentifierValue as [Supplier Product Code],
						   COUNT(dbo.StoreSetup.StoreID) AS [# of Stores Setup], dbo.NoOfStoresByBanner.[No of Stores] AS [TTL Stores In Banner]
					FROM   dbo.StoreSetup 
						INNER JOIN dbo.Stores ON dbo.StoreSetup.StoreID = dbo.Stores.StoreID and dbo.Stores.ActiveStatus=''Active''
						INNER JOIN dbo.ProductIdentifiers ON dbo.StoreSetup.ProductID = dbo.ProductIdentifiers.ProductID  and dbo.ProductIdentifiers.ProductIdentifierTypeID = 2
						Left JOIN dbo.ProductIdentifiers PD ON dbo.StoreSetup.ProductID = PD.ProductID  and PD.ProductIdentifierTypeID = 3 and PD.OwnerEntityId=dbo.StoreSetup.SupplierID
						INNER JOIN dbo.NoOfStoresByBanner ON dbo.Stores.Custom1 = dbo.NoOfStoresByBanner.Banner AND dbo.Stores.ChainID = dbo.NoOfStoresByBanner.ChainID 
						INNER JOIN dbo.Products ON dbo.ProductIdentifiers.ProductID = dbo.Products.ProductID 
						INNER JOIN ProductBrandAssignments PB on PB.ProductID=dbo.Products.ProductID 
						INNER JOIN Brands B ON PB.BrandID = B.BrandID 
						INNER JOIN SupplierBanners SB on SB.SupplierId = StoreSetup.SupplierId and SB.Status=''Active'' and SB.Banner=Stores.Custom1 
						inner join  dbo.Suppliers ON dbo.StoreSetup.SupplierID = dbo.Suppliers.SupplierID
					WHERE  1=1 '

	if(@ChainId<>'-1') 
		set @sqlQuery = @sqlQuery +  ' and dbo.Stores.ChainId=' + @ChainId
		
	if(@SupplierId<>'-1') 
		set @sqlQuery = @sqlQuery +  ' and Suppliers.SupplierId=' + @SupplierId

	if(@custom1='') 
		set @sqlQuery = @sqlQuery + ' and Stores.custom1 is Null'

	else if(@custom1<>'-1') 
		set @sqlQuery = @sqlQuery + ' and Stores.custom1=''' + @custom1 + ''''

	if(@UPC<>'') 
		set @sqlQuery = @sqlQuery + ' and ProductIdentifiers.IdentifierValue like ''%' + @UPC + '%''';

	if(@ProductDescription<>'') 
		set @sqlQuery = @sqlQuery + ' and Products.ProductName like ''%' + @ProductDescription + '%''';

	set @sqlQuery = @sqlQuery +  '	group by dbo.Stores.Custom1,B.BrandName, dbo.ProductIdentifiers.IdentifierValue, PD.IdentifierValue, dbo.NoOfStoresByBanner.[No of Stores], dbo.Products.ProductName, dbo.Suppliers.SupplierName'; 

	exec(@sqlQuery); 

End
GO
