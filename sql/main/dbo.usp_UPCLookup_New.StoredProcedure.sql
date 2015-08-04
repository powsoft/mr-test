USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UPCLookup_New]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec usp_UPCLookup_New '40393','-1','-1','-1',2,'like','',1,'like','','1','like','','','','dbo.Suppliers.SupplierName ASC',1,25,0

CREATE procedure [dbo].[usp_UPCLookup_New]
 
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
 @OtherContains varchar(20),
 @Others varchar(250),
 @SupplierIdentifierValue varchar(20),
 @RetailerIdentifierValue varchar(20),
 @OrderBy varchar(100),
 @StartIndex int,
 @PageSize int,
 @DisplayMode int
 
as
 
Begin
 Declare @sqlQuery varchar(4000)
 
 set @sqlQuery = 'SELECT DISTINCT C.ChainName as [Retailer Name], dbo.Suppliers.SupplierName as [Supplier Name], Stores.StoreIdentifier AS [Store Number], Stores.Custom1 AS Banner, 
						dbo.Products.ProductName, ProductIdentifiers.IdentifierValue AS UPC,
					    DataTrue_CustomResultSets.dbo.tmpProductsSuppliersItemsConversion.SupplierProductID as [Vendor Item Number],
						Brands.BrandName,dbo.StoresUniqueValues.supplieraccountnumber as [Supplier Acct Number], dbo.StoresUniqueValues.DriverName as [Driver Name], 
						dbo.StoresUniqueValues.RouteNumber as [Route Number], PD.Bipad as [Bipad] ,dbo.Suppliers.SupplierIdentifier as [Wholesaler ID #]
						FROM  dbo.Suppliers  with(NOLOCK)
						INNER JOIN dbo.StoreSetup  with(NOLOCK) ON dbo.Suppliers.SupplierID = dbo.StoreSetup.SupplierID
						INNER JOIN Stores with(NOLOCK) ON dbo.StoreSetup.StoreID = Stores.StoreID AND Stores.ActiveStatus = ''Active''
						INNER JOIN Chains C with(NOLOCK) ON C.ChainID = Stores.ChainId
						INNER JOIN dbo.Products with(NOLOCK) ON dbo.StoreSetup.ProductID = dbo.Products.ProductID
						INNER JOIN ProductIdentifiers with(NOLOCK) ON dbo.Products.ProductID = ProductIdentifiers.ProductID AND ProductIdentifiers.ProductIdentifierTypeID in (2,8)
						INNER JOIN SupplierBanners SB with(NOLOCK) ON SB.SupplierId = Suppliers.SupplierId AND SB.Status = ''Active'' AND SB.Banner = Stores.Custom1
						Left JOIN ProductBrandAssignments PB with(NOLOCK) ON PB.ProductID = dbo.Products.ProductID 
						AND (PB.CustomOwnerEntityID=C.ChainID OR PB.CustomOwnerEntityID=dbo.Suppliers.SupplierID)
						Left JOIN Brands with(NOLOCK) ON PB.BrandID = Brands.BrandID 
						left join DataTrue_CustomResultSets..tmpProductsSuppliersItemsConversion with(NOLOCK) on DataTrue_CustomResultSets..tmpProductsSuppliersItemsConversion.ProductID=dbo.StoreSetup.ProductID	and DataTrue_CustomResultSets..tmpProductsSuppliersItemsConversion.SupplierId=dbo.StoreSetup.SupplierId
						LEFT OUTER JOIN dbo.StoresUniqueValues with(NOLOCK) ON dbo.Suppliers.SupplierID = dbo.StoresUniqueValues.SupplierID AND dbo.StoresUniqueValues.StoreID = Stores.StoreID
						left JOIN Warehouses WH with(NOLOCK) ON WH.ChainID=C.ChainID and WH.WarehouseId=dbo.StoresUniqueValues.DistributionCenter				
						Left JOIN ProductIdentifiers PD with(NOLOCK) ON dbo.Products.ProductID = PD.ProductID AND PD.ProductIdentifierTypeID=8	
						WHERE 1=1 and dbo.Suppliers.SupplierId<>35113 and dbo.Products.ProductId > 0'
 
	if(@supplierID<>'-1')
		set @sqlQuery = @sqlQuery +  ' and StoreSetup.supplierID=' + @supplierID

	if(@ChainId<>'-1')
		set @sqlQuery = @sqlQuery +  ' and Stores.ChainID=' + @ChainId

	if(@custom1='')
		set @sqlQuery = @sqlQuery + ' and Stores.custom1 is Null'

	else if(@custom1<>'-1')
		set @sqlQuery = @sqlQuery + ' and Stores.custom1=''' + @custom1 + ''''

	if(@BrandId<>'-1')
		set @sqlQuery = @sqlQuery +  ' and Brands.BrandId= ' + @BrandId
	
	if(@SupplierIdentifierValue<>'')
		set @sqlQuery = @sqlQuery + ' and dbo.Suppliers.SupplierIdentifier like ''%' + @SupplierIdentifierValue + '%'''
		
	if(@RetailerIdentifierValue<>'')
		set @sqlQuery = @sqlQuery + ' and C.ChainIdentifier like ''%' + @RetailerIdentifierValue + '%'''
		
	if(@ProductIdentifierValue<>'')
	begin
		-- 2 = UPC, 3 = Product Name , 7 = Vendor Item Number,8=bipad
		if(@ProductIdentifierContains <> '')
			BEGIN
				IF(@ProductIdentifierContains = 'LIKE')
					BEGIN 
						if (@ProductIdentifierType=2)
							set @sqlQuery = @sqlQuery + ' and ProductIdentifiers.IdentifierValue ' + @ProductIdentifierContains + ' ''%' + @ProductIdentifierValue + '%'''	
						else if (@ProductIdentifierType=3)
							set @sqlQuery = @sqlQuery + ' and dbo.Products.ProductName ' + @ProductIdentifierContains + ' ''%' + @ProductIdentifierValue + '%'''	
						else if (@ProductIdentifierType=7)
							set @sqlQuery = @sqlQuery + ' and DataTrue_CustomResultSets.dbo.tmpProductsSuppliersItemsConversion.SupplierProductID ' + @ProductIdentifierContains + ' ''%' + @ProductIdentifierValue + '%'''		
						else if (@ProductIdentifierType=8)
							set @sqlQuery = @sqlQuery + ' and ProductIdentifiers.Bipad ' + @ProductIdentifierContains + ' ''%' + @ProductIdentifierValue + '%'''	
					END
				ELSE
					BEGIN
						if (@ProductIdentifierType=2)
							set @sqlQuery = @sqlQuery + ' and ProductIdentifiers.IdentifierValue ' + @ProductIdentifierContains + ' '''  + @ProductIdentifierValue +''''
						else if (@ProductIdentifierType=3)
							set @sqlQuery = @sqlQuery + ' and dbo.Products.ProductName ' + @ProductIdentifierContains +' '''  + @ProductIdentifierValue +''''
						else if (@ProductIdentifierType=7)
							set @sqlQuery = @sqlQuery + ' and DataTrue_CustomResultSets.dbo.tmpProductsSuppliersItemsConversion.SupplierProductID ' + @ProductIdentifierContains + ' '''  + @ProductIdentifierValue +''''
						else if (@ProductIdentifierType=8)
							set @sqlQuery = @sqlQuery + ' and ProductIdentifiers.Bipad ' + @ProductIdentifierContains + ' '''  + @ProductIdentifierValue +''''
					END
			END
	end
 
	if(@StoreIdentifierValue<>'')
	begin
		-- 1 = Store Number, 2 = SBT Number, 3 = Store Name
		IF(@StoreIdentifierContains <> '')
				BEGIN
					IF(@StoreIdentifierContains = 'LIKE')
						BEGIN
							if (@StoreIdentifierType=1)
								set @sqlQuery = @sqlQuery + ' and stores.storeidentifier ' + @StoreIdentifierContains + ' ''%' + @StoreIdentifierValue + '%'''	
							else if (@StoreIdentifierType=2)
								set @sqlQuery = @sqlQuery + ' and stores.Custom2 ' + @StoreIdentifierContains + ' ''%' + @StoreIdentifierValue + '%''' 
							else if (@StoreIdentifierType=3)
								set @sqlQuery = @sqlQuery + ' and stores.StoreName ' + @StoreIdentifierContains + ' ''%' + @StoreIdentifierValue + '%'''
						END
				ELSE
					BEGIN
						if (@StoreIdentifierType=1)
								set @sqlQuery = @sqlQuery + ' and stores.storeidentifier ' + @StoreIdentifierContains + ' ''' + @StoreIdentifierValue +''''
							else if (@StoreIdentifierType=2)
								set @sqlQuery = @sqlQuery + ' and stores.Custom2 ' + @StoreIdentifierContains + ' ''' + @StoreIdentifierValue +''''
							else if (@StoreIdentifierType=3)
								set @sqlQuery = @sqlQuery + ' and stores.StoreName ' + @StoreIdentifierContains + ' ''' + @StoreIdentifierValue +''''
					END
				END
	end

	if(@Others<>'')
	begin
		-- 1 = Distribution Center, 2 = Regional Manager, 3 = Sales Representative
		-- 4 = Supplier Account No, 5 = Driver Name, 6 = Route No
		IF(@OtherContains <> '')
			BEGIN
				IF(@OtherContains  = 'LIKE')
					BEGIN        
						if (@OtherOption=1)
							set @sqlQuery = @sqlQuery + ' and WH.WarehouseName ' + @OtherContains + ' ''%' + @Others + '%'''
						else if (@OtherOption=2)
							set @sqlQuery = @sqlQuery + ' and StoresUniqueValues.RegionalMgr ' + @OtherContains + ' ''%' + @Others + '%'''
						else if (@OtherOption=3)
							set @sqlQuery = @sqlQuery + ' and StoresUniqueValues.SalesRep ' + @OtherContains + ' ''%' + @Others + '%'''
						else if (@OtherOption=4)
							set @sqlQuery = @sqlQuery + ' and StoresUniqueValues.SupplierAccountNumber ' + @OtherContains + ' ''%' + @Others + '%'''
						else if (@OtherOption=5)
							set @sqlQuery = @sqlQuery + ' and StoresUniqueValues.DriverName ' + @OtherContains + ' ''%' + @Others + '%'''
						else if (@OtherOption=6)
							set @sqlQuery = @sqlQuery + ' and StoresUniqueValues.RouteNumber ' + @OtherContains + ' ''%' + @Others + '%'''
					END
				ELSE
					BEGIN 
						if (@OtherOption=1)
							set @sqlQuery = @sqlQuery + ' and WH.WarehouseName ' + @OtherContains + ' ''' + @Others +''''
						else if (@OtherOption=2)
							set @sqlQuery = @sqlQuery + ' and StoresUniqueValues.RegionalMgr ' + @OtherContains + ' ''' + @Others +''''
						else if (@OtherOption=3)
							set @sqlQuery = @sqlQuery + ' and StoresUniqueValues.SalesRep ' + @OtherContains + ' ''' + @Others +''''
						else if (@OtherOption=4)
							set @sqlQuery = @sqlQuery + ' and StoresUniqueValues.SupplierAccountNumber ' + @OtherContains + ' ''' + @Others +''''
						else if (@OtherOption=5)
							set @sqlQuery = @sqlQuery + ' and StoresUniqueValues.DriverName ' + @OtherContains + ' ''' + @Others +''''
						else if (@OtherOption=6)
							set @sqlQuery = @sqlQuery + ' and StoresUniqueValues.RouteNumber ' + @OtherContains + ' ''' + @Others +''''
					END
			END

	end
     

set @sqlQuery = [dbo].GetPagingQuery_New(@sqlQuery, @orderby, @StartIndex ,@PageSize ,@DisplayMode)
print @sqlQuery
exec (@sqlQuery);
End
GO
