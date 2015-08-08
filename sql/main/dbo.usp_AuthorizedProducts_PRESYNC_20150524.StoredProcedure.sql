USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_AuthorizedProducts_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--[usp_AuthorizedProducts] 40393, 40559,'Dollar General','-1',2,'',1,'',1,''
CREATE procedure [dbo].[usp_AuthorizedProducts_PRESYNC_20150524]
 @ChainId varchar(5),
 @supplierID varchar(5),
 @custom1 varchar(255),
 @BrandId varchar(5),
 @ProductIdentifierType int,
 @ProductIdentifierValue varchar(50),
 @StoreIdentifierType int,
 @StoreIdentifierValue varchar(50),
 @OtherOption int,
 @Others varchar(50)
as
 
Begin
 Declare @sqlQuery varchar(4000)
 
 set @sqlQuery = 'SELECT DISTINCT
               TOP (100) PERCENT C.ChainName as [Retailer Name], dbo.Suppliers.SupplierName as [Supplier Name], Stores.StoreIdentifier as [Store Number],
               dbo.Stores.Custom1 AS Banner,dbo.Brands.BrandName as Brand, dbo.Products.ProductName as Product, dbo.ProductIdentifiers.IdentifierValue AS UPC, DataTrue_CustomResultSets.dbo.tmpProductsSuppliersItemsConversion.SupplierProductID as [Vendor Item Number],
                dbo.StoresUniqueValues.supplieraccountnumber as [Supplier Acct Number], dbo.StoresUniqueValues.DriverName as [Driver Name], dbo.StoresUniqueValues.RouteNumber as [Route Number],dbo.Stores.Custom4 AS [Alternative Store #]
		FROM  dbo.Suppliers 
		INNER JOIN dbo.StoreSetup ON dbo.Suppliers.SupplierID = dbo.StoreSetup.SupplierID 
		INNER JOIN dbo.Stores ON dbo.StoreSetup.StoreID = dbo.Stores.StoreID and Stores.ActiveStatus=''Active'' 
		Inner join Chains C on C.ChainId=dbo.StoreSetup.ChainId
		INNER JOIN dbo.Products ON dbo.StoreSetup.ProductID = dbo.Products.ProductID 
		Inner join SupplierBanners SB on SB.SupplierId = dbo.Suppliers.SupplierId and SB.Status=''Active'' and SB.Banner=dbo.Stores.Custom1
		INNER JOIN dbo.ProductIdentifiers ON dbo.StoreSetup.ProductID = dbo.ProductIdentifiers.ProductID and dbo.ProductIdentifiers.ProductIdentifierTypeID in (2,8)
		left join DataTrue_CustomResultSets..tmpProductsSuppliersItemsConversion on DataTrue_CustomResultSets..tmpProductsSuppliersItemsConversion.ProductID=dbo.StoreSetup.ProductID
		Left JOIN dbo.ProductIdentifiers PD ON dbo.Products.ProductID = PD.ProductID and PD.ProductIdentifierTypeID=3 and PD.OwnerEntityId=dbo.Suppliers.SupplierID
		Inner Join ProductBrandAssignments PB on PB.ProductID=dbo.Products.ProductID  
		INNER JOIN dbo.Brands ON PB.BrandID = dbo.Brands.BrandID 
		LEFT OUTER JOIN dbo.StoresUniqueValues ON dbo.StoreSetup.SupplierID = dbo.StoresUniqueValues.SupplierID 
		AND dbo.StoreSetup.StoreID=dbo.StoresUniqueValues.StoreID
		left JOIN Warehouses WH ON WH.ChainID=C.ChainID and WH.WarehouseId=dbo.StoresUniqueValues.DistributionCenter
        WHERE  dbo.StoreSetup.ActiveLastDate>=GETDATE() ' 
                
if(@ChainId<>'-1')
  set @sqlQuery = @sqlQuery +  ' and StoreSetup.ChainID=' + @ChainID
 
 if(@supplierID<>'-1')
  set @sqlQuery = @sqlQuery +  ' and StoreSetup.supplierID=' + @supplierID
 
 if(@custom1='')
  set @sqlQuery = @sqlQuery + ' and Stores.custom1 is Null'
 
 else if(@custom1<>'-1')
  set @sqlQuery = @sqlQuery + ' and Stores.custom1=''' + @custom1 + ''''
 
 if(@BrandId<>'-1')
  set @sqlQuery = @sqlQuery + ' and Brands.BrandId= ' + @BrandId
 
 if(@ProductIdentifierValue<>'')
 begin

	-- 2 = UPC, 3 = Product Name , 7 = Vendor Item Number
	if (@ProductIdentifierType=2)
		 set @sqlQuery = @sqlQuery + ' and ProductIdentifiers.IdentifierValue like ''%' + @ProductIdentifierValue + '%'''
         
	else if (@ProductIdentifierType=3)
		set @sqlQuery = @sqlQuery + ' and dbo.Products.ProductName like ''%' + @ProductIdentifierValue + '%'''
		
	else if (@ProductIdentifierType=7)
		 set @sqlQuery = @sqlQuery + ' and PD.IdentifierValue like ''%' + @ProductIdentifierValue + '%'''
 end

  
 if(@StoreIdentifierValue<>'')
  begin
-- 1 = Store Number, 2 = SBT Number, 3 = Store Name
	if (@StoreIdentifierType=1)
		set @sqlQuery = @sqlQuery + ' and stores.storeidentifier like ''%' + @StoreIdentifierValue + '%'''
	else if (@StoreIdentifierType=2)
		set @sqlQuery = @sqlQuery + ' and stores.Custom2 like ''%' + @StoreIdentifierValue + '%'''
	else if (@StoreIdentifierType=3)
		set @sqlQuery = @sqlQuery + ' and stores.StoreName like ''%' + @StoreIdentifierValue + '%'''
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
 
execute(@sqlQuery);
print @sqlQuery

 
End
GO
