USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_UnAuthorized_Inventory_All]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
--exec [usp_Report_UnAuthorized_Inventory_all] '40393','41544','All','','40561','','5','1900-01-01','1900-01-01'
CREATE  procedure [dbo].[usp_Report_UnAuthorized_Inventory_All] 
	-- Add the parameters for the stored procedure here
	@chainID varchar(max),
	@PersonID int,
	@Banner varchar(50),
	@ProductUPC varchar(20),
	@SupplierId varchar(max),
	@StoreId varchar(10),
	@LastxDays int,
	@StartDate varchar(20),
	@EndDate varchar(20)
AS
BEGIN
Declare @Query varchar(max)
declare @AttValue int

 select @attvalue = AttributeID  from AttributeValues WITH(NOLOCK)  where OwnerEntityID=@PersonID and AttributeID=17
 
	set @query = '
		SELECT   Chains.ChainName as [Chain Name], Suppliers.SupplierName as [Supplier Name],
				 Stores.StoreName as [Store Name], Stores.Custom1 as Banner, 
				 Stores.StoreIdentifier as [Store Number], Products.ProductName as [Product Name], 
				 ProductIdentifiers.IdentifierValue AS UPC, Brands.BrandName as [Brand Name], 
				 Source.SourceName as [Source Name], TransactionTypes.TransactionTypeName as [Transaction Type], 
				 convert(varchar(10),cast(S.SaleDateTime as date),101) AS [Transaction Date], 
				 S.Qty, isnull(StoresUniqueValues.RouteNumber,'''') as [Route Number],
				 isnull(StoresUniqueValues.DriverName,'''') as [Driver Name],
				 isnull(StoresUniqueValues.SupplierAccountNumber,'''') as [Supplier Account No],
				 isnull(StoresUniqueValues.SBTNumber,'''') as [SBT Number]
		FROM  StoreTransactions S WITH(NOLOCK)  INNER JOIN
					   Stores  WITH(NOLOCK)  ON S.StoreID = Stores.StoreID and Stores.ActiveStatus=''Active''  INNER JOIN
					   Source ON Source.SourceId = S.SourceId INNER JOIN
					   Products WITH(NOLOCK)  ON S.ProductID = Products.ProductID INNER JOIN
					   Brands  WITH(NOLOCK) ON S.BrandID = Brands.BrandID INNER JOIN
					   ProductIdentifiers  WITH(NOLOCK) ON Products.ProductID = ProductIdentifiers.ProductID INNER JOIN
					   Suppliers  WITH(NOLOCK) ON S.SupplierID = Suppliers.SupplierID INNER JOIN
					   SupplierBanners SB WITH(NOLOCK)  on SB.SupplierId = Suppliers.SupplierID and SB.Status=''Active'' and SB.Banner=Stores.Custom1 inner join 
					   TransactionTypes  WITH(NOLOCK) ON S.TransactionTypeID = TransactionTypes.TransactionTypeID INNER JOIN
					  Chains  WITH(NOLOCK) ON S.ChainID = Chains.ChainID left join 
							  StoresUniqueValues  WITH(NOLOCK)  on Stores.Storeid=StoresUniqueValues.StoreID and StoresUniqueValues.SupplierID=Suppliers.SupplierID	
		WHERE (S.TransactionTypeID IN (26)) and ProductIdentifiers.ProductIdentifierTypeId=2 '


		--if @AttValue =17
		--	set @query = @query +  ' and Chains.ChainID in (select attributepart from fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'
		--else
		--	set @query = @query +  ' and Suppliers.SupplierId in (select attributepart from fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 9))'

		if(@SupplierId<>'-1') 
			set @Query  = @Query  + ' and Suppliers.SupplierID in (' + @SupplierId  +')'

		if(@chainID  <>'-1') 
			set @Query   = @Query  +  ' and Chains.ChainID in (' + @chainID +')'

		if(@Banner<>'All') 
			set @Query  = @Query + ' and Stores.Custom1 like ''%' + @Banner + '%'''

		if(@StoreId <>'-1') 
			set @Query   = @Query  +  ' and Stores.StoreIdentifier like ''%' + @StoreId + '%'''

		if(@ProductUPC  <>'-1') 
			set @Query   = @Query  +  ' and ProductIdentifiers.IdentifierValue like ''%' + @ProductUPC + '%'''

		if (@LastxDays > 0)
			set @Query = @Query + ' and (S.SaleDateTime >=dateadd(d,-' +  cast(@LastxDays as varchar) + ',getdate()) and S.SaleDateTime <=getdate()) '  
		
		if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
			set @Query = @Query + ' and S.SaleDateTime >= ''' + @StartDate  + '''';

		if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
			set @Query = @Query + ' and S.SaleDateTime <= ''' + @EndDate  + '''';
		
		exec  (@Query )
END
GO
