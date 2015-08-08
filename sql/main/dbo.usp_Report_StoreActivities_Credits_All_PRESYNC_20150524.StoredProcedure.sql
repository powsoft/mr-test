USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_StoreActivities_Credits_All_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_Report_StoreActivities_Credits_All_PRESYNC_20150524]
-- exec usp_Report_StoreActivities_Credits '40393','2','All','','-1','','30','1900-01-01','1900-01-01'
@chainID varchar(1000),
@PersonID int,
@Banner varchar(50),
@ProductUPC varchar(20),
@SupplierId varchar(1000),
@StoreId varchar(10),
@LastxDays int,
@StartDate varchar(20),
@EndDate varchar(20)
  
as
Begin
Declare @sqlQuery varchar(4000)
Declare @AttValue int
Declare @CostFormat varchar(10)

	if(@supplierID<>'-1')
		Begin
		DECLARE @sqlCommand nvarchar(1000)
		declare @counts int
		SET @sqlCommand = 'SELECT @cnt=Max(Costformat) FROM SupplierFormat where SupplierID in ('+ @supplierID+' )'
		EXECUTE sp_executesql @sqlCommand, N'@cnt int OUTPUT',   @cnt=@CostFormat OUTPUT
		End
	 else
		set @CostFormat=4	
		
		set @CostFormat = ISNULL(@CostFormat , 4)
 	
 select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
 
 set @sqlQuery =  ' SELECT  dbo.Chains.ChainName as Retailer, dbo.Stores.custom1 as Banner, dbo.Suppliers.SupplierName as Supplier,
					dbo.Products.ProductName as Product, dbo.Stores.StoreIdentifier as [Store No], dbo.Stores.Custom2 as [SBT Number],  
					dbo.ProductIdentifiers.IdentifierValue as UPC, 
					S.SupplierInvoiceNumber as [Supplier Doc No],
					dbo.Brands.BrandName as Brand, dbo.TransactionTypes.TransactionTypeName as Type, 
					convert(varchar(10), S.SaleDateTime, 101) as [Transaction Date],
					cast(S.Qty as varchar) as Qty, 
					''$''+ Convert(varchar(50), cast(S.rulecost as numeric(10,' + @CostFormat + '))) as Cost, 
					''$''+ Convert(varchar(50), cast(S.Promoallowance as numeric(10,' + @CostFormat + '))) as Promo,
					dbo.StoresUniqueValues.supplieraccountnumber as [Supplier Acct Number], 
					dbo.StoresUniqueValues.DriverName as [Driver Name], 
					dbo.StoresUniqueValues.RouteNumber as [Route Number] '
 
 set @sqlQuery = @sqlQuery +  ' FROM dbo.Chains INNER JOIN
                      datatrue_report.dbo.StoreTransactions S ON dbo.Chains.ChainID = S.ChainID INNER JOIN
                      dbo.Stores ON S.StoreID = dbo.Stores.StoreID and dbo.Stores.ActiveStatus=''Active''  INNER JOIN
                      dbo.Products ON S.ProductID = dbo.Products.ProductID INNER JOIN
                      dbo.Brands ON S.BrandID = dbo.Brands.BrandID INNER JOIN
                      dbo.Suppliers ON dbo.Suppliers.SupplierID = S.SupplierID INNER JOIN
                      dbo.TransactionTypes on dbo.TransactionTypes.TransactionTypeId = S.TransactionTypeID inner join
                      SupplierBanners SB on SB.SupplierId = dbo.Suppliers.SupplierID and SB.Status=''Active'' and SB.Banner=dbo.Stores.Custom1 inner join 
                      dbo.ProductIdentifiers ON dbo.Products.ProductID = dbo.ProductIdentifiers.ProductID LEFT OUTER JOIN
					  dbo.StoresUniqueValues ON S.SupplierID = dbo.StoresUniqueValues.SupplierID 
					  AND S.StoreID=dbo.StoresUniqueValues.StoreID
                      WHERE  S.TransactionTypeID in (21,8,14) 
                      and  ProductIdentifiers.ProductIdentifierTypeId = 2'

	--if @AttValue =17
	--	set @sqlQuery = @sqlQuery +  ' and dbo.Chains.ChainID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'
	--else
	--	set @sqlQuery = @sqlQuery +  ' and dbo.Suppliers.SupplierId in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 9))'
                      
	if(@ChainId <>'-1') 
		set @sqlQuery = @sqlQuery + ' and dbo.chains.ChainID in (' + @ChainId+')'
  
	if(@SupplierID <>'-1') 
		set @sqlQuery = @sqlQuery + ' and Suppliers.SupplierId in (' + @SupplierId+')'

	if(@Banner<>'All')
		set @sqlQuery = @sqlQuery + ' and Stores.custom1 like ''%' + @Banner + '%'''
 
	if(@ProductUPC<>'-1')
		set @sqlQuery = @sqlQuery + ' and ProductIdentifiers.IdentifierValue like ''%' + @ProductUPC + '%''';
	
	if(@StoreId <>'-1') 
		set @sqlQuery = @sqlQuery + ' and Stores.StoreIdentifier like ''%' + @StoreId + '%'''
	
	if (@LastxDays > 0)
		set @sqlQuery = @sqlQuery + ' and (S.SaleDateTime >=dateadd(d,-' +  cast(@LastxDays as varchar) + ',getdate()) and S.SaleDateTime <=getdate()) '  
	
	if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and S.SaleDateTime >= ''' + @StartDate  + '''';

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @sqlQuery = @sqlQuery + ' and S.SaleDateTime <= ''' + @EndDate  + '''';
	
	
	set @sqlQuery = @sqlQuery + ' order by 1,2,3,11'

execute(@sqlQuery); 
 
End
GO
