USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prICAM_GetDeliveryData]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[prICAM_GetDeliveryData]

AS
BEGIN

DECLARE @errorMessage NVARCHAR(4000)
DECLARE @errorLocation NVARCHAR(255)
DECLARE @errorSenderString NVARCHAR(255)

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	BEGIN TRY
	
	BEGIN TRANSACTION
	
	--UPDATE WHERE INVOICE NUMBER IS EXACT AND DATE MATCHES
	UPDATE icam
	SET icam.SupplierInvoiceTotal = st.Total, icam.SupplierInvoiceQty = st.Qty, icam.RecordStatus = 2, icam.SupplierExistsMatch = 1, 
	icam.SupplierInvoiceLineItemCount = st.LineItemCount, icam.SupplierInvoiceNumber = st.SupplierInvoiceNumber, icam.SupplierInvoiceDate  = st.SaleDateTime
	FROM [DataTrue_Main].[dbo].[ICAM_POMatch] AS icam
	INNER JOIN 
	(
		SELECT 
		st.ChainID, 
		st.SupplierID, 
		st.StoreID, 
		st.SaleDateTime, 
		LTRIM(RTRIM(st.SupplierInvoiceNumber)) AS SupplierInvoiceNumber, 
		SUM(CASE WHEN st.TransactionTypeID = 8 THEN st.Qty * -1 ELSE st.Qty END * CASE WHEN st.RuleCost IS NULL THEN ISNULL(st.ReportedCost, 0) ELSE st.RuleCost END) 
			+ SUM(ISNULL(st.Adjustment1, 0))
			+ SUM(ISNULL(st.Adjustment2, 0))
			+ SUM(ISNULL(st.Adjustment3, 0))
			+ SUM(ISNULL(st.Adjustment4, 0))
			+ SUM(ISNULL(st.Adjustment5, 0))
			+ SUM(ISNULL(st.Adjustment6, 0))
			+ SUM(ISNULL(st.Adjustment7, 0))
			+ SUM(ISNULL(st.Adjustment8, 0)) AS Total, 
		SUM(CASE WHEN st.TransactionTypeID = 8 THEN st.Qty * -1 ELSE st.Qty END) AS Qty, 
		COUNT(DISTINCT CONVERT(VARCHAR(50), st.ChainID) 
					 + CONVERT(VARCHAR(50), st.StoreID) 
					 + CONVERT(VARCHAR(50), st.ProductID) 
					 + CONVERT(VARCHAR(50), st.SupplierID) 
					 + CONVERT(VARCHAR(50), st.SaleDateTime)) AS LineItemCount
		FROM [DataTrue_Main].[dbo].[StoreTransactions] AS st
		WHERE st.TransactionTypeID IN (5, 8)
		GROUP BY st.ChainID, st.SupplierID, st.StoreID, st.SaleDateTime, st.SupplierInvoiceNumber
	) AS st
	ON st.ChainID = icam.ChainID
	AND st.SupplierID = icam.SupplierID
	AND st.StoreID = icam.StoreID
	AND st.SupplierInvoiceNumber = icam.InvoiceNumber
	AND st.SaleDateTime = icam.InvoiceDate
	WHERE icam.RecordStatus = 1
	
	--UPDATE WHERE INVOICE NUMBER BY Levenshtein Match <= CONFIG AND $ TOTAL WITHIN CONFIG % RANGE AND DATE DISTANCE WITHIN CONFIG RANGE
	UPDATE icam
	SET icam.SupplierInvoiceTotal = source.Total, icam.SupplierInvoiceQty = source.Qty, icam.RecordStatus = 2, icam.SupplierExistsMatch = 1, 
	icam.SupplierInvoiceLineItemCount = source.LineItemCount, icam.SupplierInvoiceNumber = source.SupplierInvoiceNumber, icam.SupplierExistsLevenshteinMatch = 1,
	icam.SupplierInvoiceDate = source.SaleDateTime
	FROM [DataTrue_Main].[dbo].[ICAM_POMatch] AS icam
	INNER JOIN
	(
	SELECT --TOP 100 PERCENT 
	st.ChainID, 
	st.SupplierID, 
	st.StoreID, 
	st.SaleDateTime, 
	st.Total, 
	st.Qty, 
	st.LineItemCount, 
	icamsource.InvoiceNumber, 
	icamsource.InvoiceDate,
	st.SupplierInvoiceNumber,
	ROW_NUMBER() OVER 
	(
		PARTITION BY st.ChainID, st.SupplierID, st.StoreID, st.SaleDateTime, st.SupplierInvoiceNumber
		ORDER BY DATEDIFF(d, st.SaleDateTime, icamsource.InvoiceDate) ASC, dbo.fnLevenshtein(st.SupplierInvoiceNumber, icamsource.InvoiceNumber, config.InvoiceNumberEditDistanceLimit) ASC
	) AS RowNumber
	FROM [DataTrue_Main].[dbo].[ICAM_POMatch] AS icamsource
	INNER JOIN [DataTrue_Main].[dbo].[Config_ICAM] AS config
	ON icamsource.ChainID = config.ChainID
	INNER JOIN 
	(
		SELECT 
		st.ChainID, 
		st.SupplierID, 
		st.StoreID, 
		st.SaleDateTime, 
		LTRIM(RTRIM(st.SupplierInvoiceNumber)) AS SupplierInvoiceNumber, 
		SUM(st.Qty * CASE WHEN st.RuleCost IS NULL THEN ISNULL(st.ReportedCost, 0) ELSE st.RuleCost END) 
			+ SUM(ISNULL(st.Adjustment1, 0))
			+ SUM(ISNULL(st.Adjustment2, 0))
			+ SUM(ISNULL(st.Adjustment3, 0))
			+ SUM(ISNULL(st.Adjustment4, 0))
			+ SUM(ISNULL(st.Adjustment5, 0))
			+ SUM(ISNULL(st.Adjustment6, 0))
			+ SUM(ISNULL(st.Adjustment7, 0))
			+ SUM(ISNULL(st.Adjustment8, 0)) AS Total, 
		SUM(st.Qty) AS Qty, 
		COUNT(DISTINCT CONVERT(VARCHAR(50), st.ChainID) 
					 + CONVERT(VARCHAR(50), st.StoreID) 
					 + CONVERT(VARCHAR(50), st.ProductID) 
					 + CONVERT(VARCHAR(50), st.SupplierID) 
					 + CONVERT(VARCHAR(50), st.SaleDateTime)) AS LineItemCount
		FROM [DataTrue_Main].[dbo].[StoreTransactions] AS st
		WHERE st.TransactionTypeID IN (5, 8)
		GROUP BY st.ChainID, st.SupplierID, st.StoreID, st.SaleDateTime, st.SupplierInvoiceNumber
	) AS st
	ON st.ChainID = icamsource.ChainID
	AND st.SupplierID = icamsource.SupplierID
	AND st.StoreID = icamsource.StoreID
	AND dbo.fnLevenshtein(st.SupplierInvoiceNumber, icamsource.InvoiceNumber, config.InvoiceNumberEditDistanceLimit) <= config.InvoiceNumberEditDistanceLimit
	AND DATEDIFF(d, st.SaleDateTime, icamsource.InvoiceDate) <= config.InvoiceDateDifferenceLimit
	AND ABS(100 * (st.Total/icamsource.RetailerInvoiceTotal)) BETWEEN (100 - config.InvoiceTotalDifferencePercentageLimit) AND (100 + config.InvoiceTotalDifferencePercentageLimit) -- +/- % difference
	WHERE icamsource.RecordStatus = 1
	AND icamsource.SupplierExistsMatch = 0
	--ORDER BY DATEDIFF(d, st.SaleDateTime, icamsource.InvoiceDate) ASC,
	--	     dbo.fnLevenshtein(st.SupplierInvoiceNumber, icamsource.InvoiceNumber, config.InvoiceNumberEditDistanceLimit) ASC
	) AS source
	ON icam.ChainID = source.ChainID
	AND icam.SupplierID = source.SupplierID
	AND icam.StoreID = source.StoreID
	AND icam.InvoiceDate = source.InvoiceDate
	AND icam.InvoiceNumber = source.InvoiceNumber
	AND source.RowNumber = 1
	
	--UPDATE PO NUMBERS FOR DELIVERIES
	UPDATE st
	SET st.PONo = po.PONumber
	FROM [DataTrue_Main].[dbo].[StoreTransactions] AS st
	INNER JOIN [DataTrue_Main].[dbo].[ICAM_POMatch] AS icam
	ON st.ChainID = icam.ChainID
	AND st.SupplierID = icam.SupplierID
	AND st.StoreID = icam.StoreID
	AND st.SupplierInvoiceNumber = icam.SupplierInvoiceNumber
	AND st.SaleDateTime = icam.InvoiceDate
	AND st.TransactionTypeID IN (5, 8)
	INNER JOIN [DataTrue_Main].[dbo].[iCAM_PONumbers] AS po
	ON po.iCamID = icam.RecordID
	AND po.RecordID = (SELECT TOP 1 RecordID
					   FROM [DataTrue_Main].[dbo].[iCAM_PONumbers] AS t
					   WHERE t.iCamID = po.iCamID
					   ORDER BY t.PONumber ASC)
	WHERE icam.RecordStatus = 2
	
	UPDATE id
	SET id.PONo = po.PONumber
	FROM [DataTrue_Main].[dbo].[InvoiceDetails] AS id
	INNER JOIN [DataTrue_Main].[dbo].[ICAM_POMatch] AS icam
	ON id.ChainID = icam.ChainID
	AND id.SupplierID = icam.SupplierID
	AND id.StoreID = icam.StoreID
	AND id.InvoiceNo = icam.SupplierInvoiceNumber
	AND id.SaleDate = icam.InvoiceDate
	AND id.InvoiceDetailTypeID = 2
	INNER JOIN [DataTrue_Main].[dbo].[iCAM_PONumbers] AS po
	ON po.iCamID = icam.RecordID
	AND po.RecordID = (SELECT TOP 1 RecordID
					   FROM [DataTrue_Main].[dbo].[iCAM_PONumbers] AS t
					   WHERE t.iCamID = po.iCamID
					   ORDER BY t.PONumber ASC)
	WHERE icam.RecordStatus = 2
	
	UPDATE id
	SET id.PONo = po.PONumber
	FROM [DataTrue_EDI].[dbo].[InvoiceDetails] AS id
	INNER JOIN [DataTrue_Main].[dbo].[ICAM_POMatch] AS icam
	ON id.ChainID = icam.ChainID
	AND id.SupplierID = icam.SupplierID
	AND id.StoreID = icam.StoreID
	AND id.InvoiceNo = icam.InvoiceNumber
	AND id.SaleDate = icam.InvoiceDate
	AND id.InvoiceDetailTypeID = 2
	INNER JOIN [DataTrue_Main].[dbo].[iCAM_PONumbers] AS po
	ON po.iCamID = icam.RecordID
	AND po.RecordID = (SELECT TOP 1 RecordID
					   FROM [DataTrue_Main].[dbo].[iCAM_PONumbers] AS t
					   WHERE t.iCamID = po.iCamID
					   ORDER BY t.PONumber ASC)
	WHERE icam.RecordStatus = 2
	
	
	--GET PRODUCT MATCH COUNT
	UPDATE icam
	SET icam.SupplierProductMatch = ProductMatch.LineItemCount
	FROM [DataTrue_Main].[dbo].[ICAM_POMatch] AS icam
	INNER JOIN
	(
		SELECT 
		st2.ChainID, 
		st2.SupplierID, 
		st2.StoreID, 
		st2.SaleDateTime, 
		LTRIM(RTRIM(st2.SupplierInvoiceNumber)) AS SupplierInvoiceNumber,
		COUNT(DISTINCT CONVERT(VARCHAR(50), st.ChainID) 
					 + CONVERT(VARCHAR(50), st.StoreID) 
					 + CONVERT(VARCHAR(50), st.ProductID) 
					 + CONVERT(VARCHAR(50), st.SupplierID) 
					 + CONVERT(VARCHAR(50), st.SaleDateTime)) AS LineItemCount
		FROM [DataTrue_Main].[dbo].[ICAM_POMatch] AS icam
		INNER JOIN [DataTrue_Main].[dbo].[StoreTransactions] AS st
		ON st.ChainID = icam.ChainID
		AND st.SupplierID = icam.SupplierID
		AND st.StoreID = icam.StoreID
		AND st.SaleDateTime = icam.InvoiceDate
		AND st.SupplierInvoiceNumber = icam.InvoiceNumber
		AND st.TransactionTypeID = 32
		INNER JOIN [DataTrue_Main].[dbo].[StoreTransactions] AS st2
		ON st2.ChainID = st.ChainID
		AND st2.SupplierID = st.SupplierID
		AND st2.StoreID = st.StoreID
		AND st2.ProductID = st.ProductID
		AND st2.SupplierInvoiceNumber = icam.SupplierInvoiceNumber
		AND st2.SaleDateTime = icam.SupplierInvoiceDate
		AND st2.TransactionTypeID IN (5, 8)
		GROUP BY st2.ChainID, st2.SupplierID, st2.StoreID, st2.SaleDateTime, st2.SupplierInvoiceNumber
	) AS ProductMatch
	ON ProductMatch.ChainID = icam.ChainID
	AND ProductMatch.SupplierID = icam.SupplierID
	AND ProductMatch.StoreID = icam.StoreID
	AND ProductMatch.SupplierInvoiceNumber = icam.SupplierInvoiceNumber
	WHERE icam.RecordStatus = 2
	
	--INSERT INVOICES WHERE NO RECEIVING RECORD
	INSERT INTO [DataTrue_Main].[dbo].[ICAM_POMatch]
	(
	 [Filename]
	,[ChainID]
	,[SupplierID]
	,[StoreID]
	,[SupplierInvoiceNumber]
	,[SupplierInvoiceDate]
	,[SupplierInvoiceQty]
	,[SupplierInvoiceTotal]
	,[SupplierInvoiceLineItemCount]
	,[RetailerInvoiceQty]
	,[RetailerInvoiceTotal]
	,[POCount]
	)
	SELECT DISTINCT
	'NORECEIVINGFILE',
	st.ChainID,
	st.SupplierID,
	st.StoreID,
	LTRIM(RTRIM(st.SupplierInvoiceNumber)) AS InvoiceNumber,
	st.SaleDateTime,
	SUM(CASE WHEN st.TransactionTypeID = 8 THEN st.Qty * -1 ELSE st.Qty END),
	SUM(CASE WHEN st.TransactionTypeID = 8 THEN st.Qty * -1 ELSE st.Qty END * CASE WHEN st.RuleCost IS NULL THEN ISNULL(st.ReportedCost, 0) ELSE st.RuleCost END) + SUM(ISNULL(Adjustment1, 0))
																									  + SUM(ISNULL(Adjustment2, 0))
																									  + SUM(ISNULL(Adjustment3, 0))
																									  + SUM(ISNULL(Adjustment4, 0))
																									  + SUM(ISNULL(Adjustment5, 0))
																									  + SUM(ISNULL(Adjustment6, 0))
																									  + SUM(ISNULL(Adjustment7, 0))
																									  + SUM(ISNULL(Adjustment8, 0)),
	COUNT(DISTINCT CONVERT(VARCHAR(50), st.ChainID) 
					 + CONVERT(VARCHAR(50), st.StoreID) 
					 + CONVERT(VARCHAR(50), st.ProductID) 
					 + CONVERT(VARCHAR(50), st.SupplierID) 
					 + CONVERT(VARCHAR(50), st.SaleDateTime)) AS LineItemCount,																							  
	0,
	0,
	0
	FROM [DataTrue_Main].[dbo].[StoreTransactions] AS st
	LEFT OUTER JOIN [DataTrue_Main].[dbo].[ICAM_POMatch] AS icam
	ON st.ChainID = icam.ChainID
	AND st.SupplierID = icam.SupplierID
	AND st.StoreID = icam.StoreID
	AND st.SupplierInvoiceNumber = icam.SupplierInvoiceNumber
	AND st.SaleDateTime = icam.SupplierInvoiceDate
	WHERE st.TransactionTypeID IN (5, 8)
	AND icam.RecordID IS NULL
	AND st.ChainID IN (SELECT DISTINCT ChainID FROM [DataTrue_Main].[dbo].[ICAM_POMatch])
	GROUP BY st.ChainID, st.SupplierID, st.StoreID, st.SupplierInvoiceNumber, st.SaleDateTime
	
	UPDATE icam
	SET icam.SupplierTotalMatch = CASE WHEN (icam.RetailerInvoiceTotal = icam.SupplierInvoiceTotal) THEN 1 ELSE 0 END, 
		icam.SupplierQtyMatch = CASE WHEN (icam.RetailerInvoiceQty = icam.SupplierInvoiceQty) THEN 1 ELSE 0 END, 
		RecordStatus = 3 --UPDATE RECORD STATUS TO 3 ON LAST UPDATE
	FROM [DataTrue_Main].[dbo].[ICAM_POMatch] AS icam
	WHERE icam.RecordStatus = 2
	
	--CHECK FOR PAYMENTS
	UPDATE icam
	SET icam.PaymentID = i.PaymentID
	FROM [DataTrue_Main].[dbo].[ICAM_POMatch] AS icam
	INNER JOIN 
	(
		SELECT 
		i.ChainID, 
		i.SupplierID, 
		i.StoreID, 
		i.SaleDate, 
		LTRIM(RTRIM(i.InvoiceNo)) AS SupplierInvoiceNumber,
		i.PaymentID
		FROM [DataTrue_Main].[dbo].[InvoiceDetails] AS i
		WHERE i.InvoiceDetailTypeID = 2
		AND i.PaymentID IS NOT NULL
		GROUP BY i.ChainID, i.SupplierID, i.StoreID, i.SaleDate, i.InvoiceNo, i.PaymentID
	) AS i
	ON i.ChainID = icam.ChainID
	AND i.SupplierID = icam.SupplierID
	AND i.StoreID = icam.StoreID
	AND i.SupplierInvoiceNumber = icam.SupplierInvoiceNumber
	AND i.SaleDate = icam.SupplierInvoiceDate
	AND icam.PaymentID IS NULL

	COMMIT TRANSACTION
	
	END TRY
	
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @errorMessage = ERROR_MESSAGE()
		SET @errorLocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		SET @errorSenderString = ERROR_PROCEDURE()
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorLocation
		,@errorMessage
		,@errorSenderString
		,0
		
		EXEC dbo.prSendEmailNotification_PassEmailAddresses 'ICAM Job Stopped'
			,'An exception occurred in prICAM_GetDeliveries.  Manual review, resolution, and re-start will be required for the job to continue.'
			,'DataTrue System', 0, 'edi@icucsolutions.com'
		
		EXEC [msdb].[dbo].[sp_stop_job] 
			@job_name = 'ICAM'	

	END CATCH
	
END
GO
