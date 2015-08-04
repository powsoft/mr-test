USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_GoLive_SupValu]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_GoLive_SupValu]
as

/*4371 3452 919
16805
34144
125
*/



UPDATE [DataTrue_Main].[dbo].[BillingControl]
   SET [BillingControlNumberOfPastDaysToRebill] = 18
      ,[InvoiceSeparation] = 3
      ,[LastBillingPeriodEndDateTime] = '12/17/2011'
      ,[NextBillingPeriodEndDateTime] = '12/18/2011'
      ,[NextBillingPeriodRunDateTime] = '12/19/2011'
 WHERE BillingControlID > 14
 
 select banner, filename, saledate, COUNT(recordid)
from datatrue_edi.dbo.Inbound852Sales
where RecordStatus = 0
and Qty <> 0
group by banner, filename, saledate

 select storeidentifier, ProductIdentifier, cast(SaleDate as date), ltrim(rtrim(PONO)), COUNT(recordid)
from datatrue_edi.dbo.Inbound852Sales
where 1 = 1
and RecordStatus = 0
--and banner = 'SS'
--and CAST(saledatetime as date) = '11/21/2011'
group by storeidentifier, ProductIdentifier, cast(SaleDate as date), ltrim(rtrim(PONO))
having COUNT(recordid) > 1

 select *
--update s set recordstatus = -5
from datatrue_edi.dbo.Inbound852Sales s
where RecordStatus = 0
and Banner = 'SYNC'
 
 
     select distinct ltrim(rtrim(UPC))
 from StoreTransactions_Working w
  where workingStatus = 1
  and ltrim(rtrim(UPC))
  not in 
(select ltrim(rtrim(identifiervalue)) from ProductIdentifiers)
 
  select storeid, productid, storeidentifier, upc, cast(SaleDateTime as date)--, COUNT(storetransactionid)
from StoreTransactions_Working
where 1 = 1
and WorkingStatus = 4
 
 select storeid, productid, storeidentifier, upc, cast(SaleDateTime as date), ltrim(rtrim(PONO)), COUNT(storetransactionid)
from StoreTransactions_Working
where 1 = 1
and WorkingStatus = 4
--and banner = 'SS'
--and CAST(saledatetime as date) = '11/21/2011'
group by storeid, productid, storeidentifier, upc, cast(SaleDateTime as date), ltrim(rtrim(PONO))
having COUNT(storetransactionid) > 1
 
 
 INSERT INTO [DataTrue_Main].[dbo].[ChainProductFactors]
           ([ChainID]
           ,[ProductID]
           ,[BrandID]
           ,[BaseUnitsCalculationPerNoOfweeks]
           ,[CostFromRetailPercent]
           ,[BillingRuleID]
           ,[IncludeDollarDiffDetails]
           ,[ActiveStartDate]
           ,[ActiveEndDate]
           ,[LastUpdateUserID])
select 40393
		,ProductId
		,0
		,17
		,75
		,1
		,1
		,'2000-01-01 00:00:00'
		,'12/31/2025'
		,2
from Products
where ProductID not in (select productid from ChainProductFactors)


select * from datatrue_edi.dbo.EDI_SupplierCrossReference


select storeidentifier, upc, cast(SaleDateTime as date)
from StoreTransactions_Working
where 1 = 1
and WorkingStatus = 4

select storeidentifier, upc, cast(SaleDateTime as date)
--select *
from StoreTransactions_Working
where 1 = 1
and WorkingStatus = 4

and (SupplierID = 0 or SupplierID is null)
and StoreIdentifier = '0006017'
and [UPC]= '072945761452'
order by saledatetime

select top 20000 * from StoreTransactions order by DateTimeCreated desc
select top 20000 * from StoreTransactions_working order by DateTimeCreated desc


--POS Invoicing Job
/*
exec dbo.prGetInboundPOSTransactions
go
exec dbo.prValidateStoresInStoreTransactions_Working
go
exec dbo.prValidateProductsInStoreTransactions_Working
go
exec dbo.prValidateSuppliersInStoreTransactions_Working
go
exec dbo.prValidateSourceInStoreTransactions_Working
go
exec dbo.prValidateTransactionTypeInStoreTransactions_Working
go
exec dbo.prInvoiceDetail_ReleaseStoreTransactions
go
exec dbo.prInvoiceDetail_POS_Create
go
exec dbo.prInvoices_POS_Retailer_Create_ABS_SV_20111218
go
exec dbo.prInvoices_POS_Supplier_Create_ABS_SV_20111218
go
exec dbo.prInvoices_POS_Retailer_Create_SS_A_20111218
go
exec dbo.prInvoices_POS_Supplier_Create_SS_A_20111218
go
exec dbo.prInvoices_POS_Retailer_Create_SS_B_20111218
go
exec dbo.prInvoices_POS_Supplier_Create_SS_B_20111218
*/


--POSAdj cost differences Invoicing Job
/*
exec dbo.prUtil_Price_Corrections_Adjustments_Run_20111216
go
exec dbo.prInvoiceDetail_ReleaseStoreTransactions
go
exec dbo.prInvoiceDetail_POSADJ_Create
go
exec dbo.prInvoices_POSADJ_Retailer_Create_ABS_SV_20111218
go
exec dbo.prInvoices_POSADJ_Supplier_Create_ABS_SV_20111218
go
exec dbo.prInvoices_POSADJ_Retailer_Create_SS_A_20111218
go
exec dbo.prInvoices_POSADJ_Supplier_Create_SS_A_20111218
go
exec dbo.prInvoices_POSADJ_Retailer_Create_SS_B_20111218
go
exec dbo.prInvoices_POSADJ_Supplier_Create_SS_B_20111218
*/


select distinct WorkingStatus--, * 
--select *
from StoreTransactions_Working
where banner = 'SS'
and CAST(saledatetime as date) = '12/8/2011'

select storeid, productid, storeidentifier, upc, cast(SaleDateTime as date), COUNT(storetransactionid)
from StoreTransactions_Working
where 1 = 1
and WorkingStatus = 4
--and banner = 'SS'
--and CAST(saledatetime as date) = '11/21/2011'
group by storeid, productid, storeidentifier, upc, cast(SaleDateTime as date)
having COUNT(storetransactionid) > 1
--41447	16921	6017	072945761452	2011-12-07	2
select *
from StoreTransactions_Working
where 1 = 1
and WorkingStatus = 4
and storeid = 41447
and ProductID =	16921

select w.reportedcost, t.reportedcost, w.qty, t.qty, w.*
from StoreTransactions_Working w
inner join StoreTransactions t
on w.StoreID = t.StoreID
and w.ProductID = t.ProductID
and CAST(w.saledatetime as date) = CAST(t.saledatetime as date)
and w.SupplierID = t.SupplierID
where w.WorkingStatus = 4

select MAX(datetimecreated) from StoreTransactions_Working
select top 60000 * from StoreTransactions_Working order by datetimecreated desc

select * from InvoiceDetailS
where StoreID = 41447
and ProductID =	16921
and SupplierID =	41465

select *
from StoreTransactions
where supplierid = 40578


select *
from InvoiceDetailS
where SaleDate = '11/30/2011'
and cast(DateTimeCreated as date) = '12/3/2011'

select *
from InvoiceDetailS
where RetailerInvoiceID = 56458

select *
from StoreTransactions
where Banner = 'ABS'
and SaleDateTime = '12/1/2011'
order by PromoAllowance desc

select *
from StoreTransactions
where Banner in ('ABS','SV')
and SaleDateTime = '12/1/2011'
and ReportedAllowance > 0
and PromoAllowance is null
order by ReportedAllowance desc

select *
from StoreTransactions
where Banner = 'SS'
and SaleDateTime = '12/3/2011'
--and ReportedAllowance > 0
and PromoAllowance is not null
--order by ReportedAllowance desc

select *
from StoreTransactions_Working w
where WorkingStatus = 4

select *
--update w set workingstatus = 4
from StoreTransactions_Working w
where WorkingStatus = -77

select * 
into Import.dbo.Inbound852Sales_20111202_AtSVGoLive
from datatrue_edi.dbo.Inbound852Sales
where RecordStatus <> 0

/*
--delete
from datatrue_edi.dbo.Inbound852Sales
where RecordStatus <> 0
*/
select *
--delete
from datatrue_edi.dbo.Inbound852Sales
where filename = 'SVEC.20111130134350_SPLIT7'

select *
--update s set recordstatus = -5
from datatrue_edi.dbo.Inbound852Sales s
where RecordStatus = 0
and Banner = 'SYNC'

update s set recordstatus = 1
from datatrue_edi.dbo.Inbound852Sales s
where RecordStatus = 0
and Saledate < '12/2/2011'
and Qty = 0

select distinct banner, filename, saledate
from datatrue_edi.dbo.Inbound852Sales
where RecordStatus = 0
and Qty <> 0

select banner, filename, saledate, COUNT(recordid)
from datatrue_edi.dbo.Inbound852Sales
where RecordStatus = 0
and Qty <> 0
group by banner, filename, saledate

select *
from datatrue_edi.dbo.Inbound852Sales
where RecordStatus = 0
and Saledate = '12/5/2011'

select distinct banner, sourceidentifier, saledatetime
from StoreTransactions_working 
where workingstatus = 0
and Qty <> 0

select * from datatrue_edi.dbo.Inbound852Sales where banner = 'sync'

--product audit


    select distinct ltrim(rtrim(UPC))
 from StoreTransactions_Working w
  where workingStatus = 1
  and ltrim(rtrim(UPC))
  not in 
(select ltrim(rtrim(identifiervalue)) from ProductIdentifiers)


    select *
 from StoreTransactions_Working
  where workingStatus = 1
  and substring(ltrim(rtrim(UPC)), 2, 10)
  not in 
(select substring(ltrim(rtrim(identifiervalue)), 2, 10) from ProductIdentifiers)
--and SUBSTRING(g.productid, 2, 10) = substring(t.ProductIdentifier, 2, 10)

    select w.UPC, i.IdentifierValue, i.productid
    --update i set i.identifiervalue = ltrim(rtrim(w.UPC))
 from StoreTransactions_Working w
 inner join ProductIdentifiers i
 on substring(ltrim(rtrim(w.UPC)), 2, 10) = substring(ltrim(rtrim(i.IdentifierValue)), 2, 10)
  where workingStatus = 1
  and ltrim(rtrim(UPC))
  not in 
(select ltrim(rtrim(identifiervalue)) from ProductIdentifiers)


    select w.UPC, i.IdentifierValue, i.productid
    --update i set i.identifiervalue = ltrim(rtrim(w.UPC))
 from StoreTransactions_Working w
 inner join ProductIdentifiers i
 on substring(ltrim(rtrim(w.UPC)), 2, 10) = substring(ltrim(rtrim(i.IdentifierValue)), 1, 11)
  where workingStatus = 1
  and ltrim(rtrim(UPC))
  not in 
(select ltrim(rtrim(identifiervalue)) from ProductIdentifiers)


--Allowance Audit
/*
select * from productprices where productpricetypeid = 8 and storeid = 41021 and ProductId = 18568 and supplierid = 
select * from productprices where productpricetypeid = 8 and storeid = 41021 and ProductId = and supplierid = 
select * from productprices where productpricetypeid = 8 and storeid = 41021 and ProductId = and supplierid = 
select * from productprices where productpricetypeid = 8 and storeid = 41021 and ProductId = and supplierid = 
select * from productprices where productpricetypeid = 8 and storeid = 41021 and ProductId = and supplierid = 
select * from productprices where productpricetypeid = 8 and storeid = 41021 and ProductId = and supplierid = 
*/
/*
41021	18568	40557
41151	18516	40557
41021	5911	40557
41174	18568	40557
41134	18558	40557
41136	18518	40557
41136	18569	40557
41023	18569	40557
41205	5909	40557
41197	5909	40557
41217	18558	40557
41048	18519	40557
41038	18519	40557
41018	18558	40557
41208	18511	40557
41076	18569	40557
41208	18518	40557
41018	5909	40557
41091	18569	40557
41158	18516	40557
41184	5909	40557

*/

select *
from StoreTransactions
where SupplierID = 40578


SELECT SUM(OriginalAmount)
from InvoicesRetailer
where InvoicePeriodStart = '11/26/2011'
--and InvoicePeriodEnd = '12/26/2011'
and RetailerInvoiceID in
(
select RetailerInvoiceID
from InvoiceDetailS
where Banner = 'SS'
and SaleDate = '11/26/2011'
)

select SUM(TotalQty * UnitCost), SUM(TotalCost)
from InvoiceDetailS
where Banner = 'SS'
and SaleDate = '11/26/2011'

select *
from InvoiceDetailS
where RawProductIdentifier = '24126008993'
and left(RawProductIdentifier, 11) = '24126008993'

--pricing audit
--first review where ABS and SV when no Allowance or promoallowance


select distinct storeid, productid, supplierid, upc, SetupCost as SC, ReportedCost as RC, ReportedAllowance as RA, PromoAllowance as PA--, *
--select distinct UPC--, storeid
from StoreTransactions
where ChainID = 40393
and SetupCost <> ReportedCost
and SaleDateTime = '12/2/2011'
and PromoAllowance is null
and Banner in ('ABS','SV')
and ReportedAllowance = 0
order by ProductID, StoreID, supplierid
--40424	5071
	

declare @storeid int= 40404
declare @productid int=5066
select * from stores where StoreID = @storeid
select * from ProductPrices where StoreID = @storeid and ProductID =	@productid
select top 1000 * from SuppliersSetupData where StoreID = @storeid and ProductID = @productid
select top 1000 * from IMport.dbo.tmpchainsetupbaseplus where StoreID = @storeid and ProductID = @productid
select top 1000 * from IMport.dbo.tmpchainsetupbaseplus2 where StoreID = @storeid and ProductID = @productid
select top 1000 * from IMport.dbo.tmpchainsetupbaseplus3 where StoreID = @storeid and ProductID = @productid
select top 1000 * from Import.dbo.SBTCostAllowanceBook where dtproductid = @productid
select top 1000 * from dbo.SuppliersSetupDataMore where datatrueproductid = @productid
select top 1000 * from Import.dbo.SuppliersSetupDataPlus where dtproductid = @productid
select top 1000 * from dbo.SuppliersSetupDataMoreNestle where DataTrueProductID = @productid
select top 1000 * from import.dbo.tmpPromotionsGilad where datatrueproductid = @productid
select top 1000 * from import.dbo.tmpPromotionsGiladNestle where datatrueproductid = @productid
select top 1000 * from dbo.SV_CostFile where dtStoreID = @storeid and dtProductID = @productid


select top 1000 * from dbo.PromotionsGilad
select top 1000 * from dbo.PromotionsGiladNestle


select * from suppliers where supplierid = 40557


	


select SetupCost as SC, ReportedCost as RC, ReportedAllowance as RA, *
from StoreTransactions
where ChainID = 40393
and SetupCost <> ReportedCost
and SaleDateTime >= '12/1/2011'
and PromoAllowance is null
order by ReportedAllowance desc

select SetupCost as SC, ReportedCost as RC, ReportedAllowance as RA, PromoAllowance as PA, *
from StoreTransactions
where ChainID = 40393
and SetupCost - PromoAllowance <> ReportedCost
and SaleDateTime >= '12/2/2011'
and PromoAllowance is not null
order by ReportedAllowance desc

select distinct UPC
from StoreTransactions
where ChainID = 40393
and SetupCost - PromoAllowance <> ReportedCost
and SaleDateTime >= '12/2/2011'
and PromoAllowance is not null
--order by ReportedAllowance desc

--look for setupcosts not matching

select distinct storeid, productid, supplierid, upc, SetupCost as SC, ReportedCost as RC, ReportedAllowance as RA, PromoAllowance as PA--, *
--select distinct UPC--, storeid
from StoreTransactions
where ChainID = 40393
and cast(SetupCost - PromoAllowance as DEC(12,2)) <> Cast(ReportedCost as DEC(12,2))
and ReportedAllowance = PromoAllowance
and SaleDateTime = '12/2/2011'
and PromoAllowance is not null
order by UPC, StoreID, supplierid desc

return
GO
