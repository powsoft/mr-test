USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_Inbound820Payments_From_Billing_Create_Debug]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prBilling_Inbound820Payments_From_Billing_Create_Debug]
as

declare @chainid int

/*
select * from chains where ChainIdentifier in ('KNG')
*/

select @chainid = chainid from Chains
where ChainIdentifier in ('KNG')

select RetailerInvoiceID, InvoiceDetailID
into #tempInvoiceDetails
from InvoiceDetails
where ChainID = @chainid
and RecordStatus = 1


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
select distinct i.RetailerInvoiceID, 'AUTOCHECK', i.OriginalAmount, DateTimeCreated, DateTimeCreated, 0
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
