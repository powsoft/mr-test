USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetProductList]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_GetProductList]
@SupplierId varchar(20),
@ChainId varchar(20),
@StoreNumber varchar(50),
@Banner varchar(50),
@UPC varchar(50),
@TableName varchar(20)
as
 
Begin
Declare @sqlQuery varchar(4000)
    set @sqlQuery = 'SELECT distinct Stores.StoreId, Stores.StoreIdentifier as [StoreNumber], Stores.Custom1 as [Banner],
              dbo.ProductIdentifiers.IdentifierValue AS UPC, dbo.Products.ProductName,dbo.Products.ProductId
                     
            FROM dbo.ProductIdentifiers
            INNER JOIN dbo.Products ON dbo.ProductIdentifiers.ProductID = dbo.Products.ProductID and dbo.ProductIdentifiers.ProductIdentifierTypeId=2
            INNER JOIN dbo.' + @TableName + ' ON dbo.ProductIdentifiers.ProductID = dbo.' + @TableName + '.ProductID
            INNER JOIN dbo.Stores ON dbo.Stores.StoreId = dbo.' +  @TableName + '.StoreId and dbo.Stores.ActiveStatus=''Active''
            Inner join SupplierBanners SB on SB.Banner=dbo.Stores.Custom1 and Status=''Active'' and SB.SupplierId=dbo.' + @TableName + '.Supplierid
            WHERE dbo.' + @TableName + '.ActiveLastDate>=GETDATE()  '
           
        if(@SupplierId <>'-1' )   
            set @sqlQuery = @sqlQuery + ' and dbo.' + @TableName + '.Supplierid = ' + @SupplierId
           
        if(@ChainId <> '-1' )
            set @sqlQuery = @sqlQuery + ' and dbo.' + @TableName + '.ChainID = ''' + @ChainId + ''''
           
        if(@StoreNumber <>'')
            set @sqlQuery  = @sqlQuery  + ' and Stores.StoreIdentifier like ''%' + @StoreNumber + '%''';
 
        if(@Banner <>'-1' )
            set @sqlQuery = @sqlQuery + ' and Stores.custom1 = ''' + @Banner + ''''
           
        if(@UPC <>'')
            set @sqlQuery  = @sqlQuery  + ' and dbo.ProductIdentifiers.IdentifierValue like ''%' + @UPC + '%''';
 
        execute(@sqlQuery);
 
End
GO
