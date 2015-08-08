USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidate_Regulated_Billing_Job_ACH_Payments_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[prValidate_Regulated_Billing_Job_ACH_Payments_PRESYNC_20150415]
AS

DECLARE @current DATE
DECLARE @jobLastRan DATETIME

BEGIN TRY

IF (SELECT DATEPART(DW, GETDATE())) IN (1, 7)
	BEGIN
		EXEC msdb.dbo.sp_stop_job 'Billing_Regulated'
		RAISERROR ('The Daily Regulated Billing stopped at Validation STAGE. Payments created on weekend.' , 16 , 1)
	END

SELECT @jobLastRan = (SELECT PaymentLastRunDateTime FROM JobRunning WHERE JobName = 'DailyRegulatedBilling' AND JobRunningID = 3)

DECLARE @RegulatedChains TABLE
(
	ChainID INT,
	ChainIdentifier VARCHAR(150)
);

INSERT INTO @RegulatedChains (ChainID)
SELECT DISTINCT ChainID FROM DataTrue_EDI..InvoicesRetailer AS IR WITH (NOLOCK)
WHERE ProcessID IN (SELECT ProcessID FROM DataTrue_Main.dbo.JobProcesses WHERE Timestamp > @jobLastRan)

UPDATE r
SET r.ChainIdentifier = (SELECT ChainIdentifier
					     FROM DataTrue_Main.dbo.Chains AS c WITH (NOLOCK)
					     WHERE c.ChainID = r.ChainID)
FROM @RegulatedChains AS r	



DECLARE @CALCTABLE TABLE (ChainID INT, SupplierID INT, BilledAmt NUMERIC(18, 9), SUPInvoiceCount INT, RETInvoiceCount INT, PaymentAmt NUMERIC(18, 9), ExcludedPaymentAmt NUMERIC(18, 9), HeldPaymentAmt NUMERIC(18, 9), ReleasedPaymentAmt NUMERIC(18, 9), HeldOngoingAmt NUMERIC(18, 9))

--CHECK TOTALS VS EDI LOAD TOTALS
INSERT INTO @CALCTABLE
(
	ChainID,
	SupplierID,
	BilledAmt,
	SUPInvoiceCount,
	RETInvoiceCount,
	PaymentAmt,
	ExcludedPaymentAmt,
	HeldPaymentAmt,
	ReleasedPaymentAmt,
	HeldOngoingAmt
)
SELECT 
IR.ChainID AS ChainID,
IR.SupplierID,
SUM(IR.TotalBilled) AS BilledAmt,
SUM(IR.SUPInvoiceCount) AS SUPInvoiceCount,
SUM(IR.RETInvoiceCount) AS RETInvoiceCount,
COALESCE(Payments.PaymentAmt, 0) AS PaymentAmt,
COALESCE(SUM(ExcludedPayments.PaymentAmt), 0) AS ExcludedPaymentAmt,
COALESCE(SUM(HeldPayments.HeldPaymentAmt), 0) AS HeldPaymentAmt,
COALESCE(SUM(ReleasedPayments.ReleasedPaymentAmt), 0) AS ReleasedPaymentAmt,
COALESCE(SUM(HeldOngoing.HeldOngoingAmt), 0) AS HeldOngoingAmt
FROM
(
	SELECT ChainId, SupplierID, SUM(TotalBilled) AS TotalBilled, SUM(SUPInvoiceCount) AS SUPInvoiceCount, SUM(RETInvoiceCount) AS RETInvoiceCount
	FROM
	(
	SELECT
	id2.ChainID,
	id2.SupplierID,
	s.SourceName,
	id2.InvoiceNo,
	ROUND(SUM(CONVERT(NUMERIC(18, 9), id2.TotalCost)), 2) AS TotalBilled,
	COUNT(DISTINCT id2.InvoiceNo) AS SUPInvoiceCount,
	COUNT(DISTINCT id2.RetailerInvoiceID) AS RETInvoiceCount
	FROM DataTrue_EDI.dbo.InvoiceDetails AS id
	INNER JOIN DataTrue_Main.dbo.InvoiceDetails AS id2
	ON id.InvoiceDetailID = id2.InvoiceDetailID
	INNER JOIN DataTrue_Main.dbo.Source AS s
	ON id2.SourceID = s.SourceID
	LEFT OUTER JOIN DataTrue_Main.dbo.Payments AS p
	ON id2.PaymentID = p.PaymentID
	WHERE 1 = 1
	AND id2.DateTimeCreated >= @jobLastRan
	AND id2.InvoiceDetailTypeID = 2
	AND id2.ChainID IN (SELECT DISTINCT ChainID FROM @RegulatedChains)
	AND ISNULL(p.IsPennyTest, 0) = 0
	GROUP BY id2.ChainID, id2.SupplierID, s.SourceName, id2.InvoiceNo
	) AS t
	GROUP BY t.ChainID, t.SupplierID
) AS IR
LEFT OUTER JOIN
(
	SELECT
	ChainID,
	SupplierID,
	SUM(CASE WHEN PaymentTypeID = 4 THEN (AmountOriginallyBilled) ELSE (AmountOriginallyBilled * -1) END) AS PaymentAmt
	FROM DataTrue_EDI.dbo.Payments AS p WITH (NOLOCK)
	WHERE 1 = 1
	AND PaymentTypeID IN (4,5)
	AND DateTimeCreated > @jobLastRan 
	AND ISNULL(IsPennyTest, 0) = 0
	GROUP BY ChainID, SupplierID
) AS Payments
ON Payments.ChainID = IR.ChainID
AND Payments.SupplierID = IR.SupplierID
LEFT OUTER JOIN
(
	SELECT ChainId, SupplierID, SUM(PaymentAmt) AS PaymentAmt
	FROM
	(
	SELECT
	id2.ChainID,
	id2.SupplierID,
	id2.InvoiceNo,
	s.SourceName,
	ROUND(SUM(id2.TotalCost), 2) AS PaymentAmt
	FROM DataTrue_EDI.dbo.InvoiceDetails AS id
	INNER JOIN DataTrue_Main.dbo.InvoiceDetails AS id2
	ON id.InvoiceDetailID = id2.InvoiceDetailID
	INNER JOIN DataTrue_Main.dbo.Source AS s
	ON id2.SourceID = s.SourceID
	WHERE 1 = 1
	AND id2.InvoiceDetailTypeID IN (2)
	AND id2.DateTimeCreated > @jobLastRan 
	AND id2.PaymentID IS NULL
	AND id2.RecordType = 3
	GROUP BY id2.ChainID, id2.SupplierID, id2.InvoiceNo, SourceName
	) AS t
	GROUP BY ChainID, SupplierID
) AS ExcludedPayments
ON ExcludedPayments.ChainID = IR.ChainID
AND ExcludedPayments.SupplierID = IR.SupplierID
LEFT OUTER JOIN
(
	SELECT ChainId, SupplierID, SUM(HeldPaymentAmt) AS HeldPaymentAmt
	FROM
	(
	SELECT
	i.ChainID,
	i.SupplierID,
	i.InvoiceNo,
	s.SourceName,
	ROUND(SUM(CASE WHEN ReleasedDateTime IS NULL THEN i.TotalCost ELSE (i.TotalCost * -1) END), 2) AS HeldPaymentAmt
	FROM [DataTrue_Main].[dbo].[BillingControl_Payments_Held] AS p
	INNER JOIN DataTrue_Main.dbo.InvoiceDetails AS i
	ON p.RetailerInvoiceID = i.RetailerInvoiceID
	INNER JOIN DataTrue_Main.dbo.Source AS s
	ON i.SourceID = s.SourceID
	WHERE 1 = 1
	AND Timestamp > @jobLastRan 
	AND ReleasedDateTime IS NULL
	GROUP BY i.ChainID, i.SupplierID, s.SourceName, i.InvoiceNo
	) t
	GROUP BY ChainID, SupplierID
) AS HeldPayments
ON HeldPayments.ChainID = IR.ChainID
AND HeldPayments.SupplierID = IR.SupplierID
LEFT OUTER JOIN
(
	SELECT ChainId, SupplierID, SUM(HeldPaymentAmt) AS ReleasedPaymentAmt
	FROM
	(
	SELECT
	i.ChainID,
	i.SupplierID,
	i.InvoiceNo,
	s.SourceName,
	ROUND(SUM(i.TotalCost), 2) AS HeldPaymentAmt
	FROM [DataTrue_Main].[dbo].[BillingControl_Payments_Held] AS p
	INNER JOIN DataTrue_Main.dbo.InvoiceDetails AS i
	ON p.RetailerInvoiceID = i.RetailerInvoiceID
	INNER JOIN DataTrue_Main.dbo.Source AS s
	ON i.SourceID = s.SourceID
	WHERE 1 = 1
	AND ReleasedDateTime > @jobLastRan
	AND ReleasedDateTime IS NOT NULL
	GROUP BY i.ChainID, i.SupplierID, s.SourceName, i.InvoiceNo
	) t
	GROUP BY ChainID, SupplierID
) AS ReleasedPayments
ON ReleasedPayments.ChainID = IR.ChainID
AND ReleasedPayments.SupplierID = IR.SupplierID
LEFT OUTER JOIN
(
	SELECT ChainId, SupplierID, SUM(HeldPaymentAmt) AS HeldOngoingAmt
	FROM
	(
	SELECT
	i.ChainID,
	i.SupplierID,
	i.InvoiceNo,
	s.SourceName,
	ROUND(SUM(i.TotalCost), 2) AS HeldPaymentAmt
	FROM [DataTrue_Main].[dbo].[BillingControl_Payments_Held] AS p
	INNER JOIN DataTrue_Main.dbo.InvoiceDetails AS i
	ON p.RetailerInvoiceID = i.RetailerInvoiceID
	INNER JOIN DataTrue_Main.dbo.Source AS s
	ON i.SourceID = s.SourceID
	WHERE 1 = 1
	AND ReleasedDateTime IS NULL
	GROUP BY i.ChainID, i.SupplierID, s.SourceName, i.InvoiceNo
	) t
	GROUP BY ChainID, SupplierID
) AS HeldOngoing
ON HeldOngoing.ChainID = IR.ChainID
AND HeldOngoing.SupplierID = IR.SupplierID
GROUP BY IR.ChainID, IR.SupplierID, Payments.PaymentAmt
ORDER BY BilledAmt DESC

INSERT INTO @CALCTABLE
(
	ChainID,
	SupplierID,
	BilledAmt,
	SUPInvoiceCount,
	RETInvoiceCount,
	PaymentAmt,
	ExcludedPaymentAmt,
	HeldPaymentAmt,
	ReleasedPaymentAmt,
	HeldOngoingAmt
)
SELECT 
p.ChainID,
p.SupplierID,
0, --BilledAmt
0, --SUPInvoiceCount
0, --RETInvoiceCount
0, --PaymentAmt
0, --ExcludedPaymentAmt
0, --HeldPaymentAmt
ROUND(SUM(p.TotalAmount), 2) AS ReleasedPaymentAmt, --ReleasedPaymentAmt
0 --HeldOngoingAmt
FROM [DataTrue_Main].[dbo].[BillingControl_Payments_Held] AS p
LEFT OUTER JOIN @CALCTABLE AS c
ON p.ChainID = c.ChainID
AND p.SupplierID = c.SupplierID
WHERE CONVERT(DATE, p.ReleasedDateTime) = CONVERT(DATE, GETDATE())
AND c.ChainID IS NULL
AND c.SupplierID IS NULL
GROUP BY p.ChainID, p.SupplierID
HAVING ROUND(SUM(p.TotalAmount), 2) <> 0

UPDATE c
SET c.HeldOngoingAmt = p.HeldOngoingAmt
FROM @CALCTABLE AS c
INNER JOIN 
(
SELECT ChainId, SupplierID, SUM(HeldPaymentAmt) AS HeldOngoingAmt
	FROM
	(
	SELECT
	i.ChainID,
	i.SupplierID,
	i.InvoiceNo,
	s.SourceName,
	ROUND(SUM(i.TotalCost), 2) AS HeldPaymentAmt
	FROM [DataTrue_Main].[dbo].[BillingControl_Payments_Held] AS p
	INNER JOIN DataTrue_Main.dbo.InvoiceDetails AS i
	ON p.RetailerInvoiceID = i.RetailerInvoiceID
	INNER JOIN DataTrue_Main.dbo.Source AS s
	ON i.SourceID = s.SourceID
	WHERE 1 = 1
	AND ReleasedDateTime IS NULL
	GROUP BY i.ChainID, i.SupplierID, s.SourceName, i.InvoiceNo
	) t
	GROUP BY ChainID, SupplierID
) AS p
ON c.ChainID = p.ChainID
AND c.SupplierID = p.SupplierID
WHERE p.HeldOngoingAmt <> 0 AND c.PaymentAmt = 0

INSERT INTO @CALCTABLE
(
	ChainID,
	SupplierID,
	BilledAmt,
	SUPInvoiceCount,
	RETInvoiceCount,
	PaymentAmt,
	ExcludedPaymentAmt,
	HeldPaymentAmt,
	ReleasedPaymentAmt,
	HeldOngoingAmt
)
SELECT 
p.ChainID,
p.SupplierID,
0, --BilledAmt
0, --SUPInvoiceCount
0, --RETInvoiceCount
0, --PaymentAmt
0, --ExcludedPaymentAmt
0, --HeldPaymentAmt
0, --ReleasedPaymentAmt
ROUND(SUM(p.TotalAmount), 2) AS HeldOngoingAmt --HeldOngoingAmt
FROM [DataTrue_Main].[dbo].[BillingControl_Payments_Held] AS p
LEFT OUTER JOIN @CALCTABLE AS c
ON p.ChainID = c.ChainID
AND p.SupplierID = c.SupplierID
WHERE p.ReleasedDateTime IS NULL
AND c.ChainID IS NULL
AND c.SupplierID IS NULL
GROUP BY p.ChainID, p.SupplierID
HAVING ROUND(SUM(p.TotalAmount), 2) <> 0

UPDATE c
SET c.PaymentAmt = p.PaymentAmt
FROM @CALCTABLE AS c
INNER JOIN 
(
SELECT
ChainID,
SupplierID,
SUM(CASE WHEN PaymentTypeID = 4 THEN (AmountOriginallyBilled) ELSE (AmountOriginallyBilled * -1) END) AS PaymentAmt
FROM DataTrue_EDI.dbo.Payments AS p WITH (NOLOCK)
WHERE 1 = 1
AND PaymentTypeID IN (4,5)
AND DateTimeCreated > @jobLastRan 
AND ISNULL(IsPennyTest, 0) = 0
GROUP BY ChainID, SupplierID
) AS p
ON c.ChainID = p.ChainID
AND c.SupplierID = p.SupplierID
WHERE p.PaymentAmt <> 0 AND c.PaymentAmt = 0


DELETE FROM @CALCTABLE WHERE BilledAmt = 0 AND PaymentAmt = 0 AND HeldOngoingAmt = 0

--CHECK FOR BILLED CHAIN COUNT > 0
IF
(SELECT COUNT(DISTINCT ChainID)
FROM @CALCTABLE) = 0
	BEGIN
		DECLARE @body1 NVARCHAR(2000)
		SELECT @body1 = 
		'Daily Regulated Billing Job Validation has Failed.' 
		+ 'No chains have been processed.'
		EXEC dbo.prSendEmailNotification_PassEmailAddresses 'Daily Regulated Billing Job Validation has Failed.'
		,@body1
		,'DataTrue System', 0
		,'datatrueit@icontroldsd.com; edi@icontroldsd.com'--'datatrueit@icontroldsd.com; edi@icontroldsd.com'
		RAISERROR ('The Daily Regulated Billing stopped at Validation STAGE. VALIDATION is not completed.' , 16 , 1)
	END

DECLARE @CALCROWS INT


--SELECT * FROM @CALCTABLE  --FOR TESTING
	
SELECT * FROM @CALCTABLE
WHERE CONVERT(MONEY,PaymentAmt) <> (CONVERT(MONEY,BilledAmt) + CONVERT(MONEY,(ExcludedPaymentAmt * -1)) + CONVERT(MONEY,(HeldPaymentAmt * -1)) + CONVERT(MONEY,ReleasedPaymentAmt))
SELECT @CALCROWS = @@ROWCOUNT
IF @CALCROWS > 0
	BEGIN
		DECLARE @body4 NVARCHAR(2000)
		SELECT @body4 = 
		'Daily Regulated Billing Job Validation has Failed.' 
		+ 'Payment amount does not equal billed amount.'
		EXEC dbo.prSendEmailNotification_PassEmailAddresses 'Daily Regulated Billing Job Validation has Failed.'
		,@body4
		,'DataTrue System', 0
		,'datatrueit@icontroldsd.com; edi@icontroldsd.com'--'datatrueit@icontroldsd.com; edi@icontroldsd.com'
		RAISERROR ('The Daily Regulated Billing stopped at Validation STAGE. VALIDATION is not completed.' , 16 , 1)
	END


DECLARE @emailSubject VARCHAR(100)
DECLARE @emailBody VARCHAR(MAX)
DECLARE @emailRecipients VARCHAR(500)

SET @emailSubject = 'Daily Report - Supplier Invoices Billing'

SET @emailBody = 'Daily Report - Supplier Invoices Billing:' + CHAR(13) + CHAR(10)

SET @emailBody = @emailBody + CHAR(13) + CHAR(10) + 'CHAIN NAME          ' + CHAR(9) + 'SUPPLIER NAME       ' + CHAR(9) + 'BILLED $' + CHAR(9) + 'SUPINV #' + CHAR(9) + 'RETINV #' + CHAR(9) + 'REG ACH $'  + CHAR(9) + 'NON-REG $' + CHAR(9) + 'HELD $    ' + CHAR(9) + 'RELEASED $' + CHAR(9) + 'HELD ONGOING $' + CHAR(13) + CHAR(10)	
	
SET @emailRecipients = 'edi@icucsolutions.com; datatrueit@icucsolutions.com; tal.zlot@icucsolutions.com; sean.zlotnitsky@icucsolutions.com; mindy.yu@icucsolutions.com; robert.noe@icucsolutions.com; bill.harris@icucsolutions.com; mark.lopez@icucsolutions.com'
--SET @emailRecipients = 'william.heine@icucsolutions.com'

DECLARE @EmailSelectCount INT

SELECT * FROM @CALCTABLE

SELECT @emailbody+=TXT
FROM
(SELECT  (SELECT LTRIM(RTRIM(LEFT(ChainName, 20))) FROM DataTrue_Main.dbo.Chains WHERE ChainID = calc.ChainID)
			+ REPLICATE(' ', (20 - LEN((SELECT LTRIM(RTRIM(LEFT(ChainName, 20))) FROM DataTrue_Main.dbo.Chains c WHERE c.ChainID = calc.ChainID)))) + CHAR(9)
			+ (SELECT LTRIM(RTRIM(LEFT(SupplierName, 20))) FROM DataTrue_Main.dbo.Suppliers s WHERE s.SupplierID = calc.SupplierID)
			+ REPLICATE(' ', (20 - LEN((SELECT LTRIM(RTRIM(LEFT(s.SupplierName, 20))) FROM DataTrue_Main.dbo.Suppliers s WHERE s.SupplierID = calc.SupplierID)))) + CHAR(9)
			+ '$' + CONVERT(VARCHAR(50), CONVERT(MONEY, BilledAmt)) + REPLICATE(' ', (14 - LEN(CONVERT(VARCHAR(50), CONVERT(MONEY, BilledAmt))))) + CHAR(9)
			+ CONVERT(VARCHAR(50), CONVERT(INT, SUPInvoiceCount)) + REPLICATE(' ', (8 - LEN(CONVERT(VARCHAR(50), CONVERT(INT, SUPInvoiceCount))))) + CHAR(9)
			+ CONVERT(VARCHAR(50), CONVERT(INT, RETInvoiceCount)) + REPLICATE(' ', (8 - LEN(CONVERT(VARCHAR(50), CONVERT(INT, RETInvoiceCount))))) + CHAR(9)
			+ '$' + CONVERT(VARCHAR(50), CONVERT(MONEY, PaymentAmt)) + REPLICATE(' ', (9 - LEN(CONVERT(VARCHAR(50), CONVERT(MONEY, PaymentAmt))))) + CHAR(9) 
			+ '$' + CONVERT(VARCHAR(50), CONVERT(MONEY, ExcludedPaymentAmt)) + REPLICATE(' ', (9 - LEN(CONVERT(VARCHAR(50), CONVERT(MONEY, (BilledAmt - PaymentAmt - ExcludedPaymentAmt)))))) + CHAR(9) 
			+ '$' + CONVERT(VARCHAR(50), CONVERT(MONEY, HeldPaymentAmt)) + REPLICATE(' ', (10 - LEN(CONVERT(VARCHAR(50), CONVERT(MONEY, HeldPaymentAmt))))) + CHAR(9) 
			+ '$' + CONVERT(VARCHAR(50), CONVERT(MONEY, ReleasedPaymentAmt)) + REPLICATE(' ', (10 - LEN(CONVERT(VARCHAR(50), CONVERT(MONEY, ReleasedPaymentAmt))))) + CHAR(9) 
			+ '$' + CONVERT(VARCHAR(50), CONVERT(MONEY, HeldOngoingAmt)) + REPLICATE(' ', (10 - LEN(CONVERT(VARCHAR(50), CONVERT(MONEY, HeldOngoingAmt))))) + CHAR(13) + CHAR(10)
FROM @CALCTABLE as calc    
ORDER BY BilledAmt DESC
FOR XML PATH(''))x(TXT)

SELECT @emailBody += 'TOTALS              ' + CHAR(9) + '                    ' + CHAR(9)
				  + '$' + CONVERT(VARCHAR(50), CONVERT(MONEY, SUM(BilledAmt))) + REPLICATE(' ', (14 - LEN(CONVERT(VARCHAR(50), CONVERT(MONEY, SUM(BilledAmt)))))) + CHAR(9)
				  + CONVERT(VARCHAR(50), CONVERT(INT, SUM(SUPInvoiceCount))) + REPLICATE(' ', (8 - LEN(CONVERT(VARCHAR(50), CONVERT(INT, SUM(SUPInvoiceCount)))))) + CHAR(9)
				  + CONVERT(VARCHAR(50), CONVERT(INT, SUM(RETInvoiceCount))) + REPLICATE(' ', (8 - LEN(CONVERT(VARCHAR(50), CONVERT(INT, SUM(RETInvoiceCount)))))) + CHAR(9)
				  + '$' + CONVERT(VARCHAR(50), CONVERT(MONEY, SUM(PaymentAmt))) + REPLICATE(' ', (9 - LEN(CONVERT(VARCHAR(50), CONVERT(MONEY, SUM(PaymentAmt)))))) + CHAR(9) 
				  + '$' + CONVERT(VARCHAR(50), CONVERT(MONEY, SUM(ExcludedPaymentAmt))) + REPLICATE(' ', (9 - LEN(CONVERT(VARCHAR(50), CONVERT(MONEY, SUM(BilledAmt - PaymentAmt - ExcludedPaymentAmt)))))) + CHAR(9) 
				  + '$' + CONVERT(VARCHAR(50), CONVERT(MONEY, SUM(HeldPaymentAmt))) + REPLICATE(' ', (10 - LEN(CONVERT(VARCHAR(50), CONVERT(MONEY, SUM(HeldPaymentAmt)))))) + CHAR(9) 
				  + '$' + CONVERT(VARCHAR(50), CONVERT(MONEY, SUM(ReleasedPaymentAmt))) + REPLICATE(' ', (10 - LEN(CONVERT(VARCHAR(50), CONVERT(MONEY, SUM(ReleasedPaymentAmt)))))) + CHAR(9) 
				  + '$' + CONVERT(VARCHAR(50), CONVERT(MONEY, SUM(HeldOngoingAmt))) + REPLICATE(' ', (10 - LEN(CONVERT(VARCHAR(50), CONVERT(MONEY, SUM(HeldOngoingAmt)))))) + CHAR(13) + CHAR(10)
FROM @CALCTABLE AS calc	

SELECT @emailBody

--EXEC dbo.[prSendEmailNotification_PassEmailAddresses_HTML_Logos] @emailSubject, @emailBody, 'DataTrue System', 0, 'william.heine@icucsolutions.com; yegor.malykh@icucsolutions.com'
EXEC dbo.[prSendEmailNotification_PassEmailAddresses_HTML_Logos] @emailSubject, @emailBody, 'DataTrue System', 0, @emailRecipients

INSERT INTO DataTrue_EDI.dbo.ProcessStatus_ACH
(
 [ChainName]
,[SupplierName]
,[Date]
,[TotalAmount]
,[AllFilesReceived]
,[BillingComplete]
,[OutBoundComplete]
,[StartProcess]
,[BillingIsRunning]
,[ACHsent]
,[AcknowledgementRecieved]
,[EFTSupplierSent]
,[EFTRetailerSent]
)
SELECT DISTINCT
calcChainTotals.ChainIdentifier
,'N/A'
,CONVERT(DATE,GETDATE())
,calcChainTotals.PaymentAmt
,1
,1
,0
,0
,1
,0
,0
,0
,0
FROM
(
	SELECT
	(SELECT ChainIdentifier FROM DataTrue_Main.dbo.Chains a WHERE a.ChainID = calc.ChainID) AS ChainIdentifier,
	SUM(calc.PaymentAmt) AS PaymentAmt  --WAS BILLED AMT, WITH INVOICES BEING HELD SHOULD IT ONLY BE ACH PAYMENTS $?
	FROM @CALCTABLE AS calc
	WHERE 1 = 1
	AND CONVERT(NUMERIC(18, 9),calc.PaymentAmt) <> 0
	GROUP BY calc.ChainID
) AS calcChainTotals

INSERT INTO DataTrue_EDI.dbo.ProcessTracking_Billing_SUP
(
 [ChainID]
,[SupplierID]
,[TotalBilledAmount]
,[ACHAmount]
,[NonACHAmount]
,[HeldAmount]
,[ReleasedAmount]
,[HeldOngoingAmount]
,[SupplierInvoiceCount]
,[RetailerInvoiceCount]
,[Timestamp]
)
SELECT
 c.ChainID--[ChainID]
,c.SupplierID--[SupplierID]
,c.BilledAmt--[TotalBilledAmount]
,c.PaymentAmt--[ACHAmount]
,c.ExcludedPaymentAmt--[NonACHAmount]
,c.HeldPaymentAmt--[HeldAmount]
,c.ReleasedPaymentAmt--[ReleasedAmount]
,c.HeldOngoingAmt--[HeldOngoingAmount]
,c.SUPInvoiceCount--[SupplierInvoiceCount]
,c.RETInvoiceCount--[RetailerInvoiceCount]
,GETDATE()--[Timestamp]
FROM @CALCTABLE AS c

END TRY

BEGIN CATCH

		declare @errormessage varchar(500)
		declare @errorlocation varchar(500)
		declare @errorsenderstring varchar(500)

		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated Job Stopped'
			,'An exception occurred in [[prValidate_Regulated_Billing_Job_ACH_Payments]].  Manual review, resolution, and re-start will be required for the job to continue.'
			,'DataTrue System', 0, 'edi@icucsolutions.com'--'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
		
		IF EXISTS(     
			select 1 
			from msdb.dbo.sysjobs_view job  
			inner join msdb.dbo.sysjobactivity activity on job.job_id = activity.job_id 
			where  
				activity.run_Requested_date is not null  
			and activity.stop_execution_date is null  
			and job.name = 'Billing_Regulated' 
		) 
		Begin
			exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'Billing_Regulated'
		End


END CATCH

------------------------- CHECK 4 ERRORS <END> ----------------------------------
GO
