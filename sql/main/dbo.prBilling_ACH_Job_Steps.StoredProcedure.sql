USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_ACH_Job_Steps]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prBilling_ACH_Job_Steps]
as

/*
dbo.prDailyPOSBillingStartJob - Starts POS Daily Billing

dbo.prDailyPOSBillingCompleteUpdate - updates processstatus_ach table
*/
/*

select *
from datatrue_edi.dbo.EDI_LoadStatus_ACH
where LoadStatus = 1

select * 
from datatrue_edi.dbo.processstatus_ach 
where BillingComplete = 0 
and BillingIsRunning is null
--7203.99/203
*/

--exec dbo.prACH_MovePendingRecordsToApprovalTable
/*

select * from datatrue_edi.dbo.Inbound846Inventory_ACH_Approval 
where 
cast(timestamp as date) = '6/27/2013' 
and
recordstatus = 0
and ediname <>'GLWINE'

*/

--
--Run this ONLY if Billing_Regulated was not started and prBilling_Regulated_startjob is not running. This eamil is sent by job so this would be a duplicate.
/*
exec dbo.prSendEmailNotification_PassEmailAddresses 'Daily Regulated Billing Job Started'
,'Daily Regulated Billing Job Started'
,'DataTrue System', 0, 'datatrueit@icontroldsd.com; edi@icontroldsd.com'
*/


--Update DataTrue_EDI.dbo.ProcessstStatus_ach.BillingIsRunning
/*
Update DataTrue_EDI.dbo.ProcessStatus_ach
Set BillingIsRunning = 1
Where [Date] = CONVERT(DATE,GETDATE())
And BillingIsRunning is null
*/

--Next step inserts into Storetransactions_working table
--exec dbo.prGetInboundSUPTransactions_846_ACH

--exec dbo.prValidateStoresInStoreTransactions_Working_SUP_ACH

--exec dbo.prValidateProductsInStoreTransactions_Working_ACH

--exec dbo.prValidateSuppliersInStoreTransactions_Working_SUP_ACH

--At this point we know the chain and supplier and need to (workingstatus = 3)
	

--exec dbo.prValidateSourceInStoreTransactions_Working_ACH

--VM removed NOMERGE from name
--Next step inserts into Storetransactions table
--exec dbo.prValidateTransactionTypeInStoreTransactions_Working_SUP_ACH

/*
select SUM(reportedcost * case when workingsource = 'SUP-S' then qty else qty * -1 end)
from storetransactions_working
where cast(datetimecreated as date) = '6/13/2013'
and CHARINDEX('SUP',workingsource) > 0
and chainidentifier = 'VAL'
--12964.2

--Verify Recordcount inserted
select *
from storetransactions
where cast(datetimecreated as date) = '6/13/2013'
and transactiontypeid in (5, 8)
and chainid = 59973 --Spartan select * from chains

--Verify Dollar Total 
select SUM(rulecost * case when transactiontypeid = 5 then qty else qty * -1 end)
from storetransactions
where cast(datetimecreated as date) = '6/13/2013'
and transactiontypeid in (5, 8)
and chainid = 59973
--select * from chains where chainidentifier='VAL'
*/

--Next step releases the transactions to be included in invoice detail creation
--exec dbo.prInvoiceDetail_ReleaseStoreTransactions_SUP_ACH

--VM removed NOMERGE from name
--Next step creates invoicedetail records from storetransactions records released

--exec dbo.prInvoiceDetail_SUP_Create_ACH

--06/11/2013
--365/17319
--Next step assigns/creates RetailerInvoceID's to the invoicedetails
--exec dbo.prInvoices_Retailer_Create_ACH  'DAILY'

--select * from chains

/*

select *
--select sum(totalcost)
 from InvoiceDetails
 where ChainID = 59973
 and CAST(datetimecreated as date) = '06/13/2013'
 
 select *
--select sum(totalcost)
--delete
 from datatrue_edi.dbo.InvoiceDetails
 where ChainID = 59973
 and CAST(datetimecreated as date) = '06/13/2013'
 
*/ 



--Use this one
/*
update h set h.RawstoreIdentifier = d.RawstoreIdentifier, 
h.InvoiceNumber = d.InvoiceNo, h.PaymentDueDate = d.PaymentDueDate, 
h.Route = d.Route, h.storeid = d.storeid
from InvoicesRetailer h
inner join InvoiceDetails d
on h.RetailerInvoiceID = d.RetailerInvoiceID
where h.chainid  in
(
select ChainID 
from datatrue_main.dbo.chains c
inner join DataTrue_EDI.dbo.ProcessStatus_ACH pr
on pr.ChainName = c.ChainIdentifier
Where BillingIsRunning = 1
and BillingComplete = 0
)
and cast(h.datetimecreated as date) = cast(getdate() as date)

*/


--print cast(getdate() as date)
--Next step creates payment records in DataTrue_Main and DataTrue_EDI Payments tables
--exec dbo.prBilling_Payment_AutoRelease_CreatePayments_ACH_ByChain



--Next step syncs the EDI database invoicedetails and invoicesretailer tables
--exec dbo.prBilling_EDIDatabase_Sync

--Next sum result should be within a penny of the expected payment amoung
	--If not then there are probably records in the Invoicesretailer table with null paymentid
/*	
 select *
 --select sum(OriginalAmount)
 from InvoicesRetailer
  where ChainID = 50964
 and CAST(datetimecreated as date) = '06/27/2013'
 
 select *
 --select sum(OriginalAmount)
 from datatrue_edi.dbo.InvoicesRetailer
  where ChainID = 50964
 and CAST(datetimecreated as date) = '06/12/2013'
 
 */
 

/* REPLACED DELETES WITH STORED PROCEDURE 
DataTrue_Main.dbo.prBilling_Regulated_DeleteInvoicesRetailerRecordsWithNullPaymentID which
applies context of regulated billing to avoid deleting non-regulated billing records

--Run next two deletes for today's date to remove the records with null paymentid
 select * --into import.dbo.invoicesretailerdeleted_20130422
 --select sum(OriginalAmount)
 --delete
 from datatrue_main.dbo.InvoicesRetailer
  --where ChainID = 50964
 where CAST(datetimecreated as date) = CAST(getdate() as date)
 and paymentid is null

 select * --into import.dbo.invoicesretailerdeleted_20130422
 --select sum(OriginalAmount)
 --delete
 from datatrue_edi.dbo.InvoicesRetailer
  where ChainID = 50964
 and CAST(datetimecreated as date) = CAST(getdate() as date)
 and paymentid is null
*/

--new delete stored procedure
--exec DataTrue_Main.dbo.prBilling_Regulated_DeleteInvoicesRetailerRecordsWithNullPaymentID
 
 --The next sum should match the amount in the datatrue_edi.dbo.EDI_LoadStatus_ACH table exactly when rounded to two decimals
/*
  select *
 --select AmountOriginallyBilled
 from datatrue_edi.dbo.Payments
 order by PaymentID desc
 
 select *
 --select AmountOriginallyBilled
 from datatrue_main.dbo.Payments
 order by PaymentID desc

*/


--Update DataTrue_EDI.dbo.ProcessstStatus_ach.BillingComplete
/*
Update DataTrue_EDI.dbo.ProcessStatus_ach
Set BillingComplete = 1
Where [Date] = CONVERT(DATE,GETDATE())
*/

--Once all matches exactly run the next to notify everyone
/*
		exec dbo.prSendEmailNotification_PassEmailAddresses 'Daily Regulated Billing Job Completed'
		,'Daily Regulated Billing Job Completed'
		,'DataTrue System', 0, 'datatrueit@icontroldsd.com; edi@icontroldsd.com'
*/	

/*
Update DataTrue_Main.dbo.JobRunning
Set JobIsRunningNow = 0
Where JobName = 'DailyRegulatedBilling'
*/
	
return
GO
