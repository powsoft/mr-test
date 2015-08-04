USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UPCLookup_New_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec usp_UPCLookup_New '40393','-1','-1','-1',2,'073410013182',1,'','1','','dbo.Suppliers.SupplierName ASC',1,25,0

CREATE procedure [dbo].[usp_UPCLookup_New_PRESYNC_20150524]
 
 @ChainId varchar(5),
 @supplierID varchar(5),
 @custom1 varchar(255),
 @BrandId varchar(5),
 @ProductIdentifierType int,
 @ProductIdentifierValue varchar(50),
 @StoreIdentifierType int,
 @StoreIdentifierValue varchar(50),
 @OtherOption int,
 @Others varchar(50),
 @OrderBy varchar(100),
@StartIndex int,
@PageSize int,
@DisplayMode int
 
as
 
Begin
 Declare @sqlQuery varchar(4000)
 
 set @sqlQuery = 'SELECT DISTINCT C.ChainName as [Retailer Name], dbo.Suppliers.SupplierName as [Supplier Name], DataTrue_Report.dbo.Stores.StoreIdentifier AS [Store Number], DataTrue_Report.dbo.Stores.Custom1 AS Banner, 
						dbo.Products.ProductName, DataTrue_Report.dbo.ProductIdentifiers.IdentifierValue AS UPC, PD.IdentifierValue	as [Vendor Item Number],
						DataTrue_Report.dbo.Brands.BrandName,dbo.StoresUniqueValues.supplieraccountnumber as [Supplier Acct Number], dbo.StoresUniqueValues.DriverName as [Driver Name], 
						dbo.StoresUniqueValues.RouteNumber as [Route Number] FROM  dbo.Suppliers
						INNER JOIN dbo.StoreSetup ON dbo.Suppliers.SupplierID = dbo.StoreSetup.SupplierID
						INNER JOIN DataTrue_Report.dbo.Stores ON dbo.StoreSetup.StoreID = DataTrue_Report.dbo.Stores.StoreID AND DataTrue_Report.dbo.Stores.ActiveStatus = ''Active''
						INNER JOIN DataTrue_Report.dbo.Chains C ON C.ChainID = DataTrue_Report.dbo.Stores.ChainId
						INNER JOIN dbo.Products ON dbo.StoreSetup.ProductID = dbo.Products.ProductID
						INNER JOIN DataTrue_Report.dbo.ProductBrandAssignments PB ON PB.ProductID = dbo.Products.ProductID 
						--and PB.CustomOwnerEntityId=dbo.Suppliers.SupplierID
						INNER JOIN DataTrue_Report.dbo.Brands ON PB.BrandID = DataTrue_Report.dbo.Brands.BrandID 
						INNER JOIN DataTrue_Report.dbo.ProductIdentifiers ON dbo.Products.ProductID = DataTrue_Report.dbo.ProductIdentifiers.ProductID AND DataTrue_Report.dbo.ProductIdentifiers.ProductIdentifierTypeID in (2,8)
						LEFT JOIN DataTrue_Report.dbo.ProductIdentifiers PD ON dbo.Products.ProductID = PD.ProductID AND PD.ProductIdentifierTypeID = 3 AND PD.OwnerEntityId = dbo.Suppliers.SupplierID
						INNER JOIN SupplierBanners SB ON SB.SupplierId = Suppliers.SupplierId AND SB.Status = ''Active'' AND SB.Banner = Stores.Custom1
						LEFT OUTER JOIN dbo.StoresUniqueValues ON dbo.Suppliers.SupplierID = dbo.StoresUniqueValues.SupplierID AND dbo.StoresUniqueValues.StoreID = Stores.StoreID
						left JOIN Warehouses WH ON WH.ChainID=C.ChainID and WH.WarehouseId=dbo.StoresUniqueValues.DistributionCenter				
						WHERE 1=1'
 
	if(@supplierID<>'-1')
		set @sqlQuery = @sqlQuery +  ' and StoreSetup.supplierID=' + @supplierID

	if(@ChainId<>'-1')
		set @sqlQuery = @sqlQuery +  ' and DataTrue_Report.dbo.Stores.ChainID=' + @ChainId

	if(@custom1='')
		set @sqlQuery = @sqlQuery + ' and DataTrue_Report.dbo.Stores.custom1 is Null'

	else if(@custom1<>'-1')
		set @sqlQuery = @sqlQuery + ' and DataTrue_Report.dbo.Stores.custom1=''' + @custom1 + ''''

	if(@BrandId<>'-1')
		set @sqlQuery = @sqlQuery +  ' and DataTrue_Report.dbo.Brands.BrandId= ' + @BrandId
	
	if(@ProductIdentifierValue<>'')
	begin
		-- 2 = UPC, 3 = Product Name , 7 = Vendor Item Number
		if (@ProductIdentifierType=2)
			set @sqlQuery = @sqlQuery + ' and DataTrue_Report.dbo.ProductIdentifiers.IdentifierValue like ''%' + @ProductIdentifierValue + '%'''

		else if (@ProductIdentifierType=3)
			set @sqlQuery = @sqlQuery + ' and dbo.Products.ProductName like ''%' + @ProductIdentifierValue + '%'''
			
		else if (@ProductIdentifierType=7)
			set @sqlQuery = @sqlQuery + ' and PD.IdentifierValue like ''%' + @ProductIdentifierValue + '%'''
	end
 
	if(@StoreIdentifierValue<>'')
	begin
		-- 1 = Store Number, 2 = SBT Number, 3 = Store Name
		if (@StoreIdentifierType=1)
			set @sqlQuery = @sqlQuery + ' and DataTrue_Report.dbo.stores.storeidentifier like ''%' + @StoreIdentifierValue + '%'''
		else if (@StoreIdentifierType=2)
			set @sqlQuery = @sqlQuery + ' and DataTrue_Report.dbo.stores.Custom2 like ''%' + @StoreIdentifierValue + '%'''
		else if (@StoreIdentifierType=3)
			set @sqlQuery = @sqlQuery + ' and DataTrue_Report.dbo.stores.StoreName like ''%' + @StoreIdentifierValue + '%'''
	end

	if(@Others<>'')
	begin
		-- 1 = Distribution Center, 2 = Regional Manager, 3 = Sales Representative
		-- 4 = Supplier Account No, 5 = Driver Name, 6 = Route No
		                     
		if (@OtherOption=1)
			set @sqlQuery = @sqlQuery + ' and WH.WarehouseName like ''%' + @Others + '%'''
		else if (@OtherOption=2)
			set @sqlQuery = @sqlQuery + ' and StoresUniqueValues.RegionalMgr like ''%' + @Others + '%'''
		else if (@OtherOption=3)
			set @sqlQuery = @sqlQuery + ' and StoresUniqueValues.SalesRep like ''%' + @Others + '%'''
		else if (@OtherOption=4)
			set @sqlQuery = @sqlQuery + ' and StoresUniqueValues.SupplierAccountNumber like ''%' + @Others + '%'''
		else if (@OtherOption=5)
			set @sqlQuery = @sqlQuery + ' and StoresUniqueValues.DriverName like ''%' + @Others + '%'''
		else if (@OtherOption=6)
			set @sqlQuery = @sqlQuery + ' and StoresUniqueValues.RouteNumber like ''%' + @Others + '%'''

	end
     

set @sqlQuery = [dbo].GetPagingQuery_New(@sqlQuery, @orderby, @StartIndex ,@PageSize ,@DisplayMode)
print @sqlQuery
exec (@sqlQuery);
End
GO
