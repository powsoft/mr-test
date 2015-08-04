USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_UnAuthorized_Inventory_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
--exec [usp_Report_UnAuthorized_Inventory] 40393,44280,'ALL',
CREATE procedure [dbo].[usp_Report_UnAuthorized_Inventory_PRESYNC_20150524] 
	-- Add the parameters for the stored procedure here
	@chainID varchar(20),
	@PersonID int,
	@Banner varchar(50),
	@ProductUPC varchar(20),
	@SupplierId varchar(10),
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
		SELECT   dbo.Chains.ChainName as [Chain Name], dbo.Suppliers.SupplierName as [Supplier Name],
				 dbo.Stores.StoreName as [Store Name], dbo.Stores.Custom1 as Banner, 
				 dbo.Stores.StoreIdentifier as [Store Number], dbo.Products.ProductName as [Product Name], 
				 dbo.ProductIdentifiers.IdentifierValue AS UPC, dbo.Brands.BrandName as [Brand Name], 
				 dbo.Source.SourceName as [Source Name], dbo.TransactionTypes.TransactionTypeName as [Transaction Type], 
				 dbo.FDatetime(S.SaleDateTime) AS [Transaction Date], 
				 S.Qty, isnull(dbo.StoresUniqueValues.RouteNumber,'''') as [Route Number],
				 isnull(dbo.StoresUniqueValues.DriverName,'''') as [Driver Name],
				 isnull(dbo.StoresUniqueValues.SupplierAccountNumber,'''') as [Supplier Account No],
				 isnull(dbo.StoresUniqueValues.SBTNumber,'''') as [SBT Number]
		FROM  datatrue_report.dbo.StoreTransactions S INNER JOIN
					   dbo.Stores ON S.StoreID = dbo.Stores.StoreID and dbo.Stores.ActiveStatus=''Active''  INNER JOIN
					   dbo.Source ON dbo.Source.SourceId = S.SourceId INNER JOIN
					   dbo.Products ON S.ProductID = dbo.Products.ProductID INNER JOIN
					   dbo.Brands ON S.BrandID = dbo.Brands.BrandID INNER JOIN
					   dbo.ProductIdentifiers ON dbo.Products.ProductID = dbo.ProductIdentifiers.ProductID INNER JOIN
					   dbo.Suppliers ON S.SupplierID = dbo.Suppliers.SupplierID INNER JOIN
					   SupplierBanners SB on SB.SupplierId = dbo.Suppliers.SupplierID and SB.Status=''Active'' and SB.Banner=dbo.Stores.Custom1 inner join 
					   dbo.TransactionTypes ON S.TransactionTypeID = dbo.TransactionTypes.TransactionTypeID INNER JOIN
					   dbo.Chains ON S.ChainID = dbo.Chains.ChainID left join 
							  dbo.StoresUniqueValues on dbo.Stores.Storeid=dbo.StoresUniqueValues.StoreID and dbo.StoresUniqueValues.SupplierID=dbo.Suppliers.SupplierID	
		WHERE (S.TransactionTypeID IN (26)) and dbo.ProductIdentifiers.ProductIdentifierTypeId=2 '


		if @AttValue =17
			set @query = @query +  ' and dbo.Chains.ChainID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'
		else
			set @query = @query +  ' and dbo.Suppliers.SupplierId in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 9))'

		if(@SupplierId<>'-1') 
			set @Query  = @Query  + ' and Suppliers.SupplierID=' + @SupplierId  

		if(@chainID  <>'-1') 
			set @Query   = @Query  +  ' and dbo.Chains.ChainID=' + @chainID 

		if(@Banner<>'All') 
			set @Query  = @Query + ' and dbo.Stores.Custom1 like ''%' + @Banner + '%'''

		if(@StoreId <>'-1') 
			set @Query   = @Query  +  ' and dbo.Stores.StoreIdentifier like ''%' + @StoreId + '%'''

		if(@ProductUPC  <>'-1') 
			set @Query   = @Query  +  ' and dbo.ProductIdentifiers.IdentifierValue like ''%' + @ProductUPC + '%'''

		if (@LastxDays > 0)
			set @Query = @Query + ' and (S.SaleDateTime >=dateadd(d,-' +  cast(@LastxDays as varchar) + ',getdate()) and S.SaleDateTime <=getdate()) '  
		
		if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
			set @Query = @Query + ' and S.SaleDateTime >= ''' + @StartDate  + '''';

		if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
			set @Query = @Query + ' and S.SaleDateTime <= ''' + @EndDate  + '''';
		
		exec  (@Query )
END
GO
