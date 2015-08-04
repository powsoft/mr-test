USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Supplier_Create]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[prUtil_Supplier_Create]
--BASE Supplier PARAMS
@paramInputUserID INT,
@paramSupplierIdentifier VARCHAR(500),
@paramSupplierName VARCHAR(255),
@paramSupplierDescription VARCHAR(500) = '',
@paramSupplierDUNS VARCHAR(13),
@paramAddress VARCHAR(100),
@paramAddress2 VARCHAR(100) = '',
@paramCity VARCHAR(50),
@paramState VARCHAR(50),
@paramZip VARCHAR(10),
@paramVendorID VARCHAR(100),

--Chains to setup for
@paramChainPIPEDelimitedList VARCHAR(500),

--Supplier TYPE PARAMS
@paramIsRegulated BIT = 0,
@paramIsPDI BIT = 0,

--CONTACT Supplier PARAMS
@paramContact VARCHAR(50) = '',
@paramContactPhone VARCHAR(50) = '',
@paramContactFax VARCHAR(50) = '',
@paramContactMobile VARCHAR(50) = '',
@paramContactEmail VARCHAR(100) = '',

--BILLING CONTROL
@paramBillingFreq VARCHAR(15) = 'Daily',
@paramBillingDay INT = 1,
@paramBillingClosingDelay INT = 1,
@paramBillingPastDays INT = 0,
@paramBillingInvoiceSeperation INT = 3,
@paramBillingSeperateCredits INT = 1,
@paramBillingPaymentDueDays INT = 1,
@paramBillingEDIRecordStatus INT = -1,
@paramBillingEDISupplierRecordStatus INT = -1,
@paramBillingAutoReleasePayments INT = -1,
@paramBillingAggregationTypeID INT = 0,

--FEES
@paramFeeType INT,
@paramFeeAmount MONEY = 0.00,

--REGULATED Supplier PARAMS
@paramRegIsAutoApproved BIT = 0,
@paramRegBankAccountNo VARCHAR(50) = '',
@paramRegBankRoutingNo VARCHAR(50) = '',

--STORE ACCOUNT EXCEL PARAMS
@paramStoreAccountPathsPIPEDelimited VARCHAR(MAX)

AS

--BASE VARIABLES
DECLARE @EntityTypeID INT
DECLARE @LoadStatus INT
DECLARE @SupplierID INT
DECLARE @SupplierIDExisting INT
DECLARE @SupplierIdentifier VARCHAR(50)
DECLARE @SupplierName VARCHAR(50)
--CHAIN VARIABLES
DECLARE @ChainIdentifier VARCHAR(50)
DECLARE @ChainPOS INT
DECLARE @ChainLastPOS INT
DECLARE @ChainID INT
DECLARE @ChainCount INT
DECLARE @paramStoreAccountPath VARCHAR(500)
DECLARE @paramStoreAccountPOS INT
DECLARE @paramStoreAccountLastPOS INT
DECLARE @paramStoreAccountPathExists BIT
DECLARE @paramStoreAccountCount INT
DECLARE @paramStoreAccountExtention VARCHAR(10)
--CONTACT VARIABLES
DECLARE @ContactFName VARCHAR(50) 
DECLARE @ContactLName VARCHAR(50)
--ERROR VARIABLES
DECLARE @errorMessage VARCHAR(4000)
DECLARE @errorLocation VARCHAR(255)
DECLARE @errorSenderString VARCHAR(255)
--MISC VARIABLES
DECLARE @SQL VARCHAR(MAX)

--GET EntityTypeID FOR SUPPLIERS
SELECT @EntityTypeID = EntityTypeID FROM EntityTypes WHERE EntityTypeName = 'Supplier'

BEGIN

BEGIN TRY
	BEGIN TRANSACTION

	--VALIDATION
	SET @errorMessage = ''
	--MAKE SURE UNIQUE DUNS NUMBER
	
	SELECT @SupplierIDExisting = SupplierID FROM [DataTrue_Main].[dbo].[Suppliers] WHERE LEFT(DunsNumber, 9) = LEFT(@paramSupplierDUNS, 9)
	IF @@ROWCOUNT > 0
		BEGIN
			SELECT @SupplierIdentifier = SupplierIdentifier FROM [DataTrue_Main].[dbo].[Suppliers] WHERE LEFT(DunsNumber, 9) = LEFT(@paramSupplierDUNS, 9)
			SELECT @SupplierName = SupplierName FROM [DataTrue_Main].[dbo].[Suppliers] WHERE LEFT(DunsNumber, 9) = LEFT(@paramSupplierDUNS, 9)
			SET @errorMessage = 'DUNS Number (' + @paramSupplierDUNS + ') already existings in system
								 under Supplier ID: (' + CONVERT(VARCHAR(10),@SupplierIDExisting) + '/' +
								 @SupplierIdentifier + ') and Supplier Name: ' + @SupplierName + '.'
		END
	--CHECK FORMATS
	IF REPLACE(@paramSupplierName, ' ', '') = ''
		BEGIN
			SET @errorMessage = 'Supplier must have a valid name.'
		END
	SET @paramSupplierDUNS = REPLACE(REPLACE(@paramSupplierDUNS, ' ', ''), '-', '')
	IF (LEN(@paramSupplierDUNS) <> 9 AND LEN(@paramSupplierDUNS) <> 13) OR ISNUMERIC(@paramSupplierDUNS) = 0
		BEGIN
			SET @errorMessage = 'Supplier must have a valid DUNS.  http://mycredit.dnb.com/search-for-duns-number/ may help.'
		END
	IF REPLACE(@paramAddress, ' ', '') = ''
		BEGIN
			SET @errorMessage = 'Supplier must have a valid address.'
		END
	IF REPLACE(@paramCity, ' ', '') = ''
		BEGIN
			SET @errorMessage = 'Supplier must have a valid city.'
		END
	IF REPLACE(@paramState, ' ', '') = ''
		BEGIN
			SET @errorMessage = 'Supplier must have a valid state.'
		END
	SET @paramZip = REPLACE(REPLACE(@paramZip, ' ', ''), '-', '')
	IF (LEN(@paramZip) <> 5 AND LEN(@paramZip) <> 9) OR ISNUMERIC(@paramZip) = 0
		BEGIN
			SET @errorMessage = 'Supplier must have a valid zip code.'
		END
	IF @paramContactPhone <> ''
		BEGIN
			SET @paramContactPhone = REPLACE(REPLACE(REPLACE(REPLACE(@paramContactPhone, ' ', ''), '-', ''), ')', ''), '(', '')
			DECLARE @tempContactPhone VARCHAR(50)
			SET @tempContactPhone = REPLACE(REPLACE(REPLACE(REPLACE(@paramContactPhone, 'e', ''), 'x', ''), 't', ''), '.', '')
			IF (LEN(@tempContactPhone) < 7) OR ISNUMERIC(@tempContactPhone) = 0
				BEGIN
					SET @errorMessage = 'Supplier contact phone number must be a valid format.'
				END
		END	
	IF @paramContactFax <> ''
		BEGIN
			SET @paramContactFax = REPLACE(REPLACE(REPLACE(REPLACE(@paramContactFax, ' ', ''), '-', ''), ')', ''), '(', '')
			DECLARE @tempContactFax VARCHAR(50)
			SET @tempContactFax = REPLACE(REPLACE(REPLACE(REPLACE(@paramContactFax, 'e', ''), 'x', ''), 't', ''), '.', '')
			IF (LEN(@tempContactFax) < 7) OR ISNUMERIC(@tempContactFax) = 0
				BEGIN
					SET @errorMessage = 'Supplier contact fax number must be a valid format.'
				END
		END	
	IF @paramContactMobile <> ''
		BEGIN
			SET @paramContactMobile = REPLACE(REPLACE(REPLACE(REPLACE(@paramContactMobile, ' ', ''), '-', ''), ')', ''), '(', '')
			DECLARE @tempContactMobile VARCHAR(50)
			SET @tempContactMobile = REPLACE(REPLACE(REPLACE(REPLACE(@paramContactMobile, 'e', ''), 'x', ''), 't', ''), '.', '')
			IF (LEN(@tempContactMobile) < 7) OR ISNUMERIC(@tempContactMobile) = 0
				BEGIN
					SET @errorMessage = 'Supplier contact mobile number must be a valid format.'
				END
		END	
	IF @paramContactEmail <> ''
		BEGIN
			IF (CHARINDEX('@', @paramContactEmail, 0) = 0) OR (CHARINDEX('.', @paramContactEmail, 0) = 0)
				BEGIN
					SET @errorMessage = 'Supplier contact email address must be a valid format.'
				END
		END	
	IF (UPPER(@paramBillingFreq) <> 'DAILY' AND  UPPER(@paramBillingFreq) <> 'WEEKLY')
		BEGIN
			SET @errorMessage = 'Supplier billing frequency must either be daily or weekly.'
		END
	
	--VALIDATE ALL CHAIN ASSIGNMENTS
	SET @ChainIdentifier = @paramChainPIPEDelimitedList
	SET @ChainLastPOS = 0
	SET @ChainPOS = 0	
	SET @ChainCount = 0
	WHILE (ISNULL(@ChainIdentifier, '') <> '')
	BEGIN
		SET @ChainCount = (@ChainCount + 1)
		SET @ChainPOS = CHARINDEX('|', @paramChainPIPEDelimitedList, @ChainLastPOS )
		IF ISNULL(@ChainPOS, 0) = 0
			BEGIN
				SET @ChainPOS = (LEN(@paramChainPIPEDelimitedList) + 1)
			END		
		SET @ChainIdentifier = SUBSTRING(@paramChainPIPEDelimitedList, (@ChainLastPOS), (@ChainPOS-@ChainLastPOS))
		--ATTEMPT TO GET CHAIN ID
		SET @ChainID = (SELECT ChainID FROM [DataTrue_Main].[dbo].[Chains] WHERE ChainIdentifier = @ChainIdentifier)
		IF ISNULL(@ChainID, 0) = 0
			BEGIN				
				SET @errorMessage = @ChainIdentifier + ' is not a valid Chain Identifier.'
				SET @ChainIdentifier = ''
			END
		ELSE
			BEGIN
				SET @ChainLastPOS = (@ChainPOS + 1)
				IF @ChainLastPOS >= LEN(@paramChainPIPEDelimitedList)
					BEGIN
						SET @ChainIdentifier = ''
					END
			END	
	END
	
	--VALIDATE STORE ACCOUNT CROSS REFERENCES
	SET @paramStoreAccountPath = @paramStoreAccountPathsPIPEDelimited
	SET @paramStoreAccountPOS = 0
	SET @paramStoreAccountLastPOS = 0
	SET @paramStoreAccountCount = 0
	WHILE (ISNULL(@paramStoreAccountPath, '') <> '')
	BEGIN
		SET @paramStoreAccountCount = (@paramStoreAccountCount + 1)
		SET @paramStoreAccountPOS = CHARINDEX('|', @paramStoreAccountPathsPIPEDelimited, @paramStoreAccountLastPOS )
		IF ISNULL(@paramStoreAccountPOS, 0) = 0
			BEGIN
				SET @paramStoreAccountPOS = (LEN(@paramStoreAccountPathsPIPEDelimited) + 1)
			END		
		SET @paramStoreAccountPath = SUBSTRING(@paramStoreAccountPathsPIPEDelimited, (@paramStoreAccountLastPOS), (@paramStoreAccountPOS-@paramStoreAccountLastPOS))
		--CHECK FILE EXTENTION FOR CSV
		SET @paramStoreAccountExtention =
			(CASE WHEN @paramStoreAccountPath LIKE '%.%'
              THEN REVERSE(LEFT(REVERSE(@paramStoreAccountPath), CHARINDEX('.', REVERSE(@paramStoreAccountPath)) - 1))
              ELSE ''
			 END)
		IF UPPER(@paramStoreAccountExtention) <> 'CSV'
			BEGIN
				SET @paramStoreAccountPath = ''
				SET @errorMessage = @paramStoreAccountPath + ' is not a valid CSV file.  Extention must be .CSV.'
			END
		--SEE IF FILE EXISTS
		SET @paramStoreAccountPathExists = DataTrue_EDI.dbo.fn_FileExists(@paramStoreAccountPath)
		IF ISNULL(@paramStoreAccountPathExists, 0) = 0
			BEGIN			
				SET @errorMessage = @paramStoreAccountPath + ' does not exist.'
				SET @paramStoreAccountPath = ''
			END
		ELSE
			BEGIN
				SET @paramStoreAccountLastPOS = (@paramStoreAccountPOS + 1)
				IF @paramStoreAccountLastPOS >= LEN(@paramStoreAccountPathsPIPEDelimited)
					BEGIN
						SET @paramStoreAccountPath = ''
					END
			END		
	END	
	
	--MAKE SURE CHAIN COUNT = STORE ACCOUNT SETUP COUNT
	IF @ChainCount <> @paramStoreAccountCount
		BEGIN
			SET @errorMessage = 'Mismatch in count of chains and store account lists provided.'
		END
		
	--VERIFY NEEDED REGULATED INFO
	IF @paramIsRegulated = 1
		BEGIN
			SET @paramRegBankAccountNo = [DataTrue_EDI].[dbo].[fn_ReplaceNonNumericChars] (@paramRegBankAccountNo)
			SET @paramRegBankRoutingNo = [DataTrue_EDI].[dbo].[fn_ReplaceNonNumericChars] (@paramRegBankRoutingNo)
			IF ISNULL(@paramRegBankAccountNo, '') = ''
				BEGIN
					SET @errorMessage = 'Bank account number must be provided for Regulated Suppliers.'
				END
			IF ISNULL(@paramRegBankRoutingNo, '') = ''
				BEGIN
					SET @errorMessage = 'Bank routing number must be provided for Regulated Suppliers.'
				END
			IF LEN(@paramRegBankRoutingNo) <> 9
				BEGIN
					SET @errorMessage = 'Bank routing number must 9 digits.'
				END 
		END
		
	IF @errorMessage <> ''
		BEGIN
			RAISERROR
				(@errorMessage, -- Message text.
                 11, -- Severity.
                 1 -- State.
                 );
		END

	--CHECK IF Supplier EXISTS
	SELECT @SupplierID = SupplierID FROM [DataTrue_Main].[dbo].[Suppliers]
	WHERE SupplierIdentifier = @paramSupplierIdentifier
	
	IF @@ROWCOUNT > 0
		BEGIN
			SET @errorMessage = @paramSupplierIdentifier + 'is an existing Supplier Identifier, please pick a new identifier.'
			RAISERROR
				(@errorMessage, -- Message text.
                 11, -- Severity.
                 1 -- State.
                 );
		END
	ELSE
		BEGIN
			--INSERT INTO SystemEntities TO GET ENTITY ID	
			INSERT INTO [DataTrue_Main].[dbo].[SystemEntities]
			(
			 [EntityTypeID]
			,[LastUpdateUserID]
			)
			VALUES
			(
			 @EntityTypeID
			,@paramInputUserID
			)
			SET @SupplierID = SCOPE_IDENTITY()
			
			--INSERT INTO Suppliers WITH SupplierID	
			INSERT INTO [DataTrue_Main].[dbo].[Suppliers]
		    (
		     [SupplierID]
		    ,[SupplierName]
		    ,[SupplierIdentifier]
		    ,[SupplierDescription]
		    ,[ActiveStartDate]
		    ,[ActiveLastDate]
		    ,[LastUpdateUserID]
		    ,[EDIName]
		    ,[DunsNumber]
		    )
			VALUES
			(
			 @SupplierID
			,@paramSupplierName
			,@paramSupplierIdentifier
			,@paramSupplierDescription
			,GETDATE()
			,'12/31/2025'
			,@paramInputUserID
			,@paramSupplierIdentifier
			,@paramSupplierDUNS
			)
		END	
		
	--INSERT ADDRESS
	INSERT INTO [DataTrue_Main].[dbo].[Addresses]
					   ([OwnerEntityID]
					   ,[AddressDescription]
					   ,[Address1]
					   ,[Address2]
					   ,[City]
					   ,[State]
					   ,[PostalCode]
					   ,[LastUpdateUserID])
				 VALUES
					   (@supplierid
					   ,'Main'
					   ,ISNULL(@paramAddress, '')
					   ,ISNULL(@paramAddress2, '')
					   ,ISNULL(@paramCity, '')
					   ,ISNULL(@paramState, '')
					   ,ISNULL(@paramZip, '')
					   ,@paramInputUserID)	
					   
	--INSERT CONTACT INFO				   		   
	IF (@paramContact <> '')
		OR (@paramContactPhone <> '')
		OR (@paramContactMobile <> '')
		OR (@paramContactFax <> '')
		OR (@paramContactEmail <> '')

		BEGIN
			
			SET @ContactFName = ''
			SET @ContactLName = ''
			
			IF @paramContact <> ''
				BEGIN
					SET @ContactFName = LEFT(LTRIM(RTRIM(ISNULL(@paramContact,''))), CHARINDEX(' ', LTRIM(RTRIM(ISNULL(@paramContact,'')))))
					SET @ContactLName = RIGHT(LTRIM(RTRIM(@paramContact)), LEN(LTRIM(RTRIM(ISNULL(@paramContact,'')))) - CHARINDEX(' ', LTRIM(RTRIM(ISNULL(@paramContact,'')))))
				END
			
			INSERT INTO [DataTrue_Main].[dbo].[ContactInfo]
			(
			 [OwnerEntityID]
			,[Title]
			,[FirstName]
			,[LastName]
			,[DeskPhone]
			,[MobilePhone]
		    ,[Fax]
		    ,[Email]
			,[LastUpdateUserID]
			)
			VALUES
			(
			 @SupplierID			
			,'Contact'
			,@ContactFName
			,@ContactLName
			,ISNULL(@paramContactPhone, '')
			,ISNULL(@paramContactMobile, '')
			,ISNULL(@paramContactFax, '')
			,ISNULL(@paramContactEmail, '')
			,@paramInputUserID
			)
		END
	
	--INSERT CROSS REFERENCES FOR SUPPLIER DUNS
	INSERT INTO [DataTrue_EDI].[dbo].[PartnerISAID]
	(
	   [PartnerId]
      ,[PartnerBanner]
      ,[PartnerISAQualifier]
      ,[PartnerISAID]
      ,[PartnerGSID]
      ,[IcontrolISAQualifier]
      ,[IcontrolISAID]
     )
     VALUES
     (
       @paramSupplierIdentifier--[PartnerId]
      ,@paramSupplierIdentifier--[PartnerBanner]
      ,''--[PartnerISAQualifier]
      ,@paramSupplierDUNS--[PartnerISAID]
      ,''--[PartnerGSID]
      ,'12'--[IcontrolISAQualifier]
      ,'2023457532'--[IcontrolISAID]
     )
	
			
	--INSERT BILLING CONTROL
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
	
	--INSERT INTO TABLES FOR EACH CHAIN ASSIGNMENT
	SET @ChainIdentifier = @paramChainPIPEDelimitedList
	SET @ChainLastPOS = 0
	SET @ChainPOS = 0	
	SET @ChainCount = 0
	WHILE (ISNULL(@ChainIdentifier, '') <> '')
	BEGIN
		SET @ChainCount = (@ChainCount + 1)
		SET @ChainPOS = CHARINDEX('|', @paramChainPIPEDelimitedList, @ChainLastPOS )
		IF ISNULL(@ChainPOS, 0) = 0
			BEGIN
				SET @ChainPOS = (LEN(@paramChainPIPEDelimitedList) + 1)
			END		
		SET @ChainIdentifier = SUBSTRING(@paramChainPIPEDelimitedList, (@ChainLastPOS), (@ChainPOS-@ChainLastPOS))
		--GET CHAIN ID (ALREADY VALIDATED)
		SET @ChainID = (SELECT ChainID FROM [DataTrue_Main].[dbo].[Chains] WHERE ChainIdentifier = @ChainIdentifier)
		
		CREATE TABLE #tmpData(ChainIdentifier VARCHAR(50), ChainID VARCHAR(10), SupplierIdentifier VARCHAR(50), SupplierID VARCHAR(10))	
		INSERT INTO #tmpData (ChainIdentifier, ChainID, SupplierIdentifier, SupplierID) VALUES (@ChainIdentifier, @ChainID, @paramSupplierIdentifier, @SupplierID)
				
		INSERT INTO DataTrue_Main.dbo.BillingControl
			  (
			   [BillingControlFrequency]
			  ,[BillingControlDay]
			  ,[BillingControlClosingDelay]
			  ,[BillingControlNumberOfPastDaysToRebill]
			  ,[ChainID]
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
			  )
		VALUES
			  (
			   @paramBillingFreq--[BillingControlFrequency]
			  ,@paramBillingDay--[BillingControlDay]
			  ,@paramBillingClosingDelay--[BillingControlClosingDelay]
			  ,@paramBillingPastDays--[BillingControlNumberOfPastDaysToRebill]
			  ,@ChainID--[ChainID]
			  ,@SupplierID--[EntityIDToInvoice]
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
			  )				  
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
			  ,@ChainID--[ChainID]
			  ,@SupplierID--[SupplierID]
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
				  @ChainID--[ChainID]
				 ,@SupplierID--[SupplierID]
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
		  ,[SupplierDuns1]
		  ,[SupplierBannerID]
		  ,[ChainID]
		)
		VALUES
		(
		   @ChainIdentifier--[ChainIdentifier]
		  ,@paramSupplierIdentifier--[SupplierIdentifier]
		  ,@paramSupplierName--[SupplierName]
		  ,@paramVendorID--[SupplierDuns]
		  ,''--[CorporateName]
		  ,''--[CorporateIdentifier]
		  ,@ChainIdentifier--[CorporateID]
		  ,''--[VendorName]
		  ,''--[VendorIdentifier]
		  ,@ChainIdentifier--[Banner]
		  ,@paramSupplierIdentifier--[EdiName]
		  ,@SupplierID--[DataTrueSupplierID]
		  ,@paramSupplierDUNS--[SupplierDuns1]
		  ,''--[SupplierBannerID]
		  ,@ChainID--[ChainID]
		)
		
		--STORE ACCOUNT CROSS REFERENCE
		
		--GET CORRECT EXCEL FILE
		SET @paramStoreAccountPath = @paramStoreAccountPathsPIPEDelimited
		SET @paramStoreAccountPOS = 0
		SET @paramStoreAccountLastPOS = 0
		SET @paramStoreAccountCount = 0
		WHILE (ISNULL(@paramStoreAccountCount, 0) <> @ChainCount)
		BEGIN
			SET @paramStoreAccountCount = (@paramStoreAccountCount + 1)
			SET @paramStoreAccountPOS = CHARINDEX('|', @paramStoreAccountPathsPIPEDelimited, @paramStoreAccountLastPOS )
			IF ISNULL(@paramStoreAccountPOS, 0) = 0
				BEGIN
					SET @paramStoreAccountPOS = (LEN(@paramStoreAccountPathsPIPEDelimited) + 1)
				END		
			SET @paramStoreAccountPath = SUBSTRING(@paramStoreAccountPathsPIPEDelimited, (@paramStoreAccountLastPOS), (@paramStoreAccountPOS-@paramStoreAccountLastPOS))
			SET @paramStoreAccountLastPOS = (@paramStoreAccountPOS + 1)	
		END		
		
		--BULK INSERT CSV FILE	
		
		SET @SQL = 'IF OBJECT_ID(''[DataTrue_EDI].[dbo].[tempEDI_StoreCrossReference_' + @ChainIdentifier + ']'', ''U'') IS NOT NULL DROP TABLE [DataTrue_EDI].[dbo].[tempEDI_StoreCrossReference_' + @ChainIdentifier + ']'
		EXEC (@SQL)
		
		SET @SQL =
		'CREATE TABLE [DataTrue_EDI].[dbo].[tempEDI_StoreCrossReference_' + @ChainIdentifier + ']
		(
		column1 VARCHAR(200) NULL,
		column2 VARCHAR(200) NULL,
		column3 VARCHAR(200) NULL,
		column4 VARCHAR(200) NULL,
		column5 VARCHAR(200) NULL,
		column6 VARCHAR(200) NULL,
		column7 VARCHAR(200) NULL,
		column8 VARCHAR(200) NULL,
		column9 VARCHAR(200) NULL,
		column10 VARCHAR(200) NULL,
		column11 VARCHAR(200) NULL,
		column12 VARCHAR(200) NULL,
		column13 VARCHAR(200) NULL,
		column14 VARCHAR(200) NULL,
		column15 VARCHAR(200) NULL,
		column16 VARCHAR(200) NULL,
		column17 VARCHAR(200) NULL,
		)'
		EXEC (@SQL)	
		
		SET @SQL = 
		'BULK INSERT [DataTrue_EDI].[dbo].[tempEDI_StoreCrossReference_' + @ChainIdentifier + '] 
		FROM ''' + @paramStoreAccountPath + ''' 
		WITH (FIELDTERMINATOR = '','', ROWTERMINATOR = ''\n'')'	
		EXEC (@SQL)
		
		SET @SQL = 	
		'INSERT INTO [DataTrue_EDI].[dbo].[EDI_StoreCrossReference] 
		(
		   [ChainIdentifier]
		  ,[StoreIdentifier]
		  ,[StoreName]
		  ,[Banner]
		  ,[CustomerStoreNumber]
		  ,[CustomerRouteNumber]
		  ,[SupplierID]
		  ,[SupplierEDIName]
		  ,[StoreID]
		  ,[Division]
		  ,[StoreLinked]
		)
		SELECT
		   (SELECT TOP (1) ChainIdentifier FROM #tmpData)--[ChainIdentifier]
		  ,column2--[StoreIdentifier]
		  ,(SELECT StoreName FROM [DataTrue_Main].[dbo].[Stores] WHERE ChainID = (SELECT TOP (1) ChainID FROM #tmpData) AND StoreIdentifier = column2)--[StoreName]
		  ,column1--[Banner]
		  ,column17--[CustomerStoreNumber]
		  ,''''--[CustomerRouteNumber]
		  ,(SELECT TOP (1) SupplierID FROM #tmpData)--[SupplierID]
		  ,(SELECT TOP (1) SupplierIdentifier FROM #tmpData)--[SupplierEDIName]
		  ,(SELECT StoreID FROM [DataTrue_Main].[dbo].[Stores] WHERE ChainID = (SELECT TOP (1) ChainID FROM #tmpData) AND StoreIdentifier = column2)--[StoreID]
		  ,column12--[Division]
		  ,column15--[StoreLinked]
		FROM [DataTrue_EDI].[dbo].[tempEDI_StoreCrossReference_' + @ChainIdentifier + '] 
		WHERE (UPPER(column1) <> ''BANNER'') AND ISNULL(column1, '''') <> '''''	
		EXEC (@SQL)
		
		IF @@ROWCOUNT < 1
			BEGIN
				SET @errorMessage = 'No records inserted during load of Supplier Store Account cross reference for file ' + @paramStoreAccountPath + '.'
				RAISERROR
					(@errorMessage, -- Message text.
					 10, -- Severity.
					 1 -- State.
					 );
			END
		DROP TABLE #tmpData	
		SET @SQL = 'IF OBJECT_ID(''[DataTrue_EDI].[dbo].[tempEDI_StoreCrossReference_' + @ChainIdentifier + ']'', ''U'') IS NOT NULL DROP TABLE [DataTrue_EDI].[dbo].[tempEDI_StoreCrossReference_' + @ChainIdentifier + ']'
		EXEC (@SQL)
		
		SELECT COUNT(*)
		FROM [DataTrue_EDI].[dbo].[EDI_StoreCrossReference]
		WHERE ChainIdentifier = @ChainIdentifier
			AND SupplierID = @SupplierID
			AND ISNULL(StoreID, -1) = -1
		IF @@ROWCOUNT > 0
			BEGIN
				SET @errorMessage = 'Invalid stores detected during insert of Supplier Store Account cross reference for file ' + @paramStoreAccountPath + '.'
				RAISERROR
					(@errorMessage, -- Message text.
					 11, -- Severity.
					 1 -- State.
					 );
			END
		
		--LOOP TO NEXT CHAIN
		SET @ChainLastPOS = (@ChainPOS + 1)
		IF @ChainLastPOS >= LEN(@paramChainPIPEDelimitedList)
			BEGIN
				SET @ChainIdentifier = ''
			END					
	END		
			
	--COMMIT THE TRANSACTION
	COMMIT TRANSACTION
	
	EXEC [DataTrue_Main].[dbo].[prUtil_Supplier_Create_StoreSetup_Banners] @paramSupplierIdentifier
								
END TRY


BEGIN CATCH
	ROLLBACK TRANSACTION

	SET @errorMessage = error_message()
	SET @errorLocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
	
	EXEC dbo.prSendEmailNotification
	@errorLocation,
	@errorMessage,
	@errorLocation,
	@paramInputUserID
	
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
    
	SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();
    RAISERROR (@ErrorMessage,
               @ErrorSeverity,
               @ErrorState
               );
	
END CATCH

END
GO
