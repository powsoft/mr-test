USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Live_Promotions_All]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  procedure [dbo].[usp_Report_Live_Promotions_All] 
	-- exec usp_Report_Live_Promotions_All '60620','41684','Bashas','072030013398','40557','-1','0','2013-12-30','2013-12-30'
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

	select @attvalue = AttributeID  from AttributeValues with(nolock) where OwnerEntityID=@PersonID and AttributeID=17
 
	set @query = 'SELECT distinct CP.SupplierName as [Supplier Name], CP.ChainName as [Chain Name], CP.Banner, 
		       CP.[SBT Number], CP.[Store Number], CP.ProductName as [Product Name], CP.UPC, ''$''+ Convert(varchar(50),CP.Allowance) as Allowance, 
               CP.PricePriority as [Price Priority], 
               convert(varchar(10),cast(CP.[Begin Date] as date),101) as [Begin Date],
               convert(varchar(10),cast(CP.[End Date] as date),101) as [End Date],
               CZ.CostZoneName as [Cost Zone Name], 
               MR.DealNumber as [Deal Number], MR.TradingPartnerPromotionIdentifier as [Trading Partner Id #]
				FROM  CurrentPromotions CP with(nolock)
				INNER JOIN SupplierBanners SB with(nolock) on SB.SupplierId = CP.SupplierID and SB.Status=''Active'' and SB.Banner=CP.Banner
				left  join MaintenanceRequests MR with(nolock) on MR.SupplierID=CP.SupplierID
							and MR.ChainID=CP.ChainID
							and MR.Banner=CP.Banner
							and MR.UPC=CP.UPC
							and MR.RequestTypeID=3
							and MR.Approved=1
							and RequestStatus not in (999, 17, 18, 15, 16, -30, -333)
							and MR.MarkDeleted=0
							AND (MR.StartDateTime <= CONVERT(varchar(10), GETDATE(), 101)) 
							AND (MR.EndDateTime >= CONVERT(varchar(10), GETDATE(), 101)) 
				left join CostZones CZ with(nolock) on CZ.CostZoneID=MR.CostZoneID
				WHERE 1=1'

	--if @AttValue =17
	--	set @query = @query + ' and CP.ChainID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'
	--else
	--	set @query = @query + ' and CP.SupplierID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 9))'


	if(@chainID  <>'-1') 
		set @Query   = @Query  +  ' and CP.ChainID in (' + @chainID +')'

	if(@Banner<>'All') 
		set @Query  = @Query + ' and CP.banner  like ''%' + @Banner + '%'''

	if(@SupplierId<>'-1') 
		set @Query  = @Query  + ' and CP.SupplierId in (' + @SupplierId  +')'


	if(@ProductUPC  <>'-1') 
		set @Query   = @Query  +  ' and  CP.UPC like ''%' + @ProductUPC + '%'''

	if (@LastxDays > 0)
		set @Query = @Query + ' and (CP.[Begin Date] between dateadd(d,-' +  cast(@LastxDays as varchar) + ', { fn NOW() }) and { fn NOW() })'  
	
	if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @Query = @Query + ' and CP.[Begin Date] >= ''' + @StartDate  + '''';

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @Query = @Query + ' and CP.[Begin Date] <= ''' + @EndDate  + '''';
		print (@Query )
	exec (@Query )
END
GO
