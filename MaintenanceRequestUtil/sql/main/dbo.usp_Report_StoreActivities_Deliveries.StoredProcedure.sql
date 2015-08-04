USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_StoreActivities_Deliveries]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- usp_Report_StoreActivities_Deliveries 40393, 41550,'Albertsons - SCAL','-1','40557','-1',5,'01/23/2013','01/24/2013'
CREATE  procedure [dbo].[usp_Report_StoreActivities_Deliveries]

@chainID varchar(20),
@PersonID int,
@Banner varchar(50),
@ProductUPC varchar(20),
@SupplierId varchar(10),
@StoreId varchar(10),
@LastxDays int,
@StartDate varchar(20),
@EndDate varchar(20), @MaxRowsCount varchar(20) = ' Top 2500000 '
  
as
Begin
Declare @sqlQuery varchar(4000)
Declare @AttValue int
Declare @CostFormat varchar(10)

	if(@supplierID<>'-1')
		Select @CostFormat = Costformat from SupplierFormat WITH(NOLOCK)  where SupplierID = @supplierID
	 else
		set @CostFormat=4	
		set @CostFormat = ISNULL(@CostFormat , 4)
 	
 select @attvalue = AttributeID  from AttributeValues WITH(NOLOCK)  where OwnerEntityID=@PersonID and AttributeID=17
 
 set @sqlQuery =  ' SELECT  Chains.ChainName as Retailer, Stores.custom1 as Banner, Suppliers.SupplierName as Supplier,
					Products.ProductName as Product, Stores.StoreIdentifier as [Store No], Stores.Custom2 as [SBT Number],  
					ProductIdentifiers.IdentifierValue as UPC, 
					S.SupplierInvoiceNumber as [Supplier Doc No],
					Brands.BrandName as Brand, TransactionTypes.TransactionTypeName as Type, 
					convert(varchar(10), S.SaleDateTime, 101) as [Transaction Date],
					cast(S.Qty as varchar) as Qty, 
					''$''+ Convert(varchar(50), cast(S.rulecost as numeric(10,' + @CostFormat + '))) as Cost, 
					''$''+ Convert(varchar(50), cast(S.Promoallowance as numeric(10,' + @CostFormat + '))) as Promo,
					StoresUniqueValues.supplieraccountnumber as [Supplier Acct Number], 
					StoresUniqueValues.DriverName as [Driver Name], 
					StoresUniqueValues.RouteNumber as [Route Number] '
   
 set @sqlQuery = @sqlQuery +  ' FROM Chains  WITH(NOLOCK) INNER JOIN
                      StoreTransactions S WITH(NOLOCK)  ON Chains.ChainID = S.ChainID INNER JOIN
                      Stores  WITH(NOLOCK)  ON S.StoreID = Stores.StoreID and Stores.ActiveStatus=''Active'' INNER JOIN
                      Products WITH(NOLOCK)  ON S.ProductID = Products.ProductID INNER JOIN
                      Brands WITH(NOLOCK)  ON S.BrandID = Brands.BrandID INNER JOIN
                      Suppliers WITH(NOLOCK)  ON Suppliers.SupplierID = S.SupplierID INNER JOIN
                      TransactionTypes WITH(NOLOCK)  on TransactionTypes.TransactionTypeId = S.TransactionTypeID inner join
                      SupplierBanners SB WITH(NOLOCK)  on SB.SupplierId = Suppliers.SupplierID and SB.Status=''Active'' and SB.Banner=Stores.Custom1 inner join 
                      ProductIdentifiers WITH(NOLOCK)  ON Products.ProductID = ProductIdentifiers.ProductID LEFT OUTER JOIN
					  StoresUniqueValues  WITH(NOLOCK)  ON S.SupplierID = StoresUniqueValues.SupplierID 
					  AND S.StoreID=StoresUniqueValues.StoreID
                      WHERE  S.TransactionTypeID in (5,9,20) 
                      and  ProductIdentifiers.ProductIdentifierTypeId = 2'

	if @AttValue =17
			set @sqlQuery = @sqlQuery + ' and chains.ChainID in (select attributepart from dbo.fnGetRetailersTable(' +  cast(@PersonID as varchar) + '))'
		else
			set @sqlQuery = @sqlQuery + ' and Suppliers.SupplierID in (select attributepart from dbo.fnGetSupplierTable(' +  cast(@PersonID as varchar) + '))'
                         
	if(@ChainId <>'-1') 
		set @sqlQuery = @sqlQuery + ' and chains.ChainID=' + @ChainId
  
	if(@SupplierID <>'-1') 
		set @sqlQuery = @sqlQuery + ' and Suppliers.SupplierId=' + @SupplierId

	if(@Banner<>'All')
		set @sqlQuery = @sqlQuery + ' and Stores.custom1 like ''%' + @Banner + '%'''
 
	if(@ProductUPC<>'-1')
		set @sqlQuery = @sqlQuery + ' and ProductIdentifiers.IdentifierValue like ''%' + @ProductUPC + '%''';
	
	if(@StoreId <>'-1') 
		set @sqlQuery = @sqlQuery + ' and Stores.StoreIdentifier like ''%' + @StoreId + '%'''
	
	if (@LastxDays > 0)
		set @sqlQuery = @sqlQuery + ' and (S.SaleDateTime >=dateadd(d,-' +  cast(@LastxDays as varchar) + ',cast(getdate() as date)) and S.SaleDateTime <=cast(getdate() as date)) '  
	
	if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and S.SaleDateTime >= ''' + @StartDate  + '''';

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @sqlQuery = @sqlQuery + ' and S.SaleDateTime <= ''' + @EndDate  + '''';
		
	set @sqlQuery = @sqlQuery + ' order by 1,2,3,11'

	execute(@sqlQuery); 
 
End
GO
