USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_ZeroCostExcpetion]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec usp_Report_ZeroCostExcpetion '75407','41713','All','-1','-1','','','',''
CREATE  procedure [dbo].[usp_Report_ZeroCostExcpetion]
	-- Add the parameters for the stored procedure here
	@chainID varchar(20),
	@PersonID int,
	@Banner varchar(50),
	@ProductUPC varchar(20),
	@SupplierId varchar(10),
	@StoreId varchar(10),
	@LastxDays int,
	@StartDate varchar(20),
	@EndDate varchar(20), @MaxRowsCount varchar(20) = ' Top 2500000 '
AS
BEGIN
Declare @Query varchar(max)
declare @AttValue int

select @attvalue = AttributeID  from AttributeValues WITH(NOLOCK)  where OwnerEntityID=@PersonID and AttributeID=17
 
 
	set @query = 'SELECT  DISTINCT ' + @MaxRowsCount + '  
							  Chains.ChainName AS Retailer, Suppliers.SupplierName AS Supplier, Stores.Custom1 AS Banner, 
							  cast(ProductPrices.UnitPrice  as varchar), 
							  convert(varchar(10),cast(ProductPrices.ActiveStartDate as date),101) AS [Begin Date], 
							  convert(varchar(10),cast(ProductPrices.ActiveLastDate as date),101) AS [End Date], 
							  cast(ProductIdentifiers.IdentifierValue as varchar) AS UPC, 
							  Products.ProductName AS Product ,StoresUniqueValues.RouteNumber as [Route Number],
							  StoresUniqueValues.DriverName as [Driver Name],StoresUniqueValues.SupplierAccountNumber as [Supplier Account Number],
							  StoresUniqueValues.SBTNumber as [SBT Number],CV.VIN
					FROM  ProductPrices with (nolock) 
					INNER JOIN Chains  with (nolock) ON ProductPrices.ChainID = Chains.ChainID 
					INNER JOIN Suppliers  with (nolock) ON ProductPrices.SupplierID = Suppliers.SupplierID 
					INNER JOIN Stores   with (nolock) ON ProductPrices.StoreID = Stores.StoreID and Stores.ActiveStatus=''Active'' 
					INNER JOIN ProductIdentifiers  with (nolock) ON ProductPrices.ProductID = ProductIdentifiers.ProductID 
					INNER JOIN SupplierBanners SB  with (nolock) on SB.SupplierId = Suppliers.SupplierID and SB.Status=''Active'' and SB.Banner=Stores.Custom1 
					Inner join Products  with (nolock) ON ProductIdentifiers.ProductID = Products.ProductID 
					left join SupplierPackages CV with(nolock)  on CV.ProductID=Products.ProductID and CV.SupplierID=Suppliers.SupplierID 
						 and CV.SupplierPackageID=ProductPrices.SupplierPackageID
					left join  StoresUniqueValues   with (nolock) on Stores.Storeid=StoresUniqueValues.StoreID and StoresUniqueValues.SupplierID=Suppliers.SupplierID	
					WHERE (ProductIdentifiers.ProductIdentifierTypeID = 2) AND (ProductPrices.ActiveLastDate > { fn NOW() }) AND (ProductPrices.UnitPrice = 0) 
					AND   (ProductPrices.ProductPriceTypeID IN (3, 5))'

		if @AttValue =17
			set @Query = @Query + ' and Chains.ChainID in (select attributepart from dbo.fnGetRetailersTable(' +  cast(@PersonID as varchar) + '))'
		else
			set @Query = @Query + ' and Suppliers.SupplierID in (select attributepart from dbo.fnGetSupplierTable(' +  cast(@PersonID as varchar) + '))'

		if(@chainID  <>'-1') 
			set @Query   = @Query  +  ' and chains.ChainID=' + @chainID 

		if(@Banner<>'All') 
			set @Query  = @Query + ' and stores.custom1  like ''%' + @Banner + '%'''

		if(@SupplierId<>'-1') 
			set @Query  = @Query  + ' and suppliers.SupplierId=' + @SupplierId  

		if(@ProductUPC  <>'-1') 
			set @Query   = @Query  +  ' and  ProductIdentifiers.IdentifierValue like ''%' + @ProductUPC + '%'''
		print (@Query )
		exec (@Query )
END
GO
