USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetMaintenanceRequestsLSN_New]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetMaintenanceRequestsLSN_New]
as

declare @MyID int
declare @startlsn binary(10)
declare @endlsn binary(10)
declare @count int
declare @from_lsn binary(10)
declare @to_lsn binary(10)

set @MyID = 0

begin try

--begin transaction


exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMinLSN_TableName 'dbo_MaintenanceRequests',@from_lsn output
exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMaxLSN @to_lsn output--sys.fn_cdc_get_max_lsn();

--print @from_lsn

--print @to_lsn

--Archive all CDC records

/*

INSERT INTO [IC-HQSQL1INST2].[DataTrue_Archive].dbo.[dbo_MaintenanceRequests_CT]
           ([__$start_lsn]
      ,[__$end_lsn]
      ,[__$seqval]
      ,[__$operation]
      ,[__$update_mask]
      ,[MaintenanceRequestID]
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
      ,[ProductIdentifierType]
      ,[SupplierPackageID]
)
SELECT [__$start_lsn]
      ,[__$end_lsn]
      ,[__$seqval]
      ,[__$operation]
      ,[__$update_mask]
      ,[MaintenanceRequestID]
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
      ,[ProductIdentifierType]
      ,[SupplierPackageID]
  FROM [IC-HQSQL1\DataTrue].DataTrue_Main.[cdc].[dbo_MaintenanceRequests_CT]
  where __$start_lsn >= @from_lsn and __$start_lsn <= @to_lsn


MERGE INTO [DataTrue_Report].[dbo].MaintenanceRequests t

USING (SELECT 
      [__$operation]
      ,[MaintenanceRequestID]
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
      ,[ProductIdentifierType]
      ,[SupplierPackageID]
      	FROM [IC-HQSQL1\DataTrue].DataTrue_Main.[cdc].[dbo_MaintenanceRequests_CT]
  where __$start_lsn >= @from_lsn and __$start_lsn <= @to_lsn
  and __$operation<>3
	order by __$start_lsn
		) s
		on t.MaintenanceRequestID = s.MaintenanceRequestID


WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
	
WHEN MATCHED THEN

update 	
   SET [SubmitDateTime] = s.SubmitDateTime
      ,[RequestTypeID] = s.RequestTypeID
      ,[ChainID] = s.ChainID
      ,[SupplierID] = s.SupplierID
      ,[Banner] = s.Banner
      ,[AllStores] = s.AllStores
      ,[UPC] = s.UPC
      ,[BrandIdentifier] = s.BrandIdentifier
      ,[ItemDescription] = s.ItemDescription
      ,[CurrentSetupCost] = s.CurrentSetupCost
      ,[Cost] = s.Cost
      ,[SuggestedRetail] = s.SuggestedRetail
      ,[PromoTypeID] = s.PromoTypeID
      ,[PromoAllowance] = s.PromoAllowance
      ,[StartDateTime] = s.StartDateTime
      ,[EndDateTime] = s.EndDateTime
      ,[SupplierLoginID] = s.SupplierLoginID
      ,[ChainLoginID] = s.ChainLoginID
      ,[Approved] = s.Approved
      ,[ApprovalDateTime] = s.ApprovalDateTime
      ,[DenialReason] = s.DenialReason
      ,[EmailGeneratedToSupplier] = s.EmailGeneratedToSupplier
      ,[EmailGeneratedToSupplierDateTime] = s.EmailGeneratedToSupplierDateTime
      ,[RequestStatus] = s.RequestStatus
      ,[CostZoneID] = s.CostZoneID
      ,[productid] = s.productid
      ,[brandid] = s.brandid
      ,[upc12] = s.upc12
      ,[datatrue_edi_costs_recordid] = s.datatrue_edi_costs_recordid
      ,[datatrue_edi_promotions_recordid] = s.datatrue_edi_promotions_recordid
      ,[dtstorecontexttypeid] = s.dtstorecontexttypeid
      ,[TradingPartnerPromotionIdentifier] = s.TradingPartnerPromotionIdentifier
      ,[MarkDeleted] = s.MarkDeleted
      ,[DeleteLoginId] = s.DeleteLoginId
      ,[DeleteReason] = s.DeleteReason
      ,[DeleteDateTime] = s.DeleteDateTime
      ,[datetimecreated] = s.datetimecreated
      ,[SkipPopulating879_889Records] = s.SkipPopulating879_889Records
      ,[Skip_879_889_Conversion_ProcessCompleted] = s.Skip_879_889_Conversion_ProcessCompleted
      ,[dtproductdescription] = s.dtproductdescription
      ,[DealNumber] = s.DealNumber
      ,[CorrectedProductID] = s.CorrectedProductID
      ,[FromWebInterface] = s.FromWebInterface
      ,[SlottingFees] = s.SlottingFees
      ,[AdFees] = s.AdFees
	  ,[Bipad]=s.Bipad
      ,[RequestSource]=s.RequestSource
      ,[RawProductIdentifier]=s.RawProductIdentifier
      ,[PDIParticipant]=s.PDIParticipant
      ,[OldUPC]=s.OldUPC
      ,[OldUPCDescription]=s.OldUPCDescription
      ,[PrimaryGroupLevel]=s.PrimaryGroupLevel
      ,[AlternateGroupLevel]=s.AlternateGroupLevel
      ,[ItemGroup]=s.ItemGroup
      ,[AlternateItemGroup]=s.AlternateItemGroup
      ,[Size]=s.Size
      ,[ManufacturerIdentifier]=s.ManufacturerIdentifier
      ,[SellPkgVINAllowReorder]=s.SellPkgVINAllowReorder
      ,[SellPkgVINAllowReClaim]=s.SellPkgVINAllowReClaim
      ,[PrimarySellablePkgIdentifier]=s.PrimarySellablePkgIdentifier
      ,[PrimarySellablePkgQty]=s.PrimarySellablePkgQty
      ,[VIN]=s.VIN
      ,[VINDescription]=s.VINDescription
      ,[PurchPackDescription]=s.PurchPackDescription
      ,[PurchPackQty]=s.PurchPackQty
      ,[AltSellPackage1]=s.AltSellPackage1
      ,[AltSellPackage1Qty]=s.AltSellPackage1Qty
      ,[AltSellPackage1UPC]=s.AltSellPackage1UPC
      ,[AltSellPackage1Retail]=s.AltSellPackage1Retail
      ,[ProductCategoryId]=s.[ProductCategoryId]
      ,[OldVIN]=s.[OldVIN]
      ,[OldVINDescription]=s.[OldVINDescription]
      ,[InCompliance]=s.[InCompliance]
      ,[ReplaceUPC]=s.[ReplaceUPC]
      ,[QtyOne]=s.[QtyOne]
      ,[QtyTwo]=s.[QtyTwo]
      ,[QtyThree]=s.[QtyThree]
      ,[QtyFour]=s.[QtyFour]
      ,[QtyFive]=s.[QtyFive]
      ,[QtySix]=s.[QtySix]
      ,[QtySeven]=s.[QtySeven]
      ,[SupplierIdentifier]=s.[SupplierIdentifier]
      ,[StoreIdentifier]=s.[StoreIdentifier]
      ,[ChainIdentifier]=s.[ChainIdentifier]
      ,[ProductIdentifierType]=s.[ProductIdentifierType]
      ,[SupplierPackageID]=s.[SupplierPackageID]


WHEN NOT MATCHED 

THEN INSERT 
           ([MaintenanceRequestID]
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
      ,[ProductIdentifierType]
      ,[SupplierPackageID]
)
     VALUES
           (s.[MaintenanceRequestID]
      ,s.[SubmitDateTime]
      ,s.[RequestTypeID]
      ,s.[ChainID]
      ,s.[SupplierID]
      ,s.[Banner]
      ,s.[AllStores]
      ,s.[UPC]
      ,s.[BrandIdentifier]
      ,s.[ItemDescription]
      ,s.[CurrentSetupCost]
      ,s.[Cost]
      ,s.[SuggestedRetail]
      ,s.[PromoTypeID]
      ,s.[PromoAllowance]
      ,s.[StartDateTime]
      ,s.[EndDateTime]
      ,s.[SupplierLoginID]
      ,s.[ChainLoginID]
      ,s.[Approved]
      ,s.[ApprovalDateTime]
      ,s.[DenialReason]
      ,s.[EmailGeneratedToSupplier]
      ,s.[EmailGeneratedToSupplierDateTime]
      ,s.[RequestStatus]
      ,s.[CostZoneID]
      ,s.[productid]
      ,s.[brandid]
      ,s.[upc12]
      ,s.[datatrue_edi_costs_recordid]
      ,s.[datatrue_edi_promotions_recordid]
      ,s.[dtstorecontexttypeid]
      ,s.[TradingPartnerPromotionIdentifier]
      ,s.[MarkDeleted]
      ,s.[DeleteLoginId]
      ,s.[DeleteReason]
      ,s.[DeleteDateTime]
      ,s.[datetimecreated]
      ,s.[SkipPopulating879_889Records]
      ,s.[Skip_879_889_Conversion_ProcessCompleted]
      ,s.[dtproductdescription]
      ,s.[DealNumber]
      ,s.[CorrectedProductID]
      ,s.[FromWebInterface]
      ,s.[SlottingFees]
      ,s.[AdFees]
      ,s.[Bipad]
      ,s.[RequestSource]
      ,s.[RawProductIdentifier]
      ,s.[PDIParticipant]
      ,s.[OldUPC]
      ,s.[OldUPCDescription]
      ,s.[PrimaryGroupLevel]
      ,s.[AlternateGroupLevel]
      ,s.[ItemGroup]
      ,s.[AlternateItemGroup]
      ,s.[Size]
      ,s.[ManufacturerIdentifier]
      ,s.[SellPkgVINAllowReorder]
      ,s.[SellPkgVINAllowReClaim]
      ,s.[PrimarySellablePkgIdentifier]
      ,s.[PrimarySellablePkgQty]
      ,s.[VIN]
      ,s.[VINDescription]
      ,s.[PurchPackDescription]
      ,s.[PurchPackQty]
      ,s.[AltSellPackage1]
      ,s.[AltSellPackage1Qty]
      ,s.[AltSellPackage1UPC]
      ,s.[AltSellPackage1Retail]
      ,s.[ProductCategoryId]
      ,s.[OldVIN]
      ,s.[OldVINDescription]
      ,s.[InCompliance]
      ,s.[ReplaceUPC]
      ,s.[QtyOne]
      ,s.[QtyTwo]
      ,s.[QtyThree]
      ,s.[QtyFour]
      ,s.[QtyFive]
      ,s.[QtySix]
      ,s.[QtySeven]
      ,s.[SupplierIdentifier]
      ,s.[StoreIdentifier]
      ,s.[ChainIdentifier]
      ,s.[ProductIdentifierType]
      ,s.[SupplierPackageID]
);

	delete [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_MaintenanceRequests_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
	*/
--commit transaction
	
end try
	
begin catch
		--rollback transaction
		
		declare @errormessage varchar(4500)
		declare @errorlocation varchar(255)
		declare @errorsenderstring nvarchar(255)

		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
--		print @errormessage

		exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
end catch
	

return
GO
