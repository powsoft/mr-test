USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_LoadNewSupplierStores]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_LoadNewSupplierStores]

@paramRecordID INT,
--STORE ACCOUNT EXCEL PARAMS
@paramStoreAccountPath VARCHAR(MAX)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	--MISC VARIABLES
	DECLARE @SQL VARCHAR(MAX)
	
    --BULK INSERT CSV FILE		   
		
	SET @SQL = 'IF OBJECT_ID(''[DataTrue_EDI].[dbo].[tempLoadNewSupplierStores_' + @paramRecordID + ']'', ''U'') IS NOT NULL DROP TABLE [DataTrue_EDI].[dbo].[tempLoadNewSupplierStores_' + @paramRecordID + ']'
	EXEC (@SQL)
	
	SET @SQL =
	'CREATE TABLE [DataTrue_EDI].[dbo].[tempLoadNewSupplierStores_' + @paramRecordID + ']
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
	)'
	EXEC (@SQL)	
	
	SET @SQL = 
	'BULK INSERT [DataTrue_EDI].[dbo].[tempLoadNewSupplierStores_' + @paramRecordID + '] 
	FROM ''' + @paramStoreAccountPath + ''' 
	WITH (FIELDTERMINATOR = '','', ROWTERMINATOR = ''\n'')'	
	EXEC (@SQL)
	
	SET @SQL = 	
	'INSERT INTO [DataTrue_EDI].[dbo].[LoadNewSupplierStores] 
	(
	   [LoadnewSupplierID]
	  ,[StoreID]
	  ,[CustomerStoreNumber]
	  ,[CustomerRouteNumber]
	  ,[StoreLinked]
	)
	SELECT
		''' + @paramRecordID + '''
		,Column1
		,Column10
		,Column11
		,Column9
	FROM [DataTrue_EDI].[dbo].[tempLoadNewSupplierStores_' + @paramRecordID + '] 
	WHERE ISNULL(column1, '''') <> '''' and ISNULL(Column10,'''') <> '''''	
	EXEC (@SQL)
END
GO
