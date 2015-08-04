USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_ZeroCostExcpetion_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE procedure [dbo].[usp_Report_ZeroCostExcpetion_PRESYNC_20150524]
	-- Add the parameters for the stored procedure here
	@chainID varchar(20),
	@PersonID int,
	@Banner varchar(50),
	@ProductUPC varchar(20),
	@SupplierId varchar(10),
	@StoreId varchar(10),
	@LastxDays int,
	@StartDate varchar(20),
	@EndDate varchar(20)
AS
BEGIN
Declare @Query varchar(5000)
declare @AttValue int

select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
 
 
	set @query = '
		       SELECT  DISTINCT  
                      dbo.Chains.ChainName AS Retailer, dbo.Suppliers.SupplierName AS Supplier, dbo.Stores.Custom1 AS Banner, 
                      cast(dbo.ProductPrices.UnitPrice  as varchar), 
                      cast(dbo.ProductPrices.ActiveStartDate as varchar) AS [Begin Date], 
                      cast(dbo.ProductPrices.ActiveLastDate as varchar) AS [End Date], 
                      cast(dbo.ProductIdentifiers.IdentifierValue as varchar) AS UPC, 
                      dbo.Products.ProductName AS Product ,dbo.StoresUniqueValues.RouteNumber as [Route Number],
                      dbo.StoresUniqueValues.DriverName as [Driver Name],dbo.StoresUniqueValues.SupplierAccountNumber as [Supplier Account Number],
                      dbo.StoresUniqueValues.SBTNumber as [SBT Number]
			FROM      dbo.ProductPrices INNER JOIN
								  dbo.Chains ON dbo.ProductPrices.ChainID = dbo.Chains.ChainID INNER JOIN
								  dbo.Suppliers ON dbo.ProductPrices.SupplierID = dbo.Suppliers.SupplierID INNER JOIN
								  dbo.Stores ON dbo.ProductPrices.StoreID = dbo.Stores.StoreID and dbo.Stores.ActiveStatus=''Active'' INNER JOIN
								  dbo.ProductIdentifiers ON dbo.ProductPrices.ProductID = dbo.ProductIdentifiers.ProductID INNER JOIN
								  SupplierBanners SB on SB.SupplierId = dbo.Suppliers.SupplierID and SB.Status=''Active'' and SB.Banner=dbo.Stores.Custom1 Inner  join
								  dbo.Products ON dbo.ProductIdentifiers.ProductID = dbo.Products.ProductID left join 
                      dbo.StoresUniqueValues on dbo.Stores.Storeid=dbo.StoresUniqueValues.StoreID and dbo.StoresUniqueValues.SupplierID=dbo.Suppliers.SupplierID	
			WHERE     (dbo.ProductIdentifiers.ProductIdentifierTypeID = 2) AND (dbo.ProductPrices.ActiveLastDate > { fn NOW() }) AND (dbo.ProductPrices.UnitPrice = 0) AND 
								  (dbo.ProductPrices.ProductPriceTypeID IN (3, 5))'

		if @AttValue =17
			set @query = @query + ' and chains.ChainID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'
		else
			set @query = @query + ' and suppliers.SupplierID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 9))'

		if(@chainID  <>'-1') 
			set @Query   = @Query  +  ' and chains.ChainID=' + @chainID 

		if(@Banner<>'All') 
			set @Query  = @Query + ' and stores.custom1  like ''%' + @Banner + '%'''

		if(@SupplierId<>'-1') 
			set @Query  = @Query  + ' and suppliers.SupplierId=' + @SupplierId  

		if(@ProductUPC  <>'-1') 
			set @Query   = @Query  +  ' and  dbo.ProductIdentifiers.IdentifierValue like ''%' + @ProductUPC + '%'''

		exec (@Query )
END
GO
