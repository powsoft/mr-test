USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_CostDifferencesPDI]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_CostDifferencesPDI]
 
 @ChainId varchar(10),
 @supplierID varchar(10),
 @BannerId varchar(255),
 @ProductName varchar(50),
 @UPC varchar(100),
 @SaleFromDate varchar(50),
 @SaleToDate varchar(50),
 @StoreNumber varchar(10),
 @SBTNumber varchar(10)
 
as
--exec usp_CostDifferences '40393','-1','-1','','','06/20/2013','06/24/2014','',''
Begin
 Declare @sqlQuery varchar(4000)

 Declare @CostFormat varchar(10)
 
	 if(@supplierID<>'-1')
		Select @CostFormat = Costformat from SupplierFormat where SupplierID = @supplierID
	 else
		set @CostFormat=4
	 set @CostFormat = ISNULL(@costformat,4)
	set @sqlQuery = ' SELECT     T.ChainName as Retailer, T.SupplierName as [Supplier Name], T.[Store Number], T.SBTNumber as [SBT Number], 
					  T.Banner, T.ProductName, T.UPC, cast(T.Qty as numeric) as Qty,
					  CAST(T.[Setup Cost] AS decimal(10,' + @CostFormat + ')) AS [Supplier Invoice Cost], 
                      CAST(T.[setup Promo] AS  decimal(10,' + @CostFormat + ')) AS [Supplier Invoice Promo], 
                      CAST(T.[Setup Net] AS decimal(10,' + @CostFormat + ')) AS [Supplier Invoice Net], 
                      CAST(T.[Reported Cost] as decimal(10,' + @CostFormat + ')) AS [Retailer Cost], 
                      CAST(T.[Reported Promo] AS  decimal(10,' + @CostFormat + ')) AS [Retailer Promo],  
                      CAST(T.RetailerNet AS decimal(10,' + @CostFormat + ')) AS [Retailer Net], 
                      convert(varchar(10), T.SaleDate, 101) AS SaleDate
					FROM    DataTrue_CustomResultSets.dbo.tmpCostDifferencesPDIByStore T 
					Where 1 = 1 '
					
	if(@ChainId <>'-1') 
		set @sqlQuery = @sqlQuery +  ' and T.ChainId=' + @ChainId 				

	if(@supplierID <>'-1') 
		set @sqlQuery = @sqlQuery +  ' and T.SupplierId=' + @supplierID  

	if(@BannerId='') 
		set @sqlQuery = @sqlQuery + ' and T.Banner is Null'

	else if(@BannerId<>'-1') 
		set @sqlQuery = @sqlQuery + ' and T.Banner=''' + @BannerId + ''''
	
	if (convert(date, @SaleFromDate  ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and T.SaleDate >= cast(''' + @SaleFromDate  + ''' as date)';

	if(convert(date, @SaleToDate ) > convert(date,'1900-01-01')) 
		set @sqlQuery = @sqlQuery + ' and T.SaleDate <= cast(''' + @SaleToDate  + ''' as date)';
		
	if(@UPC<>'') 
		set @sqlQuery = @sqlQuery + ' and T.UPC like ''%' + @UPC + '%''';
	 
	if(@StoreNumber <>'') 
		set @sqlQuery = @sqlQuery + ' and T.[Store Number] like ''%' + @StoreNumber  + '%''';
	  
	if(@SBTNumber<>'') 
		set @sqlQuery = @sqlQuery + ' and T.SBTNumber like ''%' + @SBTNumber + '%''';
	
	set @sqlQuery = @sqlQuery + ' order by T.SaleDate Desc'

exec(@sqlQuery); 

End
GO
