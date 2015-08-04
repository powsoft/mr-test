USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GenerateDefaultCostDataNonPDI]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_GenerateDefaultCostDataNonPDI]
 
as
Begin
if object_id('DataTrue_CustomResultSets.dbo.[tmpDefaultCosts]') is not null
Drop Table DataTrue_CustomResultSets.dbo.[tmpDefaultCosts]


SELECT  distinct dbo.stores.custom1 as Banner, dbo.Suppliers.SupplierID,
               dbo.Suppliers.SupplierName as Supplier, 
               isnull(SP.OwnerPackageDescription,Case 
						when ISNUMERIC(ProductName)=1 and ISNUMERIC(Description) <>1 and Description<>'UNKNOWN' then
							Description
						else	
							ProductName
						end	)as Product, 
               dbo.Products.ProductID,
               dbo.Products.Description as ProductDescription, dbo.Brands.BrandName as Brand,dbo.Chains.ChainName as [Retailer],dbo.Chains.ChainId,
               dbo.StoresUniqueValues.supplieraccountnumber as [Supplier Acct Number], dbo.StoresUniqueValues.DriverName as [Driver Name], 
               dbo.StoresUniqueValues.RouteNumber as [Route Number], 
               dbo.StoresUniqueValues.DistributionCenter, dbo.StoresUniqueValues.RegionalMgr, dbo.StoresUniqueValues.SalesRep,
               dbo.Stores.StoreIdentifier as [Store Number], dbo.stores.Custom2 as [SBT Number], dbo.stores.storeName,
               dbo.ProductIdentifiers.IdentifierValue AS UPC,cv.SupplierProductID as [Supplier Product Code], dbo.ProductIdentifiers.ProductIdentifierTypeId,
               dbo.ProductPrices.UnitPrice AS [Unit Cost], dbo.ProductPrices.UnitRetail AS [Unit Retail], 
               dbo.ProductPrices.PricePriority, CONVERT(VARCHAR(10),dbo.ProductPrices.ActiveStartDate, 101) AS [Begin Date], 
               CONVERT(VARCHAR(10), dbo.ProductPrices.ActiveLastDate, 101) AS [End Date], dbo.Stores.StoreId,
	cast(CASE WHEN ( dbo.ProductPrices.UnitRetail  > 0) THEN
										((1-(dbo.ProductPrices.UnitPrice/dbo.ProductPrices.UnitRetail))*100) 
										ELSE 0 END AS NUMERIC(10, 2)) AS [Margin],
										  dbo.ProductIdentifiers.Bipad 
Into DataTrue_CustomResultSets.dbo.[tmpDefaultCosts]

FROM  dbo.ProductPrices with(nolock) 
INNER JOIN dbo.Suppliers  with(nolock)  ON dbo.ProductPrices.SupplierID = dbo.Suppliers.SupplierID 
INNER JOIN dbo.Chains  with(nolock)  ON dbo.ProductPrices.ChainId = dbo.Chains.ChainId 
INNER JOIN dbo.Products  with(nolock)  ON dbo.ProductPrices.ProductID = dbo.Products.ProductID 
INNER JOIN dbo.Stores with(nolock)  ON dbo.ProductPrices.StoreID = dbo.Stores.StoreID 
LEFt JOIN dbo.ProductIdentifiers  with(nolock)  ON dbo.Products.ProductID = dbo.ProductIdentifiers.ProductID and dbo.ProductIdentifiers.ProductIdentifierTypeID in (2,8)
left join SupplierPackages SP with(nolock)  on SP.OwnerEntityID = ProductPrices.ChainID and SP.SupplierID=dbo.Suppliers.SupplierID and SP.ProductID=dbo.Products.ProductID  and SP.SupplierPackageID=dbo.ProductPrices.SupplierPackageID
left join DataTrue_CustomResultSets..tmpProductsSuppliersItemsConversion CV with(nolock)  on CV.ProductID=dbo.Products.ProductID and CV.SupplierID=dbo.Suppliers.SupplierID
left join  ProductIdentifiers PD with(nolock)  on PD.ProductID=dbo.ProductIdentifiers.ProductID and PD.ProductIdentifierTypeID=3 and PD.OwnerEntityId=dbo.Suppliers.SupplierID
left join ProductBrandAssignments PB with(nolock)  on PB.ProductID=dbo.Products.ProductID and PB.CustomOwnerEntityId= dbo.Chains.ChainId
left join dbo.Brands with(nolock)  ON PB.BrandID = dbo.Brands.BrandID 
LEFT OUTER JOIN dbo.StoresUniqueValues with(nolock)  ON dbo.ProductPrices.SupplierID = dbo.StoresUniqueValues.SupplierID AND dbo.ProductPrices.StoreID=dbo.StoresUniqueValues.StoreID
WHERE dbo.ProductPrices.ProductPriceTypeID =3
	and Stores.ActiveStatus='Active'
	and ProductPrices.ActiveStartDate = (Select max(ActiveStartDate) from ProductPrices P1 with(nolock)
	where  P1.ProductPriceTypeID = dbo.ProductPrices.ProductPriceTypeID
	and P1.SupplierID = dbo.ProductPrices.SupplierID 
	and P1.ProductID = dbo.ProductPrices.ProductID  
	and P1.StoreId = dbo.ProductPrices.StoreId  
	--AND P1.ActiveStartDate <= { fn NOW() } 
	--AND P1.ActiveLastDate >= { fn NOW() }											
	)

delete from DataTrue_CustomResultSets.dbo.tmpDefaultCosts where UPC like '%D%' 											


if object_id('DataTrue_CustomResultSets.dbo.[tmpDefaultCosts_Product]') is not null
Drop Table DataTrue_CustomResultSets.dbo.[tmpDefaultCosts_Product]

SELECT  distinct dbo.stores.custom1 as Banner, dbo.Suppliers.SupplierID,
               dbo.Suppliers.SupplierName as Supplier, 
               isnull(SP.OwnerPackageDescription,Case 
						when ISNUMERIC(ProductName)=1 and ISNUMERIC(Description) <>1 and Description<>'UNKNOWN' then
							Description
						else	
							ProductName
						end	)as Product, 
			   dbo.Products.ProductID,
               dbo.Products.Description as ProductDescription, dbo.Brands.BrandName as Brand,dbo.Chains.ChainName as [Retailer],dbo.Chains.ChainId,
               dbo.ProductIdentifiers.IdentifierValue AS UPC,CV.SupplierProductID as [Supplier Product Code], dbo.ProductIdentifiers.ProductIdentifierTypeId,
               dbo.ProductPrices.UnitPrice AS [Unit Cost], dbo.ProductPrices.UnitRetail AS [Unit Retail], 
               dbo.ProductPrices.PricePriority, CONVERT(VARCHAR(10),dbo.ProductPrices.ActiveStartDate, 101) AS [Begin Date], 
               CONVERT(VARCHAR(10), dbo.ProductPrices.ActiveLastDate, 101) AS [End Date],
cast(CASE WHEN ( dbo.ProductPrices.UnitRetail  > 0) THEN ((1-(dbo.ProductPrices.UnitPrice/dbo.ProductPrices.UnitRetail))*100) 
										ELSE 0 END AS NUMERIC(10, 2)) AS [Margin],
	  dbo.ProductIdentifiers.Bipad
Into DataTrue_CustomResultSets.dbo.[tmpDefaultCosts_Product]

FROM  dbo.ProductPrices  with(nolock) 
INNER JOIN dbo.Suppliers with(nolock)  ON dbo.ProductPrices.SupplierID = dbo.Suppliers.SupplierID 
INNER JOIN dbo.Chains with(nolock)  ON dbo.ProductPrices.ChainId = dbo.Chains.ChainId 
INNER JOIN dbo.Products with(nolock)  ON dbo.ProductPrices.ProductID = dbo.Products.ProductID 
INNER JOIN dbo.Stores with(nolock)  ON dbo.ProductPrices.StoreID = dbo.Stores.StoreID 
LEFT JOIN dbo.ProductIdentifiers with(nolock)  ON dbo.Products.ProductID = dbo.ProductIdentifiers.ProductID and dbo.ProductIdentifiers.ProductIdentifierTypeID in (2,8)
left join SupplierPackages SP with(nolock)  on SP.OwnerEntityID = ProductPrices.ChainID and SP.SupplierID=dbo.Suppliers.SupplierID and SP.ProductID=dbo.Products.ProductID  and SP.SupplierPackageID=dbo.ProductPrices.SupplierPackageID
left join DataTrue_CustomResultSets..tmpProductsSuppliersItemsConversion CV with(nolock)  on CV.ProductID=dbo.Products.ProductID and CV.SupplierID=dbo.Suppliers.SupplierID
left join  ProductIdentifiers PD with(nolock)   on PD.ProductID=dbo.ProductIdentifiers.ProductID and PD.ProductIdentifierTypeID=3 and (PD.OwnerEntityId=dbo.Suppliers.SupplierID or PD.OwnerEntityId= dbo.Chains.ChainId)
left join ProductBrandAssignments PB with(nolock)  on PB.ProductID=dbo.Products.ProductID and PB.CustomOwnerEntityId= dbo.Chains.ChainId 
left join dbo.Brands with(nolock)  ON PB.BrandID = dbo.Brands.BrandID 
LEFT OUTER JOIN dbo.StoresUniqueValues with(nolock)  ON dbo.ProductPrices.SupplierID = dbo.StoresUniqueValues.SupplierID AND dbo.ProductPrices.StoreID=dbo.StoresUniqueValues.StoreID
WHERE dbo.ProductPrices.ProductPriceTypeID =3 
	and Stores.ActiveStatus='Active'
	and ProductPrices.ActiveStartDate = (Select max(ActiveStartDate) from ProductPrices P1 with(nolock)
	where  P1.ProductPriceTypeID = dbo.ProductPrices.ProductPriceTypeID
	and P1.SupplierID = dbo.ProductPrices.SupplierID 
	and P1.ProductID = dbo.ProductPrices.ProductID  
	and P1.StoreId = dbo.ProductPrices.StoreId  
	--AND P1.ActiveStartDate <= { fn NOW() } 
	--AND P1.ActiveLastDate >= { fn NOW() }											
	)

delete from DataTrue_CustomResultSets.dbo.tmpDefaultCosts_Product where UPC like '%D%' 											

end
GO
