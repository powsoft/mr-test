USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_CostDifferencesPageSupplier]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_CostDifferencesPageSupplier]
 
 @AttributeValue varchar(10),
 @chainID varchar(10),
 @custom1 varchar(255),
 @BrandId varchar(10),
 @UPC varchar(100),
 @SaleFromDate varchar(50),
 @SaleToDate varchar(50),
 @StoreNumber varchar(10),
 @SBTNumber varchar(10)
  
as

Begin
 Declare @sqlQuery varchar(4000)

 set @sqlQuery = 'SELECT     dbo.Chains.ChainName as Retailer, dbo.Stores.StoreIdentifier as [Store Number], dbo.Stores.Custom2 as [SBT Number], dbo.Stores.Custom1 AS Banner, dbo.Suppliers.SupplierName, dbo.Products.ProductName, 
                      dbo.ProductIdentifiers.IdentifierValue AS UPC, CAST(SUM(dbo.StoreTransactions.Qty) AS varchar) AS Qty, 
                      CAST(dbo.StoreTransactions.SetupCost AS decimal(10,4)) AS [Supplier Cost], 
                      CAST(dbo.StoreTransactions.PromoAllowance AS decimal(10,4)) AS [Supplier Promo], 
                      CAST(dbo.StoreTransactions.SetupCost as decimal(10,4)) - Cast(isnull(dbo.StoreTransactions.PromoAllowance,0) AS decimal(10,4)) AS [Supplier Net], 
                      CAST((dbo.StoreTransactions.ReportedCost as decimal(10,4)) + CAST(dbo.StoreTransactions.ReportedAllowance) AS decimal(10,4)) AS [Retailer Cost], 
                      CAST(dbo.StoreTransactions.ReportedAllowance AS decimal(10,4)) AS [Retailer Promo], 
                      CAST(dbo.StoreTransactions.ReportedCost AS decimal(10,4)) as [Retailer Net],
                      CONVERT(varchar(10), dbo.StoreTransactions.SaleDateTime, 
                      101) AS SaleDate
FROM         dbo.TransactionTypes INNER JOIN
                      dbo.StoreTransactions INNER JOIN
                      dbo.Suppliers ON dbo.StoreTransactions.SupplierID = dbo.Suppliers.SupplierID INNER JOIN
                      dbo.Chains ON dbo.Chains.ChainID = dbo.StoreTransactions.ChainID INNER JOIN
                      dbo.Stores ON dbo.StoreTransactions.StoreID = dbo.Stores.StoreID and dbo.Stores.ActiveStatus=''Active'' INNER JOIN
                      dbo.Products ON dbo.StoreTransactions.ProductID = dbo.Products.ProductID INNER JOIN
                      dbo.ProductIdentifiers ON dbo.Products.ProductID = dbo.ProductIdentifiers.ProductID ON 
                      dbo.TransactionTypes.TransactionTypeID = dbo.StoreTransactions.TransactionTypeID 
                      Inner join SupplierBanners SB on SB.SupplierId = dbo.Suppliers.SupplierId and SB.Status=''Active'' and SB.Banner=dbo.Stores.Custom1
                     
WHERE     (dbo.ProductIdentifiers.ProductIdentifierTypeID = 2) AND (dbo.TransactionTypes.BucketTypeName = ''POS'') AND 
                      (convert(decimal(10,4),dbo.StoreTransactions.SetupCost) - convert(decimal(10,4),isnull(dbo.StoreTransactions.PromoAllowance,0)) <>
                       convert(decimal(10,4),dbo.StoreTransactions.ReportedCost) )
                     
                      AND dbo.suppliers.SupplierId  = ' + @AttributeValue 

	if(@chainID<>'-1') 
		set @sqlQuery = @sqlQuery +  ' and dbo.StoreTransactions.ChainID=' + @chainID 

	if(@custom1='') 
		set @sqlQuery = @sqlQuery + ' and stores.custom1 is Null'

	else if(@custom1<>'-1') 
		set @sqlQuery = @sqlQuery + ' and stores.custom1=''' + @custom1 + ''''

	if( convert(date, @SaleFromDate  ) > convert(date,'1900-01-01') and  convert(date, @SaleToDate ) > convert(date,'1900-01-01') ) 
		set @sqlQuery = @sqlQuery + ' and  dbo.StoreTransactions.SaleDateTime  between ''' + @SaleFromDate  + ''' and ''' + @SaleToDate + ''''  ;

	else if (convert(date, @SaleFromDate  ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and  dbo.StoreTransactions.SaleDateTime  between ''' + @SaleFromDate  + '''';

	else if(convert(date, @SaleToDate ) > convert(date,'1900-01-01')) 
		set @sqlQuery = @sqlQuery + ' and  ''' + @SaleToDate  + '''';

	if(@UPC<>'') 
		set @sqlQuery = @sqlQuery + ' and dbo.ProductIdentifiers.IdentifierValue like ''%' + @UPC + '%''';
	 
	if(@StoreNumber <>'') 
		set @sqlQuery = @sqlQuery + ' and dbo.Stores.StoreIdentifier like ''%' + @StoreNumber  + '%''';

	if(@SBTNumber<>'') 
		set @sqlQuery = @sqlQuery + ' and dbo.Stores.Custom2 like ''%' + @SBTNumber + '%''';
	
	set @sqlquery = @sqlQuery  + ' GROUP BY dbo.Chains.ChainName, dbo.Stores.StoreIdentifier, dbo.Stores.Custom1, dbo.Stores.Custom2, dbo.Suppliers.SupplierName, 
								   dbo.Products.ProductName, dbo.ProductIdentifiers.IdentifierValue, 
								   CAST(dbo.StoreTransactions.SetupCost AS decimal(10,4)), 
								   CAST(dbo.StoreTransactions.PromoAllowance AS decimal(10,4)), 
								   CAST(dbo.StoreTransactions.SetupCost as decimal(10,4)) - Cast(isnull(dbo.StoreTransactions.PromoAllowance,0) AS decimal(10,4)), 
								   CAST((dbo.StoreTransactions.ReportedCost as decimal(10,4)) + Cast(dbo.StoreTransactions.ReportedAllowance) AS decimal(10,4)), 
							       CAST(dbo.StoreTransactions.ReportedAllowance AS decimal(10,4)), CAST(dbo.StoreTransactions.ReportedCost AS decimal(10,4)), 
							       CONVERT(varchar(10), dbo.StoreTransactions.SaleDateTime, 101)
								   HAVING (CAST(SUM(dbo.StoreTransactions.Qty) AS varchar) <> ''0'')';
 
exec(@sqlQuery); 
--print(@sqlQuery)
End
GO
