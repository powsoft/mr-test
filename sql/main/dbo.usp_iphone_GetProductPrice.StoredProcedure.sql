USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_iphone_GetProductPrice]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_iphone_GetProductPrice]
@SupplierID nvarchar(20),
@ChainID nvarchar(20),
@Banner nvarchar(100),
@StoreNo nvarchar(20),
@UPC nvarchar(20),
@RecordCount varchar(20)
as

Begin
 Declare @sqlQuery varchar(4000)

 set @sqlQuery = 'SELECT  distinct top ' + @RecordCount + '  dbo.ProductIdentifiers.IdentifierValue as [UPC], dbo.ProductPrices.UnitPrice as [Price]
                FROM dbo.ProductIdentifiers INNER JOIN
                dbo.ProductPrices ON dbo.ProductIdentifiers.ProductID = dbo.ProductPrices.ProductID INNER JOIN
                dbo.Stores ON dbo.ProductPrices.StoreID = dbo.Stores.StoreID
                WHERE 1=1'

 if(@supplierID<>'-1')
    set @sqlQuery = @sqlQuery +  ' and ProductPrices.supplierID=' + @supplierID
 
 if(@ChainID<>'-1')
    set @sqlQuery = @sqlQuery +  ' and ProductPrices.ChainId=' + @ChainID

 if(@Banner<>'-1')
    set @sqlQuery = @sqlQuery +  ' and Stores.Custom1=''' + @Banner + ''''


 if(@StoreNo<>'')
    set @sqlQuery = @sqlQuery + ' and  Stores.StoreIdentifier like ''%' + @StoreNo + '%'''
 
 if(@UPC<>'')
    set @sqlQuery = @sqlQuery + ' and ProductIdentifiers.IdentifierValue like ''%' + @UPC + '%'''
 
 execute(@sqlQuery);

End
GO
