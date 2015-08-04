USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_ACH_Job_Steps_bak]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prBilling_ACH_Job_Steps_bak]
as

/*
dbo.prDailyPOSBillingStartJob - Starts POS Daily Billing

dbo.prDailyPOSBillingCompleteUpdate - updates processstatus_ach table
*/


exec dbo.prACH_MovePendingRecordsToApprovalTable

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Daily Regulated Billing Job Started'
		,'Daily Regulated Billing Job Started'
		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com; edi@icontroldsd.com'

exec dbo.prGetInboundSUPTransactions_846_ACH

exec dbo.prValidateStoresInStoreTransactions_Working_SUP_ACH

exec dbo.prValidateProductsInStoreTransactions_Working_ACH

exec dbo.prValidateSuppliersInStoreTransactions_Working_SUP_ACH

exec dbo.prValidateSourceInStoreTransactions_Working_SUP

exec dbo.prValidateTransactionTypeInStoreTransactions_Working_SUP_NOMERGE_TempTables_ACH

select *
from storetransactions
where cast(datetimecreated as date) = '4/23/2013'
and transactiontypeid in (5, 8)
and chainid = 50964

select SUM(rulecost * case when transactiontypeid = 5 then qty else qty * -1 end)
from storetransactions
where cast(datetimecreated as date) = '4/23/2013'
and transactiontypeid in (5, 8)
and chainid = 50964

--12160.4598
--select * from datatrue_edi.dbo.EDI_LoadStatus_ACH
--select * from chains

exec dbo.prInvoiceDetail_ReleaseStoreTransactions_SUP_ACH

exec dbo.prInvoiceDetail_SUP_Create_NOMERGE_TempTables_ACH

exec dbo.prInvoices_Retailer_Create_ACH  'DAILY'

--select * from chains



select *
--delete 
from DataTrue_Main..InvoicesRetailer 
where 1 = 1 
and ChainID = 50964
and RetailerInvoiceID not in 
(select distinct RetailerInvoiceID from InvoiceDetails)

select *
--select sum(totalcost)
 from InvoiceDetails
 where ChainID = 50964
 and CAST(datetimecreated as date) = '4/23/2013'
 
 select *
 --select sum(OriginalAmount)
 from InvoicesRetailer
  where ChainID = 50964
 and CAST(datetimecreated as date) = '4/22/2013'

update h set h.RawstoreIdentifier = d.RawstoreIdentifier, 
h.InvoiceNumber = d.InvoiceNo, h.PaymentDueDate = d.PaymentDueDate, 
h.Route = d.Route, h.storeid = d.storeid
from InvoicesRetailer h
inner join InvoiceDetails d
on h.RetailerInvoiceID = d.RetailerInvoiceID
where h.chainid = 50964
and cast(h.datetimecreated as date) = '4/23/2013'

exec dbo.prBilling_Payment_AutoRelease_CreatePayments_ACH_ByChain

exec dbo.prBilling_EDIDatabase_Sync

 select * --into import.dbo.invoicesretailerdeleted_20130422
 --select sum(OriginalAmount)
 --delete
 from datatrue_main.dbo.InvoicesRetailer
  where ChainID = 50964
 and CAST(datetimecreated as date) = '4/23/2013'
 and paymentid is null

 select * --into import.dbo.invoicesretailerdeleted_20130422
 --select sum(OriginalAmount)
 --delete
 from datatrue_edi.dbo.InvoicesRetailer
  where ChainID = 50964
 and CAST(datetimecreated as date) = '4/22/2013'
 and paymentid is null
 
  select *
 --select sum(OriginalAmount)
 from datatrue_edi.dbo.Payments
 order by PaymentID desc


		exec dbo.prSendEmailNotification_PassEmailAddresses 'Daily Regulated Billing Job Completed'
		,'Daily Regulated Billing Job Completed'
		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com; edi@icontroldsd.com'
		
return
GO
