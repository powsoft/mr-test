USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Testing_Worldmart_Clear]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Testing_Worldmart_Clear] as
delete RelatedTransactions where StoreTransactionID in (select StoreTransactionID from StoreTransactions where chainid = 7608)
delete RelatedTransactions where StoreTransactionID in (select WorkingTransactionID from StoreTransactions where chainid = 7608)
delete StoreTransactions_Working where chainid = 7608
delete StoreTransactions where chainid = 7608
delete InventoryPerPetual where chainid = 7608
delete dbo.InvoiceDetails where chainid = 7608
delete dbo.InvoicesRetailer where chainid = 7608
delete dbo.InvoicesSupplier where SupplierInvoiceID in (select SupplierInvoiceID from InvoiceDetails where chainid = 7608)
delete DataTrue_EDI.dbo.InvoiceDetails where chainid = 7608
delete DataTrue_EDI.dbo.InvoicesRetailer where chainid = 7608
delete DataTrue_EDI.dbo.InvoicesSupplier where SupplierInvoiceID in (select SupplierInvoiceID from InvoiceDetails where chainid = 7608)
delete InventoryCost where chainid = 7608
delete DataTrue_Report..StoreTransactions where chainid = 7608
delete DataTrue_Archive..StoreTransactions where chainid = 7608
delete DataTrue_Report..StoreSalesBySaleDate where chainid = 7608
delete DataTrue_Report..InventoryPerpetual where chainid = 7608
delete DataTrue_Archive..InventoryPerpetual where chainid = 7608
delete Source where SourceID <> 0 and SourceID <> 135  and SourceID <> 136  and SourceID <> 137  and SourceID <> 138
return
GO
