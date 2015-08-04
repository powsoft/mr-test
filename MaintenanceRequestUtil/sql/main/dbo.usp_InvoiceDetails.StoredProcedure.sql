USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_InvoiceDetails]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_InvoiceDetails]
	@SupplierId varchar(10),
	@ChainId varchar(10),
	@InvoiceNumber varchar(255)
as

Begin
 Declare @sqlQuery varchar(4000)
 Declare @CostFormat varchar(10)
 
 if(@supplierID<>'-1')
	Select @CostFormat = Costformat from SupplierFormat where SupplierID = @supplierID
 else
	set @CostFormat=4
	
 	set @sqlQuery = 'SELECT  dbo.Suppliers.SupplierName as [Supplier Name], dbo.Chains.ChainName as [Chain Name],  dbo.Stores.StoreName as [Store Name], dbo.stores.storeidentifier as [Store No] , dbo.Stores.Custom2 as [SBT Number],
 					  dbo.Stores.custom1 as Banner,B.BrandName as Brand, dbo.Products.ProductName as Product, dbo.ProductIdentifiers.IdentifierValue as [UPC], PD.IdentifierValue as [Supplier Product Code], '
					  
	set @sqlQuery = @sqlQuery + 'dbo.InvoiceDetailTypes.InvoiceDetailTypeName as [Invoice Type], dbo.InvoiceDetails.RetailerInvoiceID as [Invoice No], dbo.InvoiceDetails.TotalQty as [Total Qty], dbo.InvoiceDetails.PromoAllowance as [Allowance],
                      CAST(dbo.InvoiceDetails.UnitCost AS decimal(10,' + @CostFormat + '))  as [Unit Cost], 
                      CAST(dbo.InvoiceDetails.UnitRetail AS decimal(10,2))  as [Unit Retail], 
                      CAST((dbo.InvoiceDetails.[UnitCost] -isnull(dbo.InvoiceDetails.PromoAllowance,0))*dbo.InvoiceDetails.TotalQty AS decimal(10,' + @CostFormat + '))
                       as [Total Cost], 
                      CAST((dbo.InvoiceDetails.[UnitRetail])*dbo.InvoiceDetails.TotalQty AS decimal(10,2)) as [Total Retail], 
                      convert(date,dbo.InvoiceDetails.SaleDate,101)  as [Sale Date],
                      convert(date, dbo.InvoiceDetails.PaymentDueDate, 101) as [Payment Due Date]
					  FROM  dbo.Stores 
					  INNER JOIN dbo.Chains ON dbo.Stores.ChainID = dbo.Chains.ChainID 
                      INNER JOIN dbo.InvoiceDetails ON dbo.Stores.StoreID = dbo.InvoiceDetails.StoreID AND dbo.Chains.ChainID = dbo.InvoiceDetails.ChainID 
                      INNER JOIN dbo.Suppliers ON dbo.InvoiceDetails.SupplierID = dbo.Suppliers.SupplierID 
                      INNER JOIN dbo.InvoiceDetailTypes ON dbo.InvoiceDetails.InvoiceDetailTypeID = dbo.InvoiceDetailTypes.InvoiceDetailTypeID 
                      INNER JOIN dbo.Products ON dbo.InvoiceDetails.ProductID = dbo.Products.ProductID 
                      INNER JOIN ProductBrandAssignments PB on PB.ProductID=dbo.Products.ProductID 
					  INNER JOIN Brands B ON PB.BrandID = B.BrandID 
                      INNER JOIN dbo.ProductIdentifiers ON dbo.Products.ProductID = dbo.ProductIdentifiers.ProductID and dbo.ProductIdentifiers.ProductIdentifierTypeId = 2 
                      Left JOIN dbo.ProductIdentifiers PD ON dbo.Products.ProductID = PD.ProductID and PD.ProductIdentifierTypeId = 3 and PD.OwnerEntityId=dbo.Suppliers.SupplierID 
					  INNER JOIN SupplierBanners SB on SB.SupplierId = dbo.Suppliers.SupplierId and SB.Status=''Active'' and SB.Banner=dbo.Stores.Custom1 
                      INNER JOIN dbo.ProductIdentifierTypes ON dbo.ProductIdentifiers.ProductIdentifierTypeID = dbo.ProductIdentifierTypes.ProductIdentifierTypeID
                      WHERE  dbo.ProductIdentifiers.ProductIdentifierTypeID=2 and Stores.ActiveStatus=''Active'''
                     
                     if(@ChainId<>'-1')
                     	set @sqlQuery = @sqlQuery + ' and Chains.ChainID= ' + @ChainId 
                     
                     if(@SupplierId	>'-1')
                     	set @sqlQuery = @sqlQuery + ' and Suppliers.SupplierId= ' + @SupplierId 
                     
 					 if(len(@InvoiceNumber)>0) 
						set @sqlQuery = @sqlQuery + ' and InvoiceDetails.RetailerInvoiceId =' + @InvoiceNumber 
					
					 set @sqlQuery = @sqlQuery + ' order by Stores.storename,saledate';
					
					exec(@sqlQuery); 

End
GO
