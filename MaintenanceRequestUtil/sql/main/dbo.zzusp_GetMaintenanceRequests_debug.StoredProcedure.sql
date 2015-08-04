USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[zzusp_GetMaintenanceRequests_debug]    Script Date: 06/25/2015 18:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[zzusp_GetMaintenanceRequests_debug]
 @AccessLevel varchar(20),
 @ChainId varchar(10),
 @SupplierId varchar(10),
 @UPC varchar(100),
 @FromDate varchar(15),
 @ToDate varchar(15),
 @RequestTypeId varchar(2),
 @Status varchar(50),
 @BannerName varchar(250),
 @ShowStore varchar(1),
 @StoreNumber varchar(20),
 @DealNumber varchar(50),
 @CostZoneId varchar(20)
as

/*
[dbo].[zzusp_GetMaintenanceRequests_debug] '', '40393', '40559', '072554822575', '1900-01-01', '1900-01-01', '-1', '1', 'All', '', '', '-1', '-1'
update MaintenanceRequests set approved = 0 where maintenancerequestid = 199296
*/
Begin
 Declare @sqlQuery varchar(4000)
 
set @sqlQuery = 'Select mreq.MaintenanceRequestID,mreq.SubmitDateTime,mreq.RequestTypeID ,mreq.ChainID
       ,mreq.SupplierID,mreq.Banner,mreq.AllStores,mreq.UPC
       ,mreq.BrandIdentifier,mreq.ItemDescription,mreq.CurrentSetupCost,mreq.Cost
       ,mreq.SuggestedRetail,mreq.PromoTypeID,mreq.PromoAllowance
       ,Convert(varchar(10),mreq.StartDateTime,101) as StartDateTime 
       ,Convert(varchar(10),mreq.EndDateTime,101) as EndDateTime
       ,mreq.SupplierLoginID,mreq.ChainLoginID,mreq.Approved
       ,mreq.ApprovalDateTime,mreq.DenialReason,mreq.EmailGeneratedToSupplier
       ,mreq.EmailGeneratedToSupplierDateTime,mreq.RequestStatus
       ,mreq.CostZoneID ,mreq.productid ,mreq.brandid ,mreq.upc12
       ,mreq.datatrue_edi_costs_recordid,mreq.datatrue_edi_promotions_recordid
       ,mreq.dtstorecontexttypeid ,mreq.TradingPartnerPromotionIdentifier
       ,mreq.MarkDeleted,mreq.DeleteLoginId,mreq.DeleteDateTime,mreq.datetimecreated
       ,mreq.SkipPopulating879_889Records,mreq.Skip_879_889_Conversion_ProcessCompleted
       ,mreq.dtproductdescription ,mreq.DealNumber ,mreq.FromWebInterface,mreq.SlottingFees
       ,mreq.AdFees
  from MaintenanceRequests mreq 
  Inner join SupplierBanners SB on SB.SupplierId = mreq.SupplierId and SB.Status=''Active'' and SB.Banner=mreq.Banner 
    WHERE mreq.RequestStatus<>999 '
 
if(@ChainId<>'-1') 
 set @sqlQuery = @sqlQuery +  ' and mreq.ChainId=' + @ChainId

if(@SupplierId<>'-1') 
 set @sqlQuery = @sqlQuery +  ' and mreq.SupplierId=' + @SupplierId

if(@CostZoneId<>'-1') 
 set @sqlQuery = @sqlQuery +  ' and mreq.CostZoneId=' + @CostZoneId
 
if(@UPC<>'') 
 set @sqlQuery = @sqlQuery + ' and mreq.UPC like ''%' + @UPC + '%''';
 
if(@FromDate<>'1900-01-01') 
 set @sqlQuery = @sqlQuery + ' and StartDateTime  >= ''' + @FromDate + '''';

if(@ToDate<>'1900-01-01') 
 set @sqlQuery = @sqlQuery + ' and StartDateTime  <= ''' + @ToDate  + '''';

if (@RequestTypeId <> '-1')
 set @sqlQuery = @sqlQuery +  ' and mreq.RequestTypeID=' + @RequestTypeId

if(@Status = 1) 
Begin
 set @sqlQuery = @sqlQuery +  ' and mreq.Approved is Null '
End

if(@Status = 2) 
 set @sqlQuery = @sqlQuery +  ' and mreq.Approved = 1 and mreq.requeststatus in (0, 5)'

if(@Status = 3) 
 set @sqlQuery = @sqlQuery +  ' and mreq.Approved = 0'

if(@Status = 4) 
 set @sqlQuery = @sqlQuery +  ' and mreq.MarkDeleted = 1'

else if(@Status != -1) 
 set @sqlQuery = @sqlQuery +  ' and (MarkDeleted is null or MarkDeleted=0)' 
 
if(@BannerName<>'All' and @BannerName<>'') 
 set @sqlQuery = @sqlQuery +  ' and mreq.Banner=''' + @BannerName + ''''

if(@DealNumber<>'-1')
 set @sqlQuery = @sqlQuery +  ' and mreq.DealNumber = ''' + @DealNumber + ''''

--Special case for Gopher
set @sqlQuery = @sqlQuery +  ' and mreq.MaintenanceRequestID not in (Select MaintenanceRequestID from MaintenanceRequests where SupplierID=40558 and  SkipPopulating879_889Records = 0 and Approved is null)'
 
exec (@sqlQuery); 

End
GO
