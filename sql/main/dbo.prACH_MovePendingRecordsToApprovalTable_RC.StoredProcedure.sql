USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prACH_MovePendingRecordsToApprovalTable_RC]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[prACH_MovePendingRecordsToApprovalTable_RC]
AS

--------DECLARE VARIABLES------------
DECLARE @errorMessage nVARCHAR(4000)
DECLARE @errorLocation nVARCHAR(255)
DECLARE @errorSenderString nVARCHAR(255)
CREATE TABLE #tmpRecordIDs (RecordID INT)
-------------------------------------
BEGIN TRY
-----------------
-----------------		
BEGIN TRANSACTION
-----------------

--=======================
--    PRE PROCESSING
--=======================
--SEE IF ANY RECORDS CAN BE MATCHED
	
	--UPDATE rd 
	--SET rd.ChainName = CASE WHEN c.ChainIdentifier IS NULL THEN 'UNMATCHED' ELSE c.ChainIdentifier END,
	--rd.DataTrueChainID = CASE WHEN c.ChainID IS NULL THEN NULL ELSE c.ChainID END
	--FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries AS rd
	--LEFT OUTER JOIN DataTrue_EDI.dbo.Chains AS c
	--ON rd.ChainName = c.ChainIdentifier
	--WHERE rd.RecordStatus = 0 AND (rd.ChainName IS NULL OR rd.DataTrueChainID IS NULL)
	
	--UPDATE rd 
	--SET rd.SupplierIdentifier = CASE WHEN s.SupplierIdentifier IS NULL THEN 'UNMATCHED' ELSE s.SupplierIdentifier END,
	--    rd.EdiName = CASE WHEN s.EdiName IS NULL THEN 'UNMATCHED' ELSE s.EdiName END,
	--    rd.DataTrueSupplierID = CASE WHEN s.SupplierID IS NULL THEN NULL ELSE s.SupplierID END
	--FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries AS rd
	--LEFT OUTER JOIN DataTrue_EDI.dbo.Suppliers AS s
	--ON rd.EdiName = s.EdiName
	--WHERE rd.RecordStatus = 0 AND (rd.EDIName IS NULL OR rd.DataTrueSupplierID IS NULL)
	
	--UPDATE rd 
	--SET rd.StoreNumber = CASE WHEN s.StoreIdentifier IS NULL THEN 'UNMATCHED' ELSE s.StoreIdentifier END,
	--    rd.DataTrueStoreID = CASE WHEN s.StoreID IS NULL THEN NULL ELSE s.StoreID END
	--    --select s.StoreIdentifier, rd.*
	--FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries AS rd
	--INNER JOIN DataTrue_EDI.dbo.Chains AS c
	--ON rd.ChainName = c.ChainIdentifier
	--LEFT OUTER JOIN DataTrue_Main.dbo.Stores AS s
	--ON c.ChainID = s.ChainID
	--AND SUBSTRING(rd.StoreNumber, PATINDEX('%[^0 ]%', rd.StoreNumber + ' '), LEN(rd.StoreNumber)) = SUBSTRING(s.StoreIdentifier, PATINDEX('%[^0 ]%', s.StoreIdentifier + ' '), LEN(s.StoreIdentifier))
	--WHERE rd.RecordStatus = 0 AND (rd.StoreNumber IS NULL or rd.DataTrueStoreID IS NULL)
	
	UPDATE rd
	SET rd.ReferenceIDentification = ''
	FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries AS rd
	WHERE rd.ReferenceIDentification IS NULL
	
--GET RECORDIDS FOR PROCESSING
	INSERT INTO #tmpRecordIDs (RecordID)
	SELECT rc.RecordID
	FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries AS rc
	INNER JOIN DataTrue_EDI.dbo.EDI_LoadStatus_Receiving AS edi
	ON rc.DataTrueChainID = edi.ChainID
	AND rc.DataTrueSupplierID = edi.SupplierID
	AND rc.FileName = edi.Filename
	WHERE rc.RecordStatus = 0
	AND edi.LoadStatus = 1
	AND edi.FileName IN
	(
		SELECT TOP 1 FileName
		FROM DataTrue_EDI.dbo.EDI_LoadStatus_Receiving AS b
		WHERE 1 = 1
		AND LoadStatus = 1
		AND rc.DataTrueChainID = b.ChainID
		AND rc.DataTrueSupplierID = b.SupplierID
		ORDER BY TimeStamp ASC
	)

--RECEIVING PRODUCT MANIPULATION
	UPDATE rd
	SET rd.ProductIdentifier = DataTrue_EDI.dbo.fnParseUPC(REPLACE(rd.RawProductIdentifier, ' ', ''))
	FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries rd
	INNER JOIN #tmpRecordIDs AS t
	ON t.RecordID = rd.RecordID
	WHERE ISNULL(rd.ProductIdentifier, '') = '' AND ISNULL(rd.RawProductIdentifier, '') <> ''
	    
	UPDATE rd
	SET rd.ProductIdentifier = 'DEFAULT'
	FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries rd
	INNER JOIN #tmpRecordIDs AS t
	ON t.RecordID = rd.RecordID
	WHERE ISNULL(rd.ProductIdentifier, '') = '' AND ISNULL(rd.ItemNumber, '') = ''
		 
--UPDATE RECORDS WITH MISSING EFFECTIVE DATE TO 1/1/1900
	UPDATE rd
	SET rd.EffectiveDate = '1/1/1900'
	FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries rd
	INNER JOIN #tmpRecordIDs AS t
	ON t.RecordID = rd.RecordID
	WHERE ISNULL(rd.EffectiveDate, '') = ''
	
--=======================
--       VALIDATION
--=======================
	
	--CHECK FOR DUPLICATE INVOICE RECORDS (UNLESS THE ENTIRE INVOICE IS REJECTED)
	CREATE TABLE #tmpDupRecords (ChainIdentifier VARCHAR(100), InvoiceNo VARCHAR(100), InvoiceTotal VARCHAR(100), NewDeliveryDate VARCHAR(20), ExistingDeliveryDate VARCHAR(20), SupplierIdentifier VARCHAR(50), NewFileName VARCHAR(200), ExistingFileName VARCHAR(200), ExistingStatus VARCHAR(30), ExistingTotal VARCHAR(100), NewCnt INT, ExistingCnt INT)		
	
	--CREATE TABLE FOR APPENDED INVOICES
	--ADDED BY FREEWILLY 6/1/2015
	CREATE TABLE #tmpAppendedRecords (ChainIdentifier VARCHAR(100), InvoiceNo VARCHAR(100), InvoiceTotal VARCHAR(100), DeliveryDate VARCHAR(20), SupplierIdentifier VARCHAR(50), FileName VARCHAR(200))		
	
	INSERT INTO #tmpDupRecords (ChainIdentifier, InvoiceNo, InvoiceTotal, NewDeliveryDate, ExistingDeliveryDate, SupplierIdentifier, NewFileName, ExistingFileName, ExistingStatus, ExistingTotal, NewCnt, ExistingCnt)
	SELECT DISTINCT
		LTRIM(RTRIM(rd.ChainName)),
		CASE WHEN LTRIM(RTRIM(ISNULL(rd.ReferenceIDentification, ''))) = '' THEN rd.PurchaseOrderNo ELSE LTRIM(RTRIM(rd.ReferenceIDentification)) END AS ReferenceIDentification,
		CONVERT(NUMERIC(18, 9),	
				SUM(ISNULL(rd.Qty, 0)*rd.Cost) 
				+SUM(ISNULL(rd.AlllowanceChargeAmount1, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount2, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount3, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount4, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount5, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount6, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount7, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount8, 0))
				 ) AS ACHTotal,
		rd.EffectiveDate,
		Approval.EffectiveDate,
		rd.EdiName,
		rd.Filename, 
		Approval.FileName,
		CASE WHEN Approval.RecordStatus = 0 THEN 'APPROVED'
			 WHEN Approval.RecordStatus = 1 THEN 'PROCESSED'
			 WHEN Approval.RecordStatus = 2 THEN 'PENDING'
			 ELSE 'UNKNOWN'
		END,
		Approval.ApprovalTotal,
		COUNT(rd.RecordID) AS NewCnt,
		Approval.Cnt
	FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries rd
	INNER JOIN #tmpRecordIDs AS t
	ON t.RecordID = rd.RecordID
	CROSS APPLY
	(
	SELECT DISTINCT Approval.ChainName, EdiName, EffectiveDate,
	CASE WHEN LTRIM(RTRIM(ISNULL(Approval.ReferenceIDentification, ''))) = '' THEN Approval.PurchaseOrderNo ELSE LTRIM(RTRIM(Approval.ReferenceIDentification)) END AS ReferenceIDentification, 
	RecordStatus, FileName, COUNT(RecordID) AS Cnt,
	CONVERT(NUMERIC(18, 9),	
					SUM(Approval.Qty*Approval.Cost) 
					+SUM(ISNULL(Approval.AlllowanceChargeAmount1, 0))
					+SUM(ISNULL(Approval.AlllowanceChargeAmount2, 0))
					+SUM(ISNULL(Approval.AlllowanceChargeAmount3, 0))
					+SUM(ISNULL(Approval.AlllowanceChargeAmount4, 0))
					+SUM(ISNULL(Approval.AlllowanceChargeAmount5, 0))
					+SUM(ISNULL(Approval.AlllowanceChargeAmount6, 0))
					+SUM(ISNULL(Approval.AlllowanceChargeAmount7, 0))
					+SUM(ISNULL(Approval.AlllowanceChargeAmount8, 0))
					) AS ApprovalTotal
	FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries_Approval AS Approval
	INNER JOIN DataTrue_EDI.dbo.Chains AS c
	ON Approval.ChainName = c.ChainIdentifier
	WHERE Approval.ChainName = rd.ChainName
	AND Approval.ReferenceIDentification = rd.ReferenceIDentification
	AND Approval.EdiName = rd.EdiName
	AND Approval.RecordStatus NOT IN (3, 255)
	GROUP BY Approval.ChainName, Approval.EdiName, Approval.EffectiveDate, Approval.RecordStatus, Approval.FileName,
	CASE WHEN LTRIM(RTRIM(ISNULL(Approval.ReferenceIDentification, ''))) = '' THEN Approval.PurchaseOrderNo ELSE LTRIM(RTRIM(Approval.ReferenceIDentification)) END
	) AS Approval
	WHERE 1 = 1
	GROUP BY rd.ChainName, CASE WHEN LTRIM(RTRIM(ISNULL(rd.ReferenceIDentification, ''))) = '' THEN rd.PurchaseOrderNo ELSE LTRIM(RTRIM(rd.ReferenceIDentification)) END, 
	rd.EffectiveDate, rd.EdiName, rd.FileName, Approval.FileName, Approval.RecordStatus, Approval.ApprovalTotal, Approval.Cnt, Approval.EffectiveDate					 
	
	DELETE t
	OUTPUT deleted.ChainIdentifier, deleted.SupplierIdentifier, deleted.NewDeliveryDate, deleted.NewFileName, deleted.InvoiceNo, deleted.InvoiceTotal
	INTO #tmpAppendedRecords (ChainIdentifier, SupplierIdentifier, DeliveryDate, FileName, InvoiceNo, InvoiceTotal)
	FROM #tmpDupRecords AS t 
	WHERE 1 = 1
	AND (NewCnt <> ExistingCnt)
	AND (NewDeliveryDate = ExistingDeliveryDate)
	
	DELETE t
	OUTPUT deleted.ChainIdentifier, deleted.SupplierIdentifier, deleted.NewDeliveryDate, deleted.NewFileName, deleted.InvoiceNo, deleted.InvoiceTotal
	INTO #tmpAppendedRecords (ChainIdentifier, SupplierIdentifier, DeliveryDate, FileName, InvoiceNo, InvoiceTotal)
	FROM #tmpDupRecords AS t 
	WHERE 1 = 1
	AND(InvoiceTotal <> ExistingTotal)
	AND (NewDeliveryDate = ExistingDeliveryDate)
	
	SELECT * FROM #tmpDupRecords
					 	
	DECLARE @DupCount INT
	SET @DupCount = @@RowCount	
							
	IF @DupCount > 0
		BEGIN
		
			UPDATE #tmpDupRecords
			SET InvoiceNo = InvoiceNo + REPLICATE(' ', (10 - LEN(InvoiceNo)))
			WHERE LEN(InvoiceNo) < 11
			
			UPDATE #tmpDupRecords
			SET InvoiceTotal = CONVERT(VARCHAR(100), CONVERT(MONEY,InvoiceTotal)) + REPLICATE(' ', (13 - LEN(CONVERT(MONEY, InvoiceTotal))))
			WHERE LEN(CONVERT(MONEY, InvoiceTotal)) < 14
			
			UPDATE #tmpDupRecords
			SET ExistingTotal = CONVERT(VARCHAR(100), CONVERT(MONEY, ExistingTotal)) + REPLICATE(' ', (14 - LEN(CONVERT(MONEY, ExistingTotal))))
			WHERE LEN(ExistingTotal) < 15
			
			UPDATE #tmpDupRecords
			SET ExistingStatus = ExistingStatus + REPLICATE(' ', (15 - LEN(ExistingStatus)))
			WHERE LEN(ExistingStatus) < 16
			
			--INSERT INTO ACH_INVALIDINVOICES FOR DUPLICATES
			INSERT INTO [DataTrue_Main].[dbo].[ACH_InvalidInvoices] (ChainID, SupplierID, InvoiceNo, TotalAmt, EffectiveDate, InvalidInvoiceType, RecordStatus, Filename)
			(
			SELECT
				(SELECT ChainID FROM [DataTrue_Main].[dbo].[Chains] WHERE ChainIdentifier = rd.ChainName),
				(SELECT SupplierID FROM [DataTrue_Main].[dbo].[Suppliers] WHERE EDIName = rd.EdiName),
				CASE WHEN LTRIM(RTRIM(ISNULL(rd.ReferenceIDentification, ''))) = '' THEN rd.PurchaseOrderNo ELSE LTRIM(RTRIM(rd.ReferenceIDentification)) END AS ReferenceIDentification,
				CONVERT(NUMERIC(18, 9),	
						SUM(ISNULL(rd.Qty, 0)*rd.Cost) 
						+SUM(ISNULL(rd.AlllowanceChargeAmount1, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount2, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount3, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount4, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount5, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount6, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount7, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount8, 0))
						 ),
				rd.EffectiveDate,
				23,--DUPLICATE INVALIDINVOICETYPE FOR RECEIVING
				(SELECT CASE WHEN Actionable = 0 THEN 1 ELSE 0 END FROM DataTrue_Main.dbo.ACH_InvalidInvoiceTypes WHERE InvalidInvoiceTypeID = 23),
				rd.FileName
			FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries rd
			INNER JOIN #tmpRecordIDs AS t
			ON t.RecordID = rd.RecordID
			INNER JOIN #tmpDupRecords AS Temp
			ON rd.ChainName = Temp.ChainIdentifier
			AND rd.SupplierIdentifier = Temp.SupplierIdentifier
			AND rd.FileName = Temp.NewFileName
			AND rd.ReferenceIDentification = Temp.InvoiceNo
			WHERE 1 = 1
			GROUP BY rd.ChainName, rd.EffectiveDate, rd.SupplierIdentifier, rd.EdiName, rd.FileName,
			CASE WHEN LTRIM(RTRIM(ISNULL(rd.ReferenceIDentification, ''))) = '' THEN rd.PurchaseOrderNo ELSE LTRIM(RTRIM(rd.ReferenceIDentification)) END
			)
		
			DECLARE @dupChain VARCHAR(50)
			DECLARE @dupSupplier VARCHAR(50)
			DECLARE @dupFilename VARCHAR(120)
			DECLARE SupplierCursor CURSOR FAST_FORWARD LOCAL FOR 
			SELECT DISTINCT ChainIdentifier, SupplierIdentifier, NewFileName
			FROM #tmpDupRecords
			ORDER BY ChainIdentifier, SupplierIdentifier, NewFileName

			OPEN SupplierCursor

			FETCH NEXT FROM SupplierCursor 
			INTO @dupChain, @dupSupplier, @dupFilename
			
			WHILE @@FETCH_STATUS = 0
				BEGIN
			
					DECLARE @DupRecords VARCHAR(MAX)
					SET @DupRecords = 'INVOICE NO' + CHAR(9) + 'INVOICE TOTAL' + CHAR(9) + CHAR(9) + 'DELIVERY DATE' + CHAR(9) + CHAR(9) + 'EXISTING DATE' + CHAR(9) + CHAR(9) + 'EXISTING TOTAL' + CHAR(9) + CHAR(9) + 'EXISTING STATUS' + CHAR(9) + CHAR(9) + 'EXISTING FILE' + CHAR(13) + CHAR(10)	
									
					SELECT @DupRecords += x.InvoiceNo + CHAR(9) + x.InvoiceTotal + CHAR(9) + CHAR(9) + REPLACE(CONVERT(VARCHAR(20), x.NewDeliveryDate), '12:00AM', '') + CHAR(9) + CHAR(9) + REPLACE(CONVERT(VARCHAR(20), x.ExistingDeliveryDate), '12:00AM', '') + CHAR(9) + CHAR(9) + x.ExistingTotal + CHAR(9) + CHAR(9) + x.ExistingStatus + CHAR(9) + CHAR(9) + x.ExistingFileName + CHAR(13) + CHAR(10)
					FROM #tmpDupRecords x
					WHERE x.SupplierIdentifier = @dupSupplier
					AND x.ChainIdentifier = @dupChain
					AND x.NewFileName = @dupFilename
					ORDER BY x.InvoiceNo
					
					DECLARE @DupTotal VARCHAR(100)
					SELECT @DupTotal = SUM(CONVERT(NUMERIC(18, 9),t.InvoiceTotal))
					FROM 
					(
					SELECT DISTINCT InvoiceNo, CONVERT(NUMERIC(18, 9),InvoiceTotal) AS InvoiceTotal
					FROM #tmpDupRecords x
					WHERE x.SupplierIdentifier = @dupSupplier
					AND x.ChainIdentifier = @dupChain
					AND x.NewFileName = @dupFilename
					) AS t
					
					SET @DupRecords = 'TOTAL AMOUNT: $' + CONVERT(VARCHAR(50), CONVERT(MONEY, @DupTotal))  + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + @DupRecords	
					
					DECLARE @contacts VARCHAR(MAX) = ''
				
					SELECT @contacts += ISNULL(Email, '') + '; '
					FROM [DataTrue_Main].[dbo].[ContactInfo] AS c WITH (NOLOCK)
					WHERE 1 = 1
					AND c.OwnerEntityID = (SELECT ChainID FROM [DataTrue_Main].[dbo].[Chains] WHERE ChainName = @dupChain)
					AND c.ReceiveACHNotifications = 1
					
					SET @contacts = @contacts + 'edi@icucsolutions.com;'
					IF ISNULL(@contacts, '') = ''
						BEGIN
							SET @contacts = 'edi@icucsolutions.com;'
						END
						
					IF (SELECT IsRegulated FROM Suppliers WHERE EDIName = @dupSupplier) = 1
						BEGIN
							SET @contacts = @contacts + 'regulated@icucsolutions.com;'
						END
					ELSE IF (SELECT 1 FROM Memberships WHERE MembershipTypeID = 14
						     AND OrganizationEntityID IN (SELECT ChainID FROM DataTrue_Main.dbo.Chains WHERE ChainIdentifier = @dupChain)
						     AND MemberEntityID = (SELECT SupplierID FROM DataTrue_Main.dbo.Suppliers WHERE EDIName = @dupSupplier)) = 1
						BEGIN
							SET @contacts = @contacts + 'dataexchange@profdata.com;'
						END
					
						
					--FOR TESTING
					SET @contacts = 'william.heine@icucsolutions.com'
					------------
					DECLARE @FileName VARCHAR(200)
					SELECT @FileName = NewFileName FROM #tmpDupRecords x WHERE x.SupplierIdentifier = @dupSupplier
					DECLARE @emailSubject NVARCHAR(100) = 'Duplicate Receiving Invoices Rejected from Processing.'
					DECLARE @emailBody NVARCHAR(MAX);
					SET @emailBody = 'Identical receiving invoice numbers have been submitted previously.  If appending receiving invoices is allowed, the received date must be the same and invoice total must be different.  The following invoices were REJECTED and WILL NOT BE BILLED:' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + 
									 'RETAILER: ' + (SELECT ChainName FROM DataTrue_Main.dbo.Chains WHERE ChainIdentifier = @dupChain) + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + 
									 'SUPPLIER: ' + (SELECT Suppliername FROM DataTrue_Main.dbo.Suppliers WHERE EDIName = @dupSupplier) + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + 
									 'NEW FILE: ' + @dupFilename + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + 
									 @DupRecords

					EXEC dbo.[prSendEmailNotification_PassEmailAddresses_HTML_Logos] @emailSubject
					,@emailBody
					,'DataTrue System', 0, @contacts
					
					--UPDATE DUPLICATE ACH RECORD STATUS TO 255	
					UPDATE [DataTrue_EDI].[dbo].[Inbound846Inventory_RetailerDeliveries]
					SET RecordStatus = 255
					WHERE ReferenceIDentification IN
					(
					SELECT DISTINCT InvoiceNo
					FROM #tmpDupRecords t
					WHERE t.ChainIdentifier = @dupChain
					AND t.SupplierIdentifier = @dupSupplier
					AND t.NewFileName = FileName
					)
					AND EdiName = @dupSupplier	
					AND FileName = @dupFilename

			FETCH NEXT FROM SupplierCursor 
			INTO @dupChain, @dupSupplier, @dupFilename
			END
		END
	
	--CHECK FOR INVALID RECORDS
	CREATE TABLE #tmpInvalidRecords (ChainIdentifier VARCHAR(100), InvoiceNo VARCHAR(100), InvoiceTotal VARCHAR(100), StoreNumber VARCHAR(100), DeliveryDate VARCHAR(20), SupplierIdentifier VARCHAR(50), FileName VARCHAR(200), Details VARCHAR(500))		
	
	--INSERT INTO @TEMPINVALIDRECORDS TABLE RECORDS WITH INVOICE DETAIL TOTAL <> INVOICE HEADER REPORTED TOTAL
	INSERT INTO #tmpInvalidRecords (ChainIdentifier, InvoiceNo, InvoiceTotal, StoreNumber, DeliveryDate, SupplierIdentifier, FileName, Details)
	(
	SELECT DISTINCT
		LTRIM(RTRIM(rd.ChainName)),
		LTRIM(RTRIM(rd.ReferenceIDentification)),
		CONVERT(NUMERIC(18, 9),	
				SUM(ISNULL(rd.Qty, 0)*rd.Cost) 
				+SUM(ISNULL(rd.AlllowanceChargeAmount1, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount2, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount3, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount4, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount5, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount6, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount7, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount8, 0))
				 ),
		rd.StoreNumber,
		rd.EffectiveDate,		
		rd.EdiName,
		rd.Filename,
		'Sum of line items does not match reported total.'
	FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries rd
	INNER JOIN #tmpRecordIDs AS t
	ON t.RecordID = rd.RecordID
	WHERE rd.TotalPerInvoiceReported IS NOT NULL
	AND ReferenceIDentification NOT IN
		(
			SELECT DISTINCT InvoiceNo
			FROM #tmpDupRecords t
			WHERE t.ChainIdentifier = ChainName
			AND t.SupplierIdentifier = SupplierIdentifier
		)
	GROUP BY rd.ChainName, rd.ReferenceIDentification, rd.EffectiveDate, rd.EdiName, rd.FileName, rd.StoreNumber
	HAVING ROUND(CONVERT(NUMERIC(18, 9),	
				SUM(ISNULL(rd.Qty, 0)*rd.Cost) 
				+SUM(ISNULL(rd.AlllowanceChargeAmount1, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount2, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount3, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount4, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount5, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount6, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount7, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount8, 0))), 2) 
				<> MAX(ROUND(CONVERT(NUMERIC(18, 9), rd.TotalPerInvoiceReported), 2))
	)

	--INSERT INTO @TEMPINVALIDRECORDS TABLE RECORDS WITH UNMATCHED CHAINNAME
	INSERT INTO #tmpInvalidRecords (ChainIdentifier, InvoiceNo, InvoiceTotal, StoreNumber, DeliveryDate, SupplierIdentifier, FileName, Details)
	(
	SELECT DISTINCT
		LTRIM(RTRIM(rd.ChainName)),
		LTRIM(RTRIM(rd.ReferenceIDentification)),
		CONVERT(NUMERIC(18, 9),	
				SUM(ISNULL(rd.Qty, 0)*rd.Cost) 
				+SUM(ISNULL(rd.AlllowanceChargeAmount1, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount2, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount3, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount4, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount5, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount6, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount7, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount8, 0))
				 ),
		rd.StoreNumber,
		rd.EffectiveDate,		
		rd.EdiName,
		rd.Filename,
		'Unmatched retailer.'
	FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries rd
	INNER JOIN #tmpRecordIDs AS t
	ON t.RecordID = rd.RecordID
	WHERE ISNULL(rd.ChainName, '') = 'UNMATCHED'
	AND ReferenceIDentification NOT IN
		(
			SELECT DISTINCT InvoiceNo
			FROM #tmpDupRecords t
			WHERE t.ChainIdentifier = ChainName
			AND t.SupplierIdentifier = SupplierIdentifier
		)
	GROUP BY rd.ChainName, rd.ReferenceIDentification, rd.EffectiveDate, rd.EdiName, rd.FileName, rd.StoreNumber
	)
	
	--INSERT INTO @TEMPINVALIDRECORDS TABLE RECORDS WITH UNMATCHED SUPPLIER
	INSERT INTO #tmpInvalidRecords (ChainIdentifier, InvoiceNo, InvoiceTotal, StoreNumber, DeliveryDate, SupplierIdentifier, FileName, Details)
	(
	SELECT DISTINCT
		LTRIM(RTRIM(rd.ChainName)),
		LTRIM(RTRIM(rd.ReferenceIDentification)),
		CONVERT(NUMERIC(18, 9),	
				SUM(ISNULL(rd.Qty, 0)*rd.Cost) 
				+SUM(ISNULL(rd.AlllowanceChargeAmount1, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount2, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount3, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount4, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount5, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount6, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount7, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount8, 0))
				 ),
		rd.StoreNumber,
		rd.EffectiveDate,		
		rd.EdiName,
		rd.Filename,
		'Unmatched supplier.'
	FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries rd
	INNER JOIN #tmpRecordIDs AS t
	ON t.RecordID = rd.RecordID
	WHERE ISNULL(rd.SupplierIdentifier, '') = 'UNMATCHED'
	AND ISNULL(rd.ChainName, '') <> 'UNMATCHED'
	AND ReferenceIDentification NOT IN
		(
			SELECT DISTINCT InvoiceNo
			FROM #tmpDupRecords t
			WHERE t.ChainIdentifier = ChainName
			AND t.SupplierIdentifier = SupplierIdentifier
		)
	GROUP BY rd.ChainName, rd.ReferenceIDentification, rd.EffectiveDate, rd.EdiName, rd.FileName, rd.StoreNumber
	)
	--INSERT INTO @TEMPINVALIDRECORDS TABLE RECORDS WITH UNMATCHED STORE(S)
	INSERT INTO #tmpInvalidRecords (ChainIdentifier, InvoiceNo, InvoiceTotal, StoreNumber, DeliveryDate, SupplierIdentifier, FileName, Details)
	(
	SELECT DISTINCT
		LTRIM(RTRIM(rd.ChainName)),
		LTRIM(RTRIM(rd.ReferenceIDentification)),
		CONVERT(NUMERIC(18, 9),	
				SUM(ISNULL(rd.Qty, 0)*rd.Cost) 
				+SUM(ISNULL(rd.AlllowanceChargeAmount1, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount2, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount3, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount4, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount5, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount6, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount7, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount8, 0))
				 ),
		rd.StoreNumber,
		rd.EffectiveDate,		
		rd.EdiName,
		rd.Filename,
		'Unmatched store(s).'
	FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries rd
	INNER JOIN #tmpRecordIDs AS t
	ON t.RecordID = rd.RecordID
	WHERE ISNULL(rd.StoreNumber, '') = 'UNMATCHED'
	AND ISNULL(rd.ChainName, '') <> 'UNMATCHED'
	AND ISNULL(rd.SupplierIdentifier, '') <> 'UNMATCHED'
	AND ReferenceIDentification NOT IN
		(
			SELECT DISTINCT InvoiceNo
			FROM #tmpDupRecords t
			WHERE t.ChainIdentifier = ChainName
			AND t.SupplierIdentifier = SupplierIdentifier
		)
	GROUP BY rd.ChainName, rd.ReferenceIDentification, rd.EffectiveDate, rd.EdiName, rd.FileName, rd.StoreNumber
	)

	--INSERT INTO @TEMPINVALIDRECORDS TABLE RECORDS WITH INVALID QUANTITY VALUES
	INSERT INTO #tmpInvalidRecords (ChainIdentifier, InvoiceNo, InvoiceTotal, StoreNumber, DeliveryDate, SupplierIdentifier, FileName, Details)
	(
	SELECT DISTINCT
		LTRIM(RTRIM(rd.ChainName)),
		LTRIM(RTRIM(rd.ReferenceIDentification)),
		CONVERT(NUMERIC(18, 9),	
				SUM(ISNULL(rd.Qty, 0)*rd.Cost) 
				+SUM(ISNULL(rd.AlllowanceChargeAmount1, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount2, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount3, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount4, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount5, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount6, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount7, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount8, 0))
				 ),
		rd.StoreNumber,
		rd.EffectiveDate,
		rd.EdiName,
		rd.Filename,
		'Contains invalid quanity value(s).'
	FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries rd
	INNER JOIN #tmpRecordIDs AS t
	ON t.RecordID = rd.RecordID
	AND ReferenceIDentification IN
		(
			SELECT DISTINCT ReferenceIDentification
			FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries rd2
			INNER JOIN #tmpRecordIDs AS t2
			ON t2.RecordID = rd2.RecordID
			WHERE rd2.ChainName = rd.ChainName
			AND rd2.EffectiveDate = rd.EffectiveDate
			AND rd2.SupplierIdentifier = rd.SupplierIdentifier
			AND Qty IS NULL
		)
	AND ReferenceIDentification NOT IN
		(
			SELECT DISTINCT InvoiceNo
			FROM #tmpDupRecords t
			WHERE t.ChainIdentifier = ChainName
			AND t.SupplierIdentifier = SupplierIdentifier
		)
	GROUP BY rd.ChainName, rd.ReferenceIDentification, rd.EffectiveDate, rd.EdiName, rd.FileName, rd.StoreNumber
	)
	
	--INSERT INTO @TEMPINVALIDRECORDS TABLE RECORDS WITH NULL EFFECTIVEDATE
	INSERT INTO #tmpInvalidRecords (ChainIdentifier, InvoiceNo, InvoiceTotal, StoreNumber, DeliveryDate, SupplierIdentifier, FileName, Details)
	(
	SELECT DISTINCT
		LTRIM(RTRIM(rd.ChainName)),
		LTRIM(RTRIM(rd.ReferenceIDentification)),
		CONVERT(NUMERIC(18, 9),	
				SUM(ISNULL(rd.Qty, 0)*rd.Cost) 
				+SUM(ISNULL(rd.AlllowanceChargeAmount1, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount2, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount3, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount4, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount5, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount6, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount7, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount8, 0))
				 ),
		rd.StoreNumber,
		rd.EffectiveDate,
		rd.EdiName,
		rd.Filename,
		'All EffectiveDate values must be populated with a valid date (cannot be blank).'
	FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries rd
	INNER JOIN #tmpRecordIDs AS t
	ON t.RecordID = rd.RecordID
	AND ISNULL(rd.EffectiveDate, '') = '1/1/1900'
	AND ISNULL(rd.StoreNumber, 'UNMATCHED') <> 'UNMATCHED'
	AND ReferenceIDentification NOT IN
		(
			SELECT DISTINCT InvoiceNo
			FROM #tmpDupRecords t
			WHERE t.ChainIdentifier = ChainName
			AND t.SupplierIdentifier = EdiName
		)
	GROUP BY rd.ChainName, rd.ReferenceIDentification, rd.EffectiveDate, rd.EdiName, rd.FileName, rd.StoreNumber
	)
	
	--INSERT INTO @TEMPINVALIDRECORDS TABLE INVOICES WITH MULTIPLE STORE NUMBERS
	INSERT INTO #tmpInvalidRecords (ChainIdentifier, InvoiceNo, InvoiceTotal, StoreNumber, DeliveryDate, SupplierIdentifier, FileName, Details)
	(
	SELECT DISTINCT
		LTRIM(RTRIM(rd.ChainName)),
		LTRIM(RTRIM(rd.ReferenceIDentification)),
		CONVERT(NUMERIC(18, 9),	
				SUM(ISNULL(rd.Qty, 0)*rd.Cost) 
				+SUM(ISNULL(rd.AlllowanceChargeAmount1, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount2, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount3, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount4, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount5, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount6, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount7, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount8, 0))
				 ),
		rd.StoreNumber,
		rd.EffectiveDate,
		rd.EdiName,
		rd.Filename,
		'Invoice contains multiple stores.'
	FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries rd
	INNER JOIN #tmpRecordIDs AS t
	ON t.RecordID = rd.RecordID
	AND ReferenceIDentification NOT IN
	(
		SELECT DISTINCT InvoiceNo
		FROM #tmpDupRecords t
		WHERE t.ChainIdentifier = ChainName
		AND t.SupplierIdentifier = EdiName
	)
	WHERE rd.ReferenceIDentification <> ''
	GROUP BY rd.ChainName, rd.ReferenceIDentification, rd.EffectiveDate, rd.EdiName, rd.FileName, rd.StoreNumber
	HAVING COUNT(DISTINCT rd.StoreNumber) > 1
	)
	
	--INSERT INTO @TEMPINVALIDRECORDS TABLE INVOICES WITH MULTIPLE SALE DATES
	INSERT INTO #tmpInvalidRecords (ChainIdentifier, InvoiceNo, InvoiceTotal, StoreNumber, DeliveryDate, SupplierIdentifier, FileName, Details)
	(
	SELECT DISTINCT
		LTRIM(RTRIM(rd.ChainName)),
		LTRIM(RTRIM(rd.ReferenceIDentification)),
		CONVERT(NUMERIC(18, 9),	
				SUM(ISNULL(rd.Qty, 0)*rd.Cost) 
				+SUM(ISNULL(rd.AlllowanceChargeAmount1, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount2, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount3, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount4, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount5, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount6, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount7, 0))
				+SUM(ISNULL(rd.AlllowanceChargeAmount8, 0))
				 ),
		rd.StoreNumber,
		MIN(rd.EffectiveDate),
		rd.EdiName,
		rd.Filename,
		'Invoice contains multiple saledates.'
	FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries rd
	INNER JOIN #tmpRecordIDs AS t
	ON t.RecordID = rd.RecordID
	AND ReferenceIDentification NOT IN
	(
		SELECT DISTINCT InvoiceNo
		FROM #tmpDupRecords t
		WHERE t.ChainIdentifier = ChainName
		AND t.SupplierIdentifier = EdiName
	)
	WHERE rd.ReferenceIDentification <> ''
	GROUP BY rd.ChainName, rd.ReferenceIDentification, rd.EdiName, rd.FileName, rd.StoreNumber
	HAVING COUNT(DISTINCT rd.EffectiveDate) > 1
	)
	
	--GET INVALID RECORD COUNT
	DECLARE @InvalidCount INT
	SELECT @InvalidCount = COUNT(*) FROM #tmpInvalidRecords
	
	--SEND NOTIFICATIONS TO SUPPLIERS IF INVALID RECORDS
	IF @InvalidCount > 0
		BEGIN
		
			--INSERT INTO ACH_INVALIDINVOICES FOR INVOICES WITH SUM INVOICE DETAILS <> INVOICE HEADER REPORTED TOTAL
			INSERT INTO [DataTrue_Main].[dbo].[ACH_InvalidInvoices] (ChainID, SupplierID, InvoiceNo, TotalAmt, EffectiveDate, InvalidInvoiceType, RecordStatus, Filename)
			(
			SELECT
				(SELECT ChainID FROM [DataTrue_Main].[dbo].[Chains] WHERE ChainIdentifier = rd.ChainName),
				(SELECT SupplierID FROM [DataTrue_Main].[dbo].[Suppliers] WHERE EDIName = rd.EdiName),
				ReferenceIDentification,
				CONVERT(NUMERIC(18, 9),	
						SUM(ISNULL(rd.Qty, 0)*rd.Cost) 
						+SUM(ISNULL(rd.AlllowanceChargeAmount1, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount2, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount3, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount4, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount5, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount6, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount7, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount8, 0))
						 ),
				rd.EffectiveDate,
				35,--RECEIVING INVOICE TOTAL MISMATCH
				(SELECT CASE WHEN Actionable = 0 THEN 1 ELSE 0 END FROM DataTrue_Main.dbo.ACH_InvalidInvoiceTypes WHERE InvalidInvoiceTypeID = 35),
				rd.FileName
			FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries rd
			INNER JOIN #tmpRecordIDs AS t
			ON t.RecordID = rd.RecordID
			WHERE rd.TotalPerInvoiceReported IS NOT NULL
			AND ReferenceIDentification NOT IN
			(
				SELECT DISTINCT InvoiceNo
				FROM #tmpDupRecords t
				WHERE t.ChainIdentifier = ChainName
				AND t.SupplierIdentifier = SupplierIdentifier
			)
			GROUP BY rd.ChainName, rd.ReferenceIDentification, rd.EffectiveDate, rd.EdiName, rd.FileName
			HAVING ROUND(CONVERT(NUMERIC(18, 9),	
					SUM(ISNULL(rd.Qty, 0)*rd.Cost) 
					+SUM(ISNULL(rd.AlllowanceChargeAmount1, 0))
					+SUM(ISNULL(rd.AlllowanceChargeAmount2, 0))
					+SUM(ISNULL(rd.AlllowanceChargeAmount3, 0))
					+SUM(ISNULL(rd.AlllowanceChargeAmount4, 0))
					+SUM(ISNULL(rd.AlllowanceChargeAmount5, 0))
					+SUM(ISNULL(rd.AlllowanceChargeAmount6, 0))
					+SUM(ISNULL(rd.AlllowanceChargeAmount7, 0))
					+SUM(ISNULL(rd.AlllowanceChargeAmount8, 0))), 2) 
					<> MAX(ROUND(CONVERT(NUMERIC(18, 9), rd.TotalPerInvoiceReported), 2))
			)
			
			--INSERT INTO ACH_INVALIDINVOICES FOR INVOICES WITH UNMATCHED CHAIN
			INSERT INTO [DataTrue_Main].[dbo].[ACH_InvalidInvoices] (ChainID, SupplierID, InvoiceNo, TotalAmt, EffectiveDate, InvalidInvoiceType, RecordStatus, Filename)
			(
			SELECT
				(SELECT ChainID FROM [DataTrue_Main].[dbo].[Chains] WHERE ChainIdentifier = rd.ChainName),
				(SELECT SupplierID FROM [DataTrue_Main].[dbo].[Suppliers] WHERE EDIName = rd.EdiName),
				ReferenceIDentification,
				CONVERT(NUMERIC(18, 9),	
						SUM(ISNULL(rd.Qty, 0)*rd.Cost) 
						+SUM(ISNULL(rd.AlllowanceChargeAmount1, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount2, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount3, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount4, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount5, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount6, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount7, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount8, 0))
						 ),
				rd.EffectiveDate,
				24,--UNMATCHED RECEIVING CHAIN
				(SELECT CASE WHEN Actionable = 0 THEN 1 ELSE 0 END FROM DataTrue_Main.dbo.ACH_InvalidInvoiceTypes WHERE InvalidInvoiceTypeID = 24),
				rd.FileName
			FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries rd
			INNER JOIN #tmpRecordIDs AS t
			ON t.RecordID = rd.RecordID
			WHERE ISNULL(rd.ChainName, '') = 'UNMATCHED'
			AND ReferenceIDentification NOT IN
			(
				SELECT DISTINCT InvoiceNo
				FROM #tmpDupRecords t
				WHERE t.ChainIdentifier = ChainName
				AND t.SupplierIdentifier = SupplierIdentifier
			)
			GROUP BY rd.ChainName, rd.ReferenceIDentification, rd.EffectiveDate, rd.EdiName, rd.FileName
			)
			
			--INSERT INTO ACH_INVALIDINVOICES FOR INVOICES WITH UNMATCHED RECEIVING SUPPLIER
			INSERT INTO [DataTrue_Main].[dbo].[ACH_InvalidInvoices] (ChainID, SupplierID, InvoiceNo, TotalAmt, EffectiveDate, InvalidInvoiceType, RecordStatus, Filename)
			(
			SELECT
				(SELECT ChainID FROM [DataTrue_Main].[dbo].[Chains] WHERE ChainIdentifier = rd.ChainName),
				(SELECT SupplierID FROM [DataTrue_Main].[dbo].[Suppliers] WHERE EDIName = rd.EdiName),
				rd.ReferenceIDentification,
				CONVERT(NUMERIC(18, 9),	
						SUM(ISNULL(rd.Qty, 0)*rd.Cost) 
						+SUM(ISNULL(rd.AlllowanceChargeAmount1, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount2, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount3, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount4, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount5, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount6, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount7, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount8, 0))
						 ),
				rd.EffectiveDate,
				25,--UNMATCHED RECEIVING SUPPLIER
				(SELECT CASE WHEN Actionable = 0 THEN 1 ELSE 0 END FROM DataTrue_Main.dbo.ACH_InvalidInvoiceTypes WHERE InvalidInvoiceTypeID = 25),
				rd.FileName
			FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries rd
			INNER JOIN #tmpRecordIDs AS t
			ON t.RecordID = rd.RecordID
			WHERE ISNULL(rd.SupplierIdentifier, '') = 'UNMATCHED'
			AND ISNULL(rd.ChainName, '') <> 'UNMATCHED'
			AND ReferenceIDentification NOT IN
			(
				SELECT DISTINCT InvoiceNo
				FROM #tmpDupRecords t
				WHERE t.ChainIdentifier = ChainName
				AND t.SupplierIdentifier = SupplierIdentifier
			)
			GROUP BY rd.ChainName, rd.ReferenceIDentification, rd.EffectiveDate, rd.EdiName, rd.FileName
			)
			
			--INSERT INTO ACH_INVALIDINVOICES FOR INVOICES WITH UNMATCHED RECEIVING STORE(S)
			INSERT INTO [DataTrue_Main].[dbo].[ACH_InvalidInvoices] (ChainID, SupplierID, InvoiceNo, TotalAmt, EffectiveDate, InvalidInvoiceType, RecordStatus, Filename)
			(
			SELECT
				(SELECT ChainID FROM [DataTrue_Main].[dbo].[Chains] WHERE ChainIdentifier = rd.ChainName),
				(SELECT SupplierID FROM [DataTrue_Main].[dbo].[Suppliers] WHERE EDIName = rd.EdiName),
				rd.ReferenceIDentification,
				CONVERT(NUMERIC(18, 9),	
						SUM(ISNULL(rd.Qty, 0)*rd.Cost) 
						+SUM(ISNULL(rd.AlllowanceChargeAmount1, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount2, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount3, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount4, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount5, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount6, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount7, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount8, 0))
						 ),
				rd.EffectiveDate,
				30,--UNMATCHED RECEIVING STORE(S)
				(SELECT CASE WHEN Actionable = 0 THEN 1 ELSE 0 END FROM DataTrue_Main.dbo.ACH_InvalidInvoiceTypes WHERE InvalidInvoiceTypeID = 30),
				rd.FileName
			FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries rd
			INNER JOIN #tmpRecordIDs AS t
			ON t.RecordID = rd.RecordID
			WHERE ISNULL(rd.StoreNumber, '') = 'UNMATCHED'
			AND ISNULL(rd.ChainName, '') <> 'UNMATCHED'
			AND ISNULL(rd.SupplierIdentifier, '') <> 'UNMATCHED'		
			AND ReferenceIDentification NOT IN
			(
				SELECT DISTINCT InvoiceNo
				FROM #tmpDupRecords t
				WHERE t.ChainIdentifier = ChainName
				AND t.SupplierIdentifier = SupplierIdentifier
			)
			GROUP BY rd.ChainName, rd.ReferenceIDentification, rd.EffectiveDate, rd.EdiName, rd.FileName
			)
		
			--INSERT INTO ACH_INVALIDINVOICES FOR INVALID/MISSING QTY
			INSERT INTO [DataTrue_Main].[dbo].[ACH_InvalidInvoices] (ChainID, SupplierID, InvoiceNo, TotalAmt, EffectiveDate, InvalidInvoiceType, RecordStatus, Filename)
			(
			SELECT
				(SELECT ChainID FROM [DataTrue_Main].[dbo].[Chains] WHERE ChainIdentifier = rd.ChainName),
				(SELECT SupplierID FROM [DataTrue_Main].[dbo].[Suppliers] WHERE EDIName = rd.EdiName),
				ReferenceIDentification,
				CONVERT(NUMERIC(18, 9),	
						SUM(ISNULL(rd.Qty, 0) *rd.Cost) 
						+SUM(ISNULL(rd.AlllowanceChargeAmount1, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount2, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount3, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount4, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount5, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount6, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount7, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount8, 0))
						 ),
				rd.EffectiveDate,
				31,--INVALID RECEIVING QUANTITY VALUE(S)
				(SELECT CASE WHEN Actionable = 0 THEN 1 ELSE 0 END FROM DataTrue_Main.dbo.ACH_InvalidInvoiceTypes WHERE InvalidInvoiceTypeID = 31),
				rd.FileName
			FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries rd
			INNER JOIN #tmpRecordIDs AS t
			ON t.RecordID = rd.RecordID
			AND ReferenceIDentification NOT IN
				(
					SELECT DISTINCT InvoiceNo
					FROM #tmpDupRecords t
					WHERE t.ChainIdentifier = ChainName
					AND t.SupplierIdentifier = SupplierIdentifier
				)
			AND ReferenceIDentification IN
			(
				SELECT DISTINCT ReferenceIDentification
				FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries rd2
				INNER JOIN #tmpRecordIDs AS t2
				ON t2.RecordID = rd2.RecordID
				WHERE rd2.ChainName = rd.ChainName
				AND rd2.EffectiveDate = rd.EffectiveDate
				AND rd2.SupplierIdentifier = rd.SupplierIdentifier
				AND Qty IS NULL
			)
			GROUP BY rd.ChainName, rd.ReferenceIDentification, rd.EffectiveDate, rd.EdiName, rd.FileName
			)
			
			--INSERT INTO ACH_INVALIDINVOICES FOR INVOICES WITH NULL EFFECTIVE DATE
			INSERT INTO [DataTrue_Main].[dbo].[ACH_InvalidInvoices] (ChainID, SupplierID, InvoiceNo, TotalAmt, EffectiveDate, InvalidInvoiceType, RecordStatus, Filename)
			(
			SELECT
				(SELECT ChainID FROM [DataTrue_Main].[dbo].[Chains] WHERE ChainIdentifier = rd.ChainName),
				(SELECT SupplierID FROM [DataTrue_Main].[dbo].[Suppliers] WHERE EDIName = rd.EdiName),
				ReferenceIDentification,
				CONVERT(NUMERIC(18, 9),	
						SUM(ISNULL(rd.Qty, 0)*rd.Cost) 
						+SUM(ISNULL(rd.AlllowanceChargeAmount1, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount2, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount3, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount4, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount5, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount6, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount7, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount8, 0))
						 ),
				rd.EffectiveDate,
				35,--MISSING RECEIVING EFFECTIVEDATE
				(SELECT CASE WHEN Actionable = 0 THEN 1 ELSE 0 END FROM DataTrue_Main.dbo.ACH_InvalidInvoiceTypes WHERE InvalidInvoiceTypeID = 35),
				rd.FileName
			FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries rd
			INNER JOIN #tmpRecordIDs AS t
			ON t.RecordID = rd.RecordID
			AND ISNULL(rd.EffectiveDate, '') = '1/1/1900'
			AND ISNULL(rd.StoreNumber, 'UNMATCHED') <> 'UNMATCHED'
			AND ReferenceIDentification NOT IN
			(
				SELECT DISTINCT InvoiceNo
				FROM #tmpDupRecords t
				WHERE t.ChainIdentifier = ChainName
				AND t.SupplierIdentifier = SupplierIdentifier
			)
			GROUP BY rd.ChainName, rd.ReferenceIDentification, rd.EffectiveDate, rd.EdiName, rd.FileName
			)
			
			--INSERT INTO ACH_INVALIDINVOICES FOR INVOICES WITH MULITPLE STORE NUMBERS
			INSERT INTO [DataTrue_Main].[dbo].[ACH_InvalidInvoices] (ChainID, SupplierID, InvoiceNo, TotalAmt, EffectiveDate, InvalidInvoiceType, RecordStatus, Filename)
			(
			SELECT
				(SELECT ChainID FROM [DataTrue_Main].[dbo].[Chains] WHERE ChainIdentifier = rd.ChainName),
				(SELECT SupplierID FROM [DataTrue_Main].[dbo].[Suppliers] WHERE EDIName = rd.EdiName),
				ReferenceIDentification,
				CONVERT(NUMERIC(18, 9),	
						SUM(ISNULL(rd.Qty, 0)*rd.Cost) 
						+SUM(ISNULL(rd.AlllowanceChargeAmount1, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount2, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount3, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount4, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount5, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount6, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount7, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount8, 0))
						 ),
				rd.EffectiveDate,
				33,--MULTIPLE RECEIVING STORE NUMBERS
				(SELECT CASE WHEN Actionable = 0 THEN 1 ELSE 0 END FROM DataTrue_Main.dbo.ACH_InvalidInvoiceTypes WHERE InvalidInvoiceTypeID = 33),
				rd.FileName
			FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries rd
			INNER JOIN #tmpRecordIDs AS t
			ON t.RecordID = rd.RecordID
			AND ReferenceIDentification NOT IN
			(
				SELECT DISTINCT InvoiceNo
				FROM #tmpDupRecords t
				WHERE t.ChainIdentifier = ChainName
				AND t.SupplierIdentifier = SupplierIdentifier
			)
			WHERE rd.ReferenceIDentification <> ''
			GROUP BY rd.ChainName, rd.ReferenceIDentification, rd.EffectiveDate, rd.EdiName, rd.FileName
			HAVING COUNT(DISTINCT rd.StoreNumber) > 1
			)
			
			--INSERT INTO ACH_INVALIDINVOICES FOR INVOICES WITH MULITPLE SALE DATES
			INSERT INTO [DataTrue_Main].[dbo].[ACH_InvalidInvoices] (ChainID, SupplierID, InvoiceNo, TotalAmt, EffectiveDate, InvalidInvoiceType, RecordStatus, Filename)
			(
			SELECT
				(SELECT ChainID FROM [DataTrue_Main].[dbo].[Chains] WHERE ChainIdentifier = rd.ChainName),
				(SELECT SupplierID FROM [DataTrue_Main].[dbo].[Suppliers] WHERE EDIName = rd.EdiName),
				ReferenceIDentification,
				CONVERT(NUMERIC(18, 9),	
						SUM(ISNULL(rd.Qty, 0)*rd.Cost) 
						+SUM(ISNULL(rd.AlllowanceChargeAmount1, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount2, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount3, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount4, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount5, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount6, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount7, 0))
						+SUM(ISNULL(rd.AlllowanceChargeAmount8, 0))
						 ),
				MIN(rd.EffectiveDate),
				34,--MULTIPLE SALE DATES
				(SELECT CASE WHEN Actionable = 0 THEN 1 ELSE 0 END FROM DataTrue_Main.dbo.ACH_InvalidInvoiceTypes WHERE InvalidInvoiceTypeID = 34),
				rd.FileName
			FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries rd
			INNER JOIN #tmpRecordIDs AS t
			ON t.RecordID = rd.RecordID
			AND ReferenceIDentification NOT IN
			(
				SELECT DISTINCT InvoiceNo
				FROM #tmpDupRecords t
				WHERE t.ChainIdentifier = ChainName
				AND t.SupplierIdentifier = SupplierIdentifier
			)
			WHERE rd.ReferenceIDentification <> ''
			GROUP BY rd.ChainName, rd.ReferenceIDentification, rd.EdiName, rd.FileName
			HAVING COUNT(DISTINCT rd.EffectiveDate) > 1
			)
		
			UPDATE #tmpInvalidRecords
			SET InvoiceNo = InvoiceNo + REPLICATE(' ', (10 - LEN(InvoiceNo)))
			WHERE LEN(InvoiceNo) < 11
			
			UPDATE #tmpInvalidRecords
			SET StoreNumber = StoreNumber + REPLICATE(' ', (10 - LEN(StoreNumber)))
			WHERE LEN(StoreNumber) < 11
	
			UPDATE #tmpInvalidRecords
			SET InvoiceTotal = CONVERT(VARCHAR(100), CONVERT(MONEY,InvoiceTotal)) + REPLICATE(' ', (13 - LEN(CONVERT(MONEY, InvoiceTotal))))
			WHERE LEN(CONVERT(MONEY, InvoiceTotal)) < 14
			
			--ADD REPORTING LOCATION TO UNMATCHED CHAIN/STORES
			UPDATE t
			SET t.Details += ' Reporting Location: ' + t2.ReportingLocation
			FROM #tmpInvalidRecords AS t
			INNER JOIN
			(
			SELECT DISTINCT ReportingLocation, ChainName, EdiName, ReferenceIDentification, EffectiveDate
			FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries rd
			INNER JOIN #tmpRecordIDs AS t
			ON t.RecordID = rd.RecordID
			WHERE ISNULL(ReportingLocation, '') <> ''
			) AS t2 
			ON  t.ChainIdentifier = t2.ChainName
			AND t.SupplierIdentifier = t2.EdiName
			AND t.InvoiceNo = LTRIM(RTRIM(t2.ReferenceIDentification))
			AND t.DeliveryDate = t2.EffectiveDate
			WHERE (LTRIM(RTRIM(UPPER(ISNULL(t.ChainIdentifier, 'UNMATCHED')))) IN ('', 'UNMATCHED') OR LTRIM(RTRIM(UPPER(ISNULL(t.StoreNumber, 'UNMATCHED')))) IN ('', 'UNMATCHED'))	
			
			UPDATE t
			SET t.Details += ' Reported DUNS: ' + t2.SupplierDuns
			FROM #tmpInvalidRecords AS t
			INNER JOIN
			(
			SELECT DISTINCT SupplierDuns, ChainName, EdiName, ReferenceIDentification, EffectiveDate
			FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries rd
			INNER JOIN #tmpRecordIDs AS t
			ON t.RecordID = rd.RecordID
			WHERE ISNULL(SupplierDuns, '') <> ''
			) AS t2 
			ON  t.ChainIdentifier = t2.ChainName
			AND t.SupplierIdentifier = t2.EdiName
			AND t.InvoiceNo = LTRIM(RTRIM(t2.ReferenceIDentification))
			AND t.DeliveryDate = t2.EffectiveDate
			WHERE t.SupplierIdentifier = 'UNMATCHED'
			
			UPDATE t
			SET t.Details += ' Reported Total: ' + CONVERT(VARCHAR(150), CONVERT(MONEY, t2.TotalPerInvoiceReported))
			FROM #tmpInvalidRecords AS t
			INNER JOIN
			(
			SELECT DISTINCT ReportingLocation, ChainName, EdiName, ReferenceIDentification, EffectiveDate, TotalPerInvoiceReported
			FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries rd
			INNER JOIN #tmpRecordIDs AS t
			ON t.RecordID = rd.RecordID
			WHERE TotalPerInvoiceReported IS NOT NULL
			) AS t2 
			ON  t.ChainIdentifier = t2.ChainName
			AND t.SupplierIdentifier = t2.EdiName
			AND t.InvoiceNo = LTRIM(RTRIM(t2.ReferenceIDentification))
			AND t.DeliveryDate = t2.EffectiveDate
			WHERE t.Details = 'Sum of line items does not match reported total.'
			
			DECLARE @invalidChain VARCHAR(50)
			DECLARE @invalidChainName VARCHAR(120)
			DECLARE @invalidSupplier VARCHAR(50)
			DECLARE @invalidFilename VARCHAR(120)
			DECLARE InvalidSupplierCursor CURSOR FAST_FORWARD LOCAL FOR 
			SELECT DISTINCT ChainIdentifier, SupplierIdentifier, FileName
			FROM #tmpInvalidRecords
			ORDER BY ChainIdentifier, SupplierIdentifier, FileName

			OPEN InvalidSupplierCursor

			FETCH NEXT FROM InvalidSupplierCursor 
			INTO @invalidChain, @invalidSupplier, @invalidFilename
			
			WHILE @@FETCH_STATUS = 0
				BEGIN
			
					DECLARE @InvalidRecords VARCHAR(MAX)
					SET @InvalidRecords = 'INVOICE NO' + CHAR(9) + 'INVOICE TOTAL' + CHAR(9) + CHAR(9) + 'STORE NO   ' + CHAR(9) + 'DELIVERY DATE' + CHAR(9) + CHAR(9) + 'DETAILS' + CHAR(13) + CHAR(10)	
										
					SELECT @InvalidRecords += x.InvoiceNo + CHAR(9) + x.InvoiceTotal + CHAR(9) + CHAR(9) + x.StoreNumber + CHAR(9) + REPLACE(CONVERT(VARCHAR(20), REPLACE(x.DeliveryDate, 'Jan  1 1900', 'UNKNOWN')), '12:00AM', '') + CHAR(9) + CHAR(9) + x.Details +CHAR(13) + CHAR(10)
					FROM #tmpInvalidRecords x
					WHERE x.SupplierIdentifier = @invalidSupplier
					AND x.ChainIdentifier = @invalidChain
					AND x.FileName = @invalidFilename
					ORDER BY x.InvoiceNo, x.Details
					
					DECLARE @InvalidTotal VARCHAR(100)
					
					--SELECT @InvalidTotal = SUM(CONVERT(NUMERIC(18, 9),InvoiceTotal))
					SELECT @InvalidTotal = SUM(CONVERT(NUMERIC(18, 9),t.InvoiceTotal))
					FROM 
					(
					SELECT DISTINCT x.InvoiceNo, CONVERT(NUMERIC(18, 9),InvoiceTotal) AS InvoiceTotal
					FROM #tmpInvalidRecords x
					WHERE x.SupplierIdentifier = @invalidsupplier
					AND x.ChainIdentifier = @invalidchain
					AND x.FileName = @invalidFilename
					) AS t
					
					SET @InvalidRecords = 'TOTAL AMOUNT: $' + CONVERT(VARCHAR(50), CONVERT(MONEY, @InvalidTotal)) + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + @InvalidRecords
				
					DECLARE @invalidcontacts VARCHAR(MAX) = ''
				
					SELECT @invalidcontacts += Email + '; '
					FROM [DataTrue_Main].[dbo].[ContactInfo] AS c WITH (NOLOCK)
					WHERE 1 = 1
					AND c.OwnerEntityID = (SELECT ChainID FROM [DataTrue_Main].[dbo].[Chains] WHERE ChainIdentifier = @invalidChain)
					AND c.ReceiveACHNotifications = 1
					
					SET @invalidcontacts = @invalidcontacts + 'edi@icucsolutions.com;'
					IF ISNULL(@invalidcontacts, '') = ''
						BEGIN
							SET @invalidcontacts = 'edi@icucsolutions.com;'
						END
					IF (SELECT IsRegulated FROM Suppliers WHERE EDIName = @invalidSupplier) = 1
						BEGIN
							SET @invalidcontacts = @invalidcontacts + 'regulated@icucsolutions.com;'
						END
					ELSE IF (SELECT 1 FROM Memberships WHERE MembershipTypeID = 14
						     AND OrganizationEntityID = (SELECT ChainID FROM DataTrue_Main.dbo.Chains WHERE ChainIdentifier = @invalidSupplier)
						     AND MemberEntityID = (SELECT SupplierID FROM DataTrue_Main.dbo.Suppliers WHERE EDIName = @invalidSupplier)) = 1
						BEGIN
							SET @invalidcontacts = @invalidcontacts + 'dataexchange@profdata.com;'
						END
					ELSE IF (SELECT 1 FROM Memberships WHERE MembershipTypeID = 14
						     AND MemberEntityID = (SELECT SupplierID FROM DataTrue_Main.dbo.Suppliers WHERE EDIName = @invalidSupplier)) = 1
						     AND @invalidChain = 'UNMATCHED'
						BEGIN
							SET @invalidcontacts = @invalidcontacts + 'dataexchange@profdata.com;'
						END
					
					
					--FOR TESTING
					--SET @invalidcontacts = 'william.heine@icucsolutions.com'
					------------
					DECLARE @invalidemailSubject NVARCHAR(100) = 'Invalid Receiving Invoices found during processing.'
					DECLARE @invalidemailBody NVARCHAR(MAX);
					SET @invalidemailBody = 'The following Retailer Receiving records have failed validation and have been rejected.  See details for additional information.' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + 
									 'RETAILER: ' + (SELECT ChainName FROM DataTrue_Main.dbo.Chains WHERE ChainIdentifier = @invalidchain) + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + 
									 'SUPPLIER: ' + (SELECT Suppliername FROM DataTrue_Main.dbo.Suppliers WHERE EDIName = @invalidsupplier) + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + 
									 'FILE: ' + @invalidFileName + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + 
									 @InvalidRecords
									 
					EXEC dbo.[prSendEmailNotification_PassEmailAddresses_HTML_Logos] @invalidemailSubject
					,@invalidemailBody
					,'DataTrue System', 0, @invalidcontacts
					
					--UPDATE INVALID ACH RECORD STATUS TO 255
					UPDATE rd
					SET RecordStatus = 255
					FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries rd
					INNER JOIN #tmpRecordIDs AS t
					ON t.RecordID = rd.RecordID
					WHERE ReferenceIDentification IN
					(
						SELECT DISTINCT InvoiceNo
						FROM #tmpInvalidRecords t
						WHERE t.ChainIdentifier = @invalidchain
						AND t.SupplierIdentifier = @invalidsupplier
						AND t.FileName = @invalidFilename
					)
					AND ReferenceIDentification NOT IN
					(
						SELECT DISTINCT InvoiceNo
						FROM #tmpDupRecords t
						WHERE t.ChainIdentifier = ChainName
						AND t.SupplierIdentifier = SupplierIdentifier
					)
			FETCH NEXT FROM InvalidSupplierCursor 
			INTO @invalidChain, @invalidSupplier, @invalidFilename
			END
		END

--UPDATE APPROVAL RECORD STATUS TO 255 WHERE NEW RECORDS ARE REPLACING ALL REJECTED INVOICE RECORDS.
UPDATE rd2
SET rd2.RecordStatus = 255
FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries rd
INNER JOIN  [DataTrue_EDI].[dbo].[Inbound846Inventory_RetailerDeliveries_Approval] AS rd2
ON LTRIM(RTRIM(rd.ChainName)) = LTRIM(RTRIM(rd2.ChainName))
AND rd.SupplierIdentifier = rd2.SupplierIdentifier
AND rd.EffectiveDate = rd2.EffectiveDate
AND rd.ReferenceIDentification = rd2.ReferenceIDentification
INNER JOIN #tmpRecordIDs AS t
ON t.RecordID = rd.RecordID
WHERE rd2.RecordStatus = 3
AND NOT EXISTS
(
 SELECT ReferenceIDentification, SupplierIdentifier, EffectiveDate, RecordStatus
 FROM [DataTrue_EDI].[dbo].[Inbound846Inventory_ACH_Approval] AS i3 WITH (NOLOCK)
 WHERE LTRIM(RTRIM(i3.ChainName)) = LTRIM(RTRIM(rd2.ChainName))
 AND i3.SupplierIdentifier = rd2.SupplierIdentifier
 AND i3.EffectiveDate = rd2.EffectiveDate
 AND i3.RecordStatus IN (3, 255)
)

--CHECK FOR NOTIFICATION ONLY RECORDS
CREATE TABLE #tmpNoteRecords (ChainIdentifier VARCHAR(100), InvoiceNo VARCHAR(100), StoreNumber VARCHAR(100), InvoiceTotal VARCHAR(100), DeliveryDate VARCHAR(20), DueDate VARCHAR(20), SupplierIdentifier VARCHAR(50), FileName VARCHAR(200), Details VARCHAR(500))		

--INSERT INTO @tmpNotificationRecords TABLE RECORDS WITH INVALID CHECKDIGITS
INSERT INTO #tmpNoteRecords (ChainIdentifier, InvoiceNo, InvoiceTotal, StoreNumber, DeliveryDate, SupplierIdentifier, FileName, Details)
(
SELECT DISTINCT
	LTRIM(RTRIM(rd.ChainName)),
	LTRIM(RTRIM(rd.ReferenceIDentification)),
	CONVERT(NUMERIC(18, 9),	
			SUM(ISNULL(rd.Qty, 0)*rd.Cost) 
			+SUM(ISNULL(rd.AlllowanceChargeAmount1, 0))
			+SUM(ISNULL(rd.AlllowanceChargeAmount2, 0))
			+SUM(ISNULL(rd.AlllowanceChargeAmount3, 0))
			+SUM(ISNULL(rd.AlllowanceChargeAmount4, 0))
			+SUM(ISNULL(rd.AlllowanceChargeAmount5, 0))
			+SUM(ISNULL(rd.AlllowanceChargeAmount6, 0))
			+SUM(ISNULL(rd.AlllowanceChargeAmount7, 0))
			+SUM(ISNULL(rd.AlllowanceChargeAmount8, 0))
			 ),
	rd.StoreNumber,
	rd.EffectiveDate,
	rd.EdiName,
	rd.Filename,
	'Contains UPC(s)/EAN(s) that have invalid checkdigit which will not be added to Harmony but will be returned on remittance.'
FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries rd
INNER JOIN #tmpRecordIDs AS t
ON t.RecordID = rd.RecordID
WHERE ISNULL(RawProductIdentifier, '') <> ''
AND (SELECT ISNULL(bcs.RejectInvalidUPCs, 0)
	 FROM DataTrue_Main.dbo.BillingControl AS bc
	 INNER JOIN DataTrue_Main.dbo.BillingControl_SUP AS bcs
	 ON bc.BillingControlID = bcs.BillingControlID
	 WHERE ChainID = (SELECT ChainID
					  FROM [DataTrue_Main].[dbo].[Chains]
					  WHERE ChainIdentifier = rd.ChainName)
	 AND SupplierID = 0
	 AND UPPER(BillingControlFrequency) = 'DAILY'
	 AND BusinessTypeID = 2) = 0
AND ReferenceIDentification IN
	(
		SELECT DISTINCT ReferenceIDentification
		FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries t2
		INNER JOIN #tmpRecordIDs AS t3
		ON t2.RecordID = t3.RecordID
		WHERE t2.ChainName = rd.ChainName
		AND t2.EffectiveDate = rd.EffectiveDate
		AND t2.SupplierIdentifier = rd.SupplierIdentifier
		AND t2.FileName = rd.FileName
		AND RIGHT(t2.RawProductIdentifier, 1) <> DataTrue_EDI.dbo.fnGetCheckDigitEAN(LEFT(t2.RawProductIdentifier, LEN(t2.RawProductIdentifier) - 1))
		AND ISNUMERIC(t2.RawProductIdentifier) = 1
		AND LEN(ISNULL(t2.RawProductIdentifier, '')) > 11
		AND Datatrue_EDI.dbo.fnIsValidUPC(t2.RawProductIdentifier) <> 0
	)
AND ReferenceIDentification NOT IN
	(
		SELECT DISTINCT InvoiceNo
		FROM #tmpDupRecords t
		WHERE t.ChainIdentifier = ChainName
		AND t.SupplierIdentifier = SupplierIdentifier
	)
AND ReferenceIDentification NOT IN
(
	SELECT DISTINCT InvoiceNo
	FROM #tmpInvalidRecords t
	WHERE t.ChainIdentifier = ChainName
	AND t.DeliveryDate = EffectiveDate
	AND t.SupplierIdentifier = SupplierIdentifier
)
GROUP BY rd.ChainName, rd.ReferenceIDentification, rd.EffectiveDate, rd.EdiName, rd.FileName, rd.StoreNumber
)	

--INSERT INTO @tmpNotificationRecords TABLE RECORDS WITH INVALID UPCS
INSERT INTO #tmpNoteRecords (ChainIdentifier, InvoiceNo, InvoiceTotal, StoreNumber, DeliveryDate, SupplierIdentifier, FileName, Details)
(
SELECT DISTINCT
LTRIM(RTRIM(rd.ChainName)),
LTRIM(RTRIM(rd.ReferenceIDentification)),
CONVERT(NUMERIC(18, 9),	
		SUM(ISNULL(rd.Qty, 0)*rd.Cost) 
		+SUM(ISNULL(rd.AlllowanceChargeAmount1, 0))
		+SUM(ISNULL(rd.AlllowanceChargeAmount2, 0))
		+SUM(ISNULL(rd.AlllowanceChargeAmount3, 0))
		+SUM(ISNULL(rd.AlllowanceChargeAmount4, 0))
		+SUM(ISNULL(rd.AlllowanceChargeAmount5, 0))
		+SUM(ISNULL(rd.AlllowanceChargeAmount6, 0))
		+SUM(ISNULL(rd.AlllowanceChargeAmount7, 0))
		+SUM(ISNULL(rd.AlllowanceChargeAmount8, 0))
		 ),
rd.StoreNumber,
rd.EffectiveDate,
rd.EdiName,
rd.Filename,
'Contains invalid UPC/EAN(s) which will not be added to Harmony but will be returned on remittance.'
FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries rd
INNER JOIN #tmpRecordIDs AS t
ON t.RecordID = rd.RecordID
AND ISNULL(RawProductIdentifier, '') <> ''
AND (SELECT ISNULL(bcs.RejectInvalidUPCs, 0)
	 FROM DataTrue_Main.dbo.BillingControl AS bc
	 INNER JOIN DataTrue_Main.dbo.BillingControl_SUP AS bcs
	 ON bc.BillingControlID = bcs.BillingControlID
	 WHERE ChainID = (SELECT ChainID
					  FROM [DataTrue_Main].[dbo].[Chains]
					  WHERE ChainIdentifier = rd.ChainName)
	 AND SupplierID = 0
	 AND UPPER(BillingControlFrequency) = 'DAILY'
	 AND BusinessTypeID = 2) = 0
AND DataTrue_EDI.dbo.fnIsValidUPC(RawProductIdentifier) = 0
AND ReferenceIDentification NOT IN
(
	SELECT DISTINCT InvoiceNo
	FROM #tmpDupRecords t
	WHERE t.ChainIdentifier = ChainName
	AND t.SupplierIdentifier = SupplierIdentifier
)
AND ReferenceIDentification NOT IN
(
	SELECT DISTINCT InvoiceNo
	FROM #tmpInvalidRecords t
	WHERE t.ChainIdentifier = ChainName
	AND t.DeliveryDate = EffectiveDate
	AND t.SupplierIdentifier = SupplierIdentifier
	AND t.FileName = FileName
)
GROUP BY rd.ChainName, rd.ReferenceIDentification, rd.EffectiveDate, rd.EdiName, rd.FileName, rd.StoreNumber
)

DECLARE @NoteCount INT
SET @NoteCount = (SELECT COUNT(*) FROM #tmpNoteRecords)

IF @NoteCount > 0
	BEGIN
	
		UPDATE #tmpNoteRecords
		SET InvoiceNo = InvoiceNo + REPLICATE(' ', (10 - LEN(InvoiceNo)))
		WHERE LEN(InvoiceNo) < 11
		
		UPDATE #tmpNoteRecords
		SET StoreNumber = StoreNumber + REPLICATE(' ', (10 - LEN(StoreNumber)))
		WHERE LEN(StoreNumber) < 11

		UPDATE #tmpNoteRecords
		SET InvoiceTotal = CONVERT(VARCHAR(100), CONVERT(MONEY,InvoiceTotal)) + REPLICATE(' ', (13 - LEN(CONVERT(MONEY, InvoiceTotal))))
		WHERE LEN(CONVERT(MONEY, InvoiceTotal)) < 14
		
		DECLARE @noteChain VARCHAR(50)
		DECLARE @noteSupplier VARCHAR(50)
		DECLARE @noteFilename VARCHAR(120)
		DECLARE NoteSupplierCursor CURSOR FAST_FORWARD LOCAL FOR 
		SELECT DISTINCT ChainIdentifier, SupplierIdentifier, FileName
		FROM #tmpNoteRecords
		ORDER BY ChainIdentifier, SupplierIdentifier, FileName

		OPEN NoteSupplierCursor

		FETCH NEXT FROM NoteSupplierCursor 
		INTO @noteChain, @noteSupplier, @noteFilename
		
		WHILE @@FETCH_STATUS = 0
			BEGIN
		
				DECLARE @NoteRecords VARCHAR(MAX)
				SET @NoteRecords = 'INVOICE NO' + CHAR(9) + 'INVOICE TOTAL' + CHAR(9) + CHAR(9) + 'STORE NO   ' + CHAR(9) + 'DELIVERY DATE' + CHAR(9) + 'DETAILS' + CHAR(13) + CHAR(10)	
				
				SELECT @NoteRecords += x.InvoiceNo + CHAR(9) + x.InvoiceTotal + CHAR(9) + CHAR(9) + x.StoreNumber + CHAR(9) + REPLACE(CONVERT(VARCHAR(20), x.DeliveryDate), '12:00AM', '') + CHAR(9) + x.Details + CHAR(13) + CHAR(10)
				FROM #tmpNoteRecords x
				WHERE x.SupplierIdentifier = @noteSupplier
				AND x.ChainIdentifier = @noteChain
				AND x.FileName = @noteFilename
				ORDER BY x.InvoiceNo, x.Details
				
				DECLARE @NoteTotal VARCHAR(100)
				
				SELECT @NoteTotal = SUM(CONVERT(NUMERIC(18, 9),t.InvoiceTotal))
				FROM 
				(
				SELECT DISTINCT InvoiceNo, CONVERT(NUMERIC(18, 9),InvoiceTotal) AS InvoiceTotal
				FROM #tmpNoteRecords x
				WHERE x.SupplierIdentifier = @noteSupplier
				AND x.ChainIdentifier = @noteChain
				AND x.FileName = @noteFilename
				) AS t
				
				SET @NoteRecords = 'TOTAL AMOUNT: $' + CONVERT(VARCHAR(50), CONVERT(MONEY, @NoteTotal)) + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + @NoteRecords
				
				DECLARE @noteContacts VARCHAR(MAX) = ''
			
				SELECT @noteContacts += Email + '; '
				FROM [DataTrue_Main].[dbo].[ContactInfo] AS c WITH (NOLOCK)
				WHERE c.OwnerEntityID = (SELECT ChainID FROM [DataTrue_Main].[dbo].[Chains] WHERE ChainIdentifier = @noteChain)
				AND c.ReceiveACHNotifications = 1
				
				SET @noteContacts = @noteContacts + 'edi@icucsolutions.com;'
				IF ISNULL(@noteContacts, '') = ''
					BEGIN
						SET @noteContacts = 'edi@icucsolutions.com; '
					END
				IF (SELECT IsRegulated FROM Suppliers WHERE EDIName = @noteSupplier) = 1
						BEGIN
							SET @noteContacts = @noteContacts + 'regulated@icucsolutions.com;'
						END
				ELSE IF (SELECT 1 FROM Memberships WHERE MembershipTypeID = 14
					     AND OrganizationEntityID = (SELECT ChainID FROM DataTrue_Main.dbo.Chains WHERE ChainIdentifier = @noteChain)
					     AND MemberEntityID = (SELECT SupplierID FROM DataTrue_Main.dbo.Suppliers WHERE EDIName = @noteSupplier)) = 1
					BEGIN
						SET @noteContacts = @noteContacts + 'dataexchange@profdata.com;'
					END
				--FOR TESTING
				--SET @noteContacts = 'william.heine@icucsolutions.com'
				------------
				DECLARE @noteemailSubject NVARCHAR(100) = 'Invoice(s) Require Notification.'
				DECLARE @noteemailBody NVARCHAR(MAX);
				SET @noteemailBody = 'The following invoices require us to notify you.  See details for additional information.  These invoices WILL BE processed/marked pending approval.' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) +
											'RETAILER: ' + (SELECT ChainName FROM DataTrue_Main.dbo.Chains WHERE ChainIdentifier = @noteChain) + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + 
											'SUPPLIER: ' + (SELECT Suppliername FROM DataTrue_Main.dbo.Suppliers WHERE EDIName = @noteSupplier) + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + 
											'FILE: ' + @noteFilename + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + 
											@NoteRecords
						 					
				--EXEC dbo.[prSendEmailNotification_PassEmailAddresses_HTML_Logos] @noteemailSubject
				--,@noteemailBody
				--,'DataTrue System', 0, @noteContacts

		FETCH NEXT FROM NoteSupplierCursor
		INTO @noteChain, @noteSupplier, @noteFilename
		END
	END

--=======================================
-- INSERT STATEMENTS (PASSED VALIDATION)
--=======================================


--INSERT INTO DataTrue_Main.dbo.UploadedFiles
--(
-- [PersonId]
--,[FileName]
--,[FileType]
--,[FileLocation]
--,[FileSize]
--,[TimeStamp]
--,[ChainID]
--,[SupplierID]
--,[FileStatus]
--,[UploadSource]
--,[OriginalFileName]
--)
--SELECT DISTINCT
-- 63600--PersonID
--,a.Filename--FileName
--,'SupplierInvoices'--FileType--,RIGHT(a.Filename, LEN(a.Filename) - CHARINDEX('.', a.Filename))--FileType
--,(SELECT Value FROM DataTrue_EDI.dbo.BusinessRules_byPartner WHERE PartnerID = a.SupplierIdentifier AND BRID = 3)--FileLocation
--,'N/A'--FileSize
--,TimeStamp--TimeStamp
--,0--ChainID
--,(SELECT SupplierID FROM Suppliers WHERE EDIName = a.SupplierIdentifier)--SupplierID
--,''--FileStatus
--,'FTP'--UploadSource
--,a.FileName--OriginalFileName
--FROM DataTrue_EDI.dbo.Inbound846Inventory_ACH a
--INNER JOIN @tmpFilesToMove b
--ON b.FileName = a.FileName
--WHERE a.RecordStatus IN (0,4,5)
--AND b.FileName NOT IN
--(
--	SELECT DISTINCT FileName FROM UploadedFiles f
--	WHERE f.ChainID = (SELECT ChainID FROM DataTrue_Main.dbo.Chains WHERE ChainIdentifier = a.ChainName)
--	AND f.SupplierID = (SELECT SupplierID FROM DataTrue_Main.dbo.Suppliers WHERE EDIName = a.EdiName)
--	AND f.FileName <> 'InboundInventory_Web'
--)

INSERT INTO [DataTrue_EDI].[dbo].[Inbound846Inventory_RetailerDeliveries_Approval]
(
 [RecordID]
,[ChainName]
,[PurposeCode]
,[ReportingCode]
,[ReportingMethod]
,[ReportingLocation]
,[StoreDuns]
,[ReferenceIDentification]
,[ProductQualifier]
,[ProductIdentifier]
,[BrANDIdentifier]
,[SupplierDuns]
,[SupplierIdentifier]
,[StoreNumber]
,[UnitMeasure]
,[QtyLevel]
,[Qty]
,[Cost]
,[Retail]
,[EffectiveDate]
,[EffectiveTime]
,[TermDays]
,[ItemNumber]
,[AllowanceChargeIndicator1]
,[AllowanceChargeCode1]
,[AlllowanceChargeAmount1]
,[AllowanceChargeMethod1]
,[AllowanceChargeIndicator2]
,[AllowanceChargeCode2]
,[AlllowanceChargeAmount2]
,[AllowanceChargeMethod2]
,[AllowanceChargeIndicator3]
,[AllowanceChargeCode3]
,[AlllowanceChargeAmount3]
,[AllowanceChargeMethod3]
,[AllowanceChargeIndicator4]
,[AllowanceChargeCode4]
,[AlllowanceChargeAmount4]
,[AllowanceChargeMethod4]
,[AllowanceChargeIndicator5]
,[AllowanceChargeCode5]
,[AlllowanceChargeAmount5]
,[AllowanceChargeMethod5]
,[AllowanceChargeIndicator6]
,[AllowanceChargeCode6]
,[AlllowanceChargeAmount6]
,[AllowanceChargeMethod6]
,[AllowanceChargeIndicator7]
,[AllowanceChargeCode7]
,[AlllowanceChargeAmount7]
,[AllowanceChargeMethod7]
,[AllowanceChargeIndicator8]
,[AllowanceChargeCode8]
,[AlllowanceChargeAmount8]
,[AllowanceChargeMethod8]
,[FileName]
,[TimeStamp]
,[EdiName]
,[CountType]
,[Issue]
,[ProductName]
,[RecordType]
,[RawProductIdentifier]
,[RawStoreNo]
,[InvoiceDueDate]
,[DataTrueSupplierID]
,[DataTrueChainID]
,[DataTrueStoreID]
,[DataTrueProductID]
,[DataTrueBrANDID]
,[ShipAddress1]
,[ShipAddress2]
,[ShipCity]
,[ShipState]
,[ShipZip]
,[ShipPhoneNo]
,[ShipFax]
,[ContactName]
,[ContactPhoneNo]
,[PurchaseOrderNo]
,[PurchaseOrderDate]
,[TermsNetDueDate]
,[TermsNetDays]
,[TermsDescription]
,[PacksPerCase]
,[DivisionID]
,[RefInvoiceno]
,[RouteNo]
,[AccountCode]
,[Source]
,[SourceStatus]
,[ProductSignature]
,[RecordStatus]
,[RefIDToOriginalInvNo]
)
SELECT DISTINCT
 i.[RecordID]
,i.[ChainName]
,i.[PurposeCode]
,i.[ReportingCode]
,i.[ReportingMethod]
,i.[ReportingLocation]
,i.[StoreDuns]
,i.[ReferenceIDentification]
,i.[ProductQualifier]
,i.[ProductIdentifier]
,i.[BrANDIdentifier]
,i.[SupplierDuns]
,i.[SupplierIdentifier]
,i.[StoreNumber]
,i.[UnitMeasure]
,i.[QtyLevel]
,i.[Qty]
,i.[Cost]
,i.[Retail]
,i.[EffectiveDate]
,i.[EffectiveTime]
,i.[TermDays]
,ISNULL(i.[ItemNumber], '')
,i.[AllowanceChargeIndicator1]
,i.[AllowanceChargeCode1]
,ISNULL(i.[AlllowanceChargeAmount1], 0)
,i.[AllowanceChargeMethod1]
,i.[AllowanceChargeIndicator2]
,i.[AllowanceChargeCode2]
,ISNULL(i.[AlllowanceChargeAmount2], 0)
,i.[AllowanceChargeMethod2]
,i.[AllowanceChargeIndicator3]
,i.[AllowanceChargeCode3]
,ISNULL(i.[AlllowanceChargeAmount3], 0)
,i.[AllowanceChargeMethod3]
,i.[AllowanceChargeIndicator4]
,i.[AllowanceChargeCode4]
,ISNULL(i.[AlllowanceChargeAmount4], 0)
,i.[AllowanceChargeMethod4]
,i.[AllowanceChargeIndicator5]
,i.[AllowanceChargeCode5]
,ISNULL(i.[AlllowanceChargeAmount5], 0)
,i.[AllowanceChargeMethod5]
,i.[AllowanceChargeIndicator6]
,i.[AllowanceChargeCode6]
,ISNULL(i.[AlllowanceChargeAmount6], 0)
,i.[AllowanceChargeMethod6]
,i.[AllowanceChargeIndicator7]
,i.[AllowanceChargeCode7]
,ISNULL(i.[AlllowanceChargeAmount7], 0)
,i.[AllowanceChargeMethod7]
,i.[AllowanceChargeIndicator8]
,i.[AllowanceChargeCode8]
,ISNULL(i.[AlllowanceChargeAmount8], 0)
,i.[AllowanceChargeMethod8]
,i.[FileName]
,i.[TimeStamp]
,i.[EdiName]
,i.[CountType]
,i.[Issue]
,i.[ProductName]
,i.[RecordType]
,i.[RawProductIdentifier]
,i.[RawStoreNo]
,i.[InvoiceDueDate]
,i.[DataTrueSupplierID]
,i.[DataTrueChainID]
,i.[DataTrueStoreID]
,i.[DataTrueProductID]
,i.[DataTrueBrANDID]
,i.[ShipAddress1]
,i.[ShipAddress2]
,i.[ShipCity]
,i.[ShipState]
,i.[ShipZip]
,i.[ShipPhoneNo]
,i.[ShipFax]
,i.[ContactName]
,i.[ContactPhoneNo]
,i.[PurchaseOrderNo]
,i.[PurchaseOrderDate]
,i.[TermsNetDueDate]
,i.[TermsNetDays]
,i.[TermsDescription]
,i.[PacksPerCase]
,i.[DivisionID]
,i.[RefInvoiceno]
,i.[RouteNo]
,i.[AccountCode]
,i.[Source]
,i.[SourceStatus]
,DataTrue_EDI.dbo.fnCalcProductHashSig(i.SupplierIdentifier, ISNULL(ISNULL(i.ProductIdentifier, i.RawProductIdentifier), ISNULL(i.ItemNumber, '')), i.ProductName, i.UnitMeasure, i.PacksPerCase)
--,CASE WHEN i.RecordType = 3 AND RecordStatus NOT IN (4, 5) THEN 0
--	  WHEN i.RecordStatus = 4 THEN 4
--	  WHEN i.RecordStatus = 5
--		THEN 
--		(
--		CASE
--			WHEN (am.IsAutoApprovalRegulated = 1 OR (Source = 'Web_UserEntry' AND SourceStatus = 0)) OR i.RecordType = 3
--			THEN 6
--			ELSE 5
--		END
--		)
--	  WHEN i.RecordStatus = 255 THEN 255
--	  ELSE
--	  (
--		CASE
--			WHEN (am.IsAutoApprovalRegulated = 1 OR (Source = 'Web_UserEntry' AND SourceStatus = 0))
--			THEN 0
--			ELSE 2
--		END
--	   )
-- END -- AUTO APPROVAL
,0--RECORDSTATUS
,i.[RefIDToOriginalInvNo]
FROM DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries i
INNER JOIN #tmpRecordIDs AS t
ON t.RecordID = i.RecordID
    -----------
	LEFT OUTER JOIN
	-----------
	[DataTrue_Main].dbo.Chains  AS c ON
		i.ChainName = c.ChainIdentifier  
	-----------
	LEFT OUTER JOIN
	-----------
	[DataTrue_Main].dbo.Suppliers AS s ON
		i.EDIName = s.EDIName
	-----------
	LEFT OUTER JOIN
	-----------
	[DataTrue_Main].dbo.ApprovalManagement AS am ON
		am.ChainID = c.ChainID 
	AND am.SupplierID = s.SupplierID 
WHERE ReferenceIDentification NOT IN
	(
	SELECT DISTINCT InvoiceNo
	FROM #tmpDupRecords t
	WHERE t.ChainIdentifier = i.ChainName
	AND t.SupplierIdentifier = i.EdiName
	)
AND ReferenceIDentification NOT IN
	(
	SELECT DISTINCT InvoiceNo
	FROM #tmpInvalidRecords t
	WHERE t.ChainIdentifier = i.ChainName
	AND t.SupplierIdentifier = i.EdiName
	)


--=======================================
--           POST PROCESSING
--=======================================

--SEND NOTIFICATIONS OF PENDING APPROVALS
IF @@ROWCOUNT > 0
	BEGIN
		--LOOP THROUGH SUPPLIERS WITH PENDING APPROVAL
		DECLARE @NotificationSupplierID INT
		DECLARE @NotificationSupplierIdentifier VARCHAR(150)
		DECLARE @NotificationChainName VARCHAR(150)
		DECLARE @NotificationFilename VARCHAR(120)
		
		DECLARE NotificationCursor CURSOR FAST_FORWARD LOCAL FOR
		SELECT DISTINCT s.SupplierID, Approval.EdiName, Approval.ChainName, Approval.FileName
		FROM [DataTrue_EDI].[dbo].[Inbound846Inventory_RetailerDeliveries_Approval] AS Approval WITH (NOLOCK)
		INNER JOIN #tmpRecordIDs AS t
		ON Approval.RecordID = t.RecordID
		INNER JOIN [DataTrue_Main].[dbo].[Suppliers] AS s WITH (NOLOCK)
		ON Approval.EdiName = S.EDIName
		WHERE Approval.RecordStatus IN (2)
		
		OPEN NotificationCursor
		FETCH NEXT FROM NotificationCursor INTO @NotificationSupplierID, @NotificationSupplierIdentifier, @NotificationChainName, @NotificationFilename

		WHILE @@FETCH_STATUS = 0
			BEGIN		
				--GET INVOICE DATA
				DECLARE @tmpValidInvoices TABLE (ChainIdentifier VARCHAR(100), InvoiceNo VARCHAR(100), InvoiceTotal VARCHAR(100), StoreNumber VARCHAR(100), DeliveryDate VARCHAR(20), SupplierIdentifier VARCHAR(50), FileName VARCHAR(200))
				DELETE FROM @tmpValidInvoices
				INSERT INTO @tmpValidInvoices (ChainIdentifier, InvoiceNo, InvoiceTotal, StoreNumber, DeliveryDate, SupplierIdentifier, FileName)
				(
				SELECT DISTINCT
				LTRIM(RTRIM(Approval.ChainName)),
				LTRIM(RTRIM(Approval.ReferenceIDentification)),
				CONVERT(NUMERIC(18, 9),	
						SUM(Approval.Qty*Approval.Cost) 
						+SUM(ISNULL(Approval.AlllowanceChargeAmount1, 0))
						+SUM(ISNULL(Approval.AlllowanceChargeAmount2, 0))
						+SUM(ISNULL(Approval.AlllowanceChargeAmount3, 0))
						+SUM(ISNULL(Approval.AlllowanceChargeAmount4, 0))
						+SUM(ISNULL(Approval.AlllowanceChargeAmount5, 0))
						+SUM(ISNULL(Approval.AlllowanceChargeAmount6, 0))
						+SUM(ISNULL(Approval.AlllowanceChargeAmount7, 0))
						+SUM(ISNULL(Approval.AlllowanceChargeAmount8, 0))
						 ),
				LTRIM(RTRIM(Approval.StoreNumber)),
				Approval.EffectiveDate,
				Approval.SupplierIdentifier,
				Approval.Filename
				FROM [DataTrue_EDI].[dbo].[Inbound846Inventory_RetailerDeliveries_Approval] AS Approval WITH (NOLOCK)
				INNER JOIN #tmpRecordIDs AS t
				ON Approval.RecordID = t.RecordID
				WHERE Approval.RecordStatus = 2
				AND EdiName = @NotificationSupplierIdentifier
				AND ChainName = @NotificationChainName
				AND FileName = @NotificationFilename
				GROUP BY Approval.ChainName, Approval.ReferenceIDentification, Approval.EffectiveDate, Approval.SupplierIdentifier, Approval.FileName, LTRIM(RTRIM(Approval.StoreNumber))
				)
				
				UPDATE @tmpValidInvoices
				SET InvoiceNo = InvoiceNo + REPLICATE(' ', (10 - LEN(InvoiceNo)))
				WHERE LEN(InvoiceNo) < 11
				
				UPDATE @tmpValidInvoices
				SET StoreNumber = StoreNumber + REPLICATE(' ', (10 - LEN(StoreNumber)))
				WHERE LEN(StoreNumber) < 11
	
				UPDATE @tmpValidInvoices
				SET InvoiceTotal = CONVERT(VARCHAR(100), CONVERT(MONEY,InvoiceTotal)) + REPLICATE(' ', (13 - LEN(CONVERT(MONEY,InvoiceTotal))))
				WHERE LEN(CONVERT(MONEY,InvoiceTotal)) < 14
				
				DECLARE @ValidRecords VARCHAR(MAX)
				SET @ValidRecords = 'INVOICE NO' + CHAR(9) + 'INVOICE TOTAL' + CHAR(9) + CHAR(9) + 'STORE NO   ' + CHAR(9) + 'DELIVERY DATE' + CHAR(9) + CHAR(9) + 'IS APPENDED' + CHAR(13) + CHAR(10)	
							
				SELECT @ValidRecords += x.InvoiceNo + CHAR(9) + x.InvoiceTotal + CHAR(9) + CHAR(9) + x.StoreNumber + CHAR(9) + REPLACE(CONVERT(VARCHAR(20), x.DeliveryDate), '12:00AM', '') + CHAR(9) + CHAR(9) + CASE WHEN t.InvoiceNo IS NOT NULL THEN 'YES' ELSE 'NO' END + CHAR(13) + CHAR(10)
				FROM @tmpValidInvoices x
				LEFT OUTER JOIN #tmpAppendedRecords AS t
				ON x.ChainIdentifier = t.ChainIdentifier
				AND x.SupplierIdentifier = t.SupplierIdentifier
				AND x.InvoiceNo = t.InvoiceNo
				AND x.InvoiceTotal = t.InvoiceNo
				AND x.DeliveryDate = t.DeliveryDate
				AND x.FileName = t.FileName
				
				DECLARE @ValidTotal VARCHAR(100)
				SELECT @ValidTotal = SUM(CONVERT(NUMERIC(18, 9),InvoiceTotal)) FROM @tmpValidInvoices
				SET @ValidRecords = 'TOTAL AMOUNT: $' + CONVERT(VARCHAR(50), CONVERT(MONEY, ISNULL(@ValidTotal, 0)))  + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + @ValidRecords
				
				DECLARE @validEmailBody VARCHAR(MAX)
				SET @validEmailBody = 'The following receiving invoices have been loaded and are pending approval.' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) +
											'RETAILER: ' + (SELECT ChainName FROM DataTrue_Main.dbo.Chains WHERE ChainIdentifier = @NotificationChainName) + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + 
											'SUPPLIER: ' + (SELECT Suppliername FROM DataTrue_Main.dbo.Suppliers WHERE EDIName = @NotificationSupplierIdentifier) + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + 
											'FILE: ' + @NotificationFilename + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + 
											@ValidRecords
				
				--GET EMAIL ADDRESSES WHERE RECEIVE ACH NOTIFICATIONS IS TRUE
				DECLARE @emailaddresses VARCHAR(MAX) = ''
				SELECT @emailaddresses += Email + '; '
				FROM [DataTrue_Main].[dbo].[ContactInfo] AS c WITH (NOLOCK)
				WHERE c.OwnerEntityID = (SELECT ChainID FROM DataTrue_Main.dbo.Chains WHERE ChainIdentifier = @NotificationChainName)	
				AND c.ReceiveACHNotifications = 1
				SET @emailaddresses = @emailaddresses + 'edi@icucsolutions.com;'
				IF ISNULL(@emailaddresses, '') = ''
					BEGIN
						SET @emailaddresses = 'edi@icucsolutions.com;'
					END
				IF (SELECT IsRegulated FROM Suppliers WHERE EDIName = @NotificationSupplierIdentifier) = 1
						BEGIN
							SET @emailaddresses = @emailaddresses + 'regulated@icucsolutions.com;'
						END
					ELSE IF (SELECT 1 FROM Memberships WHERE MembershipTypeID = 14
						     AND OrganizationEntityID = (SELECT ChainID FROM DataTrue_Main.dbo.Chains WHERE ChainIdentifier = @NotificationChainName)
						     AND MemberEntityID = (SELECT SupplierID FROM DataTrue_Main.dbo.Suppliers WHERE EDIName = @NotificationSupplierIdentifier)) = 1
						BEGIN
							SET @emailaddresses = @emailaddresses + 'dataexchange@profdata.com;'
						END
				--FOR TESTING		
				--SET @emailaddresses = 'william.heine@icucsolutions.com;'
				-----------
				EXEC dbo.[prSendEmailNotification_PassEmailAddresses_HTML_Logos] 'Receiving Invoices Are Pending Approval'
					,@validEmailBody
					,'DataTrue System', 0, @emailaddresses
				FETCH NEXT FROM NotificationCursor INTO @NotificationSupplierID, @NotificationSupplierIdentifier, @NotificationChainName, @NotificationFilename
			END
		CLOSE NotificationCursor
		DEALLOCATE NotificationCursor
		
		--LOOP THROUGH SUPPLIERS WITH AUTO APPROVAL
		DECLARE @ProcessedSupplierID INT
		DECLARE @ProcessedSupplierIdentifier VARCHAR(150)
		DECLARE @ProcessedChainName VARCHAR(150)
		DECLARE @ProcessedFilename VARCHAR(120)
		
		DECLARE ProcessedCursor CURSOR FAST_FORWARD LOCAL FOR
		SELECT DISTINCT s.SupplierID, Approval.EdiName, Approval.ChainName, Approval.FileName
		FROM [DataTrue_EDI].[dbo].[Inbound846Inventory_RetailerDeliveries_Approval] AS Approval WITH (NOLOCK)
		INNER JOIN #tmpRecordIDs AS t
		ON Approval.RecordID = t.RecordID
		INNER JOIN [DataTrue_Main].[dbo].[Suppliers] AS s WITH (NOLOCK)
		ON Approval.EdiName = S.EDIName
		WHERE Approval.RecordStatus = 0
		
		OPEN ProcessedCursor
		FETCH NEXT FROM ProcessedCursor INTO @ProcessedSupplierID, @ProcessedSupplierIdentifier, @ProcessedChainName, @ProcessedFilename

		WHILE @@FETCH_STATUS = 0
			BEGIN		
				--GET INVOICE DATA
				DECLARE @tmpProcessedInvoices TABLE (ChainIdentifier VARCHAR(100), InvoiceNo VARCHAR(100), StoreNumber VARCHAR(100), InvoiceTotal VARCHAR(100), DeliveryDate VARCHAR(20), SupplierIdentifier VARCHAR(50), FileName VARCHAR(200))
				DELETE FROM @tmpProcessedInvoices
				INSERT INTO @tmpProcessedInvoices (ChainIdentifier, InvoiceNo, StoreNumber, InvoiceTotal, DeliveryDate, SupplierIdentifier, FileName)
				(
				SELECT DISTINCT
				LTRIM(RTRIM(Approval.ChainName)),
				LTRIM(RTRIM(Approval.ReferenceIDentification)),
				LTRIM(RTRIM(Approval.StoreNumber)),
				CONVERT(NUMERIC(18, 9),	
						SUM(Approval.Qty*Approval.Cost) 
						+SUM(ISNULL(Approval.AlllowanceChargeAmount1, 0))
						+SUM(ISNULL(Approval.AlllowanceChargeAmount2, 0))
						+SUM(ISNULL(Approval.AlllowanceChargeAmount3, 0))
						+SUM(ISNULL(Approval.AlllowanceChargeAmount4, 0))
						+SUM(ISNULL(Approval.AlllowanceChargeAmount5, 0))
						+SUM(ISNULL(Approval.AlllowanceChargeAmount6, 0))
						+SUM(ISNULL(Approval.AlllowanceChargeAmount7, 0))
						+SUM(ISNULL(Approval.AlllowanceChargeAmount8, 0))
						 ),
				Approval.EffectiveDate,
				Approval.EdiName,
				Approval.Filename
				FROM [DataTrue_EDI].[dbo].[Inbound846Inventory_RetailerDeliveries_Approval] AS Approval WITH (NOLOCK)
				INNER JOIN #tmpRecordIDs AS t
				ON Approval.RecordID = t.RecordID
				WHERE Approval.RecordStatus = 0
				AND EdiName = @ProcessedSupplierIdentifier
				AND ChainName = @ProcessedChainName
				AND FileName = @ProcessedFilename
				GROUP BY Approval.ChainName, Approval.ReferenceIDentification, Approval.EffectiveDate, Approval.EdiName, Approval.FileName, LTRIM(RTRIM(Approval.StoreNumber))
				)
				
				UPDATE @tmpProcessedInvoices
				SET InvoiceNo = InvoiceNo + REPLICATE(' ', (10 - LEN(InvoiceNo)))
				WHERE LEN(InvoiceNo) < 11
				
				UPDATE @tmpProcessedInvoices
				SET StoreNumber = StoreNumber + REPLICATE(' ', (10 - LEN(StoreNumber)))
				WHERE LEN(StoreNumber) < 11
	
				UPDATE @tmpProcessedInvoices
				SET InvoiceTotal = CONVERT(VARCHAR(100), CONVERT(MONEY,InvoiceTotal)) + REPLICATE(' ', (13 - LEN(CONVERT(MONEY, InvoiceTotal))))
				WHERE LEN(CONVERT(MONEY,InvoiceTotal)) < 14
				
				DECLARE @ProcessedRecords VARCHAR(MAX)
				SET @ProcessedRecords = 'INVOICE NO' + CHAR(9) + 'INVOICE TOTAL' + CHAR(9) + CHAR(9) + 'STORE NO   ' + CHAR(9) + 'DELIVERY DATE' + CHAR(9) + CHAR(9) + 'IS APPENDED' + CHAR(13) + CHAR(10)	
				
				SELECT @ProcessedRecords += x.InvoiceNo + CHAR(9) + x.InvoiceTotal + CHAR(9) + CHAR(9) + x.StoreNumber + CHAR(9) + REPLACE(CONVERT(VARCHAR(20), x.DeliveryDate), '12:00AM', '') + CHAR(9) + CHAR(9) + CASE WHEN t.InvoiceNo IS NOT NULL THEN 'YES' ELSE 'NO' END + CHAR(13) + CHAR(10)
				FROM @tmpProcessedInvoices x
				LEFT OUTER JOIN #tmpAppendedRecords AS t
				ON x.ChainIdentifier = t.ChainIdentifier
				AND x.SupplierIdentifier = t.SupplierIdentifier
				AND x.InvoiceNo = t.InvoiceNo
				AND x.InvoiceTotal = t.InvoiceNo
				AND x.DeliveryDate = t.DeliveryDate
				AND x.FileName = t.FileName
				
				DECLARE @ProcessedTotal VARCHAR(100)
				SELECT @ProcessedTotal = SUM(CONVERT(NUMERIC(18, 9),InvoiceTotal)) FROM @tmpProcessedInvoices
				SET @ProcessedRecords = 'TOTAL AMOUNT: $' + CONVERT(VARCHAR(50), CONVERT(MONEY, @ProcessedTotal))  + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + @ProcessedRecords
						
				DECLARE @ProcessedEmailBody VARCHAR(MAX)
				SET @ProcessedEmailBody = 'The following receiving invoices have been loaded and processed.' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) +
											'RETAILER: ' + (SELECT ChainName FROM DataTrue_Main.dbo.Chains WHERE ChainIdentifier = @ProcessedChainName) + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + 
											'SUPPLIER: ' + (SELECT Suppliername FROM DataTrue_Main.dbo.Suppliers WHERE EDIName = @ProcessedSupplierIdentifier) + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + 
											'FILE: ' + @ProcessedFilename + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + 
											 @ProcessedRecords + CHAR(13) + CHAR(10) --+ 
											--'</pre><p style="font-size: 10px;"> Note to distributor: You are receiving this email confirmation of the total dollar amount processed because you have opted out of the online invoice approval/rejection process. 
											--	Please note that by opting out of the online invoice approval/rejection process, you acknowledge that the invoices that you submit will be immediately processed and any errors will need to be resolved via subsequent invoicing. 
											--	Distributors also agree to indemnify, release and hold harmless iControl Systems USA LLC for any processing errors caused by not utilizing the online invoice approval/rejection process.</p><pre>'
				
				--GET EMAIL ADDRESSES WHERE RECEIVE ACH NOTIFICATIONS IS TRUE
				DECLARE @Processedemailaddresses VARCHAR(MAX) = ''
				SELECT @Processedemailaddresses += Email + '; '
				FROM [DataTrue_Main].[dbo].[ContactInfo] AS c WITH (NOLOCK)
				WHERE c.OwnerEntityID = (SELECT ChainID FROM DataTrue_Main.dbo.Chains WHERE ChainIdentifier = @ProcessedChainName)	
				AND c.ReceiveACHNotifications = 1
				SET @Processedemailaddresses = @Processedemailaddresses + 'edi@icucsolutions.com;'
				IF ISNULL(@Processedemailaddresses, '') = ''
					BEGIN
						SET @Processedemailaddresses = 'edi@icucsolutions.com;'
					END
				IF (SELECT IsRegulated FROM Suppliers WHERE EDIName = @ProcessedSupplierIdentifier) = 1
						BEGIN
							SET @Processedemailaddresses = @Processedemailaddresses + 'regulated@icucsolutions.com;'
						END
					ELSE IF (SELECT 1 FROM Memberships WHERE MembershipTypeID = 14
						     AND OrganizationEntityID = (SELECT ChainID FROM DataTrue_Main.dbo.Chains WHERE ChainIdentifier = @ProcessedChainName)
						     AND MemberEntityID = (SELECT SupplierID FROM DataTrue_Main.dbo.Suppliers WHERE EDIName = @ProcessedSupplierIdentifier)) = 1
						BEGIN
							SET @Processedemailaddresses = @Processedemailaddresses + 'dataexchange@profdata.com;'
						END
				--FOR TESTING		
				--SET @Processedemailaddresses = 'william.heine@icucsolutions.com;'
				-----------
				EXEC dbo.[prSendEmailNotification_PassEmailAddresses_HTML_Logos] 'Receiving Invoices Processed'
					,@ProcessedEmailBody
					,'DataTrue System', 0, @Processedemailaddresses
				FETCH NEXT FROM ProcessedCursor INTO @ProcessedSupplierID, @ProcessedSupplierIdentifier, @ProcessedChainName, @ProcessedFilename
			END
		CLOSE ProcessedCursor
		DEALLOCATE ProcessedCursor
	END	
	
	--UPDATE INBOUND846INVENTORY_ACH	
	UPDATE a SET a.recordstatus = 1
	FROM [DataTrue_EDI].[dbo].[Inbound846Inventory_RetailerDeliveries] a
	INNER JOIN  #tmpRecordIDs t
	ON a.RecordID = t.RecordID
	WHERE a.RecordStatus = 0
		
	--UPDATE EDI_LOADSTATUS_ACH
	UPDATE edi SET edi.loadstatus = 2
	FROM DataTrue_EDI.dbo.EDI_LoadStatus_Receiving edi
	INNER JOIN DataTrue_EDI.dbo.Inbound846Inventory_RetailerDeliveries rc
	ON edi.Filename = rc.FileName
	AND edi.ChainID = rc.DataTrueChainID
	AND edi.SupplierID = rc.DataTrueSupplierID
	INNER JOIN #tmpRecordIDs t
	ON rc.RecordID = t.RecordID
	WHERE edi.LoadStatus = 1

COMMIT TRANSACTION

END TRY

BEGIN CATCH

ROLLBACK TRANSACTION

		SET @errormessage = error_message()
		SET @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		SET @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,63600
		
		
		exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'Billing_Regulated_NewEDIData_RC'

		exec dbo.prSendEmailNotification_PassEmailAddresses 'ERROR in job Billing_Regulated_NewEDIData_RC'
			,'An exception was encountered in [prACH_MovePendingRecordsToApprovalTable_RC]'
			,'DataTrue System', 0, 'datatrueit@icontroldsd.com;edi@icontroldsd.com'		
		
END CATCH

RETURN
GO
