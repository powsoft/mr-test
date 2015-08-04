USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[GetAlcoholProductData_Products]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--42255
-- [GetAlcoholProductData_Products] 30124, 40559, '','100''''S CIGARETTES'

CREATE proc [dbo].[GetAlcoholProductData_Products]
@StoreID varchar(50), 
@SupplierID varchar(50), 
@InvoiceNo varchar(max),
@productName varchar(100)
as 
begin
 declare @sqlQuery varchar(max)
 set @sqlQuery = 'SELECT DISTINCT  b.IdentifierValue as UPC,  Products.ProductName 
					FROM [Products] with (nolock) 
					inner join storesetup  with (nolock) on storesetup.ProductID = products.ProductID 
					Inner join Stores S  with (nolock) on S.StoreId=storesetup.StoreId 
					INNER JOIN ProductPrices  with (nolock) ON ProductPrices.StoreId=storesetup.StoreId and 
					dbo.products.ProductID = dbo.ProductPrices.ProductID and PRODUCTPRICES.PRODUCTPRICETYPEID IN(3,11) AND 
					dbo.ProductPrices.SupplierID = storesetup.SupplierId and getdate() between ProductPrices.ActiveStartDate 
					and ProductPrices.ActiveLastDate 
					INNER join ProductIdentifiers b  with (nolock) on b.productid=products.productid  and b.ProductIdentifierTypeid=2
					left join ProductIdentifiers  with (nolock) on ProductIdentifiers.productid=products.productid  
					and ProductIdentifiers.ProductIdentifierTypeid=3
	where S.storeidentifier=' +  @StoreID + ' and storesetup.supplierid=' + @Supplierid + ' and Products.ProductName  like ''%' + @productName + '%'''
	 
	print(@sqlQuery);
	exec (@sqlQuery);
	
end
GO
