USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_UnAuthorized_Items_All]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
--[usp_Report_UnAuthorized_Items_All] '40393',41713,'All','-1','-1','-1','','01/26/2014', '02/04/2014'
CREATE  procedure  [dbo].[usp_Report_UnAuthorized_Items_All] 
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
 
	set @Query ='						
					SELECT   C.ChainName as [Chain Name], S.SupplierName as [Supplier Name], Stores.StoreName as [Store Name],
								   Stores.Custom1 as Banner, Stores.StoreIdentifier [Store Number], 
								   Products.ProductName as [Product Name], PD.IdentifierValue AS UPC, 
								   Brands.BrandName as [Brand Name], dbo.Source.SourceName as [Source Name], 
								   T.TransactionTypeName as [Transaction Type], 
								   convert(varchar(10),cast(ST.SaleDateTime as date),101) AS [Transaction Date], 
								   ST.Qty,isnull(SUV.RouteNumber,'''') as [Route Number], isnull(SUV.DriverName,'''') as [Driver Name],
								   isnull(SUV.SupplierAccountNumber,'''') as [Supplier Account No],isnull(SUV.SBTNumber,'''') as [SBT Number],
								   case when PP.ProductID Is null then
								    ''UPC needs to be setup at all stores delivered to''
								    else
								    ''UPC needs to be authorized for sale at this store'' end as [Supplier Action Necessary]
					FROM  StoreTransactions ST WITH(NOLOCK) 
					Left Join Productprices PP WITH(NOLOCK)  on PP.SupplierID=ST.SupplierID and PP.ChainID=ST.ChainID and PP.StoreID=ST.StoreID and PP.ProductID=ST.ProductID
					INNER JOIN
								   Stores WITH(NOLOCK)   ON ST.StoreID = Stores.StoreID and Stores.ActiveStatus=''Active'' INNER JOIN
								   Source WITH(NOLOCK)  ON ST.SourceId = dbo.Source.SourceId INNER JOIN
								   Products  WITH(NOLOCK) ON ST.ProductID = Products.ProductID INNER JOIN
								   Brands  WITH(NOLOCK) ON ST.BrandID = Brands.BrandID INNER JOIN
								   ProductIdentifiers PD WITH(NOLOCK)  ON Products.ProductID = PD.ProductID INNER JOIN
								   Suppliers S  WITH(NOLOCK) ON ST.SupplierID = S.SupplierID INNER JOIN
								   SupplierBanners SB WITH(NOLOCK)  on SB.SupplierId = S.SupplierID and SB.Status=''Active'' and SB.Banner=Stores.Custom1 inner join 
								   dbo.TransactionTypes T  WITH(NOLOCK) ON ST.TransactionTypeID = T.TransactionTypeID INNER JOIN
								  Chains C ON ST.ChainID = C.ChainID 
								   left join 
										  StoresUniqueValues  SUV on Stores.Storeid=SUV.StoreID and SUV.SupplierID=S.SupplierID
					WHERE (ST.TransactionTypeID IN (24, 25)) and PD.ProductIdentifierTypeId=2 '



	--if @AttValue =17
	--	set @query = @query + ' and C.ChainID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'
	--else
	--	set @query = @query + ' and S.SupplierID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 9))'
		
	if(@SupplierId<>'-1') 
		set @Query  = @Query  + ' and S.SupplierID in (' + @SupplierId  +')'
	  
	if(@chainID  <>'-1') 
		set @Query   = @Query  +  ' and C.ChainID in (' + @chainID  +')'

	if(@Banner<>'All') 
		set @Query  = @Query + ' and Stores.Custom1 like ''%' + @Banner + '%'''

	if(@StoreId <>'-1') 
		set @Query   = @Query  +  ' and Stores.StoreIdentifier like ''%' + @StoreId + '%''' 

	if(@ProductUPC  <>'-1') 
		set @Query   = @Query  +  '  and PD.IdentifierValue like ''%' + @ProductUPC + '%'''

	if (@LastxDays > 0)
		set @Query = @Query + ' and (ST.SaleDateTime >=dateadd(d,-' +  cast(@LastxDays as varchar) + ',getdate()) and ST.SaleDateTime <=getdate()) '  
	
	if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @Query = @Query + ' and ST.SaleDateTime >= ''' + @StartDate  + '''';

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @Query = @Query + ' and ST.SaleDateTime <= ''' + @EndDate  + '''';
	
	
	
	
	
	-- For Unauthorized Deliveries
	
	
	set @Query +=' union all 						
					SELECT   C.ChainName as [Chain Name], S.SupplierName as [Supplier Name], Stores.StoreName as [Store Name],
								   Stores.Custom1 as Banner, Stores.StoreIdentifier [Store Number], 
								   ''N.A'' as [Product Name], st.UPC AS UPC, 
								   Brands.BrandName as [Brand Name], ST.Comments as [Source Name], 
								   T.TransactionTypeName as [Transaction Type], 
								   convert(varchar(10),cast(ST.SaleDateTime as date),101) AS [Transaction Date],
								   ST.Qty,isnull(SUV.RouteNumber,'''') as [Route Number], isnull(SUV.DriverName,'''') as [Driver Name],
								   isnull(SUV.SupplierAccountNumber,'''') as [Supplier Account No],isnull(SUV.SBTNumber,'''') as [SBT Number],
								   case when PP.ProductID Is null then
								    ''UPC needs to be setup at all stores delivered to''
								    else
								    ''UPC needs to be authorized for sale at this store'' end as [Supplier Action Necessary]
					FROM  StoreTransactions ST WITH(NOLOCK) 
					Left Join Productprices PP WITH(NOLOCK)  on PP.SupplierID=ST.SupplierID and PP.ChainID=ST.ChainID and PP.StoreID=ST.StoreID and PP.ProductID=ST.ProductID
					INNER JOIN
								   Stores WITH(NOLOCK)   ON ST.StoreID = Stores.StoreID and Stores.ActiveStatus=''Active'' INNER JOIN
								   --Source WITH(NOLOCK)  ON ST.SourceId = dbo.Source.SourceId INNER JOIN
								   --Products  WITH(NOLOCK) ON ST.ProductID = Products.ProductID INNER JOIN
								   Brands  WITH(NOLOCK) ON ST.BrandID = Brands.BrandID INNER JOIN
								   --ProductIdentifiers PD WITH(NOLOCK)  ON Products.ProductID = PD.ProductID INNER JOIN
								   Suppliers S  WITH(NOLOCK) ON ST.SupplierID = S.SupplierID INNER JOIN
								   SupplierBanners SB WITH(NOLOCK)  on SB.SupplierId = S.SupplierID and SB.Status=''Active'' and SB.Banner=Stores.Custom1 inner join 
								   dbo.TransactionTypes T  WITH(NOLOCK) ON ST.TransactionTypeID = T.TransactionTypeID INNER JOIN
								  Chains C ON ST.ChainID = C.ChainID 
								   left join 
										  StoresUniqueValues  SUV on Stores.Storeid=SUV.StoreID and SUV.SupplierID=S.SupplierID
					WHERE (ST.TransactionTypeID IN ( 40,41,42))  '



	--if @AttValue =17
	--	set @query = @query + ' and C.ChainID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'
	--else
	--	set @query = @query + ' and S.SupplierID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 9))'
		
	if(@SupplierId<>'-1') 
		set @Query  = @Query  + ' and S.SupplierID in (' + @SupplierId  +')'
	  
	if(@chainID  <>'-1') 
		set @Query   = @Query  +  ' and C.ChainID in (' + @chainID  +')'

	if(@Banner<>'All') 
		set @Query  = @Query + ' and Stores.Custom1 like ''%' + @Banner + '%'''

	if(@StoreId <>'-1') 
		set @Query   = @Query  +  ' and Stores.StoreIdentifier like ''%' + @StoreId + '%''' 

	--if(@ProductUPC  <>'-1') 
		--set @Query   = @Query  +  '  and PD.IdentifierValue like ''%' + @ProductUPC + '%'''

	if (@LastxDays > 0)
		set @Query = @Query + ' and (ST.SaleDateTime >=dateadd(d,-' +  cast(@LastxDays as varchar) + ',getdate()) and ST.SaleDateTime <=getdate()) '  
	
	if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @Query = @Query + ' and ST.SaleDateTime >= ''' + @StartDate  + '''';

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @Query = @Query + ' and ST.SaleDateTime <= ''' + @EndDate  + '''';
		
		
	
		
	PRINT(@Query )	
	exec  (@Query )
	
END
GO
