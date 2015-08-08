USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Future_Promotions_All]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  procedure  [dbo].[usp_Report_Future_Promotions_All] 
	-- exec usp_Report_Future_Promotions_All '40393','40741','All','-1','40567','-1','0','1900-01-01','1900-01-01'
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
		SET @sqlCommand = 'SELECT @cnt=Max(Costformat) FROM SupplierFormat where SupplierID in ('+ @supplierID+' )'
		EXECUTE sp_executesql @sqlCommand, N'@cnt int OUTPUT',   @cnt=@CostFormat OUTPUT
		End
	 else
		set @CostFormat=4
		set @CostFormat = ISNULL(@CostFormat , 4)
	select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17

	set @query = 'SELECT   CP.ChainName as Retailer, CP.Banner, CP.SupplierName as [Supplier Name], CP.ProductName as Product, 
                CP.[Store Number], CP.[SBT Number], CP.UPC, 
                ''$''+ Convert(varchar(50), cast(CP.Allowance as numeric(10,' + @CostFormat + '))) as [Promo],  
			    convert(varchar(10),cast(CP.[Begin Date] as date),101) as [Begin Date], 
			    convert(varchar(10),cast(CP.[End Date] as date),101) as [End Date], 
			    ''$''+ Convert(varchar(50), cast(PP.UnitPrice as numeric(10,' + @CostFormat + '))) AS [Base Cost], 
				''$''+ Convert(varchar(50), cast(PP.UnitRetail as numeric(10,2))) AS [Base Retail], 
				convert(varchar(10),cast(PP.ActiveStartDate as date),101) as [Base Begin], 
                convert(varchar(10),cast(PP.ActiveLastDate as date),101) as [Base End],
				CZ.CostZoneName as [Cost Zone Name], MR.DealNumber as [Deal Number],
				MR.TradingPartnerPromotionIdentifier as [Trading Partner Id #]
				FROM  CurrentPromotions_Future  CP  WITH(NOLOCK) 
				INNER JOIN Productprices PP WITH(NOLOCK)  ON CP.StoreID = PP.StoreID AND CP.SupplierID = PP.SupplierID 
							AND  CP.BrandID = PP.BrandID AND CP.ProductID = PP.ProductID
				inner join SupplierBanners SB WITH(NOLOCK)  on SB.SupplierId = CP.SupplierId and SB.Status=''Active'' and SB.Banner=CP.Banner
				left  join MaintenanceRequests MR WITH(NOLOCK)  on MR.SupplierID=CP.SupplierID
							and MR.ChainID=CP.ChainID
							and MR.Banner=CP.Banner
							and MR.UPC=CP.UPC
							and MR.RequestTypeID=3
							and MR.Approved=1
							and RequestStatus not in (999, 17, 18, 15, 16, -30, -333)
							and MR.MarkDeleted=0
							AND (MR.StartDateTime <= CONVERT(varchar(10), GETDATE(), 101)) 
							AND (MR.EndDateTime >= CONVERT(varchar(10), GETDATE(), 101)) 
				left join CostZones CZ on CZ.CostZoneID=MR.CostZoneID							
				WHERE (PP.ProductPriceTypeID = 3) 
					AND (PP.ActiveStartDate <= { fn NOW() }) 
					AND (PP.ActiveLastDate >= { fn NOW() }) '
 
	--if @AttValue =17
	--	set @query = @query + ' and CP.ChainID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'
	--else
	--	set @query = @query + ' and CP.SupplierID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 9))'

	if(@chainID  <>'-1') 
		set @Query = @Query  +  ' and CP.ChainID in (' + @chainID +')'

	if(@Banner<>'All') 
		set @Query  = @Query + ' and CP.banner like ''%' + @Banner + '%'''

	if(@SupplierId<>'-1') 
		set @Query  = @Query  + ' and CP.SupplierId in (' + @SupplierId  +')'

	if(@ProductUPC  <>'-1') 
		set @Query   = @Query  +  ' and  CP.UPC like ''%' + @ProductUPC + '%'''

	if (@LastxDays > 0)
		set @Query = @Query + ' and (CP.[Begin Date] between { fn NOW() } and dateadd(d,' +  cast(@LastxDays as varchar) + ', { fn NOW() }) )'  
	
	if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @Query = @Query + ' and CP.[Begin Date] >= ''' + @StartDate  + '''';

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @Query = @Query + ' and CP.[Begin Date] <= ''' + @EndDate  + '''';
 
 print 	(@Query )
	exec (@Query )
	
END
GO
