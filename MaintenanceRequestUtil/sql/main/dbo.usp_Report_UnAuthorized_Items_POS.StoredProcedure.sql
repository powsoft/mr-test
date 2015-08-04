USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_UnAuthorized_Items_POS]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================

--[usp_Report_UnAuthorized_Items_POS] '40393',41713,'All','-1','40557','-1','','01/26/2014', '02/04/2014'

--select * from TransactionTypes 
CREATE  procedure [dbo].[usp_Report_UnAuthorized_Items_POS] 
	-- Add the parameters for the stored procedure here
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
Declare @Query varchar(max)
declare @AttValue int

 
	select @attvalue = AttributeID  from AttributeValues WITH(NOLOCK)  where OwnerEntityID=@PersonID and AttributeID=17
 
	set @Query ='						
					SELECT  ' + @MaxRowsCount + ' C.ChainName as [Chain Name], S.SupplierName as [Supplier Name], Stores.StoreName as [Store Name],
								   Stores.Custom1 as Banner, Stores.StoreIdentifier [Store Number], 
								   Products.ProductName as [Product Name], PD.IdentifierValue AS UPC, 
								   Brands.BrandName as [Brand Name], dbo.Source.SourceName as [Source Name], 
								   T.TransactionTypeName as [Transaction Type], 
								   convert(varchar(10),cast(ST.SaleDateTime as date),101) AS [Transaction Date], 
								   ST.Qty,isnull(SUV.RouteNumber,'''') as [Route Number], isnull(SUV.DriverName,'''') as [Driver Name],
								   isnull(SUV.SupplierAccountNumber,'''') as [Supplier Account No],isnull(SUV.SBTNumber,'''') as [SBT Number],
								    
								    ''UPC needs to be authorized for sale at this store''  as [Supplier Action Necessary]
					FROM  StoreTransactions ST with(nolock) 
					Left Join Productprices PP  with(nolock)  on PP.SupplierID=ST.SupplierID and PP.ChainID=ST.ChainID and PP.StoreID=ST.StoreID and PP.ProductID=ST.ProductID
					INNER JOIN
								   Stores with(nolock) ON ST.StoreID = Stores.StoreID and Stores.ActiveStatus=''Active'' INNER JOIN
								   dbo.Source ON ST.SourceId = dbo.Source.SourceId INNER JOIN
								   Products with(nolock) ON ST.ProductID = Products.ProductID INNER JOIN
								   Brands  with(nolock) ON ST.BrandID = Brands.BrandID INNER JOIN
								   ProductIdentifiers PD with(nolock)  ON Products.ProductID = PD.ProductID INNER JOIN
								   Suppliers S  with(nolock) ON ST.SupplierID = S.SupplierID INNER JOIN
								   SupplierBanners SB  with(nolock) on SB.SupplierId = S.SupplierID and SB.Status=''Active'' and SB.Banner=Stores.Custom1 inner join 
								   TransactionTypes T  with(nolock) ON ST.TransactionTypeID = T.TransactionTypeID INNER JOIN
								  Chains C  with(nolock) ON ST.ChainID = C.ChainID 
								   left join 
										  StoresUniqueValues  SUV  with(nolock) on Stores.Storeid=SUV.StoreID and SUV.SupplierID=S.SupplierID
					WHERE (t.BucketType=1) and pp.productid is null and cast(st.saledatetime as date) between cast(pp.ActiveStartDate as date) and cast(pp.activelastdate as date) and PD.ProductIdentifierTypeId=2 '

	if @AttValue =17
			set @Query = @Query + ' and C.ChainID in (select attributepart from dbo.fnGetRetailersTable(' +  cast(@PersonID as varchar) + '))'
		else
			set @Query = @Query + ' and S.SupplierID in (select attributepart from dbo.fnGetSupplierTable(' +  cast(@PersonID as varchar) + '))'
		
	if(@SupplierId<>'-1') 
		set @Query  = @Query  + ' and S.SupplierID=' + @SupplierId  
	  
	if(@chainID  <>'-1') 
		set @Query   = @Query  +  ' and C.ChainID=' + @chainID 

	if(@Banner<>'All') 
		set @Query  = @Query + ' and Stores.Custom1 like ''%' + @Banner + '%'''

	if(@StoreId <>'-1') 
		set @Query   = @Query  +  ' and Stores.StoreIdentifier like ''%' + @StoreId + '%''' 

	if(@ProductUPC  <>'-1') 
		set @Query   = @Query  +  ' and PD.IdentifierValue like ''%' + @ProductUPC + '%'''

	if (@LastxDays > 0)
		set @Query = @Query + ' and (ST.SaleDateTime >=dateadd(d,-' +  cast(@LastxDays as varchar) + ',getdate()) and ST.SaleDateTime <=getdate()) '  
	
	if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @Query = @Query + ' and ST.SaleDateTime >= ''' + @StartDate  + '''';

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @Query = @Query + ' and ST.SaleDateTime <= ''' + @EndDate  + '''';
		
	exec  (@Query )
	print (@Query)
END
GO
