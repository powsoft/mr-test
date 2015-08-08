USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_RetailerData (Not in use)]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_RetailerData (Not in use)]
 
 @AttributeValue varchar(5),
 @SupplierId varchar(5),
 @custom1 varchar(255),
 @BrandId varchar(5),
 @UPC varchar(100),
 @ProductDescription varchar(255),
 @IdentifierId varchar(1),
 @Store varchar(10)
as

Begin
 Declare @sqlQuery varchar(4000)

 set @sqlQuery = 'SELECT dbo.Chains.ChainName, dbo.Stores.StoreName, dbo.Stores.Custom1 as Banner, dbo.Stores.StoreIdentifier as [Store Number], dbo.Products.ProductName, 
                dbo.Brands.BrandName
FROM  dbo.Stores INNER JOIN
               dbo.StoreSetup ON dbo.Stores.StoreID = dbo.StoreSetup.StoreID INNER JOIN
               dbo.Products ON dbo.StoreSetup.ProductID = dbo.Products.ProductID INNER JOIN
               dbo.ProductIdentifiers ON dbo.StoreSetup.ProductID = dbo.ProductIdentifiers.ProductID INNER JOIN
               dbo.Brands ON dbo.StoreSetup.BrandID = dbo.Brands.BrandID INNER JOIN
               dbo.Chains ON dbo.Stores.ChainID = dbo.Chains.ChainID
WHERE  (dbo.StoreSetup.ActiveStartDate <= { fn NOW() }) AND (dbo.StoreSetup.ActiveLastDate >= { fn NOW() })
     and dbo.stores.chainid = ' + @AttributeValue;

 if(@SupplierId<>'-1') 
  set @sqlQuery = @sqlQuery +  ' and suppliers.supplierid=' + @SupplierId 

 if(@custom1='') 
  set @sqlQuery = @sqlQuery + ' and Stores.custom1 is Null'

 else if(@custom1<>'-1') 
  set @sqlQuery = @sqlQuery + ' and Stores.custom1=''' + @custom1 + ''''
  
 if(@BrandId<>'-1') 
  set @sqlQuery = @sqlQuery +  ' and Brands.BrandId= ' + @BrandId

 if(@UPC<>'') 
  set @sqlQuery = @sqlQuery + ' and ProductIdentifiers.IdentifierValue like ''%' + @UPC + '%''';
 
 if(@ProductDescription<>'') 
  set @sqlQuery = @sqlQuery + ' and Products.ProductName like ''%' + @ProductDescription + '%''';
 set @sqlQuery = @sqlQuery +  ' and ProductIdentifiers.ProductIdentifierTypeId=' + @IdentifierId;

if(@Store<>'') 
  set @sqlQuery = @sqlQuery + ' and StoreIdentifier like ''%' + @Store + '%''';
 
execute(@sqlQuery); 

End
GO
