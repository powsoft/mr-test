USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_EDIDatabase_Sync_DCR_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prBilling_EDIDatabase_Sync_DCR_PRESYNC_20150415]

as

BEGIN TRY

DECLARE @ProcessID INT

SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobName = 'NewspaperShrink_Invoice'


DECLARE @rownumb INT
DECLARE @source VARCHAR(255)
SET @source = 'SP.[prBilling_EDIDatabase_Sync_DCR]'
declare @cvsChainID int=60626
/*
Insert into EDI_InvoiceDetailIDs
select InvoicedetailID
from datatrue_edi.dbo.Invoicedetails
where 1 = 1
and InvoiceDetailID not in (select InvoiceDetailID from DataTrue_EDI..InvoiceDetails)
*/
--===============================
EXEC dbo.[Audit_Log_SP] 'STEP 000 ENTRY POINT =>',@source

declare @lastarchivemaxrowid bigint=0
select @lastarchivemaxrowid = LastMaxRowIDArchived
--select *
from dbo.ArchiveControl
where ArchiveTableName = 'datatrue_edi.dbo.invoicedetails'

--- STEP 5
EXEC dbo.[Audit_Log_SP] 'STEP 005 => INSERT INTO [DataTrue_EDI].[dbo].[InvoiceDetails] FROM [DataTrue_Main].[dbo].[InvoiceDetails]', @source

INSERT INTO [DataTrue_EDI].[dbo].[InvoiceDetails_Shrink]
           ([InvoiceDetailID]
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
          -- ,[DateTimeCreated]
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
      ,[DateSentToRetailer]
      ,[RecordStatusSupplier]
      ,[DateSentToSupplier]
      ,[ProcessId]
      ,[EDIRecordID])
SELECT [InvoiceDetailID]
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
      --change here wait
      ,CASE WHEN RecordStatus = 821 THEN 1 ELSE case when upper(banner) = 'SS' then 8 else 7 end END
      --,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[BatchID]
                 ,[ChainIdentifier]
           ,SBTNumber --20130923 [StoreIdentifier]
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
      ,[PDIParticipant]
      ,[RetailUOM]
      ,[RetailTotalQty]
	  ,CASE WHEN RecordStatus = 821 THEN GETDATE() ELSE NULL END  --,[DateSentToRetailer]
	  ,0 --,[RecordStatusSupplier]
	  ,NULL --,[DateSentToSupplier]
	  ,[ProcessID] 
	  ,[EDIRecordID]
			--select *
  FROM [DataTrue_Main].[dbo].[InvoiceDetails] with (index(1))
	where InvoiceDetailID not in (select InvoiceDetailID from DataTrue_EDI..InvoiceDetails_Shrink with (index(20)))
	and RetailerInvoiceID is not null
	and RetailerInvoiceID not in  (-33, -1)
	and InvoiceDetailTypeID in (3, 9, 11)
	AND ProcessID = @ProcessID
	option (merge join, maxdop 1)

--- STEP 6
EXEC dbo.[Audit_Log_SP] 'STEP 005.1 => INSERT INTO [DataTrue_EDI].[dbo].[InvoiceDetails_Shrink] FROM [DataTrue_Main].[dbo].[InvoiceDetails]', @source

insert into DataTrue_EDI..InvoicesRetailer 
select * from DataTrue_Main..InvoicesRetailer
where retailerinvoiceid not in (select retailerinvoiceid from DataTrue_EDI..InvoicesRetailer)
AND ProcessID = @ProcessID

--- STEP 10
EXEC dbo.[Audit_Log_SP] 'STEP 010 => INSERT DataTrue_EDI..InvoicesRetailer FROM DataTrue_Main..InvoicesRetailer', @source

insert into DataTrue_EDI..InvoicesSupplier 
select * from DataTrue_Main..InvoicesSupplier
where Supplierinvoiceid not in (select Supplierinvoiceid from DataTrue_EDI..InvoicesSupplier)
AND ProcessID = @ProcessID

--- STEP 16
EXEC dbo.[Audit_Log_SP] 'STEP 015 => FINISH !!!', @source

DECLARE @CheckTotals TABLE (ChainID INT, ChainIdentifier VARCHAR(50), CheckNumber VARCHAR(255), CheckDate DATE, RetailerInvoiceID INT, InvoiceTotal NUMERIC(18,9), Filename VARCHAR(255))

--INSERT INTO INBOUND820PAYMENTS FOR INVOICES THAT WERE ALREADY PAID BY SUPPLIER (RECORDSTATUS 821)
INSERT INTO DataTrue_EDI.dbo.Inbound820Payments
(
[ChainIdentifier]
,[InvType]
,[StoreIdentifier]
,[SaleDate]
,[UPC]
,[Cost]
,[Qty]
,[CheckNumber]
,[CheckDate]
,[Bipad]
,[StoreID]
,[WeekEndingDate]
,[iControlInvNumber]
,[InvAmt]
,[InvDate]
,[RecordStatus]
,[ChainInvNumber]
,[Inv(Val)]
,[Inv(Val)String]
,[DataTrueChainID]
,[DataTrueStoreID]
,[DataTrueProductID]
,[DataTrueBrandID]
,[DataTrueSupplierID]
,[DataTrueInvoiceDetailID]
,[iControlRetailerInvoiceID]
,[Timestamp]
,[Filename]
,[Retail]
,[RetailerAdjustmentAmount]
,[CustomerNumber]
,[VendorID]
,[CheckTotal]
,[CorpID]
)
OUTPUT
inserted.DataTrueChainID,
inserted.ChainIdentifier,
inserted.CheckNumber,
inserted.CheckDate,
inserted.iControlInvNumber,
inserted.InvAmt,
inserted.Filename
INTO @CheckTotals 
(
ChainID,
ChainIdentifier, 
CheckNumber, 
CheckDate,
RetailerInvoiceID, 
InvoiceTotal,
Filename
)
SELECT
(SELECT ChainIdentifier FROM DataTrue_Main.dbo.Chains AS c WHERE c.ChainID = d.ChainID)--[ChainIdentifier]
,NULL--,[InvType]
,(SELECT StoreIdentifier FROM DataTrue_Main.dbo.Stores AS s WHERE StoreID = d.StoreID) --,[StoreIdentifier]
,NULL--,[SaleDate]
,NULL--,[UPC]
,NULL--,[Cost]
,NULL--,[Qty]
,(SELECT ChainIdentifier FROM DataTrue_Main.dbo.Chains AS c WHERE c.ChainID = d.ChainID) + '_ManualRelease_' + REPLACE(REPLACE(CONVERT(VARCHAR(120), GETDATE(), 120), ' ', '_'), ':', '_')--,[CheckNumber]
,CONVERT(DATE, GETDATE())--,[CheckDate]
,NULL--,[Bipad]
,d.StoreID--,[StoreID]
,NULL--,[WeekEndingDate]
,d.RetailerInvoiceID--,[iControlInvNumber]
,SUM(d.TotalCost)--,[InvAmt]
,GETDATE()--,[InvDate]
,0--,[RecordStatus]
,NULL--,[ChainInvNumber]
,NULL--,[Inv(Val)]
,NULL--,[Inv(Val)String]
,d.ChainID--,[DataTrueChainID]
,d.StoreID--,[DataTrueStoreID]
,NULL--,[DataTrueProductID]
,NULL--,[DataTrueBrandID]
,d.SupplierID--,[DataTrueSupplierID]
,NULL--,[DataTrueInvoiceDetailID]
,d.RetailerInvoiceID--,[iControlRetailerInvoiceID]
,GETDATE()--,[Timestamp]
,(SELECT ChainIdentifier FROM DataTrue_Main.dbo.Chains AS c WHERE c.ChainID = d.ChainID) + '_ManualRelease_' + REPLACE(REPLACE(CONVERT(VARCHAR(120), GETDATE(), 120), ' ', '_'), ':', '_') + '_.Manual'--,[Filename]
,NULL--,[Retail]
,NULL--,[RetailerAdjustmentAmount]
,NULL--,[CustomerNumber]
,NULL--,[VendorID]
,NULL--,[CheckTotal]
,NULL--,[CorpID]
FROM [DataTrue_Main].[dbo].[InvoiceDetails] AS d
WHERE ProcessID = @ProcessID
AND InvoiceDetailTypeID IN (3, 9, 11)
AND RetailerInvoiceID is not null
AND RetailerInvoiceID not in  (-33, -1)
AND RecordStatus = 821
GROUP BY d.ChainID, d.SupplierID, d.StoreID, d.RetailerInvoiceID

INSERT INTO DataTrue_EDI.dbo.Checks_Released
(
ChainID,
ChainIdentifier,
CheckNumber,
checkDate,
checkAmt,
Released
)
SELECT
ChainID,
ChainIdentifier,
CheckNumber,
CheckDate,
SUM(InvoiceTotal),
0
FROM @CheckTotals AS t
GROUP BY ChainID, ChainIdentifier, CheckNumber, CheckDate

UPDATE i
SET i.CheckTotal = c.checkAmt
FROM DataTrue_EDI.dbo.Inbound820Payments AS i
INNER JOIN DataTrue_EDI.dbo.Checks_Released AS c
ON i.ChainIdentifier = c.ChainIdentifier
AND i.CheckNumber = c.CheckNumber
INNER JOIN @CheckTotals AS t
ON i.ChainIdentifier = t.ChainIdentifier
AND i.CheckNumber = t.CheckNumber

END TRY

BEGIN CATCH

--ROLLBACK TRANSACTION
		
		declare @errormessage varchar(max),
				@errorlocation varchar(500),
				@errorsenderstring varchar(500)

		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Newspapers_Shrink_NewInvoiceData Job Stopped'
			,'An exception occurred in [prBilling_EDIDatabase_Sync_DCR].  Manual review, resolution, and re-start will be required for the job to continue.'
			,'DataTrue System', 0, 'datatrueit@icucsolutions.com'--'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
		
		exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'Billing_Newspapers_Shrink_NewInvoiceData'
			
END CATCH
GO
