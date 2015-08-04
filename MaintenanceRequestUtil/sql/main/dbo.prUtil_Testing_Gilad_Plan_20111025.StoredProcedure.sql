USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Testing_Gilad_Plan_20111025]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Testing_Gilad_Plan_20111025]
as

--***************************MAIN DATABASE*****************************
--Ids
--SupplierID=35113=BCJ
--ChainID=35541
--StoreID=37803
--Chain Billing RuleID = 2
--supplierID=28701=WR125

select * from Exceptions

select * from Suppliers where SupplierIdentifier='wr125'

delete from dbo.StoreTransactions where ChainID='35541'
delete from dbo.StoreTransactions_Working where ChainID='35541'

select * from dbo.stores where StoreID='37803' --Store number 2453
select * from dbo.Chains

select * from dbo.StoreTransactions where ChainID='7608'

select * from dbo.StoreTransactions where ChainID<>'7608'
select * from dbo.StoreTransactions order by SaleDateTime

---*Inventory*--------
select * from InventoryPerpetual where StoreID=37803
select * from InventoryCost where StoreID=37803
select * from StoreTransactions where StoreID=37803


delete from InventoryPerpetual where StoreID=37803
delete from InventoryCost where StoreID=37803

--table ChainProductFactors use billing rule ids described in table billing rules
select * from dbo.ChainProductFactors where ChainID='35541' order by BillingRuleID--Billing RuleID scenario: A or B or C
select * from dbo.BillingRules

select * from dbo.BillingControl where EntityIDToInvoice='35113' -- SupplierID
select * from dbo.BillingControl where EntityIDToInvoice='35541' --ChainID
select * from dbo.BillingControl where EntityIDToInvoice='28701' -- SupplierID


select * from dbo.BillingControl where EntityIDToInvoice='37803' -- StoreID -- No need for it to be in BillingControl table

--When running job CreateInvoiceDetails it will create details in invoice details
-- but not yet in invoice headers. In addition, no invoices will be created yet until
-- the RunBillingCycle job will be run. only then also the headers table will be populated

--Invoice Details
select * from dbo.InvoiceDetails where StoreID='37803' and (SupplierID='35113' or SupplierID='28701')

--Invoice Headers
select * from dbo.InvoicesRetailer
select * from dbo.InvoicesSupplier

--Invoice Details
delete from dbo.InvoiceDetails
--Invoice Headers
delete from dbo.InvoicesRetailer
delete from dbo.InvoicesSupplier

update BillingControl set LastBillingPeriodEndDateTime = '2011-07-31 00:00:00.000', NextBillingPeriodEndDateTime = '2011-08-07 00:00:00.000',NextBillingPeriodRunDateTime = '2011-07-10 00:00:00.000' where EntityIDToInvoice = 35541
update BillingControl set LastBillingPeriodEndDateTime = '2011-08-01 00:00:00.000', NextBillingPeriodEndDateTime = '2011-08-08 00:00:00.000',NextBillingPeriodRunDateTime = '2011-07-11 00:00:00.000' where EntityIDToInvoice = 35113
update BillingControl set LastBillingPeriodEndDateTime = '2011-08-01 00:00:00.000', NextBillingPeriodEndDateTime = '2011-08-08 00:00:00.000',NextBillingPeriodRunDateTime = '2011-07-11 00:00:00.000' where EntityIDToInvoice = 28701
update BillingControl set LastBillingPeriodEndDateTime = '2011-08-02 00:00:00.000', NextBillingPeriodEndDateTime = '2011-08-09 00:00:00.000',NextBillingPeriodRunDateTime = '2011-07-12 00:00:00.000' where EntityIDToInvoice = 24258


--View1:Supplier Data
SELECT dbo.StoreTransactions.ChainID, dbo.StoreTransactions.SupplierID, dbo.StoreTransactions.StoreID, dbo.StoreTransactions.TransactionTypeID, dbo.TransactionTypes.TransactionTypeName, dbo.StoreTransactions.SaleDateTime, Sum(dbo.StoreTransactions.Qty) AS SumOfQty
FROM dbo.StoreTransactions INNER JOIN dbo.TransactionTypes ON dbo.StoreTransactions.TransactionTypeID = dbo.TransactionTypes.TransactionTypeID
GROUP BY dbo.StoreTransactions.ChainID, dbo.StoreTransactions.SupplierID, dbo.StoreTransactions.StoreID, dbo.StoreTransactions.TransactionTypeID, dbo.TransactionTypes.TransactionTypeName, dbo.StoreTransactions.SaleDateTime
HAVING (((dbo.StoreTransactions.TransactionTypeID) Not Like 2))
ORDER BY dbo.StoreTransactions.TransactionTypeID, dbo.StoreTransactions.SaleDateTime;

--View2:Retailer Data

SELECT dbo.StoreTransactions.ChainID, dbo.StoreTransactions.SupplierID, dbo.StoreTransactions.StoreID, dbo.StoreTransactions.TransactionTypeID, dbo.TransactionTypes.TransactionTypeName, dbo.StoreTransactions.SaleDateTime, Sum(dbo.StoreTransactions.Qty) AS SumOfQty
FROM dbo.StoreTransactions INNER JOIN dbo.TransactionTypes ON dbo.StoreTransactions.TransactionTypeID = dbo.TransactionTypes.TransactionTypeID
GROUP BY dbo.StoreTransactions.ChainID, dbo.StoreTransactions.SupplierID, dbo.StoreTransactions.StoreID, dbo.StoreTransactions.TransactionTypeID, dbo.TransactionTypes.TransactionTypeName, dbo.StoreTransactions.SaleDateTime
HAVING (((dbo.StoreTransactions.SupplierID)=35113) AND ((dbo.StoreTransactions.StoreID)=37803) AND ((dbo.StoreTransactions.TransactionTypeID) Not Like 5 And (dbo.StoreTransactions.TransactionTypeID) Not Like 8))
ORDER BY dbo.StoreTransactions.TransactionTypeID, dbo.StoreTransactions.SaleDateTime;

--View3:Transaction Status:
SELECT dbo.StoreTransactions.ChainID, dbo.StoreTransactions.SupplierID, dbo.StoreTransactions.StoreID, dbo.StoreTransactions.TransactionTypeID, dbo.TransactionTypes.TransactionTypeName, Sum(dbo.StoreTransactions.Qty) AS SumOfQty, dbo.StoreTransactions.TransactionStatus, dbo.StoreTransactions.InvoiceBatchID
FROM dbo.StoreTransactions INNER JOIN dbo.TransactionTypes ON dbo.StoreTransactions.TransactionTypeID = dbo.TransactionTypes.TransactionTypeID
GROUP BY dbo.StoreTransactions.ChainID, dbo.StoreTransactions.SupplierID, dbo.StoreTransactions.StoreID, dbo.StoreTransactions.TransactionTypeID, dbo.TransactionTypes.TransactionTypeName, dbo.StoreTransactions.TransactionStatus, dbo.StoreTransactions.InvoiceBatchID
HAVING (((dbo.StoreTransactions.ChainID)=35541) AND ((dbo.StoreTransactions.SupplierID)=35113) AND ((dbo.StoreTransactions.StoreID)=37803));

--for all suppliers
SELECT dbo.StoreTransactions.ChainID, dbo.StoreTransactions.SupplierID, dbo.StoreTransactions.StoreID, dbo.StoreTransactions.TransactionTypeID, dbo.TransactionTypes.TransactionTypeName, Sum(dbo.StoreTransactions.Qty) AS SumOfQty, dbo.StoreTransactions.TransactionStatus, dbo.StoreTransactions.InvoiceBatchID
FROM dbo.StoreTransactions INNER JOIN dbo.TransactionTypes ON dbo.StoreTransactions.TransactionTypeID = dbo.TransactionTypes.TransactionTypeID
GROUP BY dbo.StoreTransactions.ChainID, dbo.StoreTransactions.SupplierID, dbo.StoreTransactions.StoreID, dbo.StoreTransactions.TransactionTypeID, dbo.TransactionTypes.TransactionTypeName, dbo.StoreTransactions.TransactionStatus, dbo.StoreTransactions.InvoiceBatchID
HAVING (((dbo.StoreTransactions.ChainID)=35541) AND ((dbo.StoreTransactions.StoreID)=37803));

--View4: InvoiceDetails Table:
SELECT dbo.InvoiceDetails.RetailerInvoiceID, dbo.InvoiceDetails.SupplierInvoiceID, dbo.InvoiceDetails.ChainID, dbo.InvoiceDetails.StoreID, dbo.InvoiceDetails.SupplierID, dbo.InvoiceDetails.SaleDate, Sum(dbo.InvoiceDetails.TotalQty) AS SumOfTotalQty, Sum(dbo.InvoiceDetails.TotalCost) AS SumOfTotalCost, Sum(dbo.InvoiceDetails.TotalRetail) AS SumOfTotalRetail, dbo.InvoiceDetails.BatchID, dbo.InvoiceDetails.RecordStatus
FROM dbo.InvoiceDetails
GROUP BY dbo.InvoiceDetails.RetailerInvoiceID, dbo.InvoiceDetails.SupplierInvoiceID, dbo.InvoiceDetails.ChainID, dbo.InvoiceDetails.StoreID, dbo.InvoiceDetails.SupplierID, dbo.InvoiceDetails.SaleDate, dbo.InvoiceDetails.BatchID, dbo.InvoiceDetails.RecordStatus
HAVING (((dbo.InvoiceDetails.ChainID)=35541) AND ((dbo.InvoiceDetails.StoreID)=37803) AND ((dbo.InvoiceDetails.SupplierID)=35113));

--for all suppliers
SELECT dbo.InvoiceDetails.RetailerInvoiceID, dbo.InvoiceDetails.SupplierInvoiceID, dbo.InvoiceDetails.ChainID, dbo.InvoiceDetails.StoreID, dbo.InvoiceDetails.SupplierID, dbo.InvoiceDetails.SaleDate, Sum(dbo.InvoiceDetails.TotalQty) AS SumOfTotalQty, Sum(dbo.InvoiceDetails.TotalCost) AS SumOfTotalCost, Sum(dbo.InvoiceDetails.TotalRetail) AS SumOfTotalRetail, dbo.InvoiceDetails.BatchID, dbo.InvoiceDetails.RecordStatus
FROM dbo.InvoiceDetails
GROUP BY dbo.InvoiceDetails.RetailerInvoiceID, dbo.InvoiceDetails.SupplierInvoiceID, dbo.InvoiceDetails.ChainID, dbo.InvoiceDetails.StoreID, dbo.InvoiceDetails.SupplierID, dbo.InvoiceDetails.SaleDate, dbo.InvoiceDetails.BatchID, dbo.InvoiceDetails.RecordStatus
HAVING (((dbo.InvoiceDetails.ChainID)=35541) AND ((dbo.InvoiceDetails.StoreID)=37803) AND ((dbo.InvoiceDetails.SupplierID)=35113) or (dbo.InvoiceDetails.SupplierID)=28701);


--View5: Transaction status:
SELECT dbo.StoreTransactions.ChainID, dbo.StoreTransactions.SupplierID, dbo.StoreTransactions.StoreID, dbo.StoreTransactions.TransactionTypeID, dbo.TransactionTypes.TransactionTypeName, dbo.StoreTransactions.SaleDateTime, Sum(dbo.StoreTransactions.Qty) AS SumOfQty, dbo.StoreTransactions.TransactionStatus, dbo.Statuses.StatusIntValue, dbo.Statuses.StatusName, dbo.StatusTypes.StatusName
FROM (dbo.StoreTransactions INNER JOIN dbo.TransactionTypes ON dbo.StoreTransactions.TransactionTypeID = dbo.TransactionTypes.TransactionTypeID) INNER JOIN (dbo.Statuses INNER JOIN dbo.StatusTypes ON dbo.Statuses.StatusTypeID = dbo.StatusTypes.StatusTypeID) ON dbo.StoreTransactions.TransactionStatus = dbo.Statuses.StatusIntValue
GROUP BY dbo.StoreTransactions.ChainID, dbo.StoreTransactions.SupplierID, dbo.StoreTransactions.StoreID, dbo.StoreTransactions.TransactionTypeID, dbo.TransactionTypes.TransactionTypeName, dbo.StoreTransactions.SaleDateTime, dbo.StoreTransactions.TransactionStatus, dbo.Statuses.StatusIntValue, dbo.Statuses.StatusName, dbo.StatusTypes.StatusName
HAVING (((dbo.StoreTransactions.SupplierID)=35113) AND ((dbo.StoreTransactions.StoreID)=37803) AND ((dbo.StoreTransactions.TransactionTypeID) Not Like 5 And (dbo.StoreTransactions.TransactionTypeID) Not Like 8) AND ((dbo.StatusTypes.StatusName)='POSStoresTransactionsStatus'))
ORDER BY dbo.StoreTransactions.TransactionTypeID, dbo.StoreTransactions.SaleDateTime;

select * from dbo.ProductPrices where ChainID='35541' and StoreID='37803' and (SupplierID='35113' or SupplierID='28714') and ProductID=916

UPDATE dbo.ProductPrices
 SET UnitPrice=0.64
 WHERE ChainID='35541' and StoreID='37803' and (SupplierID='35113' or SupplierID='28714') and ProductID=916

select * from ProductPrices where StoreID=37803 and ProductId=577
select * from ProductPriceTypes

select * from ProductIdentifiers where ProductID = 577
select * from ProductIdentifiers where ProductID = 916
select * from stores where StoreID = 37803

select * from Datatrue_EDI.dbo.Inbound852Sales where storeidentifier = '2453' and ProductIdentifier = '089505010059'
select * from Datatrue_EDI.dbo.Inbound852Sales where storeidentifier = '2453' and ProductIdentifier = '651580443093'
select * from Datatrue_EDI.dbo.InBoundSuppliers where storeidentifier = '2453' and TitleID = '089505010059' order by recordid

delete from dbo.StoreTransactions_working where ChainID='35541'
delete from dbo.StoreTransactions where ChainID='35541'
delete from InventoryPerpetual where StoreID=37803
delete from InventoryCost where StoreID=37803

select * from stores where StoreID = 37803

select *
--UPDATE s set RecordStatus = 0
from Datatrue_EDI.dbo.Inbound852Sales s
 WHERE ChainIdentifier='ra'
 and cast(StoreIdentifier as int) = 2453
 order by StoreIdentifier
--********************************************
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
--***********************************************
select * from InventoryPerpetual where StoreID=37803
select * from InventoryCost where StoreID=37803

UPDATE dbo.ProductPrices
 SET UnitPrice=0.75
 WHERE ChainID='35541' and StoreID='37803' and (SupplierID='35113' or SupplierID='28714') and ProductID=916


select *
--update s set s.Recordstatus = 0
from Datatrue_EDI.dbo.InBoundSuppliers s 
 where 1 = 1
 --and storeidentifier = '2453' 
 --and TitleID = '089505010059'
 and FileName = 'BCJ_2011-08-07-Gilad.csv'
order by recordid

--BCJ_2011-08-07-Gilad.csv
--BCJ_2011-08-07-Sean3.csv
--BCJ_2011-08-07-Sean1.csv

select * from dbo.StoreTransactions where ChainID='35541' and StoreID='37803' and ProductID = 577 and CostMisMatch = 0 and RetailMisMatch = 0

select tt.TransactionTypeName, Qty * tt.QtySign as QtySigned, * 
--update st set transactionstatus = 2, Processing
from dbo.StoreTransactions st
inner join TransactionTypes tt
on st.TransactionTypeID = tt.TransactionTypeID
where ChainID='35541' 
and StoreID='37803' 
and ProductID = 916 
and CostMisMatch = 0 
and RetailMisMatch = 0
and st.TransactionTypeID in (5,8)




select * from TransactionTypes

--Invoice Details
select * from dbo.InvoiceDetails where StoreID='37803' and (SupplierID='35113' or SupplierID='28701')

--Invoice Headers
select * from dbo.InvoicesRetailer
select * from dbo.InvoicesSupplier

SELECT dbo.StoreTransactions.ChainID, dbo.StoreTransactions.SupplierID, dbo.StoreTransactions.StoreID, dbo.StoreTransactions.TransactionTypeID, dbo.TransactionTypes.TransactionTypeName, dbo.StoreTransactions.SaleDateTime, Sum(dbo.StoreTransactions.Qty) AS SumOfQty, dbo.StoreTransactions.TransactionStatus, dbo.Statuses.StatusIntValue, dbo.Statuses.StatusName, dbo.StatusTypes.StatusName
FROM (dbo.StoreTransactions INNER JOIN dbo.TransactionTypes ON dbo.StoreTransactions.TransactionTypeID = dbo.TransactionTypes.TransactionTypeID) INNER JOIN (dbo.Statuses INNER JOIN dbo.StatusTypes ON dbo.Statuses.StatusTypeID = dbo.StatusTypes.StatusTypeID) ON dbo.StoreTransactions.TransactionStatus = dbo.Statuses.StatusIntValue
GROUP BY dbo.StoreTransactions.ChainID, dbo.StoreTransactions.SupplierID, dbo.StoreTransactions.StoreID, dbo.StoreTransactions.TransactionTypeID, dbo.TransactionTypes.TransactionTypeName, dbo.StoreTransactions.SaleDateTime, dbo.StoreTransactions.TransactionStatus, dbo.Statuses.StatusIntValue, dbo.Statuses.StatusName, dbo.StatusTypes.StatusName
HAVING (((dbo.StoreTransactions.SupplierID)=35113) AND ((dbo.StoreTransactions.StoreID)=37803) AND ((dbo.StoreTransactions.TransactionTypeID)=5 Or (dbo.StoreTransactions.TransactionTypeID)=8) AND ((dbo.StatusTypes.StatusName)='SUPStoresTransactionsStatus'))
ORDER BY dbo.StoreTransactions.TransactionTypeID, dbo.StoreTransactions.SaleDateTime;


--***************************EDI DATABASE*****************************
delete from dbo.InBoundSuppliers where ChainIdentifier<>'WorldMart '
delete from dbo.InBoundSuppliers where ChainIdentifier<>'WorldMart '

select * from Datatrue_EDI.dbo.InBoundSuppliers where SupplierIdentifier='bcj'
select * from Datatrue_EDI.dbo.InBoundSuppliers where SupplierIdentifier='wr125'
delete from dbo.InBoundSuppliers where RecordStatus=0 and SupplierIdentifier='wr125'

delete from dbo.InBoundSuppliers where SupplierIdentifier='bcj' and RecordStatus=0 

delete from dbo.InBoundSuppliers where SupplierIdentifier='bcj'
delete from dbo.InBoundSuppliers where SupplierIdentifier='wr125'

select * from dbo.InBoundSuppliers
 
select * from dbo.InBoundSuppliers where (SupplierIdentifier='wr125' or SupplierIdentifier='bcj') and recordstatus=1 order by FileName

UPDATE dbo.InBoundSuppliers
 SET RecordStatus=0
 WHERE SupplierIdentifier='BCJ'
 
UPDATE dbo.InBoundSuppliers
 SET RecordStatus=0
 WHERE SupplierIdentifier='WR125'

delete from dbo.Inbound852Sales where ChainIdentifier='ra'
select * from dbo.Inbound852Sales where ChainIdentifier='ra' and RecordStatus=0

UPDATE Datatrue_EDI.dbo.Inbound852Sales
 SET RecordStatus=0
 WHERE ChainIdentifier='ra'


select *
from DataTrue_EDI.dbo.InBoundSuppliers
where RecordStatus = 0

--***************************REPORT DATABASE*****************************
select * from dbo.StoreTransactions where ChainID<>'7608'
delete from dbo.StoreTransactions where ChainID<>'7608'


--********************************************************************
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

select tt.TransactionTypeName, st.Qty * tt.qtysign as qtysigned, st.* 
from StoreTransactions st
inner join TransactionTypes tt
on st.TransactionTypeID = tt.TransactionTypeID
where InventoryCost is null
and ChainID='35541' and StoreID='37803'
and ProductID = 577 
and st.TransactionTypeID not in (2,9,20)
order by datetimecreated

select sum(st.Qty * tt.qtysign) -- as qtysigned, st.* 
from StoreTransactions st
inner join TransactionTypes tt
on st.TransactionTypeID = tt.TransactionTypeID
where InventoryCost is null
and ChainID='35541' and StoreID='37803'
and ProductID = 577 

and (SupplierID='35113' or SupplierID='28714') and ProductID=916
GO
