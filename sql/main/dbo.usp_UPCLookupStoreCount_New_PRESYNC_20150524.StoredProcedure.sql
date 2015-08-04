USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UPCLookupStoreCount_New_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- usp_UPCLookupStoreCount_new '-1',44199,'Dollar General','','','DataTrue_Report.dbo.Stores.Custom1 ASC',1,5000,0

CREATE procedure [dbo].[usp_UPCLookupStoreCount_New_PRESYNC_20150524]
 @SupplierId varchar(10),
 @ChainId as Varchar(10),
 @custom1 varchar(255),
 @UPC varchar(100),
 @ProductDescription varchar(255),
 @OrderBy varchar(100),
 @StartIndex int,
 @PageSize int,
 @DisplayMode int
 
as

Begin
 Declare @sqlQuery varchar(4000)

 set @sqlQuery = ' SELECT C.ChainName AS [Retailer Name]
							 , dbo.Suppliers.SupplierName AS [Supplier Name]
							 , DataTrue_Report.dbo.Stores.Custom1 AS Banner
							 , B.BrandName AS Brand
							 , dbo.Products.ProductName
							 , DataTrue_Report.dbo.ProductIdentifiers.IdentifierValue AS UPC
							 , PD.IdentifierValue AS [Vendor Item Number]
							 , count(dbo.StoreSetup.StoreID) AS [# of Stores Setup]
							 , dbo.NoOfStoresByBanner.[No of Stores] AS [TTL Stores In Banner] FROM  dbo.StoreSetup 
							INNER JOIN DataTrue_Report.dbo.Stores ON dbo.StoreSetup.StoreID = DataTrue_Report.dbo.Stores.StoreID AND DataTrue_Report.dbo.Stores.ActiveStatus = ''Active''
							INNER JOIN DataTrue_Report.dbo.Chains C ON C.ChainId = DataTrue_Report.dbo.Stores.ChainId
							INNER JOIN DataTrue_Report.dbo.ProductIdentifiers ON dbo.StoreSetup.ProductID = DataTrue_Report.dbo.ProductIdentifiers.ProductID AND DataTrue_Report.dbo.ProductIdentifiers.ProductIdentifierTypeID in (2,8)
							LEFT JOIN DataTrue_Report.dbo.ProductIdentifiers PD ON dbo.StoreSetup.ProductID = PD.ProductID AND PD.ProductIdentifierTypeID = 3 AND PD.OwnerEntityId = dbo.StoreSetup.SupplierID
							INNER JOIN dbo.NoOfStoresByBanner ON DataTrue_Report.dbo.Stores.Custom1 = dbo.NoOfStoresByBanner.Banner AND DataTrue_Report.dbo.Stores.ChainID = dbo.NoOfStoresByBanner.ChainID
							INNER JOIN dbo.Products ON DataTrue_Report.dbo.ProductIdentifiers.ProductID = dbo.Products.ProductID
							INNER JOIN DataTrue_Report.dbo.ProductBrandAssignments PB ON PB.ProductID = dbo.Products.ProductID 
							--and PB.CustomOwnerEntityId= StoreSetup.SupplierID
							INNER JOIN DataTrue_Report.dbo.Brands B ON PB.BrandID = B.BrandID
							INNER JOIN SupplierBanners SB ON SB.SupplierId = StoreSetup.SupplierId AND SB.Status = ''Active'' AND SB.Banner = DataTrue_Report.dbo.Stores.Custom1
							INNER JOIN dbo.Suppliers ON dbo.StoreSetup.SupplierID = dbo.Suppliers.SupplierID
						    WHERE  1=1 '

	if(@ChainId<>'-1') 
		set @sqlQuery = @sqlQuery +  ' and DataTrue_Report.dbo.Stores.ChainId=' + @ChainId
		
	if(@SupplierId<>'-1') 
		set @sqlQuery = @sqlQuery +  ' and Suppliers.SupplierId=' + @SupplierId

	if(@custom1='') 
		set @sqlQuery = @sqlQuery + ' and DataTrue_Report.dbo.Stores.custom1 is Null'

	else if(@custom1<>'-1') 
		set @sqlQuery = @sqlQuery + ' and DataTrue_Report.dbo.Stores.custom1=''' + @custom1 + ''''

	if(@UPC<>'') 
		set @sqlQuery = @sqlQuery + ' and DataTrue_Report.dbo.ProductIdentifiers.IdentifierValue like ''%' + @UPC + '%''';

	if(@ProductDescription<>'') 
		set @sqlQuery = @sqlQuery + ' and Products.ProductName like ''%' + @ProductDescription + '%''';

	 set @sqlQuery = @sqlQuery +  '	 group by C.ChainName, dbo.Suppliers.SupplierName, DataTrue_Report.dbo.Stores.Custom1,B.BrandName, DataTrue_Report.dbo.ProductIdentifiers.IdentifierValue, 
									 PD.IdentifierValue, dbo.NoOfStoresByBanner.[No of Stores], dbo.Products.ProductName'
	 print (@sqlQuery);
	set @sqlQuery = [dbo].GetPagingQuery_new(@sqlQuery, @orderby, @StartIndex ,@PageSize ,@DisplayMode)
	
    EXEC (@sqlQuery);

End
GO
