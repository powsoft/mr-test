USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateProductsInStoreTransactions_Working_ACH_C2D]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[prValidateProductsInStoreTransactions_Working_ACH_C2D]
AS
DECLARE @rownumb INT
DECLARE @source VARCHAR(255)
SET @source = 'SP.[prValidateProductsInStoreTransactions_Working_ACH_C2D]'

DECLARE @current DATETIME
SET @current = GETDATE()

DECLARE @userID_Initial INT
DECLARE @userID_Success INT
DECLARE @userID_SuccessFinal INT
DECLARE @userID_NonSuccess INT
DECLARE @userID_NonSuccessBrand INT

SET @userID_Initial = 55501
SET @userID_Success = 77701
SET @userID_SuccessFinal = 77702
SET @userID_NonSuccess = 66601
SET @userID_NonSuccessBrand = 66602

DECLARE @isFailure INT
SET @isFailure = 0

BEGIN TRY
--===============================
EXEC dbo.[Audit_Log_SP] 'STEP 000 ENTRY POINT => B4 UPDATE [StoreTransactions_Working] WorkingStatus = 1 ',@source

---- STEP 1
UPDATE t 
SET 
	 t.WorkingStatus = 1
	,t.LastUpdateUserID = @userID_Initial
	,t.DateTimeLastUpdate = @current
--SELECT *
FROM 
	[dbo].[StoreTransactions_Working] AS t  WITH (NOLOCK)
	-------------------------
	INNER JOIN 
	-------------------------
	[dbo].[ProductIdentifiers] AS p  WITH (NOLOCK)
		on 
			LTRIM(RTRIM(t.UPC)) = LTRIM(RTRIM(p.IdentifierValue))
WHERE 
	p.ProductIdentifierTypeID = 2 --UPC is type 2
and t.WorkingStatus = -2
and t.WorkingSource in ('SUP-S','SUP-U')
and EDIName in( select EDIName from Suppliers WITH (NOLOCK) where IsRegulated = 1 and EDIName is not null 	)

EXEC dbo.[Audit_Log_SP] 'STEP 001 => UPDATE [StoreTransactions_Working] WorkingStatus = 1 ',@source

--- STEP 2

SELECT DISTINCT 
	  StoreTransactionID
	, ltrim(rtrim(ItemSKUReported)) as ItemNumber
	, ltrim(rtrim(UPC)) as UPC
	, ItemDescriptionReported, EDIName
INTO 
	#tempStoreTransaction
--select *
FROM 
	[dbo].[StoreTransactions_Working] WITH (NOLOCK)
WHERE WorkingStatus = 1
and WorkingSource in ('SUP-S', 'SUP-U')
and EDIName in ( SELECT EDIName FROM Suppliers WITH (NOLOCK) WHERE IsRegulated = 1 and EDIName is not null and CHARINDEX('PDI', chainidentifier) < 1 )

EXEC dbo.[Audit_Log_SP] 'STEP 002 => SELECT INSERT -> #tempStoreTransaction', @source

--- STEP 3

--DROP TABLE #tmp_stage1

CREATE TABLE #tmp_stage1
(
	ID INT IDENTITY(100000001,1)
	
	,ItemNumber VARCHAR(200)
	,UPC VARCHAR(200)
	,ItemDescriptionReported  VARCHAR(200)
	,EdiName VARCHAR(200)
	,SupplierID INT
	,ProductID INT
	,ProdIdentT2 VARCHAR(200)
	,ProdIdentT3 VARCHAR(200)
);

INSERT INTO #tmp_stage1
(
	 ItemNumber
	,UPC 
	,ItemDescriptionReported 
	,EdiName 
	,SupplierID 
	,ProductID 
	,ProdIdentT2
--	,ProdIdentT3
)
SELECT --DISTINCT 
	  ItemNumber = LTRIM(RTRIM(tmp.ItemNumber))
	, UPC = LTRIM(RTRIM(tmp.UPC))
	, tmp.ItemDescriptionReported
	, ediname = LTRIM(RTRIM(tmp.ediname))
	, s.SupplierID 
	, ProductID = MAX(pi2.ProductID) --CASE WHEN LEN(LTRIM(RTRIM(tmp.UPC)))= 12 THEN MAX(pi2.ProductID) ELSE NULL END
	, MAX(pi2.identifiervalue)
--	, MAX(pi3.IdentifierValue)
--INTO
--	#tmp_stage1	
FROM 
	#tempStoreTransaction tmp
	----------------
	LEFT OUTER JOIN
	----------------
	Suppliers AS s
		ON s.UniqueEDIName = tmp.ediname
	----------------
	LEFT OUTER JOIN
	----------------
	[dbo].[ProductIdentifiers] AS p
		ON LTRIM(RTRIM(tmp.ItemNumber)) = LTRIM(RTRIM(p.IdentifierValue))
		AND ProductIdentifierTypeID = 3 
		AND p.OwnerEntityId = s.SupplierID 
	----------------
	LEFT OUTER JOIN
	----------------
	ProductIdentifiers AS pi2
		ON 
				pi2.ProductIdentifierTypeID = 2
			AND LTRIM(RTRIM(tmp.UPC)) = LTRIM(rtrim(pi2.identifiervalue))
			AND LEN(LTRIM(RTRIM(tmp.UPC))) = 12
/*			
	----------------
	LEFT OUTER JOIN
	----------------
	ProductIdentifiers AS pi3
	    ON LTRIM(RTRIM(tmp.ItemNumber)) = LTRIM(RTRIM(pi3.IdentifierValue))
	    AND pi3.ProductIdentifierTypeID = 3	
*/	    
WHERE 
		1 = 1
	AND	p.ProductID IS NULL
GROUP BY	
	  LTRIM(RTRIM(tmp.ItemNumber))
	, LTRIM(RTRIM(tmp.UPC))
	, tmp.ItemDescriptionReported
	, LTRIM(RTRIM(tmp.ediname))
	, s.SupplierID 

--declare @productid int
--declare @itemdescriptionreported nvarchar(255)
--declare @upcfound bit

EXEC dbo.[Audit_Log_SP] 'STEP 003 => SELECT INSERT -> #tmp_stage1', @source

--- STEP 4
--insert into datatrue_main.dbo.audit_sp (tablename,stepID,operationID,recordID,info,lastupdate,subtask)
--select 'Products', '[prValidateProductsInStoreTransactions_Working_ACH_READONLY]', '1', 'NEWID', NULL, GETDATE(), convert(varchar(100),ID) + ' :: ' + itemnumber
DECLARE @maxProdID INT
SELECT @maxProdID = MAX(ProductID) FROM [dbo].[Products]
--DECLARE @current DATETIME
--SET @current = GETDATE()
DECLARE @MyID INT
SET @MyID = 53829

--SELECT * FROM [dbo].[Products] ORDER BY ProductID DESC

--=============================================================
BEGIN TRANSACTION
--=============================================================
INSERT INTO [dbo].[Products]
(
	  [ProductName]
	, [Description]
	, [ActiveStartDate]
	, [ActiveLastDate]
	, [LastUpdateUserID]
	
	, Comments 
	, DateTimeCreated
	, DateTimeLastUpdate
)
SELECT
     itemdescriptionreported
   , itemdescriptionreported
   , @current
   , '12/31/2025'
   , @userID_Success
   
   , ID
   , @current
   , @current
FROM
	#tmp_stage1	
WHERE 	
	ProductID IS NULL	
AND LEN(UPC) <> 12
----------------
UNION ALL
----------------
SELECT
     itemdescriptionreported
   , itemdescriptionreported
   , @current
   , '12/31/2025'
   , @userID_Success
   
   , ID
   , @current
   , @current	
FROM
	#tmp_stage1	
WHERE 	
	ID IN (SELECT MIN(ID) FROM #tmp_stage1 WHERE (LEN(UPC) = 12) AND (ProductID IS NULL) GROUP BY	UPC	)

--- STEP 4
EXEC dbo.[Audit_Log_SP] 'STEP 004 => INSERT NEW products -> dbo.Products', @source


--drop table #productIDMapping
SELECT
	 OldID = CONVERT(INT,Comments)
	,ProductID
INTO
	#productIDMapping
FROM
	[dbo].[Products]
WHERE
	(ProductID > /*106952*/ @maxProdID)

-- select * from #productIDMapping
--UPDATE s
--SET ProductID = pm.ProductID 
--select * from #tmp_stage2
-- drop table #tmp_stage2
SELECT
	 s.*
	,NEW_ID = ISNULL(pm.ProductID,s.ProductID) 
INTO
	#tmp_stage2
FROM
	#tmp_stage1 as s
	------------
	LEFT OUTER JOIN
	------------
	#productIDMapping as pm ON
		s.ID = pm.OldID
--WHERE
--	s.ProductID IS NULL		
	
--insert into datatrue_main.dbo.audit_sp (tablename,stepID,operationID,recordID,info,lastupdate,subtask)
--select 'ProductIdentifiers', '[prValidateProductsInStoreTransactions_Working_ACH_READONLY]', '1', ProductID , ItemNumber + '::3', GETDATE(), convert(varchar(100),ID) + ' :: ' + itemnumber
--DECLARE @current DATETIME
--SET @current = GETDATE()
--DECLARE @MyID INT
--SET @MyID = 53829


--DECLARE @current DATETIME
--SET @current = GETDATE()
--DECLARE @MyID INT
--SET @MyID = 53829
INSERT INTO [dbo].[ProductIdentifiers]
(
	 [ProductID]
	,[ProductIdentifierTypeID]
	,[OwnerEntityId]
	,[IdentifierValue]
	,[LastUpdateUserID]
	,DateTimeLastUpdate
)
SELECT
	 NEW_ID
	,3 --VIN is type 3
	,supplierid -- 0 is default entity
	,itemnumber
	,@userID_Success
	,@current
from
	#tmp_stage2	
where 	
	ProductID is null 
AND NEW_ID IS NOT NULL	--49

--- STEP 5
EXEC dbo.[Audit_Log_SP] 'STEP 005 => INSERT NEW ProductIdentifiers -> dbo.ProductIdentifiers', @source

	
--insert into datatrue_main.dbo.audit_sp (tablename,stepID,operationID,recordID,info,lastupdate,subtask)
--select 'ProductIdentifiers', '[prValidateProductsInStoreTransactions_Working_ACH_READONLY]', '1', ProductID, UPC + '::2', GETDATE()  , convert(varchar(100),ID) + ' :: ' + itemnumber
--DECLARE @current DATETIME
--SET @current = GETDATE()
--DECLARE @MyID INT
--SET @MyID = 53829
INSERT INTO [dbo].[ProductIdentifiers]
(
	 [ProductID]
	,[ProductIdentifierTypeID]
	,[OwnerEntityId]
	,[IdentifierValue]
	,[LastUpdateUserID]
	,DateTimeLastUpdate
)
SELECT
	NEW_ID
   ,2 --UPC is type 2
   ,0 -- 0 is default entity
   ,UPC
   ,@userID_Success
   ,@current
FROM
	#tmp_stage2	
WHERE 	
	ProdIdentT2 IS NULL
AND LEN(UPC) = 12
AND NEW_ID IS NOT NULL

--- STEP 6
EXEC dbo.[Audit_Log_SP] 'STEP 006 => INSERT NEW ProductIdentifiers -> dbo.ProductIdentifiers', @source


--select top 10 * from products
--INSERT INTO datatrue_main.dbo.audit_sp (tablename,stepID,operationID,recordID,info,lastupdate,subtask)
--SELECT 'ProductBrandAssignments', '[prValidateProductsInStoreTransactions_Working_ACH_READONLY]', '1', 'NEWID',ISNULL(t.ProductID,ID), GETDATE()  , convert(varchar(100),ID) + ' :: ' + itemnumber
--DECLARE @current DATETIME
--SET @current = GETDATE()
--DECLARE @MyID INT
--SET @MyID = 53829
INSERT INTO [dbo].[ProductBrandAssignments]
(
	 [BrandID]
	,[ProductID]
	,[CustomOwnerEntityID]
	,[LastUpdateUserID]
	,DateTimeCreated
)
SELECT
	 0
	,t.NEW_ID 
	,0
	,@userID_Success
	,@current 
FROM
	#tmp_stage2 as t
	-----------------
	LEFT OUTER JOIN
	-----------------
	[dbo].[ProductBrandAssignments] AS a
	ON
		t.ProductID = a.ProductID 
	AND BrandID = 0
	AND CustomOwnerEntityID = 0 

WHERE
	(NEW_ID IS NOT NULL)
AND(	
	(a.ProductID IS NULL AND t.ProductID IS NOT NULL)
OR  (t.ProductID IS NULL)
)
--INSERT INTO datatrue_main.dbo.audit_sp (tablename,stepID,operationID,recordID,info,lastupdate,subtask)
--SELECT 'ProductCategoryAssignments', '[prValidateProductsInStoreTransactions_Working_ACH_READONLY]', '1', 'NEWID', ISNULL(t.ProductID,ID), GETDATE()  , convert(varchar(100),ID) + ' :: ' + itemnumber

--- STEP 7
EXEC dbo.[Audit_Log_SP] 'STEP 007 => INSERT NEW ProductBrandAssignments -> dbo.ProductBrandAssignments', @source


--DECLARE @current DATETIME
--SET @current = GETDATE()
--DECLARE @MyID INT
--SET @MyID = 53829
INSERT INTO [dbo].[ProductCategoryAssignments]
(
	 [ProductCategoryID]
	,[ProductID]
	,[CustomOwnerEntityID]
	,[LastUpdateUserID]
	,DateTimeCreated
)
SELECT
	 0
	,t.NEW_ID
	,0
	,@userID_Success   
	,@current 
FROM
	#tmp_stage2 as t
	-----------------
	LEFT OUTER JOIN
	-----------------
	[dbo].[ProductCategoryAssignments] AS a
	ON
		t.NEW_ID = a.ProductID 
	AND productcategoryid = 0
	AND CustomOwnerEntityID = 0
WHERE
	(a.ProductID IS NULL)
AND (NEW_ID IS NOT NULL)
GROUP BY
	t.NEW_ID

--=============================================================
COMMIT TRANSACTION
--=============================================================

--- STEP 8
EXEC dbo.[Audit_Log_SP] 'STEP 008 => INSERT NEW ProductCategoryAssignments -> dbo.ProductCategoryAssignments', @source


---============================ UPDATES  and VALIDATIONS =======================================

/*
update t 
set  ProductID = NULL
    ,WorkingStatus = 1
    ,BrandID = NULL
--select t.*
from 
	#tempStoreTransaction as tmp
	--------------
	INNER JOIN
	--------------
	dbo.[StoreTransactions_Working] t
		on tmp.StoreTransactionID = t.StoreTransactionID
*/	
	
--insert into datatrue_main.dbo.audit_sp (tablename,stepID,operationID,recordID,info,lastupdate)
--select 'StoreTransactions_Working', '[prValidateProductsInStoreTransactions_Working_ACH_READONLY]', '2', t.StoreTransactionID, CONVERT(VARCHAR(100),@productid) + '::2' , GETDATE() 
--DECLARE @current DATETIME
--SET @current = GETDATE()
--DECLARE @MyID INT
--SET @MyID = 53829
--select COUNT(*) from [dbo].[StoreTransactions_Working]

--drop index [IX_StoreTransactions_Working_ProductID] ON [dbo].[StoreTransactions_Working]
--CREATE NONCLUSTERED INDEX [IX_StoreTransactions_Working_ProductID] ON [dbo].[StoreTransactions_Working] 
--(
--	[ProductID] ASC
--)
--WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]


--DECLARE @current DATETIME
--SET @current = GETDATE()
--DECLARE @MyID INT
--SET @MyID = 53829

UPDATE t 
SET 
	 t.ProductID = p.ProductID
	,t.DateTimeLastUpdate = @current
	,t.LastUpdateUserID = @userID_Success
--select p.ProductID,t.*
FROM 
	[dbo].[StoreTransactions_Working] t
	---------------
	INNER JOIN 
	---------------
	#tempStoreTransaction tmp on 
			t.ProductID IS NULL
		AND tmp.StoreTransactionID = t.StoreTransactionID
	---------------	
	INNER JOIN 
	---------------
	[dbo].[ProductIdentifiers] p on 
			p.ProductIdentifierTypeID = 2 
		AND	t.UPC = p.IdentifierValue
WHERE 
	p.ProductIdentifierTypeID = 2 --UPC is type 2
AND t.ProductID IS NULL

--- STEP 9
EXEC dbo.[Audit_Log_SP] 'STEP 009 => UPDATE StoreTransactions_Working -> SET ProductID', @source


--insert into datatrue_main.dbo.audit_sp (tablename,stepID,operationID,recordID,info,lastupdate)
--select 'StoreTransactions_Working', '[prValidateProductsInStoreTransactions_Working_ACH_READONLY]', '2', t.StoreTransactionID, CONVERT(VARCHAR(100),@productid) + '::3', GETDATE() 
--DECLARE @current DATETIME
--SET @current = GETDATE()
--DECLARE @MyID INT
--SET @MyID = 53829
UPDATE t 
SET 
	 t.ProductID = p.ProductID
	,t.DateTimeLastUpdate = @current
	,t.LastUpdateUserID = @userID_Success
--select p.ProductID,t.*
FROM 
	#tempStoreTransaction tmp
	-------------------
	INNER JOIN 
	-------------------
	[dbo].[StoreTransactions_Working] t
		on tmp.StoreTransactionID = t.StoreTransactionID
	-------------------
	INNER JOIN 
	------------------- 
	[dbo].[ProductIdentifiers] p
		on ltrim(rtrim(t.ItemSKUReported)) = ltrim(rtrim(p.IdentifierValue))
WHERE 
	p.ProductIdentifierTypeID = 3 --UPC is type 2
and t.ProductID is null

--- STEP 10
EXEC dbo.[Audit_Log_SP] 'STEP 010 => UPDATE StoreTransactions_Working -> SET ProductID', @source

--insert into datatrue_main.dbo.audit_sp (tablename,stepID,operationID,recordID,info,lastupdate)
--select 'StoreTransactions_Working', '[prValidateProductsInStoreTransactions_Working_ACH_READONLY]', '2', t.StoreTransactionID, 'status = -2', GETDATE() 
declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint

--DECLARE @MyID INT
--SET @MyID = 53829

UPDATE T SET 
	 t.WorkingStatus = -2
	,t.DateTimeLastUpdate = @current
	,t.LastUpdateUserID = @userID_NonSuccess	
--select t.*
FROM 
	#tempStoreTransaction tmp
	inner join 
	[dbo].[StoreTransactions_Working] t
		on tmp.StoreTransactionID = t.StoreTransactionID
WHERE 
	t.ProductID IS NULL
	


SET @rownumb = @@ROWCOUNT
if @rownumb > 0
begin
	SET @isFailure = 1
	--- STEP 11
	EXEC dbo.[Audit_Log_SP] 'STEP 011 => UPDATE StoreTransactions_Working -> SET WorkingStatus = -2 == REPORT UNKNOWN PRODUCT Identifiers', @source, @rownumb

	set @errormessage = 'Unknown Product Identifiers Found'
	set @errorlocation = 'prValidateProductsInStoreTransactions_Working_SUP'
	set @errorsenderstring = 'prValidateProductsInStoreTransactions_Working_SUP'
	
	exec dbo.prLogExceptionAndNotifySupport
	2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
	,@errorlocation
	,@errormessage
	,@errorsenderstring
	,@MyID
	
end

--insert into datatrue_main.dbo.audit_sp (tablename,stepID,operationID,recordID,info,lastupdate)
--select 'StoreTransactions_Working', '[prValidateProductsInStoreTransactions_Working_ACH_READONLY]', '2', t.StoreTransactionID, 'BrandID = 0', GETDATE()
--DECLARE @current DATETIME
--SET @current = GETDATE()
--DECLARE @MyID INT
--SET @MyID = 53829

UPDATE T SET 
	 t.BrandID = 0
	,t.DateTimeLastUpdate = @current
	,t.LastUpdateUserID = @userID_Success
--SELECT t.*
FROM 
	#tempStoreTransaction tmp
	--------------
	INNER JOIN 
	--------------
	[dbo].[StoreTransactions_Working] t
		on tmp.StoreTransactionID = t.StoreTransactionID
WHERE 
	t.BrandID is null
AND (LEN(t.BrandIdentifier) < 1 or t.brandidentifier IS NULL)

--- STEP 12
EXEC dbo.[Audit_Log_SP] 'STEP 012 => UPDATE StoreTransactions_Working -> SET BrandID = 0', @source

--insert into datatrue_main.dbo.audit_sp (tablename,stepID,operationID,recordID,info,lastupdate)
--select 'StoreTransactions_Working', '[prValidateProductsInStoreTransactions_Working_ACH_READONLY]', '2', t.StoreTransactionID, 'BrandID = ' + CONVERT(VARCHAR(20),b.BrandID), GETDATE()
--DECLARE @current DATETIME
--SET @current = GETDATE()
--DECLARE @MyID INT
--SET @MyID = 53829


UPDATE t 
SET 
	 t.BrandID = b.BrandID
	,t.DateTimeLastUpdate = @current
	,t.LastUpdateUserID = @userID_Success
--select *
FROM 
	#tempStoreTransaction tmp
	--------------
	INNER JOIN 
	--------------
	[dbo].[StoreTransactions_Working] t
		on tmp.StoreTransactionID = t.StoreTransactionID
	--------------	
	INNER JOIN 
	--------------
	Brands b
		on t.BrandIdentifier = b.BrandIdentifier
WHERE 
	t.BrandID IS NULL
AND len(t.BrandIdentifier) > 0

--- STEP 13
EXEC dbo.[Audit_Log_SP] 'STEP 013 => UPDATE StoreTransactions_Working -> SET BrandID = Brands.BrandID', @source


--insert into datatrue_main.dbo.audit_sp (tablename,stepID,operationID,recordID,info,lastupdate)
--select 'StoreTransactions_Working', '[prValidateProductsInStoreTransactions_Working_ACH_READONLY]', '2', t.StoreTransactionID, '(2)status = -2 ', GETDATE()
--DECLARE @current DATETIME
--SET @current = GETDATE()
--DECLARE @MyID INT
--SET @MyID = 53829

UPDATE t 
SET 
	 t.WorkingStatus = -2
	,t.DateTimeLastUpdate = @current
	,t.LastUpdateUserID = @userID_NonSuccessBrand
--select *
from 
	#tempStoreTransaction tmp
	--------------
	inner join 
	--------------
	[dbo].[StoreTransactions_Working] t
		on tmp.StoreTransactionID = t.StoreTransactionID
where 
	t.BrandID IS NULL

SET @rownumb = @@ROWCOUNT
if @rownumb > 0
	begin
		SET @isFailure = 1
		--- STEP 14
		EXEC dbo.[Audit_Log_SP] 'STEP 014 => UPDATE StoreTransactions_Working -> SET WorkingStatus = -2 == REPORT UNKNOWN Brand Identifiers', @source, @rownumb

		set @errormessage = 'Unknown Brand Identifiers Found'
		set @errorlocation = 'prValidateProductsInStoreTransactions_Working_SUP'
		set @errorsenderstring = 'prValidateProductsInStoreTransactions_Working_SUP'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@userID_NonSuccessBrand
		
	end

end try
begin catch
		rollback transaction
		
		set @loadstatus = -9998
		
		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
		exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'Billing_Regulated'
			
		Update 	DataTrue_Main.dbo.JobRunning
		Set JobIsRunningNow = 0
		Where JobName = 'DailyRegulatedBilling'	

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated Job Stopped'
				,'An exception occurred in prValidateProductsInStoreTransactions_Working_ACH.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'datatrueit@icontroldsd.com;edi@icontroldsd.com'--'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
		
		return
end catch

--insert into datatrue_main.dbo.audit_sp (tablename,stepID,operationID,recordID,info,lastupdate)
--select 'StoreTransactions_Working', '[prValidateProductsInStoreTransactions_Working_ACH_READONLY]', '2', t.StoreTransactionID, 'status = 2 ', GETDATE()
--DECLARE @current DATETIME
--SET @current = GETDATE()
--DECLARE @MyID INT
--SET @MyID = 53829
--DECLARE @loadstatus INT

set @loadstatus = 2
UPDATE t 
--select *
SET 
	  WorkingStatus = @loadstatus
	, LastUpdateUserID = @userID_SuccessFinal
	, t.DateTimeLastUpdate = @current
from 
	#tempStoreTransaction tmp
	-------------
	INNER JOIN 
	-------------
	[dbo].[StoreTransactions_Working] t
		on tmp.StoreTransactionID = t.StoreTransactionID
where 
	workingstatus = 1

--- STEP 15
EXEC dbo.[Audit_Log_SP] 'FINISH ::::: STEP 015 => UPDATE StoreTransactions_Working -> SET WorkingStatus = 2', @source

IF (@isFailure = 1)
BEGIN
	exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'Billing_Regulated'
			
	Update 	DataTrue_Main.dbo.JobRunning
	Set JobIsRunningNow = 0
	Where JobName = 'DailyRegulatedBilling'	

	exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated Job Stopped AT prValidateProductsInStoreTransactions_Working_ACH_C2D'
			,'Some errors were collected DURING prValidateProductsInStoreTransactions_Working_ACH_C2S.  Manual review, resolution, and re-start will be required for the job to continue.'
			,'DataTrue System', 0, 'datatrueit@icontroldsd.com;edi@icontroldsd.com'--'datatrueit@icontroldsd.com;edi@icontroldsd.com'	

END
RETURN
GO
