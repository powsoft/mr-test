USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_InvoiceDetails_New]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_InvoiceDetails_New]
	@SupplierId varchar(10),
	@ChainId varchar(10),
	@InvoiceNumber varchar(255)
as

Begin
 Declare @sqlQuery varchar(4000)
 Declare @CostFormat varchar(10)
 
	 if(@supplierID<>'-1')
		Select @CostFormat = Costformat from SupplierFormat where SupplierID = @supplierID
	 else if(@ChainId<>'-1')
		Select @CostFormat = Costformat from SupplierFormat where SupplierID = @ChainId
	 else
		set @CostFormat=4
	set @CostFormat=isnull(@costFormat,4)
 	set @sqlQuery = 'SELECT  B.BrandName as Brand, dbo.Products.ProductName as Product, dbo.ProductIdentifiers.IdentifierValue as [UPC], PD.IdentifierValue as [Supplier Product Code], 
						CAST(dbo.InvoiceDetails.TotalQty AS decimal(10,' + @CostFormat + '))  as [Total Qty], 
						CAST(dbo.InvoiceDetails.PromoAllowance AS decimal(10,' + @CostFormat + '))  as [Allowance],
						CAST(dbo.InvoiceDetails.UnitCost AS decimal(10,' + @CostFormat + '))  as [Unit Cost], 
						CAST(dbo.InvoiceDetails.UnitRetail AS decimal(10,' + @CostFormat + '))  as [Unit Retail], 
						CAST((dbo.InvoiceDetails.[UnitCost] -isnull(dbo.InvoiceDetails.PromoAllowance,0))*dbo.InvoiceDetails.TotalQty AS decimal(10,' + @CostFormat + ')) as [Total Cost], 
						CAST((dbo.InvoiceDetails.[UnitRetail])*dbo.InvoiceDetails.TotalQty AS decimal(10,' + @CostFormat + ')) as [Total Retail]
						FROM  dbo.InvoiceDetails 
						INNER JOIN dbo.Products ON dbo.InvoiceDetails.ProductID = dbo.Products.ProductID 
						INNER JOIN ProductBrandAssignments PB on PB.ProductID=dbo.Products.ProductID 
						INNER JOIN Brands B ON PB.BrandID = B.BrandID 
						INNER JOIN dbo.ProductIdentifiers ON dbo.Products.ProductID = dbo.ProductIdentifiers.ProductID and dbo.ProductIdentifiers.ProductIdentifierTypeId in (2,8) 
						Left JOIN dbo.ProductIdentifiers PD ON dbo.Products.ProductID = PD.ProductID and PD.ProductIdentifierTypeId = 3 and PD.OwnerEntityId=dbo.InvoiceDetails.SupplierID 
						WHERE  dbo.ProductIdentifiers.ProductIdentifierTypeID in (2,8)'
                     
                     if(@ChainId<>'-1')
                     	set @sqlQuery = @sqlQuery + ' and dbo.InvoiceDetails.ChainID= ' + @ChainId 
                     
                     if(@SupplierId	>'-1')
                     	set @sqlQuery = @sqlQuery + ' and dbo.InvoiceDetails.SupplierId= ' + @SupplierId 
                     
 					 if(len(@InvoiceNumber)>0) 
						set @sqlQuery = @sqlQuery + ' and dbo.InvoiceDetails.RetailerInvoiceId =' + @InvoiceNumber 
					
					 set @sqlQuery = @sqlQuery + ' order by 1,2,3,4';
					
					exec(@sqlQuery); 

End
GO
