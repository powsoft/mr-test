USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_GetUnAuthorizedProductBySupplierId]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_GetUnAuthorizedProductBySupplierId]
	@supplierId int,
	@banner nvarchar(50)
as
Begin
	SELECT [MaintenanceRequestID]
      ,[SubmitDateTime]
      ,[RequestTypeID]
      ,[ChainID]
      ,[SupplierID]
      ,[Banner]
      ,[AllStores]
      ,'''' + [UPC]
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
      ,''''+[upc12]
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
  FROM [DataTrue_Main].[dbo].[MaintenanceRequests]
	where RequestStatus=-30
	and SupplierID=@supplierId
	and Banner in (@banner);
	
end
GO
