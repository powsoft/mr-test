USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_ProductList]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_ProductList]
 @SupplierId varchar(20),
 @ChainId varchar(20),
 @Banner varchar(50),
 @StoreNumber varchar(50),
 @UPC Varchar(50),
 @ProductName varchar(10)
as

Begin
Declare @sqlQuery varchar(4000)
	set @sqlQuery = 'Select Distinct S.SupplierName, C.ChainName, ST.Custom1 as Banner, ST.StoreIdentifier as StoreNumber,
						PD.IdentifierValue as UPC,P.ProductID,P.ProductName, P.Description
						from StoreSetup SS
						inner join Suppliers S on S.SupplierID=SS.SupplierID
						inner join Chains C on C.ChainID=SS.ChainID
						inner join Stores ST on ST.StoreID=SS.StoreID
						inner join Products P on P.ProductID=SS.ProductID
						inner join ProductIdentifiers PD on PD.ProductID=P.ProductID and PD.ProductIdentifierTypeID=2
						WHERE 1=1 '

		if(@SupplierId <>'-1' )
			set @sqlQuery  = @sqlQuery  + ' and S.SupplierId =' + @SupplierId 
				
		if(@ChainId <>'-1' ) 
			set @sqlQuery = @sqlQuery + ' and C.ChainID = ''' + @ChainId + ''''
			
		if(@Banner <>'-1' ) 
			set @sqlQuery = @sqlQuery + ' and ST.Custom1 = ''' + @Banner + ''''
				
		if(@StoreNumber <>'') 
			set @sqlQuery  = @sqlQuery  + ' and ST.StoreIdentifier = ' + @StoreNumber

		if(@UPC <>'') 
			set @sqlQuery = @sqlQuery + ' and PD.IdentifierValue like ''%' + @UPC  + '%''';

		if(@ProductName <> '') 
			set @sqlQuery = @sqlQuery + ' and P.ProductName like ''%' + @ProductName + '%''';
  
		exec(@sqlQuery); 

End
GO
