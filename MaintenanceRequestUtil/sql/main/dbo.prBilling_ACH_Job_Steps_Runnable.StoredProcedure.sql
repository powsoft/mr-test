USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_ACH_Job_Steps_Runnable]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prBilling_ACH_Job_Steps_Runnable]
as

/*
select * from datatrue_edi.dbo.processstatus_ach order by date desc
select * from jobrunning
select * from datatrue_edi.dbo.EDI_LoadStatus_ACH order by dateloaded desc
*/
exec dbo.prSendEmailNotification_PassEmailAddresses 'Daily Regulated Billing Job Started'
,'Daily Regulated Billing Job Started'
,'DataTrue System', 0, 'datatrueit@icontroldsd.com;edi@icontroldsd.com'	

exec DataTrue_Main.dbo.prValidateJobRunning

/*
SELECT *  FROM [DataTrue_EDI].[dbo].[Inbound846Inventory_ACH_Approval] where recordstatus = 0
SELECT *  FROM [DataTrue_EDI].[dbo].[Inbound846Inventory_ACH_Approval] order by recordid desc
*/

exec dbo.prGetInboundSUPTransactions_846_ACH

/*
select * from datatrue_edi.dbo.InboundInventory_WEB where recordstatus = 0
select * from datatrue_edi.dbo.InboundInventory_WEB where cast(datetimecreated as date) = '8/5/2013'
select ReferenceIdentification, sum(qty*cost) from datatrue_edi.dbo.InboundInventory_WEB where recordstatus = 0 group by ReferenceIdentification

*/

exec [dbo].[prGetInboundInventory_WEB]

/*
select top 20 * from StoreTransactions_Working order by StoreTransactionID desc
*/

exec dbo.prValidateStoresInStoreTransactions_Working_SUP_ACH

exec dbo.prValidateProductsInStoreTransactions_Working_ACH

exec dbo.prValidateSuppliersInStoreTransactions_Working_SUP_ACH

--At this point we know the chain and supplier and need to (workingstatus = 3)
	

exec dbo.prValidateSourceInStoreTransactions_Working_ACH

--VM removed NOMERGE from name
--Next step inserts into Storetransactions table
exec dbo.prValidateTransactionTypeInStoreTransactions_Working_SUP_ACH

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
exec dbo.prInvoiceDetail_ReleaseStoreTransactions_SUP_ACH

--VM removed NOMERGE from name
--Next step creates invoicedetail records from storetransactions records released

exec dbo.prInvoiceDetail_SUP_Create_ACH

--06/11/2013
--365/17319
--Next step assigns/creates RetailerInvoceID's to the invoicedetails
exec dbo.prInvoices_Retailer_Create_ACH  'DAILY'

--select * from chains

/*


select *
--select distinct storeid, supplierinvoicenumber
from storetransactions
where supplierid = 60653
 and CAST(datetimecreated as date) = '07/16/2013'
 
 select *
 from productidentifiers
 where 1 = 1
 and charindex('74136034588', identifiervalue) > 0
 '74136034589','74136034588'
 
 1522	1522071613                                        
1532	1522071613                                        
 
 select *
 --update w set w.productid = null, workingstatus = 1
 --select distinct storeidentifier, supplierinvoicenumber
from storetransactions_working w
where supplierid = 60653
 --and productid = 0
 and CAST(datetimecreated as date) = '07/16/2013'

7/8/2013
select 53552.2494000003 + 26941.1600000001 --=80493.4094000004
7/9/2013
14362.28
7/10/2013
34013.2700000001
7/11
23233.14
7/12
25185.69
7/15
35570.8900000001 993
7/16
23905.11 525
7/17
34004.9296000001 SPN
7/18
21858.76 525

select * from datatrue_edi.dbo.InboundInventory_Web order by recordid desc
select * from datatrue_edi.dbo.processstatus order by date desc
select * from datatrue_edi.dbo.processstatus_ach order by date desc
select * from jobrunning
select * from datatrue_edi.dbo.EDI_LoadStatus_ACH order by dateloaded desc
select * from suppliers 
--where supplierid = 51068
order by supplierid desc

select *
--select sum(totalcost)
--select distinct supplierid
 from InvoiceDetails
 where ChainID = 50964
 and supplierid = 62342 --allbev
 --and supplierid = 50729 --glwine
 --and supplierid = 60653 --modwine
 --and supplierid = 51068 --pawpaw
 and CAST(datetimecreated as date) = '08/28/2013'
 order by invoicedetailid desc
 
and invoiceno = 'D779611'

38940.4475
76170.83
 select *
 from suppliers
 order by supplierid desc
 
 select *
 --select sum(originalamount)
 from invoicesretailer
  where ChainID = 50964
 and CAST(datetimecreated as date) = '07/29/2013'
 order by retailerinvoiceid desc
 
 select *
--select sum(totalcost)
--delete
 from datatrue_edi.dbo.InvoiceDetails
 where ChainID = 50964
 and CAST(datetimecreated as date) = '07/8/2013'
 
*/ 

select ProductId, OwnerEntityID, COUNT(distinct identifiervalue)
from ProductIdentifiers
where ProductIdentifierTypeID = 3
group by Productid, OwnerEntityID
having COUNT(distinct identifiervalue) > 1
order by COUNT(distinct identifiervalue) desc

--Use this one
--/*
update h set h.RawstoreIdentifier = d.RawstoreIdentifier, 
h.InvoiceNumber = d.InvoiceNo, h.PaymentDueDate = d.PaymentDueDate, 
h.Route = d.Route, h.storeid = d.storeid
--select *
from InvoicesRetailer h
inner join InvoiceDetails d
on h.RetailerInvoiceID = d.RetailerInvoiceID
where h.chainid  in
(
50964
)
and cast(h.datetimecreated as date) = '9/12/2013'
and h.Route is null
and h.InvoiceNumber is null



select * from Payments
select * from datatrue_edi.dbo.payments
--*/


--print cast(getdate() as date)
--Next step creates payment records in DataTrue_Main and DataTrue_EDI Payments tables
exec datatrue_main.dbo.[prBilling_Payment_AutoRelease_CreatePayments_ACH_ByChain_Separate_FuelStores_WithAggregation]


exec prBilling_Regulated_DeleteInvoicesRetailerRecordsWithNullPaymentID


update h set h.OriginalAmount = d.IDSum, h.OpenAmount = d.IDSum
 from InvoicesRetailer h
 inner join
 (
 select retailerinvoiceid, Round(SUM(totalcost),2) as IDsum
 from datatrue_main.dbo.Invoicedetails
 where 1 = 1
 --and InvoiceDetailTypeID = 11
 --and saledate > '11/30/2011'
 and CAST(datetimecreated as date) = '8/30/2013'
 group by RetailerInvoiceID
 ) d
 on h.RetailerInvoiceID = d.RetailerInvoiceID
 and d.IDSum <> h.OriginalAmount



--Next step syncs the EDI database invoicedetails and invoicesretailer tables
exec dbo.prBilling_EDIDatabase_Sync

EXEC [dbo].[prValidate_Regulated_Billing_Job_ACH]

/*
--7/8/2013 82458.76
7/18 21858.76 525
7/19 21484.6 463
7/23 17713.6633 556
7/24 46277.8900000002 1026   select 46277.8900000002 +  721.00  = 46998.89
7/25 25418.02 517
7/26 16577.99 438
7/29 42098.0885000002 1140 + 4352.91 109 = 46450.9985 select 42098.0885000002 + 4352.91
7/30 22889.67 600
7/31 38680.4799000001 870 select 38680.4799 + 494 = 39174.48
8/1 24608.1597000001 514
8/2 17399.07 465
8/5 41409.7000000002 1129   select   41409.70 + 336    41745.70
8/6 24118.0196 588 select 116 + 24118.0196 --24234.02
8/7 34946.5708000001 790
8/8 23126.1788 570
8/9 14665.2008 422
8/12 47371.5000000004 1273  select 47371.50 + 252  47623.50
8/13 23761.73 483	select 23761.73 + 168	23929.73
8/14 36618.6790000001 902		select 36618.679 + 	84			36702.68
8/15 18727.76 
8/16 21030.24 567		select 180.00 + 	21030.24 567			21210.24
8/19 41498.6500000002 1145 select  41498.65 +  258   41756.65
8/20 27145.68 580
8/22 17589.0298
8/23 19770.25 559
8/26 39361.7000000002 1076
8/27 24613.2200000001 513
select 38940.4475 +  76170.83 = 115111.2775
8/28 GLWINE 38940.4475000001 935
8/28 ALLBEV 76170.83 1672
8/29
GLWINE	18277.1488 select 18277.1488 + 	-13125.27 + 174			5325.88
ALLBEV -13125.27
MODWINE 174
8/30
glwine 16952.91			select 16952.91 + 44684.43 = 61637.34
allbev 44684.4300000001
modwine
9/3
glwine 46488.0500000003 select 46488.0500000003 + 92117.8799999994 + 231 = 138836.9299999997
allbev 92117.8799999994
modwine 231
9/11
glwine 36224.9400000002
wsbeer 39170.6 (39170.60)
allbev 55297.5100000002

	select 36224.9400000002 + 	39170.6 + 	55297.5100000002	130693.05
	select 55297.5100000002 + 36224.9400000002
91522.45 	
modwine

albev -17209.6199999999
glwine 19834.28
wsbeer 7067.69
select -17209.6199999999 + 19834.28 + 7067.69 = 9692.3500000001

9/20
albev 24162.3800000001=24162.38
glwine 14091.17=14091.17
pawpaw 9534.65999999999=9534.66
wsbeer 19024.95=19024.95
select * from datatrue_edi.dbo.EDI_LoadStatus_ACH order by dateloaded desc
*/
 
 select *
--select sum(totalcost)
--delete
--update d set d.paymentduedate = '9/11/2013'
 from datatrue_edi.dbo.InvoiceDetails d
 where ChainID = 50964
 and supplierid = 50731 --wsbeer
 --and supplierid = 62342 --allbev
 --and supplierid = 50729 --glwine
 --and supplierid = 60653 --modwine
 --and supplierid = 51068 --pawpaw
 and CAST(datetimecreated as date) = '9/20/2013'
 and InvoiceDetailTypeID = 2
 --and SupplierID = 51068
  order by RetailerInvoiceID desc
  
 select *
 --select sum(originalamount)
 --update r set r.PaymentDueDate = '9/9/2013'
 from datatrue_edi.dbo.invoicesretailer r
  where ChainID = 50964
 and CAST(datetimecreated as date) = '9/20/2013'
 and InvoiceTypeID not in (14,15)
 --and PaymentDueDate is null
 --and PaymentID is null
 order by AggregationID desc
 --order by RetailerInvoiceID desc


/*
select * from DataTrue_EDI.dbo.ProcessStatus_ach
*/

Update DataTrue_EDI.dbo.ProcessStatus_ach
Set BillingComplete = 1, OutBoundComplete = 0, StartProcess = 0
Where [Date] = CONVERT(DATE,GETDATE())
and BillingIsRunning = 1
and BillingComplete = 0

Update DataTrue_Main.dbo.JobRunning
Set JobIsRunningNow = 0
Where JobName = 'DailyRegulatedBilling'

exec dbo.prSendEmailNotification_PassEmailAddresses 'Daily Regulated Billing Job Completed'
,'Daily Regulated Billing Job Completed'
,'DataTrue System', 0, 'datatrueit@icontroldsd.com; edi@icontroldsd.com'


--Next sum result should be within a penny of the expected payment amoung
	--If not then there are probably records in the Invoicesretailer table with null paymentid
/*	
 select *
 --select sum(OriginalAmount)
 from InvoicesRetailer
  where ChainID = 50964
 and CAST(datetimecreated as date) = '07/8/2013'
 
 select *
 --select sum(OriginalAmount)
 from datatrue_edi.dbo.InvoicesRetailer
  where ChainID = 50964
 and CAST(datetimecreated as date) = '07/8/2013'
 
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
