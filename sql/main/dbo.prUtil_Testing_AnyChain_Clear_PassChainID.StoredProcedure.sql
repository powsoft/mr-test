USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Testing_AnyChain_Clear_PassChainID]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Testing_AnyChain_Clear_PassChainID]
@chainid int
 as
--declare @chainid int set @chainid = 40393
delete RelatedTransactions where StoreTransactionID in (select StoreTransactionID from StoreTransactions where chainid = @chainid)
delete RelatedTransactions where StoreTransactionID in (select WorkingTransactionID from StoreTransactions where chainid = @chainid)
delete StoreTransactions_Working where chainid = @chainid
delete StoreTransactions where chainid = @chainid
delete InventoryPerPetual where chainid = @chainid
delete dbo.InvoiceDetails where chainid = @chainid
delete dbo.InvoicesRetailer where chainid = @chainid
delete dbo.InvoicesSupplier --where chainid = @chainid
delete DataTrue_EDI.dbo.InvoiceDetails where chainid = @chainid
delete DataTrue_EDI.dbo.InvoicesRetailer where chainid = @chainid
delete DataTrue_EDI.dbo.InvoicesSupplier --where chainid = @chainid
delete from dbo.Batch
truncate table Exceptions
delete InventoryCost where chainid = @chainid
delete InvoicesRetailer where chainid = @chainid
delete InvoicesSupplier --where chainid = @chainid
delete DataTrue_EDI..InvoicesRetailer where chainid = @chainid
delete DataTrue_EDI..InvoicesSupplier --where chainid = @chainid
truncate table cdc.dbo_StoreTransactions_CT
truncate table cdc.dbo_InventoryPerpetual_CT
truncate table cdc.dbo_InvoiceDetails_CT
--truncate table DataTrue_Report..StoreTransactions
delete DataTrue_Archive..StoreTransactions where chainid = @chainid
delete DataTrue_Archive..InventoryPerpetual where chainid = @chainid
delete Source where SourceID <> 0 and SourceID <> 135  and SourceID <> 136  and SourceID <> 137  and SourceID <> 138
delete DataTrue_Report..StoreSalesBySaleDate where chainid = @chainid
delete DataTrue_Report..StoreTransactions where chainid = @chainid
delete DataTrue_Report..InventoryPerpetual where chainid = @chainid
return
GO
