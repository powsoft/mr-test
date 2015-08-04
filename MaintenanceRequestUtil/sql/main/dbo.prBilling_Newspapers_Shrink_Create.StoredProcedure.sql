USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_Newspapers_Shrink_Create]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[prBilling_Newspapers_Shrink_Create]

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
	
	DECLARE @TempST TABLE (STID BIGINT, TransactionTypeID INT, TransactionStatus INT, ChainID INT, SupplierID INT, StoreID INT, ProductID INT, SaleDate DATETIME, RuleCost MONEY, RuleRetail MONEY)
	DECLARE @ErrorMessage VARCHAR(MAX)
	
	--=======================
	--VALIDATIONS
	--=======================
	IF (SELECT COUNT(*) FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_Calculate WHERE DeliveryQty IS NULL) > 0
		BEGIN
			SET @ErrorMessage = 'Records in InventoryReport_Newspaper_Shrink_Calculate with NULL DeliveryQty value'
			RAISERROR (@ErrorMessage, 16, 1);
		END
	IF (SELECT COUNT(*) FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_Calculate WHERE PickupQty IS NULL) > 0
		BEGIN
			SET @ErrorMessage = 'Records in InventoryReport_Newspaper_Shrink_Calculate with NULL PickupQty value'
			RAISERROR (@ErrorMessage, 16, 1);
		END
	IF (SELECT COUNT(*) FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_Calculate WHERE POSQty IS NULL) > 0
		BEGIN
			SET @ErrorMessage = 'Records in InventoryReport_Newspaper_Shrink_Calculate with NULL POSQty value'
			RAISERROR (@ErrorMessage, 16, 1);
		END
	IF (SELECT COUNT(*) FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_Calculate WHERE RuleCost IS NULL) > 0
		BEGIN
			SET @ErrorMessage = 'Records in InventoryReport_Newspaper_Shrink_Calculate with NULL RuleCost value'
			RAISERROR (@ErrorMessage, 16, 1);
		END
	IF (SELECT COUNT(*) FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_Calculate WHERE FromPOS IS NULL) > 0
		BEGIN
			SET @ErrorMessage = 'Records in InventoryReport_Newspaper_Shrink_Calculate with NULL FromPOS value'
			RAISERROR (@ErrorMessage, 16, 1);
		END

    --INSERT NEW ADJUSTED SHRINK RECORDS TO NET OUT DIFFERENCES WHERE NOT BILLED
	INSERT INTO DataTrue_Main.dbo.StoreTransactions
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
	OUTPUT inserted.StoreTransactionID, inserted.TransactionTypeID, inserted.TransactionStatus, inserted.ChainID, inserted.SupplierID, inserted.StoreID, inserted.ProductID, inserted.SaleDateTime, inserted.RuleCost, inserted.RuleRetail
	INTO @TempST
	SELECT DISTINCT
	 calc.[ChainID]
	,calc.[StoreID]
	,calc.[ProductID]
	,calc.[SupplierID]
	,17 
	,3--ProductPriceTypeID
	,0 AS BrandID
	,CASE WHEN calc.FromPOS = 0 THEN (calc.TotalShrinkQty * - 1) + (DeliveryQty - PickupQty - POSQty) 
								ELSE (calc.TotalShrinkQty * - 1) + (POSQty) 
	 END AS AdjustedQty 
	,calc.RuleCost
	,calc.RuleRetail
	,calc.SaleDate
	,calc.UPC
	,NULL --SupplierInvoiceNumber is all null in TransactionType17 = if changed the Shrink Calc engine needs to group by SupplierInvoiceNumber as well (probably index should be added).
	,calc.RuleCost
	,calc.RuleRetail
	,NULL--[ReportedAllowance]
	,NULL--[ReportedPromotionPrice]
	,calc.[RuleCost]
	,calc.[RuleRetail]
	,0--[CostMisMatch]
	,0--[RetailMisMatch]
	,calc.[RuleCost]
	,calc.[RuleRetail]
	,NULL--[ActualCostNetFee]
	,CASE WHEN calc.FromPOS = 1 THEN 800 ELSE
	 CASE WHEN calc.NewShrink = 1 THEN 0
		  WHEN calc.RejectedShrinkQty = 0 THEN 0
		  WHEN calc.RejectedShrinkQty <> 0 AND InSettlementShrinkQty = 0 THEN -800
		  END
	 END AS TransactionStatus
	,0 --[Reversed]
	,NULL--[ProcessingErrorDesc]
	,135--[SourceID] WHEN FILENAME IS CAPTURED MAY WANT TO GROUP BY SOURCEID AS WELL IN CALC ENGINE
	,NULL--[Comments]
	,NULL--[InvoiceID]
	,GETDATE()
	,63600--[LastUpdateUserID]
	,GETDATE()
	,0--.[WorkingTransactionID]
	,NULL--[InvoiceBatchID]
	,NULL--[InventoryCost]
	,NULL--.[ChainIdentifier]
	,NULL--.[StoreIdentifier]
	,NULL--.[StoreName]
	,calc.UPC--[ProductIdentifier]
	,NULL--[ProductQualifier]
	,calc.UPC--[RawProductIdentifier]
	,NULL--.[SupplierName]
	,NULL--.[SupplierIdentifier]
	,NULL--.[BrandIdentifier]
	,NULL--.[DivisionIdentifier]
	,NULL--.[UOM]
	,NULL--.[SalePrice]
	,NULL--.[InvoiceNo]
	,NULL--.[PONo]
	,NULL--.[CorporateName]
	,NULL--.[CorporateIdentifier]
	,NULL--.[Banner]
	,NULL--.[PromoTypeID]
	,NULL--.[PromoAllowance]
	,NULL--.[SBTNumber]
	,NULL--.[SourceOrDestinationID]
	,NULL--.[CreditType]
	,NULL--.[PODReceived]
	,1 --[ShrinkLocked]
	,NULL--.[InvoiceDueDate]
	,NULL--.[Adjustment1]
	,NULL--.[Adjustment2]
	,NULL--.[Adjustment3]
	,NULL--.[Adjustment4]
	,NULL--.[Adjustment5]
	,NULL--.[Adjustment6]
	,NULL--.[Adjustment7]
	,NULL--.[Adjustment8]
	,NULL--.[Route]
	,NULL--.[SupplierItemNumber]
	,NULL--.[ProductDescriptionReported]
	,NULL--lc.[RawStoreIdentifier]
	,NULL--.[CaseUPC]
	,NULL--.[UnAuthorizedAssignment]
	,NULL--.[SetupAllowance]
	,NULL--.[AccountCode]
	,NULL--.[RecordType]
	,@ProcessID
	,NULL--.[RefIDToOriginalInvNo]
	,NULL--.[PackSize]
	FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_Calculate AS calc
	WHERE calc.InvoicedShrinkQty = 0
	AND calc.RecordStatus = 0
	
	--INSERT REVERSALS FOR BILLED ITEMS
	INSERT INTO DataTrue_Main.dbo.StoreTransactions
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
	OUTPUT inserted.StoreTransactionID, inserted.TransactionTypeID, inserted.TransactionStatus, inserted.ChainID, inserted.SupplierID, inserted.StoreID, inserted.ProductID, inserted.SaleDateTime, inserted.RuleCost, inserted.RuleRetail
	INTO @TempST
	SELECT DISTINCT
	 calc.[ChainID]
	,calc.[StoreID]
	,calc.[ProductID]
	,calc.[SupplierID]
	,19
	,3--ProductPriceTypeID
	,calc.[BrandID]
	,calc.InvoicedShrinkQty --EXISTING SHRINK QTY
	,calc.RuleCost
	,calc.RuleRetail
	,calc.SaleDate
	,calc.UPC
	,NULL --SupplierInvoiceNumber is all null in TransactionType17 = if changed the Shrink Calc engine needs to group by SupplierInvoiceNumber as well (probably index should be added).
	,calc.RuleCost
	,calc.RuleRetail
	,NULL--[ReportedAllowance]
	,NULL--[ReportedPromotionPrice]
	,calc.[RuleCost]
	,calc.[RuleRetail]
	,0--[CostMisMatch]
	,0--[RetailMisMatch]
	,calc.[RuleCost]
	,calc.[RuleRetail]
	,NULL--[ActualCostNetFee]
	,800 --TransactionStatus
	,0 --[Reversed]
	,NULL--[ProcessingErrorDesc]
	,135--[SourceID] WHEN FILENAME IS CAPTURED MAY WANT TO GROUP BY SOURCEID AS WELL IN CALC ENGINE
	,NULL--[Comments]
	,NULL--[InvoiceID]
	,GETDATE()
	,63600--[LastUpdateUserID]
	,GETDATE()
	,0--.[WorkingTransactionID]
	,NULL--[InvoiceBatchID]
	,NULL--[InventoryCost]
	,NULL--.[ChainIdentifier]
	,NULL--.[StoreIdentifier]
	,NULL--.[StoreName]
	,calc.UPC--[ProductIdentifier]
	,NULL--[ProductQualifier]
	,calc.UPC--[RawProductIdentifier]
	,NULL--.[SupplierName]
	,NULL--.[SupplierIdentifier]
	,NULL--.[BrandIdentifier]
	,NULL--.[DivisionIdentifier]
	,NULL--.[UOM]
	,NULL--.[SalePrice]
	,NULL--.[InvoiceNo]
	,NULL--.[PONo]
	,NULL--.[CorporateName]
	,NULL--.[CorporateIdentifier]
	,NULL--.[Banner]
	,NULL--.[PromoTypeID]
	,NULL--.[PromoAllowance]
	,NULL--.[SBTNumber]
	,NULL--.[SourceOrDestinationID]
	,NULL--.[CreditType]
	,NULL--.[PODReceived]
	,1 --[ShrinkLocked]
	,NULL--.[InvoiceDueDate]
	,NULL--.[Adjustment1]
	,NULL--.[Adjustment2]
	,NULL--.[Adjustment3]
	,NULL--.[Adjustment4]
	,NULL--.[Adjustment5]
	,NULL--.[Adjustment6]
	,NULL--.[Adjustment7]
	,NULL--.[Adjustment8]
	,NULL--.[Route]
	,NULL--.[SupplierItemNumber]
	,NULL--.[ProductDescriptionReported]
	,NULL--lc.[RawStoreIdentifier]
	,NULL--.[CaseUPC]
	,NULL--.[UnAuthorizedAssignment]
	,NULL--.[SetupAllowance]
	,NULL--.[AccountCode]
	,NULL--.[RecordType]
	,@ProcessID
	,NULL--.[RefIDToOriginalInvNo]
	,NULL--.[PackSize]
	FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_Calculate AS calc
	WHERE calc.InvoicedShrinkQty <> 0
	AND calc.InSettlementShrinkQty = 0
	AND calc.RejectedShrinkQty = 0
	AND calc.InSettlementShrinkQty = 0
	AND calc.RecordStatus = 0
	
	--INSERT CORRECTED SHRINK QTY FOR INVOICED ITEMS (AFTER REVERSALS FOR EXISTING SHRINK QTY)
	INSERT INTO DataTrue_Main.dbo.StoreTransactions
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
	OUTPUT inserted.StoreTransactionID, inserted.TransactionTypeID, inserted.TransactionStatus, inserted.ChainID, inserted.SupplierID, inserted.StoreID, inserted.ProductID, inserted.SaleDateTime, inserted.RuleCost, inserted.RuleRetail
	INTO @TempST
	SELECT DISTINCT
	 calc.[ChainID]
	,calc.[StoreID]
	,calc.[ProductID]
	,calc.[SupplierID]
	,17
	,3--ProductPriceTypeID
	,calc.[BrandID]
	,CASE WHEN calc.FromPOS = 0 THEN (DeliveryQty - PickupQty - POSQty) ELSE (POSQty) END --CORRECT QTY
	,calc.RuleCost
	,calc.RuleRetail
	,calc.SaleDate
	,calc.UPC
	,NULL --SupplierInvoiceNumber is all null in TransactionType17 = if changed the Shrink Calc engine needs to group by SupplierInvoiceNumber as well (probably index should be added).
	,calc.RuleCost
	,calc.RuleRetail
	,NULL--[ReportedAllowance]
	,NULL--[ReportedPromotionPrice]
	,calc.[RuleCost]
	,calc.[RuleRetail]
	,0--[CostMisMatch]
	,0--[RetailMisMatch]
	,calc.[RuleCost]
	,calc.[RuleRetail]
	,NULL--[ActualCostNetFee]
	,800 --TransactionStatus
	,0 --[Reversed]
	,NULL--[ProcessingErrorDesc]
	,135--[SourceID] WHEN FILENAME IS CAPTURED MAY WANT TO GROUP BY SOURCEID AS WELL IN CALC ENGINE
	,NULL--[Comments]
	,NULL--[InvoiceID]
	,GETDATE()
	,63600--[LastUpdateUserID]
	,GETDATE()
	,0--.[WorkingTransactionID]
	,NULL--[InvoiceBatchID]
	,NULL--[InventoryCost]
	,NULL--.[ChainIdentifier]
	,NULL--.[StoreIdentifier]
	,NULL--.[StoreName]
	,calc.UPC--[ProductIdentifier]
	,NULL--[ProductQualifier]
	,calc.UPC--[RawProductIdentifier]
	,NULL--.[SupplierName]
	,NULL--.[SupplierIdentifier]
	,NULL--.[BrandIdentifier]
	,NULL--.[DivisionIdentifier]
	,NULL--.[UOM]
	,NULL--.[SalePrice]
	,NULL--.[InvoiceNo]
	,NULL--.[PONo]
	,NULL--.[CorporateName]
	,NULL--.[CorporateIdentifier]
	,NULL--.[Banner]
	,NULL--.[PromoTypeID]
	,NULL--.[PromoAllowance]
	,NULL--.[SBTNumber]
	,NULL--.[SourceOrDestinationID]
	,NULL--.[CreditType]
	,NULL--.[PODReceived]
	,1 --[ShrinkLocked]
	,NULL--.[InvoiceDueDate]
	,NULL--.[Adjustment1]
	,NULL--.[Adjustment2]
	,NULL--.[Adjustment3]
	,NULL--.[Adjustment4]
	,NULL--.[Adjustment5]
	,NULL--.[Adjustment6]
	,NULL--.[Adjustment7]
	,NULL--.[Adjustment8]
	,NULL--.[Route]
	,NULL--.[SupplierItemNumber]
	,NULL--.[ProductDescriptionReported]
	,NULL--lc.[RawStoreIdentifier]
	,NULL--.[CaseUPC]
	,NULL--.[UnAuthorizedAssignment]
	,NULL--.[SetupAllowance]
	,NULL--.[AccountCode]
	,NULL--.[RecordType]
	,@ProcessID
	,NULL--.[RefIDToOriginalInvNo]
	,NULL--.[PackSize]
	FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_Calculate AS calc
	WHERE calc.InvoicedShrinkQty <> 0
	AND calc.InSettlementShrinkQty = 0
	AND calc.RejectedShrinkQty = 0
	AND calc.InSettlementShrinkQty = 0
	AND calc.RecordStatus = 0

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
	[ExistingShrinkQty],
	[ApprovalDateTime],
	DeniedDCRSendStatus,
	DeniedDCRSendDateTime
	)
	SELECT DISTINCT
	t.TransactionTypeID, --NO ADJUSTMENTS IF NOT BILLED
	calc.[ChainID],
	calc.[StoreID],
	calc.[ProductID],
	0,--[BrandID],
	calc.[SupplierID],
	calc.[SaleDate],
	calc.RuleCost,
	CASE WHEN t.TransactionStatus IN (800, 810, 821) THEN
		CASE WHEN t.TransactionTypeID = 19 THEN calc.InvoicedShrinkQty WHEN calc.FromPOS = 0 THEN (DeliveryQty - PickupQty - POSQty) ELSE (POSQty) END
	ELSE
		CASE WHEN calc.FromPOS = 0 THEN (calc.TotalShrinkQty * - 1) + (DeliveryQty - PickupQty - POSQty) ELSE (calc.TotalShrinkQty * - 1) + (POSQty) END --ShrinkUnits
	END,
	CASE WHEN t.TransactionStatus IN (800, 810, 821) THEN
		CASE WHEN t.TransactionTypeID = 19 THEN calc.InvoicedShrinkQty WHEN calc.FromPOS = 0 THEN (DeliveryQty - PickupQty - POSQty) ELSE (POSQty) END * calc.RuleCost
	ELSE
		CASE WHEN calc.FromPOS = 0 THEN (calc.TotalShrinkQty * - 1) + (DeliveryQty - PickupQty - POSQty) ELSE (calc.TotalShrinkQty * - 1) + (POSQty) END * calc.RuleCost --[Shrink$],
	END,
	GETDATE(),
	63600 AS [LastUpdateUserID],
	CASE WHEN t.TransactionTypeID = 19 THEN 1
		 WHEN t.TransactionStatus = -800 THEN 3
		 WHEN t.TransactionStatus IN (0) THEN 2
		 WHEN t.TransactionStatus IN (800, 810, 821) THEN 1
	END	,
	t.STID,
	calc.POSQty,
	calc.DeliveryQty,
	calc.PickupQty,
	calc.TotalShrinkQty,
	CASE WHEN t.TransactionStatus IN (-800, 810, 821) THEN GETDATE()
		 ELSE NULL
	END	AS ApprovalDateTime,
	CASE WHEN t.TransactionStatus = -800 THEN 1
		 ELSE NULL
	END AS DeniedDCRSendStatus,
	CASE WHEN t.TransactionStatus = -800 THEN GETDATE()
		 ELSE NULL
	END AS DeniedDCRSendDateTime
	FROM @TempST AS t
	INNER JOIN DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_Calculate AS calc
	ON t.ChainID = calc.ChainID
	AND t.SupplierID = calc.SupplierID
	AND t.StoreID = calc.StoreID
	AND t.ProductID = calc.ProductID
	AND t.SaleDate = calc.SaleDate
	AND t.RuleCost = calc.RuleCost
	AND t.RuleRetail = calc.RuleRetail
	
	UPDATE calc
	SET calc.RecordStatus = 1
	FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_Calculate AS calc
	INNER JOIN @TempST AS t
	ON t.ChainID = calc.ChainID
	AND t.SupplierID = calc.SupplierID
	AND t.StoreID = calc.StoreID
	AND t.ProductID = calc.ProductID
	AND t.SaleDate = calc.SaleDate
	AND t.RuleCost = calc.RuleCost
	AND t.RuleRetail = calc.RuleRetail
	
	COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @ErrorMessage = ERROR_MESSAGE()
		DECLARE @emailSubject VARCHAR(MAX) = 'ERROR in Billing_Newspapers_Shrink_NewEDIData Job / [prBilling_Newspapers_Shrink_Create]'
		DECLARE @emailMessage VARCHAR(MAX) = @ErrorMessage
		DECLARE @emailRecipients VARCHAR(MAX) = 'william.heine@icucsolutions.com'
		EXEC dbo.prSendEmailNotification_PassEmailAddresses @emailSubject, @emailMessage, 'DataTrue System', 0, @emailRecipients
	END CATCH
END
GO
