USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_Newspapers_Shrink_Backup]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[prBilling_Newspapers_Shrink_Backup]

AS
BEGIN
	BEGIN TRY
	BEGIN TRANSACTION
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	--Get ProcessID
	DECLARE @ProcessID INT
	SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobName = 'NewspaperShrink'
	
	DECLARE @TempST TABLE (NewSTID BIGINT, OldSTID BIGINT, NewTransactionTypeID INT)
	DECLARE @TempSTPOS TABLE (NewSTID BIGINT)

    --INSERT REVERSALS FOR INVOICED RECORDS
	MERGE INTO DataTrue_Main.dbo.StoreTransactions AS target
	USING
	(
		SELECT i.Qty As CalcQty, st.*
		FROM DataTrue_Main.dbo.StoreTransactions AS st WITH (NOLOCK)
		INNER JOIN InventoryReport_Newspaper_Shrink_POSCheck AS i
		ON st.StoreTransactionID = i.StoreTransactionID
		AND i.TransactionStatus IN (810, 811)	
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
	,(source.[CalcQty])
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
	,@ProcessID
	,source.[RefIDToOriginalInvNo]
	,source.[PackSize]
	)
	OUTPUT inserted.StoreTransactionID, source.StoreTransactionID, inserted.TransactionTypeID INTO @TempST;

	--INSERT NEW SHRINK RECORDS WITH CORRECT VALUES
	MERGE INTO DataTrue_Main.dbo.StoreTransactions AS target
	USING
	(
		SELECT st.*, t.DeliveryQty, t.POSQty, t.FromPOS
		FROM DataTrue_Main.dbo.StoreTransactions AS st WITH (NOLOCK)
		INNER JOIN InventoryReport_Newspaper_Shrink_POSCheck AS t
		ON st.StoreTransactionID = t.StoreTransactionID
		AND t.TransactionStatus IN (810, 811)
		AND t.TransactionTypeID = 17
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
	,source.[TransactionTypeID]
	,source.[ProductPriceTypeID]
	,source.[BrandID]
	,CASE WHEN source.FromPOS = 0 THEN (source.DeliveryQty - source.POSQty) WHEN source.FromPOS = 1 THEN (source.POSQty) END
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
	,800
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
	,@ProcessID
	,source.[RefIDToOriginalInvNo]
	,source.[PackSize]
	)
	OUTPUT inserted.StoreTransactionID, source.StoreTransactionID, inserted.TransactionTypeID INTO @TempST;
	
	--INSERT NEW FROM POS RECORDS
	MERGE INTO DataTrue_Main.dbo.StoreTransactions AS target
	USING
	(
		SELECT *
		FROM InventoryReport_Newspaper_Shrink_POSCheck AS t
		WHERE t.StoreTransactionID = 0
		AND t.TransactionTypeID = 17
		AND t.POSQty <> 0
		AND t.FromPOS = 1
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
	,source.[TransactionTypeID]
	,3
	,source.[BrandID]
	,CASE WHEN source.FromPOS = 0 THEN (source.DeliveryQty - source.POSQty) WHEN source.FromPOS = 1 THEN (source.POSQty) END
	,source.RuleCost
	,source.RuleRetail
	,source.[SaleDate]
	,source.[UPC]
	,NULL
	,source.RuleCost
	,source.RuleRetail
	,NULL
	,NULL
	,source.[RuleCost]
	,source.[RuleRetail]
	,0
	,0
	,source.[RuleCost]
	,source.[RuleRetail]
	,0
	,800
	,0
	,NULL
	,135
	,NULL
	,NULL
	,GETDATE()
	,63600
	,GETDATE()
	,0
	,NULL
	,NULL
	,NULL
	,NULL
	,NULL
	,UPC
	,NULL
	,NULL
	,NULL
	,NULL
	,NULL
	,NULL
	,NULL
	,NULL
	,NULL
	,NULL
	,NULL
	,NULL
	,NULL
	,NULL
	,NULL
	,NULL
	,NULL
	,NULL
	,NULL
	,1 --[ShrinkLocked]
	,NULL
	,NULL
	,NULL
	,NULL
	,NULL
	,NULL
	,NULL
	,NULL
	,NULL
	,NULL
	,NULL
	,NULL
	,NULL
	,NULL
	,NULL
	,NULL
	,NULL
	,NULL
	,@ProcessID
	,NULL
	,NULL
	)
	OUTPUT inserted.StoreTransactionID INTO @TempSTPOS;

	--INSERT INTO SHRINK FACT TABLE	
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
	t.NewTransactionTypeID,
	i.[ChainID],
	i.[StoreID],
	i.[ProductID],
	i.[BrandID],
	i.[SupplierID],
	[SaleDateTime],
	[UnitCost],
	CASE WHEN t.NewTransactionTypeID = 17 THEN (CASE WHEN newCalc.FromPOS = 0 THEN (newCalc.DeliveryQty - newCalc.POSQty)
													 WHEN newCalc.FromPOS = 1 THEN (newCalc.POSQty) END)
	     ELSE [ShrinkUnits]
	END,
	CASE WHEN t.NewTransactionTypeID = 17 THEN (CASE WHEN newCalc.FromPOS = 0 THEN (i.UnitCost * (newCalc.DeliveryQty - newCalc.POSQty))
													 WHEN newCalc.FromPOS = 1 THEN (i.UnitCost * (newCalc.POSQty)) END) 
		 ELSE [Shrink$]
	END,
	GETDATE(),
	[LastUpdateUserID],
	CASE WHEN newCalc.TransactionStatus IN (810, 811) THEN 1
		 WHEN newCalc.TransactionStatus IN (-800, 0, 800, 815) THEN 2
	END	,
	t.NewSTID,
	CASE WHEN t.NewTransactionTypeID = 17 THEN newCalc.POSQty ELSE [OriginalPOS] END,
	ISNULL([OriginalDeliveries], 0),
	ISNULL([OriginalPickups], 0),
	GETDATE(),
	DeniedDCRSendStatus,
	DeniedDCRSendDateTime
	FROM DataTrue_Main.dbo.[InventoryReport_Newspaper_Shrink_Facts] AS i WITH (NOLOCK)
	INNER JOIN @TempST AS t
	ON i.StoreTransactionID = t.OldSTID
	INNER JOIN InventoryReport_Newspaper_Shrink_POSCheck AS newCalc
	ON newCalc.StoreTransactionID = t.OldSTID
	
	--UPDATE NON-INVOICED RECORDS TO CORRECT VALUES
	UPDATE st
	SET st.Qty = (CASE WHEN newCalc.FromPOS = 0 THEN (newCalc.DeliveryQty - newCalc.POSQty)
					   WHEN newCalc.FromPOS = 1 THEN (newCalc.POSQty) END),
		st.TransactionStatus = (CASE WHEN newCalc.FromPOS = 0 THEN (CASE WHEN (newCalc.DeliveryQty - newCalc.POSQty) = 0 THEN 815 ELSE 0 END)
									 WHEN newCalc.FromPOS = 1 THEN (CASE WHEN (newCalc.POSQty) = 0 THEN 815 ELSE 0 END) END),
		st.DateTimeLastUpdate = GETDATE()									  
	FROM DataTrue_Main.dbo.StoreTransactions AS st
	INNER JOIN InventoryReport_Newspaper_Shrink_POSCheck AS newCalc
	ON st.StoreTransactionID = newCalc.StoreTransactionID
	AND newCalc.TransactionStatus IN (-800, 0, 800, 815)
	WHERE newCalc.FromPOS = 0
	
	--UPDATE SHRINK FACT TABLE TO CORRECT VALUES
	UPDATE fact
	SET fact.OriginalPOS = newCalc.POSQty,
	    fact.ShrinkUnits = (CASE WHEN newCalc.FromPOS = 0 THEN (newCalc.DeliveryQty - newCalc.POSQty)
							     WHEN newCalc.FromPOS = 1 THEN (newCalc.POSQty) END),
	    fact.Shrink$ = (CASE WHEN newCalc.FromPOS = 0 THEN (fact.UnitCost * (newCalc.DeliveryQty - newCalc.POSQty))
							 WHEN newCalc.FromPOS = 1 THEN (fact.UnitCost * (newCalc.POSQty)) END),
		fact.Status = (CASE WHEN newCalc.FromPOS = 0 THEN (CASE WHEN (newCalc.DeliveryQty - newCalc.POSQty) = 0 THEN 4 ELSE 2 END)
							WHEN newCalc.FromPOS = 1 THEN (CASE WHEN (newCalc.POSQty) = 0 THEN 4 ELSE 2 END) END),
		fact.ApprovalDateTime = null,
		fact.DeniedDCRSendDateTime = null,
		fact.DeniedDCRSendStatus = 0,
		fact.RejectReason = null					 
	FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_Facts AS fact
	INNER JOIN InventoryReport_Newspaper_Shrink_POSCheck AS newCalc
	ON fact.StoreTransactionID = newCalc.StoreTransactionID
	AND newCalc.TransactionStatus IN (-800, 0, 800, 815)
	WHERE newCalc.FromPOS = 0

	--INSERT NEW FROM POS RECORDS
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
	st.TransactionTypeID,
	st.[ChainID],
	st.[StoreID],
	st.[ProductID],
	st.[BrandID],
	st.[SupplierID],
	st.[SaleDateTime],
	st.RuleCost,
	st.Qty,
	(st.RuleCost * (st.Qty)),
	GETDATE(),
	63600,
	1,
	st.StoreTransactionID,
	st.Qty,
	0,
	0,
	GETDATE(),
	NULL,
	NULL
	FROM DataTrue_Main.dbo.StoreTransactions AS st WITH (NOLOCK)
	INNER JOIN @TempSTPOS AS t
	ON st.StoreTransactionID = t.NewSTID
	
	COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		DECLARE @ErrorMessage VARCHAR(MAX)
		SET @ErrorMessage = ERROR_MESSAGE()
		DECLARE @emailSubject VARCHAR(MAX) = 'ERROR in Billing_Newspapers_Shrink_NewEDIData Job / [prBilling_Newspapers_Shrink_Create]'
		DECLARE @emailMessage VARCHAR(MAX) = @ErrorMessage
		DECLARE @emailRecipients VARCHAR(MAX) = 'william.heine@icucsolutions.com'
		EXEC dbo.prSendEmailNotification_PassEmailAddresses @emailSubject, @emailMessage, 'DataTrue System', 0, @emailRecipients
	END CATCH
END
GO
