USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_Newspapers_Shrink_ApproveInSettlement]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[prBilling_Newspapers_Shrink_ApproveInSettlement]
	@ChainIdentifier VARCHAR(50),
	@SessionID VARCHAR(100) = ''
AS
BEGIN

BEGIN TRY

	DECLARE @ApprovedTotal NUMERIC(18, 9)
	DECLARE @RejectedTotal NUMERIC(18, 9)
	DECLARE @PaidTotal NUMERIC(18, 9)

	DECLARE @ChainID INT
	DECLARE @FirstWeekEndingDate DATE
	DECLARE @FirstSaleDate DATE
	DECLARE @DayOfWeek INT
	DECLARE @SQL VARCHAR(MAX)
	
	DECLARE @ShrinkDCRsApprovals VARCHAR(2000) = '[DataTrue_EDI].[dbo].Shrink_DCRs_Approvals' + @SessionID
									
	SELECT @ChainID = ChainID FROM DataTrue_Main.dbo.Chains WHERE ChainIdentifier = @ChainIdentifier

	SELECT @FirstSaleDate = cm.datemigrated
	FROM DataTrue_Main.dbo.chains_migration AS cm WITH (NOLOCK)
	WHERE chainid = @ChainIdentifier

	SET @FirstWeekEndingDate = DATEADD(d, 6, @FirstSaleDate)
	SET @DayOfWeek = DATEPART(dw, @FirstWeekEndingDate)

	SET DATEFIRST @DayOfWeek

	SET @SQL = 'UPDATE i
				SET Status = 1, i.[ApprovalDateTime] = GETDATE()
				FROM InventoryReport_Newspaper_Shrink_Facts i
				INNER JOIN ' + @ShrinkDCRsApprovals + '  AS approved
				ON i.StoreID = (SELECT storeid FROM stores s WHERE s.LegacySystemStoreIdentifier = approved.StoreID)
				AND CAST(i.ChainID AS VARCHAR)  = ' + CAST(@ChainID  AS VARCHAR) +'
				AND i.Supplierid = (SELECT SupplierId FROM Suppliers s WHERE s.SupplierIdentifier = approved.Wholesaler)
				AND DATEDIFF(WEEK, DATEADD(dd,-@@datefirst, ''' + CAST(@FirstSaleDate AS VARCHAR) + '''), DATEADD(dd,-@@datefirst,i.SaleDateTime)) = DATEDIFF(WEEK, DATEADD(dd,-@@datefirst,''' + CAST(@FirstSaleDate AS VARCHAR) + '''), DATEADD(dd,-@@datefirst,[W/E]))
				AND approved.[A/R] = ''A''
				AND i.Status = 2
				AND i.ApprovalDateTime IS NULL'
	EXEC(@SQL)
	

	SET @SQL = 'UPDATE i
				SET Status = 3, i.[ApprovalDateTime] = GETDATE(), i.RejectReason = ''Client Rejection (via iControl Analyst)''
				FROM InventoryReport_Newspaper_Shrink_Facts i
				INNER JOIN ' + @ShrinkDCRsApprovals + ' AS approved
				ON i.StoreID = (SELECT storeid FROM stores s WHERE s.LegacySystemStoreIdentifier = approved.StoreID)
				AND CAST(i.ChainID AS VARCHAR)  = ' + CASt(@ChainID  AS VARCHAR) +'
				AND i.Supplierid = (SELECT SupplierId FROM Suppliers s WHERE s.SupplierIdentifier = approved.Wholesaler)
				AND DATEDIFF(WEEK, DATEADD(dd,-@@datefirst,''' + CAST(@FirstSaleDate AS VARCHAR) + '''), DATEADD(dd,-@@datefirst,i.SaleDateTime)) = DATEDIFF(WEEK, DATEADD(dd,-@@datefirst,''' + CAST(@FirstSaleDate AS VARCHAR) + '''), DATEADD(dd,-@@datefirst,[W/E]))
				AND approved.[A/R] = ''R''
				AND i.Status = 2
				AND i.ApprovalDateTime IS NULL'
	EXEC(@SQL)
	 
	SET @SQL = 'UPDATE i
				SET Status = 6, i.[ApprovalDateTime] = GETDATE(), i.RejectReason = ''Client Rejection (via iControl Analyst)''
				FROM InventoryReport_Newspaper_Shrink_Facts i
				INNER JOIN ' + @ShrinkDCRsApprovals + ' AS approved
				ON i.StoreID = (SELECT storeid FROM stores s WHERE s.LegacySystemStoreIdentifier = approved.StoreID)
				AND CAST(i.ChainID AS VARCHAR)  = ' + CASt(@ChainID  AS VARCHAR) +'
				AND i.Supplierid = (SELECT SupplierId FROM Suppliers s WHERE s.SupplierIdentifier = approved.Wholesaler)
				AND DATEDIFF(WEEK, DATEADD(dd,-@@datefirst,''' + CAST(@FirstSaleDate AS VARCHAR) + '''), DATEADD(dd,-@@datefirst,i.SaleDateTime)) = DATEDIFF(WEEK, DATEADD(dd,-@@datefirst,''' + CAST(@FirstSaleDate AS VARCHAR) + '''), DATEADD(dd,-@@datefirst,[W/E]))
				AND approved.[A/R] = ''P''
				AND i.Status = 2
				AND i.ApprovalDateTime IS NULL'
	EXEC(@SQL)

	--CREATE REVERSAL RECORDS FOR OLD APPROVED THAT HAVE MATCHING NEW APPROVED
	DECLARE @NeedToRejectSTIDs TABLE (StoreTransactionID BIGINT)
	DECLARE @TempST TABLE (NewSTID BIGINT, OldSTID BIGINT, NewTransactionTypeID INT)
	
	UPDATE f
	SET Status = 3, RejectReason = 'Replaced by new approved shrink that has matching context.', ApprovalDateTime = GETDATE(), DeniedDCRSendStatus = 1, DeniedDCRSendDateTime = GETDATE()
	OUTPUT inserted.StoreTransactionID INTO @NeedToRejectSTIDs
	FROM DataTrue_Main..InventoryReport_Newspaper_Shrink_Facts AS f
	WHERE TransactionTypeID = 17
	AND StoreTransactionID IN
	(
		SELECT DISTINCT f1.StoreTransactionID
		FROM DataTrue_Main..InventoryReport_Newspaper_Shrink_Facts f1
		INNER JOIN DataTrue_Main..InventoryReport_Newspaper_Shrink_Facts f2
		ON f1.ChainID = f2.ChainID
		AND f1.StoreID = f2.StoreID
		AND f1.ProductID = f2.ProductID
		AND f1.SaleDateTime = f2.SaleDateTime
		AND f1.Status = 5
		AND f2.Status = 1
	)
	
	--Need to create TransactionType 19 Records in StoreTransactions table for shrink reversals
	
	--INSERT REVERSALS
	MERGE INTO DataTrue_Main.dbo.StoreTransactions AS target
	USING
	(
		SELECT *
		FROM DataTrue_Main.dbo.StoreTransactions AS st WITH (NOLOCK)
		WHERE StoreTransactionID IN (SELECT StoreTransactionID FROM @NeedToRejectSTIDs)
	) AS source
	ON (1 = 0)
	WHEN NOT MATCHED THEN
	INSERT
	(
	 [ChainID]
	,[StoreID]
	,[ProductID]
	,[SupplierID]
	,[TransactionTypeID]
	,[ProductPriceTypeID]
	,[BrandID]
	,[Qty]
	,[SetupCost]
	,[SetupRetail]
	,[SaleDateTime]
	,[UPC]
	,[SupplierInvoiceNumber]
	,[ReportedCost]
	,[ReportedRetail]
	,[ReportedAllowance]
	,[ReportedPromotionPrice]
	,[RuleCost]
	,[RuleRetail]
	,[CostMisMatch]
	,[RetailMisMatch]
	,[TrueCost]
	,[TrueRetail]
	,[ActualCostNetFee]
	,[TransactionStatus]
	,[Reversed]
	,[ProcessingErrorDesc]
	,[SourceID]
	,[Comments]
	,[InvoiceID]
	,[DateTimeCreated]
	,[LastUpdateUserID]
	,[DateTimeLastUpdate]
	,[WorkingTransactionID]
	,[InvoiceBatchID]
	,[InventoryCost]
	,[ChainIdentifier]
	,[StoreIdentifier]
	,[StoreName]
	,[ProductIdentifier]
	,[ProductQualifier]
	,[RawProductIdentifier]
	,[SupplierName]
	,[SupplierIdentifier]
	,[BrandIdentifier]
	,[DivisionIdentifier]
	,[UOM]
	,[SalePrice]
	,[InvoiceNo]
	,[PONo]
	,[CorporateName]
	,[CorporateIdentifier]
	,[Banner]
	,[PromoTypeID]
	,[PromoAllowance]
	,[SBTNumber]
	,[SourceOrDestinationID]
	,[CreditType]
	,[PODReceived]
	,[ShrinkLocked]
	,[InvoiceDueDate]
	,[Adjustment1]
	,[Adjustment2]
	,[Adjustment3]
	,[Adjustment4]
	,[Adjustment5]
	,[Adjustment6]
	,[Adjustment7]
	,[Adjustment8]
	,[Route]
	,[SupplierItemNumber]
	,[ProductDescriptionReported]
	,[RawStoreIdentifier]
	,[CaseUPC]
	,[UnAuthorizedAssignment]
	,[SetupAllowance]
	,[AccountCode]
	,[RecordType]
	,[ProcessID]
	,[RefIDToOriginalInvNo]
	,[PackSize]
	)
	VALUES
	(
	 source.[ChainID]
	,source.[StoreID]
	,source.[ProductID]
	,source.[SupplierID]
	,19 --TRANSACTION TYPE ID OF 19 FOR SHRINK REVERSAL ORIGINATING FROM SUP SOURCE
	,source.[ProductPriceTypeID]
	,source.[BrandID]
	,(source.[Qty])
	,source.[SetupCost]
	,source.[SetupRetail]
	,source.[SaleDateTime]
	,source.[UPC]
	,source.[SupplierInvoiceNumber]
	,source.[ReportedCost]
	,source.[ReportedRetail]
	,source.[ReportedAllowance]
	,source.[ReportedPromotionPrice]
	,source.[RuleCost]
	,source.[RuleRetail]
	,source.[CostMisMatch]
	,source.[RetailMisMatch]
	,source.[TrueCost]
	,source.[TrueRetail]
	,source.[ActualCostNetFee]
	,800 --TRANSACTION STATUS SET TO 800 SO REVERSALS WILL BE INVOICED
	,source.[Reversed]
	,source.[ProcessingErrorDesc]
	,source.[SourceID]
	,source.[Comments]
	,source.[InvoiceID]
	,GETDATE()
	,source.[LastUpdateUserID]
	,GETDATE()
	,source.[WorkingTransactionID]
	,source.[InvoiceBatchID]
	,source.[InventoryCost]
	,source.[ChainIdentifier]
	,source.[StoreIdentifier]
	,source.[StoreName]
	,source.[ProductIdentifier]
	,source.[ProductQualifier]
	,source.[RawProductIdentifier]
	,source.[SupplierName]
	,source.[SupplierIdentifier]
	,source.[BrandIdentifier]
	,source.[DivisionIdentifier]
	,source.[UOM]
	,source.[SalePrice]
	,source.[InvoiceNo]
	,source.[PONo]
	,source.[CorporateName]
	,source.[CorporateIdentifier]
	,source.[Banner]
	,source.[PromoTypeID]
	,source.[PromoAllowance]
	,source.[SBTNumber]
	,source.[SourceOrDestinationID]
	,source.[CreditType]
	,source.[PODReceived]
	,1 --[ShrinkLocked]
	,source.[InvoiceDueDate]
	,source.[Adjustment1]
	,source.[Adjustment2]
	,source.[Adjustment3]
	,source.[Adjustment4]
	,source.[Adjustment5]
	,source.[Adjustment6]
	,source.[Adjustment7]
	,source.[Adjustment8]
	,source.[Route]
	,source.[SupplierItemNumber]
	,source.[ProductDescriptionReported]
	,source.[RawStoreIdentifier]
	,source.[CaseUPC]
	,source.[UnAuthorizedAssignment]
	,source.[SetupAllowance]
	,source.[AccountCode]
	,source.[RecordType]
	,source.[ProcessID]
	,source.[RefIDToOriginalInvNo]
	,source.[PackSize]
	)
	OUTPUT inserted.StoreTransactionID, source.StoreTransactionID, inserted.TransactionTypeID INTO @TempST;
	
	INSERT INTO [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts]
	(
	[TransactionTypeID],
	[ChainID],
	[StoreID],
	[ProductID],
	[BrandID],
	[SupplierID],
	[SaleDateTime],
	[UnitCost],
	[ShrinkUnits],
	[Shrink$],
	[DateTimeCreated],
	[LastUpdateUserID],
	[Status],
	[StoreTransactionID],
	[OriginalPOS],
	[OriginalDeliveries],
	[OriginalPickups],
	[ApprovalDateTime],
	DeniedDCRSendStatus,
	DeniedDCRSendDateTime
	)
	SELECT DISTINCT
	19,
	[ChainID],
	[StoreID],
	[ProductID],
	[BrandID],
	[SupplierID],
	[SaleDateTime],
	[UnitCost],
	[ShrinkUnits],
	[Shrink$],
	GETDATE(),
	[LastUpdateUserID],
	[Status],
	t.NewSTID,
	[OriginalPOS],
	[OriginalDeliveries],
	[OriginalPickups],
	[ApprovalDateTime],
	DeniedDCRSendStatus,
	DeniedDCRSendDateTime
	FROM DataTrue_Main.dbo.[InventoryReport_Newspaper_Shrink_Facts] AS st
	INNER JOIN @TempST AS t
	ON st.StoreTransactionID = t.OldSTID
	
	--RESET RECORDS TO APPROVED FOR OLD APPROVED THAT HAVE NEW MATCHING THAT WAS REJECTED
	UPDATE f
	SET Status = 1
	FROM DataTrue_Main..InventoryReport_Newspaper_Shrink_Facts AS f
	WHERE StoreTransactionID IN
	(
		SELECT DISTINCT f1.StoreTransactionID
		FROM DataTrue_Main..InventoryReport_Newspaper_Shrink_Facts f1
		INNER JOIN DataTrue_Main..InventoryReport_Newspaper_Shrink_Facts f2
		ON f1.ChainID = f2.ChainID
		AND f1.StoreID = f2.StoreID
		AND f1.ProductID = f2.ProductID
		AND f1.SaleDateTime = f2.SaleDateTime
		AND f1.Status = 5
		AND f2.Status = 3
	)
	
	IF(LEN(RTRIM(@SessionID)) > 1)
	BEGIN
		SET @SQL = 'IF OBJECT_ID(''' + @ShrinkDCRsApprovals + ''', ''U'') IS NOT NULL DROP TABLE '+ @ShrinkDCRsApprovals
		EXEC (@SQL)
	END

END TRY

BEGIN CATCH

ROLLBACK TRANSACTION
		
		declare @errormessage varchar(max),
				@errorlocation varchar(500),
				@errorsenderstring varchar(500)

		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Newspapers_Shrink_NewInvoiceData Job Stopped'
			,'An exception occurred in [prBilling_Newspapers_Shrink_ApproveInSettlement].  Manual review, resolution, and re-start will be required for the job to continue.'
			,'DataTrue System', 0, 'datatrueit@icucsolutions.com'--'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
		
		exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'Billing_Newspapers_Shrink_NewInvoiceData'
			
END CATCH

END
GO
