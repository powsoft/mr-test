USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_NewItem_Past]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_NewItem_Past]

 @ChainId varchar(10),
 @SupplierId varchar(10),
 @UPC varchar(100),
 @FromDate varchar(15),
 @ToDate varchar(15),
 @BannerName varchar(250),
 @DealNumber varchar(50),
 @CostZoneId varchar(20)
as

Begin
 Declare @sqlQuery varchar(4000)
 Declare @CostFormat varchar(10)
 
 if(@supplierID<>'-1')
	Select @CostFormat = Costformat from SupplierFormat where SupplierID = @supplierID
 else
	set @CostFormat=4
	
set @sqlQuery = 'SELECT ch.ChainName, sup.SupplierName, 

					CASE WHEN AllStores = 1 THEN ''All'' 
					ELSE ''Multiple'' END AS AllStores, 
					mreq.Banner AS BannerName, CostZoneName,
					mreq.UPC, mreq.ItemDescription, 
					convert(date, mreq.SubmitDateTime, 101) as SubmitDateTime, 
					convert(date, mreq.StartDateTime, 101) as StartDateTime, 
					convert(date, mreq.EndDateTime, 101) as EndDateTime, 
					cast(mreq.CurrentSetupCost as numeric(10,' + @CostFormat + ')) as CurrentSetupCost, 
					cast(mreq.Cost as numeric(10,' + @CostFormat + ')) as Cost, 
					cast(mreq.SuggestedRetail as numeric(10,2)) as SuggestedRetail
				FROM  dbo.MaintenanceRequests AS mreq 
				INNER JOIN dbo.Suppliers AS sup ON mreq.SupplierId = sup.SupplierId 
				INNER JOIN dbo.Chains AS ch ON mreq.ChainId = ch.ChainId 
				Left Join CostZones CZ on CZ.CostZoneId = mreq.CostZoneID 
				Inner join SupplierBanners SB on SB.SupplierId = sup.SupplierId and SB.Status=''Active'' and SB.Banner=mreq.Banner
				WHERE mreq.RequestStatus<>999 and mreq.RequestTypeID=1 and 
				mreq.EndDateTime < { fn NOW() } '
 
if(@ChainId<>'-1') 
	set @sqlQuery = @sqlQuery +  ' and mreq.ChainId=' + @ChainId

if(@SupplierId<>'-1') 
	set @sqlQuery = @sqlQuery +  ' and mreq.SupplierId=' + @SupplierId

if(@CostZoneId<>'-1') 
	set @sqlQuery = @sqlQuery +  ' and mreq.CostZoneId=' + @CostZoneId
 
if(@UPC<>'') 
	set @sqlQuery = @sqlQuery + ' and UPC like ''%' + @UPC + '%''';
 
if(@FromDate<>'1900-01-01') 
	set @sqlQuery = @sqlQuery + ' and convert(varchar(10),StartDateTime,101)  >= ''' + @FromDate + '''';

if(@ToDate<>'2025-01-01') 
	set @sqlQuery = @sqlQuery + ' and convert(varchar(10),EndDateTime,101)  <= ''' + @ToDate  + '''';

if(@BannerName<>'-1') 
	set @sqlQuery = @sqlQuery +  ' and mreq.Banner=''' + @BannerName + ''''

if(@DealNumber<>'-1')
	set @sqlQuery = @sqlQuery +  ' and mreq.DealNumber = ''' + @DealNumber + ''''

exec (@sqlQuery); 

End
GO
