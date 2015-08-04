USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[preValidate_Data_4_Billing_Regulated_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[preValidate_Data_4_Billing_Regulated_PRESYNC_20150415]
AS

BEGIN TRY

BEGIN TRANSACTION

DECLARE @errormessage VARCHAR(MAX)
DECLARE @errorlocation VARCHAR(MAX)
DECLARE @errorsenderstring VARCHAR(MAX)

DECLARE @emailSubject VARCHAR(100)
DECLARE @emailBody VARCHAR(MAX)
DECLARE @emailRecipients VARCHAR(500)

declare @trace as varchar='0'
DECLARE @jobLastRan DATETIME
SELECT @jobLastRan = (SELECT JobLastRunDateTime FROM JobRunning WHERE JobName = 'DailyRegulatedBilling')
set @trace='1'
--GET APPROVED RECORDS

UPDATE Approval
SET Approval.ApprovalTimeStamp = GETDATE()
--select *
FROM DataTrue_EDI.dbo.Inbound846Inventory_ACH_Approval Approval
INNER JOIN DataTrue_EDI.dbo.Inbound846Inventory_ACH_Approval t
ON Approval.FileName = t.FileName
AND Approval.EdiName = t.EdiName
AND Approval.ChainName = t.ChainName
WHERE Approval.RecordStatus IN (5, 6)
AND t.RecordStatus IN (0)
AND t.ApprovalTimeStamp > @jobLastRan

UPDATE Approval
SET Approval.ApprovalTimeStamp = GETDATE()
--select *
FROM DataTrue_EDI.dbo.Inbound846Inventory_ACH_Approval Approval
WHERE Approval.RecordStatus IN (4)
AND Approval.ApprovalTimeStamp < @jobLastRan

DECLARE @tmpInbound846Inventory_ACH_Approval TABLE
(
	[RecordID] [bigint] NOT NULL,
	[ChainName] [varchar](50) NULL,
	[PurposeCode] [varchar](3) NULL,
	[ReportingCode] [varchar](2) NULL,
	[ReportingMethod] [nchar](15) NULL,
	[ReportingLocation] [varchar](100) NULL,
	[StoreDuns] [varchar](50) NULL,
	[ReferenceIDentification] [nchar](50) NULL,
	[ProductQualifier] [varchar](5) NULL,
	[ProductIdentifier] [varchar](50) NULL,
	[BrandIdentifier] [varchar](50) NULL,
	[SupplierDuns] [nvarchar](50) NULL,
	[SupplierIdentifier] [varchar](50) NULL,
	[StoreNumber] [varchar](50) NULL,
	[UnitMeasure] [varchar](10) NULL,
	[QtyLevel] [varchar](5) NULL,
	[Qty] [int] NULL,
	[Cost] [money] NULL,
	[Retail] [money] NULL,
	[EffectiveDate] [datetime] NULL,
	[EffectiveTime] [nvarchar](50) NULL,
	[TermDays] [nvarchar](10) NULL,
	[ItemNumber] [nvarchar](50) NULL,
	[AllowanceChargeIndicator1] [nvarchar](2) NULL,
	[AllowanceChargeCode1] [nvarchar](10) NULL,
	[AlllowanceChargeAmount1] [numeric](18, 9) NULL,
	[AllowanceChargeMethod1] [nvarchar](10) NULL,
	[AllowanceChargeIndicator2] [nvarchar](10) NULL,
	[AllowanceChargeCode2] [nvarchar](10) NULL,
	[AlllowanceChargeAmount2] [numeric](18, 9) NULL,
	[AllowanceChargeMethod2] [nvarchar](10) NULL,
	[AllowanceChargeIndicator3] [nvarchar](2) NULL,
	[AllowanceChargeCode3] [nvarchar](10) NULL,
	[AlllowanceChargeAmount3] [numeric](18, 9) NULL,
	[AllowanceChargeMethod3] [nvarchar](10) NULL,
	[AllowanceChargeIndicator4] [nvarchar](2) NULL,
	[AllowanceChargeCode4] [nvarchar](10) NULL,
	[AlllowanceChargeAmount4] [numeric](18, 9) NULL,
	[AllowanceChargeMethod4] [nvarchar](10) NULL,
	[AllowanceChargeIndicator5] [nvarchar](2) NULL,
	[AllowanceChargeCode5] [nvarchar](10) NULL,
	[AlllowanceChargeAmount5] [numeric](18, 9) NULL,
	[AllowanceChargeMethod5] [nvarchar](10) NULL,
	[AllowanceChargeIndicator6] [nvarchar](2) NULL,
	[AllowanceChargeCode6] [nvarchar](10) NULL,
	[AlllowanceChargeAmount6] [numeric](18, 9) NULL,
	[AllowanceChargeMethod6] [nvarchar](10) NULL,
	[AllowanceChargeIndicator7] [nvarchar](2) NULL,
	[AllowanceChargeCode7] [nvarchar](10) NULL,
	[AlllowanceChargeAmount7] [numeric](18, 9) NULL,
	[AllowanceChargeMethod7] [nvarchar](10) NULL,
	[AllowanceChargeIndicator8] [nvarchar](2) NULL,
	[AllowanceChargeCode8] [nvarchar](10) NULL,
	[AlllowanceChargeAmount8] [numeric](18, 9) NULL,
	[AllowanceChargeMethod8] [nvarchar](10) NULL,
	[FileName] [nvarchar](500) NULL,
	[TimeStamp] [datetime] NULL,
	[RecordStatus] [tinyint] NOT NULL,
	[EdiName] [nvarchar](50) NULL,
	[CountType] [nvarchar](10) NULL,
	[Issue] [nvarchar](10) NULL,
	[ProductName] [nvarchar](100) NULL,
	[RecordType] [tinyint] NULL,
	[RawProductIdentifier] [nvarchar](50) NULL,
	[RawStoreNo] [nvarchar](50) NULL,
	[InvoiceDueDate] [datetime] NULL,
	[DataTrueSupplierID] [int] NULL,
	[DataTrueChainID] [int] NULL,
	[DataTrueStoreID] [int] NULL,
	[DataTrueProductID] [int] NULL,
	[DataTrueBrandID] [int] NULL,
	[ShipAddress1] [nvarchar](80) NULL,
	[ShipAddress2] [nvarchar](80) NULL,
	[ShipCity] [nvarchar](80) NULL,
	[ShipState] [nvarchar](2) NULL,
	[ShipZip] [nvarchar](10) NULL,
	[ShipPhoneNo] [nvarchar](16) NULL,
	[ShipFax] [nvarchar](16) NULL,
	[ContactName] [nvarchar](80) NULL,
	[ContactPhoneNo] [nvarchar](16) NULL,
	[PurchaseOrderNo] [nvarchar](50) NULL,
	[PurchaseOrderDate] [date] NULL,
	[TermsNetDueDate] [date] NULL,
	[TermsNetDays] [nvarchar](10) NULL,
	[TermsDescription] [nvarchar](100) NULL,
	[PacksPerCase] [nvarchar](10) NULL,
	[DivisionID] [nvarchar](10) NULL,
	[RefInvoiceno] [nvarchar](50) NULL,
	[RouteNo] [nvarchar](50) NULL,
	[AccountCode] [nvarchar](100) NULL,
	[Source] [varchar](50) NULL,
	[SourceStatus] [smallint] NULL,
	[RecordStatusDetails] [varchar](120) NULL,
	[ApprovalTimeStamp] [datetime] NULL,
	[ProductSignature] [varbinary](128) NULL,
	[RefIDToOriginalInvNo] [varchar](100) NULL,
	[ProcessID] [int]
)
set @trace='2'
INSERT INTO @tmpInbound846Inventory_ACH_Approval
SELECT * FROM [DataTrue_EDI].[dbo].[Inbound846Inventory_ACH_Approval] AS i
WHERE 1 = 1
AND ApprovalTimeStamp >= @jobLastRan
AND RecordStatus <> 1
set @trace='3'

DECLARE @BadRecordCount INT
DECLARE @CALCTABLE TABLE (ChainID INT, SupplierID INT, Filename VARCHAR(120), ApprovalAmt NUMERIC(18,9), FailedValidationAmt  NUMERIC(18,9), LoadedAmt NUMERIC(18,9), WebAmt  NUMERIC(18,9), PendingAmt NUMERIC(18,9))

UPDATE load
SET load.UpdatedTimeStamp = GETDATE()
FROM DataTrue_EDI.dbo.EDI_LoadStatus_ACH load
INNER JOIN @tmpInbound846Inventory_ACH_Approval t
ON load.FileName = t.FileName
AND load.PartnerID = t.EdiName
AND load.Chain = t.ChainName
AND t.RecordStatus = 0

UPDATE ACH
SET ACH.TimeStamp = GETDATE()
FROM DataTrue_EDI.dbo.Inbound846Inventory_ACH ACH
INNER JOIN @tmpInbound846Inventory_ACH_Approval t
ON ACH.FileName = t.FileName
AND ACH.EdiName = t.EdiName
AND ACH.ChainName = t.ChainName
WHERE ACH.RecordStatus = 255

UPDATE ACH
SET ACH.TimeStamp = GETDATE()
FROM DataTrue_EDI.dbo.Inbound846Inventory_ACH ACH
INNER JOIN DataTrue_EDI.dbo.EDI_LoadStatus_ACH AS Load
ON ACH.FileName = Load.FileName
AND ACH.EdiName = Load.PartnerID
AND ACH.ChainName = Load.Chain
WHERE ACH.RecordStatus = 255
AND Load.UpdatedTimeStamp > @jobLastRan
AND ACH.TimeStamp < @jobLastRan

set @trace='4'
--CHECK TOTALS VS EDI LOAD TOTALS

INSERT INTO @CALCTABLE (ChainID, SupplierID, Filename, ApprovalAmt, FailedValidationAmt, LoadedAmt, WebAmt, PendingAmt)
SELECT
ChainID = (SELECT ChainID FROM Chains WITH (NOLOCK) WHERE ChainIdentifier = Chain)
,SupplierID = (SELECT SupplierID FROM Suppliers WITH (NOLOCK) WHERE EDIName = PartnerID)
,FileName
,0 --ApprovalAmt
,0 --FailedValidationAmt
,ROUND(CONVERT(NUMERIC(18, 9), SUM(TotalAmt - BilledAmt)), 2) AS TotalAmt
,0 --WebAmt
,0
FROM DataTrue_EDI.dbo.EDI_LoadStatus_ACH WITH (NOLOCK)
WHERE LoadStatus IN (2,3)
AND ISNULL(UpdatedTimeStamp, DateLoaded) >= @jobLastRan
GROUP BY Chain, PartnerID, FileName

UPDATE c
SET c.ApprovalAmt = Approval.TotalAmt
FROM @CALCTABLE AS c
INNER JOIN 
(
	SELECT ChainID, SupplierID, Filename, SUM(TotalAmt) AS TotalAmt
	FROM
	(
	SELECT
	(SELECT ChainID FROM Chains WHERE Chains.ChainIdentifier = Approval.ChainName) AS ChainID
	,(SELECT SupplierID FROM Suppliers WHERE Suppliers.EDIName = Approval.EdiName) AS SupplierID
	,ReferenceIDentification
	,FileName
	,TotalAmt =  ROUND(CONVERT(NUMERIC(18, 9),	
						  SUM(Qty * CONVERT(MONEY, Cost)) 
						 +SUM(ISNULL(AlllowanceChargeAmount1, 0))
						 +SUM(ISNULL(AlllowanceChargeAmount2, 0))
						 +SUM(ISNULL(AlllowanceChargeAmount3, 0))
						 +SUM(ISNULL(AlllowanceChargeAmount4, 0))
						 +SUM(ISNULL(AlllowanceChargeAmount5, 0))
						 +SUM(ISNULL(AlllowanceChargeAmount6, 0))
						 +SUM(ISNULL(AlllowanceChargeAmount7, 0))
						 +SUM(ISNULL(AlllowanceChargeAmount8, 0))
						 ), 2)
	FROM @tmpInbound846Inventory_ACH_Approval AS Approval
	GROUP BY ChainName, EdiName, FileName, ReferenceIDentification
	) t
	GROUP BY ChainID, SupplierID, FileName
) AS Approval
ON c.ChainID = Approval.ChainID
AND c.SupplierID = Approval.SupplierID
AND c.Filename = Approval.FileName

--UPDATE c
--SET c.WebAmt = Web.TotalAmt
--FROM @CALCTABLE AS c
--INNER JOIN
--(
--	SELECT ChainID, SupplierID, Filename, SUM(TotalAmt) AS TotalAmt
--	FROM
--	(
--   SELECT
--	ChainID = DataTrueChainID
--   ,SupplierID = DataTrueSupplierID
--   ,FileName
--   ,ReferenceIDentification
--   ,TotalAmt = ROUND(SUM((CASE PurposeCode WHEN 'CR' THEN Qty * -1 ELSE Qty END) * Cost + ROUND(ISNULL(AllowanceChargeAmount, 0), 2) + Adjustment2), 2)
--   FROM [DataTrue_EDI].[dbo].[InboundInventory_Web]
--   WHERE 1 = 1
--   AND LastUpdateDateTime >= @jobLastRan
--   AND RecordStatus = 2
--   GROUP BY DataTrueChainID, DataTrueSupplierID, FileName, ReferenceIDentification
--   ) t
--	GROUP BY ChainID, SupplierID, FileName
--) AS Web
--ON c.ChainID = Web.ChainID
--AND c.SupplierID = Web.SupplierID
--AND c.Filename = Web.FileName

UPDATE c
SET c.FailedValidationAmt = FailedValidationAmt.TotalAmt
FROM @CALCTABLE AS c
INNER JOIN
(
	SELECT ChainID, SupplierID, Filename, SUM(RejectedAmt) AS TotalAmt
	FROM
	(
	SELECT
	(SELECT ChainID FROM Chains WITH (NOLOCK) WHERE Chains.ChainIdentifier = Inbound846Inventory_ACH.ChainName) AS ChainID
	,(SELECT SupplierID FROM Suppliers WHERE Suppliers.EDIName = Inbound846Inventory_ACH.EdiName) AS SupplierID
	,FileName
	,ReferenceIDentification
	,RejectedAmt = ROUND(CONVERT(NUMERIC(18, 9),	
						  SUM(Qty * CONVERT(MONEY, Cost)) 
						 +SUM(ISNULL(AlllowanceChargeAmount1, 0))
						 +SUM(ISNULL(AlllowanceChargeAmount2, 0))
						 +SUM(ISNULL(AlllowanceChargeAmount3, 0))
						 +SUM(ISNULL(AlllowanceChargeAmount4, 0))
						 +SUM(ISNULL(AlllowanceChargeAmount5, 0))
						 +SUM(ISNULL(AlllowanceChargeAmount6, 0))
						 +SUM(ISNULL(AlllowanceChargeAmount7, 0))
						 +SUM(ISNULL(AlllowanceChargeAmount8, 0))
						 ), 2)
	FROM DataTrue_EDI.dbo.Inbound846Inventory_ACH WITH (NOLOCK)
	WHERE TimeStamp >= @jobLastRan
	AND RecordStatus = 255
	GROUP BY ChainName, EdiName, FileName, ReferenceIDentification
	) t
	GROUP BY ChainID, SupplierID, FileName
) AS FailedValidationAmt
ON c.ChainID = FailedValidationAmt.ChainID
AND c.SupplierID = FailedValidationAmt.SupplierID
AND c.Filename = FailedValidationAmt.FileName

SELECT * FROM @CALCTABLE
WHERE CONVERT(NUMERIC(18, 9),((LoadedAmt + WebAmt) - (ApprovalAmt + FailedValidationAmt))) <> CONVERT(NUMERIC(18, 9), 0)
SET @BadRecordCount = @@ROWCOUNT
set @trace='5'
IF @BadRecordCount > 0
	BEGIN	
		SET @errormessage =	'The total amount in DATATRUE_EDI.dbo.EDI_LoadStatus_ACH table is different from amount in DATATRUE_EDI.dbo.Inbound846Inventory_ACH_Approval table'
		SET @emailBody = @errormessage + CHAR(13) + CHAR(10)
		SET @emailBody = @emailBody + CHAR(13) + CHAR(10) + 'CHAIN NAME' + CHAR(9) + 'APPROVED AMOUNT   ' + CHAR(9) + CHAR(9) + 'REJECTED AMOUNT' + CHAR(9) + CHAR(9) + 'LOADED AMOUNT  ' + CHAR(9) + CHAR(9) + 'WEB AMOUNT     ' + CHAR(13) + CHAR(10)	
		SELECT @emailBody += (SELECT LTRIM(RTRIM(ChainIdentifier)) FROM DataTrue_Main.dbo.Chains WHERE ChainID = calc.ChainID)
							+ REPLICATE(' ', (10 - LEN((SELECT LTRIM(RTRIM(ChainIdentifier)) FROM DataTrue_Main.dbo.Chains WHERE ChainID = calc.ChainID)))) + CHAR(9)
							+ '$' + CONVERT(VARCHAR(50), CONVERT(MONEY, ApprovalAmt)) + REPLICATE(' ', (15 - LEN(CONVERT(VARCHAR(50), CONVERT(MONEY, ApprovalAmt))))) + CHAR(9) + CHAR(9) 
							+ '$' + CONVERT(VARCHAR(50), CONVERT(MONEY, FailedValidationAmt)) + REPLICATE(' ', (15 - LEN(CONVERT(VARCHAR(50), CONVERT(MONEY, FailedValidationAmt))))) + CHAR(9) + CHAR(9) 
							+ '$' + CONVERT(VARCHAR(50), CONVERT(MONEY, LoadedAmt)) + REPLICATE(' ', (15 - LEN(CONVERT(VARCHAR(50), CONVERT(MONEY, LoadedAmt))))) + CHAR(9) + CHAR(9) 
							+ '$' + CONVERT(VARCHAR(50), CONVERT(MONEY, WebAmt)) + REPLICATE(' ', (15 - LEN(CONVERT(VARCHAR(50), CONVERT(MONEY, WebAmt))))) + CHAR(13) + CHAR(10)
							FROM @CALCTABLE AS calc	
		set @trace='6'	
		RAISERROR (@errormessage , 16 , 1)
	END	
	
set @trace='7'
COMMIT TRANSACTION
set @trace='8'
END TRY

BEGIN CATCH

ROLLBACK TRANSACTION

	SET @errormessage = 'An exception was encountered in [preValidate_Data_4_Billing_Regulated]:' + error_message() + '  trace(' + @trace + ')'
	SET @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
	SET @errorsenderstring = ERROR_PROCEDURE()
	
	exec dbo.prLogExceptionAndNotifySupport
	1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
	,@errorlocation
	,@errormessage
	,@errorsenderstring
	,60630
	
	IF @emailBody IS NULL
		BEGIN
			SET @emailBody = @errormessage
		END
	
	
	exec [msdb].[dbo].[sp_stop_job] 
		@job_name = 'Billing_Regulated_NewInvoiceData'

	exec dbo.prSendEmailNotification_PassEmailAddresses 'ERROR in job Billing_Regulated_NewInvoiceData'
		,@emailBody
		,'DataTrue System', 0, 'datatrueit@icontroldsd.com;edi@icontroldsd.com'		
		
END CATCH

RETURN
GO
