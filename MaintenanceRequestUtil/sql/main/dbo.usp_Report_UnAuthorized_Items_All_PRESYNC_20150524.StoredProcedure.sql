USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_UnAuthorized_Items_All_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE procedure  [dbo].[usp_Report_UnAuthorized_Items_All_PRESYNC_20150524] 
	-- Add the parameters for the stored procedure here
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
 
	set @Query ='						
					SELECT   C.ChainName as [Chain Name], S.SupplierName as [Supplier Name], dbo.Stores.StoreName as [Store Name],
								   dbo.Stores.Custom1 as Banner, dbo.Stores.StoreIdentifier [Store Number], 
								   dbo.Products.ProductName as [Product Name], PD.IdentifierValue AS UPC, 
								   dbo.Brands.BrandName as [Brand Name], dbo.Source.SourceName as [Source Name], 
								   T.TransactionTypeName as [Transaction Type], dbo.FDatetime(ST.SaleDateTime) AS [Transaction Date], 
								   ST.Qty,isnull(SUV.RouteNumber,'''') as [Route Number], isnull(SUV.DriverName,'''') as [Driver Name],
								   isnull(SUV.SupplierAccountNumber,'''') as [Supplier Account No],isnull(SUV.SBTNumber,'''') as [SBT Number],
								   case when PP.ProductID Is null then
								    ''UPC needs to be setup at all stores delivered to''
								    else
								    ''UPC needs to be authorized for sale at this store'' end as [Supplier Action Necessary]
					FROM  datatrue_report.dbo.StoreTransactions ST
					Left Join ProductPrices PP on PP.SupplierID=ST.SupplierID and PP.ChainID=ST.ChainID and PP.StoreID=ST.StoreID and PP.ProductID=ST.ProductID
					INNER JOIN
								   dbo.Stores ON ST.StoreID = dbo.Stores.StoreID and dbo.Stores.ActiveStatus=''Active'' INNER JOIN
								   dbo.Source ON ST.SourceId = dbo.Source.SourceId INNER JOIN
								   dbo.Products ON ST.ProductID = dbo.Products.ProductID INNER JOIN
								   dbo.Brands ON ST.BrandID = dbo.Brands.BrandID INNER JOIN
								   dbo.ProductIdentifiers PD ON dbo.Products.ProductID = PD.ProductID INNER JOIN
								   dbo.Suppliers S ON ST.SupplierID = S.SupplierID INNER JOIN
								   SupplierBanners SB on SB.SupplierId = S.SupplierID and SB.Status=''Active'' and SB.Banner=dbo.Stores.Custom1 inner join 
								   dbo.TransactionTypes T ON ST.TransactionTypeID = T.TransactionTypeID INNER JOIN
								   dbo.Chains C ON ST.ChainID = C.ChainID 
								   left join 
										  dbo.StoresUniqueValues SUV on dbo.Stores.Storeid=SUV.StoreID and SUV.SupplierID=S.SupplierID
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
		set @Query  = @Query + ' and dbo.Stores.Custom1 like ''%' + @Banner + '%'''

	if(@StoreId <>'-1') 
		set @Query   = @Query  +  ' and dbo.Stores.StoreIdentifier like ''%' + @StoreId + '%''' 

	if(@ProductUPC  <>'-1') 
		set @Query   = @Query  +  '  and PD.IdentifierValue like ''%' + @ProductUPC + '%'''

	if (@LastxDays > 0)
		set @Query = @Query + ' and (ST.SaleDateTime >=dateadd(d,-' +  cast(@LastxDays as varchar) + ',getdate()) and ST.SaleDateTime <=getdate()) '  
	
	if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @Query = @Query + ' and ST.SaleDateTime >= ''' + @StartDate  + '''';

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @Query = @Query + ' and ST.SaleDateTime <= ''' + @EndDate  + '''';
		
	exec  (@Query )
	
END
GO
