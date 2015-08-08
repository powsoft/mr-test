USE [DataTrue_Main]
GO
/****** Object:  View [dbo].[vwCurrentCostsPending]    Script Date: 06/25/2015 18:26:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vwCurrentCostsPending]
AS
SELECT dbo.Suppliers.SupplierName
		 , dbo.Products.ProductName
		 , dbo.Brands.BrandName
		 , dbo.Stores.StoreIdentifier AS [Store Number]
		 , dbo.Stores.StoreName AS [Store Name]
		 , dbo.Stores.Custom2 AS [SBT Number]
		 , dbo.ProductIdentifiers.IdentifierValue AS UPC
		 , dbo.ProductPrices.UnitPrice
		 , dbo.ProductPrices.UnitRetail
		 , dbo.ProductPrices.PricePriority
		 , cast(dbo.ProductPrices.ActiveStartDate AS DATETIME) AS [Begin Date]
		 , convert(VARCHAR(10), dbo.ProductPrices.ActiveLastDate, 101) AS [End Date]
		 , dbo.Stores.StoreID
		 , dbo.Stores.ChainID
		 , dbo.Suppliers.SupplierID
		 , dbo.ProductIdentifiers.ProductIdentifierTypeID
		 , dbo.Brands.BrandID
		 , dbo.ProductIdentifiers.ProductID
		 , dbo.Chains.ChainName
		 , dbo.Stores.Custom1 AS Banner
FROM
	dbo.ProductPrices
	INNER JOIN dbo.Suppliers
		ON dbo.ProductPrices.SupplierID = dbo.Suppliers.SupplierID
	INNER JOIN dbo.Products
		ON dbo.ProductPrices.ProductID = dbo.Products.ProductID
	INNER JOIN dbo.ProductIdentifiers
		ON dbo.Products.ProductID = dbo.ProductIdentifiers.ProductID
	INNER JOIN dbo.Brands
		ON dbo.ProductPrices.BrandID = dbo.Brands.BrandID
	INNER JOIN dbo.Stores
		ON dbo.ProductPrices.StoreID = dbo.Stores.StoreID
	INNER JOIN dbo.Chains
		ON dbo.Stores.ChainID = dbo.Chains.ChainID
WHERE
	(dbo.ProductPrices.ProductPriceTypeID = 3)
	--AND (dbo.ProductPrices.ActiveStartDate <= convert(VARCHAR(10), getdate(), 101))
	--AND (dbo.ProductPrices.ActiveLastDate >= convert(VARCHAR(10), getdate(), 101))
	AND (dbo.ProductIdentifiers.ProductIdentifierTypeID = 2)
GO
