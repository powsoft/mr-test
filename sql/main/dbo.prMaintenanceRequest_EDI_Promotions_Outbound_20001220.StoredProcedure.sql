USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_EDI_Promotions_Outbound_20001220]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_EDI_Promotions_Outbound_20001220]
as

/*
select top 10 * from [DataTrue_EDI].[dbo].[Promotions]
select top 10 * FROM [DataTrue_Main].[dbo].[MaintenanceRequests]
*/

/*
INSERT INTO [DataTrue_EDI].[dbo].[Promotions]
           ([SupplierIdentifier]
           ,[DateStartPromotion]
           ,[DateEndPromotion]
           ,[PromotionStatus]
           ,[PromotionNumber]
           ,[MarketAreaCodeIdentifier]
           ,[MarketAreaCode]
           ,[UnitSize]
           ,[VendorName]
           ,[VendorDuns]
           ,[Note]
           ,[StoreName]
           ,[StoreDuns]
           ,[StoreNumber]
           ,[ProductName]
           ,[Allowance_ChargeCode]
           ,[Allowance_ChargeMethod]
           ,[Allowance_ChargeRate]
           ,[Allowance_ChargeMeasureCode]
           ,[RawProductIdentifier]
           ,[ProductIdentifier]
           ,[FileName]
           ,[DateTimeCreated]
           ,[Loadstatus]
           ,[productid]
           ,[supplierid]
           ,[storeid]
           ,[banner]
           ,[CorpIdentifier]
           ,[CorporateName]
           ,[SupplierName]
           ,[StoreIdentifier]
           ,[dtstorecontexttypeid]
           ,[dtcostzoneid]
           ,[dtmaintenancerequestid])
SELECT [MaintenanceRequestID]
      ,[SubmitDateTime]
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
  FROM [DataTrue_Main].[dbo].[MaintenanceRequests]
  */








return
GO
