USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Research_Billing]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Research_Billing]

as

select *
from InvoiceDetails
where DateTimeCreated > '1/9/2012'
and InvoiceDetailTypeID = 1

select *
from datatrue_edi.dbo.InvoiceDetails
where DateTimeCreated > '1/9/2012'
and InvoiceDetailTypeID = 1


--select *
select COUNT(storetransactionid)
--select distinct TransactionStatus
from StoreTransactions [no lock]
where 1 = 1
--and storeidentifier = '6706'
and SaleDateTime >= '1/8/2012'
--and Banner = 'SS'
--and PONo = '105402'
and TransactionStatus = 0

-- 59231 4707

--select *
select COUNT(storetransactionid)
--select distinct workingstatus
from StoreTransactions_working [no lock]
where 1 = 1
--and Transactiontypeid in (2,6)
and SaleDateTime >= '1/8/2012'
--and storeidentifier = '6706'
--and SaleDateTime >= '12/21/2011'
--and PONo = '105402'
--and TransactionStatus = 0

select *
from StoreTransactions [no lock]
where 1 = 1
and Transactiontypeid in (2,6)
and DateTimeCreated > '12/23/2011'
order by transactionstatus
--and storeidentifier = '6706'
--and SaleDateTime >= '12/21/2011'
--and PONo = '105402'

select *
from datatrue_edi.dbo.InvoiceDetails [No Lock]
where 1 = 1
--and DateTimeCreated > '12/23/2011'
and saledate = '1/8/2012'


select banner, pono, sum(qty) AS posqty
from datatrue_edi.dbo.Inbound852Sales
where cast(datetimereceived as date) = '1/9/2012'
and Banner in ('ABS','SV','SS')
group by banner, PONo


--select *
select Banner, PONo, SUM(totalqty)
from datatrue_edi.dbo.InvoiceDetails [No Lock]
where 1 = 1
and InvoiceDetailTypeID = 1
and cast(DateTimeCreated as date) = '1/9/2012'
group by Banner, pono

select *
from datatrue_edi.dbo.InvoiceDetails [No Lock]
where 1 = 1
and InvoiceDetailTypeID = 1
and cast(DateTimeCreated as date) = '1/9/2012'
and pono not in
(
select distinct pono
from datatrue_edi.dbo.Inbound852Sales
where cast(datetimereceived as date) = '1/9/2012'
and Banner in ('ABS','SV','SS')
)



select banner, pono, sum(qty) AS posqty
from datatrue_edi.dbo.Inbound852Sales
where cast(datetimereceived as date) = '1/9/2012'
and Banner in ('ABS','SV','SS')
group by banner, PONo

select top 10 *
from InvoiceDetails
order by DateTimeCreated desc


select Banner, PONo, SUM(totalqty) as detailqty
from datatrue_edi.dbo.InvoiceDetails [No Lock]
where 1 = 1
and InvoiceDetailTypeID = 1
and cast(DateTimeCreated as date) = '1/9/2012'
group by Banner, pono



select banner, pono, sum(qty) AS posqty
into #temppos
from datatrue_edi.dbo.Inbound852Sales

where cast(datetimereceived as date) = '1/9/2012'
and Banner in ('ABS','SV','SS')
group by banner, PONo

select *
from #temppos a
inner join 
(select Banner, PONo, SUM(totalqty) as detailqty
from datatrue_edi.dbo.InvoiceDetails [No Lock]
where 1 = 1
and InvoiceDetailTypeID = 1
and cast(DateTimeCreated as date) = '1/9/2012'
group by Banner, pono)b
on a.banner = b.banner
and isnull(a.pono, 0) = isnull(b.pono, 0)
where posqty <> detailqty



select *
from datatrue_edi.dbo.Inbound852Sales
where 1 = 1
--and storeidentifier = '6706'
and SaleDate >= '12/20/2011'
and PONo = '120229'
--and StoreIdentifier = '31274'
and SupplierIdentifier = '5263637'
order by ProductIdentifier

select *
from StoreTransactions_working
where 1 = 1
--and storeidentifier = '6706'
and SaleDateTime >= '12/20/2011'
and PONo = '120229'
and StoreIdentifier = '31274'
and SupplierIdentifier = '5263637'
order by UPC

select *
from StoreTransactions_working
where 1 = 1
--and 5163422

select *
from StoreTransactions
where 1 = 1
--and storeidentifier = '6706'
and SaleDateTime >= '12/20/2011'
and PONo = '120229'
and StoreIdentifier = '31274'
and SupplierIdentifier = '5263637'
order by UPC

--order by DateTimeCreated desc

select *
from InvoiceDetailS
where 1 = 1
--and storeidentifier = '6706'
and SaleDate >= '12/20/2011'
and PONo = '120229'
and StoreIdentifier = '31274'
and SupplierIdentifier = '5263637'


select *
from ChainProductFactors
where ProductID = 4949


select * from InvoiceDetailS
where BatchID = '1557'

select *
from StoreTransactions_Working
where storeidentifier = '6706'
and SaleDateTime <= '12/20/2011'
and PONo in ('105402','105404')
and WorkingStatus = -6
order by RawProductIdentifier
--order by DateTimeCreated desc

select *
from StoreTransactions
where StoreID = 41179
and ProductID = 5700
and CAST(saledatetime as date) = '12/19/2011'

select *
from datatrue_edi.dbo.Inbound852Sales
where PONo = '105402'
and Saledate = '12/20/2011'

select *
from RelatedTransactions
order by DateTimeCreated


select *
from datatrue_edi.dbo.Inbound852Sales
where PONo = '105402'
and Saledate = '12/20/2011'

select *
from StoreTransactions_Working
where 1 = 1
and SaleDateTime = '12/20/2011'
and PONo in ('105402')

select *
from StoreTransactions
where 1 = 1
and SaleDateTime = '12/20/2011'
and PONo in ('105402')

select *
from InvoiceDetails [No Lock]
where 1 = 1
and SaleDate = '12/21/2011'
and PONo in ('105402')


select *
from datatrue_edi.dbo.InvoiceDetails [No Lock]
where 1 = 1
and SaleDate = '12/21/2011'




select * into import.dbo.invoicedetails_20120109 from InvoiceDetailS
select * into import.dbo.invoicesretailer_20120109 from invoicesretailer
select * into import.dbo.invoicessupplier_20120109 from invoicessupplier
select *
--delete 
from InvoicesRetailer where RetailerInvoiceID in (select RetailerInvoiceID from InvoiceDetailS where Banner = 'SS' and CAST(saledate as date) <> '12/1/2011')
select *
--delete 
from InvoicesSupplier where SupplierInvoiceID in (select SupplierInvoiceID from InvoiceDetailS where Banner = 'SS' and CAST(saledate as date) <> '12/1/2011')

select*
--delete 
from InvoiceDetailS where Banner = 'SS' and CAST(saledate as date) <> '12/1/2011'
--EDI**********************************************
select * into import.dbo.invoicedetailsEDI_20120109 from datatrue_edi.dbo.InvoiceDetailS
select * into import.dbo.invoicesretailerEDI_20120109 from datatrue_edi.dbo.invoicesretailer
select * into import.dbo.invoicessupplierEDI_20120109 from datatrue_edi.dbo.invoicessupplier
select *
--delete 
from datatrue_edi.dbo.InvoicesRetailer where RetailerInvoiceID in (select RetailerInvoiceID from datatrue_edi.dbo.InvoiceDetailS where CAST(DateTimeCreated as date) = '1/9/2012')
select *
--delete 
from datatrue_edi.dbo.InvoicesSupplier where SupplierInvoiceID in (select SupplierInvoiceID from datatrue_edi.dbo.InvoiceDetailS where Banner = 'SS' and CAST(saledate as date) <> '12/1/2011')

select*
--delete 
from datatrue_edi.dbo.InvoiceDetailS where Banner = 'SS' and CAST(saledate as date) <> '12/1/2011'
--*************************************************


select *
--update w set w.workingstatus = 4 
from StoreTransactions_Working w where Banner = 'SS' and CAST(saledatetime as date) <> '12/1/2011'

select *
--update w set setupcost = null, setupretail = null, rulecost = null, ruleretail = null, costmismatch = 0, retailmismatch = 0, productpricetypeid = null, promotypeid = null, promoallowance = null
from StoreTransactions_Working w where w.workingstatus = 4  and Banner = 'SS' and CAST(saledatetime as date) <> '12/1/2011'




select * 
from StoreTransactions
where 1 = 1
and ChainID = 40393 
and StoreID not in (41000, 41001, 41002)
and SupplierID not in (41440)
and CAST(saledatetime as date) >= '11/30/2011'
 and Qty <> 0
and TransactionStatus in (0, 2)
and TransactionTypeID in (2,6)

select * 
from StoreTransactions
where 1 = 1
and ChainID = 40393 
and StoreID in (41000, 41001, 41002)
--and SupplierID in (41440)
and CAST(saledatetime as date) = '1/8/2012'
 --and Qty = 0
and TransactionStatus in (0, 2)
and TransactionTypeID in (2,6)
/*
5554863

6706
 105402
 7203000271
 4871
 
6706
 105402
 7313001237
 4871
 
6706
 105402
 7341013835
 4871
 
6706
 105404
 7255411120
 105562
 */
GO
