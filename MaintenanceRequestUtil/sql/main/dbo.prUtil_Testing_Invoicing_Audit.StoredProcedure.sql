USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Testing_Invoicing_Audit]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Testing_Invoicing_Audit]
as

select * from InvoiceDetails where RetailerInvoiceID = 486

select sum(TotalQty * unitcost) from InvoiceDetails where RetailerInvoiceID = 486

select * from InvoicesRetailer

select * from StoreTransactions
where InvoiceBatchID in
(select BatchID from InvoiceDetails where RetailerInvoiceID = 486)

select * from StoreTransactions
where InvoiceBatchID in
(select BatchID from InvoiceDetails where RetailerInvoiceID = 486)
and SupplierID in (35113,28701)

select SUM(qty * rulecost) from StoreTransactions
where InvoiceBatchID in
(select BatchID from InvoiceDetails where RetailerInvoiceID = 486)
and SupplierID = 28701

select SUM(qty * rulecost) from StoreTransactions
where InvoiceBatchID in
(select BatchID from InvoiceDetails where RetailerInvoiceID = 486)
and SupplierID = 35113


select * from StoreTransactions
where 1 = 1
and storeid = 37803
and productid = 916
and TransactionTypeID in (5,8,9,14,20,21)
--and TransactionStatus = 801
order by SaleDateTime, StoreID, ProductID, BrandID, StoreTransactionID

select *
from InvoiceDetails
where SupplierInvoiceID = 465

select *
from InvoicesSupplier
where SupplierInvoiceID = 465

return
GO
