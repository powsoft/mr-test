USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_Newspapers_Shrink_Create_New]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[prBilling_Newspapers_Shrink_Create_New]

AS

BEGIN TRY

	SET NOCOUNT ON;
	
	SET ARITHABORT ON;


	--BEGIN TRANSACTION
	
		--Prep temp tables for inserted, deleted, and updated STIDs
		DECLARE @DeleteSTIDs TABLE (StoreTransactionID BIGINT)
		DECLARE @UpdatedSTIDs TABLE (StoreTransactionID BIGINT)
		DECLARE @InsertedSTIDs TABLE (StoreTransactionID BIGINT)
		
		--Get ProcessID
		DECLARE @ProcessID INT
		SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobName = 'NewspaperShrink'
		
		--Declare temp tables for shrink
		DECLARE @tempShrinkTransactions TABLE (StoreTransactionID BIGINT, ChainID INT, SupplierID INT, StoreID INT, ProductID INT, BrandID INT, SaleDate DATE, Qty INT, RuleCost MONEY, RuleRetail MONEY, TransactionTypeID INT, UPC VARCHAR(20))
		DECLARE @tempShrinkCalc TABLE (ChainID INT, SupplierID INT, StoreID INT, ProductID INT, BrandID INT, SaleDate DATE, POSQty INT, DropOffQty INT, PickUpQty INT, ShrinkQty INT, RuleCost MONEY, RuleRetail MONEY, ApprovedDrawQty INT, UPC VARCHAR(20))
		
		--Need to update where UPCs are blank/null
		DECLARE @BlankUPCs INT = 0
		
		SELECT @BlankUPCs = (SELECT COUNT(StoreTransactionID)
							 FROM DataTrue_Main.dbo.StoreTransactions AS st
							 WHERE 1 = 1
							 AND ProcessID = @ProcessID
							 AND ISNULL(UPC, '') = '')
							 
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
					WHERE t.UPC = '' OR LEN(t.UPC) < 1
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
					WHERE t.UPC = '' OR LEN(t.UPC) < 1
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
					WHERE t.UPC = '' OR LEN(t.UPC) < 1
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
					WHERE t.UPC = '' OR LEN(t.UPC) < 1
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
					WHERE t.UPC = '' OR LEN(t.UPC) < 1
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
						SELECT  TOP 1 IdentifierValue 
						FROM    DataTrue_Main..ProductIdentifiers
						WHERE   ProductID = p.ProductID
						AND		ProductIdentifierTypeID = 8
						AND		LEN(IdentifierValue) = 12
						ORDER	BY DateTimeCreated DESC
					)
					WHERE ISNULL(UPC, '') = '' OR LEN(t.UPC) < 1
					
					SET @BlankUPCs -= @@ROWCOUNT
						
					IF @BlankUPCs > 0
						BEGIN
							RAISERROR ('Unmable to match all UPCs in prBilling_Newspapers_Shrink_Create_New.' , 16 , 1)
						END	
						
				END
		
		----Need to check if UPCs are still blank/null
		--SELECT @BlankUPCs = (SELECT COUNT(StoreTransactionID)
		--					 FROM DataTrue_Main.dbo.StoreTransactions AS st
		--					 WHERE 1 = 1
		--					 AND ProcessID = @ProcessID
		--					 AND ISNULL(UPC, '') = '')
							 
		
	
NoBlankUPCs:

		-- Set ProductIdentifier = UPC where null/blank
		UPDATE t
		SET t.ProductIdentifier = t.UPC
		FROM DataTrue_Main.dbo.StoreTransactions AS t
		WHERE t.ProcessID = @ProcessID
		AND ISNULL(t.ProductIdentifier, '') = ''
		
		--Insert deliveries and pickups into temp shrink table
		INSERT INTO @tempShrinkTransactions (StoreTransactionID, ChainID, SupplierID, StoreID, ProductID, BrandID, SaleDate, Qty, RuleCost, RuleRetail, TransactionTypeID, UPC)
		SELECT s.StoreTransactionID, s.ChainID, s.SupplierID, s.StoreID, s.ProductID, s.BrandID, CAST(s.SaleDateTime AS DATE), s.Qty, s.RuleCost, s.RuleRetail, s.TransactionTypeID, LTRIM(RTRIM(ISNULL(s.UPC, '')))
		FROM DataTrue_Main.dbo.StoreTransactions AS s
		WHERE 1 = 1
		AND ProcessID = @ProcessID
		
		--Flow records to shrink calculation temp table
		INSERT INTO @tempShrinkCalc (ChainID, SupplierID, StoreID, ProductID, BrandID, SaleDate, POSQty, DropOffQty, PickUpQty, ShrinkQty, ApprovedDrawQty, RuleCost, RuleRetail, UPC)
		SELECT t.ChainID, t.SupplierID, t.StoreID, t.ProductID, t.BrandID, t.SaleDate, 0, 0, 0, 0, 0, MAX(t.RuleCost), MAX(t.RuleRetail), MAX(t.UPC)
		FROM @tempShrinkTransactions AS t
		GROUP BY t.ChainID, t.SupplierID, t.StoreID, t.ProductID, t.BrandID, t.SaleDate
		
		SELECT * INTO DataTrue_EDI.dbo.WorkingTable_Shrink_Calc
		FROM @tempShrinkCalc
		
		--Get POS quantity
		UPDATE t
		SET t.POSQty  = s.Qty
		FROM DataTrue_EDI.dbo.WorkingTable_Shrink_Calc t
		INNER JOIN
		(
			SELECT ChainID, SupplierID, StoreID, ProductID, SaleDateTime, SUM(Qty) AS Qty
			FROM DataTrue_Main.dbo.StoreTransactions 
			WHERE TransactionTypeID IN (2, 6, 7, 16)
			AND ISNULL(InvoiceBatchID, 0) <> 0
			GROUP BY ChainID, SupplierID, StoreID, ProductID, SaleDateTime
		) AS s
		ON t.ChainID = s.ChainID
		AND t.SupplierID = s.SupplierID
		AND t.StoreID = s.StoreID
		AND t.ProductID = s.ProductID
		AND t.SaleDate = s.SaleDateTime
		
		--Get delivery (drop-off) quantity
		UPDATE t
		SET t.DropOffQty = ISNULL(s.Qty, 0)
		FROM DataTrue_EDI.dbo.WorkingTable_Shrink_Calc AS t
		INNER JOIN
		(
			SELECT st.ChainID, st.SupplierID, st.StoreID, st.ProductID, st.BrandID, CONVERT(DATE, st.SaleDateTime) AS SaleDate, SUM(Qty) AS Qty
			FROM DataTrue_Main.dbo.StoreTransactions AS st  with (index(0))
			INNER JOIN (SELECT MAX(st2.DateTimeCreated) AS DateTimeCreated, st2.ChainID, st2.SupplierID, st2.StoreID, st2.ProductID, st2.SaleDateTime, st2.TransactionTypeID
						FROM DataTrue_Main.dbo.StoreTransactions AS st2
						WHERE st2.DateTimeCreated >= GETDATE() - 30
						AND st2.TransactionTypeID IN (5)
						GROUP BY st2.ChainID, st2.SupplierID, st2.StoreID, st2.ProductID, st2.SaleDateTime, st2.TransactionTypeID) AS st2
			ON st.ChainID = st2.ChainID
			AND st.SupplierID = st2.SupplierID
			AND st.StoreID = st2.StoreID
			AND st.ProductID = st2.ProductID
			AND st.SaleDateTime = st2.SaleDateTime
			AND st.TransactionTypeID = st2.TransactionTypeID
			AND st.DateTimeCreated = st2.DateTimeCreated
			GROUP BY st.ChainID, st.SupplierID, st.StoreID, st.ProductID, st.BrandID, CONVERT(DATE, st.SaleDateTime)
		) AS s
		ON s.ChainID = t.ChainID
		AND s.SupplierID = t.SupplierID
		AND s.StoreID = t.StoreID
		AND s.ProductID = t.ProductID
		--AND s.BrandID = t.BrandID
		AND s.SaleDate = t.SaleDate
		option (hash group,hash join)
		
		--Get pick-up quantity
		UPDATE t
		SET t.PickUpQty = ISNULL(s.Qty, 0)
		FROM DataTrue_EDI.dbo.WorkingTable_Shrink_Calc AS t
		INNER JOIN
		(
			SELECT st.ChainID, st.SupplierID, st.StoreID, st.ProductID, st.BrandID, CONVERT(DATE, st.SaleDateTime) AS SaleDate, SUM(Qty) AS Qty
			FROM DataTrue_Main.dbo.StoreTransactions AS st with (index(0))
			INNER JOIN (SELECT MAX(st2.DateTimeCreated) AS DateTimeCreated, st2.ChainID, st2.SupplierID, st2.StoreID, st2.ProductID, st2.SaleDateTime, st2.TransactionTypeID
						FROM DataTrue_Main.dbo.StoreTransactions AS st2
						WHERE st2.DateTimeCreated >= GETDATE() - 30
						AND st2.TransactionTypeID IN (8)
						GROUP BY st2.ChainID, st2.SupplierID, st2.StoreID, st2.ProductID, st2.SaleDateTime, st2.TransactionTypeID) AS st2
			ON st.ChainID = st2.ChainID
			AND st.SupplierID = st2.SupplierID
			AND st.StoreID = st2.StoreID
			AND st.ProductID = st2.ProductID
			AND st.SaleDateTime = st2.SaleDateTime
			AND st.TransactionTypeID = st2.TransactionTypeID
			AND st.DateTimeCreated = st2.DateTimeCreated
			GROUP BY st.ChainID, st.SupplierID, st.StoreID, st.ProductID, st.BrandID, CONVERT(DATE, st.SaleDateTime)
		) AS s
		ON s.ChainID = t.ChainID
		AND s.SupplierID = t.SupplierID
		AND s.StoreID = t.StoreID
		AND s.ProductID = t.ProductID
		--AND s.BrandID = t.BrandID
		AND s.SaleDate = t.SaleDate
		option (hash group,hash join)
		
		--Calculate shrink
		UPDATE t
		SET t.ShrinkQty = (DropOffQty - PickUpQty - POSQty)
		FROM DataTrue_EDI.dbo.WorkingTable_Shrink_Calc AS t
		
		--Check if there are matching APPROVED transactions already in Shrink Fact table		
		--Set Status to 5 in Shrink Facts table where there are existing APPROVED transactions
		UPDATE i 
		SET i.Status = 5
		FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_Facts AS i
		WHERE 1 = 1
		AND i.Status IN (1, 6)
		AND CONVERT(VARCHAR(50), i.ChainID) + CONVERT(VARCHAR(50), i.StoreID) + CONVERT(VARCHAR(50), i.ProductID) + CONVERT(VARCHAR(50), CONVERT(DATE, i.SaleDateTime))
		IN
		(
			SELECT DISTINCT CONVERT(VARCHAR(50), t.ChainID) + CONVERT(VARCHAR(50), t.StoreID) + CONVERT(VARCHAR(50), t.ProductID) + CONVERT(VARCHAR(50), t.SaleDate)
			FROM DataTrue_EDI.dbo.WorkingTable_Shrink_Calc AS t
		)
	
		--Reject existing pending IN SETTLEMENT transactions from Shrink Fact table	
		UPDATE i
		SET i.Status = 3, RejectReason = 'Pending record rejected by incoming duplicate context', DeniedDCRSendStatus = 1, DeniedDCRSendDateTime = GETDATE(), ApprovalDateTime = GETDATE()
		OUTPUT inserted.StoreTransactionID INTO @DeleteSTIDs
		--select *
		FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_Facts AS i
		WHERE 1 = 1
		AND i.Status IN (2, 4)
		AND i.TransactionTypeID = 17
		AND CONVERT(VARCHAR(50), i.ChainID) + CONVERT(VARCHAR(50), i.StoreID) + CONVERT(VARCHAR(50), i.ProductID) + CONVERT(VARCHAR(50),CONVERT(DATE, i.SaleDateTime))
		IN
		(
			SELECT DISTINCT CONVERT(VARCHAR(50), t.ChainID) + CONVERT(VARCHAR(50), t.StoreID) + CONVERT(VARCHAR(50), t.ProductID) + CONVERT(VARCHAR(50), t.SaleDate)
			FROM DataTrue_EDI.dbo.WorkingTable_Shrink_Calc AS t
		)
		
		SELECT * FROM @DeleteSTIDs
		
		UPDATE st
		SET st.TransactionStatus = -800, st.ShrinkLocked = 1
		FROM DataTrue_Main.dbo.StoreTransactions AS st
		WHERE StoreTransactionID IN (SELECT StoreTransactionID FROM @DeleteSTIDs)
						
		--Insert shrink records into StoreTransactions (TransactionTypeID = 17 for shrink)
		INSERT INTO DataTrue_Main.dbo.StoreTransactions
		(
		[ChainID],
		[StoreID],
		[ProductID],
		[SupplierID],
		[TransactionTypeID],
		[TransactionStatus],
		[ProductPriceTypeID],
		[BrandID],
		[Qty],
		[SetupCost],
		[SetupRetail],
		[SaleDateTime],
		[RuleCost],
		[RuleRetail],
		[TrueCost],
		[TrueRetail],
		[LastUpdateUserID],
		[SourceID],
		[WorkingTransactionID],
		[UPC],
		[ProductIdentifier],
		[ProcessID]
		)
		OUTPUT inserted.StoreTransactionID INTO @InsertedSTIDs
		SELECT DISTINCT
		ChainID,--[ChainID],
		StoreID,--[StoreID],
		ProductID,--[ProductID],
		SupplierID,--[SupplierID],
		17,--[TransactionTypeID],
		CASE WHEN ShrinkQty = 0 THEN 815 ELSE 0 END,--[TransactionStatus],
		3,--[ProductPriceTypeID],
		BrandID,--[BrandID],
		ShrinkQty,--[Qty],
		RuleCost,--[SetupCost],
		RuleRetail,--[SetupRetail],
		SaleDate,--[SaleDateTime],
		RuleCost,--[RuleCost],
		RuleRetail,--[RuleRetail],
		RuleCost,--[TrueCost],
		RuleRetail,--[TrueRetail],
		63600,--[LastUpdateUserID],
		135,--[SourceID],
		0,--[WorkingTransactionID],
		UPC,--[UPC]
		UPC,
		@ProcessID
		FROM DataTrue_EDI.dbo.WorkingTable_Shrink_Calc
		
		SELECT * FROM @InsertedSTIDs
		
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
		[OriginalPickups]
		)
		SELECT DISTINCT
		st.[TransactionTypeID],--[TransactionTypeID],
		st.[ChainID],--[ChainID],
		st.[StoreID],--[StoreID],
		st.[ProductID],--[ProductID],
		st.[BrandID],--[BrandID],
		st.[SupplierID],--[SupplierID],
		st.[SaleDateTime],--[SaleDateTime],
		st.[RuleCost],--[UnitCost],
		st.[Qty],--[ShrinkUnits],
		(st.[Qty] * st.[RuleCost]),--[Shrink$],
		GETDATE(),--[DateTimeCreated],
		63600,--[LastUpdateUserID],
		CASE WHEN st.Qty = 0 THEN 4 ELSE 2 END,--[Status],
		st.[StoreTransactionID],--[StoreTransactionID],
		t.POSQty,--[OriginalPOS],
		t.DropOffQty,--[OriginalDeliveries],
		t.PickUpQty--[OriginalPickups]
		FROM DataTrue_Main.dbo.StoreTransactions AS st WITH (NOLOCK)
		INNER JOIN DataTrue_EDI.dbo.WorkingTable_Shrink_Calc AS t
		ON t.ChainID = st.ChainID
		AND t.SupplierID = st.SupplierID
		AND t.StoreID = st.StoreID
		AND t.ProductID = st.ProductID
		AND t.BrandID = st.BrandID
		AND t.SaleDate = CAST(st.SaleDateTime AS DATE)
		WHERE 1 = 1
		AND StoreTransactionID IN (SELECT StoreTransactionID FROM @InsertedSTIDs)
		
		-- REJECT RECORDS THAT HAVE EXACT SAME CONTEXT DETAILS
		DECLARE @DupShrinkSTIDs TABLE (StoreTransactionID BIGINT)
		
		UPDATE st
		SET st.TransactionStatus = -800, st.ShrinkLocked = 1
		OUTPUT inserted.StoreTransactionID INTO @DupShrinkSTIDs
		FROM DataTrue_Main.dbo.StoreTransactions AS st
		WHERE StoreTransactionID IN
		(
			SELECT DISTINCT f2.StoreTransactionID
			FROM DataTrue_Main..InventoryReport_Newspaper_Shrink_Facts f1
			INNER JOIN DataTrue_Main..InventoryReport_Newspaper_Shrink_Facts f2
			ON f1.ChainID = f2.ChainID
			AND f1.StoreID = f2.StoreID
			AND f1.ProductID = f2.ProductID
			AND f1.SaleDateTime = f2.SaleDateTime
			AND f1.status = 5
			AND f2.Status = 2
			AND f1.UnitCost = f2.UnitCost
			AND f1.ShrinkUnits = f2.ShrinkUnits
			AND f1.Shrink$ = f2.Shrink$
			AND f1.OriginalPOS = f2.OriginalPOS
			AND f1.OriginalDeliveries = f2.OriginalDeliveries
			AND f1.OriginalPickups = f2.OriginalPickups
		)
		
		UPDATE f
		SET status = 3, RejectReason = 'Record rejected due to existing duplicate context', ApprovalDateTime = GETDATE(), DeniedDCRSendStatus = 1, DeniedDCRSendDateTime = GETDATE()
		FROM DataTrue_Main..InventoryReport_Newspaper_Shrink_Facts AS f
		WHERE StoreTransactionID IN	(SELECT StoreTransactionID FROM @DupShrinkSTIDs)
		
		
		--Update old back from approved pending to approved where old approved = new pending
		UPDATE f1
		SET f1.Status = 1
		FROM DataTrue_Main..InventoryReport_Newspaper_Shrink_Facts f1
		INNER JOIN DataTrue_Main..InventoryReport_Newspaper_Shrink_Facts f2
		ON f1.ChainID = f2.ChainID
		AND f1.StoreID = f2.StoreID
		AND f1.ProductID = f2.ProductID
		AND f1.SaleDateTime = f2.SaleDateTime
		AND f1.status = 5
		AND f2.Status IN (2, 3)
		AND f1.UnitCost = f2.UnitCost
		AND f1.ShrinkUnits = f2.ShrinkUnits
		AND f1.Shrink$ = f2.Shrink$
		AND f1.OriginalPOS = f2.OriginalPOS
		AND f1.OriginalDeliveries = f2.OriginalDeliveries
		AND f1.OriginalPickups = f2.OriginalPickups
		AND f2.StoreTransactionID IN (SELECT StoreTransactionID FROM @DupShrinkSTIDs)
		
		
		--Run POS Exclusions
		UPDATE f
		SET f.Status = 3, f.RejectReason = 'POS Only - Specific supplier/store for one product', f.ApprovalDateTime = GETDATE(), DeniedDCRSendStatus = 1, DeniedDCRSendDateTime = GETDATE()
		OUTPUT inserted.StoreTransactionID INTO @UpdatedSTIDs
		FROM [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts] AS f
		INNER JOIN [DataTrue_Main].[dbo].[BillingExclusions] AS b
		ON b.ChainID = f.ChainID
		AND b.ProductID = f.ProductID
		AND b.StoreID = f.StoreID
		AND b.Supplierid = f.Supplierid
		WHERE f.Status IN (2, 4)
		--AND CONVERT(DATE, f.DateTimeCreated) = CONVERT(DATE, GETDATE())
		--AND f.StoreTransactionID IN (SELECT StoreTransactionID FROM @InsertedSTIDs)
		AND b.InvoiceDetailTypeID = 3
		
		UPDATE f
		SET f.Status = 3, f.RejectReason = 'POS Only - All stores/suppliers for one product', f.ApprovalDateTime = GETDATE(), DeniedDCRSendStatus = 1, DeniedDCRSendDateTime = GETDATE()
		OUTPUT inserted.StoreTransactionID INTO @UpdatedSTIDs
		FROM [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts] AS f
		INNER JOIN [DataTrue_Main].[dbo].[BillingExclusions] AS b
		ON b.ChainID = f.ChainID
		AND b.ProductID = f.ProductID
		AND b.StoreID = 0
		AND b.Supplierid = 0
		AND f.TransactionTypeID = 17
		WHERE f.Status IN (2, 4)
		--AND CONVERT(DATE, f.DateTimeCreated) = CONVERT(DATE, GETDATE())
		--AND f.StoreTransactionID IN (SELECT StoreTransactionID FROM @InsertedSTIDs)
		AND b.InvoiceDetailTypeID = 3
		
		UPDATE f
		SET f.Status = 3, f.RejectReason = 'POS Only - All stores/products for one supplier', f.ApprovalDateTime = GETDATE(), DeniedDCRSendStatus = 1, DeniedDCRSendDateTime = GETDATE()
		OUTPUT inserted.StoreTransactionID INTO @UpdatedSTIDs
		FROM [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts] AS f
		INNER JOIN [DataTrue_Main].[dbo].[BillingExclusions] AS b
		ON b.ChainID = f.ChainID
		AND b.ProductID = 0
		AND b.StoreID = 0
		AND b.Supplierid = f.Supplierid
		AND f.TransactionTypeID = 17
		WHERE f.Status IN (2, 4)
		--AND CONVERT(DATE, f.DateTimeCreated) = CONVERT(DATE, GETDATE())
		--AND f.StoreTransactionID IN (SELECT StoreTransactionID FROM @InsertedSTIDs)
		AND b.InvoiceDetailTypeID = 3
		
		--Update StoreTransactions as rejected for POS exclusions
		UPDATE st
		SET st.TransactionStatus = -800, st.ShrinkLocked = 1
		FROM [DataTrue_Main].[dbo].[StoreTransactions] AS st
		INNER JOIN [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts] AS f
		ON f.StoreTransactionID = st.StoreTransactionID
		WHERE f.StoreTransactionID IN (SELECT StoreTransactionID FROM @UpdatedSTIDs)
		
		DROP TABLE DataTrue_EDI.dbo.WorkingTable_Shrink_Calc
		
	--COMMIT TRANSACTION
END TRY

BEGIN CATCH
	--ROLLBACK TRANSACTION
	DECLARE @ErrorMessage VARCHAR(MAX)
	SET @ErrorMessage = ERROR_MESSAGE()
	DECLARE @emailSubject VARCHAR(MAX) = 'ERROR in Billing_Newspapers_Shrink_NewApprovalData Job'
	DECLARE @emailMessage VARCHAR(MAX) = @ErrorMessage + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + 'ProcessID: ' + CONVERT(VARCHAR(50), @ProcessID)
	DECLARE @emailRecipients VARCHAR(MAX) = 'datatrueit@icontroldsd.com; edi@icontroldsd.com'
	EXEC dbo.prSendEmailNotification_PassEmailAddresses @emailSubject, @emailMessage, 'DataTrue System', 0, @emailRecipients
END CATCH

RETURN
GO
