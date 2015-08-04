USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prArchive_StoreTransactions_Working_Debug]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prArchive_StoreTransactions_Working_Debug]
as

/*
select * into import.dbo.storetransactions_working_BeforeArchive_20121101  from storetransactions_working where WorkingStatus = 5 and DATEDIFF(day, datetimecreated, getdate())>14
select * from chains

*/

select storetransactionid 
into #tempWorkingRecords
--select count(*)
from DataTrue_Main.dbo.StoreTransactions_Working
where chainid in (59973,63612,
63613,
63614)
and WorkingStatus = 5
--and ChainIdentifier = 'CST_PDI'
--and DATEDIFF(day, datetimecreated, getdate())>14

SET IDENTITY_INSERT DataTrue_Archive.dbo.storetransactions_working ON 

INSERT INTO [DataTrue_Archive].[dbo].[storetransactions_working]
           ([StoreTransactionID]
           ,[ChainID]
           ,[ChainIdentifier]
           ,[StoreIdentifier]
           ,[SourceIdentifier]
           ,[SupplierIdentifier]
           ,[DateTimeSourceReceived]
           ,[StoreID]
           ,[ProductID]
           ,[SupplierID]
           ,[TransactionTypeID]
           ,[ProductPriceTypeID]
           ,[BrandID]
           ,[Qty]
           ,[SetupCost]
           ,[SetupRetail]
           ,[SaleDateTime]
           ,[UPC]
           ,[ProductIdentifierType]
           ,[ProductCategoryIdentifier]
           ,[BrandIdentifier]
           ,[SupplierInvoiceNumber]
           ,[ReportedCost]
           ,[ReportedRetail]
           ,[ReportedPromotionPrice]
           ,[ReportedAllowance]
           ,[RuleCost]
           ,[RuleRetail]
           ,[CostMisMatch]
           ,[RetailMisMatch]
           ,[TrueCost]
           ,[TrueRetail]
           ,[ActualCostNetFee]
           ,[TransactionStatus]
           ,[Reversed]
           ,[ProcessingErrorDesc]
           ,[SourceID]
           ,[Comments]
           ,[InvoiceID]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[WorkingSource]
           ,[WorkingStatus]
           ,[RecordID_EDI_852]
           ,[Banner]
           ,[StoreName]
           ,[ProductQualifier]
           ,[RawProductIdentifier]
           ,[SupplierName]
           ,[DivisionIdentifier]
           ,[UOM]
           ,[SalePrice]
           ,[InvoiceNo]
           ,[PONo]
           ,[CorporateName]
           ,[CorporateIdentifier]
           ,[PromoTypeID]
           ,[PromoAllowance]
           ,[SBTNumber]
           ,[TempStoreIDTest]
           ,[EDIBanner]
           ,[EDIName]
           ,[StoreIDCorrection]
           ,[SourceOrDestinationID]
           ,[RecordType]
           ,[Bipad])
SELECT [StoreTransactionID]
      ,[ChainID]
      ,[ChainIdentifier]
      ,[StoreIdentifier]
      ,[SourceIdentifier]
      ,[SupplierIdentifier]
      ,[DateTimeSourceReceived]
      ,[StoreID]
      ,[ProductID]
      ,[SupplierID]
      ,[TransactionTypeID]
      ,[ProductPriceTypeID]
      ,[BrandID]
      ,[Qty]
      ,[SetupCost]
      ,[SetupRetail]
      ,[SaleDateTime]
      ,[UPC]
      ,[ProductIdentifierType]
      ,[ProductCategoryIdentifier]
      ,[BrandIdentifier]
      ,[SupplierInvoiceNumber]
      ,[ReportedCost]
      ,[ReportedRetail]
      ,[ReportedPromotionPrice]
      ,[ReportedAllowance]
      ,[RuleCost]
      ,[RuleRetail]
      ,[CostMisMatch]
      ,[RetailMisMatch]
      ,[TrueCost]
      ,[TrueRetail]
      ,[ActualCostNetFee]
      ,[TransactionStatus]
      ,[Reversed]
      ,[ProcessingErrorDesc]
      ,[SourceID]
      ,[Comments]
      ,[InvoiceID]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[WorkingSource]
      ,[WorkingStatus]
      ,[RecordID_EDI_852]
      ,[Banner]
      ,[StoreName]
      ,[ProductQualifier]
      ,[RawProductIdentifier]
      ,[SupplierName]
      ,[DivisionIdentifier]
      ,[UOM]
      ,[SalePrice]
      ,[InvoiceNo]
      ,[PONo]
      ,[CorporateName]
      ,[CorporateIdentifier]
      ,[PromoTypeID]
      ,[PromoAllowance]
      ,[SBTNumber]
      ,[TempStoreIDTest]
      ,[EDIBanner]
      ,[EDIName]
      ,[StoreIDCorrection]
      ,[SourceOrDestinationID]
      ,[RecordType]
      ,[Bipad]
  FROM [DataTrue_Main].[dbo].[StoreTransactions_Working]
where StoreTransactionID in
(select storetransactionid from #tempWorkingRecords) 

delete DataTrue_Main.dbo.StoreTransactions_Working
where StoreTransactionID in
(select storetransactionid from #tempWorkingRecords)


drop table #tempWorkingRecords

return
GO
