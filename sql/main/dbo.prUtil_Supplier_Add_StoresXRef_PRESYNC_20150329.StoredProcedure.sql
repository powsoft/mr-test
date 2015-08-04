USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Supplier_Add_StoresXRef_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[prUtil_Supplier_Add_StoresXRef_PRESYNC_20150329]

--CHAIN PARAMS
@paramChainID INT,
--SUPPLIER PARAMS
@paramSupplierID INT,
--STORE ACCOUNT EXCEL PARAMS
@paramStoreAccountPath VARCHAR(MAX),
--USER PARAMS
@paramInputUserID INT

AS
BEGIN
BEGIN TRY
BEGIN TRANSACTION
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	--CHAIN VARIABLES
	DECLARE @ChainIdentifier VARCHAR(50)
	
	--SUPPLIER VARIABLES
	DECLARE @SupplierIdentifier VARCHAR(50)
	DECLARE @SupplierEDIName VARCHAR(50)
	
	--MISC VARIABLES
	DECLARE @SQL VARCHAR(MAX)
	
	--ERROR VARIABLES
	DECLARE @errorMessage VARCHAR(4000)
	DECLARE @errorLocation VARCHAR(255)
	DECLARE @errorSenderString VARCHAR(255)
	
	--SET VARIABLES
	SELECT @ChainIdentifier = ChainIdentifier FROM DataTrue_Main.dbo.Chains WHERE ChainID = @paramChainID
	SELECT @SupplierIdentifier = SupplierIdentifier FROM DataTrue_Main.dbo.Suppliers WHERE SupplierID = @paramSupplierID
	SELECT @SupplierEDIName = EDIName FROM DataTrue_Main.dbo.Suppliers WHERE SupplierID = @paramSupplierID

    --BULK INSERT CSV FILE		   
    CREATE TABLE #tmpData(ChainIdentifier VARCHAR(50), ChainID VARCHAR(10), SupplierIdentifier VARCHAR(50), SupplierID VARCHAR(10))	
	INSERT INTO #tmpData (ChainIdentifier, ChainID, SupplierIdentifier, SupplierID) VALUES (@ChainIdentifier, @paramChainID, @SupplierIdentifier, @paramSupplierID)
		
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
	  ,(SELECT StoreName FROM DataTrue_Main.dbo.Stores WHERE ChainID = (SELECT TOP (1) ChainID FROM #tmpData) AND StoreIdentifier = column2)--[StoreName]
	  ,column14--[Banner]
	  ,column17--[CustomerStoreNumber]
	  ,''''--[CustomerRouteNumber]
	  ,(SELECT TOP (1) SupplierID FROM #tmpData)--[SupplierID]
	  ,(SELECT TOP (1) EDIName FROM DataTrue_Main.dbo.Suppliers WHERE SupplierIdentifier = (SELECT TOP (1) SupplierIdentifier FROM #tmpData))--[SupplierEDIName]
	  ,(SELECT StoreID FROM DataTrue_Main.dbo.Stores WHERE ChainID = (SELECT TOP (1) ChainID FROM #tmpData) AND StoreIdentifier = column2)--[StoreID]
	  ,column12--[Division]
	  ,column15--[StoreLinked]
	FROM [DataTrue_EDI].[dbo].[tempEDI_StoreCrossReference_' + @ChainIdentifier + '] 
	WHERE (UPPER(column1) NOT IN (''BANNER'', ''CHAIN'')) AND ISNULL(column1, '''') <> '''''	
	EXEC (@SQL)
	
	IF @@ROWCOUNT < 1
		BEGIN
			SET @errorMessage = 'No records inserted during load of Supplier Store Account cross reference for file ' + @paramStoreAccountPath + '.'
			RAISERROR
				(@errorMessage, -- Message text.
				 11, -- Severity.
				 1 -- State.
				 );
		END
	DROP TABLE #tmpData	
	SET @SQL = 'IF OBJECT_ID(''[DataTrue_EDI].[dbo].[tempEDI_StoreCrossReference_' + @ChainIdentifier + ']'', ''U'') IS NOT NULL DROP TABLE [DataTrue_EDI].[dbo].[tempEDI_StoreCrossReference_' + @ChainIdentifier + ']'
	EXEC (@SQL)
	
	
	IF (SELECT COUNT(*)
		FROM [DataTrue_EDI].[dbo].[EDI_StoreCrossReference]
		WHERE ChainIdentifier = @ChainIdentifier
		AND SupplierID = @paramSupplierID
		AND ISNULL(StoreID, -1) = -1) > 0
		BEGIN
			SET @errorMessage = 'Invalid stores detected during insert of Supplier Store Account cross reference for file ' + @paramStoreAccountPath + '.'
			RAISERROR
				(@errorMessage, -- Message text.
				 10, -- Severity.
				 1 -- State.
				 );
		END
		
	INSERT INTO DataTrue_EDI.dbo.TranslationMaster
	(
	TranslationTypeID,
	TranslationChainID,
	TranslationTradingPartnerIdentifier,
	TranslationSupplierID,
	TranslationStoreID,
	TranslationValueOutside,
	TranslationTargetColumn,
	ActiveStartDate,
	ActiveLastDate
	)
	SELECT
	27,
	(SELECT ChainID FROM DataTrue_Main.dbo.Chains c WHERE c.ChainIdentifier = x.ChainIdentifier),
	x.ChainIdentifier,
	(SELECT SupplierID FROM DataTrue_Main.dbo.Suppliers s WHERE s.EDIName = x.SupplierEDIName),
	(SELECT StoreID FROM DataTrue_Main.dbo.Stores s WHERE s.StoreIdentifier = x.StoreIdentifier AND s.ChainID = (SELECT ChainID FROM DataTrue_Main.dbo.Chains c WHERE c.ChainIdentifier = x.ChainIdentifier)),
	x.CustomerStoreNumber,
	'ALL',
	CONVERT(DATE, GETDATE()),
	'12/31/2099'
	FROM DataTrue_EDI.dbo.EDI_StoreCrossReference x
	WHERE CONVERT(VARCHAR(50), (SELECT StoreID FROM DataTrue_Main.dbo.Stores s WHERE s.StoreIdentifier = x.StoreIdentifier AND s.ChainID = (SELECT ChainID FROM DataTrue_Main.dbo.Chains c WHERE c.ChainIdentifier = x.ChainIdentifier)))
		  + CONVERT(VARCHAR(50), (SELECT SupplierID FROM DataTrue_Main.dbo.Suppliers s WHERE s.EDIName = x.SupplierEDIName)) 
		  NOT IN
		  (
		  SELECT DISTINCT CONVERT(VARCHAR(50), TranslationStoreID) + CONVERT(VARCHAR(50), TranslationSupplierID)
		  FROM DataTrue_EDI.dbo.TranslationMaster
		  WHERE TranslationTypeID = 27
		  )
	AND ISNULL(x.CustomerStoreNumber, '') <> ''
	AND ISNULL((SELECT StoreID FROM DataTrue_Main.dbo.Stores s WHERE s.StoreIdentifier = x.StoreIdentifier AND s.ChainID = (SELECT ChainID FROM DataTrue_Main.dbo.Chains c WHERE c.ChainIdentifier = x.ChainIdentifier)), 0) <> 0
	AND ISNULL((SELECT SupplierID FROM DataTrue_Main.dbo.Suppliers s WHERE s.EDIName = x.SupplierEDIName), 0) <> 0
	
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
