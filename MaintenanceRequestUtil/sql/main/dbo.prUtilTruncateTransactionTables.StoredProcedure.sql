USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtilTruncateTransactionTables]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtilTruncateTransactionTables]
/*

******************Inventory Perpetual****************************
select top 100 * from InventoryPerpetual
select sum(CurrentOnHandQty) from InventoryPerpetual where chainid = 35541
select sum(SBTSales * Retail) from InventoryPerpetual where chainid = 35541


*******************Chain Setup Steps*******************************
Chain table record
ChainProductFactors default record for POS-added products

select count(*) from DataTrue_Main..StoreTransactions_Working where workingstatus = 4
select top 1000 * from DataTrue_Main..StoreTransactions_Working
--delete from DataTrue_Main..StoreTransactions_Working
where Workingsource in ('POS')

select top 1000 * from DataTrue_Main..StoreTransactions_Working order by datetimecreated desc
select top 1000 * from DataTrue_Main..StoreTransactions order by datetimecreated desc
select* from DataTrue_Main..StoreTransactions where datetimecreated >= '10/11/2011'

select* from DataTrue_Main..StoreTransactions where storeid = 36840 and productid = 336 order by saledatetime




update storetransactions set InvoiceBatchID = null where storetransactionid = 498972


select storeid, sum(cast(reportedretail as money))
from DataTrue_Main..StoreTransactions_Working
where chainidentifier = 'RA'
group by storeid
order by sum(cast(reportedretail as money)) desc

10069-35565
10191-35690
10187-35685
01363-37317
10103-35600

select supplieridentifier from suppliers where supplierid in
(
select distinct supplierid from storesetup where storeid in
('35565',
'35690',
'35685',
'37317',
'35600')
)

select transactiontypeid, count(*) 
from DataTrue_Main..StoreTransactions
group by transactiontypeid

select * from StoreTransactions 
where transactiontypeid in (7,16)
--and reportedcost <> 0
order by saledatetime, storeid, productid, brandid

select * from StoreTransactions 
where 1 = 1
and chainid = 35541 
and storeid = 35985 
and productid = 770
and cast(saledatetime as date) = '2011-07-16'

select * from relatedtransactions where workingtransactionid = 426973
426973


--***********************Storetransactions********************************
select sum(ruleretail * qty) from storetransactions where chainid = 35541

update datatrue_edi.dbo.InBoundSuppliers set recordstatus = 1
select storeid, productid, brandid, cast(saledatetime as date), count(*) 
from DataTrue_Main..StoreTransactions
group by storeid, productid, brandid, cast(saledatetime as date)
having count(*) > 1
order by count(*) desc

	select StoreTransactionID, ProcessingErrorDesc,
	SetupCost, SetupRetail, ReportedCost, ReportedRetail,
	Qty, SupplierID
	from StoreTransactions
	where len(ProcessingErrorDesc) > 0
	and isnumeric(ProcessingErrorDesc) > 0

select * from DataTrue_Main..StoreTransactions_Working
where storeid = 35689 and productid = 607 and cast(saledatetime as date) = '7/20/2011'

select * from DataTrue_Main..StoreTransactions
where storeid = 35689 and productid = 607 and cast(saledatetime as date) = '7/20/2011'

select count(*) from DataTrue_Main..StoreTransactions
--delete from DataTrue_Main..StoreTransactions
select distinct chainid from DataTrue_Main..StoreTransactions_Working
where TransactionTypeID in (2)
update [DataTrue_Main].[dbo].[StoreTransactions_Working] set workingstatus = 4
select distinct workingstatus from [DataTrue_Main].[dbo].[StoreTransactions_Working]
select distinct chainid from [DataTrue_Main].[dbo].[StoreTransactions_Working]
select distinct brandid from [DataTrue_Main].[dbo].[StoreTransactions_Working]
select distinct supplierid from [DataTrue_Main].[dbo].[StoreTransactions_Working]
select distinct storeid from [DataTrue_Main].[dbo].[StoreTransactions_Working]
select distinct productid from [DataTrue_Main].[dbo].[StoreTransactions_Working]
select * from [DataTrue_Main].[dbo].[StoreTransactions_Working] where supplierid = 7584

select * from [DataTrue_Main].[dbo].[StoreTransactions_Working] where unitsaleprice is null
select UPC from [DataTrue_Main].[dbo].[StoreTransactions_Working] 
where UPC in (select ProductName from Products)
and UPC not in (select IdentifierValue from ProductIdentifiers where ProductIdentifierTypeID = 2)

select * from ProductIdentifiers where ProductIdentifierTypeID = 2 and productid = 865

select distinct TransactionTypeID from DataTrue_Main..StoreTransactions_Working
select count(*) from DataTrue_Main..Stores
select count(*) from DataTrue_EDI..Inbound852Sales
update DataTrue_EDI..Inbound852Sales set Recordstatus = 1
--*************Rite Aide********************************
select *
--update s set s.Recordstatus = 0
FROM  DataTrue_EDI..InboundSuppliers s
WHERE (ChainIdentifier = 'RA') 
and storeidentifier = '3144' --10314' --storeid 35813
AND (Saledate >= '7/31/2011')
and (Saledate < '8/9/2011')

select storeidentifier, count(storetransactionid)
from storetransactions_working
where transactiontypeid in (5, 8)
group by storeidentifier
order by count(storetransactionid) desc

declare @sid int = 3144
--select storeidentifier, count(recordid)
update s set s.Recordstatus = 0
FROM  DataTrue_EDI..InboundSuppliers s
WHERE (s.ChainIdentifier = 'RA')
--and cast(storeidentifier as int) = @sid  
AND (Saledate >= '7/31/2011')
and (Saledate < '8/9/2011')
group by storeidentifier
order by count(recordid) desc

declare @sid int = 3144
--select storeidentifier, count(recordid)
update s set recordstatus = 0
FROM  DataTrue_EDI..Inbound852Sales s
WHERE (s.ChainIdentifier = 'RA')
and cast(storeidentifier as int) = @sid 
AND (Saledate >= '7/31/2011')
and (Saledate < '8/9/2011')
group by storeidentifier
order by count(recordid) desc

select * from storetransactions_working where storeidentifier = '10314'

select *
--update s set s.Recordstatus = 0
FROM  DataTrue_EDI..Inbound852Sales s
WHERE (s.ChainIdentifier = 'RA') 
--and storeidentifier = '3144'
AND (Saledate >= '7/31/2011')
and (Saledate < '8/9/2011')

select *
--update s set s.Recordstatus = 0
FROM  DataTrue_EDI..Inbound852Sales s
WHERE (ChainIdentifier = 'RA') 
AND (Saledate >= '7/31/2011')
and (Saledate < '8/9/2011')
and storeidentifier = '4439'


select *
--update s set s.Recordstatus = 0
FROM  DataTrue_EDI..Inbound852Sales s
WHERE (ChainIdentifier = 'RA') 
AND (Saledate >= '7/31/2011')
and (Saledate < '8/9/2011')
order by storeidentifier, productidentifier, saledate

select * from stores where storeid = 35413
select * from products where productid = 35413
select * from suppliers where supplierid = 35413
--******************************************************
select count(recordid) from DataTrue_EDI..Inbound852Sales where recordstatus = 0
select * from DataTrue_EDI..Inbound852Sales where recordstatus = 0
select distinct saledate from DataTrue_EDI..Inbound852Sales where chainidentifier = 'RA' order by saledate
select count(*) from DataTrue_EDI..InBoundSuppliers
update DataTrue_EDI..InBoundSuppliers set RecordStatus = 1
select count(*) from DataTrue_Main..InventoryPerpetual

update i set i.chainid = s.chainid 
from DataTrue_Main..InventoryPerpetual i
inner join stores s
on i.storeid = s.storeid

select count(*) from DataTrue_Main..Stores

select top 100 * from storesetup where InventoryCostMethod is null
*/
as
--
--************************Payment Release*****************************************************************************

exec prInvoices_Supplier_ReleaseForPayment
exec prInvoicesSupplier_ReleasedForPayment_Get

--*****************Views*************************
exec prUtil_GetInventoryCostView 7608
exec prUtil_GetInventoryPerpetualView 7608
exec prUtil_GetStoreTransactionView 7608
exec prUtil_GetInvoiceDetailsView 7608
exec prUtil_GetInvoiceHeaderView 7608
--***********************************************

update DataTrue_EDI..InvoicesRetailer set TransmissionDate = null, TransmissionRef = null, OpenAmount = Originalamount, Invoicestatus = 0
--********************************************************************************************************************
--alter procedure prUtil_Testing_Worldmart_Clear as
delete RelatedTransactions where StoreTransactionID in (select StoreTransactionID from StoreTransactions where chainid = 7608)
delete RelatedTransactions where StoreTransactionID in (select WorkingTransactionID from StoreTransactions where chainid = 7608)
delete StoreTransactions_Working where chainid = 7608
delete StoreTransactions where chainid = 7608
delete InventoryPerPetual where chainid = 7608
delete dbo.InvoiceDetails where chainid = 7608
delete dbo.InvoicesRetailer where chainid = 7608
delete dbo.InvoicesSupplier --where chainid = 7608
delete DataTrue_EDI.dbo.InvoiceDetails where chainid = 7608
delete DataTrue_EDI.dbo.InvoicesRetailer where chainid = 7608
delete DataTrue_EDI.dbo.InvoicesSupplier --where chainid = 7608
delete from dbo.Batch
truncate table Exceptions
delete InventoryCost where chainid = 7608
delete InvoicesRetailer where chainid = 7608
delete InvoicesSupplier --where chainid = 7608
delete DataTrue_EDI..InvoicesRetailer where chainid = 7608
delete DataTrue_EDI..InvoicesSupplier --where chainid = 7608
truncate table cdc.dbo_StoreTransactions_CT
truncate table cdc.dbo_InventoryPerpetual_CT
truncate table cdc.dbo_InvoiceDetails_CT
--truncate table DataTrue_Report..StoreTransactions
delete DataTrue_Report..StoreTransactions where chainid = 7608
delete DataTrue_Archive..StoreTransactions where chainid = 7608
delete DataTrue_Report..StoreSalesBySaleDate where chainid = 7608
delete DataTrue_Report..InventoryPerpetual where chainid = 7608
delete DataTrue_Archive..InventoryPerpetual where chainid = 7608
delete Source where SourceID <> 0 and SourceID <> 135  and SourceID <> 136  and SourceID <> 137  and SourceID <> 138
return
--*****************Views*************************
exec prUtil_GetInventoryCostView 40393
exec prUtil_GetInventoryPerpetualView 40393
exec prUtil_GetStoreTransactionView 7608
exec prUtil_GetInvoiceDetailsView 7608
exec prUtil_GetInvoiceHeaderView 7608
--***********************************************
exec prUtil_Testing_Worldmart_Clear
--*************846 Import*************************

--update DataTrue_EDI..Inbound846Inventory set RecordStatus = 0 where ChainName in ('WorldMart', 'WorldMartx') or (storenumber = '02804' and ProductIdentifier = '089505010059')
--update DataTrue_EDI..Inbound846Inventory set RecordStatus = 0 where ChainName in ('CVS') 

exec prGetInbound846Inventory
exec prValidateStoresInStoreTransactions_Working_INV
exec prValidateProductsInStoreTransactions_Working_INV
exec prValidateSuppliersInStoreTransactions_Working_INV
exec prValidateSourceInStoreTransactions_Working_INV
exec prValidateTransactionTypeInStoreTransactions_Working_INV
exec prApplyINVStoreTransactionsToInventory
exec prApplyINVStoreTransactionsToInventoryCost --************************************************************************
--*************For Initial Count Zero Shrink Revision**************************
exec prProcessShrink_Initial
--*************For Non-Initial Count Apply Shrink Revision**************************
exec prProcessShrink
--*************For Non-Initial Count Apply Shrink Revision**************************
exec prInventory_WAVG_ProcessTransactions
exec prInventory_FIFO_ProcessTransactions

exec prCDCGetStoreTransactionsLSN
exec prCDCGetInventoryPerpetualUpdatesLSN
--*************Supplier Store Transactions Import*************************
--update DataTrue_EDI..InBoundSuppliers set RecordStatus = 0 where RecordID in (1,2,3)
--update storetransactions set InventoryCost = null where storetransactionid = 499221
--*****************Views*************************
exec prUtil_GetInventoryCostView 7608
exec prUtil_GetInventoryPerpetualView 7608
exec prUtil_GetStoreTransactionView 7608
exec prUtil_GetInvoiceDetailsView 7608
exec prUtil_GetInvoiceHeaderView 7608
--***********************************************

exec prGetInboundSUPTransactions
exec prValidateStoresInStoreTransactions_Working_SUP
exec prValidateProductsInStoreTransactions_Working_SUP
exec prValidateSuppliersInStoreTransactions_Working_SUP
exec prValidateSourceInStoreTransactions_Working_SUP
exec prValidateTransactionTypeInStoreTransactions_Working_SUP
exec prProcessSUPDeliveriesForShrinkReversal
exec prProcessSUPPickupsForShrinkReversal
exec prApplySUPStoreTransactionsToInventoryCost--************************************************************************
exec prInventory_WAVG_ProcessTransactions
exec prInventory_FIFO_ProcessTransactions
exec prApplySUPStoreTransactionsToInventory
exec prApplyShrinkReversalToInventory

exec prCDCGetStoreTransactionsLSN
exec prCDCGetInventoryPerpetualUpdatesLSN
--*************POS Transactions*******************************
--update DataTrue_EDI..Inbound852Sales set Recordstatus = 0 where chainname = 'RA'
--select * from DataTrue_EDI..Inbound852Sales where Recordstatus = 0
--*****************Views*************************
exec prUtil_GetInventoryCostView 40393
exec prUtil_GetInventoryPerpetualView 40393
exec prUtil_GetStoreTransactionView 7608
exec prUtil_GetInvoiceDetailsView 7608
exec prUtil_GetInvoiceHeaderView 7608
--***********************************************

exec prGetInboundPOSTransactions
exec prValidateStoresInStoreTransactions_Working
exec prValidateProductsInStoreTransactions_Working
exec prValidateSuppliersInStoreTransactions_Working
exec prValidateSourceInStoreTransactions_Working
exec prValidateTransactionTypeInStoreTransactions_Working
exec prProcessPOSForShrinkReversal
exec prInventory_WAVG_ProcessTransactions
exec prInventory_FIFO_ProcessTransactions
exec prApplyPOSStoreTransactionsToInventory
exec prApplyShrinkReversalToInventory

exec prCDCGetStoreTransactionsLSN
exec prCDCGetInventoryPerpetualUpdatesLSN

--select DATEPART(weekday, getdate())
--*******************Invoicing Start******************************************
/*
delete dbo.InvoiceDetails
update storetransactions set inventorycost = null, transactionstatus = 0 where storetransactionid = 499022
update storetransactions set transactionstatus = 1, invoicebatchid = null
update storetransactions set transactionstatus = 1, invoicebatchid = null where storetransactionid = 498950
*/
--*****************Views*************************
exec prUtil_GetInventoryCostView 7608
exec prUtil_GetInventoryPerpetualView 7608
exec prUtil_GetStoreTransactionView 7608
exec prUtil_GetInvoiceDetailsView 7608
exec prUtil_GetInvoiceHeaderView 7608
--***********************************************
/*
update storetransactions set setupcost = null where storetransactionid in (498971,498972)
update storetransactions set reportedcost = null where storetransactionid in (498971,498972)
update storetransactions set InvoiceBatchID = null where storetransactionid in (498971,498972)

delete dbo.InvoiceDetails
update storetransactions set transactionstatus = 0, invoicebatchid = null
update storetransactions set transactionstatus = 1, invoicebatchid = null where storetransactionid = 498956
select * from invoicedetails where saledate = '11/7/2011'
update invoicedetails set retailerinvoiceid = null where saledate = '11/7/2011'
update datatrue_EDI.dbo.invoicedetails set retailerinvoiceid = null where saledate = '11/7/2011'
select * delete from InvoicesRetailer where retailerinvoiceid in
(select retailerinvoiceid from invoicedetails where saledate = '11/7/2011')
select * delete from datatrue_EDI.dbo.InvoicesRetailer where retailerinvoiceid in
(select retailerinvoiceid from invoicedetails where saledate = '11/7/2011')
*/
--*****************Views*************************
exec prUtil_GetInventoryCostView 7608
exec prUtil_GetInventoryPerpetualView 7608
exec prUtil_GetStoreTransactionView 7608
exec prUtil_GetInvoiceDetailsView 7608
exec prUtil_GetInvoiceHeaderView 7608
--***********************************************

--create procedure prUtil_Testing_CreateInvoiceDetails as
exec prInvoiceDetail_ReleaseStoreTransactions
exec prInvoiceDetail_POS_Create
exec prInvoiceDetail_SUP_Create
exec prInvoiceDetail_Retailer_Shrink_Create
exec prInvoiceDetail_Supplier_Shrink_Create
exec prInvoiceDetail_POSADJ_Create
exec prInvoiceDetail_SUPADJ_Create
exec prInvoiceDetail_Retailer_Shrink_Adj_Create
exec prInvoiceDetail_Supplier_Shrink_Adj_Create
exec prInvoiceDetail_DollarDifference_Create
return
--*****************Views*************************
exec prUtil_GetInventoryCostView 7608
exec prUtil_GetInventoryPerpetualView 7608
exec prUtil_GetStoreTransactionView 7608
exec prUtil_GetInvoiceDetailsView 7608
exec prUtil_GetInvoiceHeaderView 7608
--***********************************************


--Run Invoicing Job
/*
update InvoiceDetails set RetailerInvoiceId = null, SupplierInvoiceId = null, recordstatus = 0
update BillingControl set InvoiceSeparation = 3, LastBillingPeriodEndDateTime = '2011-07-10 00:00:00.000', NextBillingPeriodEndDateTime = '2011-07-17 00:00:00.000',NextBillingPeriodRunDateTime = '2011-07-20 00:00:00.000' where BillingControlFrequency = 'Weekly'
update InvoiceDetails set RetailerInvoiceId = null, SupplierInvoiceId = null, recordstatus = 0 where invoicedetailtypeid in (7,9,10,8)
update InvoiceDetails set RetailerInvoiceId = null, SupplierInvoiceId = null, recordstatus = 0 where invoicedetailid in (605,606)
update ChainProductFactors set BillingRuleID = 1 WHERE     (ProductID in (3444,1))
update ChainProductFactors set BillingRuleID = 2 WHERE     chainid = 35541
delete InvoicesRetailer
delete InvoicesSupplier
delete DataTrue_EDI..InvoicesRetailer
delete DataTrue_EDI..InvoicesSupplier
delete DataTrue_EDI..InvoiceDetails

update InvoiceDetails set SupplierInvoiceId = null, recordstatus = 0
update BillingControl set InvoiceSeparation = 1, LastBillingPeriodEndDateTime = '2011-07-11 00:00:00.000', NextBillingPeriodEndDateTime = '2011-07-18 00:00:00.000',NextBillingPeriodRunDateTime = '2011-07-21 00:00:00.000' where BillingControlFrequency = 'Weekly'
update ChainProductFactors set BillingRuleID = 1 WHERE     (ProductID in (3444))
update ChainProductFactors set BillingRuleID = 1 WHERE     (ProductID in (1))
delete InvoicesSupplier


update BillingControl set LastBillingPeriodEndDateTime = '2011-07-31 00:00:00.000', NextBillingPeriodEndDateTime = '2011-08-07 00:00:00.000',NextBillingPeriodRunDateTime = '2011-07-10 00:00:00.000' where EntityIDToInvoice = 35541
update BillingControl set LastBillingPeriodEndDateTime = '2011-08-01 00:00:00.000', NextBillingPeriodEndDateTime = '2011-08-08 00:00:00.000',NextBillingPeriodRunDateTime = '2011-07-11 00:00:00.000' where EntityIDToInvoice = 35113
update BillingControl set LastBillingPeriodEndDateTime = '2011-08-02 00:00:00.000', NextBillingPeriodEndDateTime = '2011-08-09 00:00:00.000',NextBillingPeriodRunDateTime = '2011-07-12 00:00:00.000' where EntityIDToInvoice = 24258

*/
--*****************Views*************************
exec prUtil_GetInventoryCostView 7608
exec prUtil_GetInventoryPerpetualView 7608
exec prUtil_GetStoreTransactionView 7608
exec prUtil_GetInvoiceDetailsView 7608
exec prUtil_GetInvoiceHeaderView 7608
--***********************************************

exec prInvoices_Retailer_Create
exec prInvoices_Supplier_Create



--*******************Invoicing End******************************************


exec prInvoices_Supplier_ReleaseForPayment

exec prInvoicesSupplier_ReleasedForPayment_Get








--****************************************************************************
--exec DataTrue_Report..prStoreSalesBySaleDate_Insert


exec prUpdateTrueCostAndTrueRetail 96735, 7.90, 9.90, 8, 999


declare @invoicedate smalldatetime
declare @rundate date
set @invoicedate = '7/1/2011'
while @invoicedate < '8/1/2011'
	begin
			set @rundate = cast(@invoicedate as date)	
			exec [prInvoiceDetail_DollarDifference_Create] @rundate			
			set @invoicedate = DATEADD(day,1,@invoicedate)
	end


select t1.StoreTransactionID, 
t2.StoreTransactionID as ShrinkTransactionID, 
t2.Qty, t2.TrueCost, t2.TrueRetail
from StoreTransactions t1
inner join StoreTransactions t2
on t1.StoreID = t2.StoreID
and t1.ProductID = t2.ProductID
and t1.BrandID = t2.BrandID
where t1.TransactionTypeID in (2, 7)
and t2.TransactionTypeID in (17)
and t1.SaleDateTime < t2.SaleDateTime
and t1.TransactionStatus = 0
order by t2.SaleDateTime

select * from StoreTransactions 
where 1 = 1
and storeid = 24112
and productid = 3444
and TransactionStatus = 0


/*
exec prCDCGetStoreTransactionsLSN
exec prCDCGetInventoryPerpetualUpdatesLSN


select * from InventoryPerpetual where shrinkrevision <> 0
delete from storetransactions where storetransactionid <> 96735
update storetransactions set truecost = null
exec DataTrue_Report.dbo.prStoreSalesBySaleDate_Insert
select * into DataTrue_Archive..StoreTransactions from DataTrue_Report..StoreTransactions
truncate table DataTrue_Archive..StoreTransactions
select * into DataTrue_Archive..InventoryPerpetual from DataTrue_Report..InventoryPerpetual
truncate table DataTrue_Archive..InventoryPerpetual
prArchiveStoreTransactions
create procedure prArchiveStoreTransactions
as
insert into DataTrue_Archive..StoreTransactions select * from cdc.dbo_StoreTransactions_CT
return
*/

select *
--update w set WorkingStatus = 3 
from StoreTransactions_Working  w
where 1 = 1
and workingsource in ('POS')
--and workingsource in ('SUP-S', 'SUP-U', 'SUP-X')

select count(*) from DataTrue_EDI..InBoundSuppliers
update StoreTransactions_Working set WorkingStatus = 0 where workingsource in ('SUP-S', 'SUP-U', 'SUP-X')
select *
--delete 
from StoreTransactions_Working where workingsource in ('SUP-S', 'SUP-U', 'SUP-X')
update DataTrue_EDI..InBoundSuppliers set RecordStatus = 0

SELECT     *
FROM         StoreTransactions
WHERE     (StoreID = 1548) AND (ProductID = 577)

SELECT     *
FROM         StoreTransactions
WHERE     (ProductID = 577) and TransactionTypeID = 2

SELECT     *
FROM         InventoryPerpetual
WHERE     1 = 1
and ShrinkRevision <> 0
and (StoreID = 1548) AND (ProductID = 577)

delete
FROM         StoreTransactions
WHERE     (StoreID <> 1548)

delete
FROM         StoreTransactions
WHERE     (ProductID <> 577)

select top 10 * 
from DataTrue_EDI..Inbound852Sales 
where productidentifier = '089505010059'
and StoreIdentifier = '01013'

select * from Stores where StoreId = 1548



select *
--delete 
--update t set workingstatus = 4
from StoreTransactions_Working t 
where 1 = 1
and WorkingStatus = 2
and workingsource = 'INV'
--and WorkingStatus = -5
--and workingsource = 'INV-BOD'

update StoreTransactions_Working set WorkingStatus = 0 
where workingsource in ('INV')

select *
--delete 
from InventoryPerpetual where chainid = 7608
update DataTrue_EDI..Inbound846Inventory set RecordStatus = 0 where chainname in ('WorldMart','WorldMartx')


return
GO
