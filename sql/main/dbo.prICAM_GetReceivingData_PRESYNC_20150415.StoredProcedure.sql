USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prICAM_GetReceivingData_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[prICAM_GetReceivingData_PRESYNC_20150415]

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

    -- Insert statements for procedure here
	INSERT INTO [DataTrue_Main].[dbo].[ICAM_POMatch]
	(
	 [Filename]
	,[ChainID]
	,[SupplierID]
	,[StoreID]
	,[InvoiceNumber]
	,[InvoiceDate]
	,[RetailerInvoiceQty]
	,[RetailerInvoiceTotal]
	,[RetailerInvoiceLineItemCount]
	,[SupplierInvoiceQty]
	,[SupplierInvoiceTotal]
	,[POCount]
	)
	SELECT DISTINCT
	src.SourceName,
	st.ChainID,
	st.SupplierID,
	st.StoreID,
	st.SupplierInvoiceNumber,
	st.SaleDateTime,
	SUM(st.Qty),
	SUM(st.Qty * CASE WHEN st.RuleCost IS NULL THEN ISNULL(st.ReportedCost, 0) ELSE st.RuleCost END) + SUM(ISNULL(Adjustment1, 0))
																									  + SUM(ISNULL(Adjustment2, 0))
																									  + SUM(ISNULL(Adjustment3, 0))
																									  + SUM(ISNULL(Adjustment4, 0))
																									  + SUM(ISNULL(Adjustment5, 0))
																									  + SUM(ISNULL(Adjustment6, 0))
																									  + SUM(ISNULL(Adjustment7, 0))
																									  + SUM(ISNULL(Adjustment8, 0)),
	COUNT(st.StoreTransactionID),																								  
	0,
	0,
	0
	FROM [DataTrue_Main].[dbo].[StoreTransactions] AS st
	INNER JOIN [DataTrue_Main].[dbo].[Source] AS src
	ON st.SourceID = src.SourceID
	INNER JOIN [DataTrue_EDI].[dbo].[EDI_LoadStatus_Receiving] AS edi
	ON edi.ChainID = st.ChainID
	AND edi.SupplierID = st.SupplierID
	AND edi.Filename = src.SourceName
	WHERE st.TransactionTypeID = 32
	AND edi.LoadStatus = 2
	GROUP BY src.SourceName, st.ChainID, st.SupplierID, st.StoreID, st.SupplierInvoiceNumber, st.SaleDateTime
	
	INSERT INTO [DataTrue_Main].[dbo].[iCAM_PONumbers]
	(
	 [iCamID]
    ,[PONumber]
    ,[PODate]
    )
    SELECT DISTINCT
    icam.RecordID,
    st.PONo,
    NULL --NO PURCHASE ORDER DATE IN ST?
    FROM [DataTrue_Main].[dbo].[ICAM_POMatch] AS icam
    INNER JOIN [DataTrue_Main].[dbo].[StoreTransactions] AS st
    ON st.ChainID = icam.ChainID
    AND st.SupplierID = icam.SupplierID
    AND st.StoreID = icam.StoreID
    AND st.SaleDateTime = icam.InvoiceDate
    AND st.SupplierInvoiceNumber = icam.InvoiceNumber
	INNER JOIN [DataTrue_Main].[dbo].[Source] AS src
	ON src.SourceID = st.SourceID
	INNER JOIN [DataTrue_EDI].[dbo].[EDI_LoadStatus_Receiving] AS edi
	ON edi.ChainID = st.ChainID
	AND edi.SupplierID = st.SupplierID
	AND edi.Filename = src.SourceName
	WHERE st.TransactionTypeID = 32
	AND edi.LoadStatus = 2
	AND ISNULL(st.PONo, '') <> ''
	
	UPDATE edi
	SET edi.LoadStatus = 3, UpdatedTimestamp = GETDATE()
	FROM [DataTrue_Main].[dbo].[StoreTransactions] AS st
	INNER JOIN [DataTrue_Main].[dbo].[Source] AS src
	ON st.SourceID = src.SourceID
	INNER JOIN [DataTrue_EDI].[dbo].[EDI_LoadStatus_Receiving] AS edi
	ON edi.ChainID = st.ChainID
	AND edi.SupplierID = st.SupplierID
	AND edi.Filename = src.SourceName
	WHERE st.TransactionTypeID = 32
	AND edi.LoadStatus = 2
	
	UPDATE icam
	SET icam.POCount = ISNULL(po.POCount, 0), icam.RecordStatus = 1
	FROM [DataTrue_Main].[dbo].[ICAM_POMatch] AS icam
	LEFT OUTER JOIN 
	(
		SELECT iCamID, COUNT(DISTINCT PONumber) AS POCount
		FROM [DataTrue_Main].[dbo].[iCAM_PONumbers] AS t
		INNER JOIN [DataTrue_Main].[dbo].[ICAM_POMatch] AS t2
		ON t.iCamID = t2.RecordID
		WHERE t2.RecordStatus = 0
		GROUP BY t.iCamID
	) AS po
	ON icam.RecordID = po.iCamID
	WHERE icam.RecordStatus = 0
	
	COMMIT TRANSACTION
	
	END TRY
	
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @errorMessage = error_message()
		SET @errorLocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		SET @errorSenderString = ERROR_PROCEDURE()
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorLocation
		,@errorMessage
		,@errorSenderString
		,0
		
		EXEC dbo.prSendEmailNotification_PassEmailAddresses 'ICAM Job Stopped'
			,'An exception occurred in prICAM_GetReceivingData.  Manual review, resolution, and re-start will be required for the job to continue.'
			,'DataTrue System', 0, 'edi@icucsolutions.com'
		
		EXEC [msdb].[dbo].[sp_stop_job] 
			@job_name = 'ICAM'	

	END CATCH
	
END
GO
