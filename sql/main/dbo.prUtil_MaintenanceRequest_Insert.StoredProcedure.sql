USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_MaintenanceRequest_Insert]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prUtil_MaintenanceRequest_Insert]
as

declare @dummy int=0


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
     Select '11/30/2011'
           ,2
           ,40393
           ,SupplierID
           ,'Cub Foods'
           ,1
           ,[12DigitUPC]
           ,Itemdescription
           ,UnitPrice
           ,Cost
           ,Retail
           ,0
           ,0
           ,'11/30/2011'
           ,'11/30/2012'
           ,40384
           ,0


from dbo.SuppliersSetupData ss
inner join ProductPrices pp
on ss.storeid = pp.StoreID
and ss.productid = pp.ProductID
and ss.brandid = pp.BrandID
and ss.SupplierID = pp.SupplierID
where pp.ProductPriceTypeID = 5
and ss.Cost <> pp.UnitPrice           

*/

return
GO
