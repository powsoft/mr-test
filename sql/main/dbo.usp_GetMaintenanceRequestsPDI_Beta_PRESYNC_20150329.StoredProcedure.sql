USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetMaintenanceRequestsPDI_Beta_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
exec [usp_GetMaintenanceRequestsPDI_Beta] 
		'Supplier'
		,'59973'
		,'62314'
		,''
		,'1900-01-01'
		,'1900-01-01'
		,'-1'
		,'-1'
		,'CST Brands'
		,0
		,''
		,'-1'
		,'-1'
		,'62331'
		,'-1'
		,'-1'
		,'TRUE'
		,'-1'
		,'0'
*/
CREATE procedure [dbo].[usp_GetMaintenanceRequestsPDI_Beta_PRESYNC_20150329]
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
 @CostZoneId varchar(20),
 @UserId varchar(20),
 @ProductCategoryIDLevel2 varchar(10),
 @ProductCategoryIDLevel3 varchar(10),
 @isPDIUSer varchar(5),
 @Compliance varchar(2),
 @AllRqstStatus varchar(10),
 @SupplierIdentifierValue varchar(20),
 @RetailerIdentifierValue varchar(20),
 @Bipad varchar(100),
 @OwnerMarketID varchar(100),
 @Category varchar(20)
  
as
-- exec [usp_GetMaintenanceRequestsPDI_Beta] 'Supplier','-1', '-1','','1900-01-01','1900-01-01','-1','-1','All',0,'','-1','-1',50334,'-1','-1','True','',''
Begin
 Declare @sqlQuery varchar(4000)
 
set @sqlQuery = 'SELECT mreq.[MaintenanceRequestID]
						 , mreq.SubmitDateTime
						 , mreq.RequestTypeID
						 , mreq.ChainID
						 , mreq.SupplierID
						 , mreq.ItemGroup
						 , mreq.AlternateItemGroup
						 , mreq.ItemDescription
						 , mreq.Size
						 , mreq.BrandIdentifier AS BrandId
						 , mreq.ManufacturerIdentifier AS ManufacturerId
						 , mreq.SellPkgVINAllowReorder
						 , mreq.SellPkgVINAllowReClaim
						 , mreq.PrimarySellablePkgIdentifier
						 , mreq.PrimarySellablePkgQty
						 , mreq.UPC
						 , CAST(ISNULL(mreq.SuggestedRetail,0) AS DECIMAL(10,2)) AS SuggestedRetail
						 , mreq.AllStores
						 , mreq.CostZoneID AS ZoneID
						 , mreq.VIN
						 , mreq.VINDescription
						 , mreq.PurchPackDescription
						 , mreq.PurchPackQty
						 , CAST(ISNULL(mreq.CurrentSetupCost,0) AS DECIMAL(10,2)) AS CurrentSetupCost
						 , CAST(ISNULL(mreq.Cost,0) AS DECIMAL(10,2)) AS Cost
						 , mreq.PromoTypeID
						 , '''' AS [Promo#]
						 , CAST(ISNULL(mreq.PromoAllowance,0) AS DECIMAL(10,2)) AS PromoAllowance
						 , convert(VARCHAR(10), mreq.StartDateTime, 101) AS StartDate
						 , convert(VARCHAR(10), mreq.EndDateTime, 101) AS EndDate
						 , mreq.AltSellPackage1
						 , mreq.AltSellPackage1Qty
						 , mreq.AltSellPackage1UPC
						 , mreq.AltSellPackage1Retail
						 , mreq.OldVIN
						 , mreq.OldUPC
						 , mreq.ReplaceUPC '
						 
      set @sqlQuery = @sqlQuery +'  FROM  dbo.MaintenanceRequests AS mreq with(nolock) 
									INNER JOIN MaintananceRequestsTypes Mt  with(nolock)  ON mreq.RequestTypeID=Mt.RequestType
									INNER JOIN dbo.Suppliers AS sup  with(nolock)  ON mreq.SupplierId = sup.SupplierId 
									INNER JOIN dbo.Chains AS ch with(nolock)  ON mreq.ChainId = ch.ChainId 
									Inner join SupplierBanners SB with(nolock)  on SB.SupplierId = mreq.SupplierId and SB.Status=''Active'' and SB.Banner=mreq.Banner
									Left Join DealContracts dc with(nolock)  on dc.DealNumber=mreq.DealNumber and dc.SupplierId = mreq.SupplierId 
									Left Join ProductCategories pc3 with(nolock)  on pc3.ProductCategoryID=mreq.ProductCategoryID
									left join logins lgn with(nolock) on lgn.OwnerEntityId = mreq.SupplierLoginID
									left join persons prn with(nolock) on prn.Personid = lgn.OwnerEntityID
									left join persons prnc with(nolock) on prnc.Personid = mreq.ChainLoginID '
		
		IF(@isPDIUSer='True')
		Begin
			set @sqlQuery = @sqlQuery + ' Left JOIN ProductCategories P2 with(nolock)  ON P2.ProductCategoryID=pc3.ProductCategoryParentID '
										 
		END

		if(@ShowStore='1')
		set @sqlQuery = @sqlQuery + ' Left JOIN tmpMaintenanceRequestStores MRS with(nolock)  ON MRS.MaintenanceRequestId= mreq.MaintenanceRequestId'

		if(@AllRqstStatus <> '1')
			Begin
			  set @sqlQuery = @sqlQuery + ' WHERE mreq.RequestStatus not in (999, 17, 18, 15, 16, -30, -333)'
			end
		else
			Begin
			  set @sqlQuery = @sqlQuery + ' WHERE mreq.RequestStatus in (999, 17, 18, 15, 16, -30, -333)'
			end 

		 
		if(@ChainId<>'-1') 
		 set @sqlQuery = @sqlQuery +  ' and mreq.ChainId=' + @ChainId

		if(@SupplierId<>'-1') 
		 set @sqlQuery = @sqlQuery +  ' and mreq.SupplierId=' + @SupplierId

		if(@CostZoneId<>'-1') 
		 set @sqlQuery = @sqlQuery +  ' and mreq.CostZoneId=' + @CostZoneId
		 
		if(@UPC<>'') 
		 set @sqlQuery = @sqlQuery + ' and mreq.UPC like ''%' + @UPC + '%''';
		 
		if(@Bipad<>'') 
		 set @sqlQuery = @sqlQuery + ' and mreq.Bipad like ''%' + @Bipad + '%''';
		 
		--if(@OwnerMarketID <> '') 
		-- set @sqlQuery = @sqlQuery + ' and mreq.OwnerMarketID like ''%' + @OwnerMarketID + '%'''; 
		
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

		else if(@Status <> -1) 
		 set @sqlQuery = @sqlQuery +  ' and (MarkDeleted is null or MarkDeleted=0)' 
		 
		if(@BannerName<>'All' and @BannerName<>'') 
		 set @sqlQuery = @sqlQuery +  ' and mreq.Banner=''' + @BannerName + ''''

		if(@DealNumber<>'-1')
		 set @sqlQuery = @sqlQuery +  ' and mreq.DealNumber = ''' + @DealNumber + ''''
		 
		if(@SupplierIdentifierValue<>'')
			set @sqlQuery = @sqlQuery + ' and sup.SupplierIdentifier like ''%' + @SupplierIdentifierValue + '%'''
				
		if(@RetailerIdentifierValue<>'')
			set @sqlQuery = @sqlQuery + ' and ch.ChainIdentifier like ''%' + @RetailerIdentifierValue + '%'''
			
		if(@Category='1')
				set @sqlQuery = @sqlQuery +  ' and (isnull(mreq.Bipad,'''') <> '''')'
		else if(@Category='2')
				set @sqlQuery = @sqlQuery +  ' and (isnull(mreq.Bipad,'''') = '''')'	

		--Special case for Gopher
		set @sqlQuery = @sqlQuery +  ' and mreq.MaintenanceRequestID not in (Select MaintenanceRequestID from MaintenanceRequests where SupplierID=40558 and  SkipPopulating879_889Records = 0 and Approved is null)'

		 print @sqlQuery
		exec (@sqlQuery); 

End
GO
