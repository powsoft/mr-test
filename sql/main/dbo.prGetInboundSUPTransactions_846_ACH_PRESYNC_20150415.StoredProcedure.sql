USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetInboundSUPTransactions_846_ACH_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[prGetInboundSUPTransactions_846_ACH_PRESYNC_20150415]

AS 

--=======================
--    DECLARE VARIABLES
--=======================

DECLARE @errorMessage NVARCHAR(4000)
DECLARE @errorLocation NVARCHAR(255)
DECLARE @errorSenderString NVARCHAR(255)
DECLARE @LoadStatus SMALLINT
DECLARE @ExistFilesComplete BIT = 0
DECLARE @ExistFilesIncomplete BIT = 0
DECLARE @MyID INT
DECLARE @jobLastRan DATETIME
SELECT @jobLastRan = (SELECT JobLastRunDateTime FROM DataTrue_Main..JobRunning WHERE JobName = 'DailyRegulatedBilling')
DECLARE @tempInboundTransactions TABLE (RecordID INT)
DECLARE @ProcessID INT

--=======================
--    PRE PROCESSING
--=======================

-----------------
BEGIN TRY
-----------------

-----------------
BEGIN TRANSACTION
-----------------

--SET USER ID
	SET @MyID = 53827
	
--SET PROCESS ID
	INSERT INTO DataTrue_Main.dbo.JobProcesses (JobRunningID) VALUES (3) --JobRunningID 3 = DailyRegulatedBilling
	SELECT @ProcessID = SCOPE_IDENTITY()
	UPDATE DataTrue_Main.dbo.JobRunning SET LastProcessID = @ProcessID WHERE JobName = 'DailyRegulatedBilling'

--GET REGULATED CHAINS
	--INSERT INTO @RegulatedChains (ChainID)
	--SELECT DISTINCT step.EntityIDToInclude
	--FROM DataTrue_Main.dbo.ProcessStepEntities AS step WITH (NOLOCK)
	--WHERE step.ProcessStepName = 'DailyRegulatedBilling'

	--UPDATE r
	--SET r.ChainIdentifier = (SELECT ChainIdentifier
	--						 FROM DataTrue_Main.dbo.Chains AS c WITH (NOLOCK)
	--						 WHERE c.ChainID = r.ChainID)
	--FROM @RegulatedChains AS r

--UPDATE 000000000000 UPCS
	UPDATE i SET ProductIdentifier = '', RawProductIdentifier = '000000000000'
	FROM DataTrue_EDI.dbo.Inbound846Inventory_ACH_Approval i
	WHERE 1 = 1
	AND RecordStatus = 0
	AND Qty <> 0
	AND PurposeCode in ('DB','CR')
	AND ProductIdentifier = '000000000000'
	
--UPDATE RECORDS WITH NO UPC OR ITEM NUMBER
	UPDATE i SET ProductIdentifier = 'DEFAULT'
	--select *
	FROM DataTrue_EDI.dbo.Inbound846Inventory_ACH_Approval i
	WHERE 1 = 1
	AND RecordStatus = 0
	AND Qty <> 0
	AND PurposeCode in ('DB','CR')
	AND (ISNULL(ProductIdentifier, '') = ''AND ISNULL(ItemNumber, '') = '')
	
--UPDATE RECORDS WITH NO PRODUCT NAME
	UPDATE i SET i.ProductName = CASE WHEN ISNUMERIC(ISNULL(i.ItemNumber, '0')) = 0 THEN i.ItemNumber ELSE 'UNKNOWN' END
	--select *
	FROM DataTrue_EDI.dbo.Inbound846Inventory_ACH_Approval i
	WHERE 1 = 1
	AND RecordStatus = 0
	AND Qty <> 0
	AND PurposeCode in ('DB','CR')
	AND ISNULL(i.ProductName, '') = ''
	
--UPDATE RECORDS WITH BOTTLE RETURN
	UPDATE i SET ProductIdentifier = '999999999998', RawProductIdentifier = '999999999998'
	FROM DataTrue_EDI.dbo.Inbound846Inventory_ACH_Approval i
	WHERE 1 = 1
	AND RecordStatus = 0
	AND Qty <> 0
	AND PurposeCode in ('DB','CR')
	AND ISNULL(ProductIdentifier, '') = ''
	AND CHARINDEX('Bottle Return', ProductName) > 0
	
--GET VALID RECORDS FROM INBOUND846INVENTORY_ACH_APPROVAL
	INSERT INTO @tempInboundTransactions (RecordID)
	SELECT RecordID
	FROM DataTrue_EDI.dbo.Inbound846Inventory_ACH_Approval i
	WHERE 1 = 1
	AND RecordStatus = 0
	--AND ChainName in (SELECT DISTINCT ChainIdentifier FROM @RegulatedChains)
	AND PurposeCode in ('DB','CR')
	AND (ISNULL(ProductIdentifier, '') <> '' OR ISNULL(ItemNumber, '') <> '')
	AND ISNULL(StoreNumber, '') <> ''

--=======================
--      PROCESSING
--=======================

--SET LOAD STATUS FOR SUCESSFUL INSERTS
	SET @LoadStatus = 1

--INSERT VALID RECORDS INTO STORETRANSACTIONS_WORKING
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
	--,[ReportedUnitPrice]
	,[ReportedCost]
	,[ReportedRetail]
	,[WorkingSource]
	,[LastUpdateUserID]
	,[SourceIdentifier]
	--,[DateTimeSourceReceived]
	,[Banner]
	,[CorporateIdentifier]
	,[EDIName]--)
	,[RecordID_EDI_852]
	,[RawProductIdentifier]
	,[InvoiceDueDate]
	,[Adjustment1]
	,[Adjustment2]
	,[Adjustment3]
	,[Adjustment4]
	,[Adjustment5]
	,[Adjustment6]
	,[Adjustment7]
	,[Adjustment8]
	,[ItemSKUReported]
	,[ItemDescriptionReported]
	,[RawStoreIdentifier]
	,[Route]
	,[UOM]
	,[AccountCode]
	,[RecordType]
	,[ProcessID]
	,[RefIDToOriginalInvNo]
	,[PackSize]
	,[PONo]
	)
	SELECT
	 LTRIM(RTRIM(ChainName))
	,LTRIM(RTRIM(StoreNumber))
	,LTRIM(RTRIM(SupplierIdentifier))
	,CASE WHEN Purposecode = 'DB' THEN Qty 
		  WHEN Purposecode = 'CR' THEN Qty * -1
		  ELSE Qty
	 END
	,CAST(EffectiveDate AS DATE)
	,ISNULL(ProductIdentifier, '')
	,BrandIdentifier
	,ReferenceIDentification
	,ISNULL(Cost, 0)
	,ISNULL(Retail, 0)
	,CASE WHEN Purposecode = 'DB' THEN 'SUP-S' 
	      WHEN Purposecode = 'CR' THEN 'SUP-U' 
	      ELSE 'SUP-X' 
	 END
	,@MyID
	,ISNULL(FileName, 'DEFAULT')
	--,CAST([TimeStamp] AS DATE)
	,[ReportingLocation]
	,[StoreDuns]
	,[EDIName]
	,s.[RecordID]
	,[Rawproductidentifier]
	,[TermsNetDueDate]
	,ISNULL([AlllowanceChargeAmount1], 0)
	,ISNULL([AlllowanceChargeAmount2], 0)
	,ISNULL([AlllowanceChargeAmount3], 0)
	,ISNULL([AlllowanceChargeAmount4], 0)
	,ISNULL([AlllowanceChargeAmount5], 0)
	,ISNULL([AlllowanceChargeAmount6], 0)
	,ISNULL([AlllowanceChargeAmount7], 0)
	,ISNULL([AlllowanceChargeAmount8], 0)
	,LTRIM(RTRIM(ItemNumber))
	,LTRIM(RTRIM(ProductName))
	,LTRIM(RTRIM(RawStoreNo))
	,LTRIM(RTRIM(RouteNo))
	,LTRIM(RTRIM([UnitMeasure]))
	,[AccountCode]
	,[RecordType]
	,@ProcessID
	,[RefIDToOriginalInvNo]
	,[PacksPerCase]
	,[PurchaseOrderNo]
	FROM DataTrue_EDI.dbo.Inbound846Inventory_ACH_Approval AS s WITH (NOLOCK)
	INNER JOIN @tempInboundTransactions t
	ON s.RecordID = t.RecordId

--=======================
--   POST PROCESSING
--=======================

	UPDATE s SET RecordStatus = @LoadStatus, ProcessID = @ProcessID
	FROM DataTrue_EDI.dbo.Inbound846Inventory_ACH_Approval s
	INNER JOIN @tempInboundTransactions t
	ON s.RecordID = t.RecordID

-----------------
COMMIT TRANSACTION
-----------------

-----------------
END TRY
-----------------

-----------------	
BEGIN CATCH
-----------------

-----------------
ROLLBACK TRANSACTION
-----------------

	SET @LoadStatus = -9998

	SET @errorMessage = ERROR_MESSAGE()
	SET @errorLocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
	SET @errorSenderString = ERROR_PROCEDURE()
	
	EXEC dbo.prLogExceptionAndNotifySupport
	 1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
	,@errorLocation
	,@errorMessage
	,@errorSenderString
	,@MyID
		
	EXEC [msdb].[dbo].[sp_stop_job] 
		@job_name = 'Billing_Regulated_NewInvoiceData'
		
	UPDATE 	DataTrue_Main.dbo.JobRunning
	SET JobIsRunningNow = 0
	WHERE JobName = 'DailyRegulatedBilling'			

	EXEC dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated Job Stopped'
			,'An exception was encountered in prGetInboundSUPTransactions_846_ACH.  Manual review, resolution, AND re-start will be required for the job to continue.'
			,'DataTrue System', 0, 'charlie.clark@icontrol.com'--'datatrueit@icontroldsd.com;edi@icontroldsd.com'		

	UPDATE s SET RecordStatus = @LoadStatus
	FROM DataTrue_EDI.dbo.Inbound846Inventory_ACH_Approval s
	INNER JOIN @tempInboundTransactions t
	ON s.RecordID = t.RecordID
	
	--UPDATE c SET c.loadstatus = 3
	--FROM DataTrue_EDI.dbo.EDI_LoadStatus_ACH c
	--WHERE LoadStatus = 2
	--AND c.[TimeStamp] > @jobLastRan
		
-----------------		
END CATCH
-----------------

-----------------
RETURN
-----------------
GO
