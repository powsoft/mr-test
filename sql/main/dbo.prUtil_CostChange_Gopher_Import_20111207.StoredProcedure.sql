USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_CostChange_Gopher_Import_20111207]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_CostChange_Gopher_Import_20111207]
as

/*
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
           ,[CostZoneID])
SELECT [McatCode]
      ,[ItemNbr]
      ,ltrim(rtrim([UPC]))
      ,ltrim(rtrim([Item]))
      ,[Pkg]
      ,[OrderShippingUnitQty]
      ,[CR]
      ,[ZoneName]
      ,[EffectiveDate]
      ,[EndDate]
      ,[BaseCost]
      ,[Allowance]
      ,[NetCost]
      ,[CostType]
      ,[HandlingMthd]
      ,[PromotionInfo]
      ,[SugRetail]
      ,[QtyRetail]
  FROM [DataTrue_EDI].[dbo].[TEMP_GopherCostChange]
*/

select * from productidentifiers where identifiervalue = '824325771595'

select * from productprices 
where productid = 15347 
and ProductPriceTypeID = 3
and StoreID in (select StoreID from stores where Custom1 = 'Cub Foods')
/*
824325771595
Something to Prove
3.22
5.5
*/

return
GO
