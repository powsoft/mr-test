USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UPCLookupStoreCountSupplier_XXXX]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_UPCLookupStoreCountSupplier_XXXX]
 
 @AttributeValue varchar(5),
 @ChainId varchar(5),
 @custom1 varchar(255),
 @UPC varchar(100),
 @ProductDescription varchar(255)

as

Begin
 Declare @sqlQuery varchar(4000)

 set @sqlQuery = 'SELECT     dbo.Suppliers.SupplierName as [Supplier Name], dbo.Stores.Custom1 AS Banner, dbo.Products.ProductName, dbo.ProductIdentifiers.IdentifierValue AS UPC, 
                      COUNT(dbo.StoreSetup.StoreID) AS [# of Stores Setup], dbo.NoOfStoresByBanner.[No of Stores] AS [TTL Stores In Banner]
FROM         dbo.StoreSetup INNER JOIN
                      dbo.Stores ON dbo.StoreSetup.StoreID = dbo.Stores.StoreID  and dbo.Stores.ActiveStatus=''Active'' INNER JOIN
                      dbo.ProductIdentifiers ON dbo.StoreSetup.ProductID = dbo.ProductIdentifiers.ProductID INNER JOIN
                      dbo.NoOfStoresByBanner ON dbo.Stores.Custom1 = dbo.NoOfStoresByBanner.Banner AND dbo.Stores.ChainID = dbo.NoOfStoresByBanner.ChainID INNER JOIN
                      dbo.Products ON dbo.ProductIdentifiers.ProductID = dbo.Products.ProductID INNER JOIN
                      SupplierBanners SB on SB.SupplierId = StoreSetup.SupplierId and SB.Status=''Active'' and SB.Banner=Stores.Custom1 inner join 
                      dbo.Suppliers ON dbo.StoreSetup.SupplierID = dbo.Suppliers.SupplierID
WHERE     (dbo.ProductIdentifiers.ProductIdentifierTypeID = 2) AND dbo.Suppliers.SupplierID = ' + @AttributeValue;

 if(@ChainId<>'-1') 
  set @sqlQuery = @sqlQuery +  ' and StoreSetup.ChainId=' + @ChainId

 if(@custom1='') 
  set @sqlQuery = @sqlQuery + ' and Stores.custom1 is Null'

 else if(@custom1<>'-1') 
  set @sqlQuery = @sqlQuery + ' and Stores.custom1=''' + @custom1 + ''''
  
 if(@UPC<>'') 
  set @sqlQuery = @sqlQuery + ' and ProductIdentifiers.IdentifierValue like ''%' + @UPC + '%''';
 
 if(@ProductDescription<>'') 
  set @sqlQuery = @sqlQuery + ' and Products.ProductName like ''%' + @ProductDescription + '%''';
 
 set @sqlQuery = @sqlQuery +  '	group by dbo.Stores.Custom1, dbo.ProductIdentifiers.IdentifierValue, dbo.NoOfStoresByBanner.[No of Stores], dbo.Products.ProductName, dbo.Suppliers.SupplierName'; 
 
execute(@sqlQuery); 

End
GO
