USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_Newspapers_Shrink_Calculate]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[prBilling_Newspapers_Shrink_Calculate]
	-- Add the parameters for the stored procedure here
	@DaysBackToGoTotal INT = 365,
	@DaysBackToGoRecalc INT = 90,
	@DoNotDelete BIT = 0	
AS
BEGIN

	BEGIN TRY
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SET ARITHABORT ON;
	
	TRUNCATE TABLE DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck 
	TRUNCATE TABLE DataTrue_Main.dbo.[InventoryReport_Newspaper_Shrink_Calculate]
	
--================================
--UPDATE FROM PRODUCT PRICES CALCS
--================================
	
	DECLARE @StepMessage VARCHAR(500)
	SET @StepMessage = 'STEP 1 - UPDATE RULECOST FOR CHANGES IN PRODUCT PRICES: ' + CONVERT(VARCHAR(100), GETDATE())
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
	AND st.SaleDateTime >= GETDATE() - @DaysBackToGoTotal
	
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
	AND st.SaleDateTime >= GETDATE() - @DaysBackToGoTotal
	
	--GET PROCESSID
	DECLARE @ProcessID INT
	SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobName = 'NewspaperShrink'
	
	SET @StepMessage = 'STEP 2 - CHECK FOR BLANK UPCS: ' + CONVERT(VARCHAR(100), GETDATE())
	RAISERROR(@StepMessage, 0, 1) WITH NOWAIT
	
	DECLARE @BlankUPCs INT = 0
		
	SELECT @BlankUPCs = (SELECT COUNT(StoreTransactionID)
						 FROM DataTrue_Main.dbo.StoreTransactions AS st
						 WHERE 1 = 1
						 AND ProcessID = @ProcessID
						 AND ISNULL(UPC, '') = '')


--============================
--     BLANK UPC CALCS
--============================
						 				 
	IF @BlankUPCs > 0
		BEGIN
			-- Atempt update from POS join
			UPDATE t
			SET t.UPC = st.UPC
			FROM DataTrue_Main.dbo.StoreTransactions AS t with (index(98,61))
			INNER JOIN DataTrue_Main.dbo.StoreTransactions AS st 
			ON t.ProcessID = @ProcessID
			AND t.ChainID = st.ChainID
			AND t.SupplierID = st.SupplierID
			AND t.StoreID = st.StoreID
			AND t.ProductID = st.ProductID
			AND t.SaleDateTime = st.SaleDateTime
			AND st.TransactionTypeID IN (2, 6)
			WHERE LEN(ISNULL(t.UPC, '')) < 1
			AND LEN(st.UPC) = 12
			option (hash group, hash join)
			--1
			
			SET @BlankUPCs -= @@ROWCOUNT
			IF @BlankUPCs = 0
				BEGIN
					GOTO NoBlankUPCs
				END
			
			--Attempt update from POS join without saledate
			UPDATE t
			SET t.UPC = st.UPC
			FROM DataTrue_Main.dbo.StoreTransactions AS t with (index(98,61))
			INNER JOIN DataTrue_Main.dbo.StoreTransactions AS st 
			ON t.ProcessID = @ProcessID
			AND t.ChainID = st.ChainID
			AND t.SupplierID = st.SupplierID
			AND t.StoreID = st.StoreID
			AND t.ProductID = st.ProductID
			AND st.TransactionTypeID IN (2, 6)
			WHERE LEN(ISNULL(t.UPC, '')) < 1
			AND LEN(st.UPC) = 12
			option (hash group, hash join)
			--2
				
			SET @BlankUPCs -= @@ROWCOUNT
			IF @BlankUPCs = 0
				BEGIN
					GOTO NoBlankUPCs
				END
				
			--Attempt update from POS join without chain/store
			UPDATE t
			SET t.UPC = st.UPC
			FROM DataTrue_Main.dbo.StoreTransactions AS t with (index(98,61))
			INNER JOIN DataTrue_Main.dbo.StoreTransactions AS st 
			ON t.ProcessID = @ProcessID
			AND t.SupplierID = st.SupplierID
			AND t.ProductID = st.ProductID
			AND t.SaleDateTime = st.SaleDateTime
			AND st.TransactionTypeID IN (2, 6)
			WHERE LEN(ISNULL(t.UPC, '')) < 1
			AND LEN(st.UPC) = 12
			option (hash group, hash join)
			--3
				
				
			SET @BlankUPCs -= @@ROWCOUNT
			IF @BlankUPCs = 0
				BEGIN
					GOTO NoBlankUPCs
				END
				
			-- Atempt update from POS join without chain/store or saledate
			UPDATE t
			SET t.UPC = st.UPC
			FROM DataTrue_Main.dbo.StoreTransactions AS t with (index(98,61))
			INNER JOIN DataTrue_Main.dbo.StoreTransactions AS st 
			ON t.ProcessID = @ProcessID
			AND t.SupplierID = st.SupplierID
			AND t.ProductID = st.ProductID
			AND st.TransactionTypeID IN (2, 6)
			WHERE LEN(ISNULL(t.UPC, '')) < 1
			AND LEN(st.UPC) = 12
			option (hash group, hash join)
			--4
				
				
			SET @BlankUPCs -= @@ROWCOUNT
			IF @BlankUPCs = 0
				BEGIN
					GOTO NoBlankUPCs
				END
				
			-- Atempt update from POS join without supplier/saledate
			UPDATE t
			SET t.UPC = st.UPC
			FROM DataTrue_Main.dbo.StoreTransactions AS t with (index(98,61))
			INNER JOIN DataTrue_Main.dbo.StoreTransactions AS st 
			ON t.ProcessID = @ProcessID
			AND t.ChainID = st.ChainID
			AND t.StoreID = st.StoreID
			AND t.ProductID = st.ProductID
			AND st.TransactionTypeID IN (2, 6)
			WHERE LEN(ISNULL(t.UPC, '')) < 1
			AND LEN(st.UPC) = 12
			option (hash group, hash join)
			--5
				
			SET @BlankUPCs -= @@ROWCOUNT
			IF @BlankUPCs = 0
				BEGIN
					GOTO NoBlankUPCs
				END
				
			-- Final update by last created UPC in ProductIdentifiers
			UPDATE t
			SET t.UPC = p.IdentifierValue
			FROM DataTrue_Main.dbo.StoreTransactions AS t with (index(98,61))
			INNER JOIN DataTrue_Main.dbo.ProductIdentifiers AS p
			ON ProcessID = @ProcessID 
			AND t.ProductID = p.ProductID
			AND p.IdentifierValue = 
			(
				SELECT  TOP 1 LTRIM(RTRIM(IdentifierValue)) AS IdentifierValue
				FROM    DataTrue_Main..ProductIdentifiers
				WHERE   ProductID = p.ProductID
				AND		ProductIdentifierTypeID = 8
				AND		LEN(LTRIM(RTRIM(IdentifierValue))) = 12
				ORDER	BY DateTimeCreated DESC
			)
			WHERE LEN(ISNULL(t.UPC, '')) < 1
			
			SET @BlankUPCs -= @@ROWCOUNT
				
			IF @BlankUPCs > 0
				BEGIN
					RAISERROR ('Unmable to match all UPCs in prBilling_Newspapers_Shrink_Create_New.' , 16 , 1)
				END	
				
		END
		
NoBlankUPCs:

--============================
--   EXISTING SHRINK CALCS
--============================
	
	SET @StepMessage = 'STEP 3 - GET EXISTING SHRINK IN SYSTEM: ' + CONVERT(VARCHAR(100), GETDATE())
	RAISERROR(@StepMessage, 0, 1) WITH NOWAIT
	
	--INSERT EXISTING SHRINK/ADJ (TYPES 17/19)
	INSERT INTO DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck (TransactionStatus, ChainID, SupplierID, StoreID, ProductID, SaleDate, Qty, RuleCost, RuleRetail, UPC)
	SELECT
	s.TransactionStatus, 
	--CASE s.TransactionStatus WHEN 821 THEN 810 WHEN 810 THEN 810 ELSE 0 END, 
	s.ChainID, 
	s.SupplierID, 
	s.StoreID, 
	s.ProductID, 
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
	AND s.SaleDateTime >= GETDATE() - @DaysBackToGoTotal
	GROUP BY s.TransactionStatus,
	--CASE s.TransactionStatus WHEN 821 THEN 810 WHEN 810 THEN 810 ELSE 0 END, 
	s.ChainID, s.SupplierID, s.StoreID, s.ProductID, s.SaleDateTime, s.RuleCost, s.RuleRetail

	SET @StepMessage = 'STEP 4 - PIVOT SHRINK TO CALC TABLE: ' + CONVERT(VARCHAR(100), GETDATE())
	RAISERROR(@StepMessage, 0, 1) WITH NOWAIT
	
	INSERT INTO [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Calculate]
	(
	 [ChainID]
	,[SupplierID]
	,[StoreID]
	,[ProductID]
	,[BrandID]
	,[SaleDate]
	,[RejectedShrinkQty]
	,[InSettlementShrinkQty]
	,[ApprovedShrinkQty]
	,[InvoicedShrinkQty]
	,[OutsidePaymentShrinkQty]
	,[RuleCost]
	,[RuleRetail]
	,[UPC]
	,[FromPOS]
	,[RecordStatus]
	,[NewShrink]
	)
	SELECT
	 ChainID AS [ChainID]
	,SupplierID AS [SupplierID]
	,StoreID AS [StoreID]
	,ProductID AS [ProductID]
	,0 AS [BrandID]
	,SaleDate AS [SaleDate]
	,ISNULL(SUM(CASE WHEN TransactionStatus = -800 THEN Qty END), 0) AS [RejectedShrinkQty]
	,ISNULL(SUM(CASE WHEN TransactionStatus = 0 THEN Qty END), 0) AS [InSettlementShrinkQty]
	,ISNULL(SUM(CASE WHEN TransactionStatus = 800 THEN Qty END), 0) AS [ApprovedShrinkQty]
	,ISNULL(SUM(CASE WHEN TransactionStatus = 810 THEN Qty END), 0) AS [InvoicedShrinkQty]
	,ISNULL(SUM(CASE WHEN TransactionStatus = 821 THEN Qty END), 0) AS [OutsidePaymentShrinkQty]
	,RuleCost AS [RuleCost]
	,RuleRetail AS [RuleRetail]
	,UPC AS [UPC]
	,FromPOS AS [FromPOS]
	,0 AS [RecordStatus]
	,0 AS [NewShrink]
	FROM InventoryReport_Newspaper_Shrink_POSCheck
	GROUP BY
	 [ChainID]
	,[SupplierID]
	,[StoreID]
	,[ProductID]
	,[BrandID]
	,[SaleDate]
	,[RuleCost]
	,[RuleRetail]
	,[UPC]
	,[FromPOS]
	
	UPDATE pos
	SET pos.FromPOS = 1, pos.DeliveryQty = 0, pos.PickupQty = 0 , pos.POSQty = 0
	FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_Calculate AS pos
	INNER JOIN DataTrue_Main.dbo.BillingControl_Shrink AS bc
	ON pos.ChainID = bc.ChainID
	AND pos.SupplierID = bc.SupplierID
	AND bc.ShrinkControlType IN (1, 2)
	
	UPDATE pos
	SET pos.FromPOS = 0, pos.DeliveryQty = 0, pos.PickupQty = 0, pos.POSQty = 0
	FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_Calculate AS pos
	WHERE ISNULL(FromPOS, 0) = 0
	
--============================
--    NOT FROM POS CALCS
--============================

	SET @StepMessage = 'STEP 5 - GET CURRENT DELIVERY STIDS: ' + CONVERT(VARCHAR(100), GETDATE())
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
	WHERE st2.SaleDateTime >= GETDATE() - @DaysBackToGoTotal
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
	
	SET @StepMessage = 'STEP 6 - MERGE DELIVERY DATA: ' + CONVERT(VARCHAR(100), GETDATE())
	RAISERROR(@StepMessage, 0, 1) WITH NOWAIT
	
	--UPDATE DELIVERY QTY WHERE CONTEXT EXISTS AND INSERT MISSING DELIVERY CONTEXT "NOT FROM POS"
	MERGE INTO DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_Calculate AS target
	USING
	(
		SELECT ChainID, SupplierID, StoreID, ProductID, SaleDateTime, 
		ISNULL(SUM(CASE WHEN TransactionTypeID = 5 THEN Qty END), 0) AS DeliveryQty, 
		ISNULL(SUM(CASE WHEN TransactionTypeID = 8 THEN (Qty) END), 0) AS PickupQty, 
		MAX(UPC) AS UPC,
		ISNULL(CASE WHEN (ProductPriceTypeID IS NULL AND MAX(SetupCost) IS NULL AND RuleCost IS NULL) THEN 0 ELSE RuleCost END, 0) AS RuleCost, 
		ISNULL(CASE WHEN (ProductPriceTypeID IS NULL AND MAX(SetupCost) IS NULL AND RuleCost IS NULL) THEN 0 ELSE RuleRetail END, 0) AS RuleRetail
		FROM DataTrue_Main.dbo.StoreTransactions 
		WHERE TransactionTypeID IN (5, 8)
		AND StoreTransactionID IN (SELECT StoreTransactionID FROM DataTrue_EDI.dbo.tmpDeliveryPickupSTIDS)
		GROUP BY ChainID, SupplierID, StoreID, ProductID, SaleDateTime, ProductPriceTypeID, RuleCost, RuleRetail
		--HAVING SUM(CASE WHEN TransactionTypeID = 5 THEN Qty ELSE (Qty * -1) END) <> 0
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
	SET target.DeliveryQty = source.DeliveryQty,
	    target.PickupQty = source.PickupQty
	WHEN NOT MATCHED THEN
	INSERT
	(
	 [ChainID]
	,[SupplierID]
	,[StoreID]
	,[ProductID]
	,[BrandID]
	,[SaleDate]
	,[RejectedShrinkQty]
	,[InSettlementShrinkQty]
	,[ApprovedShrinkQty]
	,[InvoicedShrinkQty]
	,[RuleCost]
	,[RuleRetail]
	,[UPC]
	,[DeliveryQty]
	,[PickupQty]
	,[POSQty]
	,[FromPOS]
	,[RecordStatus]
	,[NewShrink]
	)
	VALUES
	(
	 source.ChainID --AS [ChainID]
	,source.SupplierID --AS [SupplierID]
	,source.StoreID --AS [StoreID]
	,source.ProductID --AS [ProductID]
	,0 --AS [BrandID]
	,source.SaleDateTime --AS [SaleDate]
	,0 --AS [RejectedShrinkQty]
	,0 --AS [InSettlementShrinkQty]
	,0 --AS [ApprovedShrinkQty]
	,0 --AS [InvoicedShrinkQty]
	,source.RuleCost --AS [RuleCost]
	,source.RuleRetail --AS [RuleRetail]
	,source.UPC --AS [UPC]
	,source.DeliveryQty --AS [DeliveryQty]
	,source.PickupQty --AS [PickupQty]
	,0 --AS [POSQty]
	,0 --AS [FromPOS]
	,0 --AS [RecordStatus]	
	,1 --AS [NewShrink]
	);
	
	SET @StepMessage = 'STEP 7 - GET POS QTY NOT FROM POS: ' + CONVERT(VARCHAR(100), GETDATE())
	RAISERROR(@StepMessage, 0, 1) WITH NOWAIT

	--UPDATE POS NOT FROM POS
	UPDATE p
	SET p.POSQty = s.Qty
	FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_Calculate AS p
	INNER JOIN
	(
		SELECT ChainID, SupplierID, StoreID, ProductID, SaleDateTime, SUM(Qty) AS Qty, 
		CASE WHEN (ProductPriceTypeID IS NULL AND MAX(SetupCost) IS NULL AND RuleCost IS NULL) THEN 0 ELSE RuleCost END AS RuleCost, 
		CASE WHEN (ProductPriceTypeID IS NULL AND MAX(SetupCost) IS NULL AND RuleCost IS NULL) THEN 0 ELSE RuleRetail END AS RuleRetail
		FROM DataTrue_Main.dbo.StoreTransactions 
		WHERE TransactionTypeID IN (2, 6, 7, 16)
		AND ISNULL(InvoiceBatchID, 0) <> 0
		AND SaleDateTime >= GETDATE() - @DaysBackToGoTotal
		GROUP BY ChainID, SupplierID, StoreID, ProductID, SaleDateTime, RuleCost, RuleRetail, ProductPriceTypeID
	) AS s
	ON p.ChainID = s.ChainID
	AND p.SupplierID = s.SupplierID
	AND p.StoreID = s.StoreID
	AND p.ProductID = s.ProductID
	AND p.SaleDate = s.SaleDateTime
	AND CONVERT(MONEY, p.RuleCost) = CONVERT(MONEY, s.RuleCost)
	AND CONVERT(MONEY, p.RuleRetail) = CONVERT(MONEY, s.RuleRetail)
	WHERE FromPOS = 0

	IF @DoNotDelete = 0
		BEGIN
		    --CF HARD CODING
			DELETE FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_Calculate
			WHERE SaleDate < '7/1/2014'
			AND ChainID = 60624
			
			--CF HARD CODING
			DELETE FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_Calculate
			WHERE SaleDate < '11/1/2014'
			AND ChainID = 60624
			AND SupplierID <> 26582
			
			--DELETE WHERE SHRINK IS CORRECT
			DELETE 
			FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_Calculate
			WHERE ((DeliveryQty - PickupQty - POSQty) = (OutsidePaymentShrinkQty)) 
			AND ISNULL(FromPOS, 0) = 0

			
			DELETE 
			FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_Calculate
			WHERE ((DeliveryQty - PickupQty - POSQty) = (InvoicedShrinkQty + ApprovedShrinkQty)) 
			AND ISNULL(FromPOS, 0) = 0
			
			DELETE 
			FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_Calculate
			WHERE ((DeliveryQty - PickupQty - POSQty) = (InSettlementShrinkQty)) 
			AND ISNULL(FromPOS, 0) = 0
			
			DELETE 
			FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_Calculate
			WHERE ((DeliveryQty - PickupQty - POSQty) = (RejectedShrinkQty)) 
			AND ISNULL(FromPOS, 0) = 0
						
			DELETE 
			FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_Calculate
			WHERE OutsidePaymentShrinkQty <> 0
			AND InvoicedShrinkQty = 0
			AND ApprovedShrinkQty = 0
			AND InSettlementShrinkQty = 0
			AND RejectedShrinkQty = 0
		END
	
	
--============================
--      FROM POS CALCS
--============================

	SET @StepMessage = 'STEP 8 - MERGE FROM POS DATA: ' + CONVERT(VARCHAR(100), GETDATE())
	RAISERROR(@StepMessage, 0, 1) WITH NOWAIT
	
	--INSERT FROM POS RELATIONSHIP DATA
	MERGE INTO DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_Calculate AS target
	USING
	(
		SELECT s.ChainID, s.SupplierID, s.StoreID, s.ProductID,
		s.SaleDateTime AS SaleDate, 
		SUM(s.Qty) AS Qty, 
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
		WHERE s.SaleDateTime >= GETDATE() - @DaysBackToGoTotal
		AND s.SaleDateTime >= bc.StartDate
		GROUP BY
		s.ChainID,
		s.SupplierID,
		s.StoreID,
		s.ProductID,
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
	SET target.POSQty = source.Qty
	WHEN NOT MATCHED THEN
	INSERT
	(
	 [ChainID]
	,[SupplierID]
	,[StoreID]
	,[ProductID]
	,[BrandID]
	,[SaleDate]
	,[RejectedShrinkQty]
	,[InSettlementShrinkQty]
	,[ApprovedShrinkQty]
	,[InvoicedShrinkQty]
	,[RuleCost]
	,[RuleRetail]
	,[UPC]
	,[DeliveryQty]
	,[PickupQty]
	,[POSQty]
	,[FromPOS]
	,[RecordStatus]
	,[NewShrink]
	)
	VALUES
	(
	 source.ChainID --AS [ChainID]
	,source.SupplierID --AS [SupplierID]
	,source.StoreID --AS [StoreID]
	,source.ProductID --AS [ProductID]
	,0 --AS [BrandID]
	,source.SaleDate --AS [SaleDate]
	,0 --AS [RejectedShrinkQty]
	,0 --AS [InSettlementShrinkQty]
	,0 --AS [ApprovedShrinkQty]
	,0 --AS [InvoicedShrinkQty]
	,source.RuleCost --AS [RuleCost]
	,source.RuleRetail --AS [RuleRetail]
	,source.UPC --AS [UPC]
	,0 --AS [DeliveryQty]
	,0--AS [PickupQty]
	,source.Qty --AS [POSQty]
	,1 --AS [FromPOS]
	,0 --AS [RecordStatus]	
	,1 --AS [NewShrink]
	);
	
	UPDATE DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_Calculate
	Set TotalShrinkQty = RejectedShrinkQty + InSettlementShrinkQty + ApprovedShrinkQty + InvoicedShrinkQty + OutsidePaymentShrinkQty
	
	IF @DoNotDelete = 0
		BEGIN
			
			--DELETE WHERE SHRINK IS CORRECT
			DELETE 
			FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_Calculate
			WHERE ((POSQty) = (InvoicedShrinkQty + ApprovedShrinkQty)) 
			AND ISNULL(FromPOS, 0) = 1
			
			DELETE 
			FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_Calculate
			WHERE ((TotalShrinkQty) = (DeliveryQty - PickupQty - POSQty)) 
			AND ISNULL(FromPOS, 0) = 0
			
			--DELETE FROMPOS NOT 1 WEEK OLD
			DELETE i
			FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_Calculate AS i
			INNER JOIN DataTrue_Main.dbo.BillingControl_Shrink AS bc
			ON 1 = 1
			AND i.ChainID = bc.ChainID
			AND i.SupplierID = bc.SupplierID
			AND bc.ShrinkControlType = 1	
			AND ISNULL(FromPOS, 0) = 1	
			WHERE i.SaleDate > (SELECT DATEADD(dd, - (DATEPART(dw, GETDATE())), GETDATE()) - 6)
			
			--DELETE RECALC < @DaysBackToGoRecalc, leave records that are all IN SETTLEMENT or new shrink
			DELETE i
			--select i.*
			FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_Calculate AS i
			WHERE i.SaleDate < GETDATE() - @DaysBackToGoRecalc
			AND (i.NewShrink = 0 AND i.InSettlementShrinkQty <> i.TotalShrinkQty AND FromPOS = 0)
			
		END
		
	SET @StepMessage = 'STEP 9 - BILLING EXCLUSIONS: ' + CONVERT(VARCHAR(100), GETDATE())
	RAISERROR(@StepMessage, 0, 1) WITH NOWAIT
	
	--BILLING EXCLULSIONS
	--POS Only - Specific supplier/store for one product
	DELETE f
	FROM [DataTrue_Main].[dbo].InventoryReport_Newspaper_Shrink_Calculate AS f
	INNER JOIN [DataTrue_Main].[dbo].[BillingExclusions] AS b
	ON b.ChainID = f.ChainID
	AND b.ProductID = f.ProductID
	AND b.StoreID = f.StoreID
	AND b.Supplierid = f.Supplierid
	WHERE b.InvoiceDetailTypeID = 3
	
	--POS Only - All stores/suppliers for one product
	DELETE f
	FROM [DataTrue_Main].[dbo].InventoryReport_Newspaper_Shrink_Calculate AS f
	INNER JOIN [DataTrue_Main].[dbo].[BillingExclusions] AS b
	ON b.ChainID = f.ChainID
	AND b.ProductID = f.ProductID
	AND b.StoreID = 0
	AND b.Supplierid = 0
	WHERE b.InvoiceDetailTypeID = 3
	
	--POS Only - All stores/products for one supplier
	DELETE f
	FROM [DataTrue_Main].[dbo].InventoryReport_Newspaper_Shrink_Calculate AS f
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
		DECLARE @emailRecipients VARCHAR(MAX) = 'datatrueit@icucsolutions.com'
		EXEC dbo.prSendEmailNotification_PassEmailAddresses @emailSubject, @emailMessage, 'DataTrue System', 0, @emailRecipients
	END CATCH
END
GO
