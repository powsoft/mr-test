USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequests_PDI_NetCostOnly_Create_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequests_PDI_NetCostOnly_Create_PRESYNC_20150329]
as

declare @rec cursor
declare @rec2 cursor
declare @singlestoreidincontext int
declare @MaintenanceRequestID int
declare @ChainID int
declare @SupplierID int
declare @Banner varchar(100)
declare @AllStores smallint
declare @Cost money
declare @SuggestedRetail money
declare @StartDateTime datetime
declare @EndDateTime datetime
declare @CostZoneID int
declare @productid int
declare @brandid int
declare @upc12  varchar(100)
declare @dtstorecontexttypeid int
declare @VIN varchar(100)
declare @promoamount money
declare @promostartdate datetime
declare @promoenddate datetime
declare @productpricetypeid tinyint
declare @supplierpackageid int


select top 1 * into #MR_temp from MaintenanceRequests

truncate table #MR_temp

set @rec = CURSOR local fast_forward FOR
SELECT [MaintenanceRequestID]
      ,[ChainID]
      ,[SupplierID]
      ,[Banner]
      ,[AllStores]
      ,[Cost]
      ,[SuggestedRetail]
      ,[StartDateTime]
      ,[EndDateTime]
      ,[CostZoneID]
      ,[productid]
      ,[brandid]
      ,[upc12]
      ,[dtstorecontexttypeid]
      ,[VIN]
  FROM [DataTrue_Main].[dbo].[MaintenanceRequests]
	where RequestTypeID = 2
	and PDIParticipant = 1
	and RequestStatus in (0, 1, 2)
	and SkipPopulating879_889Records = 1
	and Skip_879_889_Conversion_ProcessCompleted is null
	and ISNULL(approved, 0) = 1

open @rec

fetch next from @rec into @MaintenanceRequestID,@ChainID,@SupplierID,@Banner,@AllStores,@Cost,@SuggestedRetail,@StartDateTime
							,@EndDateTime,@CostZoneID,@productid,@brandid,@upc12,@dtstorecontexttypeid,@VIN

while @@FETCH_STATUS = 0
	begin
	
		set @singlestoreidincontext = null
		
		--get single store context
		if @dtstorecontexttypeid = 2
			begin
			
				select @singlestoreidincontext = storeid
				from ProductPrices 
				where StoreID in 
				(select StoreID from stores where Custom1 = '@Banner')
			
			end

		if @dtstorecontexttypeid = 3
			begin
				if @CostZoneID = 0
					begin
						select @singlestoreidincontext = storeid
						from ProductPrices 
						where StoreID in 
						(select StoreID from stores where ChainID = @ChainID)					
					end
				else
					begin
						select @singlestoreidincontext = storeid
						from ProductPrices 
						where StoreID in 
						(select StoreID from CostZoneRelations where CostZoneID = @CostZoneID)	
					end		
			
			end
			
		--Look for promotions
		
		set @supplierpackageid = null
		
		select @supplierpackageid = supplierpackageid 
		from SupplierPackages
		where ProductID = @productid
		and VIN = @VIN
		and OwnerEntityID = @ChainID
		and SupplierID = @SupplierID
		
		select UnitPrice, ActiveStartDate, ActiveLastDate
		into #Promos_temp --select *
		from ProductPrices
		where StoreID = @singlestoreidincontext
		and ProductID = @productid
		and SupplierID = @SupplierID
						and ProductPriceTypeID = 8
						and SupplierPackageID = @supplierpackageid
						and (( ActiveStartDate <= @StartDateTime and ActiveLastDate >= @StartDateTime) 
							or ( ActiveStartDate <= @EndDateTime and ActiveLastDate >= @EndDateTime) 
							or ( ActiveStartDate <= @StartDateTime and ActiveLastDate >= @EndDateTime) 
							or ( ActiveStartDate >= @StartDateTime and ActiveLastDate <= @EndDateTime))

		If @@ROWCOUNT > 1
			begin
				set @rec2 = CURSOR local fast_forward FOR
				select UnitPrice, ActiveStartDate, ActiveLastDate
				from #Promos_temp
				
				open @rec2
				
				fetch next from @rec2 into @promoamount,@promostartdate,@promoenddate
				
				while @@fetch_status = 0
					begin
						INSERT INTO [DataTrue_Main].[dbo].[MaintenanceRequests]
								   ([SubmitDateTime]
								   ,[RequestTypeID]
								   ,[ChainID]
								   ,[SupplierID]
								   ,[Banner]
								   ,[AllStores]
								   ,[UPC]
								   ,[BrandIdentifier]
								   ,[ItemDescription]
								   ,[CurrentSetupCost]
								   ,[Cost]
								   ,[SuggestedRetail]
								   ,[PromoTypeID]
								   ,[PromoAllowance]
								   ,[StartDateTime]
								   ,[EndDateTime]
								   ,[SupplierLoginID]
								   ,[ChainLoginID]
								   ,[Approved]
								   ,[ApprovalDateTime]
								   ,[DenialReason]
								   ,[EmailGeneratedToSupplier]
								   ,[EmailGeneratedToSupplierDateTime]
								   ,[RequestStatus]
								   ,[CostZoneID]
								   ,[productid]
								   ,[brandid]
								   ,[upc12]
								   ,[datatrue_edi_costs_recordid]
								   ,[datatrue_edi_promotions_recordid]
								   ,[dtstorecontexttypeid]
								   ,[TradingPartnerPromotionIdentifier]
								   ,[MarkDeleted]
								   ,[DeleteLoginId]
								   ,[DeleteReason]
								   ,[DeleteDateTime]
								   ,[datetimecreated]
								   ,[SkipPopulating879_889Records]
								   ,[Skip_879_889_Conversion_ProcessCompleted]
								   ,[dtproductdescription]
								   ,[DealNumber]
								   ,[CorrectedProductID]
								   ,[FromWebInterface]
								   ,[SlottingFees]
								   ,[AdFees]
								   ,[Bipad]
								   ,[RequestSource]
								   ,[RawProductIdentifier]
								   ,[PDIParticipant]
								   ,[OldUPC]
								   ,[OldUPCDescription]
								   ,[PrimaryGroupLevel]
								   ,[AlternateGroupLevel]
								   ,[ItemGroup]
								   ,[AlternateItemGroup]
								   ,[Size]
								   ,[ManufacturerIdentifier]
								   ,[SellPkgVINAllowReorder]
								   ,[SellPkgVINAllowReClaim]
								   ,[PrimarySellablePkgIdentifier]
								   ,[PrimarySellablePkgQty]
								   ,[VIN]
								   ,[VINDescription]
								   ,[PurchPackDescription]
								   ,[PurchPackQty]
								   ,[AltSellPackage1]
								   ,[AltSellPackage1Qty]
								   ,[AltSellPackage1UPC]
								   ,[AltSellPackage1Retail]
								   ,[ProductCategoryId]
								   ,[OldVIN]
								   ,[OldVINDescription]
								   ,[InCompliance]
								   ,[ReplaceUPC]
								   ,[QtyOne]
								   ,[QtyTwo]
								   ,[QtyThree]
								   ,[QtyFour]
								   ,[QtyFive]
								   ,[QtySix]
								   ,[QtySeven]
								   ,[SupplierIdentifier]
								   ,[StoreIdentifier]
								   ,[ChainIdentifier]
								   ,[ProductIdentifierType])
						SELECT [SubmitDateTime]
							  ,[RequestTypeID]
							  ,[ChainID]
							  ,[SupplierID]
							  ,[Banner]
							  ,[AllStores]
							  ,[UPC]
							  ,[BrandIdentifier]
							  ,[ItemDescription]
							  ,[CurrentSetupCost]
							  ,[Cost] - @promoamount
							  ,[SuggestedRetail]
							  ,[PromoTypeID]
							  ,[PromoAllowance]
							  ,@promostartdate --[StartDateTime] 
							  ,@promoenddate --[EndDateTime]
							  ,[SupplierLoginID]
							  ,[ChainLoginID]
							  ,[Approved]
							  ,[ApprovalDateTime]
							  ,[DenialReason]
							  ,[EmailGeneratedToSupplier]
							  ,[EmailGeneratedToSupplierDateTime]
							  ,17 --[RequestStatus]
							  ,[CostZoneID]
							  ,[productid]
							  ,[brandid]
							  ,[upc12]
							  ,null --[datatrue_edi_costs_recordid]
							  ,null --[datatrue_edi_promotions_recordid]
							  ,[dtstorecontexttypeid]
							  ,[TradingPartnerPromotionIdentifier]
							  ,[MarkDeleted]
							  ,[DeleteLoginId]
							  ,[DeleteReason]
							  ,[DeleteDateTime]
							  ,[datetimecreated]
							  ,0 --[SkipPopulating879_889Records]
							  ,[MaintenanceRequestID] --[Skip_879_889_Conversion_ProcessCompleted]
							  ,[dtproductdescription]
							  ,[DealNumber]
							  ,[CorrectedProductID]
							  ,[FromWebInterface]
							  ,[SlottingFees]
							  ,[AdFees]
							  ,[Bipad]
							  ,[RequestSource]
							  ,[RawProductIdentifier]
							  ,[PDIParticipant]
							  ,[OldUPC]
							  ,[OldUPCDescription]
							  ,[PrimaryGroupLevel]
							  ,[AlternateGroupLevel]
							  ,[ItemGroup]
							  ,[AlternateItemGroup]
							  ,[Size]
							  ,[ManufacturerIdentifier]
							  ,[SellPkgVINAllowReorder]
							  ,[SellPkgVINAllowReClaim]
							  ,[PrimarySellablePkgIdentifier]
							  ,[PrimarySellablePkgQty]
							  ,[VIN]
							  ,[VINDescription]
							  ,[PurchPackDescription]
							  ,[PurchPackQty]
							  ,[AltSellPackage1]
							  ,[AltSellPackage1Qty]
							  ,[AltSellPackage1UPC]
							  ,[AltSellPackage1Retail]
							  ,[ProductCategoryId]
							  ,[OldVIN]
							  ,[OldVINDescription]
							  ,[InCompliance]
							  ,[ReplaceUPC]
							  ,[QtyOne]
							  ,[QtyTwo]
							  ,[QtyThree]
							  ,[QtyFour]
							  ,[QtyFive]
							  ,[QtySix]
							  ,[QtySeven]
							  ,[SupplierIdentifier]
							  ,[StoreIdentifier]
							  ,[ChainIdentifier]
							  ,[ProductIdentifierType]
						  FROM [DataTrue_Main].[dbo].[MaintenanceRequests]
						  where MaintenanceRequestID = @MaintenanceRequestID						
						fetch next from @rec2 into @promoamount,@promostartdate,@promoenddate
					end
			
			end
					
			INSERT INTO [DataTrue_Main].[dbo].[MaintenanceRequests]
					   ([SubmitDateTime]
					   ,[RequestTypeID]
					   ,[ChainID]
					   ,[SupplierID]
					   ,[Banner]
					   ,[AllStores]
					   ,[UPC]
					   ,[BrandIdentifier]
					   ,[ItemDescription]
					   ,[CurrentSetupCost]
					   ,[Cost]
					   ,[SuggestedRetail]
					   ,[PromoTypeID]
					   ,[PromoAllowance]
					   ,[StartDateTime]
					   ,[EndDateTime]
					   ,[SupplierLoginID]
					   ,[ChainLoginID]
					   ,[Approved]
					   ,[ApprovalDateTime]
					   ,[DenialReason]
					   ,[EmailGeneratedToSupplier]
					   ,[EmailGeneratedToSupplierDateTime]
					   ,[RequestStatus]
					   ,[CostZoneID]
					   ,[productid]
					   ,[brandid]
					   ,[upc12]
					   ,[datatrue_edi_costs_recordid]
					   ,[datatrue_edi_promotions_recordid]
					   ,[dtstorecontexttypeid]
					   ,[TradingPartnerPromotionIdentifier]
					   ,[MarkDeleted]
					   ,[DeleteLoginId]
					   ,[DeleteReason]
					   ,[DeleteDateTime]
					   ,[datetimecreated]
					   ,[SkipPopulating879_889Records]
					   ,[Skip_879_889_Conversion_ProcessCompleted]
					   ,[dtproductdescription]
					   ,[DealNumber]
					   ,[CorrectedProductID]
					   ,[FromWebInterface]
					   ,[SlottingFees]
					   ,[AdFees]
					   ,[Bipad]
					   ,[RequestSource]
					   ,[RawProductIdentifier]
					   ,[PDIParticipant]
					   ,[OldUPC]
					   ,[OldUPCDescription]
					   ,[PrimaryGroupLevel]
					   ,[AlternateGroupLevel]
					   ,[ItemGroup]
					   ,[AlternateItemGroup]
					   ,[Size]
					   ,[ManufacturerIdentifier]
					   ,[SellPkgVINAllowReorder]
					   ,[SellPkgVINAllowReClaim]
					   ,[PrimarySellablePkgIdentifier]
					   ,[PrimarySellablePkgQty]
					   ,[VIN]
					   ,[VINDescription]
					   ,[PurchPackDescription]
					   ,[PurchPackQty]
					   ,[AltSellPackage1]
					   ,[AltSellPackage1Qty]
					   ,[AltSellPackage1UPC]
					   ,[AltSellPackage1Retail]
					   ,[ProductCategoryId]
					   ,[OldVIN]
					   ,[OldVINDescription]
					   ,[InCompliance]
					   ,[ReplaceUPC]
					   ,[QtyOne]
					   ,[QtyTwo]
					   ,[QtyThree]
					   ,[QtyFour]
					   ,[QtyFive]
					   ,[QtySix]
					   ,[QtySeven]
					   ,[SupplierIdentifier]
					   ,[StoreIdentifier]
					   ,[ChainIdentifier]
					   ,[ProductIdentifierType])
			SELECT [SubmitDateTime]
				  ,[RequestTypeID]
				  ,[ChainID]
				  ,[SupplierID]
				  ,[Banner]
				  ,[AllStores]
				  ,[UPC]
				  ,[BrandIdentifier]
				  ,[ItemDescription]
				  ,[CurrentSetupCost]
				  ,[Cost]
				  ,[SuggestedRetail]
				  ,[PromoTypeID]
				  ,[PromoAllowance]
				  ,[StartDateTime] 
				  ,'12/31/2099' --[EndDateTime]
				  ,[SupplierLoginID]
				  ,[ChainLoginID]
				  ,[Approved]
				  ,[ApprovalDateTime]
				  ,[DenialReason]
				  ,[EmailGeneratedToSupplier]
				  ,[EmailGeneratedToSupplierDateTime]
				  ,17 --[RequestStatus]
				  ,[CostZoneID]
				  ,[productid]
				  ,[brandid]
				  ,[upc12]
				  ,[datatrue_edi_costs_recordid]
				  ,[datatrue_edi_promotions_recordid]
				  ,[dtstorecontexttypeid]
				  ,[TradingPartnerPromotionIdentifier]
				  ,[MarkDeleted]
				  ,[DeleteLoginId]
				  ,[DeleteReason]
				  ,[DeleteDateTime]
				  ,[datetimecreated]
				  ,0 --[SkipPopulating879_889Records]
				  ,[MaintenanceRequestID] --[Skip_879_889_Conversion_ProcessCompleted]
				  ,[dtproductdescription]
				  ,[DealNumber]
				  ,[CorrectedProductID]
				  ,[FromWebInterface]
				  ,[SlottingFees]
				  ,[AdFees]
				  ,[Bipad]
				  ,[RequestSource]
				  ,[RawProductIdentifier]
				  ,[PDIParticipant]
				  ,[OldUPC]
				  ,[OldUPCDescription]
				  ,[PrimaryGroupLevel]
				  ,[AlternateGroupLevel]
				  ,[ItemGroup]
				  ,[AlternateItemGroup]
				  ,[Size]
				  ,[ManufacturerIdentifier]
				  ,[SellPkgVINAllowReorder]
				  ,[SellPkgVINAllowReClaim]
				  ,[PrimarySellablePkgIdentifier]
				  ,[PrimarySellablePkgQty]
				  ,[VIN]
				  ,[VINDescription]
				  ,[PurchPackDescription]
				  ,[PurchPackQty]
				  ,[AltSellPackage1]
				  ,[AltSellPackage1Qty]
				  ,[AltSellPackage1UPC]
				  ,[AltSellPackage1Retail]
				  ,[ProductCategoryId]
				  ,[OldVIN]
				  ,[OldVINDescription]
				  ,[InCompliance]
				  ,[ReplaceUPC]
				  ,[QtyOne]
				  ,[QtyTwo]
				  ,[QtyThree]
				  ,[QtyFour]
				  ,[QtyFive]
				  ,[QtySix]
				  ,[QtySeven]
				  ,[SupplierIdentifier]
				  ,[StoreIdentifier]
				  ,[ChainIdentifier]
				  ,[ProductIdentifierType]
			  FROM [DataTrue_Main].[dbo].[MaintenanceRequests]
			  where MaintenanceRequestID = @MaintenanceRequestID
												
		fetch next from @rec into @MaintenanceRequestID,@ChainID,@SupplierID,@Banner,@AllStores,@Cost,@SuggestedRetail,@StartDateTime
							,@EndDateTime,@CostZoneID,@productid,@brandid,@upc12,@dtstorecontexttypeid,@VIN	
	end	
	
close @rec
deallocate @rec

						
return
GO
