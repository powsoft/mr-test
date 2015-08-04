USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_PDI_Job_Steps]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[prBilling_PDI_Job_Steps]
as


exec [prGetInboundPOSTransactions_PDI]

exec prValidateStoresInStoreTransactions_Working_PDI

exec [prValidateProductsInStoreTransactions_Working_PDI]

select *
from StoreTransactions_Working
where ChainID = 62597
and CAST(datetimecreated as date) = CAST(GETDATE() as date)
and WorkingStatus = -2


select *
--update w set w.productid = i.productid, w.brandid = 0, w.workingstatus = 2
from StoreTransactions_Working w
inner join ProductIdentifiers i
on '0' + SUBSTRING(upc, 1, 11) = i.IdentifierValue
and i.ProductIdentifierTypeID = 2
where ChainID = 62597
and CAST(w.datetimecreated as date) = CAST(GETDATE() as date)
and WorkingStatus = -2

select '0' + SUBSTRING('441001018920', 2, 10)

select *
from ProductIdentifiers
where IdentifierValue like '%4100101892%'
--44100101892

exec dbo.prValidateSuppliersInStoreTransactions_Working_PDI

select *
--update w set w.supplierid = 63868, w.workingstatus = 3
from StoreTransactions_Working w
where ChainID = 62597
and CAST(datetimecreated as date) = CAST(GETDATE() as date)
and WorkingStatus = -3


select distinct i.*
--select count(*)
--update w set w.ItemSKUReported = Ltrim(rtrim(i.comments))
from storetransactions_working w
inner join productidentifiers i
on w.ProductID = i.ProductId
and i.ProductIdentifierTypeID = 2
and w.workingstatus = 3
and cast(w.datetimecreated as date) = CAST(getdate() as date)
--and w.chainid = 59973
and w.ItemSKUReported is null
and Ltrim(rtrim(i.comments)) is not null

select distinct i.*
--select count(*)
--update w set w.ItemSKUReported = Ltrim(rtrim(i.comments))
--select w.*
from storetransactions_working w
inner join productidentifiers i
on w.ProductID = i.ProductId
and i.ProductIdentifierTypeID = 13
and w.workingstatus = 3
and cast(w.datetimecreated as date) = CAST(getdate() as date)
--and w.chainid = 59973
and w.ItemSKUReported is null
and Ltrim(rtrim(i.comments)) is not null

select *
--update w set itemskureported = PDIItemNumber
--select count(*)
from storetransactions_working w
inner join [DataTrue_EDI].dbo.Temp_PDI_UPC u
on w.UPC = u.upc12
and w.chainidentifier = u.chainidentifier
and cast(w.datetimecreated as date) = CAST(getdate() as date)
--and w.chainidentifier = 'MILE'
--and u.chainidentifier = 'ROCK'
and w.ItemSKUReported is null
and w.workingstatus = 3

select *
--update w set setupcost = UnitPrice
--select count(*)
from storetransactions_working w
inner join ProductPrices p
on w.StoreID = p.StoreID
and w.ProductID = p.ProductID
and w.SupplierID = p.SupplierID
and w.ItemSKUReported is null
and w.WorkingStatus = 3
and cast(w.datetimecreated as date) = CAST(getdate() as date)

select * from SupplierPackages where SupplierPackageID = 10295

select *
--update w set w.setupcost = 1.87
from StoreTransactions_Working w
where StoreTransactionID in (185860516,185860629)

select *
from [DataTrue_EDI].dbo.Temp_PDI_Costs u
where rawproductidentifier = '10485'

select *
--select count(*)
from storetransactions_working w
where 1 = 1
and w.ItemSKUReported is null
and w.workingstatus = 3
and cast(w.datetimecreated as date) = CAST(getdate() as date)
--and w.chainid = 63612

select storetransactionid, UPC, storeid, storeidentifier, productid, itemskureported, UOMQty, supplierid, chainid
,cast(null as char(1)) as Purchasable, cast(null as int) as SupplierPackageID, cast(null as money) as cost
,cast(saledatetime as date) as SaleDate, cast('1' as char(1)) as CostZoneID
into #tempPDIItemSales --drop table #tempPDIItemSales
--select top 10000 *
--select distinct workingstatus
--update w set workingstatus = 4
--select count(*)
--update w set w.workingstatus = 4
from storetransactions_working w
where 1 = 1
--and cast(w.datetimecreated as date) = '9/26/2013'
--and chainid = 59973
and workingsource = 'POS'
and workingstatus = 3
and setupcost is null
and itemskureported is not null
and cast(w.datetimecreated as date) = CAST(getdate() as date)

update t set CostZoneId = ltrim(rtrim(a.CostZoneID))
--select *
--select distinct storeidentifier
--update t set t.MarketID = 1
from #tempPDIItemSales t
inner join datatrue_edi.dbo.Temp_PDI_VendorSiteAuthorizations a
on t.Supplierid = a.datatruesupplierid
and t.ChainID = a.DatatrueChainID
and ltrim(rtrim(t.storeidentifier)) = ltrim(rtrim(siteid))


update t set t.purchasable = 'Y'
--select count(storetransactionid)
--select * --from supplierpackages
from #tempPDIItemSales t
inner join supplierpackages p
on ltrim(rtrim(t.itemskureported)) = ltrim(rtrim(p.OwnerPDIItemNo))
and t.uomqty = p.ownerpackageqty
and p.purchasable = 1
and t.purchasable is null

--select * from datatrue_edi.dbo.Temp_PDI_ItemPkg where PDIITEMNumber = '40183'
--update datatrue_edi.dbo.Temp_PDI_ItemPkg set packagequantity = replace(packagequantity, '.000', '')
update #tempPDIItemSales set uomqty = replace(uomqty, '.000', '')

update t set t.purchasable = 'Y'
--select * --from supplierpackages
--select count(storetransactionid)
from #tempPDIItemSales t
inner join datatrue_edi.dbo.Temp_PDI_ItemPkg p
on ltrim(rtrim(t.itemskureported)) = ltrim(rtrim(p.PDIItemNumber))
and cast(t.uomqty as int) = cast(p.packagequantity as int)
and ltrim(rtrim(p.purchasable)) = 'Y'

update t set t.cost = c.packagecost
--select *
from #tempPDIItemSales t
inner join [DataTrue_EDI].dbo.Temp_PDI_Costs c
on ltrim(rtrim(Itemskureported)) = ltrim(rtrim(c.PDIItemNo))
and cast(t.UOMQty as int) = cast(c.PackageQty as int)
and saledate between c.Effectivedate and isnull(c.NextEffectivedate, '12/31/2099')
and (cast(c.costzoneID as int) = cast(t.costzoneID as int) or cast(c.costzoneID as int) = 0 or cast(c.costzoneID as int) = 1)
and t.cost is null

update w set w.SetupCost = t.cost
from #tempPDIItemSales t
inner join storetransactions_working w
on t.storetransactionid = w.storetransactionid
and t.cost is not null
and w.setupcost is null


select distinct cast(saledatetime as date) as SaleDate, UPC, 
ItemSKUReported, StoreIdentifier, SupplierID, chainID
,cast(null as money) as ItemSingleCost
,cast(null as varchar(50)) as PackageCode
,cast(null as int) as RetailQty
,cast(null as money) as TotalCost
,cast('1' as char(1)) as MarketID
into #tempitemcost --drop table #tempitemcost
--select *
--select count(*)
from storetransactions_working w
--inner join costzonerelations r
--on w.storeid = r.storeid
--and w.supplierid = r.supplierid
where 1 = 1
--and w.chainid = 62597
and cast(w.datetimecreated as date) = CAST(getdate() as date)
and w.workingstatus = 3
and SetupCost is null

update t set MarketId = ltrim(rtrim(a.CostZoneID))
--select *
--select distinct storeidentifier
--update t set t.MarketID = 1
from #tempitemcost t
inner join datatrue_edi.dbo.Temp_PDI_VendorSiteAuthorizations a
on t.Supplierid = a.datatruesupplierid
and t.ChainID = a.DatatrueChainID
and ltrim(rtrim(t.storeidentifier)) = ltrim(rtrim(siteid))

select ltrim(rtrim(PDIItemNo)) as PDIItemNo, max(PackageQty) as MaxPackageQty, 
cast(null as varchar(50)) as MaxPackageCode, cast(null as money) as MaxPackageCost,CostZoneID 
,EffectiveDate, isnull(NextEffectiveDate, '12/31/2099') as NextEffectiveDate
into #tempitemmaxpackage --drop table #tempitemmaxpackage
--select *
from [DataTrue_EDI].dbo.Temp_PDI_Costs
where 1 = 1
--and ChainIdentifier = 'CTB_PDI'
--and VendorName = '114495'
and ChainIdentifier in ('MILE','MTN','ROCK','VOLT')
and orderable = 'Y'
and PDIItemNo in (select distinct ItemSKUReported from  #tempitemcost where ItemSingleCost is null)
group by ltrim(rtrim(PDIItemNo)), CostZoneID, EffectiveDate, isnull(NextEffectiveDate, '12/31/2099')


update p set p.MaxPackageCode = c.PackageCode, p.MaxPackageCost = c.PackageCost
--select *
from [DataTrue_EDI].dbo.Temp_PDI_Costs c
inner join #tempitemmaxpackage p
on c.PDIItemNo = p.PDIItemNo
and c.PackageQty = p.MaxPackageQty
and (cast(c.costzoneid as int) = cast(p.Costzoneid as int) or cast(c.costzoneid as int) = 0)
and c.EffectiveDate = p.EffectiveDate
and ChainIdentifier in ('MILE','MTN','ROCK','VOLT')
--and ChainIdentifier = 'CTB_PDI'
--and VendorName = '114495'
and orderable = 'Y'
and c.PackageCost <> 0
and MaxPackageCost is null


select *
--update c set ItemSingleCost = MaxPackageCost/MaxPackageQty, PackageCode = MaxPackageCode
from #tempitemcost c
inner join #tempitemmaxpackage p
on c.ItemSKUReported = p.PDIItemNo
and cast(marketid as int) = cast(p.costzoneid as int)
and c.saledate between p.EffectiveDate and p.NextEffectiveDate
and ItemSingleCost is null


select *
--update c set ItemSingleCost = MaxPackageCost/MaxPackageQty, PackageCode = MaxPackageCode
from #tempitemcost c
inner join #tempitemmaxpackage p
on c.ItemSKUReported = p.PDIItemNo
and (cast(p.costzoneid as int) = 1 or cast(p.costzoneid as int) = 0)
and c.saledate between p.EffectiveDate and p.NextEffectiveDate
and ItemSingleCost is null

select *
--update c set ItemSingleCost = MaxPackageCost/MaxPackageQty, PackageCode = MaxPackageCode
from #tempitemcost c
inner join #tempitemmaxpackage p
on c.ItemSKUReported = p.PDIItemNo
and cast(p.costzoneid as int) = 0
and c.saledate between p.EffectiveDate and p.NextEffectiveDate
and ItemSingleCost is null

select *
--update c set ItemSingleCost = MaxPackageCost/MaxPackageQty, PackageCode = MaxPackageCode
from #tempitemcost c
inner join #tempitemmaxpackage p
on c.ItemSKUReported = p.PDIItemNo
--and cast(marketid as int) = cast(p.costzoneid as int)
--and c.saledate between p.EffectiveDate and p.NextEffectiveDate
and ItemSingleCost is null

select *
--select itemskureported, count(*)
--select distinct itemskureported
from #tempitemcost c
where ItemSingleCost is null
and itemskureported is null
--group by itemskureported
--order by count(*) desc

select *
--update c set ItemSingleCost = MaxPackageCost/MaxPackageQty, PackageCode = MaxPackageCode
from #tempitemcost c
inner join #tempitemmaxpackage p
on c.ItemSKUReported = p.PDIItemNo
--and cast(marketid as int) = cast(p.costzoneid as int)
--and c.saledate between p.EffectiveDate and p.NextEffectiveDate
--and c.saledate >= p.effectivedate
and ItemSingleCost is null

select *
--select count(*)
--update w set SetupCost = UOMQty * c.ItemSingleCost
from storetransactions_working w
inner join #tempitemcost c
on cast(w.saledatetime as date) = cast(c.saledate as date)
and ltrim(rtrim(w.ItemSKUReported)) = ltrim(rtrim(c.ItemSKUReported))
and ltrim(rtrim(w.StoreIdentifier)) = ltrim(rtrim(c.StoreIdentifier))
and ltrim(rtrim(w.UPC)) = ltrim(rtrim(c.UPC))
--and w.supplierid = c.supplierid
and w.chainid = c.chainid
and w.SetupCost is null

select *
from StoreTransactions
where 1 = 1
and ProductID = 3479643

select *
--update w set w.setupcost = 1.02
from StoreTransactions_Working w
where 1 = 1
--and ProductID = 3479643
and CAST(datetimecreated as date) = CAST(getdate() as date)
and WorkingStatus = 3
and SetupCost is null


exec dbo.prValidateSourceInStoreTransactions_Working_PDI

exec [prValidateTransactionTypeInStoreTransactions_Working_NOMERGE_TempTables_PDI_debug]


exec dbo.prInvoiceDetail_ReleaseStoreTransactions



exec dbo.prInvoiceDetail_POS_Create_NOMERGE


/*
select top 100 * from invoicedetails order by invoicedetailid desc

select * from storesetup where chainid = 44285
*/

update d set d.pdiparticipant = 1
--select *
from InvoiceDetailS d
--where InvoiceDetailID in
--(47826701,
--47826700,
--47826699,
--47826698,
--47826697,
--47826696,
--47826695,
--47826694,
--47826693,
--47826692,
--47826691,
--47826690)
inner join storesetup ss
on d.StoreID = ss.StoreID
and d.ProductID = ss.productid
and d.SupplierID = ss.SupplierID
and ss.PDIParticipant = 1
and d.PDIParticipant =0


--update VIN,


update d set VIN = i.identifiervalue
--select *
from datatrue_edi.dbo.InvoiceDetails d
inner join productidentifiers i
on d.productid = i.productid
and d.supplierid = i.ownerentityid
and i.productidentifiertypeid = 3
where d.ChainID = 44285
--and CAST(d.DateTimeCreated as DATE) = '3/26/2013'
--order by invoicedetailid desc

select *
--update d set VIN = left(Rawproductidentifier, 10), RetailUOM = 'EACH', RetailTotalQty = TotalQty
from invoicedetails d
where InvoiceDetailID in
(47826701,
47826700,
47826699,
47826698,
47826697,
47826696,
47826695,
47826694,
47826693,
47826692,
47826691,
47826690)

select *
from ProductIdentifiers
where 1 = 1
and ProductID in
(31426,
31427,
31428,
31429,
31430,
31431,
31432,
31433,
31434,
31435,
31436,
31437)

select *
--select distinct retailerinvoiceid
--update d set recordstatus = 35, recordstatussupplier = 35
--update d set pdiparticipant = 1
--update d set d.vin = cast(supplierid as nvarchar) + cast(productid as nvarchar)
--update d set RetailTotalQty = TotalQty, RetailUOM = 'EACH'
--select sum(totalcost)
from datatrue_edi.dbo.InvoiceDetails d
where ChainID = 44285
and RetailerInvoiceID = 1881189
and CAST(DateTimeCreated as DATE) = '3/23/2013'
and supplierid = 44268
and VIN is null

--50725





 
exec [dbo].[prInvoices_POS_Retailer_Create_PDI]


exec dbo.prBilling_EDIDatabase_Sync

return

/*

exec dbo.prSendEmailNotification_PassEmailAddresses 'Daily Billing Job Started'
,'Retailer and supplier invoicing has started for today''s POS files'
,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;Edi@icontroldsd.com'
go
--exec [dbo].[prGetInboundPOSTransactions_DollarGeneral]
--go
--exec dbo.prValidateStoresInStoreTransactions_Working
--go
exec dbo.prGetInboundPOSTransactions_ForJEWELandSHAWS
go
exec dbo.prGetInboundPOSTransactions
go
--exec dbo.[prGetInboundPOSTransactions_ForSourceInterlink]
--go
exec dbo.prValidateStoresInStoreTransactions_Working
go
--exec dbo.prPOS_Billing_SYNC_BANNER_RESTORE
--go
exec dbo.prValidateProductsInStoreTransactions_Working
go
exec dbo.prValidateSuppliersInStoreTransactions_Working
go
exec dbo.prPOS_Supplier_Info_PopulateWhenNull
go
exec dbo.prValidateSourceInStoreTransactions_Working
go
exec dbo.prValidateAuthorizedStores
go
exec dbo.prValidateAuthorizedItems
go
exec dbo.prPOS_Dupe_Check
go
------exec dbo.prValidateTransactionTypeInStoreTransactions_Working
------go

exec dbo.prValidateTransactionTypeInStoreTransactions_Working_NOMERGE_TempTables
go

--exec dbo.prValidateTransactionTypeInStoreTransactions_Working_NOMERGE
--go
exec dbo.prSendEmailNotification_PassEmailAddresses 'Daily Billing Job - Storetransactions Records Inserted'
,'Storetransactions Records Inserted'
,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'
go

exec dbo.prStoreTransactions_NewRecord_Status_Manage_Special
go

exec dbo.prInvoiceDetail_ReleaseStoreTransactions
go
--exec dbo.[prInvoiceDetail_ReleaseStoreTransactions_ForSourceInterlink]
--go
exec dbo.prInvoiceDetail_POS_Create_NOMERGE
go
exec dbo.prSendEmailNotification_PassEmailAddresses 'Daily Billing Job - InvoiceDetails Inserted'
,'InvoiceDetails Inserted'
,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'
go
exec dbo.prInvoices_POS_Retailer_Create_ABS_SV_20111218
go
--exec dbo.prInvoices_POS_Supplier_Create_ABS_SV_20111218
--go
exec dbo.prSendEmailNotification_PassEmailAddresses 'Daily Billing Job - ABS and SV Invoiced'
,'ABS and SV Invoiced'
,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'
go
exec dbo.prInvoices_POS_Retailer_Create_SS_A_20111218
go
--exec dbo.prInvoices_POS_Supplier_Create_SS_A_20111218
--go
exec dbo.prSendEmailNotification_PassEmailAddresses 'Daily Billing Job - SS A Invoiced'
,'SS A Invoiced'
,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'
go
exec dbo.prInvoices_POS_Retailer_Create_SS_B_20111218
go
--exec dbo.prInvoices_POS_Supplier_Create_SS_B_20111218
--go


exec prBilling_EDIDatabase_Sync
go

exec prBilling_Invoices_Statuses_Special_Manage
go

exec dbo.prSendEmailNotification_PassEmailAddresses 'Daily Billing Job Complete'
,'All retailer and supplier invoicing has been completed for today''s POS files'
,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;Edi@icontroldsd.com'
go

update h set h.OriginalAmount = d.IDSum, h.OpenAmount = d.IDSum
 from InvoicesRetailer h
 inner join
 (
 select retailerinvoiceid, SUM(totalcost) as IDsum
 from datatrue_main.dbo.Invoicedetails
 where 1 = 1
 --and InvoiceDetailTypeID = 11
 --and saledate > '11/30/2011'
 group by RetailerInvoiceID
 ) d
 on h.RetailerInvoiceID = d.RetailerInvoiceID
 and d.IDSum <> h.OriginalAmount
go

update h set h.OriginalAmount = d.IDSum, h.OpenAmount = d.IDSum
 from datatrue_edi.dbo.InvoicesRetailer h
 inner join
 (
 select retailerinvoiceid, SUM(totalcost) as IDsum
 from datatrue_main.dbo.Invoicedetails
 where 1 = 1
 --and InvoiceDetailTypeID = 11
 --and saledate > '11/30/2011'
 group by RetailerInvoiceID
 ) d
 on h.RetailerInvoiceID = d.RetailerInvoiceID
 and d.IDSum <> h.OriginalAmount
go
exec prDailyPOSBillingCompleteUpdate
go

exec [dbo].[prProcessPOSForShrinkReversal]
go

exec [dbo].[prInventory_WAVG_ProcessTransactions]
go

--exec [dbo].[prInventory_FIFO_ProcessTransactions]
--go

exec [dbo].[prApplyPOSStoreTransactionsToInventory]
go

exec [dbo].[prApplyShrinkReversalToInventory]
go

--exec prProducts_Brands_Manage
--go

				update s set s.BillingIsRunning = 2
				from [DataTrue_EDI].[dbo].[ProcessStatus] s
				where upper(ltrim(rtrim(ChainName))) = 'SV'
				and CAST(date as date) = cast(getdate() as date)
				and isnull(BillingComplete, 0) = 1
				and ISNULL(BillingIsRunning, 0) = 1
				and isnull(AllFilesReceived, 0) = 1
go


*/
GO
