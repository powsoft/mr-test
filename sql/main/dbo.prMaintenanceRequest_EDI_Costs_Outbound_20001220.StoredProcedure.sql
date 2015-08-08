USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_EDI_Costs_Outbound_20001220]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prMaintenanceRequest_EDI_Costs_Outbound_20001220]
as

/*
select top 10 * from [DataTrue_EDI].[dbo].[Costs]
select top 10 * FROM [DataTrue_Main].[dbo].[MaintenanceRequests]
*/

/*
INSERT INTO [DataTrue_EDI].[dbo].[Costs]
           ([PartnerIdentifier]
           ,[PartnerName]
           ,[PartnerDuns]
           ,[PartnerAddress]
           ,[PartnerCity]
           ,[PartnerState]
           ,[PartnerZip]
           ,[PriceChangeCode]
           ,[Banner]
           ,[StoreIdentifier]
           ,[StoreName]
           ,[StoreAddress]
           ,[StoreCity]
           ,[StoreState]
           ,[StoreZip]
           ,[PricingMarket]
           ,[AllStores]
           ,[Cost]
           ,[SuggRetail]
           ,[RawProductIdentifier]
           ,[ProductIdentifier]
           ,[ProductName]
           ,[ProcessDate]
           ,[ProcessTime]
           ,[EffectiveDate]
           ,[EndDate]
           ,[FirstOrderDate]
           ,[FirstShipDate]
           ,[FirstArrivalDate]
           ,[MarketAccount]
           ,[MarketAccountDescription]
           ,[PriceBracket]
           ,[UOM]
           ,[PrePriced]
           ,[Qty]
           ,[unitweight]
           ,[weightqualifier]
           ,[weightunitcode]
           ,[FileName]
           ,[DateCreated]
           ,[PriceListNumber]
           ,[RecordStatus]
           ,[dtchainid]
           ,[dtsupplierid]
           ,[dtbanner]
           ,[dtstorecontexttypeid])
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
