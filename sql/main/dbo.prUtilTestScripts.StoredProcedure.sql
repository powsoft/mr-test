USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtilTestScripts]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prUtilTestScripts]

as
--

--********************Clear All For News Test Run*********************************

truncate table StoreTransactions_Working
delete StoreTransactions
delete InventoryPerPetual
delete Source where SourceID <> 0 and SourceID <> 135  and SourceID <> 136  and SourceID <> 137  and SourceID <> 138
truncate table DataTrue_Report..StoreTransactions
truncate table DataTrue_Archive..StoreTransactions
truncate table DataTrue_Report..StoreSalesBySaleDate
truncate table DataTrue_Report..InventoryPerpetual
truncate table DataTrue_Archive..InventoryPerpetual
delete dbo.InvoiceDetails
delete dbo.InvoicesRetailer
delete dbo.InvoicesSupplier
delete from dbo.Batch
truncate table Exceptions
truncate table cdc.dbo_StoreTransactions_CT
truncate table cdc.dbo_InventoryPerpetual_CT
truncate table cdc.dbo_InvoiceDetails_CT

--*************846 Import*************************
--update DataTrue_EDI..Inbound846Inventory set RecordStatus = 0 where ChainName in ('WorldMart', 'WorldMartx') or (storenumber = '02804' and ProductIdentifier = '089505010059')

exec prGetInbound846Inventory
exec prValidateStoresInStoreTransactions_Working_INV
exec prValidateProductsInStoreTransactions_Working_INV
exec prValidateSuppliersInStoreTransactions_Working_INV
exec prValidateSourceInStoreTransactions_Working_INV
exec prValidateTransactionTypeInStoreTransactions_Working_INV
exec prApplyINVStoreTransactionsToInventory
exec prProcessShrink

exec prCDCGetStoreTransactionsLSN
exec prCDCGetInventoryPerpetualUpdatesLSN
--*************POS Transactions*******************************
--update DataTrue_EDI..Inbound852Sales set Recordstatus = 0

exec prGetInboundPOSTransactions
exec prValidateStoresInStoreTransactions_Working
exec prValidateProductsInStoreTransactions_Working
exec prValidateSuppliersInStoreTransactions_Working
exec prValidateSourceInStoreTransactions_Working
exec prValidateTransactionTypeInStoreTransactions_Working
exec prProcessPOSForShrinkReversal
exec prApplyPOSStoreTransactionsToInventory
exec prApplyShrinkReversalToInventory

exec prCDCGetStoreTransactionsLSN
exec prCDCGetInventoryPerpetualUpdatesLSN
--*************Supplier Store Transactions Import*************************
--update DataTrue_EDI..InBoundSuppliers set RecordStatus = 0 where RecordID in (1,2,3)

exec prGetInboundSUPTransactions
exec prValidateStoresInStoreTransactions_Working_SUP
exec prValidateProductsInStoreTransactions_Working_SUP
exec prValidateSuppliersInStoreTransactions_Working_SUP
exec prValidateSourceInStoreTransactions_Working_SUP
exec prValidateTransactionTypeInStoreTransactions_Working_SUP
exec prProcessSUPDeliveriesForShrinkReversal
exec prProcessSUPPickupsForShrinkReversal
exec prApplySUPStoreTransactionsToInventory
exec prApplyShrinkReversalToInventory

exec prCDCGetStoreTransactionsLSN
exec prCDCGetInventoryPerpetualUpdatesLSN
--*******************Invoicing Start******************************************
/*
delete dbo.InvoiceDetails
update storetransactions set transactionstatus = 1, invoicebatchid = null
*/

exec prInvoiceDetail_ReleaseStoreTransactions
exec prInvoiceDetail_POS_Create
exec prInvoiceDetail_SUP_Create
exec prInvoiceDetail_Shrink_Create
--exec [prInvoiceDetail_DollarDifference_Create] '6/2/2011'

declare @invoicedate smalldatetime
declare @rundate date
set @invoicedate = '7/1/2011'
while @invoicedate < '8/1/2011'
	begin
			set @rundate = cast(@invoicedate as date)	
			exec [prInvoiceDetail_DollarDifference_Create] @rundate			
			set @invoicedate = DATEADD(day,1,@invoicedate)
	end

--Run Invoicing Job
/*
update InvoiceDetails set RetailerInvoiceId = null, recordstatus = 0
update BillingControl set LastBillingPeriodEndDateTime = '2011-07-10 00:00:00.000', NextBillingPeriodEndDateTime = '2011-07-17 00:00:00.000',NextBillingPeriodRunDateTime = '2011-07-20 00:00:00.000' where BillingControlFrequency = 'Weekly'
delete InvoicesRetailer
delete InvoicesSupplier
*/

exec prInvoices_Retailer_Create 'Weekly'


--*******************Invoicing End******************************************





return
GO
