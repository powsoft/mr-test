USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_Newspapers_Shrink_Calculate_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[prBilling_Newspapers_Shrink_Calculate_PRESYNC_20150415]
	-- Add the parameters for the stored procedure here
	@DaysBackToGo INT = 90,
	@DoNotDelete BIT = 0	
AS
BEGIN

	BEGIN TRY
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SET ARITHABORT ON;
	
	TRUNCATE TABLE DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck 
	
	--UPDATE RULECOST FOR CHANGES IN PRODUCT PRICES
	
	DECLARE @StepMessage VARCHAR(500)
	SET @StepMessage = 'STEP 1: ' + CONVERT(VARCHAR(100), GETDATE())
	RAISERROR(@StepMessage, 0, 1) WITH NOWAIT
	
	UPDATE st
	SET st.RuleCost = pp.UnitPrice, st.SetupCost = pp.UnitPrice
	FROM DataTrue_Main.dbo.StoreTransactions AS st
	INNER JOIN ProductPrices AS pp
	ON st.ChainID = pp.ChainID
	AND st.SupplierID = pp.SupplierID
	AND st.StoreID = pp.StoreID
	AND st.ProductID = pp.ProductID
	INNER JOIN JobProcesses AS p
	ON st.ProcessID = p.ProcessID
	AND p.JobRunningID = 10
	AND st.TransactionTypeID in (5,8)
	WHERE st.SaleDateTime BETWEEN pp.ActiveStartDate and pp.ActiveLastDate
	AND (st.RuleCost <> pp.UnitPrice OR st.SetupCost <> pp.UnitPrice)
	AND st.SaleDateTime >= GETDATE() - @DaysBackToGo
	
	UPDATE st
	SET st.RuleRetail = pp.UnitRetail, st.SetupRetail = pp.UnitRetail
	FROM DataTrue_Main.dbo.StoreTransactions AS st
	INNER JOIN ProductPrices AS pp
	ON st.ChainID = pp.ChainID
	AND st.SupplierID = pp.SupplierID
	AND st.StoreID = pp.StoreID
	AND st.ProductID = pp.ProductID
	INNER JOIN JobProcesses AS p
	ON st.ProcessID = p.ProcessID
	AND p.JobRunningID = 10
	AND st.TransactionTypeID in (5,8)
	WHERE st.SaleDateTime BETWEEN pp.ActiveStartDate and pp.ActiveLastDate
	AND (st.RuleRetail <> pp.UnitRetail OR st.SetupRetail <> pp.UnitRetail)
	AND st.SaleDateTime >= GETDATE() - @DaysBackToGo
	
	--GET PROCESSID
	DECLARE @ProcessID INT
	SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobName = 'NewspaperShrink'
	
	SET @StepMessage = 'STEP 2: ' + CONVERT(VARCHAR(100), GETDATE())
	RAISERROR(@StepMessage, 0, 1) WITH NOWAIT
	
	--INSERT EXISTING SHRINK/ADJ (TYPES 17/19)
	INSERT INTO DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck (TransactionStatus, ChainID, SupplierID, StoreID, ProductID, BrandID, SaleDate, Qty, RuleCost, RuleRetail, UPC)
	SELECT
	s.TransactionStatus, 
	--CASE s.TransactionStatus WHEN 821 THEN 810 WHEN 810 THEN 810 ELSE 0 END, 
	s.ChainID, 
	s.SupplierID, 
	s.StoreID, 
	s.ProductID, 
	s.BrandID, 
	s.SaleDateTime, 
	SUM(CASE WHEN s.TransactionTypeID = 19 THEN s.Qty * -1 ELSE s.Qty END) AS Qty, 
	s.RuleCost, 
	s.RuleRetail,
	MAX(LTRIM(RTRIM(ISNULL(s.UPC, '')))) AS UPC
	FROM DataTrue_Main.dbo.StoreTransactions AS s	
	INNER JOIN DataTrue_Main.dbo.JobProcesses AS jp
	ON s.ProcessID = jp.ProcessID
	AND jp.JobRunningID = 10
	WHERE s.TransactionTypeID IN (17, 19)
	AND s.SaleDateTime >= GETDATE() - @DaysBackToGo
	GROUP BY s.TransactionStatus,
	--CASE s.TransactionStatus WHEN 821 THEN 810 WHEN 810 THEN 810 ELSE 0 END, 
	s.ChainID, s.SupplierID, s.StoreID, s.ProductID, s.BrandID, s.SaleDateTime, s.RuleCost, s.RuleRetail
	
	SET @StepMessage = 'STEP 3: ' + CONVERT(VARCHAR(100), GETDATE())
	RAISERROR(@StepMessage, 0, 1) WITH NOWAIT
	
	--INSERT MISSING "FROM POS" - POS BUCKET TYPE TO GET CONTEXT NOT ALREADY EXISTING
	MERGE INTO DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck AS target
	USING
	(
		SELECT s.ChainID, s.SupplierID, s.StoreID, s.ProductID, s.BrandID, 
		s.SaleDateTime AS SaleDate, 
		SUM(CASE WHEN s.TransactionTypeID = 19 THEN s.Qty * -1 ELSE s.Qty END) AS Qty, 
		MAX(LTRIM(RTRIM(ISNULL(s.UPC, '')))) AS UPC,
		s.RuleCost AS OrigCost, 
		s.RuleRetail AS OrigRetail, 
		(s.RuleCost * (bc.Rate/100)) AS RuleCost,  
		(s.RuleRetail * (bc.Rate/100)) AS RuleRetail
		FROM DataTrue_Main.dbo.StoreTransactions AS s
		INNER JOIN DataTrue_Main.dbo.TransactionTypes AS tt
		ON s.TransactionTypeID = tt.TransactionTypeID
		AND tt.BucketType = 1
		INNER JOIN DataTrue_Main.dbo.BillingControl_Shrink AS bc
		ON 1 = 1
		AND s.ChainID = bc.ChainID
		AND s.SupplierID = bc.SupplierID
		AND bc.ShrinkControlType = 1		
		WHERE s.SaleDateTime >= GETDATE() - @DaysBackToGo
		AND s.SaleDateTime >= bc.StartDate
		GROUP BY
		s.ChainID,
		s.SupplierID,
		s.StoreID,
		s.ProductID,
		s.BrandID,
		s.SaleDateTime,
		s.RuleCost,
		s.RuleRetail,
		bc.Rate
	) AS source
	ON 
	(
	target.ChainID = source.ChainID
	AND target.SupplierID = source.SupplierID
	AND target.StoreID = source.StoreID
	AND target.ProductID = source.ProductID
	AND target.SaleDate = source.SaleDate
	AND CONVERT(MONEY, target.RuleCost) = CONVERT(MONEY, source.RuleCost)
	AND CONVERT(MONEY, target.RuleRetail) = CONVERT(MONEY, source.RuleRetail)
	)
	WHEN MATCHED THEN
	UPDATE 
	SET target.POSQty = source.Qty,
		target.POSCost = source.RuleCost,
		target.POSRetail = source.RuleRetail,
		target.DeliveryQty = 0,
		target.FromPOS = 1
	WHEN NOT MATCHED THEN
	INSERT
	(
	 [TransactionStatus]
	,[ChainID]
	,[SupplierID]
	,[StoreID]
	,[ProductID]
	,[BrandID]
	,[SaleDate]
	,[Qty]
	,[RuleCost]
	,[RuleRetail]
	,[UPC]
	,[DeliveryQty]
	,[POSQty]
	,[POSCost]
	,[POSRetail]
	,[FromPOS]
	)
	VALUES
	(
	 0--,[TransactionStatus]
	,source.ChainID--,[ChainID]
	,source.SupplierID--,[SupplierID]
	,source.StoreID--,[StoreID]
	,source.ProductID--,[ProductID]
	,source.BrandID--,[BrandID]
	,source.SaleDate--,[SaleDate]
	,0--,[Qty]
	,source.RuleCost--,[RuleCost]
	,source.RuleRetail--,[RuleRetail]
	,source.UPC--,[UPC]
	,0--,[DeliveryQty]
	,source.Qty--,[POSQty]
	,source.RuleCost--,[POSCost]
	,source.RuleRetail--,[POSRetail]
	,1--,[FromPOS]
	);
	
	SET @StepMessage = 'STEP 4: ' + CONVERT(VARCHAR(100), GETDATE())
	RAISERROR(@StepMessage, 0, 1) WITH NOWAIT
	
	UPDATE pos
	SET pos.FromPOS = 1
	FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck AS pos
	INNER JOIN DataTrue_Main.dbo.BillingControl_Shrink AS bc
	ON pos.ChainID = bc.ChainID
	AND pos.SupplierID = bc.SupplierID
	AND bc.ShrinkControlType IN (1, 2)
	
	UPDATE DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck
	SET FromPOS = 0 WHERE FromPOS IS NULL
	
	SET @StepMessage = 'STEP 5: ' + CONVERT(VARCHAR(100), GETDATE())
	RAISERROR(@StepMessage, 0, 1) WITH NOWAIT
	
	--GET TOTAL SHRINK FOR FROM POS
	UPDATE p
	SET p.Qty = s.Qty
	--select p.*
	FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck AS p
	INNER JOIN
	(
		SELECT s.ChainID, s.SupplierID, s.StoreID, s.ProductID, s.BrandID, 
		s.SaleDateTime AS SaleDate, SUM(CASE WHEN s.TransactionTypeID = 19 THEN s.Qty * -1 ELSE s.Qty END) AS Qty, MAX(LTRIM(RTRIM(ISNULL(s.UPC, '')))) AS UPC,
		s.RuleCost AS RuleCost, 
		s.RuleRetail AS RuleRetail
		FROM DataTrue_Main.dbo.StoreTransactions AS s
		INNER JOIN DataTrue_Main.dbo.BillingControl_Shrink AS bc
		ON 1 = 1
		AND s.ChainID = bc.ChainID
		AND s.SupplierID = bc.SupplierID
		AND bc.ShrinkControlType = 1
		AND s.SaleDateTime >= bc.StartDate
		WHERE s.SaleDateTime >= GETDATE() - @DaysBackToGo
		AND s.TransactionTypeID IN (17, 19)
		GROUP BY
		s.ChainID,
		s.SupplierID,
		s.StoreID,
		s.ProductID,
		s.BrandID,
		s.SaleDateTime,
		s.RuleCost,
		s.RuleRetail,
		bc.Rate
	) AS s
	ON p.ChainID = s.ChainID
	AND p.SupplierID = s.SupplierID
	AND p.StoreID = s.StoreID
	AND p.ProductID = s.ProductID
	AND p.SaleDate = s.SaleDate
	AND CONVERT(MONEY, p.RuleCost) = CONVERT(MONEY, s.RuleCost)
	AND CONVERT(MONEY, p.RuleRetail) = CONVERT(MONEY, s.RuleRetail)
	WHERE ISNULL(FromPOS, 0) = 1
	
	SET @StepMessage = 'STEP 6: ' + CONVERT(VARCHAR(100), GETDATE())
	RAISERROR(@StepMessage, 0, 1) WITH NOWAIT
	
	--GET DELIVERY INFO FOR NOT FROM POS RECORDS
	IF OBJECT_ID('DataTrue_EDI.dbo.tmpDeliveryPickupSTIDS', 'U') IS NOT NULL
	DROP TABLE DataTrue_EDI.dbo.tmpDeliveryPickupSTIDS
	
	SELECT StoreTransactionID
	INTO DataTrue_EDI.dbo.tmpDeliveryPickupSTIDS
	FROM
	(
	SELECT MAX(st2.DateTimeCreated) AS DateTimeCreated, st2.ChainID, st2.SupplierID, st2.StoreID, st2.ProductID, st2.SaleDateTime, st2.TransactionTypeID
	FROM DataTrue_Main.dbo.StoreTransactions AS st2-- WITH (INDEX (1))
	INNER JOIN DataTrue_Main.dbo.JobProcesses AS jp
	ON st2.ProcessID = jp.ProcessID
	AND jp.JobRunningID = 10
	WHERE st2.DateTimeCreated >= GETDATE() - @DaysBackToGo
	AND st2.TransactionTypeID IN (5, 8)
	GROUP BY st2.ChainID, st2.SupplierID, st2.StoreID, st2.ProductID, st2.SaleDateTime, st2.TransactionTypeID
	) AS st2
	INNER JOIN DataTrue_Main.dbo.StoreTransactions AS st-- WITH (INDEX (1))
	ON st.ChainID = st2.ChainID
	AND st.SupplierID = st2.SupplierID
	AND st.StoreID = st2.StoreID
	AND st.ProductID = st2.ProductID
	AND st.SaleDateTime = st2.SaleDateTime
	AND st.TransactionTypeID = st2.TransactionTypeID
	AND st.DateTimeCreated = st2.DateTimeCreated
	INNER JOIN DataTrue_Main.dbo.JobProcesses AS jp
	ON st.ProcessID = jp.ProcessID
	AND jp.JobRunningID = 10
	OPTION (FORCE ORDER, HASH GROUP)
	
	SET @StepMessage = 'STEP 7: ' + CONVERT(VARCHAR(100), GETDATE())
	RAISERROR(@StepMessage, 0, 1) WITH NOWAIT
	
	--UPDATE DELIVERY QTY WHERE CONTEXT EXISTS AND INSERT MISSING DELIVERY CONTEXT "NOT FROM POS"
	MERGE INTO DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck AS target
	USING
	(
		SELECT ChainID, SupplierID, StoreID, ProductID, SaleDateTime, SUM(CASE WHEN TransactionTypeID = 5 THEN Qty ELSE (Qty * -1) END) AS Qty, MAX(UPC) AS UPC,
		CASE WHEN (ProductPriceTypeID IS NULL AND SetupCost IS NULL AND RuleCost IS NULL) THEN 0 ELSE RuleCost END AS RuleCost, 
		CASE WHEN (ProductPriceTypeID IS NULL AND SetupCost IS NULL AND RuleCost IS NULL) THEN 0 ELSE RuleRetail END AS RuleRetail
		FROM DataTrue_Main.dbo.StoreTransactions 
		WHERE TransactionTypeID IN (5, 8)
		AND StoreTransactionID IN (SELECT StoreTransactionID FROM DataTrue_EDI.dbo.tmpDeliveryPickupSTIDS)
		GROUP BY ChainID, SupplierID, StoreID, ProductID, SaleDateTime, ProductPriceTypeID, RuleCost, SetupCost, RuleRetail
		HAVING SUM(CASE WHEN TransactionTypeID = 5 THEN Qty ELSE (Qty * -1) END) <> 0
	) AS source
	ON 
	(
	target.ChainID = source.ChainID
	AND target.SupplierID = source.SupplierID
	AND target.StoreID = source.StoreID
	AND target.ProductID = source.ProductID
	AND target.SaleDate = source.SaleDateTime
	AND CONVERT(MONEY, target.RuleCost) = CONVERT(MONEY, source.RuleCost)
	AND CONVERT(MONEY, target.RuleRetail) = CONVERT(MONEY, source.RuleRetail)
	)
	WHEN MATCHED THEN
	UPDATE 
	SET target.DeliveryQty = source.Qty
	WHEN NOT MATCHED THEN
	INSERT
	(
	 [TransactionStatus]
	,[ChainID]
	,[SupplierID]
	,[StoreID]
	,[ProductID]
	,[BrandID]
	,[SaleDate]
	,[Qty]
	,[RuleCost]
	,[RuleRetail]
	,[UPC]
	,[DeliveryQty]
	,[POSQty]
	,[POSCost]
	,[POSRetail]
	,[FromPOS]
	)
	VALUES
	(
	 0--,[TransactionStatus]
	,source.ChainID--,[ChainID]
	,source.SupplierID--,[SupplierID]
	,source.StoreID--,[StoreID]
	,source.ProductID--,[ProductID]
	,0--,[BrandID]
	,source.SaleDateTime--,[SaleDate]
	,0--,[Qty]
	,source.RuleCost--,[RuleCost]
	,source.RuleRetail--,[RuleRetail]
	,source.UPC--,[UPC]
	,source.Qty--,[DeliveryQty]
	,0--,[POSQty]
	,source.RuleCost--,[POSCost]
	,source.RuleRetail--,[POSRetail]
	,0--,[FromPOS]
	);
	
	SET @StepMessage = 'STEP 8: ' + CONVERT(VARCHAR(100), GETDATE())
	RAISERROR(@StepMessage, 0, 1) WITH NOWAIT

	--UPDATE POS NOT FROM POS
	UPDATE p
	SET p.POSQty = s.Qty, p.POSCost = s.RuleCost, p.POSRetail = s.RuleRetail
	FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck AS p
	INNER JOIN
	(
		SELECT ChainID, SupplierID, StoreID, ProductID, SaleDateTime, SUM(Qty) AS Qty, 
		CASE WHEN (ProductPriceTypeID IS NULL AND SetupCost IS NULL AND RuleCost IS NULL) THEN 0 ELSE RuleCost END AS RuleCost, 
		CASE WHEN (ProductPriceTypeID IS NULL AND SetupCost IS NULL AND RuleCost IS NULL) THEN 0 ELSE RuleRetail END AS RuleRetail
		FROM DataTrue_Main.dbo.StoreTransactions 
		WHERE TransactionTypeID IN (2, 6, 7, 16)
		AND ISNULL(InvoiceBatchID, 0) <> 0
		AND SaleDateTime >= GETDATE() - @DaysBackToGo
		GROUP BY ChainID, SupplierID, StoreID, ProductID, SaleDateTime, RuleCost, RuleRetail, ProductPriceTypeID, SetupCost
	) AS s
	ON p.ChainID = s.ChainID
	AND p.SupplierID = s.SupplierID
	AND p.StoreID = s.StoreID
	AND p.ProductID = s.ProductID
	AND p.SaleDate = s.SaleDateTime
	AND CONVERT(MONEY, p.RuleCost) = CONVERT(MONEY, s.RuleCost)
	AND CONVERT(MONEY, p.RuleRetail) = CONVERT(MONEY, s.RuleRetail)
	WHERE FromPOS = 0
	
	SET @StepMessage = 'STEP 9: ' + CONVERT(VARCHAR(100), GETDATE())
	RAISERROR(@StepMessage, 0, 1) WITH NOWAIT
	
	--UPDATE POS FOR FROM POS
	UPDATE p
	SET p.POSQty = s.Qty, p.POSCost = s.RuleCost, p.POSRetail = s.RuleRetail
	FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck AS p-- with (index (17))
	INNER JOIN DataTrue_Main.dbo.BillingControl_Shrink AS bc
	ON 1 = 1
	AND p.ChainID = bc.ChainID
	AND p.SupplierID = bc.SupplierID
	AND bc.ShrinkControlType = 1
	AND p.SaleDate >= bc.StartDate
	INNER JOIN
	(
		SELECT s.ChainID, s.SupplierID, StoreID, ProductID, SaleDateTime, SUM(Qty) AS Qty,
		CASE WHEN (ProductPriceTypeID IS NULL AND SetupCost IS NULL AND RuleCost IS NULL) THEN 0 ELSE (RuleCost * bc.Rate / 100) END AS RuleCost, 
		CASE WHEN (ProductPriceTypeID IS NULL AND SetupCost IS NULL AND RuleCost IS NULL) THEN 0 ELSE (RuleRetail * Rate / 100)  END AS RuleRetail
		FROM DataTrue_Main.dbo.StoreTransactions AS s
		INNER JOIN DataTrue_Main.dbo.BillingControl_Shrink AS bc
		ON 1 = 1
		AND s.ChainID = bc.ChainID
		AND s.SupplierID = bc.SupplierID
		AND bc.ShrinkControlType = 1
		AND s.SaleDateTime >= bc.StartDate
		WHERE TransactionTypeID IN (2, 6, 7, 16)
		AND ISNULL(InvoiceBatchID, 0) <> 0
		AND s.SaleDateTime >= GETDATE() - @DaysBackToGo
		GROUP BY s.ChainID, s.SupplierID, StoreID, ProductID, SaleDateTime, RuleCost, RuleRetail, ProductPriceTypeID, SetupCost, Rate
	) AS s
	ON p.ChainID = s.ChainID
	AND p.SupplierID = s.SupplierID
	AND p.StoreID = s.StoreID
	AND p.ProductID = s.ProductID
	AND p.SaleDate = s.SaleDateTime
	AND CONVERT(MONEY, p.RuleCost) = CONVERT(MONEY, s.RuleCost)
	AND CONVERT(MONEY, p.RuleRetail) = CONVERT(MONEY, s.RuleRetail)
	WHERE FromPOS = 1
	
	SET @StepMessage = 'STEP 10: ' + CONVERT(VARCHAR(100), GETDATE())
	RAISERROR(@StepMessage, 0, 1) WITH NOWAIT
	
	UPDATE DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck 
	SET POSQty = CASE WHEN POSQty IS NULL THEN 0 ELSE POSQty END,
	    DeliveryQty = CASE WHEN DeliveryQty IS NULL THEN 0 ELSE DeliveryQty END,
	    POSCost = CASE WHEN POSCost IS NULL THEN 0.00 ELSE POSCost END,
	    POSRetail = CASE WHEN POSRetail IS NULL THEN 0.00 ELSE POSRetail END
	WHERE FromPOS = 0
	
	UPDATE DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck 
	SET DeliveryQty = 0
	WHERE FromPOS = 1
	
	SET @StepMessage = 'STEP 11: ' + CONVERT(VARCHAR(100), GETDATE())
	RAISERROR(@StepMessage, 0, 1) WITH NOWAIT
			
	DELETE FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck
	WHERE ChainID NOT IN (SELECT DISTINCT ChainID 
						  FROM StoreTransactions AS s
					      INNER JOIN JobProcesses AS p
					      ON s.ProcessID = p.ProcessID
					      AND p.JobRunningID = 10
					      WHERE TransactionTypeID IN (5, 8, 17))

	IF @DoNotDelete = 0
		BEGIN
			--DELETES
			DELETE FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck
			WHERE Qty = 0 AND DeliveryQty = 0 AND POSQty = 0 	
			
			DELETE FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck
			WHERE TransactionStatus = 821	
			
			DELETE FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck
			WHERE SaleDate < '7/1/2014'
			AND ChainID = 60624
		
			DELETE FROM i
			FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck AS i
			INNER JOIN DataTrue_Main.dbo.BillingControl_Shrink AS bc
			ON 1 = 1
			AND i.ChainID = bc.ChainID
			AND i.SupplierID = bc.SupplierID
			AND bc.ShrinkControlType = 1	
			AND ISNULL(FromPOS, 0) = 1	
			WHERE i.SaleDate > (SELECT DATEADD(dd, 7 - (DATEPART(dw, GETDATE())), GETDATE()) - 6)
	
			DELETE FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck
			WHERE ((DeliveryQty - POSQty) = Qty) AND ISNULL(FromPOS, 0) = 0
			
			DELETE FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck
			WHERE (POSQty = Qty) AND ISNULL(FromPOS, 0) = 1

		END
		
	SET @StepMessage = 'STEP 12: ' + CONVERT(VARCHAR(100), GETDATE())
	RAISERROR(@StepMessage, 0, 1) WITH NOWAIT
	
	--BILLING EXCLULSIONS
	--POS Only - Specific supplier/store for one product
	DELETE f
	FROM [DataTrue_Main].[dbo].InventoryReport_Newspaper_Shrink_POSCheck AS f
	INNER JOIN [DataTrue_Main].[dbo].[BillingExclusions] AS b
	ON b.ChainID = f.ChainID
	AND b.ProductID = f.ProductID
	AND b.StoreID = f.StoreID
	AND b.Supplierid = f.Supplierid
	WHERE b.InvoiceDetailTypeID = 3
	
	--POS Only - All stores/suppliers for one product
	DELETE f
	FROM [DataTrue_Main].[dbo].InventoryReport_Newspaper_Shrink_POSCheck AS f
	INNER JOIN [DataTrue_Main].[dbo].[BillingExclusions] AS b
	ON b.ChainID = f.ChainID
	AND b.ProductID = f.ProductID
	AND b.StoreID = 0
	AND b.Supplierid = 0
	WHERE b.InvoiceDetailTypeID = 3
	
	--POS Only - All stores/products for one supplier
	DELETE f
	FROM [DataTrue_Main].[dbo].InventoryReport_Newspaper_Shrink_POSCheck AS f
	INNER JOIN [DataTrue_Main].[dbo].[BillingExclusions] AS b
	ON b.ChainID = f.ChainID
	AND b.ProductID = 0
	AND b.StoreID = 0
	AND b.Supplierid = f.Supplierid
	WHERE b.InvoiceDetailTypeID = 3
	
	END TRY
	
	BEGIN CATCH
		ROLLBACK TRANSACTION
		DECLARE @ErrorMessage VARCHAR(MAX)
		SET @ErrorMessage = ERROR_MESSAGE()
		DECLARE @emailSubject VARCHAR(MAX) = 'ERROR in Billing_Newspapers_Shrink_NewEDIData Job / [prBilling_Newspapers_Shrink_Calculate]'
		DECLARE @emailMessage VARCHAR(MAX) = @ErrorMessage
		DECLARE @emailRecipients VARCHAR(MAX) = 'william.heine@icucsolutions.com'
		EXEC dbo.prSendEmailNotification_PassEmailAddresses @emailSubject, @emailMessage, 'DataTrue System', 0, @emailRecipients
	END CATCH
END
GO
