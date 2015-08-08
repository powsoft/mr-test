USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_EDIDatabase_Sync_C2S]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prBilling_EDIDatabase_Sync_C2S]

as

DECLARE @rownumb INT
DECLARE @source VARCHAR(255)
SET @source = 'SP.[prBilling_EDIDatabase_Sync]'

declare @historic_limit datetime
set @historic_limit = getdate() - 101
select @historic_limit

declare @historic_limit_4_invoices datetime
set @historic_limit_4_invoices = getdate() - 3
select @historic_limit_4_invoices


declare @historic_limit_4_invoices_edi datetime
set @historic_limit_4_invoices_edi = getdate() - 3
select @historic_limit_4_invoices_edi

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

declare @lastInvoiceDetailsID bigint=0
select @lastInvoiceDetailsID = MAX([InvoiceDetailID]) from [DataTrue_EDI].[dbo].[InvoiceDetails]
--select @lastInvoiceDetailsID

INSERT INTO [DataTrue_EDI].[dbo].[InvoiceDetails]
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
           
           ,[DateTimeCreated]
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
)
SELECT 
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

			--change here wait
			,case when upper(banner) = 'SS' then 2 else 0 end

			,[DateTimeCreated]
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
			,[VIN]
			,[RawStoreIdentifier]
			,[Route]
--select *
  FROM [DataTrue_Main].[dbo].[InvoiceDetails]
	where 1 = 1
	and DateTimeLastUpdate >= @historic_limit_4_invoices
	--and InvoiceDetailID not in (select InvoiceDetailID from DataTrue_Main..EDI_InvoiceDetailIDs)
	and InvoiceDetailID not in (select InvoiceDetailID from DataTrue_EDI..InvoiceDetails where DateTimeLastUpdate >= @historic_limit_4_invoices_edi)
	and RetailerInvoiceID is not null
	and RetailerInvoiceID not in  (-33, -1)
	and InvoiceDetailID > @lastarchivemaxrowid
	and InvoiceDetailTypeID = 1
	and isnull(PDIParticipant, 0) <> 1

--- STEP 1
EXEC dbo.[Audit_Log_SP] 'STEP 001 => INSERT INTO [DataTrue_EDI].[dbo].[InvoiceDetails] FROM [DataTrue_Main].[dbo].[InvoiceDetails]', @source  

INSERT INTO [DataTrue_EDI].[dbo].[InvoiceDetails]
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
           ------------------------
           ,[RecordStatus]
           ,[RecordStatusSupplier]
           ------------------------
           ,[DateTimeCreated]
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
)
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
      -- change here wait
      ,0
      ,0
      ------------------------
      ,[DateTimeCreated]
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
		,[VIN]
		,[RawStoreIdentifier]
		,[Route]      
--select *
  FROM [DataTrue_Main].[dbo].[InvoiceDetails]
	where 1 = 1
	and DateTimeLastUpdate >= @historic_limit_4_invoices
	--and InvoiceDetailID not in (select InvoiceDetailID from DataTrue_Main..EDI_InvoiceDetailIDs)
	and InvoiceDetailID not in (select InvoiceDetailID from DataTrue_EDI..InvoiceDetails where DateTimeLastUpdate >= @historic_limit_4_invoices_edi)
	and RetailerInvoiceID is not null
	and RetailerInvoiceID not in  (-33, -1)
	and InvoiceDetailID > @lastarchivemaxrowid
	and InvoiceDetailTypeID = 2
	and isnull(PDIParticipant, 0) <> 1

--- STEP 2
EXEC dbo.[Audit_Log_SP] 'STEP 002 => INSERT INTO [DataTrue_EDI].[dbo].[InvoiceDetails] FROM [DataTrue_Main].[dbo].[InvoiceDetails]', @source  


INSERT INTO [DataTrue_EDI].[dbo].[InvoiceDetails]
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
           ,[RecordStatusSupplier]
           
           ,[DateTimeCreated]
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
)
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
      ,25
      ,25
      
      ,[DateTimeCreated]
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
		,[VIN]
		,[RawStoreIdentifier]
		,[Route]      
--select *
FROM [DataTrue_Main].[dbo].[InvoiceDetails]
	where 1 = 1
	and DateTimeLastUpdate >= @historic_limit_4_invoices
	--and InvoiceDetailID not in (select InvoiceDetailID from DataTrue_Main..EDI_InvoiceDetailIDs)
	and InvoiceDetailID not in (select InvoiceDetailID from DataTrue_EDI..InvoiceDetails where DateTimeLastUpdate >= @historic_limit_4_invoices_edi)
	and RetailerInvoiceID is not null
	and RetailerInvoiceID not in  (-33, -1)
	and InvoiceDetailID > @lastarchivemaxrowid
	and InvoiceDetailTypeID = 2
	and isnull(PDIParticipant, 0) = 1
	
--- STEP 3
EXEC dbo.[Audit_Log_SP] 'STEP 003 => INSERT INTO [DataTrue_EDI].[dbo].[InvoiceDetails] FROM [DataTrue_Main].[dbo].[InvoiceDetails]', @source

INSERT INTO [DataTrue_EDI].[dbo].[InvoiceDetails]
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

			,[DateTimeCreated]
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
)
SELECT 
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

			--change here wait
			,case when upper(banner) = 'SS' then 6 else 0 end

			,[DateTimeCreated]
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
			,[VIN]
			,[RawStoreIdentifier]
			,[Route]      
--select *
  FROM [DataTrue_Main].[dbo].[InvoiceDetails]
	where 1 = 1
	and DateTimeLastUpdate >= @historic_limit_4_invoices
	--and InvoiceDetailID not in (select InvoiceDetailID from DataTrue_Main..EDI_InvoiceDetailIDs)
	and InvoiceDetailID not in (select InvoiceDetailID from DataTrue_EDI..InvoiceDetails where DateTimeLastUpdate >= @historic_limit_4_invoices_edi)
	and RetailerInvoiceID is not null
	and RetailerInvoiceID not in  (-33, -1)
	and InvoiceDetailID > @lastarchivemaxrowid
	and InvoiceDetailTypeID = 7
	and isnull(PDIParticipant, 0) <> 1

--- STEP 4
EXEC dbo.[Audit_Log_SP] 'STEP 004 => INSERT INTO [DataTrue_EDI].[dbo].[InvoiceDetails] FROM [DataTrue_Main].[dbo].[InvoiceDetails]', @source
	
INSERT INTO [DataTrue_EDI].[dbo].[InvoiceDetails]
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
			,[RecordStatusSupplier]

			,[DateTimeCreated]
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
)
SELECT 
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
			--change here wait
			,25
			,25

			,[DateTimeCreated]
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
			,[VIN]
			,[RawStoreIdentifier]
			,[Route]      
--select *
  FROM [DataTrue_Main].[dbo].[InvoiceDetails]
	where 1 = 1
	and DateTimeLastUpdate >= @historic_limit_4_invoices
	--and InvoiceDetailID not in (select InvoiceDetailID from DataTrue_Main..EDI_InvoiceDetailIDs)
	and InvoiceDetailID not in (select InvoiceDetailID from DataTrue_EDI..InvoiceDetails where DateTimeLastUpdate >= @historic_limit_4_invoices_edi)
	and RetailerInvoiceID is not null
	and isnull(PDIParticipant, 0) = 1
	and InvoiceDetailID > @lastarchivemaxrowid		
	and RetailerInvoiceID not in  (-33, -1)
	and InvoiceDetailTypeID = 1

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

			,[DateTimeCreated]
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
)
      
SELECT 
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
			
			--change here wait
			,case when upper(banner) = 'SS' then 8 else 7 end
			
			,[DateTimeCreated]
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

			--select *
  FROM [DataTrue_Main].[dbo].[InvoiceDetails]
	where 1=1
	and DateTimeLastUpdate >= @historic_limit_4_invoices
	and InvoiceDetailID not in (select InvoiceDetailID from DataTrue_EDI..InvoiceDetails_Shrink)
	and RetailerInvoiceID is not null
	and RetailerInvoiceID not in  (-33, -1)
	and InvoiceDetailID > @lastarchivemaxrowid
	and InvoiceDetailTypeID = 11

--- STEP 6
EXEC dbo.[Audit_Log_SP] 'STEP 005.1 => INSERT INTO [DataTrue_EDI].[dbo].[InvoiceDetails_Shrink] FROM [DataTrue_Main].[dbo].[InvoiceDetails]', @source

----------------------------------------
DECLARE @current DATETIME = GETDATE()
DECLARE @updateUser INT = 333666
----------------------------------------

update 
	eid 
set 
	 eid.SupplierInvoiceID = mid.SupplierInvoiceID
	,LastUpdateUserID = @updateUser
	,DateTimeLastUpdate = @current
from 
	DataTrue_Main..InvoiceDetails mid with(nolock)
	-----------
	inner join 
	-----------
	DataTrue_EDI..InvoiceDetails eid
	on 
		mid.InvoiceDetailID = eid.InvoiceDetailID
	where 
		mid.DateTimeLastUpdate >= @historic_limit_4_invoices
	and	eid.SupplierInvoiceID is null
	and mid.SupplierInvoiceID is not null

--- STEP 6
EXEC dbo.[Audit_Log_SP] 'STEP 006 => UPDATE DataTrue_EDI..InvoiceDetails SET SupplierInvoiceID FROM DataTrue_Main..InvoiceDetails', @source


update 
	eid 
set 
	eid.RetailerInvoiceID = mid.RetailerInvoiceID
	,LastUpdateUserID = @updateUser
	,DateTimeLastUpdate = @current
from 
	DataTrue_Main..InvoiceDetails mid with(nolock)
	-------------
	inner join 
	-------------
	DataTrue_EDI..InvoiceDetails eid
	on 
		mid.InvoiceDetailID = eid.InvoiceDetailID
	where 
		mid.DateTimeLastUpdate >= @historic_limit_4_invoices
	and eid.RetailerInvoiceID is null
	and mid.RetailerInvoiceID is not null

--- STEP 7
EXEC dbo.[Audit_Log_SP] 'STEP 007 => UPDATE DataTrue_EDI..InvoiceDetails SET RetailerInvoiceID FROM DataTrue_Main..InvoiceDetails', @source


--*******************************************************************************************************
UPDATE h 
SET 
		h.OriginalAmount = d.IDSum
	,	h.OpenAmount = d.IDSum
	,	LastUpdateUserID = @updateUser
	,	DateTimeLastUpdate = @current
FROM 
	DataTrue_Main.dbo.InvoicesRetailer h 
	--------------
	INNER JOIN
	--------------
	(
		SELECT 
			 RetailerInvoiceID
			,ROUND(SUM(totalcost),2) as IDsum
		FROM 
			DataTrue_Main.dbo.InvoiceDetails with (nolock)
		WHERE
			(DateTimeLastUpdate >= @historic_limit_4_invoices)
		AND	(RetailerInvoiceID	IS NOT NULL)
		GROUP BY 
			RetailerInvoiceID
	) d
	ON 
		(h.RetailerInvoiceID IS NOT NULL)
	AND	(h.RetailerInvoiceID = d.RetailerInvoiceID)
	AND (d.IDSum <> h.OriginalAmount)

--- STEP 8
EXEC dbo.[Audit_Log_SP] 'STEP 008 => UPDATE datatrue_main.InvoicesRetailer SET OriginalAmount, OpenAmount FROM DataTrue_Main..InvoiceDetails', @source



UPDATE h 
SET 
		h.OriginalAmount = d.IDSum
	,	h.OpenAmount = d.IDSum
	,	LastUpdateUserID = @updateUser
	,	DateTimeLastUpdate = @current
FROM 
	DataTrue_Main.dbo.InvoicesSupplier h
	------------------
	INNER JOIN
	------------------
	(
		SELECT 
				SupplierInvoiceID
			,	ROUND(SUM(totalcost),2) as IDsum
		FROM 
			DataTrue_Main.dbo.InvoiceDetails WITH(NOLOCK)
		WHERE
			DateTimeLastUpdate >= @historic_limit_4_invoices
		AND SupplierInvoiceID IS NOT NULL		
		GROUP BY 
			SupplierInvoiceID
	) d
	on 
		(h.SupplierInvoiceID IS NOT NULL)
	AND	(h.SupplierInvoiceID = d.SupplierInvoiceID)
	AND (d.IDSum <> h.OriginalAmount)

--- STEP 9
EXEC dbo.[Audit_Log_SP] 'STEP 009 => UPDATE datatrue_main.InvoicesSupplier SET OriginalAmount, OpenAmount FROM DataTrue_Main..InvoiceDetails', @source



--drop table DataTrue_EDI..InvoicesRetailer
INSERT INTO 
	DataTrue_EDI..InvoicesRetailer 
SELECT * FROM 
	DataTrue_Main..InvoicesRetailer WITH(NOLOCK)
WHERE 
	RetailerInvoiceID NOT IN 
	(
		SELECT 
			RetailerInvoiceID 
		FROM 
			DataTrue_EDI..InvoicesRetailer WITH(NOLOCK)
	)
--drop table DataTrue_EDI..InvoicesSupplier
--select * into DataTrue_EDI..InvoicesSupplier from InvoicesSupplier

--- STEP 10
EXEC dbo.[Audit_Log_SP] 'STEP 010 => INSERT DataTrue_EDI..InvoicesRetailer FROM DataTrue_Main..InvoicesRetailer', @source


INSERT INTO DataTrue_EDI..InvoicesSupplier 
SELECT * FROM 
	DataTrue_Main..InvoicesSupplier WITH(NOLOCK)
WHERE 
	Supplierinvoiceid NOT IN 
	(
		SELECT 
			Supplierinvoiceid 
		FROM 
			DataTrue_EDI..InvoicesSupplier WITH(NOLOCK)
	)

--- STEP 11
EXEC dbo.[Audit_Log_SP] 'STEP 011 => INSERT DataTrue_EDI..InvoicesSupplier FROM DataTrue_Main..InvoicesSupplier', @source


UPDATE h 
SET 
		h.OriginalAmount = d.IDSum
	,	h.OpenAmount = d.IDSum
	,	LastUpdateUserID = @updateUser
	,	DateTimeLastUpdate = @current
FROM 
	DataTrue_EDI.dbo.InvoicesSupplier h
	----------------	
	INNER JOIN
	----------------
	 (
			SELECT 
				 SupplierInvoiceID
				,ROUND(SUM(totalcost),2) as IDsum
			FROM 
				DataTrue_Main.dbo.InvoiceDetails WITH(NOLOCK)
			WHERE 
				(DateTimeLastUpdate >= @historic_limit_4_invoices)
			AND (SupplierInvoiceID IS NOT NULL		)
			GROUP BY 
				SupplierInvoiceID
	 ) d
 on 
	(h.SupplierInvoiceID IS NOT NULL		)
AND (h.SupplierInvoiceID = d.SupplierInvoiceID)
AND (d.IDSum <> h.OriginalAmount)

--- STEP 12
EXEC dbo.[Audit_Log_SP] 'STEP 012 => UPDATE Ddatatrue_edi.dbo.InvoicesSupplier SET OriginalAmount, OpenAmount FROM datatrue_edi.dbo.InvoicesSupplier', @source


UPDATE h 
SET 
		h.OriginalAmount = d.IDSum
	,	h.OpenAmount = d.IDSum
	,	LastUpdateUserID = @updateUser
	,	DateTimeLastUpdate = @current
FROM 
DataTrue_EDI.dbo.InvoicesRetailer h
----------------
INNER JOIN
----------------
(
	SELECT 
			RetailerInvoiceID
		,	ROUND(SUM(totalcost),2) as IDsum
	FROM 
		DataTrue_Main.dbo.InvoiceDetails WITH (NOLOCK)
	WHERE 
		(DateTimeLastUpdate >= @historic_limit_4_invoices)
	AND (RetailerInvoiceID IS NOT NULL		)	
	GROUP BY
		RetailerInvoiceID
) d
on 
	(h.RetailerInvoiceID IS NOT NULL		)	
AND	(h.RetailerInvoiceID = d.RetailerInvoiceID)
AND (d.IDSum <> h.OriginalAmount)
 
 --- STEP 13
EXEC dbo.[Audit_Log_SP] 'STEP 013 => UPDATE datatrue_edi.dbo.InvoicesRetailer SET OriginalAmount, OpenAmount FROM datatrue_main.dbo.Invoicedetails', @source


UPDATE d 
SET 
	  d.ReferenceIdentification = w.ReferenceIdentification
	, d.GLN = w.GLN
	, d.GTIN = w.GTIN
	, d.RetailerItemNo = w.RetailerItemNo
	, d.SupplierItemNo = w.SupplierItemNo
	, d.PackSize = w.PackSize
--select *
FROM 
	DataTrue_EDI.dbo.InvoiceDetails d 
	----------------
	INNER JOIN 
	----------------
	DataTrue_Main.dbo.StoreTransactions_Working w  WITH (NOLOCK)
on 
	d.DateTimeLastUpdate >= @historic_limit_4_invoices 
and	d.chainid = 62348
and d.storeid = w.storeid
and d.productid = w.productid
and d.supplierid = w.supplierid
and cast(d.SaleDate as date) = cast(w.saledatetime as date)
and cast(d.DateTimeCreated as date) = cast(getdate() as date)

--- STEP 14
EXEC dbo.[Audit_Log_SP] 'STEP 014 => UPDATE datatrue_edi.dbo.invoicedetails SET ReferenceIdentification, GLN... FROM datatrue_main.dbo.storetransactions_working', @source

--- STEP 15
EXEC dbo.[Audit_Log_SP] 'STEP 015 => FINISH !!!', @source
GO
