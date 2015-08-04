USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Supplier_Add_Stores_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[prUtil_Supplier_Add_Stores_PRESYNC_20150415]

--CHAIN PARAMS
@paramChainID INT,
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
	
	--MISC VARIABLES
	DECLARE @SQL VARCHAR(MAX)
	
	--ERROR VARIABLES
	DECLARE @errorMessage VARCHAR(4000)
	DECLARE @errorLocation VARCHAR(255)
	DECLARE @errorSenderString VARCHAR(255)
	
	--SET VARIABLES
	SELECT @ChainIdentifier = ChainIdentifier FROM DataTrue_Main.dbo.Chains WHERE ChainID = @paramChainID
	
    --BULK INSERT CSV FILE		   
    CREATE TABLE #tmpData(ChainIdentifier VARCHAR(50), ChainID VARCHAR(10))	
	INSERT INTO #tmpData (ChainIdentifier, ChainID) VALUES (@ChainIdentifier, @paramChainID)
		
	SET @SQL = 'IF OBJECT_ID(''[DataTrue_EDI].[dbo].[tempEDI_Stores_' + @ChainIdentifier + ']'', ''U'') IS NOT NULL DROP TABLE [DataTrue_EDI].[dbo].[tempEDI_Stores_' + @ChainIdentifier + ']'
	EXEC (@SQL)
	
	SET @SQL =
	'CREATE TABLE [DataTrue_EDI].[dbo].[tempEDI_Stores_' + @ChainIdentifier + ']
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
	'BULK INSERT [DataTrue_EDI].[dbo].[tempEDI_Stores_' + @ChainIdentifier + '] 
	FROM ''' + @paramStoreAccountPath + ''' 
	WITH (FIELDTERMINATOR = '','', ROWTERMINATOR = ''\n'')'	
	EXEC (@SQL)
	
	SET @SQL = 	
	'INSERT INTO [DataTrue_EDI].[dbo].[Load_StoreClusters]
	(
	   [ChainIdentifier]
      ,[ClusterIdentifier]
      ,[LoadStatus]
      ,[DateTimeCreated]
      ,[FileName]
	)
	SELECT DISTINCT
	(SELECT TOP (1) ChainIdentifier FROM #tmpData)--[ChainIdentifier]
	,column13--[ClusterIdentifier]
	,0--[LoadStatus]
	,GETDATE()--[DateTimeCreated]
	,''' + @paramStoreAccountPath + '''--[FileName]
	FROM [DataTrue_EDI].[dbo].[tempEDI_Stores_' + @ChainIdentifier + '] 
	WHERE (UPPER(column1) NOT IN (''BANNER'', ''CHAIN'')) AND ISNULL(column1, '''') <> '''' AND ISNULL(column13, '''') <> '''''
	EXEC (@SQL)
	
	SET @SQL = 	
	'INSERT INTO [DataTrue_EDI].[dbo].[Load_Stores]
	(
	 [ChainIdentifier]
	,[StoreIdentifier]
	,[StoreClusterIdentifier]
	,[StoreManager]
	,[StoreName]
	,[Address]
	,[Address2]
	,[City]
	,[State]
	,[Zip]
	,[Tel]
	,[MobileTel]
	,[Fax]
	,[Email]
	,[ActiveStartDate]
	,[ActiveEndDate]
	,[LoadStatus]
	,[SBTNo]
	,[LegacySystemStoreIdentifier]
	,[DateTimeCreated]
	,[Banner]
	,[FileName]
	)
	SELECT
	(SELECT TOP (1) ChainIdentifier FROM #tmpData)--[ChainIdentifier]
	,column2--[StoreIdentifier]
	,column13--[StoreClusterIdentifier]	
	,column11--[StoreManager]
	,(SELECT ChainName FROM DataTrue_Main.dbo.Chains WHERE ChainIdentifier = (SELECT TOP (1) ChainIdentifier FROM #tmpData)) + '' #'' + column2--[StoreName]
	,column4--[Address]
	,''''--[Address2]
	,column5--[City]
	,column6--[State]
	,column7--[Zip]
	,column8--[Tel]
	,column9--[MobileTel]
	,column10--[Fax]
	,''''--[Email]
	,GETDATE()--[ActiveStartDate]
	,''12/31/2025''--[ActiveEndDate]
	,0--[LoadStatus]
	,column2--[SBTNo]
	,(SELECT TOP (1) ChainIdentifier FROM #tmpData) + column2--[LegacySystemStoreIdentifier]
	,GETDATE()--[DateTimeCreated]
	,column14--[Banner]
	,''' + @paramStoreAccountPath + '''--[FileName]
	FROM [DataTrue_EDI].[dbo].[tempEDI_Stores_' + @ChainIdentifier + '] 
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
	SET @SQL = 'IF OBJECT_ID(''[DataTrue_EDI].[dbo].[tempEDI_Stores_' + @ChainIdentifier + ']'', ''U'') IS NOT NULL DROP TABLE [DataTrue_EDI].[dbo].[tempEDI_Stores_' + @ChainIdentifier + ']'
	EXEC (@SQL)
	
COMMIT TRANSACTION
	
	--EXEC DataTrue_Main.dbo.prUtil_Load_Clusters
	--EXEC DataTrue_Main.dbo.prUtil_Load_Stores

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
