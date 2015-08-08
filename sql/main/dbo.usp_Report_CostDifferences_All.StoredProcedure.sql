USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_CostDifferences_All]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================


CREATE  procedure [dbo].[usp_Report_CostDifferences_All] 
 --exec usp_Report_CostDifferences_All '-1','62966','All','-1','-1','','4','1900-01-01','1900-01-01'
	-- exec usp_Report_CostDifferences_All '40393,44199','40384','All','-1','40558,41440,44246','-1','0','05/01/2013','05/31/2013'
		-- exec usp_Report_CostDifferences_All '60620','41684','All','-1','40567','-1','0','03/16/2015','03/16/2015'
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
Declare @CostFormat varchar(10)

	if(@supplierID<>'-1')
		Begin
		DECLARE @sqlCommand nvarchar(max)
		declare @counts int
		SET @sqlCommand = 'SELECT @cnt=Max(Costformat) FROM SupplierFormat  with (nolock)   where SupplierID in ('+ @supplierID+' )'
		--print(@sqlCommand)
		EXECUTE sp_executesql @sqlCommand, N'@cnt int OUTPUT',   @cnt=@CostFormat OUTPUT
		End
	 else
		set @CostFormat=4
	set @CostFormat = isnull(@costformat,4)	
	select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
 
	set @Query ='
					SELECT DISTINCT T.ChainName as [Chain Name], T.Banner, T.SupplierName as [Supplier Name], B.BrandName as Brand, T.ProductName as [Product Name], 
					T.UPC, PD.IdentifierValue as [Supplier Product Code], T.Qty, 
					''$''+ Convert(varchar(50),cast(T.[Setup Cost] as numeric(10,' + @CostFormat + '))) as [Supplier Cost], 
					''$''+ Convert(varchar(50),cast(T.[setup Promo] as numeric(10,' + @CostFormat + '))) as [Supplier Promo], 
					''$''+ Convert(varchar(50),cast(T.[Setup Net] as numeric(10,' + @CostFormat + '))) as [Supplier Net], 
					''$''+ Convert(varchar(50),cast(T.[Reported Cost] as numeric(10,' + @CostFormat + '))) as [Retailer Cost], 
					''$''+ Convert(varchar(50),cast(T.[Reported Promo] as numeric(10,' + @CostFormat + '))) as [Retailer Promo], 
					''$''+ Convert(varchar(50),cast(T.RetailerNet as numeric(10,' + @CostFormat + '))) as [Retailer Net], 
					convert(varchar(10),Cast(T.SaleDate as date),101) as [Transaction Date],
					T.RouteNumber as [Route Number], T.DriverName as [Driver Name], 
					T.SuppAccountNo as [Supplier Account No], T.SBTNumber as [SBT Number], T.CostZoneName as [Cost Zone], 
					T.SupplierID as [Supplier ID #]
					FROM  DataTrue_CustomResultSets.dbo.tmpCostDifferences T  with (nolock)  
					INNER JOIN ProductBrandAssignments PB with (nolock)   on PB.ProductID=T.ProductID 
					INNER JOIN Brands B  with (nolock)   ON PB.BrandID = B.BrandID 
					Left JOIN    ProductIdentifiers PD  with (nolock)  ON T.ProductID = PD.ProductID AND PD.ProductIdentifierTypeID =3 and PD.OwnerEntityId=T.SupplierId 
					WHERE  1 =1  and ISNULL(JobRunningID,'''') <> 3 '

	if(@SupplierId<>'-1') 
		set @Query  = @Query  + ' and T.SupplierId in (' + @SupplierId +')'
	  
	if(@chainID  <>'-1') 
		set @Query   = @Query  +  ' and T.ChainID in (' + @chainID +')'

	if(@Banner<>'All') 
		set @Query  = @Query + ' and T.banner like ''%' + @Banner + '%'''

	if(@ProductUPC  <>'-1') 
		set @Query   = @Query  +  ' and  T.UPC  like ''%' + @ProductUPC + '%'''

	if (@LastxDays > 0)
		set @Query = @Query + ' and cast(T.SaleDate as date) >= cast(dateadd(d,-' +  cast(@LastxDays as varchar) + ', cast(getdate() as date)) as date) and T.SaleDate  <= getdate() '  
	
	if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @Query = @Query + ' and T.SaleDate >= cast(''' + @StartDate  + ''' as date)';

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @Query = @Query + ' and T.SaleDate <= cast(''' + @EndDate  + ''' as date)';
		
	exec (@Query )
  PRINT (@QUERY)
END
GO
