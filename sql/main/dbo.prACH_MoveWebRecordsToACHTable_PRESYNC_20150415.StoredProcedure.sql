USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prACH_MoveWebRecordsToACHTable_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[prACH_MoveWebRecordsToACHTable_PRESYNC_20150415]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
BEGIN TRY

BEGIN TRANSACTION

		

	DECLARE @JobLastRan DATETIME
	SELECT @JobLastRan = JobLastRunDateTime FROM DataTrue_Main.dbo.JobRunning WHERE JobName = 'DailyRegulatedBilling'

	--SET BLANK PRODUCTS TO 'DEFAULT'	
	UPDATE t SET t.ProductIdentifier = 'DEFAULT'
	FROM DataTrue_EDI.dbo.InboundInventory_Web t
	WHERE t.RecordStatus = 0
	AND LEN(ISNULL(t.ProductIdentifier, '')) < 1
	AND t.DataTrueProductID = 0
	AND t.DateTimeCreated >= @JobLastRan
	
	--UPDATE PRODUCT ID
	UPDATE t SET t.DataTrueProductID = p.ProductID
	FROM DataTrue_EDI.dbo.InboundInventory_WEB t
	INNER JOIN DataTrue_Main.dbo.ProductIdentifiers p
	ON LTRIM(RTRIM(t.ProductIdentifier)) = LTRIM(RTRIM(p.IdentifierValue))
	AND t.RecordStatus = 0
	AND p.ProductIdentifierTypeID = 2
	AND ISNULL(t.DataTrueProductID, 0) = 0
	AND t.DateTimeCreated >= @JobLastRan
	
	--SELECT INTO #tempInboundTransactions
	SELECT RecordID
	INTO #tempInboundTransactions
	FROM DataTrue_EDI.dbo.InboundInventory_Web i
	WHERE RecordStatus IN (0)
	AND ISNULL(Qty, 0) <> 0
	AND PurposeCode IN ('DB','CR')
	AND EffectiveDate IS NOT NULL
	AND ISNULL(ProductIdentifier, '') <> ''
	AND ISNULL(StoreNumber, '') <> ''
	AND i.LastUpdateDateTime >= @JobLastRan
	ORDER BY RecordID
	
	UPDATE web
	SET web.Filename = CONVERT(VARCHAR(50), web.DataTrueChainID) + '_' + CONVERT(VARCHAR(50), web.DataTrueSupplierID) + '_Web846Import_' + REPLACE(REPLACE(CONVERT(VARCHAR(120), GETDATE(), 120), ' ', '_'), ':', '_')--[FileName]
	FROM DataTrue_EDI.dbo.InboundInventory_Web AS web
	INNER JOIN #tempInboundTransactions AS t
	ON web.RecordID = t.RecordID
	
	UPDATE i
	SET i.LastUpdateDateTime = GETDATE()
	FROM DataTrue_EDI.dbo.InboundInventory_Web i
	WHERE RecordStatus IN (0)
	AND ISNULL(Qty, 0) <> 0
	AND PurposeCode IN ('DB','CR')
	AND EffectiveDate IS NOT NULL
	AND ISNULL(ProductIdentifier, '') <> ''
	AND ISNULL(StoreNumber, '') <> ''
	AND i.LastUpdateDateTime < @JobLastRan
	
	IF EXISTS
	(
		SELECT TOP 1 RecordID
		FROM DataTrue_EDI.dbo.InboundInventory_Web i
		WHERE RecordStatus IN (0)
		AND ISNULL(Qty, 0) <> 0
		AND PurposeCode IN ('DB','CR')
		AND EffectiveDate IS NOT NULL
		AND ISNULL(ProductIdentifier, '') <> ''
		AND ISNULL(StoreNumber, '') <> ''
		AND i.LastUpdateDateTime < @JobLastRan
	)
		BEGIN
			EXEC dbo.prSendEmailNotification_PassEmailAddresses_HTML_Logos 'InboundInventory_Web Aged Records'
				,'Aged records with status 0 discovered during prACH_MoveWebRecordsToACHTable execution.  Records will not be pulled since the update timestamp is before the timestamp of the last RB run.  Please review these records manually.'
				,'DataTrue System', 0, 'edi@icucsolutions.com'
		END
		
	DECLARE @FileNameUpdateTable TABLE (RecordID INT, Filename VARCHAR(500))
	
	INSERT INTO [DataTrue_EDI].[dbo].[Inbound846Inventory_ACH]
	(
	 [ChainName]
	,[PurposeCode]
	,[ReportingCode]
	,[ReportingMethod]
	,[ReportingLocation]
	,[StoreDuns]
	,[ReferenceIDentification]
	,[ProductQualifier]
	,[ProductIdentifier]
	,[BrandIdentifier]
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
	,[RecordStatus]
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
	,[DataTrueBrandID]
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
	,[VendorName]
	,[AccountCode]
	,[Source]
	,[SourceStatus]
	)
	SELECT
	 (SELECT ChainIdentifier FROM DataTrue_Main.dbo.Chains WHERE ChainID = web.DataTrueChainID)--[ChainName]
	,web.PurposeCode--[PurposeCode]
	,''--[ReportingCode]
	,''--[ReportingMethod]
	,web.ReportingLocation--[ReportingLocation]
	,''--[StoreDuns]
	,web.ReferenceIDentification--[ReferenceIDentification]
	,web.ProductQualifier--[ProductQualifier]
	,web.ProductIdentifier--[ProductIdentifier]
	,web.BrandIdentifier--[BrandIdentifier]
	,''--[SupplierDuns]
	,(SELECT SupplierIdentifier FROM DataTrue_Main.dbo.Suppliers WHERE SupplierID = web.DataTrueSupplierID)--[SupplierIdentifier]
	,web.StoreIdentifier--[StoreNumber]
	,web.UnitMeasure--[UnitMeasure]
	,web.QtyLevel--[QtyLevel]
	,CASE WHEN web.Purposecode = 'DB' THEN web.Qty 
		  WHEN web.Purposecode = 'CR' THEN web.Qty * -1
		  ELSE web.Qty
		  END--[Qty]
	,web.Cost--[Cost]
	,web.Retail--[Retail]
	,web.EffectiveDate--[EffectiveDate]
	,''--[EffectiveTime]
	,''--[TermDays]
	,web.ItemNumber--[ItemNumber]
	,''--[AllowanceChargeIndicator1]
	,''--[AllowanceChargeCode1]
	,ROUND(ISNULL(web.AllowanceChargeAmount, 0), 2)--[AlllowanceChargeAmount1]
	,''--[AllowanceChargeMethod1]
	,''--[AllowanceChargeIndicator2]
	,''--[AllowanceChargeCode2]
	,ISNULL(web.Adjustment2, 0)--[AlllowanceChargeAmount2]
	,''--[AllowanceChargeMethod2]
	,''--[AllowanceChargeIndicator3]
	,''--[AllowanceChargeCode3]
	,0--ISNULL(web.AllowanceChargeAmount, 0)--[AlllowanceChargeAmount3]
	,''--[AllowanceChargeMethod3]
	,''--[AllowanceChargeIndicator4]
	,''--[AllowanceChargeCode4]
	,0--[AlllowanceChargeAmount4]
	,''--[AllowanceChargeMethod4]
	,''--[AllowanceChargeIndicator5]
	,''--[AllowanceChargeCode5]
	,0--[AlllowanceChargeAmount5]
	,''--[AllowanceChargeMethod5]
	,''--[AllowanceChargeIndicator6]
	,''--[AllowanceChargeCode6]
	,0--[AlllowanceChargeAmount6]
	,''--[AllowanceChargeMethod6]
	,''--[AllowanceChargeIndicator7]
	,''--[AllowanceChargeCode7]
	,0--[AlllowanceChargeAmount7]
	,''--[AllowanceChargeMethod7]
	,''--[AllowanceChargeIndicator8]
	,''--[AllowanceChargeCode8]
	,0--[AlllowanceChargeAmount8]
	,''--[AllowanceChargeMethod8]
	,web.FileName
	,web.LastUpdateDateTime--[TimeStamp]
	,0--[RecordStatus]
	,(SELECT EDIName FROM DataTrue_Main.dbo.Suppliers WHERE SupplierID = web.DataTrueSupplierID)--[EdiName]
	,''--[CountType]
	,''--[Issue]
	,web.ProductName--[ProductName]
	,CASE WHEN (SELECT IsRegulated FROM DataTrue_Main.dbo.Suppliers WHERE SupplierID = web.DataTrueSupplierID) = 1 THEN 0 ELSE 3 END--[RecordType]
	,''--[RawProductIdentifier]
	,web.StoreNumber--[RawStoreNo]
	,web.InvoiceDueDate--[InvoiceDueDate]
	,web.DataTrueSupplierID--[DataTrueSupplierID]
	,web.DataTrueChainID--[DataTrueChainID]
	,web.DataTrueStoreID--[DataTrueStoreID]
	,web.DataTrueProductID--[DataTrueProductID]
	,web.DataTrueBrandID--[DataTrueBrandID]
	,''--[ShipAddress1]
	,''--[ShipAddress2]
	,''--[ShipCity]
	,''--[ShipState]
	,''--[ShipZip]
	,''--[ShipPhoneNo]
	,''--[ShipFax]
	,''--[ContactName]
	,''--[ContactPhoneNo]
	,web.PONumber--[PurchaseOrderNo]
	,web.PODate--[PurchaseOrderDate]
	,web.InvoiceDueDate--[TermsNetDueDate]
	,''--[TermsNetDays]
	,''--[TermsDescription]
	,web.PPC--[PacksPerCase]
	,''--[DivisionID]
	,''--[RefInvoiceno]
	,''--[RouteNo]
	,''--[VendorName]
	,''--[AccountCode]
	,'Web_UserEntry'--[Source]
	,CASE WHEN RecordStatus = 0 THEN 0 ELSE 1 END--[SourceStatus]
	FROM [DataTrue_EDI].[dbo].[InboundInventory_Web] AS web
	INNER JOIN #tempInboundTransactions AS t
    ON web.RecordID = t.RecordID
    
    INSERT INTO DataTrue_EDI.dbo.EDI_LoadStatus_ACH
    (
	 [PartnerID]
	,[FileName]
	,[LoadStatus]
	,[ExceptionID]
	,[TotalRecordsLoaded]
	,[DateLoaded]
	,[PartnerType]
	,[TotalAmt]
	,[FileType]
	,[Chain]
	,[Map]
	,[Banner]
	,[EmailSent]
	,[TimeStamp]
	,[UpdatedTimeStamp]
	)
    SELECT
     (SELECT EDIName FROM DataTrue_Main.dbo.Suppliers s WHERE s.SupplierID = web.DataTrueSupplierID) --[PartnerID]
	,FileName--[FileName]
	,1--[LoadStatus]
	,0--[ExceptionID]
	,COUNT(web.RecordID)--[TotalRecordsLoaded]
	,CONVERT(DATE, GETDATE())--[DateLoaded]
	,2--[PartnerType]
	,SUM((CASE web.PurposeCode WHEN 'CR' THEN web.Qty * -1 ELSE web.Qty END) * web.Cost + ROUND(ISNULL(web.AllowanceChargeAmount, 0), 2) + web.Adjustment2)--[TotalAmt]
	,'Web_UserEntry'--[FileType]
	,(SELECT ChainIdentifier FROM DataTrue_Main.dbo.Chains c WHERE c.ChainID = web.DataTrueChainID)--[Chain]
	,'Web_UserEntry'--[Map]
	,''--[Banner]
	,0--[EmailSent]
	,GETDATE()--[TimeStamp]
	,GETDATE()--[UpdatedTimeStamp]
    FROM [DataTrue_EDI].[dbo].[InboundInventory_Web] AS web
	INNER JOIN #tempInboundTransactions AS t
    ON web.RecordID = t.RecordID 
    GROUP BY web.DataTrueChainID, web.DataTrueSupplierID, web.FileName
    
    --UPDATE RECORD STATUS IN INBOUNDINVENTORY_WEB TO 2
    UPDATE web
    SET RecordStatus = 2
    FROM [DataTrue_EDI].[dbo].[InboundInventory_Web] AS web
    INNER JOIN #tempInboundTransactions AS t
    ON web.RecordID = t.RecordID

COMMIT TRANSACTION

END TRY

BEGIN CATCH

ROLLBACK TRANSACTION

	DECLARE @errormessage nvarchar(4000)
	DECLARE @errorlocation nvarchar(255)
	DECLARE @errorsenderstring nvarchar(255)
	SET @errormessage = ERROR_MESSAGE()
	SET @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
	SET @errorsenderstring = ERROR_PROCEDURE()
	
	EXEC dbo.prLogExceptionAndNotifySupport
		 1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,0
		
	EXEC dbo.prSendEmailNotification_PassEmailAddresses 'Error in prACH_MoveWebRecordsToACHTable'
				,'Job Billing_Regulated_NewInvoiceData_MoveToApprovalTable has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'		

END CATCH

END
GO
