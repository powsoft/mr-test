USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_Newspapers_Shrink_Create_POSReCheck_New]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[prBilling_Newspapers_Shrink_Create_POSReCheck_New]
	-- Add the parameters for the stored procedure here
	@DaysBackToGo INT = 90,
	@DoNotDelete BIT = 0	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SET ARITHABORT ON;
	
	TRUNCATE TABLE DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck 
	
	--Get ProcessID
	DECLARE @ProcessID INT
	SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobName = 'NewspaperShrink'
	
	--INSERT SHRINK
    DECLARE @ShrinkSTIDs TABLE (StoreTransactionID BIGINT)
	INSERT INTO @ShrinkSTIDs (StoreTransactionID)
	SELECT MAX(StoreTransactionID)
	FROM DataTrue_Main.dbo.StoreTransactions AS a
	WHERE a.SaleDateTime >= GETDATE() - @DaysBackToGo
	AND a.TransactionTypeID IN (17)
	--AND a.ProcessID < @ProcessID
	GROUP BY SupplierID,
	ChainID,
	StoreID,
	ProductID,
	SaleDateTime,
	TransactionTypeID,
	RuleCost,
	UPC
	
	INSERT INTO DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck (StoreTransactionID, TransactionStatus, ChainID, SupplierID, StoreID, ProductID, BrandID, SaleDate, Qty, RuleCost, RuleRetail, TransactionTypeID, UPC)
	SELECT MAX(s.StoreTransactionID) AS StoreTransactionID, MAX(s.TransactionStatus) AS TransactionStatus, s.ChainID, s.SupplierID, s.StoreID, s.ProductID, s.BrandID, CAST(s.SaleDateTime AS DATE), SUM(s.Qty) AS Qty, s.RuleCost, s.RuleRetail, s.TransactionTypeID, MAX(LTRIM(RTRIM(ISNULL(s.UPC, '')))) AS UPC
	FROM DataTrue_Main.dbo.StoreTransactions AS s
	WHERE s.TransactionTypeID = 17
	AND s.StoreTransactionID IN (SELECT StoreTransactionID FROM @ShrinkSTIDs)
	GROUP BY TransactionStatus, s.ChainID, s.SupplierID, s.StoreID, s.ProductID, s.BrandID, CAST(s.SaleDateTime AS DATE), s.RuleCost, s.RuleRetail, s.TransactionTypeID
	
	--INSERT MISSING "FROM POS"
	MERGE INTO DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck AS target
	USING
	(
		SELECT s.ChainID, s.SupplierID, s.StoreID, s.ProductID, s.BrandID, 
		CAST(s.SaleDateTime AS DATE) AS SaleDate, SUM(s.Qty) AS Qty, LTRIM(RTRIM(ISNULL(s.UPC, ''))) AS UPC,
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
		AND CONVERT(DATE, s.SaleDateTime) >= bc.StartDate
		--AND CONVERT(DATE, s.SaleDateTime) <= (SELECT DATEADD(dd, 7 - (DATEPART(dw, GETDATE())), GETDATE()) - 13)
		GROUP BY
		s.ChainID,
		s.SupplierID,
		s.StoreID,
		s.ProductID,
		s.BrandID,
		CAST(s.SaleDateTime AS DATE),
		s.RuleCost,
		s.RuleRetail,
		LTRIM(RTRIM(ISNULL(s.UPC, ''))),
		bc.Rate
	) AS source
	ON 
	(
	target.ChainID = source.ChainID
	AND target.SupplierID = source.SupplierID
	AND target.StoreID = source.StoreID
	AND target.ProductID = source.ProductID
	AND target.SaleDate = source.SaleDate
	AND LTRIM(RTRIM(target.UPC)) = LTRIM(RTRIM(source.UPC))
	AND CONVERT(MONEY, target.RuleCost) = CONVERT(MONEY, source.RuleCost)
	AND target.TransactionTypeID = 17
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
	 [StoreTransactionID]
	,[TransactionStatus]
	,[ChainID]
	,[SupplierID]
	,[StoreID]
	,[ProductID]
	,[BrandID]
	,[SaleDate]
	,[Qty]
	,[RuleCost]
	,[RuleRetail]
	,[TransactionTypeID]
	,[UPC]
	,[DeliveryQty]
	,[POSQty]
	,[POSCost]
	,[POSRetail]
	,[FromPOS]
	)
	VALUES
	(
	 0-- [StoreTransactionID]
	,0--,[TransactionStatus]
	,source.ChainID--,[ChainID]
	,source.SupplierID--,[SupplierID]
	,source.StoreID--,[StoreID]
	,source.ProductID--,[ProductID]
	,source.BrandID--,[BrandID]
	,source.SaleDate--,[SaleDate]
	,0--,[Qty]
	,source.RuleCost--,[RuleCost]
	,source.RuleRetail--,[RuleRetail]
	,17--,[TransactionTypeID]
	,source.UPC--,[UPC]
	,0--,[DeliveryQty]
	,source.Qty--,[POSQty]
	,source.RuleCost--,[POSCost]
	,source.RuleRetail--,[POSRetail]
	,1--,[FromPOS]
	);
	
	UPDATE pos
	SET pos.FromPOS = 1
	FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck AS pos
	INNER JOIN DataTrue_Main.dbo.BillingControl_Shrink AS bc
	ON pos.ChainID = bc.ChainID
	AND pos.SupplierID = bc.SupplierID
	AND bc.ShrinkControlType IN (1, 2)
	
	UPDATE DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck
	SET FromPOS = 0 WHERE FromPOS IS NULL
	
	--GET TOTAL SHRINK FOR FROM POS
	UPDATE p
	SET p.Qty += s.Qty
	--select p.*
	FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck AS p
	INNER JOIN
	(
		SELECT s.ChainID, s.SupplierID, s.StoreID, s.ProductID, s.BrandID, 
		CAST(s.SaleDateTime AS DATE) AS SaleDate, SUM(CASE WHEN s.TransactionTypeID = 19 THEN s.Qty * -1 ELSE s.Qty END) AS Qty, LTRIM(RTRIM(ISNULL(s.UPC, ''))) AS UPC,
		s.RuleCost AS RuleCost, 
		s.RuleRetail AS RuleRetail
		FROM DataTrue_Main.dbo.StoreTransactions AS s
		INNER JOIN DataTrue_Main.dbo.BillingControl_Shrink AS bc
		ON 1 = 1
		AND s.ChainID = bc.ChainID
		AND s.SupplierID = bc.SupplierID
		AND bc.ShrinkControlType = 1
		AND CONVERT(DATE, s.SaleDateTime) >= bc.StartDate
		--AND CONVERT(DATE, s.SaleDateTime) <= (SELECT DATEADD(dd, 7 - (DATEPART(dw, GETDATE())), GETDATE()) - 13)
		WHERE s.SaleDateTime >= GETDATE() - @DaysBackToGo
		AND s.TransactionTypeID IN (17, 19)
		AND StoreTransactionID NOT IN (SELECT StoreTransactionID FROM @ShrinkSTIDs)
		GROUP BY
		s.ChainID,
		s.SupplierID,
		s.StoreID,
		s.ProductID,
		s.BrandID,
		CAST(s.SaleDateTime AS DATE),
		s.RuleCost,
		s.RuleRetail,
		LTRIM(RTRIM(ISNULL(s.UPC, ''))),
		bc.Rate
	) AS s
	ON p.ChainID = s.ChainID
	AND p.SupplierID = s.SupplierID
	AND p.StoreID = s.StoreID
	AND p.ProductID = s.ProductID
	AND CONVERT(DATE, p.SaleDate) = CONVERT(DATE, s.SaleDate)
	AND p.RuleCost = s.RuleCost
	AND p.RuleRetail = s.RuleRetail
	WHERE ISNULL(FromPOS, 0) = 1
	
	--GET DELIVERY INFO FOR NOT FROM POS RECORDS
	IF OBJECT_ID('DataTrue_EDI.dbo.tmpDeliveryPickupSTIDS', 'U') IS NOT NULL
	DROP TABLE DataTrue_EDI.dbo.tmpDeliveryPickupSTIDS
	
	SELECT StoreTransactionID
	INTO DataTrue_EDI.dbo.tmpDeliveryPickupSTIDS
	FROM
	(
	SELECT MAX(st2.DateTimeCreated) AS DateTimeCreated, st2.ChainID, st2.SupplierID, st2.StoreID, st2.ProductID, st2.SaleDateTime, st2.TransactionTypeID
	FROM DataTrue_Main.dbo.StoreTransactions AS st2 WITH (INDEX (1))
	WHERE st2.DateTimeCreated >= GETDATE() - @DaysBackToGo
	AND st2.TransactionTypeID IN (5, 8)
	--AND ISNULL(st2.ProcessID, 0) < @ProcessID
	GROUP BY st2.ChainID, st2.SupplierID, st2.StoreID, st2.ProductID, st2.SaleDateTime, st2.TransactionTypeID
	) AS st2
	INNER JOIN DataTrue_Main.dbo.StoreTransactions AS st WITH (INDEX (1))
	ON st.ChainID = st2.ChainID
	AND st.SupplierID = st2.SupplierID
	AND st.StoreID = st2.StoreID
	AND st.ProductID = st2.ProductID
	AND st.SaleDateTime = st2.SaleDateTime
	AND st.TransactionTypeID = st2.TransactionTypeID
	AND st.DateTimeCreated = st2.DateTimeCreated
	--AND ISNULL(st.ProcessID, 0) < @ProcessID
	OPTION (FORCE ORDER, HASH GROUP)

	UPDATE p
	SET p.DeliveryQty = s.Qty
	--select p.*
	FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck AS p
	INNER JOIN
	(
		SELECT ChainID, SupplierID, StoreID, ProductID, SaleDateTime, SUM(CASE WHEN TransactionTypeID = 5 THEN Qty ELSE (Qty * -1) END) AS Qty
		FROM DataTrue_Main.dbo.StoreTransactions 
		WHERE TransactionTypeID IN (5, 8)
		AND StoreTransactionID IN (SELECT StoreTransactionID FROM DataTrue_EDI.dbo.tmpDeliveryPickupSTIDS)
		GROUP BY ChainID, SupplierID, StoreID, ProductID, SaleDateTime
	) AS s
	ON p.ChainID = s.ChainID
	AND p.SupplierID = s.SupplierID
	AND p.StoreID = s.StoreID
	AND p.ProductID = s.ProductID
	AND CONVERT(DATE, p.SaleDate) = CONVERT(DATE, s.SaleDateTime)
	WHERE ISNULL(FromPOS, 0) = 0
	
	UPDATE p
	SET p.POSQty = s.Qty, p.POSCost = s.RuleCost, p.POSRetail = s.RuleRetail
	FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck AS p
	INNER JOIN
	(
		SELECT ChainID, SupplierID, StoreID, ProductID, SaleDateTime, SUM(Qty) AS Qty, CASE WHEN (ProductPriceTypeID IS NULL AND SetupCost IS NULL) THEN 0 ELSE RuleCost END AS RuleCost, CASE WHEN (ProductPriceTypeID IS NULL AND SetupCost IS NULL) THEN 0 ELSE RuleRetail END AS RuleRetail
		FROM DataTrue_Main.dbo.StoreTransactions 
		WHERE TransactionTypeID IN (2, 6, 7, 16)
		AND ISNULL(InvoiceBatchID, 0) <> 0
		GROUP BY ChainID, SupplierID, StoreID, ProductID, SaleDateTime, RuleCost, RuleRetail, ProductPriceTypeID, SetupCost
	) AS s
	ON p.ChainID = s.ChainID
	AND p.SupplierID = s.SupplierID
	AND p.StoreID = s.StoreID
	AND p.ProductID = s.ProductID
	AND p.SaleDate = s.SaleDateTime
	AND p.RuleCost = s.RuleCost
	AND p.RuleRetail = s.RuleRetail
	WHERE FromPOS = 0
	
	UPDATE DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck 
	SET POSQty = CASE WHEN POSQty IS NULL THEN 0 ELSE POSQty END,
	    DeliveryQty = CASE WHEN DeliveryQty IS NULL THEN 0 ELSE DeliveryQty END,
	    POSCost = CASE WHEN POSCost IS NULL THEN 0.00 ELSE POSCost END,
	    POSRetail = CASE WHEN POSRetail IS NULL THEN 0.00 ELSE POSRetail END
	WHERE FromPOS = 0

	IF @DoNotDelete = 0
		BEGIN
		
			DELETE FROM i
			FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck AS i
			INNER JOIN DataTrue_Main.dbo.BillingControl_Shrink AS bc
			ON 1 = 1
			AND i.ChainID = bc.ChainID
			AND i.SupplierID = bc.SupplierID
			AND bc.ShrinkControlType = 1	
			AND ISNULL(FromPOS, 0) = 1	
			WHERE CONVERT(DATE, i.SaleDate) > (SELECT DATEADD(dd, 7 - (DATEPART(dw, GETDATE())), GETDATE()) - 6)
	
			DELETE FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck
			WHERE ((DeliveryQty - POSQty) = Qty) AND ISNULL(FromPOS, 0) = 0
			AND TransactionTypeID = 17
			
			DELETE FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck
			WHERE (POSQty = Qty) AND ISNULL(FromPOS, 0) = 1
			AND TransactionTypeID = 17

		END
		
	--DELETE FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck
	--WHERE ISNULL(FromPOS, 0) = CASE WHEN @FromPOS = 0 THEN 1 ELSE 0 END
	
	--IF @FromPOS = 0
	--	BEGIN
	--		DROP TABLE DataTrue_EDI.dbo.tmpDeliveryPickupSTIDS
	--	END	
	
	--SELECT TransactionStatus, SUM(Qty * RuleCost) FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck WHERE (DeliveryQty - POSQty) <> Qty GROUP BY TransactionStatus
	--SELECT TransactionStatus, SUM((DeliveryQty - POSQty) * RuleCost) FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck WHERE (DeliveryQty - POSQty) <> Qty GROUP BY TransactionStatus

	--DROP TABLE DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_POSCheck
END
GO
