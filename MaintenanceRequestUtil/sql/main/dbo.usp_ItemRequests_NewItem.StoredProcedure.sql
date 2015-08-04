USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_ItemRequests_NewItem]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_ItemRequests_NewItem]

 @SupplierId varchar(10),
 @ChainId varchar(10),
 @Banner varchar(255),
 @FromStartDate varchar(50),
 @ToStartDate varchar(50),
 @ProductIdentifierType int,
 @ProductIdentifierValue varchar(50),
 @StoreIdentifierType int,
 @StoreIdentifierValue varchar(50),
 @OtherOption int,
 @Others varchar(50),
 @DealNumber varchar(50),
 @CostZoneId varchar(50),
 @RequestStatus varchar(10)
 
as

Begin
	Declare @sqlQuery varchar(4000)
	Declare @CostFormat varchar(10)
 
	if(@supplierID<>'-1')
		Select @CostFormat = Costformat from SupplierFormat where SupplierID = @supplierID
	else
		set @CostFormat=4
		
	set @sqlQuery = 'SELECT ch.ChainName as [Chain Name], sup.SupplierName as [Supplier Name], 
						CASE WHEN AllStores = 1 THEN ''All'' ELSE ''Multiple'' END AS [All Stores], 
						mreq.Banner AS [Banner Name], CostZoneName as [Cost Zone Name], mreq.UPC, mreq.ItemDescription as [Item Description], 
						convert(date, mreq.SubmitDateTime, 101) as [Submit Date Time], 
						convert(date, mreq.StartDateTime, 101) as [Start Date Time], 
						convert(date, mreq.EndDateTime, 101) as [End Date Time], 
						cast(mreq.CurrentSetupCost as numeric(10,' + @CostFormat + ')) as [Current Setup Cost], 
						cast(mreq.Cost as numeric(10,' + @CostFormat + ')) as Cost, 
						cast(mreq.SuggestedRetail as numeric(10,2)) as [Suggested Retail]
					FROM  dbo.MaintenanceRequests AS mreq 
					INNER JOIN dbo.Suppliers AS sup ON mreq.SupplierId = sup.SupplierId 
					INNER JOIN dbo.Chains AS ch ON mreq.ChainId = ch.ChainId 
					Left Join CostZones CZ on CZ.CostZoneId = mreq.CostZoneID 
					Inner join SupplierBanners SB on SB.SupplierId = sup.SupplierId and SB.Status=''Active'' and SB.Banner=mreq.Banner
					WHERE mreq.RequestStatus<>999 and mreq.RequestTypeID=1 and mreq.Approved=1 and (mreq.MarkDeleted is null)'
				
	if(@RequestStatus ='Current')	
		set @sqlQuery = @sqlQuery +  ' and	(mreq.StartDateTime <= { fn NOW() }) AND (mreq.EndDateTime >= { fn NOW() }) '
	
	else if(@RequestStatus ='Future')	
		set @sqlQuery = @sqlQuery +  ' and	mreq.StartDateTime > { fn NOW() }  '
		
	else if(@RequestStatus ='Past')	
		set @sqlQuery = @sqlQuery +  ' and	mreq.EndDateTime < { fn NOW() } '
	
	if(@SupplierId<>'-1') 
		set @sqlQuery = @sqlQuery +  ' and mreq.SupplierId=' + @SupplierId

	if(@ChainId<>'-1') 
		set @sqlQuery = @sqlQuery +  ' and mreq.ChainId=' + @ChainId
	  
	if(@Banner='') 
		set @sqlQuery = @sqlQuery + ' and mreq.Banner is Null'

	else if(@Banner<>'-1') 
		set @sqlQuery = @sqlQuery + ' and mreq.Banner=''' + @Banner + ''''

	if (convert(date, @FromStartDate  ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and convert(varchar(10),StartDateTime,101)  >= ''' + @FromStartDate + '''';

	if (convert(date, @FromStartDate  ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and convert(varchar(10),StartDateTime,101)  <= ''' + @ToStartDate  + '''';
	
	if(@ProductIdentifierValue<>'')
		 set @sqlQuery = @sqlQuery + ' and mreq.UPC like ''%' + @ProductIdentifierValue + '%'''

	if(@DealNumber<>'-1')
		set @sqlQuery = @sqlQuery +  ' and mreq.DealNumber = ''' + @DealNumber + ''''
		
	if(@CostZoneId<>'-1')
		set @sqlQuery = @sqlQuery +  ' and mreq.CostZoneId = ''' + @CostZoneId + ''''
	
	set @sqlQuery = @sqlQuery + ' order by 1,2,3,4,5,6,7'

	exec (@sqlQuery); 

End
GO
