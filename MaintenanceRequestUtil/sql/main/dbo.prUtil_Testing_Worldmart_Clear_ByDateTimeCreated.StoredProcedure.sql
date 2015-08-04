USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Testing_Worldmart_Clear_ByDateTimeCreated]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prUtil_Testing_Worldmart_Clear_ByDateTimeCreated]
as
delete RelatedTransactions where StoreTransactionID in (select StoreTransactionID from StoreTransactions where datetimecreated >= '10/11/2011')
delete RelatedTransactions where StoreTransactionID in (select WorkingTransactionID from StoreTransactions where datetimecreated >= '10/11/2011')
delete StoreTransactions_Working where datetimecreated >= '10/11/2011'
delete StoreTransactions where datetimecreated >= '10/11/2011'
--delete InventoryPerPetual where chainid = 7608
delete dbo.InvoiceDetails where datetimecreated >= '10/11/2011'
delete dbo.InvoicesRetailer where datetimecreated >= '10/11/2011'
delete dbo.InvoicesSupplier --where chainid = 7608
delete DataTrue_EDI.dbo.InvoiceDetails where datetimecreated >= '10/11/2011'
delete DataTrue_EDI.dbo.InvoicesRetailer where datetimecreated >= '10/11/2011'
delete DataTrue_EDI.dbo.InvoicesSupplier where datetimecreated >= '10/11/2011'
delete from dbo.Batch
truncate table Exceptions
--delete InventoryCost where chainid = 7608
delete InvoicesRetailer where datetimecreated >= '10/11/2011'
delete InvoicesSupplier where datetimecreated >= '10/11/2011'
delete DataTrue_EDI..InvoicesRetailer where datetimecreated >= '10/11/2011'
delete DataTrue_EDI..InvoicesSupplier where datetimecreated >= '10/11/2011'
truncate table cdc.dbo_StoreTransactions_CT
truncate table cdc.dbo_InventoryPerpetual_CT
truncate table cdc.dbo_InvoiceDetails_CT
--truncate table DataTrue_Report..StoreTransactions
delete DataTrue_Report..StoreTransactions where datetimecreated >= '10/11/2011'
delete DataTrue_Archive..StoreTransactions where datetimecreated >= '10/11/2011'
delete DataTrue_Report..StoreSalesBySaleDate where datetimecreated >= '10/11/2011'
--delete DataTrue_Report..InventoryPerpetual where datetimecreated >= '10/11/2011'
--delete DataTrue_Archive..InventoryPerpetual where chainid = 7608
delete Source where SourceID <> 0 and SourceID <> 135  and SourceID <> 136  and SourceID <> 137  and SourceID <> 138



return
GO
