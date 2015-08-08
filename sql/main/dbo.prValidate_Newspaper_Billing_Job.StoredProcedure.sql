USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidate_Newspaper_Billing_Job]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create PROCEDURE [dbo].[prValidate_Newspaper_Billing_Job]
AS

DECLARE @NewspaperChains TABLE
(
      ChainID INT,
      ChainIdentifier VARCHAR(150)
);

INSERT INTO @NewspaperChains (ChainID)
SELECT DISTINCT ss.ChainID
FROM DataTrue_Main.dbo.StoreSetup AS ss WITH (NOLOCK)
INNER JOIN DataTrue_Main.dbo.Suppliers AS s WITH (NOLOCK)
ON ss.SupplierID = s.SupplierID
WHERE s.IsRegulated = 0
and ss.ChainID in (select EntityIDToInclude 
					from dbo.ProcessStepEntities 
					 where ProcessStepName in ('prGetInboundPOSTransactions_Newspapers', 'prGetInboundPOSTransactions_PDI_Newspapers'))

UPDATE r
SET r.ChainIdentifier = (SELECT ChainIdentifier
                                   FROM DataTrue_Main.dbo.Chains AS c WITH (NOLOCK)
                                   WHERE c.ChainID = r.ChainID)
FROM @NewspaperChains AS r

--Select *
--from @NewspaperChains

DECLARE @current DATE
DECLARE @jobLastRan DATETIME

SELECT @jobLastRan = (SELECT JobLastRunDateTime FROM JobRunning WHERE JobName = 'DailyRegulatedBilling')

INSERT INTO DataTrue_Main.[dbo].[InvoicesRetailer_Errors_Newspapers]
(
        RetailerInvoiceID
      ,[ChainID]
      ,[InvoiceDate]
      ,[InvoicePeriodStart]
      ,[InvoicePeriodEnd]
      ,[OriginalAmount]
      ,[InvoiceTypeID]
      ,[TransmissionDate]
      ,[TransmissionRef]
      ,[InvoiceStatus]
      ,[OpenAmount]
      ,[DateTimeClosed]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[InvoiceDetailGroupID]
      ,[RawStoreIdentifier]
      ,[Route]
      ,[InvoiceNumber]
      ,[PaymentID]
      ,[PaymentDueDate]
      ,[StoreID]
      ,[AggregationID]

        ,[ErrorDetails]
)
SELECT
         RetailerInvoiceID
        ,[ChainID]
      ,[InvoiceDate]
      ,[InvoicePeriodStart]
      ,[InvoicePeriodEnd]
      ,[OriginalAmount]
      ,[InvoiceTypeID]
      ,[TransmissionDate]
      ,[TransmissionRef]
      ,[InvoiceStatus]
      ,[OpenAmount]
      ,[DateTimeClosed]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[InvoiceDetailGroupID]
      ,[RawStoreIdentifier]
      ,[Route]
      ,[InvoiceNumber]
      ,[PaymentID]
      ,[PaymentDueDate]
      ,[StoreID]
      ,[AggregationID]
      
      ,'Paymentid IS NULL Issue'
FROM 
      DataTrue_EDI.dbo.InvoicesRetailer 
WHERE
      Paymentid Is Null
AND CAST(DateTimeCreated as date) = @current
AND ChainID IN (SELECT DISTINCT ChainID FROM @NewsPaperChains)
AND InvoiceTypeID not in (14,15)
--GROUP BY 
--    CAST(DateTimeCreated as date),ChainID
--ORDER BY
--select * from DataTrue_Main.[dbo].[InvoicesRetailer_Errors_Newspapers] order by recordId desc


INSERT INTO DataTrue_Main.[dbo].[InvoicesRetailer_Errors_Newspapers]
(
         RetailerInvoiceID
      ,[ChainID]
      ,[InvoiceDate]
      ,[InvoicePeriodStart]
      ,[InvoicePeriodEnd]
      ,[OriginalAmount]
      ,[InvoiceTypeID]
      ,[TransmissionDate]
      ,[TransmissionRef]
      ,[InvoiceStatus]
      ,[OpenAmount]
      ,[DateTimeClosed]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[InvoiceDetailGroupID]
      ,[RawStoreIdentifier]
      ,[Route]
      ,[InvoiceNumber]
      ,[PaymentID]
      ,[PaymentDueDate]
      ,[StoreID]
      ,[AggregationID]

        ,[ErrorDetails]
)
SELECT
         RetailerInvoiceID
        ,[ChainID]
      ,[InvoiceDate]
      ,[InvoicePeriodStart]
      ,[InvoicePeriodEnd]
      ,[OriginalAmount]
      ,[InvoiceTypeID]
      ,[TransmissionDate]
      ,[TransmissionRef]
      ,[InvoiceStatus]
      ,[OpenAmount]
      ,[DateTimeClosed]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[InvoiceDetailGroupID]
      ,[RawStoreIdentifier]
      ,[Route]
      ,[InvoiceNumber]
      ,[PaymentID]
      ,[PaymentDueDate]
      ,[StoreID]
      ,[AggregationID]
      
      ,'Paymentid IS NULL Issue'
FROM 
      DataTrue_Main.dbo.InvoicesRetailer 
WHERE
      Paymentid Is Null
AND CAST(DateTimeCreated as date) = @current
AND ChainID IN (SELECT DISTINCT ChainID FROM @NewsPaperChains)
--GROUP BY 
--    CAST(DateTimeCreated as date),ChainID
--ORDER BY
--select * from DataTrue_Main.[dbo].[InvoicesRetailer_Errors_Newspapers] order by recordId desc

/*
--------- Clean NULLs
DELETE
FROM 
      DataTrue_Main.dbo.InvoicesRetailer 
WHERE
      Paymentid Is Null
AND CAST(DateTimeCreated as date) = @current
AND @ChainID = ChainID

--------- Clean NULLs
DELETE
FROM 
      DataTrue_EDI.dbo.InvoicesRetailer 
WHERE
      Paymentid Is Null
AND CAST(DateTimeCreated as date) = @current
AND @ChainID = ChainID
*/


-------------------------------------------------------------------
--
--         REGULATED  TOTAL(s) EDI vs. InvoiceDetails
--
-------------------------------------------------------------------


------------------------- CHECK 4 ERRORS ----------------------------------
IF EXISTS
(     
      SELECT 
      --TOP 10
            edi.DATE
            ,edi.Chain
            ,ROUND(edi.EDI_InvoicesRetailer_AMOUNT , 2)
            ,ROUND(inv.INVOICES_AMOUNT ,2)
      FROM
      (
      --- total by all suppliers
      select 
             DATE = CAST(datetimecreated as date)
            ,Chain =  ChainID
            ,EDI_InvoicesRetailer_AMOUNT = sum(originalamount)
      --    ,EDI_RECNO = COUNT(*)

      from DATATRUE_EDI.dbo.InvoicesRetailer
      where 
            ChainID IN (SELECT DISTINCT ChainID FROM @NewsPaperChains)
      and CAST(datetimecreated as date) = @current
      and InvoiceTypeID = 1
      --and PaymentID is not null (potential issue)
      -- order by RetailerInvoiceID desc
      group by
            CAST(datetimecreated as date), ChainID
      ) AS edi
      ------------------
      LEFT OUTER JOIN
      ------------------
      ( 
      --- total combined InvoiceDetails
      select 
             DATE = CAST(datetimecreated as date)
            ,CHAIN = ChainID
            ,INVOICES_AMOUNT = SUM(totalcost)
            ,INVOICES_RECNO = COUNT(*) 
      from 
            DATATRUE_MAIN.dbo.InvoiceDetails 
      where 
            ChainID IN (SELECT DISTINCT ChainID FROM @NewsPaperChains)
      AND CAST(datetimecreated as date) = @current
      and InvoiceDetailTypeID = 2
      group by
            ChainID,CAST(datetimecreated as date)
      ) AS inv
      ON 
            edi.date = inv.date
      AND edi.chain = inv.chain

      WHERE
            ROUND(edi.EDI_InvoicesRetailer_AMOUNT , 2) <> ROUND(inv.INVOICES_AMOUNT ,2)
)
BEGIN
      PRINT 'ISSUE'
      
      DECLARE @dt DATE
      DECLARE @Chain INT
      DECLARE @EDI_AMT DECIMAL(20,2)
      DECLARE @MAIN_AMT DECIMAL(20,2)
      
      SELECT 
      TOP 1
            @dt = edi.DATE
            ,@Chain = edi.Chain
            ,@EDI_AMT = ROUND(edi.EDI_InvoicesRetailer_AMOUNT , 2)
            ,@MAIN_AMT = ROUND(inv.INVOICES_AMOUNT ,2)
      FROM
      (
      --- total by all suppliers
      select 
             DATE = CAST(datetimecreated as date)
            ,Chain =  ChainID
            ,EDI_InvoicesRetailer_AMOUNT = sum(originalamount)
      --    ,EDI_RECNO = COUNT(*)

      from DATATRUE_EDI.dbo.InvoicesRetailer
      where 
            ChainID IN (SELECT DISTINCT ChainID FROM @NewsPaperChains)
      and CAST(datetimecreated as date) = @current
      and InvoiceTypeID not in (14,15)
      --and PaymentID is not null (potential issue)
      -- order by RetailerInvoiceID desc
      group by
            CAST(datetimecreated as date), ChainID
      ) AS edi
      ------------------
      LEFT OUTER JOIN
      ------------------
      ( 
      --- total combined InvoiceDetails
      select 
             DATE = CAST(datetimecreated as date)
            ,CHAIN = ChainID
            ,INVOICES_AMOUNT = SUM(totalcost)
            ,INVOICES_RECNO = COUNT(*) 
      from 
            DATATRUE_MAIN.dbo.InvoiceDetails 
      where 
            ChainID IN (SELECT DISTINCT ChainID FROM @NewsPaperChains)
      AND CAST(datetimecreated as date) = @current
      and InvoiceDetailTypeID = 2
      group by
            ChainID,CAST(datetimecreated as date)
      ) AS inv
      ON 
            edi.date = inv.date
      AND edi.chain = inv.chain

      WHERE
            ROUND(edi.EDI_InvoicesRetailer_AMOUNT , 2) <> ROUND(inv.INVOICES_AMOUNT ,2)
            
      DECLARE @body NVARCHAR(2000)
      SELECT @body = 'Daily Regulated Billing Job Validation is Failed.' + ' For ChainID=' + CONVERT(VARCHAR(20),@Chain) + ' as of date = [' + CONVERT(VARCHAR(20),@dt,102) + '] =>> [EDI InvoicesRetailer TOTAL AMOUNT] = ' + CONVERT(VARCHAR(20),@EDI_AMT) + ' [MAIN InvoiceDetails] = ' + CONVERT(VARCHAR(20), @MAIN_AMT) + ' [The DELTA IS] = ' + CONVERT(VARCHAR(20), CONVERT(DECIMAL(20,2),@EDI_AMT - @MAIN_AMT))
      
      --select @body
      
      EXEC dbo.prSendEmailNotification_PassEmailAddresses 'Daily Regulated Billing Job Validation is Failed. TOTAL in Details vs Retailers Amounts are not same.'
      ,@body
      ,'DataTrue System', 0
      ,'josh.kiracofe@icucsolutions.com'--'datatrueit@icontroldsd.com; edi@icontroldsd.com'--'datatrueit@icontroldsd.com; edi@icontroldsd.com'
      
      RAISERROR ('The Daily Regulated Billing stopped at Validation STAGE. VALIDATION is not completed.' , 16 , 1)
END



DECLARE @CALCTABLE TABLE (Chain INT, BilledAmt MONEY, ApprovedAmt MONEY, NotApprovedAmt MONEY, FailedValAmt MONEY, EDILoadedAmt MONEY, WebLoadedAmt MONEY)

--CHECK TOTALS VS EDI LOAD TOTALS
INSERT INTO @CALCTABLE
(
      Chain,
      BilledAmt,
      ApprovedAmt,
      NotApprovedAmt,
      FailedValAmt,
      EDILoadedAmt,
      WebLoadedAmt
)
SELECT IR.Chain AS Chain,
IR.EDI_InvoicesRetailer_AMOUNT AS BilledAmt,
COALESCE(Approved.EDI_Approved_AMOUNT, 0) AS ApprovedAmt, 
COALESCE(NotApproved.EDI_NotApprovedAMT, 0) AS NotApprovedAmt, 
COALESCE(RecordValidation.EDI_FailedValidation, 0) AS FailedValAmt, 
COALESCE(EDILoad.TotalAmt, 0) AS EDILoadedAmt,
COALESCE(Web.EDI_WebTotal, 0) AS WebLoadedAmt
FROM
(
      SELECT 
       DATE = CAST(datetimecreated AS DATE)
      ,Chain =  ChainID
      ,EDI_InvoicesRetailer_AMOUNT = SUM(originalamount)
      FROM DATATRUE_EDI.dbo.InvoicesRetailer AS IR WITH (NOLOCK)
      WHERE 1 = 1
      --AND CAST(datetimecreated AS DATE) = @current
      AND DateTimeCreated >= @jobLastRan
      AND InvoiceTypeID = 1
      AND ChainID IN (SELECT DISTINCT ChainID FROM @NewsPaperChains)
      --AND ABS(OriginalAmount) > '.01'
      GROUP BY
            CAST(datetimecreated AS DATE), ChainID
) AS IR
LEFT OUTER JOIN
(
   SELECT
      Chain = DataTrueChainID
   ,EDI_WebTotal = SUM((CASE PurposeCode WHEN 'CR' THEN Qty * -1 ELSE Qty END) * Cost + CONVERT(MONEY,Adjustment1) + CONVERT(MONEY,Adjustment2) + CONVERT(MONEY,AllowanceChargeAmount))
   FROM [DataTrue_EDI].[dbo].[InboundInventory_Web]
   WHERE DataTrueChainID IN (SELECT DISTINCT ChainID FROM @NewsPaperChains)
   AND DateTimeCreated >= @jobLastRan
   AND RecordStatus = 2
   GROUP BY DataTrueChainID
) AS Web
ON Web.Chain = IR.Chain
LEFT OUTER JOIN
(
      SELECT
      ChainName
      ,EDI_Approved_AMOUNT =  CONVERT(DECIMAL(20,2),  
                                                  SUM(Qty*Cost) 
                                                 +SUM(CONVERT(float,ISNULL(AlllowanceChargeAmount1,0)))
                                                +SUM(CONVERT(float,ISNULL(AlllowanceChargeAmount2,0)))
                                                +SUM(CONVERT(float,ISNULL(AlllowanceChargeAmount3,0)))
                                                +SUM(CONVERT(float,ISNULL(AlllowanceChargeAmount4,0)))
                                                +SUM(CONVERT(float,ISNULL(AlllowanceChargeAmount5,0)))
                                                +SUM(CONVERT(float,ISNULL(AlllowanceChargeAmount6,0)))
                                                +SUM(CONVERT(float,ISNULL(AlllowanceChargeAmount7,0)))
                                                +SUM(CONVERT(float,ISNULL(AlllowanceChargeAmount8,0)))
                                                )
      FROM DataTrue_EDI.dbo.Inbound846Inventory_ACH_Approval WITH (NOLOCK)
      WHERE ChainName IN (SELECT DISTINCT ChainIdentifier FROM Chains WHERE ChainID IN (SELECT DISTINCT ChainID FROM @NewsPaperChains))
      AND ISNULL(ApprovalTimeStamp, TimeStamp) >= @jobLastRan
      AND RecordStatus = 1
      GROUP BY ChainName
) AS Approved
--ON Approved.DATE = IR.DATE
ON Approved.ChainName = (SELECT ChainIdentifier FROM Chains WITH (NOLOCK) WHERE ChainID = IR.Chain)
LEFT OUTER JOIN
(
      SELECT
      ChainName
      ,EDI_NotApprovedAMT =  CONVERT(DECIMAL(20,2),   
                                                  SUM(Qty*Cost) 
                                                 +SUM(CONVERT(float,ISNULL(AlllowanceChargeAmount1,0)))
                                                +SUM(CONVERT(float,ISNULL(AlllowanceChargeAmount2,0)))
                                                +SUM(CONVERT(float,ISNULL(AlllowanceChargeAmount3,0)))
                                                +SUM(CONVERT(float,ISNULL(AlllowanceChargeAmount4,0)))
                                                +SUM(CONVERT(float,ISNULL(AlllowanceChargeAmount5,0)))
                                                +SUM(CONVERT(float,ISNULL(AlllowanceChargeAmount6,0)))
                                                +SUM(CONVERT(float,ISNULL(AlllowanceChargeAmount7,0)))
                                                +SUM(CONVERT(float,ISNULL(AlllowanceChargeAmount8,0)))
                                                )
      FROM DataTrue_EDI.dbo.Inbound846Inventory_ACH_Approval WITH (NOLOCK)
      WHERE ChainName IN (SELECT DISTINCT ChainIdentifier FROM Chains WHERE ChainID IN (SELECT DISTINCT ChainID FROM @NewsPaperChains))
      AND ISNULL(ApprovalTimeStamp, TimeStamp) >= @jobLastRan
      AND RecordStatus <> 1
      GROUP BY ChainName
) AS NotApproved
--ON Approved.DATE = IR.DATE
ON NotApproved.ChainName = (SELECT ChainIdentifier FROM Chains WITH (NOLOCK) WHERE ChainID = IR.Chain)
LEFT OUTER JOIN
(
      SELECT
      ChainName
      ,EDI_FailedValidation =  CONVERT(DECIMAL(20,2), 
                                                  SUM(Qty*Cost) 
                                                 +SUM(CONVERT(float,ISNULL(AlllowanceChargeAmount1,0)))
                                                +SUM(CONVERT(float,ISNULL(AlllowanceChargeAmount2,0)))
                                                +SUM(CONVERT(float,ISNULL(AlllowanceChargeAmount3,0)))
                                                +SUM(CONVERT(float,ISNULL(AlllowanceChargeAmount4,0)))
                                                +SUM(CONVERT(float,ISNULL(AlllowanceChargeAmount5,0)))
                                                +SUM(CONVERT(float,ISNULL(AlllowanceChargeAmount6,0)))
                                                +SUM(CONVERT(float,ISNULL(AlllowanceChargeAmount7,0)))
                                                +SUM(CONVERT(float,ISNULL(AlllowanceChargeAmount8,0)))
                                                )
      FROM DataTrue_EDI.dbo.Inbound846Inventory_ACH WITH (NOLOCK)       
      WHERE ChainName IN (SELECT DISTINCT ChainIdentifier FROM Chains WHERE ChainID IN (SELECT DISTINCT ChainID FROM @NewsPaperChains))
      AND TimeStamp >= @jobLastRan
      AND RecordStatus NOT IN (0, 1)
      GROUP BY ChainName
) AS RecordValidation
ON RecordValidation.ChainName = (SELECT ChainIdentifier FROM Chains WITH (NOLOCK) WHERE ChainID = IR.Chain)
LEFT OUTER JOIN
(
      SELECT
      Chain = (SELECT ChainID FROM Chains WITH (NOLOCK) WHERE ChainIdentifier = Chain)
      ,SUM(TotalAmt) - SUM(BilledAmt) - SUM(RejectedAmt) - SUM(FailedValidationAmt) - SUM(PendingAmt) AS TotalAmt
      FROM DataTrue_Main.dbo.Main_LoadStatus_ACH AS ACH WITH (NOLOCK)
      WHERE (SELECT ChainID FROM DataTrue_Main..Chains WHERE ChainIdentifier = Chain) IN (SELECT DISTINCT ChainID FROM @NewsPaperChains)
      AND LoadStatus IN (2)
      AND ISNULL(UpdatedTimeStamp, DateLoaded) >= @jobLastRan
      GROUP BY Chain
) AS EDILoad
ON EDILoad.Chain = IR.Chain

--CHECK FOR BILLED CHAIN COUNT > 0
IF
(SELECT COUNT(DISTINCT Chain)
FROM @CALCTABLE) = 0
      BEGIN
            DECLARE @body1 NVARCHAR(2000)
            SELECT @body1 = 
            'Daily Regulated Billing Job Validation is Failed.' 
            + 'No chains have been processed.'
            EXEC dbo.prSendEmailNotification_PassEmailAddresses 'Daily Regulated Billing Job Validation has Failed.'
            ,@body1
            ,'DataTrue System', 0
            ,'datatrueit@icontroldsd.com; edi@icontroldsd.com'--'datatrueit@icontroldsd.com; edi@icontroldsd.com'
            RAISERROR ('The Daily Regulated Billing stopped at Validation STAGE. VALIDATION is not completed.' , 16 , 1)
      END

DECLARE @CALCROWS INT

SELECT * FROM @CALCTABLE
WHERE CONVERT(MONEY,BilledAmt) <> CONVERT(MONEY,((EDILoadedAmt + WebLoadedAmt)))
SELECT @CALCROWS = @@ROWCOUNT
IF @CALCROWS > 0
      BEGIN
            DECLARE @body2 NVARCHAR(2000)
            SELECT @body2 = 
            'Daily Regulated Billing Job Validation is Failed.' 
            + 'Loaded amount - rejected amount does not equal billed amount.'
            EXEC dbo.prSendEmailNotification_PassEmailAddresses 'Daily Regulated Billing Job Validation has Failed.'
            ,@body2
            ,'DataTrue System', 0
            ,'datatrueit@icontroldsd.com; edi@icontroldsd.com'--'datatrueit@icontroldsd.com; edi@icontroldsd.com'
            RAISERROR ('The Daily Regulated Billing stopped at Validation STAGE. VALIDATION is not completed.' , 16 , 1)
      END

SELECT * FROM @CALCTABLE
WHERE CONVERT(MONEY,BilledAmt) <> CONVERT(MONEY, ApprovedAmt)
SELECT @CALCROWS = @@ROWCOUNT
IF @CALCROWS > 0
      BEGIN
            DECLARE @body3 NVARCHAR(2000)
            SELECT @body3 = 
            'Daily Regulated Billing Job Validation is Failed.' 
            + 'EDI Approved amount does not equal billed amount.'
            EXEC dbo.prSendEmailNotification_PassEmailAddresses 'Daily Regulated Billing Job Validation has Failed.'
            ,@body3
            ,'DataTrue System', 0
            ,'datatrueit@icontroldsd.com; edi@icontroldsd.com'--'datatrueit@icontroldsd.com; edi@icontroldsd.com'
            RAISERROR ('The Daily Regulated Billing stopped at Validation STAGE. VALIDATION is not completed.' , 16 , 1)
      END

------------------------- CHECK 4 ERRORS <END> ----------------------------------

UPDATE h 
SET 
h.RawstoreIdentifier = d.RawstoreIdentifier, 
h.InvoiceNumber = d.InvoiceNo, h.PaymentDueDate = d.PaymentDueDate, 
h.Route = d.Route, h.storeid = d.storeid
FROM 
      DATATRUE_MAIN.dbo.InvoicesRetailer h
      ---------------
      INNER JOIN 
      ---------------
      DATATRUE_MAIN.dbo.InvoiceDetails d

ON h.RetailerInvoiceID = d.RetailerInvoiceID
WHERE 
      h.chainid IN (SELECT DISTINCT ChainID FROM @NewsPaperChains)
AND CAST(h.datetimecreated as date) = @current

-----------------------------------------------------------------

UPDATE h 
SET 
h.RawstoreIdentifier = d.RawstoreIdentifier, 
h.InvoiceNumber = d.InvoiceNo, h.PaymentDueDate = d.PaymentDueDate, 
h.Route = d.Route, h.storeid = d.storeid
FROM 
      DATATRUE_EDI.dbo.InvoicesRetailer h
      ---------------
      INNER JOIN 
      ---------------
      DATATRUE_EDI.dbo.InvoiceDetails d

ON h.RetailerInvoiceID = d.RetailerInvoiceID
WHERE 
      h.chainid IN (SELECT DISTINCT ChainID FROM @NewsPaperChains)
AND CAST(h.datetimecreated as date) = @current

-----------------------------------------------------------------

Update DataTrue_EDI.dbo.ProcessStatus_ach
Set BillingComplete = 1, OutBoundComplete = 0, StartProcess = 0
Where [Date] = CONVERT(DATE,GETDATE())
and BillingIsRunning = 1
and BillingComplete = 0

-----------------------------------------------------------------

Update DataTrue_Main.dbo.JobRunning
Set JobIsRunningNow = 0
Where JobName = 'DailyRegulatedBilling'

-----------------------------------------------------------------

--exec DATATRUE_Main.dbo.prSendEmailNotification_PassEmailAddresses 'VALIDATION FOR => Daily Regulated Billing Job is Completed'
--,'VALIDATION FOR => Daily Regulated Billing Job  is Completed'
--,'DataTrue System', 0, 'datatrueit@icontroldsd.com; edi@icontroldsd.com'



------
GO
