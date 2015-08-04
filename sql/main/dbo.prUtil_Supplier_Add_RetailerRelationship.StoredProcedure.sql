USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Supplier_Add_RetailerRelationship]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[prUtil_Supplier_Add_RetailerRelationship]

--CHAIN PARAMS
@paramChainID INT,
--SUPPLIER PARAMS
@paramSupplierID INT,
@paramGoLiveDate DATE,
@paramVendorID VARCHAR(100),
--STORE ACCOUNT EXCEL PARAMS
@paramStoreAccountPath VARCHAR(MAX),
--Supplier TYPE PARAMS
@paramIsRegulated BIT = 0,
@paramRegulatedRAS VARCHAR(100) = '',
@paramIsPDI BIT = 0,
--REGULATED Supplier PARAMS
@paramRegIsAutoApproved BIT = 0,
@paramRegBankAccountNo VARCHAR(50) = '',
@paramRegBankRoutingNo VARCHAR(50) = '',
--USER PARAMS
@paramInputUserID INT,
--BILLING CONTROL
@paramBillingFreq VARCHAR(15) = 'Daily',
@paramBillingDay INT = 1,
@paramBillingClosingDelay INT = 1,
@paramBillingPastDays INT = 30,
@paramBillingInvoiceSeperation INT = 3,
@paramBillingSeperateCredits INT = 1,
@paramBillingPaymentDueDays INT = 1,
@paramBillingEDIRecordStatus INT = -1,
@paramBillingEDISupplierRecordStatus INT = -1,
@paramBillingAutoReleasePayments INT = -1,
@paramBillingAggregationTypeID INT = 0,
@paramBillingRequirePOInfo BIT = 0,
--FEES
@paramFeeType INT = 3,
@paramFeeAmount MONEY,
@paramISAID varchar(10)=NULL

AS
BEGIN
BEGIN TRY
BEGIN TRANSACTION
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	--CHAIN VARIABLES
	DECLARE @ChainIdentifier VARCHAR(50)
	DECLARE @ChainISPDI int
	--SUPPLIER VARIABLES
	DECLARE @SupplierIdentifier VARCHAR(50)
	DECLARE @SupplierEDIName VARCHAR(50)
	DECLARE @SupplierName VARCHAR(50)
	
	--MISC VARIABLES
	DECLARE @SQL VARCHAR(MAX)
	DECLARE @BusinessTypeID int

	--ERROR VARIABLES
	DECLARE @errorMessage VARCHAR(4000)
	DECLARE @errorLocation VARCHAR(255)
	DECLARE @errorSenderString VARCHAR(255)
	
	--SET VARIABLES
	SELECT @ChainIdentifier = ChainIdentifier FROM DataTrue_Main.dbo.Chains WHERE ChainID = @paramChainID
	SELECT @SupplierIdentifier = SupplierIdentifier FROM DataTrue_Main.dbo.Suppliers WHERE SupplierID = @paramSupplierID
	SELECT @SupplierEDIName = EDIName FROM DataTrue_Main.dbo.Suppliers WHERE SupplierID = @paramSupplierID
	SELECT @SupplierName = SupplierName FROM DataTrue_Main.dbo.Suppliers WHERE SupplierID = @paramSupplierID
	SET @BusinessTypeID=case @paramIsRegulated when 1 then 2 else 1 end
	SELECT @ChainISPDI = PDITradingPartner FROM DataTrue_Main.dbo.Chains WHERE ChainID = @paramChainID
	
	--CREATE EDI_STORECROSSREFERENCE RECORDS
	EXEC DataTrue_Main.dbo.prUtil_Supplier_Add_StoresXRef @paramChainID, @paramSupplierID, @paramStoreAccountPath, @paramInputUserID
	
	--CREATE STORESSETUP, STORESUNIQUEVALUES, AND SUPPLIERSBANNERS RECORDS
	EXEC DataTrue_Main.dbo.prUtil_Supplier_Add_StoreSetup_Banners @paramChainID, @SupplierEDIName, @paramGoLiveDate
	
	--UPDATE DEFAULTS BASED ON PDI/REGULATED SUPPLIER
	IF @paramBillingEDIRecordStatus = -1
		BEGIN
			IF @paramIsPDI = 1
				BEGIN
					SET @paramBillingEDIRecordStatus = 25
				END
			ELSE
				BEGIN
					SET @paramBillingEDIRecordStatus = 0
				END
		END
	IF @paramBillingEDISupplierRecordStatus = -1
		BEGIN
			IF @paramIsPDI = 1
				BEGIN
					SET @paramBillingEDISupplierRecordStatus = 25
				END
			ELSE
				BEGIN
					SET @paramBillingEDISupplierRecordStatus = 0
				END
		END
	IF @paramBillingAutoReleasePayments = -1
		BEGIN
			IF @paramIsRegulated = 1
				BEGIN
					SET @paramBillingAutoReleasePayments = 1
				END
			ELSE
				BEGIN
					SET @paramBillingAutoReleasePayments = 0
				END
		END

	--INSERT VENDOR ID TRANSLATIONS REGARDLESS OF CONTEXT
	IF @ChainISPDI = 1
		BEGIN
			IF NOT EXISTS (SELECT * FROM DataTrue_Main.dbo.BillingControl WHERE ChainID=@paramChainID AND SupplierID=@paramSupplierID)
			
			EXEC DataTrue_EDI.dbo.usp_AddTranslation_26_VendorID @paramChainID, @paramSupplierID, @paramVendorID
		END
		
	--INSERT BILLING CONTROL
	DECLARE  @BillingControlNewID TABLE (BillingControlID INT)
	
	INSERT INTO DataTrue_Main.dbo.BillingControl
	(
	 [BillingControlFrequency]
	,[BillingControlDay]
	,[BillingControlClosingDelay]
	,[BillingControlNumberOfPastDaysToRebill]
	,[ChainID]
	,[SupplierID]
	,[EntityIDToInvoice]
	,[ProductSubGroupType]
	,[ProductSubGroupID]
	,[InvoiceSeparation]
	,[LastBillingPeriodEndDateTime]
	,[NextBillingPeriodEndDateTime]
	,[NextBillingPeriodRunDateTime]
	,[DateTimeCreated]
	,[LastUpdateUserID]
	,[DateTimeLastUpdate]
	,[IsActive]
	,[SeparateCredits]
	,[PaymentDueInDays]
	,[AutoReleasePaymentWhenDue]
	,[InvoiceNumberSource]
	,[PDIParticipant]
	,[ISACH]
	,[EDIRecordStatusToApply]
	,[EDIRecrodStatusSupplierToApply]
	,[AggregationTypeID]
	,[BusinessTypeID]
	)
	OUTPUT inserted.BillingControlID INTO @BillingControlNewID
	VALUES
	(
	 @paramBillingFreq--[BillingControlFrequency]
	,@paramBillingDay--[BillingControlDay]
	,@paramBillingClosingDelay--[BillingControlClosingDelay]
	,@paramBillingPastDays--[BillingControlNumberOfPastDaysToRebill]
	,@paramChainID--[ChainID]
	,@paramSupplierID--[SupplierID]
	,@paramSupplierID--[EntityIDToInvoice]
	,''--[ProductSubGroupType]
	,''--[ProductSubGroupID]
	,@paramBillingInvoiceSeperation--[InvoiceSeparation]
	,CONVERT(DATE,DATEADD(dd, -1, GETDATE()))--[LastBillingPeriodEndDateTime]
	,CONVERT(DATE,GETDATE())--[NextBillingPeriodEndDateTime]
	,CONVERT(DATE,DATEADD(dd, 1, GETDATE()))--[NextBillingPeriodRunDateTime]
	,GETDATE()--[DateTimeCreated]
	,@paramInputUserID--[LastUpdateUserID]
	,GETDATE()--[DateTimeLastUpdate]
	,1--[IsActive]
	,@paramBillingSeperateCredits--[SeparateCredits]
	,@paramBillingPaymentDueDays--[PaymentDueInDays]
	,@paramBillingAutoReleasePayments--[AutoReleasePaymentWhenDue]
	,''--[InvoiceNumberSource]
	,@paramIsPDI--[PDIParticipant]
	,@paramIsRegulated--[ISACH]
	,@paramBillingEDIRecordStatus--[EDIRecordStatusToApply]
	,@paramBillingEDISupplierRecordStatus--[EDIRecrodStatusSupplierToApply]
	,@paramBillingAggregationTypeID--[AggregationTypeID]
	,2--(1 - Non-regulated, 2 - regulated)
	)	
	
	--INSERT BILLING CONTROL SUP	

	INSERT INTO [DataTrue_Main].[dbo].[BillingControl_SUP]
	(
	BillingControlID,
	MaintainEDICreditSeparation,
	ParkFutureEffectiveDates,
	ParkFutureEffectiveDatesRegulated,
	ParkFutureDueDates,
	ParkFutureDueDatesRegulated,
	AllowBillingZeroDollarLineItems,
	AllowBillingZeroDollarLineItemsRegulated,
	AllowBillingZeroDollarInvoices,
	AllowBillingZeroDollarInvoicesRegulated,
	RoundSummedInvoice
	)
	SELECT
	BillingControlID,
	CASE WHEN @ChainISPDI = 1 THEN 1 ELSE 0 END, --MaintainEDICreditSeparation
	CASE WHEN @ChainISPDI = 1 THEN 0 ELSE 1 END, --ParkFutureEffectiveDates
	1, --ParkFutureEffectiveDatesRegulated
	CASE WHEN @ChainISPDI = 1 THEN 0 ELSE 1 END, --ParkFutureDueDates
	1, --ParkFutureDueDatesRegulated
	CASE WHEN @ChainISPDI = 1 THEN 1 ELSE 0 END, --AllowBillingZeroDollarLineItems
	CASE WHEN @ChainISPDI = 1 THEN 1 ELSE 0 END, --AllowBillingZeroDollarLineItemsRegulated
	CASE WHEN @ChainISPDI = 1 THEN 1 ELSE 0 END, --AllowBillingZeroDollarInvoices
	CASE WHEN @ChainISPDI = 1 THEN 1 ELSE 0 END, --AllowBillingZeroDollarInvoicesRegulated
	CASE WHEN @ChainISPDI = 1 THEN 1 ELSE 0 END --RoundSummedInvoice
	FROM @BillingControlNewID
	
				  
	--INSERT SERVICE FEES
	INSERT INTO [DataTrue_Main].[dbo].[ServiceFees]
	(
	 [ServiceFeeTypeID]
	,[ChainID]
	,[SupplierID]
	,[StoreID]
	,[ProductID]
	,[ServiceFeeFactorValue]
	,[ActiveStartDate]
	,[ActiveLastDate]
	,[ServiceFeeReportedToRetailerDate]
	,[FileName]
	,[Comments]
	,[DateTimeCreated]
	,[LastUpdateUserID]
	,[DateTimeLastUpdate]
	,[FromFactor]
	,[ToFactor]
	)
	VALUES
	(
	 @paramFeeType--[ServiceFeeTypeID]
	,@paramChainID--[ChainID]
	,@paramSupplierID--[SupplierID]
	,0--[StoreID]
	,0--[ProductID]
	,@paramFeeAmount--[ServiceFeeFactorValue]
	,CONVERT(DATE,GETDATE())--[ActiveStartDate]
	,'12/31/2025'--[ActiveLastDate]
	,''--[ServiceFeeReportedToRetailerDate]
	,''--[FileName]
	,''--[Comments]
	,GETDATE()--[DateTimeCreated]
	,@paramInputUserID--[LastUpdateUserID]
	,GETDATE()--[DateTimeLastUpdate]
	,'1'--[FromFactor]
	,'1000000'--[ToFactor]
	)	  
	--INSERT APPROVAL MANAGEMENT IF AUTO APPROVED
	IF @paramRegIsAutoApproved = 1
		BEGIN
			INSERT INTO [DataTrue_Main].[dbo].[ApprovalManagement]
			(
			  [ChainID]
			 ,[SupplierID]
			 ,[IsAutoApprovalRegulated]
			)
			VALUES
			(
			  @paramChainID--[ChainID]
			 ,@paramSupplierID--[SupplierID]
			 ,1--[IsAutoApprovalRegulated]
			)
		END  
		
	--INSERT INTO EDI_SupplierCrossReference_byCorp
	INSERT INTO [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp]
	(
	 [ChainIdentifier]
	,[SupplierIdentifier]
	,[SupplierName]
	,[SupplierDuns]
	,[CorporateName]
	,[CorporateIdentifier]
	,[CorporateID]
	,[VendorName]
	,[VendorIdentifier]
	,[Banner]
	,[EdiName]
	,[DataTrueSupplierID]
	,[SupplierBannerID]
	,[ChainID]
	,[IsRegulated]
	,RAS
	)
	VALUES
	(
	 @ChainIdentifier--[ChainIdentifier]
	,@SupplierIdentifier--[SupplierIdentifier]
	,@SupplierName--[SupplierName]
	,@paramVendorID--[SupplierDuns]
	,@ChainIdentifier--[CorporateName]
	,''--[CorporateIdentifier]
	,@ChainIdentifier--[CorporateID]
	,''--[VendorName]
	,''--[VendorIdentifier]
	,@ChainIdentifier--[Banner]
	,@SupplierEDIName--[EdiName]
	,@paramSupplierID--[DataTrueSupplierID]
	,''--[SupplierBannerID]
	,@paramChainID--[ChainID]
	,@paramIsRegulated
	,@paramRegulatedRAS
	)

	
	DECLARE @OutboundMap VARCHAR(100)
	SET @OutboundMap = ''
	
	IF UPPER(@paramRegulatedRAS) = 'DBEV'
		BEGIN
			SET @OutboundMap = '820_dBev'
		END
	IF UPPER(@paramRegulatedRAS) = 'VIP'
		BEGIN
			SET @OutboundMap = '820_VIP'
		END
	IF UPPER(@paramRegulatedRAS) = 'QB'
		BEGIN
			SET @OutboundMap = ''
		END
	IF UPPER(@paramRegulatedRAS) = 'SOFTEON'
		BEGIN
			SET @OutboundMap = '820'
		END
	IF UPPER(@paramRegulatedRAS) = 'ENCOMPASS'
		BEGIN
			SET @OutboundMap = '820'
			IF NOT EXISTS (SELECT * FROM DataTrue_EDI..EDI_X12Map_ACH where ChainIdentifier=@SupplierIdentifier)
				BEGIN					
					INSERT INTO DataTrue_EDI..EDI_X12Map_ACH
					SELECT @SupplierEDIName,map,Direction,Field,Segment,Qualifier,Place,FieldOrder from DataTrue_EDI..EDI_X12Map_ACH where ChainIdentifier=@paramRegulatedRAS
				END
		END		
	IF @paramRegulatedRAS = ''
		BEGIN
			SET @OutboundMap = 'EFT_Sup'
		END
		
	INSERT INTO [DataTrue_EDI].[dbo].[PartnersToProcess_ForACH]
	(
	 [partner]
	,[Map]
	,[Direction]
	,[ChainIdentifier]
	,[ChainID]
	,[SupplierID]
	,[Active]
	,[TaxID]
	,[PartnerName]
	,[UseDebitFilter]
	,[DatetimeCreated]
	)
	SELECT
 	 @SupplierEDIName
	,@OutboundMap
	,CASE WHEN @OutboundMap = '' THEN '' ELSE 'OUT' END
	,(SELECT ChainIdentifier FROM DataTrue_Main.dbo.Chains WHERE ChainID = @paramChainID)
	,@paramChainID
	,@paramSupplierID
	,1
	,CASE WHEN (SELECT TaxIDMask FROM DataTrue_Main.dbo.Chains WHERE ChainID = @paramChainID) = '99-9999999'
	      THEN (SELECT SUBSTRING(TaxID,1,2) + '-' + SUBSTRING(TaxID, 3, 7) FROM DataTrue_Main.dbo.Suppliers WHERE SupplierID = @paramSupplierID)
	      ELSE (SELECT TaxID FROM DataTrue_Main.dbo.Suppliers WHERE SupplierID = @paramSupplierID)
		  END
    ,(SELECT SupplierName FROM DataTrue_Main.dbo.Suppliers WHERE SupplierID = @paramSupplierID)
	,2
	,GETDATE()
	
	INSERT INTO [DataTrue_EDI].[dbo].[FileSpecificationsPositional]
	(
	 [PartnerID]
	,[Map]
	,[FieldName]
	,[FieldDescription]
	,[FieldinHeader]
	,[FieldType]
	,[FieldSize]
	,[FieldStart]
	,[FieldEnd]
	,[StaticFieldValue]
	,[SourceTable]
	,[SourceField]
	,[JoinTable]
	,[JoinField]
	,[HubType]
	)
	SELECT DISTINCT
	 @SupplierEDIName
	,[Map]
	,[FieldName]
	,[FieldDescription]
	,[FieldinHeader]
	,[FieldType]
	,[FieldSize]
	,[FieldStart]
	,[FieldEnd]
	,[StaticFieldValue]
	,[SourceTable]
	,[SourceField]
	,[JoinTable]
	,[JoinField]
	,[HubType]
	FROM [DataTrue_EDI].[dbo].[FileSpecificationsPositional]
	WHERE @SupplierEDIName NOT IN
	(
		SELECT DISTINCT PartnerID
		FROM [DataTrue_EDI].[dbo].[FileSpecificationsPositional]
		WHERE PartnerID = @SupplierEDIName AND Map = @OutboundMap
	)
	AND PartnerID = @paramRegulatedRAS
	
		  
COMMIT TRANSACTION
END TRY
BEGIN CATCH
ROLLBACK TRANSACTION

	SET @errorMessage = ERROR_MESSAGE()
	SET @errorLocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
	
	EXEC dbo.prSendEmailNotification
	@errorLocation,
	@errorMessage,
	@errorLocation,
	@paramInputUserID
	
    DECLARE @errorSeverity INT;
    DECLARE @errorState INT;
    
	SELECT 
        @errorMessage = ERROR_MESSAGE(),
        @errorSeverity = ERROR_SEVERITY(),
        @errorState = ERROR_STATE();
    RAISERROR (@errorMessage,
               @errorSeverity,
               @errorState
               );
END CATCH     
    
END
GO
