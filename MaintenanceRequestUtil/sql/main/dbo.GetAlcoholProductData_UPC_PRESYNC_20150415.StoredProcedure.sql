USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[GetAlcoholProductData_UPC_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--42255
--[GetAlcoholProductData_UPC] 138, 40559, '','0'
--[GetAlcoholProductData_UPC] 1523, 50729, '',''

CREATE proc [dbo].[GetAlcoholProductData_UPC_PRESYNC_20150415]
@StoreID varchar(50),
@SupplierID varchar(50), 
@InvoiceNo varchar(max),
@UPC varchar(50)
as 
begin
 declare @sqlQuery varchar(max)
 set @sqlQuery = '
 SELECT DISTINCT   b.IdentifierValue as UPC  
	 
	
   FROM [Products] 
	inner join storesetup on storesetup.ProductID = products.ProductID 
	Inner join Stores S on S.StoreId=storesetup.StoreId 
	INNER JOIN ProductPrices ON ProductPrices.StoreId=storesetup.StoreId and dbo.products.ProductID = dbo.ProductPrices.ProductID and PRODUCTPRICES.PRODUCTPRICETYPEID IN(3,11) AND dbo.ProductPrices.SupplierID = storesetup.SupplierId and getdate() between ProductPrices.ActiveStartDate and ProductPrices.ActiveLastDate 
	INNER join ProductIdentifiers b on b.productid=products.productid  and b.ProductIdentifierTypeid=2
	left join ProductIdentifiers on ProductIdentifiers.productid=products.productid  and ProductIdentifiers.ProductIdentifierTypeid=3
	where S.storeidentifier=' +  @StoreID + ' and storesetup.supplierid=' + @Supplierid + ' and b.identifiervalue like ''' + @upc + '%'''
	 
	exec (@sqlQuery)
	print (@sqlQuery)
	
end
GO
