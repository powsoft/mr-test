USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidate_Regulated_Billing_Job_ACH]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[prValidate_Regulated_Billing_Job_ACH]
AS

BEGIN TRY

	DECLARE @ProcessID INT

	SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobName = 'DailyRegulatedBilling'

	DECLARE @RegulatedChains TABLE
	(
		ChainID INT,
		ChainIdentifier VARCHAR(150)
	);

	INSERT INTO @RegulatedChains (ChainID)
	SELECT DISTINCT ChainID FROM DataTrue_Main.dbo.StoreTransactions AS st WITH (NOLOCK)
	WHERE st.ProcessID = @ProcessID

	UPDATE r
	SET r.ChainIdentifier = (SELECT ChainIdentifier
							 FROM DataTrue_Main.dbo.Chains AS c WITH (NOLOCK)
							 WHERE c.ChainID = r.ChainID)
	FROM @RegulatedChains AS r

	DECLARE @current DATE
	DECLARE @jobLastRan DATETIME

	SELECT @jobLastRan = (SELECT JobLastRunDateTime FROM JobRunning WHERE JobName = 'DailyRegulatedBilling')

	DECLARE @CALCTABLE TABLE (ChainID INT, SupplierID INT, Filename VARCHAR(120), BilledAmt NUMERIC(18, 9), ApprovedAmt NUMERIC(18, 9), NotApprovedAmt NUMERIC(18, 9), NotApprovedAmt_Web NUMERIC(18, 9), FailedValAmt NUMERIC(18, 9), EDILoadedAmt NUMERIC(18, 9), WebLoadedAmt NUMERIC(18, 9))

	--CHECK TOTALS VS EDI LOAD TOTALS
	INSERT INTO @CALCTABLE
	(
		ChainID,
		SupplierID,
		Filename,
		BilledAmt,
		ApprovedAmt,
		NotApprovedAmt,
		NotApprovedAmt_Web,
		FailedValAmt,
		EDILoadedAmt,
		WebLoadedAmt
	)
	SELECT
	ChainID = (SELECT ChainID FROM Chains WITH (NOLOCK) WHERE ChainIdentifier = Chain)
	,SupplierID = (SELECT SupplierID FROM Suppliers WITH (NOLOCK) WHERE EDIName = PartnerID)
	,FileName
	,0 --Billed AMT
	,0 --ApprovedAmt
	,0 --NotApprovedAmt
	,0 --NotApprovedAmt_Web
	,0 --FailedValAmt
	,SUM(ROUND(TotalAmt, 2)) - SUM(ROUND(BilledAmt, 2)) - SUM(ROUND(RejectedAmt, 2)) - SUM(ROUND(FailedValidationAmt, 2)) - SUM(ROUND(PendingAmt, 2)) AS TotalAmt
	,0 --WebLoadedAmt
	FROM DataTrue_EDI.dbo.EDI_LoadStatus_ACH AS ACH 
	WHERE (SELECT ChainID FROM DataTrue_Main..Chains WHERE ChainIdentifier = Chain) IN (SELECT DISTINCT ChainID FROM @RegulatedChains)
	AND LoadStatus IN (3)
	AND ISNULL(UpdatedTimeStamp, DateLoaded) >= @jobLastRan
	GROUP BY Chain, PartnerID, FileName

	--INSERT INTO @CALCTABLE
	--(
	--	ChainID,
	--	SupplierID,
	--	Filename,
	--	BilledAmt,
	--	ApprovedAmt,
	--	NotApprovedAmt,
	--	NotApprovedAmt_Web,
	--	FailedValAmt,
	--	EDILoadedAmt,
	--	WebLoadedAmt
	--)
	--SELECT
	--ChainID,	--ChainID,
	--SupplierID,	--SupplierID,
	--FileName,	--Filename,
	--0,	--BilledAmt,
	--0,	--ApprovedAmt,
	--0,	--NotApprovedAmt,
	--0,	--NotApprovedAmt_Web,
	--0,	--FailedValAmt,
	--0,	--EDILoadedAmt,
	--TotalAmt	--WebLoadedAmt
	--FROM
	--(
	--	SELECT ChainID, SupplierID, Filename, SUM(EDI_WebTotal) AS TotalAmt
	--	FROM
	--	(
	--	SELECT
	--	ChainID = DataTrueChainID
	--   ,SupplierID = DataTrueSupplierID
	--   ,FileName
	--   ,ReferenceIDentification
	--   ,EDI_WebTotal = ROUND(SUM((CASE PurposeCode WHEN 'CR' THEN Qty * -1 ELSE Qty END) * Cost + ROUND(ISNULL(AllowanceChargeAmount, 0), 2) + Adjustment2), 2)
	--   FROM [DataTrue_EDI].[dbo].[InboundInventory_Web]
	--   WHERE DataTrueChainID IN (SELECT DISTINCT ChainID FROM @RegulatedChains)
	--   AND LastUpdateDateTime >= @jobLastRan
	--   AND RecordStatus = 2
	--   GROUP BY DataTrueChainID, DataTrueSupplierID, FileName, ReferenceIDentification
	--	) t
	--	GROUP BY ChainID, SupplierID, Filename
	--) AS Web

	UPDATE c
	SET c.BilledAmt = Billed.TotalAmt
	FROM @CALCTABLE AS c
	INNER JOIN 
	(
		SELECT ChainID, SupplierID, Filename, SUM(TotalBilled) AS TotalAmt
		FROM
		(
		SELECT
		id2.ChainID,
		id2.SupplierID,
		s.SourceName AS Filename,
		id2.InvoiceNo,
		ROUND(SUM(CONVERT(NUMERIC(18, 9), id2.TotalCost)), 2) AS TotalBilled
		FROM DataTrue_EDI.dbo.InvoiceDetails AS id
		INNER JOIN DataTrue_Main.dbo.InvoiceDetails AS id2
		ON id.InvoiceDetailID = id2.InvoiceDetailID
		INNER JOIN DataTrue_Main.dbo.Source AS s
		ON id2.SourceID = s.SourceID
		WHERE 1 = 1
		AND id2.DateTimeCreated >= @jobLastRan
		AND id2.InvoiceDetailTypeID = 2
		AND id2.ChainID IN (SELECT DISTINCT ChainID FROM @RegulatedChains)
		GROUP BY id2.ChainID, id2.SupplierID, s.SourceName, id2.InvoiceNo
		) t
		GROUP BY ChainID, SupplierID, Filename
	) AS Billed
	ON Billed.ChainID = c.ChainID
	AND Billed.SupplierID = c.SupplierID
	AND BIlled.Filename = c.Filename

	UPDATE c
	SET c.ApprovedAmt = Approved.TotalAmt
	FROM @CALCTABLE AS c
	INNER JOIN 
	(
		SELECT ChainID, SupplierID, Filename, SUM(EDI_Approved_AMOUNT) AS TotalAmt
		FROM
		(
		SELECT
		(SELECT ChainID FROM Chains WHERE Chains.ChainIdentifier = a.ChainName) AS ChainID
		,(SELECT SupplierID FROM Suppliers WHERE Suppliers.EDIName = a.EdiName) AS SupplierID
		,FileName
		,ReferenceIDentification
		,EDI_Approved_AMOUNT =  ROUND(CONVERT(NUMERIC(18, 9),	
									  SUM(Qty*Cost) 
									 +SUM(ISNULL(AlllowanceChargeAmount1, 0))
									 +SUM(ISNULL(AlllowanceChargeAmount2, 0))
									 +SUM(ISNULL(AlllowanceChargeAmount3, 0))
									 +SUM(ISNULL(AlllowanceChargeAmount4, 0))
									 +SUM(ISNULL(AlllowanceChargeAmount5, 0))
									 +SUM(ISNULL(AlllowanceChargeAmount6, 0))
									 +SUM(ISNULL(AlllowanceChargeAmount7, 0))
									 +SUM(ISNULL(AlllowanceChargeAmount8, 0))
									 ), 2)
		FROM DataTrue_EDI.dbo.Inbound846Inventory_ACH_Approval AS a
		WHERE ChainName IN (SELECT DISTINCT ChainIdentifier FROM Chains WHERE ChainID IN (SELECT DISTINCT ChainID FROM @RegulatedChains))
		AND ISNULL(ApprovalTimeStamp, TimeStamp) >= @jobLastRan
		AND RecordStatus = 1
		AND ProcessID = @ProcessID
		GROUP BY ChainName, EdiName, FileName, ReferenceIDentification
		) t
		GROUP BY ChainID, SupplierID, Filename
	) AS Approved
	ON Approved.ChainID = c.ChainID
	AND Approved.SupplierID = c.SupplierID
	AND Approved.Filename = c.Filename

	UPDATE c
	SET c.NotApprovedAmt = NotApproved.TotalAmt
	FROM @CALCTABLE AS c
	INNER JOIN 
	(
		SELECT ChainID, SupplierID, Filename, SUM(EDI_NotApprovedAMT) AS TotalAmt
		FROM
		(
		SELECT
		(SELECT ChainID FROM Chains WHERE Chains.ChainIdentifier = a.ChainName) AS ChainID
		,(SELECT SupplierID FROM Suppliers WHERE Suppliers.EDIName = a.EdiName) AS SupplierID
		,FileName
		,ReferenceIDentification
		,EDI_NotApprovedAMT =  ROUND(CONVERT(NUMERIC(18, 9),	
									  SUM(Qty*Cost) 
									 +SUM(ISNULL(AlllowanceChargeAmount1, 0))
									 +SUM(ISNULL(AlllowanceChargeAmount2, 0))
									 +SUM(ISNULL(AlllowanceChargeAmount3, 0))
									 +SUM(ISNULL(AlllowanceChargeAmount4, 0))
									 +SUM(ISNULL(AlllowanceChargeAmount5, 0))
									 +SUM(ISNULL(AlllowanceChargeAmount6, 0))
									 +SUM(ISNULL(AlllowanceChargeAmount7, 0))
									 +SUM(ISNULL(AlllowanceChargeAmount8, 0))
									 ), 2)
		FROM DataTrue_EDI.dbo.Inbound846Inventory_ACH_Approval AS a
		WHERE ChainName IN (SELECT DISTINCT ChainIdentifier FROM Chains WHERE ChainID IN (SELECT DISTINCT ChainID FROM @RegulatedChains))
		AND ISNULL(ApprovalTimeStamp, TimeStamp) >= @jobLastRan
		AND RecordStatus NOT IN (0, 1, 2)
		GROUP BY ChainName, EdiName, FileName, ReferenceIDentification
		) t
		GROUP BY ChainID, SupplierID, Filename
	) AS NotApproved
	ON NotApproved.ChainID = c.ChainID
	AND NotApproved.SupplierID = c.SupplierID
	AND NotApproved.Filename = c.Filename

	--UPDATE c
	--SET c.NotApprovedAmt_Web = NotApproved_Web.TotalAmt
	--FROM @CALCTABLE AS c
	--INNER JOIN 
	--(
	--	SELECT ChainID, SupplierID, Filename, SUM(EDI_NotApprovedAMT) AS TotalAmt
	--	FROM
	--	(
	--	SELECT
	--	(SELECT ChainID FROM Chains WHERE Chains.ChainIdentifier = a.ChainName) AS ChainID
	--	,(SELECT SupplierID FROM Suppliers WHERE Suppliers.EDIName = a.EdiName) AS SupplierID
	--	,FileName
	--	,ReferenceIDentification
	--	,EDI_NotApprovedAMT =  ROUND(CONVERT(NUMERIC(18, 9),	
	--								  SUM(Qty*Cost) 
	--								 +SUM(ISNULL(AlllowanceChargeAmount1, 0))
	--								 +SUM(ISNULL(AlllowanceChargeAmount2, 0))
	--								 +SUM(ISNULL(AlllowanceChargeAmount3, 0))
	--								 +SUM(ISNULL(AlllowanceChargeAmount4, 0))
	--								 +SUM(ISNULL(AlllowanceChargeAmount5, 0))
	--								 +SUM(ISNULL(AlllowanceChargeAmount6, 0))
	--								 +SUM(ISNULL(AlllowanceChargeAmount7, 0))
	--								 +SUM(ISNULL(AlllowanceChargeAmount8, 0))
	--								 ), 2)
	--	FROM DataTrue_EDI.dbo.Inbound846Inventory_ACH_Approval AS a
	--	WHERE ChainName IN (SELECT DISTINCT ChainIdentifier FROM Chains WHERE ChainID IN (SELECT DISTINCT ChainID FROM @RegulatedChains))
	--	AND ISNULL(ApprovalTimeStamp, TimeStamp) >= @jobLastRan
	--	AND RecordStatus <> 1
	--	AND Source IN ('InboundInventory_Web', 'InboundInventory_Web/1')
	--	GROUP BY ChainName, EdiName, FileName, ReferenceIDentification
	--	) t
	--	GROUP BY ChainID, SupplierID, Filename
	--) AS NotApproved_Web
	--ON NotApproved_Web.ChainID = c.ChainID
	--AND NotApproved_Web.SupplierID = c.SupplierID
	--AND NotApproved_Web.Filename = c.Filename

	UPDATE c
	SET c.FailedValAmt = RecordValidation.TotalAmt
	FROM @CALCTABLE AS c
	INNER JOIN 
	(
		SELECT ChainID, SupplierID, Filename, SUM(EDI_FailedValidation) AS TotalAmt
		FROM
		(
		SELECT
		(SELECT ChainID FROM Chains WHERE Chains.ChainIdentifier = a.ChainName) AS ChainID
		,(SELECT SupplierID FROM Suppliers WHERE Suppliers.EDIName = a.EdiName) AS SupplierID
		,FileName
		,ReferenceIDentification
		,EDI_FailedValidation =  ROUND(CONVERT(NUMERIC(18, 9),	
									  SUM(Qty*Cost) 
									 +SUM(ISNULL(AlllowanceChargeAmount1, 0))
									 +SUM(ISNULL(AlllowanceChargeAmount2, 0))
									 +SUM(ISNULL(AlllowanceChargeAmount3, 0))
									 +SUM(ISNULL(AlllowanceChargeAmount4, 0))
									 +SUM(ISNULL(AlllowanceChargeAmount5, 0))
									 +SUM(ISNULL(AlllowanceChargeAmount6, 0))
									 +SUM(ISNULL(AlllowanceChargeAmount7, 0))
									 +SUM(ISNULL(AlllowanceChargeAmount8, 0))
									 ), 2)
		FROM DataTrue_EDI.dbo.Inbound846Inventory_ACH AS a	WITH (TABLOCKX)
		WHERE ChainName IN (SELECT DISTINCT ChainIdentifier FROM Chains WHERE ChainID IN (SELECT DISTINCT ChainID FROM @RegulatedChains))
		AND TimeStamp >= @jobLastRan
		AND RecordStatus NOT IN (0, 1)
		GROUP BY ChainName, EdiName, FileName, ReferenceIDentification
		) t
		GROUP BY ChainID, SupplierID, Filename
	) AS RecordValidation
	ON RecordValidation.ChainID = c.ChainID
	AND RecordValidation.SupplierID = c.SupplierID
	AND RecordValidation.Filename = c.Filename


	--CHECK FOR BILLED CHAIN COUNT > 0
	IF
	(SELECT COUNT(DISTINCT ChainID)
	FROM @CALCTABLE) = 0
		BEGIN
			DECLARE @body1 NVARCHAR(2000)
			SELECT @body1 = 
			'Regulated_Billing_NewInvoiceData Job Validation has Failed.' 
			+ 'No chains have been processed.'
			EXEC dbo.prSendEmailNotification_PassEmailAddresses 'Daily Regulated Billing Job Validation has Failed.'
			,@body1
			,'DataTrue System', 0
			--,'william.heine@icucsolutions.com'
			,'datatrueit@icontroldsd.com; edi@icontroldsd.com'--'datatrueit@icontroldsd.com; edi@icontroldsd.com'
			RAISERROR ('The Daily Regulated Billing stopped at Validation STAGE. VALIDATION is not completed.' , 16 , 1)
		END

	DECLARE @CALCROWS INT

	DECLARE @FailedValidation BIT

	SELECT * FROM @CALCTABLE
	--WHERE (CONVERT(NUMERIC(18, 9),BilledAmt) + CONVERT(NUMERIC(18, 9),NotApprovedAmt_Web)) <> CONVERT(NUMERIC(18, 9),((EDILoadedAmt + WebLoadedAmt - FailedValAmt)))
	WHERE (CONVERT(MONEY,BilledAmt)) <> CONVERT(MONEY,((EDILoadedAmt)))
	SELECT @CALCROWS = @@ROWCOUNT
	IF @CALCROWS > 0
		BEGIN
			SET @FailedValidation = 1
			UPDATE DataTrue_EDI.dbo.InvoiceDetails
			SET RecordStatus = 255
			WHERE ProcessID = @ProcessID
			DECLARE @body2 NVARCHAR(2000)
			SELECT @body2 = 
			'Daily Regulated Billing Job Validation has Failed.' 
			+ 'Loaded amount - rejected amount does not equal billed amount.'
			EXEC dbo.prSendEmailNotification_PassEmailAddresses 'Regulated_Billing_NewInvoiceData Job Validation has Failed.'
			,@body2
			,'DataTrue System', 0
			--,'william.heine@icucsolutions.com'
			,'datatrueit@icontroldsd.com; edi@icontroldsd.com'--'datatrueit@icontroldsd.com; edi@icontroldsd.com'
			RAISERROR ('The Daily Regulated Billing stopped at Validation STAGE. VALIDATION is not completed.' , 16 , 1)
		END
		
	--SELECT * FROM @CALCTABLE
	--WHERE CONVERT(MONEY,BilledAmt) <> (CONVERT(MONEY,PaymentAmt) + CONVERT(MONEY,ExcludedPaymentAmt))
	--SELECT @CALCROWS = @@ROWCOUNT
	--IF @CALCROWS > 0
	--	BEGIN
	--		SET @FailedValidation = 1
	--		DECLARE @body4 NVARCHAR(2000)
	--		SELECT @body4 = 
	--		'Daily Regulated Billing Job Validation has Failed.' 
	--		+ 'Payment amount does not equal billed amount.'
	--		EXEC dbo.prSendEmailNotification_PassEmailAddresses 'Daily Regulated Billing Job Validation has Failed.'
	--		,@body4
	--		,'DataTrue System', 0
	--		,'datatrueit@icontroldsd.com; edi@icontroldsd.com'--'datatrueit@icontroldsd.com; edi@icontroldsd.com'
	--		RAISERROR ('The Daily Regulated Billing stopped at Validation STAGE. VALIDATION is not completed.' , 16 , 1)
	--	END

	SELECT * FROM @CALCTABLE
	WHERE CONVERT(MONEY,BilledAmt) <> CONVERT(MONEY, ApprovedAmt)
	SELECT @CALCROWS = @@ROWCOUNT
	IF @CALCROWS > 0
		BEGIN
			SET @FailedValidation = 1
			UPDATE DataTrue_EDI.dbo.InvoiceDetails
			SET RecordStatus = 255
			WHERE ProcessID = @ProcessID
			DECLARE @body3 NVARCHAR(2000)
			SELECT @body3 = 
			'Regulated_Billing_NewInvoiceData Job Validation has Failed.' 
			+ 'EDI Approved amount does not equal billed amount.'
			EXEC dbo.prSendEmailNotification_PassEmailAddresses 'Daily Regulated Billing Job Validation has Failed.'
			,@body3
			,'DataTrue System', 0
			--,'william.heine@icucsolutions.com'
			,'datatrueit@icontroldsd.com; edi@icontroldsd.com'--'datatrueit@icontroldsd.com; edi@icontroldsd.com'
			RAISERROR ('The Daily Regulated Billing stopped at Validation STAGE. VALIDATION is not completed.' , 16 , 1)
		END

	IF @FailedValidation = 1 
		BEGIN
			UPDATE DataTrue_EDI.dbo.InvoiceDetails
			SET RecordStatus = 255
			WHERE ProcessID = @ProcessID
		END
	ELSE
		BEGIN
			UPDATE DataTrue_EDI.dbo.InvoiceDetails
			SET RecordStatus = 0
			WHERE ProcessID = @ProcessID
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
	WHERE h.InvoiceTypeID = 1
	AND d.InvoiceDetailTypeID = 2
	AND	h.chainid IN (SELECT DISTINCT ChainID FROM @RegulatedChains)
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
	WHERE h.InvoiceTypeID = 1
	AND d.InvoiceDetailTypeID = 2
	AND h.chainid IN (SELECT DISTINCT ChainID FROM @RegulatedChains)
	AND CAST(h.datetimecreated as date) = @current

	-----------------------------------------------------------------

	-----------------------------------------------------------------

	Update DataTrue_Main.dbo.JobRunning
	Set JobIsRunningNow = 0
	Where JobName = 'DailyRegulatedBilling'

END TRY

BEGIN CATCH
	declare @errormessage varchar(500)
		declare @errorlocation varchar(500)
		declare @errorsenderstring varchar(500)

		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated_NewInvoiceData Job Stopped'
			,'An exception occurred in [prValidate_Regulated_Billing_Job_ACH].  Manual review, resolution, and re-start will be required for the job to continue.'
			,'DataTrue System', 0, 'edi@icucsolutions.com'--'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
		
		IF EXISTS(     
			select 1 
			from msdb.dbo.sysjobs_view job  
			inner join msdb.dbo.sysjobactivity activity on job.job_id = activity.job_id 
			where  
				activity.run_Requested_date is not null  
			and activity.stop_execution_date is null  
			and job.name = 'Billing_Regulated_NewInvoiceData' 
		) 
		Begin
			exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'Billing_Regulated_NewInvoiceData'
		End
END CATCH
GO
