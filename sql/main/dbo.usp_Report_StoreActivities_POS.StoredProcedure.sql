USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_StoreActivities_POS]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- usp_Report_StoreActivities_POS_All '75221','59977','Maverik','-1','-1','-1','0','11/17/2014','11/17/2014'
CREATE  procedure [dbo].[usp_Report_StoreActivities_POS]

@chainID varchar(1000),
@PersonID int,
@Banner varchar(50),
@ProductUPC varchar(20),
@SupplierId varchar(1000),
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
		Begin
		DECLARE @sqlCommand nvarchar(1000)
		declare @counts int
		SET @sqlCommand = 'SELECT @cnt=Max(Costformat) FROM SupplierFormat WITH(NOLOCK)  where SupplierID in ('+ @supplierID+' )'
		EXECUTE sp_executesql @sqlCommand, N'@cnt int OUTPUT',   @cnt=@CostFormat OUTPUT
		End
	 else
		set @CostFormat=4	
		set @CostFormat = ISNULL(@CostFormat , 4)
 	
 select @attvalue = AttributeID  from AttributeValues WITH(NOLOCK)  where OwnerEntityID=@PersonID and AttributeID=17
 
 set @sqlQuery =  ' SELECT ' + @MaxRowsCount + ' Chains.ChainName as Retailer, Stores.custom1 as Banner, Suppliers.SupplierName as Supplier,
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
   
 set @sqlQuery = @sqlQuery +  ' FROM Chains WITH(NOLOCK)  
								INNER JOIN StoreTransactions S WITH(NOLOCK)  ON Chains.ChainID = S.ChainID 
								INNER JOIN Stores  WITH(NOLOCK)  ON S.StoreID = Stores.StoreID and Stores.ActiveStatus=''Active'' 
								INNER JOIN Products WITH(NOLOCK)  ON S.ProductID = Products.ProductID 
								INNER JOIN Suppliers WITH(NOLOCK)  ON Suppliers.SupplierID = S.SupplierID 
								INNER JOIN TransactionTypes WITH(NOLOCK)  on TransactionTypes.TransactionTypeId = S.TransactionTypeID 
								inner join SupplierBanners SB WITH(NOLOCK)  on SB.SupplierId = Suppliers.SupplierID and SB.Status=''Active'' and SB.Banner=Stores.Custom1 
								inner join ProductIdentifiers  WITH(NOLOCK) ON Products.ProductID = ProductIdentifiers.ProductID and dbo.ProductIdentifiers.IdentifierValue = s.UPC
								left join dbo.ProductBrandAssignments PB  WITH(NOLOCK) on PB.ProductID=dbo.Products.ProductID and PB.CustomOwnerEntityId= S.SupplierID 
								left join dbo.Brands  WITH(NOLOCK) ON PB.BrandID = dbo.Brands.BrandID
								LEFT OUTER JOIN StoresUniqueValues  WITH(NOLOCK)  ON S.SupplierID = StoresUniqueValues.SupplierID AND S.StoreID=StoresUniqueValues.StoreID
								left outer join dbo.ProductIdentifiers PD  WITH(NOLOCK) on dbo.Products.ProductID = PD.ProductID and PD.ProductIdentifierTypeId =3 and PD.OwnerEntityId=S.SupplierID
								left JOIN Warehouses WH  WITH(NOLOCK) ON WH.ChainID=Chains.ChainID and WH.WarehouseId=StoresUniqueValues.DistributionCenter
									  WHERE  S.TransactionTypeID in (2,6,7,16) and  ProductIdentifiers.ProductIdentifierTypeId IN(2,8)
									  and Cast(S.SaleDateTime as date) between Cast(Stores.ActiveFromDate as date) and Cast(Stores.ActiveLastDate as date) '

	--if @AttValue =17
	--	set @sqlQuery = @sqlQuery +  ' and Chains.ChainID in (select attributepart from fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'
	--else
	--	set @sqlQuery = @sqlQuery +  ' and Suppliers.SupplierId in (select attributepart from fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 9))'
                      
	if(@ChainId <>'-1') 
		set @sqlQuery = @sqlQuery + ' and chains.ChainID in (' + @ChainId +')'
  
	if(@SupplierID <>'-1') 
		set @sqlQuery = @sqlQuery + ' and Suppliers.SupplierId in (' + @SupplierId +')'

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

	print(@sqlQuery);
	execute(@sqlQuery); 
 
End
GO
