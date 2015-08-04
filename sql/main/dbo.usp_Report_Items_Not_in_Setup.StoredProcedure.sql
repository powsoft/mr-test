USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Items_Not_in_Setup]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================

-- exec usp_Report_Items_Not_in_Setup '40393','40384','All','','40562','-1','','1900-01-01','1900-01-01'
CREATE  procedure [dbo].[usp_Report_Items_Not_in_Setup] 
	@chainID varchar(20),
	@PersonID int,
	@Banner varchar(50),
	@ProductUPC varchar(20),
	@SupplierId varchar(10),
	@StoreId varchar(10),
	@LastxDays int,
	@StartDate varchar(20),
	@EndDate varchar(20), @MaxRowsCount varchar(20) = ' Top 2500000 '
AS
BEGIN
	Declare @Query varchar(5000)
	declare @AttValue int

	select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
 
	set @query = '
		SELECT     Chains.ChainName as Retailer,  Suppliers.SupplierName as Supplier,
				   Stores.StoreName as [Store Name],  Stores.Custom1 as Banner, 
				   Stores.StoreIdentifier AS [Store Number],  Products.ProductName as [Product Name], 
				   ProductIdentifiers.IdentifierValue AS UPC,  Brands.BrandName as [Brand Name], 
				   TransactionTypes.TransactionTypeName as [Transaction Type], 
				   convert(varchar(10),cast(S.saledatetime as date),101) AS [Sale Date], 
				  S.Qty,isnull(StoresUniqueValues.RouteNumber,'''') as [Route Number],
				  isnull(StoresUniqueValues.DriverName,'''') as [Driver Name],
				  isnull(StoresUniqueValues.SupplierAccountNumber,'''') as [SupplierAccount#],
				  isnull(StoresUniqueValues.SBTNumber,'''') as [SBT Number]
		FROM  StoreTransactions S  with(nolock) INNER JOIN
					   Stores  with(nolock) ON S.StoreID =  Stores.StoreID and  Stores.ActiveStatus =''Active''  INNER JOIN
					   Products  with(nolock) ON S.ProductID =  Products.ProductID INNER JOIN
					   Brands with(nolock) ON S.BrandID =  Brands.BrandID INNER JOIN
					   ProductIdentifiers with(nolock) ON  Products.ProductID =  ProductIdentifiers.ProductID  and  ProductIdentifiers.ProductIdentifierTypeID=2 INNER JOIN
					   Suppliers with(nolock) ON S.SupplierID =  Suppliers.SupplierID 
					   INNER JOIN  TransactionTypes with(nolock) ON S.TransactionTypeID =  TransactionTypes.TransactionTypeID 
					   INNER JOIN Chains with(nolock) ON S.ChainID =  Chains.ChainID 
					   inner join SupplierBanners SB  with(nolock) on SB.SupplierId =  Suppliers.SupplierId and SB.Status=''Active'' and SB.Banner=Stores.Custom1
					   left join StoresUniqueValues  with(nolock) on  Stores.Storeid=StoresUniqueValues.StoreID and  StoresUniqueValues.SupplierID=Suppliers.SupplierID
					   left join StoreSetup ST   with(nolock) on ST.SupplierID=Suppliers.SupplierID and ST.StoreID=STores.StoreID and ST.ProductID=Products.ProductID
		WHERE 
		saledatetime >=''12/1/2011'' and ST.ProductID is null and  TransactionTypes.BucketType =1 '

	if @AttValue =17
			set @Query = @Query + ' and chains.ChainID in (select attributepart from dbo.fnGetRetailersTable(' +  cast(@PersonID as varchar) + '))'
		else
			set @Query = @Query + ' and suppliers.SupplierID in (select attributepart from dbo.fnGetSupplierTable(' +  cast(@PersonID as varchar) + '))'

	
	if(@SupplierId<>'-1') 
		set @Query  = @Query  + ' and Suppliers.SupplierID=' + @SupplierId  

	if(@chainID  <>'-1') 
		set @Query   = @Query  +  ' and  Chains.ChainID=' + @chainID 

	if(@Banner<>'All') 
		set @Query  = @Query + ' and  Stores.Custom1 like ''%' + @Banner + '%'''

	if(@StoreId <>'-1') 
		set @Query   = @Query  +  ' and  Stores.StoreIdentifier like ''%' + @StoreId + '%''' 

	if(@ProductUPC  <>'-1') 
		set @Query   = @Query  +  ' and  ProductIdentifiers.IdentifierValue  like ''%' + @ProductUPC + '%'''

	if (@LastxDays > 0)
		set @Query = @Query + ' and cast(S.SaleDateTime as date) >=cast(dateadd(d,-' +  cast(@LastxDays as varchar) + ',getDate()) as date) and cast(S.SaleDateTime as date)<= cast(getdate() as date)'  
	
	if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @Query = @Query + ' and S.SaleDateTime >= ''' + @StartDate  + '''';

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @Query = @Query + ' and S.SaleDateTime <= ''' + @EndDate  + '''';
		
	exec  (@Query )
	
END
GO
