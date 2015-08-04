USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_Inbound820Payments_From_Billing_Create_Newspaper_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prBilling_Inbound820Payments_From_Billing_Create_Newspaper_PRESYNC_20150329]
as

declare @chainid int

select RetailerInvoiceID, InvoiceDetailID
into #tempInvoiceDetails
--Select *
from InvoiceDetails d
where d.ChainID in (
select EntityIDToInclude 
from ProcessStepEntities 
where ProcessStepName in ('prBilling_Inbound820Payments_From_Billing_Create_Newspaper', 
						'prBilling_Inbound820Payments_From_Billing_Create_Newspaper_PDI' ) 
and IsActive = 1
)
and RecordStatus = 1
and d.RetailerInvoiceID is not null
and d.RetailerInvoiceID <> 0
and d.SupplierInvoiceID is not null
order by saledate
/*

select * from [DataTrue_EDI].[dbo].[Inbound820Payments] where datatruechainid = 42490 order by saledate
*/

INSERT INTO [DataTrue_EDI].[dbo].[Inbound820Payments]
           ([ChainIdentifier]
           ,[InvType]
           ,[StoreIdentifier]
           ,[SaleDate]
           ,[UPC]
           ,[Cost]
           ,[Qty]
           ,[WeekEndingDate]
           ,[iControlInvNumber]
           ,[InvAmt]
           ,[InvDate]
           ,[RecordStatus]
           ,[DataTrueChainID]
           ,[DataTrueStoreID]
           ,[DataTrueProductID]
           ,[DataTrueBrandID]
           ,[DataTrueSupplierID]
           ,[DataTrueInvoiceDetailID])
           
 SELECT isnull(d.[ChainIdentifier], '')
	  ,h.InvoiceTypeID
	  ,d.[StoreIdentifier]
	  ,d.[SaleDate]
	  ,d.RawProductIdentifier
	  ,d.UnitCost
	  ,d.TotalQty
	  ,h.InvoicePeriodEnd
      ,h.[RetailerInvoiceID]
      ,h.OriginalAmount
      ,h.InvoiceDate
      ,0 --recordstatus
      ,d.ChainID
      ,d.StoreID
      ,d.ProductID
      ,d.BrandID
      ,d.SupplierID
      ,d.[InvoiceDetailID]
  FROM [DataTrue_Main].[dbo].[InvoicesRetailer] h
  inner join [DataTrue_Main].[dbo].[InvoiceDetails] d
  on h.RetailerInvoiceID = d.RetailerInvoiceID
  inner join #tempInvoiceDetails t
  on d.InvoiceDetailID = t.InvoiceDetailID

update datatrue_edi.dbo.InvoicesRetailer
set InvoiceStatus = 2
where RetailerInvoiceID in
(select Distinct RetailerInvoiceID from #tempInvoiceDetails)

INSERT INTO [DataTrue_EDI].[dbo].[InvoicePaymentsFromRetailer]
           ([RetailerInvoiceID]
           ,[RetailerCheckNumber]
           ,[RetailerPaymentAmount]
           ,[DateTimePaymentReceived]
           ,[DateTimeCreated]
           ,[LastUpdateUserID])
select distinct i.RetailerInvoiceID, 'AUTOCHECK', i.OriginalAmount, GETDATE(), GETDATE(), 0
from #tempInvoiceDetails t
inner join [DataTrue_EDI].[dbo].[InvoicesRetailer] i
on t.RetailerInvoiceID = i.RetailerInvoiceID

update d 
set RecordStatus = 2
from InvoiceDetails d
inner join #tempInvoiceDetails t
on d.InvoiceDetailID = t.InvoiceDetailID

return
GO
