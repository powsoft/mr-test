USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_ZeroCostExcpetion_All]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
-- exec usp_Report_ZeroCostExcpetion_All '75407','-1','All','-1','-1','','','',''
CREATE  procedure  [dbo].[usp_Report_ZeroCostExcpetion_All]
	-- Add the parameters for the stored procedure here
	@chainID varchar(max),
	@PersonID int,
	@Banner varchar(50),
	@ProductUPC varchar(20),
	@SupplierId varchar(max),
	@StoreId varchar(10),
	@LastxDays int,
	@StartDate varchar(20),
	@EndDate varchar(20)
AS
BEGIN
Declare @Query varchar(max)
declare @AttValue int

select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
 
 
	set @query = '
		       SELECT  DISTINCT  
                      Chains.ChainName AS Retailer, Suppliers.SupplierName AS Supplier, Stores.Custom1 AS Banner, 
                      cast(ProductPrices.UnitPrice  as varchar), 
                      convert(varchar(10),cast(ProductPrices.ActiveStartDate as date),101) AS [Begin Date], 
					  convert(varchar(10),cast(ProductPrices.ActiveLastDate as date),101) AS [End Date], 
                      cast(ProductIdentifiers.IdentifierValue as varchar) AS UPC, 
                      Products.ProductName AS Product ,StoresUniqueValues.RouteNumber as [Route Number],
                      StoresUniqueValues.DriverName as [Driver Name],StoresUniqueValues.SupplierAccountNumber as [Supplier Account Number],
                      StoresUniqueValues.SBTNumber as [SBT Number],CV.VIN
			FROM ProductPrices WITH(NOLOCK)  
				INNER JOIN Chains WITH(NOLOCK)  ON ProductPrices.ChainID = Chains.ChainID 
				INNER JOIN Suppliers WITH(NOLOCK)  ON ProductPrices.SupplierID = Suppliers.SupplierID 
				INNER JOIN Stores  WITH(NOLOCK)  ON ProductPrices.StoreID = Stores.StoreID and Stores.ActiveStatus=''Active'' 
				INNER JOIN ProductIdentifiers WITH(NOLOCK)  ON ProductPrices.ProductID = ProductIdentifiers.ProductID 
				INNER JOIN SupplierBanners SB WITH(NOLOCK)  on SB.SupplierId = Suppliers.SupplierID and SB.Status=''Active'' and SB.Banner=Stores.Custom1
				Inner  join Products WITH(NOLOCK)  ON ProductIdentifiers.ProductID = Products.ProductID 
				left join SupplierPackages CV with(nolock)  on CV.ProductID=Products.ProductID and CV.SupplierID=Suppliers.SupplierID 
						 and CV.SupplierPackageID=ProductPrices.SupplierPackageID
				left join StoresUniqueValues  WITH(NOLOCK)  on Stores.Storeid=StoresUniqueValues.StoreID and StoresUniqueValues.SupplierID=Suppliers.SupplierID	
			WHERE (ProductIdentifiers.ProductIdentifierTypeID = 2) AND (ProductPrices.ActiveLastDate > { fn NOW() }) AND (ProductPrices.UnitPrice = 0) AND 
								  (ProductPrices.ProductPriceTypeID IN (3, 5))'

		--if @AttValue =17
		--	set @query = @query + ' and chains.ChainID in (select attributepart from fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'
		--else
		--	set @query = @query + ' and suppliers.SupplierID in (select attributepart from fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 9))'

		if(@chainID  <>'-1') 
			set @Query   = @Query  +  ' and chains.ChainID in (' + @chainID +')'

		if(@Banner<>'All') 
			set @Query  = @Query + ' and stores.custom1  like ''%' + @Banner + '%'''

		if(@SupplierId<>'-1') 
			set @Query  = @Query  + ' and suppliers.SupplierId in (' + @SupplierId  +')'

		if(@ProductUPC  <>'-1') 
			set @Query   = @Query  +  ' and  ProductIdentifiers.IdentifierValue like ''%' + @ProductUPC + '%'''

		exec (@Query )
END
GO
