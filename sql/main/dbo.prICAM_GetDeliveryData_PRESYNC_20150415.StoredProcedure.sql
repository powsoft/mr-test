USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prICAM_GetDeliveryData_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[prICAM_GetDeliveryData_PRESYNC_20150415]

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
	
	UPDATE icam
	SET icam.SupplierInvoiceTotal = st.Total, icam.SupplierInvoiceQty = st.Qty, icam.RecordStatus = 2, icam.SupplierExistsMatch = 1, 
	icam.SupplierInvoiceLineItemCount = st.LineItemCount
	FROM [DataTrue_Main].[dbo].[ICAM_POMatch] AS icam
	INNER JOIN 
	(
		SELECT 
		st.ChainID, 
		st.SupplierID, 
		st.StoreID, 
		st.SaleDateTime, 
		st.SupplierInvoiceNumber, 
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
	ON st.ChainID = icam.ChainID
	AND st.SupplierID = icam.SupplierID
	AND st.StoreID = icam.StoreID
	AND st.SupplierInvoiceNumber = icam.InvoiceNumber
	AND st.SaleDateTime = icam.InvoiceDate
	WHERE icam.RecordStatus = 1
	
	UPDATE st
	SET st.PONo = po.PONumber
	FROM [DataTrue_Main].[dbo].[StoreTransactions] AS st
	INNER JOIN [DataTrue_Main].[dbo].[ICAM_POMatch] AS icam
	ON st.ChainID = icam.ChainID
	AND st.SupplierID = icam.SupplierID
	AND st.StoreID = icam.StoreID
	AND st.SaleDateTime = icam.InvoiceDate
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
	AND id.SaleDate = icam.InvoiceDate
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
	AND id.SaleDate = icam.InvoiceDate
	INNER JOIN [DataTrue_Main].[dbo].[iCAM_PONumbers] AS po
	ON po.iCamID = icam.RecordID
	AND po.RecordID = (SELECT TOP 1 RecordID
					   FROM [DataTrue_Main].[dbo].[iCAM_PONumbers] AS t
					   WHERE t.iCamID = po.iCamID
					   ORDER BY t.PONumber ASC)
	WHERE icam.RecordStatus = 2
	
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
		st2.SupplierInvoiceNumber,
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
		AND st2.SupplierInvoiceNumber = st.SupplierInvoiceNumber
		AND st2.SaleDateTime = st.SaleDateTime
		AND st2.TransactionTypeID IN (5, 8)
		GROUP BY st2.ChainID, st2.SupplierID, st2.StoreID, st2.SaleDateTime, st2.SupplierInvoiceNumber
	) AS ProductMatch
	ON ProductMatch.ChainID = icam.ChainID
	AND ProductMatch.SupplierID = icam.SupplierID
	AND ProductMatch.StoreID = icam.StoreID
	AND ProductMatch.SupplierInvoiceNumber = icam.InvoiceNumber
	WHERE icam.RecordStatus = 2
	
	UPDATE icam
	SET icam.SupplierTotalMatch = CASE WHEN (icam.RetailerInvoiceTotal = icam.SupplierInvoiceTotal) THEN 1 ELSE 0 END, 
		icam.SupplierQtyMatch = CASE WHEN (icam.RetailerInvoiceQty = icam.SupplierInvoiceQty) THEN 1 ELSE 0 END, 
		RecordStatus = 3 --UPDATE RECORD STATUS TO 3 ON LAST UPDATE
	FROM [DataTrue_Main].[dbo].[ICAM_POMatch] AS icam
	WHERE icam.RecordStatus = 2

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
