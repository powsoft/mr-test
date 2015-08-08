USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Nestle_DunsReRun_20111205]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Nestle_DunsReRun_20111205]
as


select * from datatrue_edi.dbo.EDI_SupplierCrossReference

-- Nestlie 40559

select * from InvoiceDetailS 
where SupplierID = 40559
and Banner = 'SS'
and SaleDate in ('12/1/2011', '12/2/2011', '12/3/2011')

select distinct SupplierIdentifier
from InvoiceDetailS 
where SupplierID = 40559
and Banner = 'SS'
and SaleDate in ('12/1/2011', '12/2/2011', '12/3/2011')

--Create Backups of Everything

select * into import.dbo.invoicedetails_20111205 from InvoiceDetailS
select * into import.dbo.invoicesretailer_20111205 from invoicesretailer
select * into import.dbo.invoicessupplier_20111205 from invoicessupplier
select *
--delete 
from InvoicesRetailer where RetailerInvoiceID in 
(
select RetailerInvoiceID 
from InvoiceDetailS 
where SupplierID = 40559
and Banner = 'SS'
and SaleDate in ('12/1/2011', '12/2/2011', '12/3/2011')
)
select *
--delete 
from InvoicesSupplier where SupplierInvoiceID in 
(
select SupplierInvoiceID 
from InvoiceDetailS 
where SupplierID = 40559
and Banner = 'SS'
and SaleDate in ('12/1/2011', '12/2/2011', '12/3/2011')
)
--0665638590000
--0009269990000
select*
--update d set RetailerInvoiceID = Null, SupplierInvoiceID = null
from InvoiceDetailS d
where SupplierID = 40559
and Banner = 'SS'
and SaleDate in ('12/1/2011', '12/2/2011', '12/3/2011')
--EDI**********************************************
select * into import.dbo.invoicedetailsEDI_20111205 from datatrue_edi.dbo.InvoiceDetailS
select * into import.dbo.invoicesretailerEDI_20111205 from datatrue_edi.dbo.invoicesretailer
select * into import.dbo.invoicessupplierEDI_20111205 from datatrue_edi.dbo.invoicessupplier
select *
--delete 
from datatrue_edi.dbo.InvoicesRetailer where RetailerInvoiceID in 
(
select RetailerInvoiceID 
from InvoiceDetailS 
where SupplierID = 40559
and Banner = 'SS'
and SaleDate in ('12/1/2011', '12/2/2011', '12/3/2011')
)
select *
--delete 
from datatrue_edi.dbo.InvoicesSupplier where SupplierInvoiceID in 
(
select SupplierInvoiceID 
from InvoiceDetailS 
where SupplierID = 40559
and Banner = 'SS'
and SaleDate in ('12/1/2011', '12/2/2011', '12/3/2011')
)

select distinct SupplierName --*

from datatrue_edi.dbo.InvoiceDetailS where SupplierID = 40559
and Banner = 'SS'
and SaleDate in ('12/1/2011', '12/2/2011', '12/3/2011')


select distinct SupplierName --*
--delete
from InvoiceDetailS where SupplierID = 40559
and Banner = 'SS'
and SaleDate in ('12/1/2011', '12/2/2011', '12/3/2011')
--*************************************************


return
GO
