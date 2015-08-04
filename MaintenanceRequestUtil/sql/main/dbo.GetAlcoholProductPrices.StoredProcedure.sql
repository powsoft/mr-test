USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[GetAlcoholProductPrices]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--[GetAlcoholProductPrices] '130','40557','071921000011'
CREATE proc [dbo].[GetAlcoholProductPrices]
@StoreID varchar(50), 
@UPC varchar(50)
as 
begin
declare @sqlQuery varchar(max)

set @sqlQuery =' SELECT DISTINCT [Products].[ProductID],[Products].[ProductName],
CONVERT(DECIMAL(10,2),ProductPrices.UnitPrice) AS Cost, 	
CONVERT(DECIMAL(10,2),  Productprices.UnitRetail )as Retail
	
	
   FROM [Products] 
	inner join storesetup on storesetup.ProductID = products.ProductID 
	Inner join Stores S on S.StoreId=storesetup.StoreId 
	INNER JOIN ProductPrices ON ProductPrices.StoreId=storesetup.StoreId and dbo.products.ProductID = dbo.ProductPrices.ProductID and PRODUCTPRICES.PRODUCTPRICETYPEID=3 AND dbo.ProductPrices.SupplierID = storesetup.SupplierId and getdate() between ProductPrices.ActiveStartDate and ProductPrices.ActiveLastDate 
	INNER join ProductIdentifiers b on b.productid=products.productid  and b.ProductIdentifierTypeid=2
	left join ProductIdentifiers on ProductIdentifiers.productid=products.productid  and ProductIdentifiers.ProductIdentifierTypeid=3
	where b.IdentifierValue='''+@UPC+''' and S.storeidentifier=' + @StoreID + ''
	
	exec(@sqlQuery)
End
GO
