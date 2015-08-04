USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Inventory_Bring_Online]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Inventory_Bring_Online]
as
--drop table import.dbo.InvoiceDetails_20120129BeforeBimboReload

select * into import.dbo.Inbound846Inventory_20120129BeforeBimboReload from [DataTrue_EDI].[dbo].[Inbound846Inventory]
select * into import.dbo.storetransactions_working_20120129BeforeBimboReload from storetransactions_working where SupplierID = 40557
select * into import.dbo.storetransactions_20120129BeforeBimboReload from storetransactions where SupplierID = 40557
select * into import.dbo.InventoryPerpetual_20120129BeforeBimboReload from InventoryPerpetual
select * into import.dbo.InventoryCost_20120129BeforeBimboReload from InventoryCost
select * into import.dbo.InvoiceDetails_20120129BeforeBimboReload from InvoiceDetails where SupplierID = 40557


select * from InvoiceDetailS where SupplierID = 40557 and InvoiceDetailTypeID in (3, 5)
select * from StoreTransactions where SupplierID = 40557 and TransactionTypeID = 17

select * from StoreTransactions where SupplierID = 40557 and TransactionTypeID in (5, 8)
select * from datatrue_report.dbo.StoreTransactions where SupplierID = 40557 and TransactionTypeID in (5, 8)

select * from StoreTransactions where SupplierID = 40557 and TransactionTypeID in (11) and CAST(saledatetime as date) <> '12/1/2011'
select * from StoreTransactions_Working where SupplierID = 40557 and WorkingSource in ('INV-BOD') and CAST(saledatetime as date) <> '12/1/2011'

select * from StoreTransactions_working where SupplierID = 40557 and WorkingSource in ('SUP-S','SUP-U','SUP-X')

select * 
--update i set recordstatus = 0
from [DataTrue_EDI].[dbo].[Inbound846Inventory] i where EdiName = 'BIM' and PurposeCode in ('DB','CR') and EffectiveDate > '11/30/2011'

select *
from StoreTransactions
where SupplierID = 40557
and TransactionTypeID in (5,8)
and SetupCost is null

select * 
--update i set recordstatus = 0
from [DataTrue_EDI].[dbo].[Inbound846Inventory] i where EdiName = 'BIM' and PurposeCode in ('CNT') and EffectiveDate <> '12/1/2011'

select * from datatrue_edi.dbo.edi_suppliercrossreference

select top 1000 *
from StoreTransactions
where TransactionTypeID = 11
order by DateTimeCreated desc

select top 1000 *
--update t set supplierid = 40561, saledatetime = '1/23/2012'
from StoreTransactions t
where TransactionTypeID = 17
and CAST(datetimecreated as date) = '1/26/2012'
order by DateTimeCreated desc

select *
--update d set supplierid = 40561, saledate = '1/23/2012'
from InvoiceDetails d 
where 1 = 1
--and InvoiceDetailTypeID = 3 and SupplierID in (40561)
and CAST(datetimecreated as date) = '1/26/2012'


select saledatetime, COUNT(storetransactionid)
from StoreTransactions t
where SupplierID = 40557
and TransactionTypeID = 11
group by saledatetime



SELECT *
  FROM [DataTrue_EDI].[dbo].[Inbound846Inventory]
  where EdiName = 'BIM'


SELECT distinct Purposecode
  FROM [DataTrue_EDI].[dbo].[Inbound846Inventory]
  where EdiName = 'SAR'


select saledatetime, COUNT(storetransactionid)
from StoreTransactions t
where SupplierID = 41465
and TransactionTypeID in (5, 8)
group by saledatetime
order by saledatetime 

select saledatetime, transactionstatus, COUNT(storetransactionid)
from StoreTransactions
where SupplierID = 40557
and TransactionTypeID in (11)
group by SaleDateTime, transactionstatus
order by SaleDateTime, transactionstatus

select EffectiveDate, COUNT(recordid)
  FROM [DataTrue_EDI].[dbo].[Inbound846Inventory]
  where PurposeCode in ('cnt')
  --where PurposeCode in ('db','cr')
  and EdiName = 'SAR'
  and RecordStatus = 0
  and EffectiveDate > '11/30/2011'
  group by EffectiveDate
  order by EffectiveDate

select *
from StoreTransactions t
where SupplierID = 41465
and TransactionTypeID in (5, 8)
and DateTimeCreated < '2/3/2012'

select *
--delete
from StoreTransactions_Working --t
where EDIName = 'SAR'
and WorkingSource in ('SUP-S','SUP-U')

select *
from StoreTransactions t
where SupplierID = 41465
and TransactionTypeID in (11)

--select *
--select distinct storenumber, productidentifier
select storenumber, productidentifier, COUNT(recordid)
  FROM [DataTrue_EDI].[dbo].[Inbound846Inventory]
  where PurposeCode in ('cnt')
  --where PurposeCode in ('db','cr')
  and EdiName = 'SAR'
  and RecordStatus = 0
  and EffectiveDate = '12/3/2011'
  group by storenumber, productidentifier
  order by COUNT(recordid) desc
 
	select *
   FROM [DataTrue_EDI].[dbo].[Inbound846Inventory]
  where PurposeCode in ('cnt')
  --where PurposeCode in ('db','cr')
  and EdiName = 'SAR'
  and RecordStatus = 0
  and EffectiveDate = '12/3/2011'
  and StoreNumber = '6006'
  and ProductIdentifier = '050400215313'
 /* SAR dupes in count 
 6001                	050400215313
6003                	050400215313
6006                	050400215313
6007                	050400215313
  */
    
select distinct storeid, ProductId
from StoreTransactions
where SupplierID = 41465
and TransactionTypeID = 2

select saledate, datetimecreated, COUNT(invoicedetailid)
from InvoiceDetailS
where SupplierID = 40557
and InvoiceDetailTypeID = 3
group by saledate, datetimecreated
order by datetimecreated, saledate

select *
--update d set saledate = '2011-12-27 00:00:00.000'
from InvoiceDetailS d
where SupplierID = 40557
and InvoiceDetailTypeID = 3
and SaleDate = '2011-12-06'
and DateTimeCreated = '2012-01-30 07:52:22.070'


select *
  FROM [DataTrue_EDI].[dbo].[Inbound846Inventory]
  where PurposeCode in ('cr')
  and EdiName = 'BIM'
  and EffectiveDate > '11/30/2011'
and Qty > 0

  
select *
from InvoiceDetails d 
inner join stores s
on d.StoreID = s.storeid
where InvoiceDetailTypeID = 3 and SupplierID in (40561)

select d.* 
--update d set saledate = '12/5/2011'
--update d set banner = s.custom1
from InvoiceDetails d 
inner join stores s
on d.StoreID = s.storeid
where InvoiceDetailTypeID = 3 and SupplierID in (40562, 40561, 40558)
and Banner is null

select d.* 
--update d set productidentifier = i.identifiervalue, RawProductIdentifier = i.identifiervalue
from InvoiceDetails d 
inner join productidentifiers i
on d.ProductID = i.ProductID
where InvoiceDetailTypeID = 3 and SupplierID in (40562, 40561, 40558)
and i.ProductIdentifierTypeID = 2
and d.productidentifier is null

select * 
from InvoiceDetails where InvoiceDetailTypeID = 3 
--and storeid = 40509	and productid = 5511
order by invoicedetailid desc

select MAX(saledatetime)
from [dbo].[StoreTransactions_Working] w
where SupplierID = 40558
and WorkingSource in ('SUP-U','SUP-S')

select effectivedate, COUNT(recordid) 
from datatrue_edi.dbo.Inbound846Inventory
where purposecode in ('DB','CR')
and EffectiveDate >= '12/1/2011'
and RecordStatus = 0
and EdiName = 'BIM'
group by effectivedate
order by effectivedate

select effectivedate, COUNT(recordid) 
from datatrue_edi.dbo.Inbound846Inventory
where purposecode in ('CNT')
and EffectiveDate >= '12/1/2011'
and RecordStatus = 0
and EdiName = 'BIM'
group by effectivedate
order by effectivedate

select SUM(qty)
from [dbo].[StoreTransactions_Working] w
where SupplierID = 40558
and WorkingSource in ('SUP-U','SUP-S')
and cast(saledatetime as date) = '12/23/2011'


select saledatetime, COUNT(StoreTransactionID) 
from [dbo].[StoreTransactions_Working]
where WorkingSource in ('SUP-U','SUP-S')
and saledatetime >= '12/1/2011'
group by saledatetime
order by saledatetime

select distinct ediname from datatrue_edi.dbo.Inbound846Inventory

select effectivedate, ediname, COUNT(recordid) 
from datatrue_edi.dbo.Inbound846Inventory
where  1 = 1
and RecordStatus = 0
--and EdiName in ('GOP')
--and purposecode in ('DB','CR')
--and EffectiveDate >= '12/1/2011'
group by effectivedate, ediname
order by ediname, effectivedate

select *
--update w set w.qty = w.qty * -1
from [dbo].[StoreTransactions_Working] w
where WorkingStatus = 4
and WorkingSource in ('SUP-U')


--gopher reload
select *
--update w set supplierid = 41704
from [dbo].[StoreTransactions_Working] w
where WorkingSource in ('SUP-U','SUP-S', 'SUP-X')
and SupplierID = 40558
or SupplierIdentifier = 'GopherNews'
--and saledatetime >= '12/1/2011'

select *
--update w set saledatetime = '12/1/2011'
from [dbo].[StoreTransactions_working] w
where TransactionTypeID in (11)
and SupplierID = 40558

select *
--update w set supplierid = 41704
from [dbo].[StoreTransactions] w
where TransactionTypeID in (5,8)
and SupplierID = 40558

select *
--update w set supplierid = 41704
from datatrue_report.[dbo].[StoreTransactions] w
where TransactionTypeID in (5,8)
and SupplierID = 40558

select *
--update p set ShrinkRevision = 0
from InventoryPerpetual p
inner join
(
select distinct storeid, ProductId
from StoreTransactions
where SupplierID = 40558
and TransactionTypeID in (2)
) t
on p.StoreID = t.StoreID
and p.ProductID = t.ProductID
where 1 = 1
and ShrinkRevision <> 0
--and p.OriginalQty <> 0

select *
from InventoryPerpetual p
where 1 = 1
and ShrinkRevision <> 0

select *
--update P set p.shrinkrevision = 0
from InventoryPerpetual p
where ProductId in
(
	select distinct productid
	from StoreTransactions t
	where t.ProductID in 
	(
	select productid
	from InventoryPerpetual p
	where 1 = 1
	and ShrinkRevision <> 0
	)
	and supplierid = 40558
)
and shrinkrevision <> 0

select *
from InventoryPerpetual p
inner join 
(
select distinct storeid, ProductId
from StoreTransactions t
where TransactionTypeID = 11
and supplierid = 40562
) t
on p.StoreID = t.StoreID
and p.ProductID = t.ProductID
order by SBTSales desc

update InventoryPerpetual
set ShrinkRevision = 0

select *
from InventoryPerpetual
where storeid = 40460
and productid = 5505

select *
--update t set TransactionStatus = 0
from StoreTransactions t
where TransactionTypeID = 11
and supplierid = 40561
and CAST(saledatetime as date) = '12/5/2011'


--40509	5511	0

select *
from StoreTransactions
where StoreID = 40509
--and ProductID =	5511
and BrandID =	0
and CAST(saledatetime as date) >= '12/1/2011'
order by Saledatetime

select TransactionTypeID, case when TransactionTypeID in (2,6,7,16,8) then Qty * -1 else Qty end, Saledatetime
from StoreTransactions
where StoreID = 40509
and ProductID =	5511
and BrandID =	0
and CAST(saledatetime as date) >= '12/1/2011'
order by Saledatetime


/*
--SHM 12/5 count=119 COHQty=5 
--sales 2529, deliveries 2570, pickups 168   119 - 2529 + 2570 -168 = -8 Shrink = 5 - -8 = 13
declare @storeid int=40509
declare @productid int=5511
declare @brandid int = 0
declare @saledatetime date='12/5/2011'
declare @countbeforesales bit = 1
declare @countbeforedeliveries bit = 1
--sales
		select SUM(Qty)
		from [dbo].[StoreTransactions]
		where StoreID = @storeid
		and ProductID = @productid
		and BrandID = @brandid
		and TransactionTypeID in (2,6,7,16) --2 is POS sales
		and SaleDateTime >= case when @countbeforesales = 1 then cast(@saledatetime as DATE) else cast(DATEADD(day,1,@saledatetime) as DATE) end
		and TransactionStatus > 1
		and TransactionStatus not in (Select StatusIntValue from Statuses where StatusTypeID = 9) --KilledStoreTransactionStatus is type 9
--deliveries
		select SUM(Qty)
		from [dbo].[StoreTransactions]
		where StoreID = @storeid
		and ProductID = @productid
		and BrandID = @brandid
		and TransactionTypeID in (5,4,9,20) --5 is SUP deliveries
		and SaleDateTime >= case when @countbeforedeliveries = 1 then cast(@saledatetime as DATE) else cast(DATEADD(day,1,@saledatetime) as DATE) end
		and TransactionStatus > 1
		and TransactionStatus not in (Select StatusIntValue from Statuses where StatusTypeID = 9) --KilledStoreTransactionStatus is type 9
--pickups
		select SUM(Qty)
		from [dbo].[StoreTransactions]
		where StoreID = @storeid
		and ProductID = @productid
		and BrandID = @brandid
		and TransactionTypeID in (8,13,14,21) --8 is SUP pickups
		and SaleDateTime >= case when @countbeforedeliveries = 1 then cast(@saledatetime as DATE) else cast(DATEADD(day,1,@saledatetime) as DATE) end
		and TransactionStatus > 1
		and TransactionStatus not in (Select StatusIntValue from Statuses where StatusTypeID = 9) --KilledStoreTransactionStatus is type 9
	
*/
select *
from ProductPrices p
where StoreID = 40457
and ProductID = 5423

select *
from storetransactions_working
where WorkingSource = 'INV'
and WorkingStatus = 0
and supplierid = 40561

select distinct custom1
from stores s
inner join
(select distinct storeid from storetransactions where SupplierID = 40561) t
on s.StoreID = t.storeid


select w.*
--update w set w.workingstatus = 5
from StoreTransactions_Working w
inner join StoreTransactions t
on w.StoreTransactionID = t.WorkingTransactionID

where 1 = 1
--and w.workingstatus = 4
and t.SupplierID = 40558
and t.TransactionTypeID in (5, 8)
and t.SaleDateTime >'11/30/2011'
order by t.SaleDateTime



select w.storeidentifier, t.StoreIdentifier
--update t set t.storeidentifier = w.storeidentifier
from StoreTransactions t
inner join StoreTransactions_Working w
on t.WorkingTransactionID = w.StoreTransactionID
where t.TransactionTypeID = 5
and t.SupplierID = 41464

select t.StoreID, s.*
--update t set t.storeid = s.storeid
from StoreTransactions t
inner join stores s
on t.StoreIdentifier = s.StoreIdentifier
where TransactionTypeID = 5
and SupplierID = 41464
and s.Custom1 = 'Shop N Save Warehouse Foods Inc'
and t.StoreID <> s.storeid

update t set t.SetupCost = p.UnitPrice,
t.SetupRetail = p.UnitRetail,
t.RuleCost = p.UnitPrice
--select p.UnitPrice, t.SetupCost, t.*
from [dbo].[StoreTransactions] t
inner join [dbo].[ProductPrices] p
on t.ProductID = p.ProductID 
and t.BrandID = p.BrandID
and t.ChainID = p.ChainID 
and t.StoreID = p.StoreID 
and t.SupplierID = p.SupplierID 
where 1 = 1
--and t.SetupCost is null
and t.TransactionTypeID = 5
and t.SupplierID = 41464
and p.ProductPriceTypeID = 3
and t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate

select custom1 from stores
where StoreID in
(
select distinct storeid
from StoreTransactions
where TransactionTypeID = 2
and SupplierID = 41464
)

select *
from StoreTransactions
where TransactionTypeID = 5
and SupplierID = 41464

select distinct storeid, productid
from StoreTransactions
where TransactionTypeID = 5
and SupplierID = 41464
and SetupCost is null


select distinct storeid, COUNT(ProductID)
from StoreTransactions
where TransactionTypeID = 5
and SupplierID = 41464
and SetupCost is null
group by storeid
order by COUNT(ProductID) desc

select ProductId, [UPC], COUNT(storetransactionid)
from StoreTransactions
where TransactionTypeID = 5
and storeid = 40962
group by productid, [UPC]
order by COUNT(storetransactionid) desc

select *
from StoreTransactions
where StoreID = 40962
and TransactionTypeID = 2

select *
from StoreTransactions
where 1 = 1
and StoreID = 41448 --40962
and TransactionTypeID = 2
and [UPC] = '024126008931'

select *
from Stores
where StoreID = 40962

select *
from Stores
where StoreIdentifier = '6018'


select *
from StoreTransactions
where TransactionTypeID = 2
and ProductID = 17235
and StoreID = 40961

select *
from ProductPrices
where ProductID = 17235
and ProductPriceTypeID  = 3
and StoreID = 40961


select * from InventorySettlementRequests

select * into import.dbo.InventorySettlementRequests_20120112 from InventorySettlementRequests

delete from InventorySettlementRequests

select * from [DataTrue_Main].[dbo].[InventorySettlementRequests] where supplierId = 41465

INSERT INTO [DataTrue_Main].[dbo].[InventorySettlementRequests]
           ([StoreNumber]
           ,[StoreID]
           ,[PhysicalInventoryDate]
           ,[InvoiceAmount]
           ,[Settle]
           ,[UnsettledShrink]
           ,[RequestingPersonID]
           ,[RequestDate]
           ,[ApprovingPersonID]
           ,[ApprovedDate]
           ,[supplierId]
           ,[retailerId]
           ,[DenialReason]
           ,[UPC]
           ,[ProductID])

select distinct storeidentifier, storeid, '1/2/2012', 0.00, 'Y', 0.00, 0, '3/7/2012', 0, '3/7/2012', 40557, 40393, '', upc, ProductID
from StoreTransactions
--from StoreTransactions_working
where SupplierID = 40557
and StoreID in (select StoreID from stores where LTRIM(rtrim(custom1)) = 'Farm Fresh Markets')
and TransactionTypeID = 11
and SaleDateTime = '1/2/2012'
--and SaleDateTime > '11/30/2011'
--and TransactionTypeID = 11

select distinct SupplierName
from datatrue_edi.dbo.X12_SuppliersDeliveriesAndInventories

select *
--update p set ShrinkRevision = 0
from InventoryPerpetual p
where ShrinkRevision <> 0

select *
--update p set ShrinkRevision = 0
from InventoryPerpetual p
inner join 
(select distinct storeid, productid
from StoreTransactions
where SupplierID = 41464
and TransactionTypeID in (5, 8, 11)) s
on p.StoreID = s.StoreID
and p.ProductID = s.ProductID

select *
from StoreTransactions
where SupplierID = 41465
and TransactionTypeID in (5, 8)

select distinct UPC
from StoreTransactions_Working
where WorkingStatus = -99


select WorkingStatus, COUNT(storetransactionid)
from StoreTransactions_Working
group by workingstatus

--Parked records in storetransactions_working
--negative 9 has 5303 old test POS records for saledate 11/14/2011
--negative 44 with SUP-S are GOP dupes 
--negative 44 with with POS are 8 GOP records from december sales dates
--negative 99 has 1566 old test POS records for saledate 11/16/2011

select distinct supplierid , workingsource
--select *
from StoreTransactions_Working
where 1 = 1
--and WorkingStatus < 5
and WorkingStatus = 0
and WorkingSource = 'POS'
--order by StoreID, ProductID, saledatetime

select *
from StoreTransactions
where SupplierID = 40558
and TransactionTypeID in (2,6,7,16)

select distinct TransactionStatus
from StoreTransactions
where SupplierID = 40558
and TransactionTypeID in (2,6,7,16)

select TransactionStatus, COUNT(storetransactionid)
from StoreTransactions
where SupplierID = 40558
and SaleDateTime > '11/30/2011'
and TransactionTypeID in (2,6,7,16)
group by TransactionStatus

select TransactionStatus, COUNT(storetransactionid)
from StoreTransactions
where SupplierID = 40558
and SaleDateTime > '11/30/2011'
and TransactionTypeID in (2,6,7,16)
group by TransactionStatus

select * 
--update x set x.recordstatus = 0
from dbo.X12_SuppliersDeliveriesAndInventories x
where RecordStatus = 0
order by invoicedate

select ActivityCode, COUNT(recordid) 
from dbo.X12_SuppliersDeliveriesAndInventories
where RecordStatus = 0
group by ActivityCode

select * from dbo.X12_SuppliersDeliveriesAndInventories
where Activitycode is null


select p.*
from InventoryPerpetual p
inner join
(
select StoreID, productid
from inventorycost
where supplierid = 40562
) c
on p.StoreID = c.StoreID
and p.ProductID = c.ProductID

select *
--delete
from InventoryPerpetual
where originatingStoreTransactionID = -21

select *
--delete
from inventorycost
where supplierid = 40558


select *
--delete
from inventorycost
order by DateTimeCreated desc

select *
--update c set supplierid = 40558
from InventoryCost c
where CAST(datetimecreated as date) = '12/27/2011'

select *
from StoreTransactions
where 1 = 1
and SupplierID = 40558
and TransactionTypeID in (2,6,7,16)
and SaleDateTime > '11/30/2011'

select distinct TransactionTypeID
from StoreTransactions
where 1 = 1
and SupplierID = 40558
and TransactionTypeID in (2,6,7,16)
and SaleDateTime > '11/30/2011'


select * from InventoryPerpetual where SBTSales > 0 and ChainID = 40393 order by DateTimeCreated desc
select * from InventoryPerpetual where Deliveries > 0 and ChainID = 40393 order by DateTimeCreated desc

select * from InventoryCost where ChainID = 40393 order by DateTimeCreated desc
select * from InventoryPerpetual where ShrinkRevision <> 0


exec prGetInbound846Inventory
exec prValidateStoresInStoreTransactions_Working_INV
exec prValidateProductsInStoreTransactions_Working_INV
exec prValidateSuppliersInStoreTransactions_Working_INV
exec prValidateSourceInStoreTransactions_Working_INV
exec prInventory_ZeroCount_ByStore_Create
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

--***************Store Matching********************
update t set t.ChainID = 40393
--select *
from [dbo].[StoreTransactions_Working] t

where 1 = 1
and WorkingStatus = 0


--select t.StoreIdentifier, s.StoreIdentifier, s.StoreID, c.ChainID
update t set t.StoreID = s.StoreID
--select s.StoreID
from [dbo].[StoreTransactions_Working] t
inner join [dbo].[Stores] s
on t.ChainID = s.ChainID 
and cast(t.StoreIdentifier as int) = cast(s.StoreIdentifier as int)
--and cast(t.StoreIdentifier as int) = cast(s.custom2 as int)
and ltrim(rtrim(s.Custom3)) = 'SS' --LWS
--and ltrim(rtrim(s.Custom3)) <> 'SS' --Bimbo
where 1 = 1
and WorkingStatus = 0
and t.StoreID is null

--select t.StoreIdentifier, s.StoreIdentifier, s.StoreID, c.ChainID
update t set t.StoreID = s.StoreID
--select s.StoreID
from [dbo].[StoreTransactions_Working] t
inner join [dbo].[Stores] s
on t.ChainID = s.ChainID 
--and cast(t.StoreIdentifier as int) = cast(s.StoreIdentifier as int)
and cast('55' + right(ltrim(rtrim(t.StoreIdentifier)), 3) as int)= ltrim(rtrim(s.custom2))
--and cast(t.StoreIdentifier as int) = cast('55' + right(ltrim(rtrim(s.custom2)), 3) as int)
--and cast(t.StoreIdentifier as int) = '55' + cast(ltrim(rtrim(s.custom2)) as int)
--and ltrim(rtrim(s.Custom3)) = 'SS' --LWS
and ltrim(rtrim(s.Custom3)) <> 'SS' --Bimbo
where 1 = 1
and WorkingStatus = 0
and t.StoreID is null

select distinct StoreIdentifier
from [dbo].[StoreTransactions_Working] t
where 1 = 1
and WorkingStatus = 0
and storeid is null

select *
from stores
where Custom2 = '55865'

select *
--update t set workingstatus = -98
from [dbo].[StoreTransactions_Working] t
where 1 = 1
and WorkingStatus = 0
and storeid is null

select distinct workingstatus
from [dbo].[StoreTransactions_Working] t


--*************Manage UPC*******************

declare @rec cursor
declare @rec2 cursor
declare @rec3 cursor
declare @upc nvarchar(50)
declare @productid int
declare @brandid int
declare @mrupc nvarchar(50)
declare @checkdigit char(1)
declare @lenofupc tinyint
declare @maintenancerequestid int
--declare @addnewproduct smallint=1
declare @itemdescription nvarchar(255)
declare @upc12 nvarchar(50)
declare @upc11 nvarchar(50)
declare @chainid int
declare @addnewproduct bit=0
declare @productfound bit
declare @approved bit
/*
select top 100 * from dbo.MaintenanceRequests where supplierid = 40567
select * from productidentifiers where productid = 16396 --16640 024126008221
	select *
	from dbo.StoreTransactions_Working w
	where 1 = 1
	and workingStatus = 1
	and productid is null
*/

set @rec = CURSOR local fast_forward FOR
	select distinct LTRIM(rtrim(upc))
	from dbo.StoreTransactions_Working w
	where 1 = 1
	and workingStatus = 1
	and LEN(upc) = 11
	
open @rec

fetch next from @rec into @mrupc

while @@FETCH_STATUS = 0
	begin
	
				set @productfound = 0
				
			
			if @productfound = 0
				begin
				
				--set @upc11 = '0' + @mrupc
				set @upc11 = @mrupc
				
				set @CheckDigit = ''
				exec [dbo].[prUtil_UPC_GetCheckDigit]
					 @upc11,
					 @CheckDigit OUT	
					 
				set @upc12 = @upc11 + @CheckDigit				
				
				
					
					select @productid = productid from ProductIdentifiers 
					where LTRIM(rtrim(identifiervalue)) = @upc12
					
					if @@ROWCOUNT > 0
						begin
							set @productfound = 1
						end					

				
				end

		  if @productfound = 1
			begin
				update dbo.StoreTransactions_Working set Productid = @productid, upc = @upc12
				where upc = @mrupc
				and WorkingStatus = 1
			end
			
		fetch next from @rec into @mrupc
	end
	
close @rec
deallocate @rec
	



return
GO
