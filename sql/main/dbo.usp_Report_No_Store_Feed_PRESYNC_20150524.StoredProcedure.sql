USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_No_Store_Feed_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE procedure [dbo].[usp_Report_No_Store_Feed_PRESYNC_20150524] 
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

	begin try
        Drop Table [@tmpNoFeed]
    end try
    begin catch
    end catch
    
	Declare @Query varchar(5000)
	declare @AttValue int

	select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
	
	set @query = '	Select distinct SP.SupplierName as [Supplier Name], C.ChainName as [Chain Name],  t.Banner, s.StoreIdentifier as [Store Number], 
					convert(varchar(10), t.OnSaleDate, 101)  as [On Sale Date Not Received], t.TransactionType as [Transaction Type Not Received]
					from DataTrue_CustomResultSets.dbo.tmpNoStoreFeed t 
					inner join Chains C on C.ChainId=t.ChainId
					inner join datatrue_report.dbo.Suppliers SP on SP.SupplierId=t.SupplierId
					inner join Stores S on S.StoreID=t.StoreId and S.ChainID=t.ChainId and S.Custom1=t.Banner
					INNER JOIN SupplierBanners SB on SB.SupplierId = SP.SupplierID and SB.Status=''Active'' and SB.Banner=t.Banner
					where 1=1 '

	if @AttValue =17
		set @query = @query + ' and C.ChainID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'
	else
		set @query = @query + ' and t.SupplierID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 9))'

	if(@SupplierId<>'-1') 
		set @Query  = @Query  + ' and t.SupplierID=' + @SupplierId  

	if(@chainID  <>'-1') 
		set @Query   = @Query  +  ' and C.ChainID=' + @chainID 

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


--exec [usp_Report_No_Store_Feed] 40393, 40384,'All', 'All', 40570, '-1', 4
GO
