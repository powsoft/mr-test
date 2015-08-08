USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Zero_POS_Authorized_Items_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================

-- exec [usp_Report_Zero_POS_Authorized_Items] '40393','2','All','-1','-1','-1','5','1900-01-01','1900-01-01'
CREATE procedure [dbo].[usp_Report_Zero_POS_Authorized_Items_PRESYNC_20150524] 
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
	set @query = '	Select  Z.[Chain Name], Z.[Supplier Name], Z.Banner, Z.[Store Number], Z.UPC, Z.ProductName as [Item Description],
						''$''+ Convert(varchar(50), Z.[Default Cost]) as [Default Cost], ''$''+ Convert(varchar(50),Z.Allowance) as Allowance,
						dbo.FDatetime(Z.[Promo Start Date]) as [Promo Start Date], 
						dbo.FDatetime(Z.[Promo End Date]) as [Promo End Date], 
						dbo.FDatetime(Z.[Transaction Date]) as [Transaction Date],
						Z.[Supplier Acct Number], Z.[Driver Name], Z.[Route Number]
					from DataTrue_CustomResultSets.dbo.tmpZeroPOSException Z 
					Inner join SupplierBanners SB on SB.SupplierId = Z.SupplierID and SB.Status=''Active'' and SB.Banner=Z.Banner
					Where 1=1 '

	if @AttValue =17
		set @query = @query + ' and Z.ChainID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'
	else
		set @query = @query + ' and Z.SupplierID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 9))'

	if(@SupplierId<>'-1') 
		set @Query  = @Query  + ' and Z.SupplierID=' + @SupplierId  

	if(@chainID  <>'-1') 
		set @Query   = @Query  +  ' and Z.ChainID=' + @chainID 

	if(@Banner<>'All') 
		set @Query  = @Query + ' and Z.Banner like ''%' + @Banner + '%'''
	
	if(@ProductUPC<>'-1') 
		set @Query  = @Query + ' and Z.UPC like ''%' + @ProductUPC + '%'''	

	if(@StoreId <>'-1') 
		set @Query   = @Query  +  ' and Z.[Store Number] like ''%' + @StoreId + '%''' 

	if (@LastxDays > 0)
		set @Query = @Query + ' and Z.[Transaction Date] >=dateadd(d,-' +  cast(@LastxDays as varchar) + ',getDate()) and Z.[Transaction Date] <=getdate() '  
	
	if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @Query = @Query + ' and Z.[Transaction Date] >= ''' + @StartDate  + '''';

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @Query = @Query + ' and Z.[Transaction Date] <= ''' + @EndDate  + '''';
		
	set @Query = @Query + ' order by 1, 2, 3, 4, 5 desc'
	
	exec  (@Query )
	
END
GO
