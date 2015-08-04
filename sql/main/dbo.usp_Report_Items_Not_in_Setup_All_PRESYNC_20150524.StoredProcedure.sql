USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Items_Not_in_Setup_All_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE procedure [dbo].[usp_Report_Items_Not_in_Setup_All_PRESYNC_20150524] 
	@chainID varchar(1000),
	@PersonID int,
	@Banner varchar(50),
	@ProductUPC varchar(20),
	@SupplierId varchar(1000),
	@StoreId varchar(10),
	@LastxDays int,
	@StartDate varchar(20),
	@EndDate varchar(20)
AS
BEGIN
	Declare @Query varchar(5000)
	declare @AttValue int

	select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
 
	set @query = '
		SELECT    dbo.Chains.ChainName as Retailer, dbo.Suppliers.SupplierName as Supplier,
				  dbo.Stores.StoreName as [Store Name], dbo.Stores.Custom1 as Banner, 
				  dbo.Stores.StoreIdentifier AS [Store Number], dbo.Products.ProductName as [Product Name], 
				  dbo.ProductIdentifiers.IdentifierValue AS UPC, dbo.Brands.BrandName as [Brand Name], 
				  dbo.TransactionTypes.TransactionTypeName as [Transaction Type], 
				  dbo.FDatetime(S.saledatetime) AS [Sale Date], 
				  S.Qty,isnull(dbo.StoresUniqueValues.RouteNumber,'''') as [Route Number],
				  isnull(dbo.StoresUniqueValues.DriverName,'''') as [Driver Name],
				  isnull(dbo.StoresUniqueValues.SupplierAccountNumber,'''') as [SupplierAccount#],
				  isnull(dbo.StoresUniqueValues.SBTNumber,'''') as [SBT Number]
		FROM  datatrue_report.dbo.StoreTransactions S INNER JOIN
					   dbo.Stores ON S.StoreID = dbo.Stores.StoreID and dbo.Stores.ActiveStatus =''Active''  INNER JOIN
					   dbo.Products ON S.ProductID = dbo.Products.ProductID INNER JOIN
					   dbo.Brands ON S.BrandID = dbo.Brands.BrandID INNER JOIN
					   dbo.ProductIdentifiers ON dbo.Products.ProductID = dbo.ProductIdentifiers.ProductID  and dbo.ProductIdentifiers.ProductIdentifierTypeID=2 INNER JOIN
					   dbo.Suppliers ON S.SupplierID = dbo.Suppliers.SupplierID 
					   INNER JOIN dbo.TransactionTypes ON S.TransactionTypeID = dbo.TransactionTypes.TransactionTypeID 
					   INNER JOIN dbo.Chains ON S.ChainID = dbo.Chains.ChainID 
					   inner join SupplierBanners SB on SB.SupplierId = dbo.Suppliers.SupplierId and SB.Status=''Active'' and SB.Banner=dbo.Stores.Custom1
					   left join dbo.StoresUniqueValues on dbo.Stores.Storeid=dbo.StoresUniqueValues.StoreID and dbo.StoresUniqueValues.SupplierID=dbo.Suppliers.SupplierID
					   left join StoreSetup ST on ST.SupplierID=Suppliers.SupplierID and ST.StoreID=STores.StoreID and ST.ProductID=Products.ProductID
		WHERE 
		saledatetime >=''12/1/2011'' and ST.ProductID is null and dbo.TransactionTypes.BucketType =1 '

	--if @AttValue =17
	--	set @query = @query + ' and dbo.Chains.ChainID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'
	--else
	--	set @query = @query + ' and dbo.Suppliers.SupplierID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 9))'

	if(@SupplierId<>'-1') 
		set @Query  = @Query  + ' and Suppliers.SupplierID in (' + @SupplierId  +')'

	if(@chainID  <>'-1') 
		set @Query   = @Query  +  ' and dbo.Chains.ChainID in (' + @chainID +')'

	if(@Banner<>'All') 
		set @Query  = @Query + ' and dbo.Stores.Custom1 like ''%' + @Banner + '%'''

	if(@StoreId <>'-1') 
		set @Query   = @Query  +  ' and dbo.Stores.StoreIdentifier like ''%' + @StoreId + '%''' 

	if(@ProductUPC  <>'-1') 
		set @Query   = @Query  +  ' and dbo.ProductIdentifiers.IdentifierValue  like ''%' + @ProductUPC + '%'''

	if (@LastxDays > 0)
		set @Query = @Query + ' and S.SaleDateTime >=dateadd(d,-' +  cast(@LastxDays as varchar) + ',getDate()) and S.SaleDateTime <=getdate() '  
	
	if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @Query = @Query + ' and S.SaleDateTime >= ''' + @StartDate  + '''';

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @Query = @Query + ' and S.SaleDateTime <= ''' + @EndDate  + '''';
		
	exec  (@Query )
	
END
GO
