USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_Newspapers_Shrink_ApproveInSettlement_FromCSV]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[prBilling_Newspapers_Shrink_ApproveInSettlement_FromCSV]
	@ChainIdentifier VARCHAR(50),
	@CSVFilePath VARCHAR(MAX)
AS
BEGIN
BEGIN TRY
BEGIN TRANSACTION

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	--MISC VARIABLES
	DECLARE @SQL VARCHAR(MAX)
	
	--ERROR VARIABLES
	DECLARE @errorMessage VARCHAR(4000)
	DECLARE @errorLocation VARCHAR(255)
	DECLARE @errorSenderString VARCHAR(255)
	
	SET @SQL = 'IF OBJECT_ID(''[DataTrue_EDI].[dbo].[temp_ShrinkApprovalCSV_' + @ChainIdentifier + ']'', ''U'') IS NOT NULL DROP TABLE [DataTrue_EDI].[dbo].[temp_ShrinkApprovalCSV_' + @ChainIdentifier + ']'
	EXEC (@SQL)
	
	SET @SQL =
	'CREATE TABLE [DataTrue_EDI].[dbo].[temp_ShrinkApprovalCSV_' + @ChainIdentifier + ']
	(
	[Chain] VARCHAR(500) NULL,
	[StoreID] VARCHAR(500) NULL,
	[W/E] VARCHAR(500) NULL,
	[Settlement Shrink $] VARCHAR(500) NULL,
	[Settlement Shrink Units] VARCHAR(500) NULL,
	[Total Shrink $] VARCHAR(500) NULL,
	[Total Shrink Units] VARCHAR(500) NULL,
	[Wholesaler] VARCHAR(500) NULL,
	[A/R] VARCHAR(500) NULL,
	)'
	EXEC (@SQL)	
	
	SET @SQL = 
	'BULK INSERT [DataTrue_EDI].[dbo].[temp_ShrinkApprovalCSV_' + @ChainIdentifier + '] 
	FROM ''' + @CSVFilePath + ''' 
	WITH (FIELDTERMINATOR = '','', ROWTERMINATOR = ''\n'', FIRSTROW = 2)'	
	EXEC (@SQL)
	
	TRUNCATE TABLE [DataTrue_EDI].[dbo].[Shrink_DCRs_Approvals] 
	
	SET @SQL = 	
	'INSERT INTO [DataTrue_EDI].[dbo].[Shrink_DCRs_Approvals] 
	(
	   [Chain]
	  ,[StoreID]
	  ,[W/E]
	  ,[Settlement Shrink $]
	  ,[Settlement Shrink Units]
	  ,[Total Shrink $]
	  ,[Total Shrink Units]
	  ,[Wholesaler]
	  ,[A/R]
	)
	SELECT
	   [Chain]
	  ,[StoreID]
	  ,[W/E]
	  ,[Settlement Shrink $]
	  ,[Settlement Shrink Units]
	  ,[Total Shrink $]
	  ,[Total Shrink Units]
	  ,[Wholesaler]
	  ,[A/R]
	FROM [DataTrue_EDI].[dbo].[temp_ShrinkApprovalCSV_' + @ChainIdentifier + ']'	
	EXEC (@SQL)
	
	--SET @SQL = 'IF OBJECT_ID(''[DataTrue_EDI].[dbo].[temp_ShrinkApprovalCSV_' + @ChainIdentifier + ']'', ''U'') IS NOT NULL DROP TABLE [DataTrue_EDI].[dbo].[temp_ShrinkApprovalCSV_' + @ChainIdentifier + ']'
	--EXEC (@SQL)

COMMIT TRANSACTION

	EXEC DataTrue_Main.dbo.[prBilling_Newspapers_Shrink_ApproveInSettlement] @ChainIdentifier

END TRY
BEGIN CATCH

	ROLLBACK TRANSACTION
	
    SET @errorMessage = ERROR_MESSAGE()
	SET @errorLocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
	
	EXEC dbo.prSendEmailNotification
	@errorLocation,
	@errorMessage,
	@errorLocation,
	63600
	
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
