USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[GetAlcoholProductData_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--42255
--[GetAlcoholProductData] 601,79898, '',''

CREATE proc [dbo].[GetAlcoholProductData_PRESYNC_20150329]
@StoreID varchar(50), 
@SupplierID varchar(50), 
@InvoiceNo varchar(50),
@UPC varchar(100)
as 
begin
declare @sqlQuery varchar(max)
set @sqlQuery = ' SELECT DISTINCT TOP 50 [Products].[ProductID], ProductIdentifiers.IdentifierValue   as SKU,b.IdentifierValue   as UPC  ,[ProductName],[Description],[UOM],CONVERT(DECIMAL(10,2),ProductPrices.UnitPrice) AS Cost, 
	(select top 1 RecordId from [DataTrue_EDI].[dbo].[InboundInventory_Web] with (nolock) where ReferenceIdentification=''' + @InvoiceNo + ''' and  DataTrueProductID=Products.ProductID  ) as RecordId ,
	(select sum(qty) from [DataTrue_EDI].[dbo].[InboundInventory_Web] with (nolock) where ReferenceIdentification=''' + @InvoiceNo + ''' and DataTrueProductID=Products.ProductID and PurposeCode=''DB'') as QtyDB ,
	(select sum(Adjustment1) from [DataTrue_EDI].[dbo].[InboundInventory_Web] with (nolock) where ReferenceIdentification=''' + @InvoiceNo + ''' and DataTrueProductID=Products.ProductID and PurposeCode=''DB'') as Discount ,
	(select sum(qty) from [DataTrue_EDI].[dbo].[InboundInventory_Web] with (nolock) where ReferenceIdentification=''' + @InvoiceNo + ''' and DataTrueProductID=Products.ProductID and PurposeCode=''CR'') as QtyCR,
	(select sum(Adjustment2) from [DataTrue_EDI].[dbo].[InboundInventory_Web] with (nolock) where ReferenceIdentification=''' + @InvoiceNo + ''' and DataTrueProductID=Products.ProductID and PurposeCode=''DB'') as Adjustments ,	
	CONVERT(DECIMAL(10,2),  Productprices.UnitRetail )as Price,
	ProductPrices.ActiveStartDate,
	ProductPrices.ActiveLastDate,
	ISNULL((select TOP 1 RecordStatus  from [DataTrue_EDI].[dbo].[InboundInventory_Web] with (nolock) where ReferenceIdentification=''' + @InvoiceNo + ''' and DataTrueProductID=Products.ProductID and PurposeCode=''DB''),0) as RecordStatus,
	(select sum(PPC)  from [DataTrue_EDI].[dbo].[InboundInventory_Web] with (nolock) where ReferenceIdentification=''' + @InvoiceNo + ''' and DataTrueProductID=Products.ProductID and PurposeCode=''DB'') as PPC 	
   
   FROM [Products] 
	left  join storesetup with (nolock) on storesetup.ProductID = products.ProductID 
	Inner join Stores S with (nolock) on S.StoreId=storesetup.StoreId 
	INNER JOIN ProductPrices with (nolock) ON ProductPrices.StoreId=storesetup.StoreId and dbo.products.ProductID = dbo.ProductPrices.ProductID and PRODUCTPRICES.PRODUCTPRICETYPEID IN (3,11) AND dbo.ProductPrices.SupplierID = storesetup.SupplierId and getdate() between ProductPrices.ActiveStartDate and ProductPrices.ActiveLastDate 
	INNER join ProductIdentifiers b with (nolock) on b.productid=products.productid  and b.ProductIdentifierTypeid=2
	left join ProductIdentifiers with (nolock) on ProductIdentifiers.productid=products.productid  and ProductIdentifiers.ProductIdentifierTypeid=3
	where S.storeidentifier=' + @StoreID + ' and storesetup.supplierid=' + @Supplierid 
	
	if len(@sqlquery) >0 
		set @sqlQuery = @sqlQuery + ' and b.IdentifierValue  like ''' + @upc + '%'''
	
	set @sqlQuery = @sqlQuery + ' order by products.[ProductName]'
	
	print (@sqlQuery)
	exec (@sqlQuery)
end
GO
