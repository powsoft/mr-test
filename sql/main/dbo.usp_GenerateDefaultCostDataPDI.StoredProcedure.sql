USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GenerateDefaultCostDataPDI]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_GenerateDefaultCostDataPDI]
 
as
Begin

--For PDI
if object_id('DataTrue_CustomResultSets.dbo.[tmpDefaultCostsPDI]') is not null
Drop Table DataTrue_CustomResultSets.dbo.[tmpDefaultCostsPDI]
SELECT  distinct dbo.stores.custom1 as Banner, dbo.Suppliers.SupplierID,
               dbo.Suppliers.SupplierName as Supplier, 
                isnull(CV.OwnerPackageDescription,Case 
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
               dbo.ProductIdentifiers.IdentifierValue AS UPC,cv.VIN as [Supplier Product Code], (cv.OwnerPackageIdentifier + ' - ' + cv.OwnerPackageDescription) as [Package Desc], 
               dbo.ProductIdentifiers.ProductIdentifierTypeId, dbo.ProductPrices.ProductPriceTypeID, 
               case when dbo.ProductPrices.ProductPriceTypeID = 8 then 'Promo' else 'Cost' end as [Cost Type],
               case when dbo.ProductPrices.ProductPriceTypeID = 8 then dbo.ProductPrices.[UnitPrice]  when dbo.ProductPrices.ProductPriceTypeID = 3  then dbo.ProductPrices.[UnitPrice]  when pp3.ProductPriceTypeID Is not null then pp3.[UnitPrice]  else Null end as [Sellable Unit Cost],
               case when dbo.ProductPrices.ProductPriceTypeID = 8 then dbo.ProductPrices.[UnitRetail] when dbo.ProductPrices.ProductPriceTypeID = 3  then dbo.ProductPrices.[UnitRetail] when pp3.ProductPriceTypeID is not null then pp3.[UnitRetail] else Null end as [Sellable Unit Retail],
               case when dbo.ProductPrices.ProductPriceTypeID = 8 then dbo.ProductPrices.[UnitPrice]  when dbo.ProductPrices.ProductPriceTypeID = 11 then dbo.ProductPrices.[UnitPrice]  when pp11.ProductPriceTypeID Is not null then pp11.[UnitPrice] else Null end as [Purchasable Unit Cost],
               case when dbo.ProductPrices.ProductPriceTypeID = 8 then dbo.ProductPrices.[UnitRetail] when dbo.ProductPrices.ProductPriceTypeID = 11 then dbo.ProductPrices.[UnitRetail] when pp11.ProductPriceTypeID Is not null then pp11.[UnitRetail] else Null end as [Purchasable Unit Retail],
               dbo.ProductPrices.PricePriority, CONVERT(VARCHAR(10),dbo.ProductPrices.ActiveStartDate, 101) AS [Begin Date], 
               CONVERT(VARCHAR(10), dbo.ProductPrices.ActiveLastDate, 101) AS [End Date], dbo.Stores.StoreId,0 as Margin
Into DataTrue_CustomResultSets.dbo.[tmpDefaultCostsPDI]  

FROM  dbo.ProductPrices  with(nolock) 

INNER JOIN dbo.Suppliers with(nolock)  ON dbo.ProductPrices.SupplierID = dbo.Suppliers.SupplierID 
INNER JOIN dbo.Chains with(nolock)  ON dbo.ProductPrices.ChainId = dbo.Chains.ChainId  
INNER JOIN dbo.Stores with(nolock)  ON dbo.ProductPrices.StoreID = dbo.Stores.StoreID 
INNER JOIN dbo.Products with(nolock)  ON dbo.ProductPrices.ProductID = dbo.Products.ProductID
LEFT JOIN dbo.ProductIdentifiers with(nolock)  ON dbo.Products.ProductID = dbo.ProductIdentifiers.ProductID and dbo.ProductIdentifiers.ProductIdentifierTypeID in (2,8)
left join SupplierPackages CV with(nolock)  on CV.OwnerEntityID = ProductPrices.ChainID and CV.SupplierID=dbo.Suppliers.SupplierID and CV.ProductID=dbo.Products.ProductID  and CV.SupplierPackageID=dbo.ProductPrices.SupplierPackageID
left join ProductBrandAssignments PB with(nolock)  on PB.ProductID=dbo.Products.ProductID and PB.CustomOwnerEntityId= dbo.Chains.ChainId
left join dbo.Brands with(nolock)  ON PB.BrandID = dbo.Brands.BrandID 
LEFT OUTER JOIN dbo.StoresUniqueValues with(nolock)  ON dbo.ProductPrices.SupplierID = dbo.StoresUniqueValues.SupplierID AND dbo.ProductPrices.StoreID=dbo.StoresUniqueValues.StoreID
left join ProductPrices PP3 with(nolock)  on PP3.ProductID=ProductPrices.ProductID and PP3.SupplierID=ProductPrices.SupplierID 
		and PP3.ChainId=ProductPrices.ChainId and PP3.StoreId=ProductPrices.StoreID and PP3.ProductPriceTypeID=3
		and PP3.ActiveStartDate=ProductPrices.ActiveStartDate and PP3.ActiveLastDate= ProductPrices.ActiveLastDate
		and isnull(PP3.SupplierPackageID,0)= isnull(ProductPrices.SupplierPackageID ,0)
left join ProductPrices PP11 with(nolock)  on PP11.ProductID=ProductPrices.ProductID and PP11.SupplierID=ProductPrices.SupplierID 
		and PP11.ChainId=ProductPrices.ChainId and PP11.StoreId=ProductPrices.StoreID and PP11.ProductPriceTypeID=11
		and PP11.ActiveStartDate=ProductPrices.ActiveStartDate and PP11.ActiveLastDate= ProductPrices.ActiveLastDate
		and isnull(PP11.SupplierPackageID,0)= isnull(ProductPrices.SupplierPackageID ,0)		
WHERE (dbo.ProductPrices.ProductPriceTypeID in (3,8,11))
		and Stores.ActiveStatus='Active' and Chains.PDITradingPartner=1
		--and getdate() between dbo.ProductPrices.ActiveStartDate and dbo.ProductPrices.ActiveLastDate
		--and ProductPrices.ActiveStartDate = (Select max(ActiveStartDate) from ProductPrices P1
		--										where  P1.ProductPriceTypeID = dbo.ProductPrices.ProductPriceTypeID
		--										and P1.SupplierID = dbo.ProductPrices.SupplierID 
		--										and P1.ProductID = dbo.ProductPrices.ProductID  
		--										and P1.StoreId = dbo.ProductPrices.StoreId  
		--										and P1.ChainId = dbo.ProductPrices.ChainId  
		--										and isnull(P1.SupplierPackageID,0)= isnull(ProductPrices.SupplierPackageID ,0)
		--										)
												
update DataTrue_CustomResultSets.dbo.[tmpDefaultCostsPDI] set Margin = 
cast(CASE WHEN (  [Purchasable Unit Retail] > 0) THEN
										((1-( [Purchasable Unit Cost]/ [Purchasable Unit Retail]))*100) 
										ELSE 0 END AS NUMERIC(10, 2)) 
										
delete from DataTrue_CustomResultSets.dbo.tmpDefaultCostsPDI where UPC like '%D%' 											
delete from DataTrue_CustomResultSets.dbo.tmpDefaultCostsPDI where ProductIdentifierTypeID = 2 and ProductPriceTypeID = 3

if object_id('DataTrue_CustomResultSets.dbo.[tmpDefaultCostsPDI_Product]') is not null
Drop Table DataTrue_CustomResultSets.dbo.[tmpDefaultCostsPDI_Product]

SELECT  distinct dbo.stores.custom1 as Banner, dbo.Suppliers.SupplierID,
               dbo.Suppliers.SupplierName as Supplier, 
               isnull(CV.OwnerPackageDescription,Case 
						when ISNUMERIC(ProductName)=1 and ISNUMERIC(Description) <>1 and Description<>'UNKNOWN' then
							Description
						else	
							ProductName
						end
					) as Product,
			   dbo.Products.ProductID,
               dbo.Products.Description as ProductDescription, dbo.Brands.BrandName as Brand,dbo.Chains.ChainName as [Retailer],dbo.Chains.ChainId,
               dbo.ProductIdentifiers.IdentifierValue AS UPC,CV.VIN as [Supplier Product Code], (cv.OwnerPackageIdentifier + ' - ' + cv.OwnerPackageDescription) as [Package Desc], 
               dbo.ProductIdentifiers.ProductIdentifierTypeId, ProductPrices.ProductPriceTypeID,
               case when dbo.ProductPrices.ProductPriceTypeID = 8 then 'Promo' else 'Cost' end as [Cost Type],
			   case when dbo.ProductPrices.ProductPriceTypeID = 8 then dbo.ProductPrices.[UnitPrice]  when dbo.ProductPrices.ProductPriceTypeID = 3  then dbo.ProductPrices.[UnitPrice]  when pp3.ProductPriceTypeID Is not null then pp3.[UnitPrice]  else Null end as [Sellable Unit Cost],
               case when dbo.ProductPrices.ProductPriceTypeID = 8 then dbo.ProductPrices.[UnitRetail] when dbo.ProductPrices.ProductPriceTypeID = 3  then dbo.ProductPrices.[UnitRetail] when pp3.ProductPriceTypeID is not null then pp3.[UnitRetail] else Null end as [Sellable Unit Retail],
               case when dbo.ProductPrices.ProductPriceTypeID = 8 then dbo.ProductPrices.[UnitPrice]  when dbo.ProductPrices.ProductPriceTypeID = 11 then dbo.ProductPrices.[UnitPrice]  when pp11.ProductPriceTypeID Is not null then pp11.[UnitPrice] else Null end as [Purchasable Unit Cost],
               case when dbo.ProductPrices.ProductPriceTypeID = 8 then dbo.ProductPrices.[UnitRetail] when dbo.ProductPrices.ProductPriceTypeID = 11 then dbo.ProductPrices.[UnitRetail] when pp11.ProductPriceTypeID Is not null then pp11.[UnitRetail] else Null end as [Purchasable Unit Retail],
               dbo.ProductPrices.PricePriority, CONVERT(VARCHAR(10),dbo.ProductPrices.ActiveStartDate, 101) AS [Begin Date], 
               CONVERT(VARCHAR(10), dbo.ProductPrices.ActiveLastDate, 101) AS [End Date],0 as Margin
	
Into DataTrue_CustomResultSets.dbo.[tmpDefaultCostsPDI_Product]

FROM  dbo.ProductPrices  with(nolock) 
INNER JOIN dbo.Suppliers  with(nolock) ON dbo.ProductPrices.SupplierID = dbo.Suppliers.SupplierID 
INNER JOIN dbo.Chains with(nolock)  ON dbo.ProductPrices.ChainId = dbo.Chains.ChainId 
INNER JOIN dbo.Stores with(nolock)  ON dbo.ProductPrices.StoreID = dbo.Stores.StoreID 
INNER JOIN dbo.Products with(nolock)  ON dbo.ProductPrices.ProductID = dbo.Products.ProductID 
LEFT JOIN dbo.ProductIdentifiers with(nolock)  ON dbo.Products.ProductID = dbo.ProductIdentifiers.ProductID and dbo.ProductIdentifiers.ProductIdentifierTypeID in (2,8)
left join SupplierPackages CV with(nolock)  on CV.OwnerEntityID = ProductPrices.ChainID AND CV.ProductID=dbo.Products.ProductID and CV.SupplierID=dbo.Suppliers.SupplierID and CV.SupplierPackageID=dbo.ProductPrices.SupplierPackageID
left join ProductBrandAssignments PB with(nolock)  on PB.ProductID=dbo.Products.ProductID and PB.CustomOwnerEntityId= dbo.Chains.ChainId
left join dbo.Brands with(nolock)  ON PB.BrandID = dbo.Brands.BrandID 
LEFT OUTER JOIN dbo.StoresUniqueValues with(nolock)  ON dbo.ProductPrices.SupplierID = dbo.StoresUniqueValues.SupplierID AND dbo.ProductPrices.StoreID=dbo.StoresUniqueValues.StoreID
left join ProductPrices PP3 with(nolock)  on PP3.ProductID=ProductPrices.ProductID and PP3.SupplierID=ProductPrices.SupplierID 
	and PP3.ChainId=ProductPrices.ChainId and PP3.StoreId=ProductPrices.StoreID and PP3.ProductPriceTypeID=3
	and PP3.ActiveStartDate=ProductPrices.ActiveStartDate and PP3.ActiveLastDate= ProductPrices.ActiveLastDate
	and isnull(PP3.SupplierPackageID,0)= isnull(ProductPrices.SupplierPackageID ,0)
left join ProductPrices PP11 with(nolock)  on PP11.ProductID=ProductPrices.ProductID and PP11.SupplierID=ProductPrices.SupplierID 
		and PP11.ChainId=ProductPrices.ChainId and PP11.StoreId=ProductPrices.StoreID and PP11.ProductPriceTypeID=11
		and PP11.ActiveStartDate=ProductPrices.ActiveStartDate and PP11.ActiveLastDate= ProductPrices.ActiveLastDate
		and isnull(PP11.SupplierPackageID,0)= isnull(ProductPrices.SupplierPackageID ,0)				
WHERE (dbo.ProductPrices.ProductPriceTypeID in (3,8,11))
	and Stores.ActiveStatus='Active' and Chains.PDITradingPartner=1 
	--and getdate() between dbo.ProductPrices.ActiveStartDate and dbo.ProductPrices.ActiveLastDate 
	--and ProductPrices.ActiveStartDate = (Select max(ActiveStartDate) from ProductPrices P1
	--										where  P1.ProductPriceTypeID = dbo.ProductPrices.ProductPriceTypeID
	--										and P1.SupplierID = dbo.ProductPrices.SupplierID 
	--										and P1.ProductID = dbo.ProductPrices.ProductID  
	--										and P1.StoreId = dbo.ProductPrices.StoreId  
	--										and P1.ChainId = dbo.ProductPrices.ChainId  
	--										and isnull(P1.SupplierPackageID,0)= isnull(ProductPrices.SupplierPackageID ,0)
	--									)
										
update DataTrue_CustomResultSets.dbo.[tmpDefaultCostsPDI_Product] set Margin = 
cast(CASE WHEN (  [Purchasable Unit Retail] > 0) THEN
										((1-( [Purchasable Unit Cost]/ [Purchasable Unit Retail]))*100) 
										ELSE 0 END AS NUMERIC(10, 2)) 
delete from DataTrue_CustomResultSets.dbo.tmpDefaultCostsPDI_Product where UPC like '%D%' 											
delete from DataTrue_CustomResultSets.dbo.tmpDefaultCostsPDI_Product where ProductIdentifierTypeID = 2 and ProductPriceTypeID = 3

end
GO
