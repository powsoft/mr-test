USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetInboundSUPTransactions_846_Newspapers_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[prGetInboundSUPTransactions_846_Newspapers_PRESYNC_20150329]

AS 

DECLARE @ProcessID INT

DECLARE @errormessage NVARCHAR(4000)
DECLARE @errorlocation NVARCHAR(255)
DECLARE @errorsenderstring NVARCHAR(255)
DECLARE @loadstatus SMALLINT
DECLARE @MyID INT
SET @MyID = 7427

BEGIN TRY

	BEGIN TRANSACTION
	
		SET DATEFIRST 7 --SET WEEKENDING DAY TO SUNDAY

		--SET TEMP TABLE FOR CHAINS TO EXCLUDE
		DECLARE @ChainsExcluded TABLE (ChainIdentifier VARCHAR(50))
		INSERT INTO @ChainsExcluded (ChainIdentifier) VALUES ('CVS')
		INSERT INTO @ChainsExcluded (ChainIdentifier) VALUES ('QC')

		--UPDATE EXISTING RECORDS WITH NEWER MATCHING CONTEXT TO RECORD STATUS 255
		UPDATE DataTrue_EDI.dbo.Inbound846Inventory_Newspapers
		SET RecordStatus = 255
		WHERE 1 = 1
		AND ChainName NOT IN (SELECT ChainIdentifier FROM @ChainsExcluded)
		AND RecordStatus = 0
		AND RecordType = 0
		AND PurposeCode IN ('DB','CR')
		AND EffectiveDate >= '11/18/2013'
		AND EffectiveDate IS NOT NULL
		AND (LEN(ProductIdentifier) > 0 OR LEN(Bipad) > 0)
		AND (ProductIdentifier IS NOT NULL OR Bipad IS NOT NULL)
		AND LEN(StoreNumber) > 0
		AND StoreNumber IS NOT NULL
		AND EffectiveDate <= (SELECT DATEADD(dd, 7 - (DATEPART(dw, GETDATE())), GETDATE()) - 13)
		AND RecordID NOT IN
		(
			SELECT RecordID
			FROM DataTrue_EDI.dbo.Inbound846Inventory_Newspapers AS edi
			WHERE 1 = 1
			AND ChainName NOT IN (SELECT ChainIdentifier FROM @ChainsExcluded)
			AND RecordStatus = 0
			AND RecordType = 0
			AND PurposeCode IN ('DB','CR')
			AND EffectiveDate >= '11/18/2013'
			AND EffectiveDate IS NOT NULL
			AND (LEN(ProductIdentifier) > 0 OR LEN(Bipad) > 0)
			AND (ProductIdentifier IS NOT NULL OR Bipad IS NOT NULL)
			AND LEN(StoreNumber) > 0
			AND StoreNumber IS NOT NULL
			AND
			(
				RecordID IN
				(
					SELECT TOP 1 RecordID
					FROM DataTrue_EDI.dbo.Inbound846Inventory_Newspapers AS edi2 WITH (NOLOCK)
					WHERE edi2.ChainName = edi.ChainName
					AND edi2.DataTrueSupplierID = edi.DataTrueSupplierID
					AND edi2.DataTrueStoreID = edi.DataTrueStoreID
					AND edi2.Bipad = edi.Bipad
					AND edi2.EffectiveDate = edi.EffectiveDate
					AND edi2.PurposeCode = edi.PurposeCode
					ORDER BY edi2.TimeStamp DESC
				)
				OR
				(
					FileName IN
					(
						SELECT TOP 1 FileName
						FROM DataTrue_EDI.dbo.Inbound846Inventory_Newspapers AS edi2 WITH (NOLOCK)
						WHERE edi2.ChainName = edi.ChainName
						AND edi2.DataTrueSupplierID = edi.DataTrueSupplierID
						AND edi2.DataTrueStoreID = edi.DataTrueStoreID
						AND edi2.Bipad = edi.Bipad
						AND edi2.EffectiveDate = edi.EffectiveDate
						AND edi2.PurposeCode = edi.PurposeCode
						AND edi2.FileName = edi.FileName
						AND edi2.RecordID IN
						(
							SELECT TOP 1 RecordID
							FROM DataTrue_EDI.dbo.Inbound846Inventory_Newspapers AS edi3 WITH (NOLOCK)
							WHERE edi2.ChainName = edi3.ChainName
							AND edi2.DataTrueSupplierID = edi3.DataTrueSupplierID
							AND edi2.DataTrueStoreID = edi3.DataTrueStoreID
							AND edi2.Bipad = edi3.Bipad
							AND edi2.EffectiveDate = edi3.EffectiveDate
							AND edi2.PurposeCode = edi3.PurposeCode
							ORDER BY edi3.TimeStamp DESC
						) 
					)
					AND
					(
						TimeStamp BETWEEN
						(
							SELECT TOP 1 DATEADD(S, -2, TimeStamp)
							FROM DataTrue_EDI.dbo.Inbound846Inventory_Newspapers AS edi2 WITH (NOLOCK)
							WHERE edi2.ChainName = edi.ChainName
							AND edi2.DataTrueSupplierID = edi.DataTrueSupplierID
							AND edi2.DataTrueStoreID = edi.DataTrueStoreID
							AND edi2.Bipad = edi.Bipad
							AND edi2.EffectiveDate = edi.EffectiveDate
							AND edi2.PurposeCode = edi.PurposeCode
							AND edi2.FileName = edi.FileName
							ORDER BY TimeStamp DESC
						)
						AND
						(
							SELECT TOP 1 DATEADD(S, 2, TimeStamp)
							FROM DataTrue_EDI.dbo.Inbound846Inventory_Newspapers AS edi2 WITH (NOLOCK)
							WHERE edi2.ChainName = edi.ChainName
							AND edi2.DataTrueSupplierID = edi.DataTrueSupplierID
							AND edi2.DataTrueStoreID = edi.DataTrueStoreID
							AND edi2.Bipad = edi.Bipad
							AND edi2.EffectiveDate = edi.EffectiveDate
							AND edi2.PurposeCode = edi.PurposeCode
							AND edi2.FileName = edi.FileName
							ORDER BY TimeStamp DESC
						)
					)
				)
			)
		)

		--SET PROCESS ID
		INSERT INTO DataTrue_Main.dbo.JobProcesses (JobRunningID) VALUES (10) --JobRunningID 10 = NewspaperShrink
		SELECT @ProcessID = SCOPE_IDENTITY()
		UPDATE DataTrue_Main.dbo.JobRunning SET LastProcessID = @ProcessID WHERE JobName = 'NewspaperShrink'
		
		--SET DRAW FILES TO RECORD TYPE 5
		UPDATE t
		SET t.RecordType = 5
		FROM DataTrue_EDI.dbo.Inbound846Inventory_Newspapers AS t
		WHERE 1 = 1
		AND RecordStatus = 0
		AND UPPER(Filename) LIKE '%DRAW%'

		--UPDATE NULL OR BLANK STORE NUMBERS WITH WHLS STORE NUMBER
		UPDATE t
		SET t.StoreNumber = REPLACE(t.Whls_StoreIdentifier, t.ChainName, '')
		FROM DataTrue_EDI.dbo.Inbound846Inventory_Newspapers t
		WHERE 1 = 1
		AND (t.StoreNumber IS NULL OR LEN(t.StoreNumber) < 1)
		AND t.Whls_StoreIdentifier IS NOT NULL
		AND LEN(t.Whls_StoreIdentifier) > 0
		AND t.RecordStatus = 0

		--GET RECORD IDS TO PROCESS
		SELECT RecordID 
		INTO #tempInboundTransactions 
		FROM DataTrue_EDI.dbo.Inbound846Inventory_Newspapers i
		WHERE 1 = 1
		AND ChainName NOT IN (SELECT ChainIdentifier FROM @ChainsExcluded)
		AND RecordStatus = 0
		AND RecordType = 0
		AND PurposeCode IN ('DB','CR')
		AND EffectiveDate >= '11/18/2013'
		AND EffectiveDate IS NOT NULL
		AND (LEN(productidentifier) > 0 OR LEN(Bipad) > 0)
		AND (ProductIdentifier IS NOT NULL OR Bipad IS NOT NULL)
		AND LEN(StoreNumber) > 0
		AND StoreNumber IS NOT NULL
		AND EffectiveDate <= (SELECT DATEADD(dd, 7 - (DATEPART(dw, GETDATE())), GETDATE()) - 13)
		ORDER BY RecordID

		SET @loadstatus = 1 
		
		--INSERT INTO STORETRANSACTIONS_WORKING
		INSERT INTO [dbo].[StoreTransactions_Working]
		(
			[ChainIdentifier]
			,[StoreIdentifier]
			,[SupplierIdentifier]
			,[Qty]
			,[SaleDateTime]
			,[UPC]
			,[BrandIdentifier]
			,[SupplierInvoiceNumber]
			,[ReportedCost]
			,[ReportedRetail]
			,[WorkingSource]
			,[LastUpdateUserID]
			,[SourceIdentifier]
			,[Banner]
			,[CorporateIdentifier]
			,[EDIName]--)
			,[RecordID_EDI_852]
			,[RawProductIdentifier]
			,[Bipad]
			,[StoreID]
			,[SupplierID]
			,[DateTimeSourceReceived]
			,[ProcessID]
			,[EDIBanner]
		)
		SELECT
		LTRIM(RTRIM(ChainName)),
		LTRIM(RTRIM(StoreNumber)),
		LTRIM(RTRIM(SupplierIdentifier)),
		CASE WHEN Purposecode = 'DB' THEN Qty 
			 WHEN Purposecode = 'CR' THEN Qty
			 ELSE Qty
		END,
		CAST(effectiveDate AS DATE),
		Isnull(ProductIdentifier, ''),
		BrandIdentifier,
		ReferenceIDentification,
		ISNULL(Cost, 0),
		ISNULL(Retail, 0),
		CASE WHEN Purposecode = 'DB' THEN 'SUP-S' 
			 WHEN Purposecode = 'CR' THEN 'SUP-U' 
			 ELSE 'SUP-X' 
		END,
		7427,
		ISNULL(FileName, 'DEFAULT'),
		[ReportingLocation],
		[StoreDuns],
		[EDIName],
		s.[RecordID],
		[Rawproductidentifier],
		[Bipad],
		[DataTrueStoreID],
		[DataTrueSupplierID],
		[TimeStamp],
		@ProcessID,
		(SELECT ISNULL(Custom3, '') FROM DataTrue_Main.dbo.Stores WHERE StoreID = s.DataTrueStoreID)
		FROM DataTrue_EDI.dbo.Inbound846Inventory_Newspapers s
		INNER JOIN #tempInboundTransactions t
		ON s.RecordID = t.RecordID

	COMMIT TRANSACTION
	
END TRY
	
BEGIN CATCH

	ROLLBACK TRANSACTION
	
	SET @loadstatus = -9998
	SET @errormessage = ERROR_MESSAGE()
	SET @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
	SET @errorsenderstring = ERROR_PROCEDURE()
	
	EXEC dbo.prLogExceptionAndNotifySupport
	1, --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
	@errorlocation,
	@errormessage,
	@errorsenderstring,
	@MyID
				
	EXEC [msdb].[dbo].[sp_stop_job] 
		@job_name = 'DailySUPLoadDeliveriesAndPickups_THIS_IS_CURRENT_ONE'

	EXEC dbo.prSendEmailNotification_PassEmailAddresses 'Load Deliveries AND Pickups Job Stopped'
			,'Deliveries AND pickup loading has been stopped due to an exception.  Manual review, resolution, AND re-start will be required for the job to continue.'
			,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;edi@icontroldsd.com'		
		
END CATCH
	
UPDATE s
SET RecordStatus = @loadstatus
FROM DataTrue_EDI.dbo.Inbound846Inventory_Newspapers s
INNER JOIN #tempInboundTransactions t
ON s.RecordID = t.RecordID

RETURN
GO
