USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_Payment_Create_ToDeploy]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Joshua Kiracofe
-- Create date: 2/26/2015
-- Description:	Create Payments without using cursors
-- =============================================
CREATE PROCEDURE [dbo].[prBilling_Payment_Create_ToDeploy]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
declare @MyID int=7419

    -- Insert statements for procedure here
select distinct s.chainid, d.SupplierID, SUM(TotalQty*UnitCost) TotalPaymentAmount, CAST(0 as int) FirstStatus, CAST(0 as int) PaymentId Into #TempChainPayments --Drop Table #TempChainPayments
from InvoicesRetailer s with(nolock)
inner join InvoiceDetailS d with(nolock)
on s.RetailerInvoiceID = d.RetailerInvoiceID
and s.ChainID in (select EntityIDtoInclude 
		from ProcessStepEntities 
		where ProcessStepName Like 'prBilling_Payment_Create%'
		and IsActive = 1)
and d.PaymentID is null
and d.RetailerInvoiceID is not null
and d.RetailerInvoiceID <> -1
and d.SupplierInvoiceID is not null
and d.SupplierInvoiceID <> -1
and d.SupplierID <> 0
and SaleDate >= '11/18/2013'
Group by S.ChainID, d.SupplierID
having SUM(totalqty*unitcost) >= 20

select distinct d.InvoiceDetailID into #InvoiceDetailID
from InvoiceDetailS d with(nolock)
where 1=1
and d.ChainID in (select EntityIDtoInclude 
		from ProcessStepEntities 
		where ProcessStepName Like 'prBilling_Payment_Create%'
		and IsActive = 1)
and d.PaymentID is null
and d.RetailerInvoiceID is not null
and d.RetailerInvoiceID <> -1
and d.SupplierInvoiceID is not null
and d.SupplierInvoiceID <> -1
and d.SupplierID <> 0
and SaleDate >= '11/18/2013'


Update P Set P.FirstStatus = C.Payment820ReleaseFirstStatus
--select distinct c.*
from dbo.PaymentDisbursementReleaseControl c
inner join #TempChainPayments P on 
PaymentDisbursementPayerEntityID = p.ChainID

select CAST(0 as int) as PaymentId
,CAST(0 as int) as PayerEntityId
,CAST(0 as int) as PayeeEntityId
,CAST(0 as money) as AmountOriginallyBilled
into #outputtable


Insert Into Payments (PayerEntityID, PayeeEntityID, AmountOriginallyBilled, PaymentStatus, PaymentTypeID, LastUpdateUserID)
OUTPUT INSERTED.PaymentID, inserted.PayerEntityID, inserted.PayeeEntityID, Inserted.AmountOriginallyBilled INTO #outputtable
Select ChainID, SupplierID, TotalPaymentAmount, FirstStatus, 1, @MyID
from #TempChainPayments
Order by SupplierID, ChainID

update c set c.PaymentId = o.PaymentId
from #TempChainPayments c
inner join #outputtable o
on c.ChainID = o.PayerEntityId
and c.SupplierID = o.PayeeEntityId
and C.TotalPaymentAmount = o.AmountOriginallyBilled


update d set d.PaymentID = c.PaymentId--, d.RecordStatus = 1
from datatrue_main.dbo.InvoiceDetails d
inner join #TempChainPayments c
on d.ChainID = c.ChainID
and d.SupplierID = c.supplierid
and d.InvoiceDetailID in (Select InvoiceDetailID from #InvoiceDetailID)

update ed set ed.paymentid = md.PaymentID
from datatrue_edi.dbo.InvoiceDetails ed
inner join datatrue_main.dbo.InvoiceDetails md
on ed.InvoiceDetailID = md.InvoiceDetailID
inner join #InvoiceDetailID t
on md.InvoiceDetailID = t.InvoiceDetailID

INSERT INTO [DataTrue_EDI].[dbo].[Payments]
		   ([PaymentID]
		   ,[PaymentTypeID]
		   ,[ChainID]
		   ,[SupplierID]
		   ,[AmountOriginallyBilled]
		   ,[LastUpdateUserID])
SELECT P.[PaymentID] 
	  ,[PaymentTypeID]
	  ,[PayerEntityID]
	  ,[PayeeEntityID]
	  ,[AmountOriginallyBilled]
	  ,[LastUpdateUserID]
  FROM [DataTrue_Main].[dbo].[Payments]	P inner Join
  #TempChainPayments C on P.PaymentID = C.PaymentId
  Where Cast(DateTimeCreated as date) = Convert(date, getdate())
  
  INSERT INTO [DataTrue_Main].[dbo].[PaymentHistory]
           ([PaymentID]
           ,[LastUpdateUserID]
           ,[PaymentStatus]
           ,[PaymentStatusChangeDateTime]
           ,[AmountPaid])
  Select Paymentid
		,@MyId
		,FirstStatus
		,GETDATE()
		,TotalPaymentAmount
  From #TempChainPayments
   
  INSERT INTO [DataTrue_EDI].[dbo].[PaymentHistory]
           ([PaymentID]
           ,[LastUpdateUserID]
           ,[PaymentStatus]
           ,[PaymentStatusChangeDateTime]
           ,[AmountPaid])
  Select Paymentid
		,@MyId
		,FirstStatus
		,GETDATE()
		,TotalPaymentAmount
  From #TempChainPayments
  
  Drop Table #InvoiceDetailID
  Drop Table #outputtable
  Drop Table #TempChainPayments

DECLARE @tmpProcessedInvoices TABLE (chainname varchar(50), SupplierName varchar(50), totalretail varchar(50), chainid int, totalcost varchar(50), PaymentId varchar(50))
INSERT INTO @tmpProcessedInvoices (chainname, SupplierName, totalretail, chainid, totalcost, PaymentId)

Select Left(C.ChainName, 15), Left(S.SupplierName, 15), SUM(totalqty*UnitRetail) as TotalRetail, I.ChainID, SUM(totalqty*Unitcost) totalcost, I.PaymentID
from InvoiceDetails I
Inner Join Chains C on C.ChainID = I.ChainID
Inner Join Suppliers S on I.SupplierID = S.SupplierId
inner Join Payments P on P.PaymentID = I.PaymentID
Where C.ChainID in (select EntityIDtoInclude 
		from ProcessStepEntities 
		where ProcessStepName Like 'prBilling_Payment_Create%'
		and IsActive = 1)
And cast(P.DateTimeCreated as date) = Convert(date, getdate())
and PaymentTypeID = 1
and RecordType = 0
Group by C.ChainName, S.SupplierName, I.ChainID, I.PaymentID

If @@ROWCOUNT > 0
Begin

UPDATE @tmpProcessedInvoices
SET chainname =  chainname + REPLICATE(' ', (14 - LEN(chainname)))
	WHERE LEN(chainname) < 15

UPDATE @tmpProcessedInvoices
SET SupplierName = SupplierName + REPLICATE(' ', (14 - LEN(SupplierName)))
	WHERE LEN(SupplierName) < 15

UPDATE @tmpProcessedInvoices
SET totalcost = Convert(varchar(50), convert(money,totalcost))+ REPLICATE(' ', (11 - LEN(convert(money,totalcost))))
WHERE LEN(convert(money, totalcost)) < 12

UPDATE @tmpProcessedInvoices
SET totalretail = CONVERT(varchar(50), convert(money, totalretail)) + REPLICATE(' ', (11 - LEN(convert(money, totalretail))))
WHERE LEN(CONVERT(money, totalretail)) < 12

UPDATE @tmpProcessedInvoices
SET PaymentId = CONVERT(varchar(50), PaymentId) + REPLICATE(' ', (9 - LEN(PaymentId)))
WHERE LEN(PaymentId) < 10

DECLARE @ProcessedRecords VARCHAR(MAX)
SET @ProcessedRecords = 'TOTAL COST'				 + CHAR(9) + CHAR(9)  
					+ 'TOTAL RETAIL'				 + CHAR(9) + CHAR(9) 
					+ 'PAYMENT ID'					 + CHAR(9) + CHAR(9)  
					+ 'CHAIN NAME'					 + CHAR(9) + CHAR(9)
					+ 'SUPPLIER NAME'				 + CHAR(13) + CHAR(10)    

SELECT @ProcessedRecords +=  x.totalcost	+ CHAR(9) + CHAR(9) 
					+ x.totalretail		    + CHAR(9) + CHAR(9)
					+ x.PaymentId			+ CHAR(9) + CHAR(9)
					+ chainname				+ CHAR(9) + CHAR(9)
					+ x.SupplierName		+ CHAR(13) + CHAR(10)
FROM @tmpProcessedInvoices x
Order by x.chainid, x.SupplierName

DECLARE @ProcessedEmailBody VARCHAR(MAX)
SET @ProcessedEmailBody = 'The following chains were billed.' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) +
									   CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + 
									   @ProcessedRecords + CHAR(13) + CHAR(10) 

--GET EMAIL ADDRESSES WHERE RECEIVE ACH NOTIFICATIONS IS TRUE
DECLARE @Processedemailaddresses VARCHAR(MAX) = ''
SET @Processedemailaddresses = 'datatrueit@icucsolutions.com; mindy.yu@icucsolutions.com; anthony.oginni@icucsolutions.com; edi@icucsolutions.com; invoices@icucsolutions.com; ap@icucsolutions.com'

EXEC dbo.[prSendEmailNotification_PassEmailAddresses_HTML_Logos] 'New Payments Have been Created'
  ,@ProcessedEmailBody
  ,'DataTrue System', 0, @Processedemailaddresses
  
END
End
GO
