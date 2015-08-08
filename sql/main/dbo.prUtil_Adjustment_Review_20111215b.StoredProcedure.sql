USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Adjustment_Review_20111215b]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prUtil_Adjustment_Review_20111215b]
as

select *
from ProductIdentifiers
where IdentifierValue = '043396303287' --072945601369'

select distinct custom1 from stores


select *
from invoicedetails
where 1 = 1
--and totalqty = 0
and InvoiceDetailTypeID = 7
and Banner = 'SS'
order by totalqty

select *
from datatrue_edi.dbo.invoicedetails
where 1 = 1
--and totalqty = 0
and InvoiceDetailTypeID = 7
and Banner = 'SS'
order by totalqty


select *
from InvoicesRetailer
where RetailerInvoiceID in
(
select RetailerInvoiceID
from datatrue_edi.dbo.invoicedetails
where 1 = 1
--and totalqty = 0
and InvoiceDetailTypeID = 7
and Banner = 'SS'
)
order by originalamount

select *
from StoreTransactions t
where Banner = 'SS'
and RuleCost - PromoAllowance <> ReportedCost
and SupplierID = 41464

select *
from datatrue_edi.dbo.invoicedetails
where 1 = 1
--and totalqty = 0
and InvoiceDetailTypeID = 7
and Banner = 'SS'
and ProductID = 17042
order by SaleDate desc

select *
from datatrue_edi.dbo.invoicedetails
where 1 = 1
--and totalqty = 0
and InvoiceDetailTypeID = 7
and Banner = 'SS'
and ProductID = 17042
and SaleDate = '12/1/2011'
order by totalqty


--Why no Adjustment? UPC 43396303287(9298) store 6020(40964) date 12/1

select * from stores where StoreIdentifier = '6020'

select * from StoreTransactions where StoreID = 40964 and ProductID = 9298 and SaleDateTime = '12/1/2011'

select * from productprices where ProductID = 9298 and StoreID = 40964 --and --SaleDateTime = '12/1/2011'
select a.* from import.dbo.tmpAdjustments20111213 a inner join StoreTransactions t on a.storetransactionid = t.StoreTransactionID where ProductID = 9298 and StoreID = 40964 and SaleDateTime = '12/1/2011'
select * from StoreTransactions where StoreID = 40964 and ProductID = 9298 and SaleDateTime = '12/1/2011'

select * from cdc.dbo_productprices_ct where StoreID = 40964 and ProductID = 9298

return
GO
