USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_No_Store_Feed_All]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  procedure  [dbo].[usp_Report_No_Store_Feed_All] 
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

	select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
	
	set @query = '	Select distinct SP.SupplierName as [Supplier Name], C.ChainName as [Chain Name],  t.Banner, s.StoreIdentifier as [Store Number], 
					convert(varchar(10), t.OnSaleDate, 101)  as [On Sale Date Not Received], t.TransactionType as [Transaction Type Not Received]
					from DataTrue_CustomResultSets.dbo.tmpNoStoreFeed t WITH(NOLOCK) 
					inner join Chains C WITH(NOLOCK)  on C.ChainId=t.ChainId
					inner join Suppliers SP WITH(NOLOCK)  on SP.SupplierId=t.SupplierId
					inner join Stores S WITH(NOLOCK)  on S.StoreID=t.StoreId and S.ChainID=t.ChainId and S.Custom1=t.Banner
					INNER JOIN SupplierBanners SB WITH(NOLOCK)  on SB.SupplierId = SP.SupplierID and SB.Status=''Active'' and SB.Banner=t.Banner
					where 1=1 '

	--if @AttValue =17
	--	set @query = @query + ' and C.ChainID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'
	--else
	--	set @query = @query + ' and t.SupplierID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 9))'

	if(@SupplierId<>'-1') 
		set @Query  = @Query  + ' and t.SupplierID in (' + @SupplierId  +')'

	if(@chainID  <>'-1') 
		set @Query   = @Query  +  ' and C.ChainID in (' + @chainID +')'

	if(@Banner<>'All') 
		set @Query  = @Query + ' and S.Custom1 like ''%' + @Banner + '%'''

	if(@StoreId <>'-1') 
		set @Query   = @Query  +  ' and S.StoreIdentifier like ''%' + @StoreId + '%''' 

	if (@LastxDays > 0)
		set @Query = @Query + ' and t.OnSaleDate >=dateadd(d,-' +  cast(@LastxDays as varchar) + ',getDate()) and t.OnSaleDate <=getdate() '  
	
	if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @Query = @Query + ' and t.OnSaleDate >= ''' + @StartDate  + '''';

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @Query = @Query + ' and t.OnSaleDate <= ''' + @EndDate  + '''';
		
	set @Query = @Query + ' order by 1, 2, 3, 4, 5 desc'
	
	exec  (@Query )
	
END
GO
