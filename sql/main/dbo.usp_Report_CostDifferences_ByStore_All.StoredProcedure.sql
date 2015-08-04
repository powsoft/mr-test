USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_CostDifferences_ByStore_All]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  procedure [dbo].[usp_Report_CostDifferences_ByStore_All] 
	-- [usp_Report_CostDifferences_ByStore_All] '-1','2','All','','-1','-1','0','1900-01-01','1900-01-01'
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
 
Declare @AccessLevel varchar(20)
Declare @AccessValue varchar(20)

	select @AccessLevel=AttributeName, @AccessValue=AttributeValue
	from AttributeDefinitions d
	inner join AttributeValues v on d.AttributeID = v.AttributeID
	where OwnerEntityID = @PersonId and v.IsActive = 1 and d.AttributeID IN(9,17,23)
			
	if(@AccessLevel ='ChainAccess') 		
		Begin	
			if(@chainID<>'-1') 
				Set @chainID =@chainID --+ ',' +@AccessValue
			else
				Set @chainID =@AccessValue
		End
	else if(@AccessLevel ='SupplierAccess') 	
		Begin
			if(@SupplierId<>'-1') 
				Set @SupplierId = @SupplierId --+ ',' +@AccessValue
			else
				Set @SupplierId=@AccessValue
		End
		
	
 if(@supplierID<>'-1')
		Begin
		DECLARE @sqlCommand nvarchar(max)
		declare @counts int
		SET @sqlCommand = 'SELECT @cnt=Max(Costformat) FROM SupplierFormat where SupplierID in ('+ @supplierID+' )'
		EXECUTE sp_executesql @sqlCommand, N'@cnt int OUTPUT',   @cnt=@CostFormat OUTPUT
		End
 else
	set @CostFormat=4
 set @CostFormat = isnull(@costformat,4)		
 select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
 
 set @Query =' SELECT   DISTINCT  T.ChainName as [Chain Name]
						, T.[Store Number] as [Store Number]
						, T.Banner AS Banner
						, T.SupplierName as [Supplier Name]
						, B.BrandName as Brand
						, T.ProductName as [Product Name]
						, T.UPC AS UPC
						, PD.IdentifierValue as [Supplier Product Code]
						, T.Qty AS Qty
						, ''$'' + Convert(varchar(50),cast(T.[Setup Cost] as numeric(10,' + @CostFormat + '))) as [Setup Cost] 
						, ''$'' + Convert(varchar(50),cast(T.[setup Promo] as numeric(10,' + @CostFormat + '))) as [Setup Promo]
						, ''$'' + Convert(varchar(50),cast(T.[Setup Net] as numeric(10,' + @CostFormat + '))) as [Setup Net]
						, ''$'' + Convert(varchar(50),cast(T.[Reported Cost] as numeric(10,' + @CostFormat + '))) as [Reported Cost]
						, ''$'' + Convert(varchar(50),cast(T.[Reported Promo] as numeric(10,' + @CostFormat + '))) as [Reported Promo]
						, ''$'' + Convert(varchar(50),cast(T.RetailerNet as numeric(10,' + @CostFormat + '))) as [Retailer Net]
						, convert(varchar(10),CAST(T.SaleDate as date),101) AS [Sale Date]
						, isnull(T.RouteNumber,'''') as [Route Number]
						, isnull(T.DriverName,'''') as [Driver Name]
						, isnull(T.SuppAccountNo,'''') as [Supplier Account No]
						, isnull(T.SBTNumber,'''') as [SBT Number], isnull(T.CostZoneName,'''') as [Cost Zone] 
						, T.SupplierID as [Supplier ID #]
		FROM  DataTrue_CustomResultSets.dbo.tmpCostDifferencesByStore T
					INNER JOIN ProductBrandAssignments PB on PB.ProductID=T.ProductID 
					INNER JOIN Brands B ON PB.BrandID = B.BrandID 
					Left JOIN    ProductIdentifiers PD ON T.ProductID = PD.ProductID AND PD.ProductIdentifierTypeID =3 and PD.OwnerEntityId=T.SupplierId 
					where 1=1 and ISNULL(JobRunningID,'''') <> 3   '
		
		if(@SupplierId<>'-1') 
			set @Query  = @Query  + ' and T.SupplierId in (' + @SupplierId +')'
		     
		if(@chainID  <>'-1') 
			set @Query   = @Query  +  ' and T.ChainID in (' + @chainID +')'

		if(@Banner<>'All') 
			set @Query  = @Query + ' and T.Banner like ''%' + @Banner + '%'''

		if(@StoreId <>'-1') 
			set @Query   = @Query  +  ' and T.[Store number] like ''%' + @StoreId + '%'''

		if(@ProductUPC  <>'-1') 
			set @Query   = @Query  +  ' and T.UPC like ''%' + @ProductUPC + '%'''

		if (@LastxDays > 0)
			set @Query = @Query + ' and cast(T.SaleDate as date) >= cast(dateadd(d,-' +  cast(@LastxDays as varchar) + ', cast(getdate() as date)) as date) and T.SaleDate  <= getdate() '  
	
		if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
			set @Query = @Query + ' and T.SaleDate >= cast(''' + @StartDate  + ''' as date)';

		if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
			set @Query = @Query + ' and T.SaleDate <= cast(''' + @EndDate  + ''' as date)';
			
		print(@Query )	
		exec  (@Query )
END
GO
