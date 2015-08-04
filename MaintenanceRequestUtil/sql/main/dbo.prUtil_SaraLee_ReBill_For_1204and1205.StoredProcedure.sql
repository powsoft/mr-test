USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_SaraLee_ReBill_For_1204and1205]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_SaraLee_ReBill_For_1204and1205]
as

select * into import.dbo.storetransactions_working_20111207b_BeforeSaraLeeReBill1204and1205 from storetransactions_working
select * into import.dbo.storetransactions_20111207b_BeforeSaraLeeReBill1204and1205 from storetransactions

select t.PromoAllowance, p.UnitPrice, *
--update t set t.PromoAllowance = p.UnitPrice, t.PromoTypeID = P.ProductPriceTypeID
from [dbo].[StoreTransactions_Working] t
inner join [dbo].[ProductPrices] p
on t.ProductID = p.ProductID 
and t.BrandID = p.BrandID
and t.ChainID = p.ChainID 
and t.StoreID = p.StoreID 
and t.SupplierID = p.SupplierID 
where p.ProductPriceTypeID in 
(8, 9, 10) --2 is Chain Entity
and t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate
and CAST(saledatetime as date) = '12/5/2011'
and t.SupplierID = 41465
and t.PromoAllowance <> p.UnitPrice
and t.Banner = 'SS'

select * into Import.dbo.InvoiceDetails_20111207b_BeforeSARALEEREbill1204and1205 from invoicedetails
select * into Import.dbo.InvoicesRetailer_20111207b_BeforeSARALEEREbill1204and1205 from invoicesretailer
select * into Import.dbo.Invoicesupplier_20111207b_BeforeSARALEEREbill1204and1205 from invoicessupplier

select * into Import.dbo.InvoiceDetailsEDI_20111207b_BeforeSARALEEREbill1204and1205 from datatrue_edi.dbo.invoicedetails
select * into Import.dbo.InvoicesRetailerEDI_20111207b_BeforeSARALEEREbill1204and1205 from datatrue_edi.dbo.invoicesretailer
select * into Import.dbo.InvoicesupplierEDI_20111207b_BeforeSARALEEREbill1204and1205 from datatrue_edi.dbo.invoicessupplier

--remove from EDI
select *
--delete
from datatrue_edi.dbo.InvoicesRetailer
where RetailerInvoiceID in
(select RetailerInvoiceID from InvoiceDetailS where SupplierID = 41465 and Banner = 'SS' and SaleDate = '12/5/2011')

select *
--delete
from datatrue_edi.dbo.InvoicesSupplier
where SupplierInvoiceID in
(select SupplierInvoiceID from InvoiceDetailS where SupplierID = 41465 and Banner = 'SS' and SaleDate = '12/5/2011')

select * 
--delete
from datatrue_edi.dbo.InvoiceDetailS where SupplierID = 41465 and Banner = 'SS' and SaleDate = '12/5/2011'

--Main Dont delete details
select *
--delete
from datatrue_main.dbo.InvoicesRetailer
where RetailerInvoiceID in
(select RetailerInvoiceID from InvoiceDetailS where SupplierID = 41465 and Banner = 'SS' and SaleDate = '12/5/2011')

select *
--delete
from datatrue_main.dbo.InvoicesSupplier
where SupplierInvoiceID in
(select SupplierInvoiceID from InvoiceDetailS where SupplierID = 41465 and Banner = 'SS' and SaleDate = '12/5/2011')

select * 
--update d set d.RetailerInvoiceID = null, d.SupplierInvoiceID = null
--delete
from datatrue_main.dbo.InvoiceDetailS
where SupplierID = 41465 and Banner = 'SS' and SaleDate = '12/5/2011'

--select distinct workingstatus from [StoreTransactions_Working]
select t.PromoAllowance, *
--update t set t.PromoAllowance = null, t.PromoTypeID = null
from [dbo].[StoreTransactions_Working] t
where CAST(saledatetime as date) = '12/5/2011'
and t.SupplierID = 41465
and t.Banner = 'SS'

select t.PromoAllowance, p.UnitPrice, *
--update t set t.PromoAllowance = p.UnitPrice, t.PromoTypeID = P.ProductPriceTypeID, t.workingstatus = 1204
from [dbo].[StoreTransactions_Working] t
inner join [dbo].[ProductPrices] p
on t.ProductID = p.ProductID 
and t.BrandID = p.BrandID
and t.ChainID = p.ChainID 
and t.StoreID = p.StoreID 
and t.SupplierID = p.SupplierID 
where p.ProductPriceTypeID in 
(8, 9, 10) --2 is Chain Entity
and t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate
and CAST(saledatetime as date) = '12/5/2011'
and t.SupplierID = 41465
and isnull(t.PromoAllowance, 0) <> p.UnitPrice
and t.Banner = 'SS'

select w.PromoAllowance, t.PromoAllowance, *
--update t set t.PromoAllowance = w.PromoAllowance
from [dbo].[StoreTransactions_Working] w
inner join StoreTransactions t
on w.StoreTransactionID = t.WorkingTransactionID
where w.WorkingStatus = 1205


select *
--update t set t.transactionstatus = 801
from StoreTransactions t
where SupplierID = 41465 and Banner = 'SS' and cast(SaleDateTime as date) = '12/5/2011' and TransactionStatus <> 88


select storeid, ProductId --41447	16921
from StoreTransactions
where SupplierID = 41465 and Banner = 'SS' and cast(SaleDateTime as date) = '12/5/2011'
group by StoreID, ProductID
having COUNT(qty) > 1

return
GO
