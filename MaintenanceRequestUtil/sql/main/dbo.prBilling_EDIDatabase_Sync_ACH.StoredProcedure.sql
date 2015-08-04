USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_EDIDatabase_Sync_ACH]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[prBilling_EDIDatabase_Sync_ACH]

AS

BEGIN TRY

--BEGIN TRANSACTION

DECLARE @ProcessID INT

SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobName = 'DailyRegulatedBilling'


DECLARE @rownumb INT
DECLARE @source VARCHAR(255)
SET @source = 'SP.[prBilling_EDIDatabase_Sync_ACH]'

EXEC dbo.[Audit_Log_SP] 'STEP 000 ENTRY POINT =>',@source

declare @lastarchivemaxrowid bigint=0
select @lastarchivemaxrowid = LastMaxRowIDArchived
--select *
from dbo.ArchiveControl nolock
where ArchiveTableName = 'datatrue_edi.dbo.invoicedetails'

--- STEP 1
EXEC dbo.[Audit_Log_SP] 'STEP 001 => INSERT INTO [DataTrue_EDI].[dbo].[InvoiceDetails] FROM [DataTrue_Main].[dbo].[InvoiceDetails]', @source  

INSERT INTO [DataTrue_EDI].[dbo].[InvoiceDetails]
(
 [InvoiceDetailID]
,[RetailerInvoiceID]
,[SupplierInvoiceID]
,[ChainID]
,[StoreID]
,[ProductID]
,[BrandID]
,[SupplierID]
,[InvoiceDetailTypeID]
,[TotalQty]
,[UnitCost]
,[UnitRetail]
,[TotalCost]
,[TotalRetail]
,[SaleDate]
,[RecordStatus]
,[RecordStatusSupplier]
--,[DateTimeCreated]
,[LastUpdateUserID]
,[DateTimeLastUpdate]
,[BatchID]
,[ChainIdentifier]
,[StoreIdentifier]
,[StoreName]
,[ProductIdentifier]
,[ProductQualifier]
,[RawProductIdentifier]
,[SupplierName]
,[SupplierIdentifier]
,[BrandIdentifier]
,[DivisionIdentifier]
,[UOM]
,[SalePrice]
,[Allowance]
,[InvoiceNo]
,[PONo]
,[CorporateName]
,[CorporateIdentifier]
,[Banner]
,PromoTypeID
,PromoAllowance
,SBTNumber
,[FinalInvoiceTotalCost]
,[OriginalShrinkTotalQty]
,[PaymentDueDate]
,[PaymentID]
,[Adjustment1]
,[Adjustment2]
,[Adjustment3]
,[Adjustment4]
,[Adjustment5]
,[Adjustment6]
,[Adjustment7]
,[Adjustment8]
,[PDIParticipant]
,[RetailUOM]
,[RetailTotalQty]
,[VIN]
,[RawStoreIdentifier]
,[Route]    
,[RecordType] 
,[ProcessID] 
,[AccountCode]
,[RefIDToOriginalInvNo]
,[PackSize]
,[EDIRecordID]
)
SELECT [InvoiceDetailID]
,[RetailerInvoiceID]
,[SupplierInvoiceID]
,i.[ChainID]
,[StoreID]
,[ProductID]
,[BrandID]
,[SupplierID]
,[InvoiceDetailTypeID]
,[TotalQty]
,[UnitCost]
,[UnitRetail]
,[TotalCost]
,[TotalRetail]
,[SaleDate]
--change here wait
,0
,0
--,[DateTimeCreated]
,i.[LastUpdateUserID]
,i.[DateTimeLastUpdate]
,[BatchID]
,i.[ChainIdentifier]
,[StoreIdentifier]
,[StoreName]
,[ProductIdentifier]
,[ProductQualifier]
,[RawProductIdentifier]
,[SupplierName]
,[SupplierIdentifier]
,[BrandIdentifier]
,[DivisionIdentifier]
,[UOM]
,[SalePrice]
,[Allowance]
,[InvoiceNo]
,[PONo]
,[CorporateName]
,[CorporateIdentifier]
,[Banner]
,PromoTypeID
,isnull(PromoAllowance, 0)
,SBTNumber
,[FinalInvoiceTotalCost]
,[OriginalShrinkTotalQty]
,[PaymentDueDate]
,[PaymentID]
,[Adjustment1]
,[Adjustment2]
,[Adjustment3]
,[Adjustment4]
,[Adjustment5]
,[Adjustment6]
,[Adjustment7]
,[Adjustment8]
,CASE WHEN c.PDITradingPartner = 1 THEN 1 ELSE 0 END
,[RetailUOM]
,[RetailTotalQty]
,[VIN]
,[RawStoreIdentifier]
,[Route]  
,[RecordType] 
,[ProcessID]   
,[AccountCode]
,[RefIDToOriginalInvNo]
,[PackSize]
,[EDIRecordID]
--select *
FROM [DataTrue_Main].[dbo].[InvoiceDetails] AS i WITH (NOLOCK)
INNER JOIN [DataTrue_Main].[dbo].[Chains] AS c WITH (NOLOCK)
ON i.ChainID = c.ChainID
where 1 = 1
--and InvoiceDetailID not in (select InvoiceDetailID from DataTrue_Main..EDI_InvoiceDetailIDs)
and InvoiceDetailID not in (select InvoiceDetailID from DataTrue_EDI..InvoiceDetails nolock)
and RetailerInvoiceID is not null
and RetailerInvoiceID not in  (-33, -1)
and InvoiceDetailID > @lastarchivemaxrowid
and InvoiceDetailTypeID = 2
and ProcessID = @ProcessID

update eid set eid.SupplierInvoiceID = did.SupplierInvoiceID
from DataTrue_Main..InvoiceDetails did
inner join DataTrue_EDI..InvoiceDetails eid
on did.InvoiceDetailID = eid.InvoiceDetailID
where eid.SupplierInvoiceID is null
and did.SupplierInvoiceID is not null
and did.ProcessID = @ProcessID


--- STEP 6
EXEC dbo.[Audit_Log_SP] 'STEP 006 => UPDATE DataTrue_EDI..InvoiceDetails SET SupplierInvoiceID FROM DataTrue_Main..InvoiceDetails', @source

update eid set eid.RetailerInvoiceID = did.RetailerInvoiceID
from DataTrue_Main..InvoiceDetails did
inner join DataTrue_EDI..InvoiceDetails eid
on did.InvoiceDetailID = eid.InvoiceDetailID
where eid.RetailerInvoiceID is null
and did.InvoiceDetailTypeID = 2
and did.ProcessID = @ProcessID


--- STEP 9
EXEC dbo.[Audit_Log_SP] 'STEP 009 => UPDATE datatrue_main.InvoicesSupplier SET OriginalAmount, OpenAmount FROM DataTrue_Main..InvoiceDetails', @source



--drop table DataTrue_EDI..InvoicesRetailer
insert into DataTrue_EDI..InvoicesRetailer 
select * from DataTrue_Main..InvoicesRetailer nolock
where retailerinvoiceid not in (select retailerinvoiceid from DataTrue_EDI..InvoicesRetailer nolock)

--drop table DataTrue_EDI..InvoicesSupplier
--select * into DataTrue_EDI..InvoicesSupplier from InvoicesSupplier

--- STEP 10
EXEC dbo.[Audit_Log_SP] 'STEP 010 => INSERT DataTrue_EDI..InvoicesRetailer FROM DataTrue_Main..InvoicesRetailer', @source

insert into DataTrue_EDI..InvoicesSupplier 
select * from DataTrue_Main..InvoicesSupplier nolock
where Supplierinvoiceid not in (select Supplierinvoiceid from DataTrue_EDI..InvoicesSupplier nolock)
 
 --- STEP 13
EXEC dbo.[Audit_Log_SP] 'STEP 013 => UPDATE datatrue_edi.dbo.InvoicesRetailer SET OriginalAmount, OpenAmount FROM datatrue_main.dbo.Invoicedetails', @source
update r set r.aggregationid = m.aggregationid
from datatrue_edi.dbo.InvoicesRetailer r --with (nolock)
inner join datatrue_main.dbo.InvoicesRetailer m
on r.RetailerInvoiceid = m.RetailerInvoiceID
and r.aggregationid is null
and M.aggregationid is not null

--IF EXISTS (SELECT name 
--FROM [IC-HQSQL1REPORT].master.dbo.sysdatabases 
--WHERE ('[' + name + ']' = 'DataTrue_Report' 
--OR name = 'DataTrue_Report'))
--	BEGIN
--		INSERT INTO [IC-HQSQL1REPORT].[DataTrue_Report].[dbo].[InvoiceDetails]
--		(
--		 [InvoiceDetailID]
--		,[RetailerInvoiceID]
--		,[SupplierInvoiceID]
--		,[ChainID]
--		,[StoreID]
--		,[ProductID]
--		,[BrandID]
--		,[SupplierID]
--		,[InvoiceDetailTypeID]
--		,[TotalQty]
--		,[UnitCost]
--		,[UnitRetail]
--		,[TotalCost]
--		,[TotalRetail]
--		,[SaleDate]
--		,[RecordStatus]
--		--,[DateTimeCreated]
--		,[LastUpdateUserID]
--		,[DateTimeLastUpdate]
--		,[BatchID]
--		,[ChainIdentifier]
--		,[StoreIdentifier]
--		,[StoreName]
--		,[ProductIdentifier]
--		,[ProductQualifier]
--		,[RawProductIdentifier]
--		,[SupplierName]
--		,[SupplierIdentifier]
--		,[BrandIdentifier]
--		,[DivisionIdentifier]
--		,[UOM]
--		,[SalePrice]
--		,[Allowance]
--		,[InvoiceNo]
--		,[PONo]
--		,[CorporateName]
--		,[CorporateIdentifier]
--		,[Banner]
--		,PromoTypeID
--		,PromoAllowance
--		,SBTNumber
--		,[FinalInvoiceTotalCost]
--		,[OriginalShrinkTotalQty]
--		,[PaymentDueDate]
--		,[PaymentID]
--		,[Adjustment1]
--		,[Adjustment2]
--		,[Adjustment3]
--		,[Adjustment4]
--		,[Adjustment5]
--		,[Adjustment6]
--		,[Adjustment7]
--		,[Adjustment8]
--		,[PDIParticipant]
--		,[RetailUOM]
--		,[RetailTotalQty]
--		,[VIN]
--		,[RawStoreIdentifier]
--		,[Route]    
--		,[RecordType]  
--		,[ProcessID]
--		,[EDIRecordID]
--		)
--		SELECT [InvoiceDetailID]
--		,[RetailerInvoiceID]
--		,[SupplierInvoiceID]
--		,i.[ChainID]
--		,[StoreID]
--		,[ProductID]
--		,[BrandID]
--		,[SupplierID]
--		,[InvoiceDetailTypeID]
--		,[TotalQty]
--		,[UnitCost]
--		,[UnitRetail]
--		,[TotalCost]
--		,[TotalRetail]
--		,[SaleDate]
--		--change here wait
--		,0
--		--,[DateTimeCreated]
--		,i.[LastUpdateUserID]
--		,i.[DateTimeLastUpdate]
--		,[BatchID]
--		,i.[ChainIdentifier]
--		,[StoreIdentifier]
--		,[StoreName]
--		,[ProductIdentifier]
--		,[ProductQualifier]
--		,[RawProductIdentifier]
--		,[SupplierName]
--		,[SupplierIdentifier]
--		,[BrandIdentifier]
--		,[DivisionIdentifier]
--		,[UOM]
--		,[SalePrice]
--		,[Allowance]
--		,[InvoiceNo]
--		,[PONo]
--		,[CorporateName]
--		,[CorporateIdentifier]
--		,[Banner]
--		,PromoTypeID
--		,isnull(PromoAllowance, 0)
--		,SBTNumber
--		,[FinalInvoiceTotalCost]
--		,[OriginalShrinkTotalQty]
--		,[PaymentDueDate]
--		,[PaymentID]
--		,[Adjustment1]
--		,[Adjustment2]
--		,[Adjustment3]
--		,[Adjustment4]
--		,[Adjustment5]
--		,[Adjustment6]
--		,[Adjustment7]
--		,[Adjustment8]
--		,[PDIParticipant]
--		,[RetailUOM]
--		,[RetailTotalQty]
--		,[VIN]
--		,[RawStoreIdentifier]
--		,[Route]  
--		,[RecordType]  
--		,[ProcessID]  
--		,[EDIRecordID]
--		--select *
--		FROM [DataTrue_Main].[dbo].[InvoiceDetails] AS i WITH (NOLOCK)
--		INNER JOIN [DataTrue_Main].[dbo].[Chains] AS c WITH (NOLOCK)
--		ON i.ChainID = c.ChainID
--		where 1 = 1
--		--and InvoiceDetailID not in (select InvoiceDetailID from DataTrue_Main..EDI_InvoiceDetailIDs)
--		and InvoiceDetailID not in (select InvoiceDetailID from [IC-HQSQL1REPORT].[DataTrue_Report].[dbo].[InvoiceDetails] nolock)
--		and RetailerInvoiceID is not null
--		and RetailerInvoiceID not in  (-33, -1)
--		and InvoiceDetailID > @lastarchivemaxrowid
--		and InvoiceDetailTypeID = 2
--		and ProcessID = @ProcessID
		
		--update rpt set rpt.SupplierInvoiceID = did.SupplierInvoiceID
		--from DataTrue_Main..InvoiceDetails did
		--inner join [IC-HQSQL1REPORT].DataTrue_Report.dbo.InvoiceDetails rpt
		--on did.InvoiceDetailID = rpt.InvoiceDetailID
		--where rpt.SupplierInvoiceID is null
		--and did.SupplierInvoiceID is not null
		--and did.ProcessID = @ProcessID
		
		--;WITH NoSupplierID AS
		--(
		--	SELECT InvoiceDetailID
		--	FROM DataTrue_Main.dbo.InvoiceDetails AS did
		--	WHERE did.InvoiceDetailTypeID = 2 AND did.SupplierInvoiceID IS NOT NULL
		--	AND (SELECT SupplierInvoiceID
		--		 FROM [IC-HQSQL1REPORT].DataTrue_Report.dbo.InvoiceDetails AS rpt
		--		 WHERE rpt.InvoiceDetailTypeID = 2
		--		 AND did.InvoiceDetailID = rpt.InvoiceDetailID) IS NULL		
		--)
		--UPDATE rpt SET rpt.SupplierInvoiceID = (SELECT SupplierInvoiceID FROM NoSupplierID WHERE InvoiceDetailID = NoSupplierID.InvoiceDetailID)
		--FROM [IC-HQSQL1REPORT].DataTrue_Report.dbo.InvoiceDetails AS rpt
		
		--update rpt set rpt.RetailerInvoiceID = did.RetailerInvoiceID
		--from DataTrue_Main..InvoiceDetails did
		--inner join [IC-HQSQL1REPORT].[DataTrue_Report].dbo.InvoiceDetails rpt
		--on did.InvoiceDetailID = rpt.InvoiceDetailID
		--where rpt.RetailerInvoiceID is null
		--and did.InvoiceDetailTypeID = 2
		--and did.ProcessID = @ProcessID
		
		--insert into [IC-HQSQL1REPORT].[DataTrue_Report].dbo.InvoicesRetailer 
		--select * from DataTrue_Main.dbo.InvoicesRetailer nolock
		--where retailerinvoiceid not in (select retailerinvoiceid from [IC-HQSQL1REPORT].[DataTrue_Report].dbo.InvoicesRetailer  nolock)
		
		--insert into [IC-HQSQL1REPORT].[DataTrue_Report].dbo.InvoicesSupplier 
		--select * from DataTrue_Main.dbo.InvoicesSupplier nolock
		--where Supplierinvoiceid not in (select Supplierinvoiceid from [IC-HQSQL1REPORT].[DataTrue_Report].dbo.InvoicesSupplier nolock)
		
		--update r set r.aggregationid = m.aggregationid
		--from [IC-HQSQL1REPORT].DataTrue_Report.dbo.InvoicesRetailer r --with (nolock)
		--inner join datatrue_main.dbo.InvoicesRetailer m
		--on r.RetailerInvoiceid = m.RetailerInvoiceID
		--and r.aggregationid is null
		--and M.aggregationid is not null
		
	--END

--- STEP 16
EXEC dbo.[Audit_Log_SP] 'STEP 015 => FINISH !!!', @source

--COMMIT TRANSACTION

END TRY

BEGIN CATCH

--ROLLBACK TRANSACTION
		
		declare @errormessage varchar(max),
				@errorlocation varchar(500),
				@errorsenderstring varchar(500)

		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated_NewInvoiceData Job Stopped'
			,'An exception occurred in [prBilling_EDIDatabase_Sync_ACH].  Manual review, resolution, and re-start will be required for the job to continue.'
			,'DataTrue System', 0, 'edi@icucsolutions.com'--'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
		
		exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'Billing_Regulated_NewInvoiceData'
			
END CATCH
GO
