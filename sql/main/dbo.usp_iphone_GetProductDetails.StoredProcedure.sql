USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_iphone_GetProductDetails]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create procedure [dbo].[usp_iphone_GetProductDetails]
 @SupplierId varchar(20),
 @ChainId varchar(20),
 @StoreName varchar(50),
 @StoreNo varchar(50),
 @BannerName varchar(50),
 @ProductName varchar(50),
 @UPC varchar(50)
 
as

Begin
Declare @sqlQuery varchar(4000)
	set @sqlQuery = 'Select top 200 PD.IdentifierValue as [UPC], P.ProductName as [Product Name], P.Description, S.StoreIdentifier as [Store Number], S.StoreName as [Store Name], 
					S.Custom1 AS Banner, PP.UnitRetail as [Retail Price] from Products P 
					inner join ProductIdentifiers PD on PD.ProductID=P.ProductId
					inner join StoreSetup SS on SS.ProductID=P.ProductID
					inner join Suppliers SP on SP.SupplierID=SS.SupplierID
					inner join Chains C on C.ChainID=SS.ChainID
					inner join Stores S on S.StoreID=SS.StoreID and C.ChainID=S.ChainID
					inner join ProductPrices PP on PP.ProductID=P.ProductID and PP.SupplierID=SP.SupplierID and PP.StoreID=S.StoreID and PP.ProductPriceTypeID=3

					Where   1=1  '
			

		if(@SupplierId <>'-1' )	
			set @sqlQuery = @sqlQuery + ' and SP.SupplierID = ''' + @SupplierId + ''''
			
		if(@ChainId <>'-1' ) 
			set @sqlQuery = @sqlQuery + ' and C.ChainID = ''' + @ChainId + ''''
			
		if(@StoreName <>'') 
			set @sqlQuery  = @sqlQuery  + ' and S.StoreName like ''%' + @StoreName + '%'''
			
		if(@StoreNo <>'') 
			set @sqlQuery  = @sqlQuery  + ' and S.StoreIdentifier like ''%' + @StoreNo + '%'''
			
		if(@BannerName <>'') 
			set @sqlQuery  = @sqlQuery  + ' and S.Custom1 like ''%' + @BannerName + '%'''
			
		if(@ProductName <>'') 
			set @sqlQuery  = @sqlQuery  + ' and P.ProductName = ''' + @ProductName + ''''
			
		if(@UPC <>'') 
			set @sqlQuery  = @sqlQuery  + ' and PD.IdentifierValue = ''' + @UPC + ''''
			
		execute(@sqlQuery); 

End
GO
