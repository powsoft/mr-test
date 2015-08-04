USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_EDIDatabase_Sync]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prBilling_EDIDatabase_Sync]

as

DECLARE @rownumb INT
DECLARE @source VARCHAR(255)
SET @source = 'SP.[prBilling_EDIDatabase_Sync]'
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


--CHECK WITH NIK B BEFORE MAKING CHANGES TO BELOW STATEMENT
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
      ,[RetailerItemNo] 
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
      ,case when upper(banner) = 'SS' then 2 else 0 end
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
      ,[RecordType]
      ,[ProcessID] 
      ,[RetailerItemNo] 
--select *
  FROM [DataTrue_Main].[dbo].[InvoiceDetails] with (index(1))
	where 1 = 1
	--and InvoiceDetailID not in (select InvoiceDetailID from DataTrue_Main..EDI_InvoiceDetailIDs)
	and InvoiceDetailID not in (select InvoiceDetailID from DataTrue_EDI..InvoiceDetails with (index(59)))
	and RetailerInvoiceID is not null
	and RetailerInvoiceID not in  (-33, -1)
	and InvoiceDetailID > @lastarchivemaxrowid
	and InvoiceDetailTypeID in (1, 16)
	--and isnull(PDIParticipant, 0) <> 1
	and ChainID <> @cvsChainID
	--and convert(date, DateTimeCreated) = CONVERT(date, getdate())
	option (querytraceon 8795,merge join,maxdop 2)
	

--- STEP 1
EXEC dbo.[Audit_Log_SP] 'STEP 001 => INSERT INTO [DataTrue_EDI].[dbo].[InvoiceDetails] FROM [DataTrue_Main].[dbo].[InvoiceDetails]', @source  

--CHECK WITH NIK B BEFORE MAKING CHANGES TO BELOW STATEMENT
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
      ,RetailerItemNo  
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
      ,case when upper(banner) = 'SS' then 2 else 0 end
      ,0
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
      ,[RecordType] 
      ,[ProcessID]
      ,RetailerItemNo     
--select *
  FROM [DataTrue_Main].[dbo].[InvoiceDetails] with (index(76))
	where 1 = 1
	--and InvoiceDetailID not in (select InvoiceDetailID from DataTrue_Main..EDI_InvoiceDetailIDs)
	and InvoiceDetailID not in (select InvoiceDetailID from DataTrue_EDI..InvoiceDetails with (index(59)))
	and RetailerInvoiceID is null
    and SupplierInvoiceID is not Null
	--and RetailerInvoiceID not in  (-33, -1)
	and InvoiceDetailID > @lastarchivemaxrowid
	and InvoiceDetailTypeID in (1,16)
	--and isnull(PDIParticipant, 0) <> 1
	and convert(date, DateTimeCreated) = CONVERT(date, getdate())
	and ChainID <> @cvsChainID
	option (merge join,maxdop 2)
	
	
--- STEP 2
EXEC dbo.[Audit_Log_SP] 'STEP 002 => INSERT INTO [DataTrue_EDI].[dbo].[InvoiceDetails] FROM [DataTrue_Main].[dbo].[InvoiceDetails]', @source  


--INSERT INTO [DataTrue_EDI].[dbo].[InvoiceDetails]
--           ([InvoiceDetailID]
--           ,[RetailerInvoiceID]
--           ,[SupplierInvoiceID]
--           ,[ChainID]
--           ,[StoreID]
--           ,[ProductID]
--           ,[BrandID]
--           ,[SupplierID]
--           ,[InvoiceDetailTypeID]
--           ,[TotalQty]
--           ,[UnitCost]
--           ,[UnitRetail]
--           ,[TotalCost]
--           ,[TotalRetail]
--           ,[SaleDate]
--           ,[RecordStatus]
--           ,[RecordStatusSupplier]
--           --,[DateTimeCreated]
--           ,[LastUpdateUserID]
--           ,[DateTimeLastUpdate]
--           ,[BatchID]
--           ,[ChainIdentifier]
--           ,[StoreIdentifier]
--           ,[StoreName]
--           ,[ProductIdentifier]
--           ,[ProductQualifier]
--           ,[RawProductIdentifier]
--           ,[SupplierName]
--           ,[SupplierIdentifier]
--           ,[BrandIdentifier]
--           ,[DivisionIdentifier]
--           ,[UOM]
--           ,[SalePrice]
--           ,[Allowance]
--           ,[InvoiceNo]
--           ,[PONo]
--           ,[CorporateName]
--           ,[CorporateIdentifier]
--           ,[Banner]
--           ,PromoTypeID
--			,PromoAllowance
--			,SBTNumber
--      ,[FinalInvoiceTotalCost]
--      ,[OriginalShrinkTotalQty]
--      ,[PaymentDueDate]
--      ,[PaymentID]
--      ,[Adjustment1]
--      ,[Adjustment2]
--      ,[Adjustment3]
--      ,[Adjustment4]
--      ,[Adjustment5]
--      ,[Adjustment6]
--      ,[Adjustment7]
--      ,[Adjustment8]
--      ,[PDIParticipant]
--      ,[RetailUOM]
--      ,[RetailTotalQty]
--      ,[VIN]
--      ,[RawStoreIdentifier]
--      ,[Route]
--      ,[RecordType]
--)
--SELECT [InvoiceDetailID]
--      ,[RetailerInvoiceID]
--      ,[SupplierInvoiceID]
--      ,[ChainID]
--      ,[StoreID]
--      ,[ProductID]
--      ,[BrandID]
--      ,[SupplierID]
--      ,[InvoiceDetailTypeID]
--      ,[TotalQty]
--      ,[UnitCost]
--      ,[UnitRetail]
--      ,[TotalCost]
--      ,[TotalRetail]
--      ,[SaleDate]
--      --change here wait
--      ,25
--      ,25
--      --,[DateTimeCreated]
--      ,[LastUpdateUserID]
--      ,[DateTimeLastUpdate]
--      ,[BatchID]
--                 ,[ChainIdentifier]
--           ,[StoreIdentifier]
--           ,[StoreName]
--           ,[ProductIdentifier]
--           ,[ProductQualifier]
--           ,[RawProductIdentifier]
--           ,[SupplierName]
--           ,[SupplierIdentifier]
--           ,[BrandIdentifier]
--           ,[DivisionIdentifier]
--           ,[UOM]
--           ,[SalePrice]
--           ,[Allowance]
--           ,[InvoiceNo]
--           ,[PONo]
--           ,[CorporateName]
--           ,[CorporateIdentifier]
--           ,[Banner]
--           ,PromoTypeID
--			,isnull(PromoAllowance, 0)
--			,SBTNumber
--      ,[FinalInvoiceTotalCost]
--      ,[OriginalShrinkTotalQty]
--      ,[PaymentDueDate]
--      ,[PaymentID]
--      ,[Adjustment1]
--      ,[Adjustment2]
--      ,[Adjustment3]
--      ,[Adjustment4]
--      ,[Adjustment5]
--      ,[Adjustment6]
--      ,[Adjustment7]
--      ,[Adjustment8]
--      ,[PDIParticipant]
--      ,[RetailUOM]
--      ,[RetailTotalQty]
--      ,[VIN]
--      ,[RawStoreIdentifier]
--      ,[Route]   
--      ,[RecordType]   
----select *
--  FROM [DataTrue_Main].[dbo].[InvoiceDetails]
--	where 1 = 1
--	--and InvoiceDetailID not in (select InvoiceDetailID from DataTrue_Main..EDI_InvoiceDetailIDs)
--	and InvoiceDetailID not in (select InvoiceDetailID from DataTrue_EDI..InvoiceDetails)
--	and RetailerInvoiceID is not null
--	and RetailerInvoiceID not in  (-33, -1)
--	and InvoiceDetailID > @lastarchivemaxrowid
--	and InvoiceDetailTypeID = 2
--	and isnull(PDIParticipant, 0) = 1
--	and ChainID <> @cvsChainID
	
--- STEP 3
EXEC dbo.[Audit_Log_SP] 'STEP 003 => INSERT INTO [DataTrue_EDI].[dbo].[InvoiceDetails] FROM [DataTrue_Main].[dbo].[InvoiceDetails]', @source

--CHECK WITH NIK B BEFORE MAKING CHANGES TO BELOW STATEMENT
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
      ,[SourceID]
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
      ,case when upper(banner) = 'SS' then 6 else 0 end
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
      ,[RecordType] 
      ,[ProcessID] 
      ,[SourceID]    
--select *
  FROM [DataTrue_Main].[dbo].[InvoiceDetails] with (index(1))
	where 1 = 1
	--and InvoiceDetailID not in (select InvoiceDetailID from DataTrue_Main..EDI_InvoiceDetailIDs)
	and InvoiceDetailID not in (select InvoiceDetailID from DataTrue_EDI..InvoiceDetails with (index(59)))
	and RetailerInvoiceID is not null
	and RetailerInvoiceID not in  (-33, -1)
	and InvoiceDetailID > @lastarchivemaxrowid
	and InvoiceDetailTypeID = 7
	--and convert(date, DateTimeCreated) = CONVERT(date, getdate())
	--and isnull(PDIParticipant, 0) <> 1
	and ChainID <> @cvsChainID
	option (merge join,maxdop 2)
	

--- STEP 4
EXEC dbo.[Audit_Log_SP] 'STEP 004 => INSERT INTO [DataTrue_EDI].[dbo].[InvoiceDetails] FROM [DataTrue_Main].[dbo].[InvoiceDetails]', @source
	
--INSERT INTO [DataTrue_EDI].[dbo].[InvoiceDetails]
--           ([InvoiceDetailID]
--           ,[RetailerInvoiceID]
--           ,[SupplierInvoiceID]
--           ,[ChainID]
--           ,[StoreID]
--           ,[ProductID]
--           ,[BrandID]
--           ,[SupplierID]
--           ,[InvoiceDetailTypeID]
--           ,[TotalQty]
--           ,[UnitCost]
--           ,[UnitRetail]
--           ,[TotalCost]
--           ,[TotalRetail]
--           ,[SaleDate]
--           ,[RecordStatus]
--           ,[RecordStatusSupplier]
--          -- ,[DateTimeCreated]
--           ,[LastUpdateUserID]
--           ,[DateTimeLastUpdate]
--           ,[BatchID]
--           ,[ChainIdentifier]
--           ,[StoreIdentifier]
--           ,[StoreName]
--           ,[ProductIdentifier]
--           ,[ProductQualifier]
--           ,[RawProductIdentifier]
--           ,[SupplierName]
--           ,[SupplierIdentifier]
--           ,[BrandIdentifier]
--           ,[DivisionIdentifier]
--           ,[UOM]
--           ,[SalePrice]
--           ,[Allowance]
--           ,[InvoiceNo]
--           ,[PONo]
--           ,[CorporateName]
--           ,[CorporateIdentifier]
--           ,[Banner]
--           ,PromoTypeID
--			,PromoAllowance
--			,SBTNumber
--      ,[FinalInvoiceTotalCost]
--      ,[OriginalShrinkTotalQty]
--      ,[PaymentDueDate]
--      ,[PaymentID]
--      ,[Adjustment1]
--      ,[Adjustment2]
--      ,[Adjustment3]
--      ,[Adjustment4]
--      ,[Adjustment5]
--      ,[Adjustment6]
--      ,[Adjustment7]
--      ,[Adjustment8]
--      ,[PDIParticipant]
--      ,[RetailUOM]
--      ,[RetailTotalQty]
--      ,[VIN]
--      ,[RawStoreIdentifier]
--      ,[Route]      
--      ,[RecordType]
--      ,[ProcessID] 
--)
--SELECT [InvoiceDetailID]
--      ,[RetailerInvoiceID]
--      ,[SupplierInvoiceID]
--      ,[ChainID]
--      ,[StoreID]
--      ,[ProductID]
--      ,[BrandID]
--      ,[SupplierID]
--      ,[InvoiceDetailTypeID]
--      ,[TotalQty]
--      ,[UnitCost]
--      ,[UnitRetail]
--      ,[TotalCost]
--      ,[TotalRetail]
--      ,[SaleDate]
--      --change here wait
--      ,25 
--      ,25 
--      --,[DateTimeCreated]
--      ,[LastUpdateUserID]
--      ,[DateTimeLastUpdate]
--      ,[BatchID]
--                 ,[ChainIdentifier]
--           ,[StoreIdentifier]
--           ,[StoreName]
--           ,[ProductIdentifier]
--           ,[ProductQualifier]
--           ,[RawProductIdentifier]
--           ,[SupplierName]
--           ,[SupplierIdentifier]
--           ,[BrandIdentifier]
--           ,[DivisionIdentifier]
--           ,[UOM]
--           ,[SalePrice]
--           ,[Allowance]
--           ,[InvoiceNo]
--           ,[PONo]
--           ,[CorporateName]
--           ,[CorporateIdentifier]
--       ,[Banner]
--           ,PromoTypeID
--			,isnull(PromoAllowance, 0)
--			,SBTNumber
--      ,[FinalInvoiceTotalCost]
--      ,[OriginalShrinkTotalQty]
--      ,[PaymentDueDate]
--      ,[PaymentID]
--      ,[Adjustment1]
--      ,[Adjustment2]
--      ,[Adjustment3]
--      ,[Adjustment4]
--      ,[Adjustment5]
--      ,[Adjustment6]
--      ,[Adjustment7]
--      ,[Adjustment8]
--      ,[PDIParticipant]
--      ,[RetailUOM]
--      ,[RetailTotalQty]
--      ,[VIN]
--      ,[RawStoreIdentifier]
--      ,[Route]    
--      ,[RecordType]  
--      ,[ProcessID] 
----select *
--  FROM [DataTrue_Main].[dbo].[InvoiceDetails] with (index(1))
--	where 1 = 1
--	--and InvoiceDetailID not in (select InvoiceDetailID from DataTrue_Main..EDI_InvoiceDetailIDs)
--	and InvoiceDetailID not in (select InvoiceDetailID from DataTrue_EDI..InvoiceDetails with (index(59)))
--	and RetailerInvoiceID is not null
--	and isnull(PDIParticipant, 0) = 1
--	and InvoiceDetailID > @lastarchivemaxrowid		
--	and RetailerInvoiceID not in  (-33, -1)
--	and InvoiceDetailTypeID in (1,16)
--	and ChainID <> @cvsChainID
--	option (merge join,maxdop 1)
	

--- STEP 5
--EXEC dbo.[Audit_Log_SP] 'STEP 005 => INSERT INTO [DataTrue_EDI].[dbo].[InvoiceDetails] FROM [DataTrue_Main].[dbo].[InvoiceDetails]', @source

--CHECK WITH NIK B BEFORE MAKING CHANGES TO BELOW STATEMENT
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
      ,[ProcessId])
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
      ,CASE WHEN RecordStatus = 820 THEN 1 ELSE case when upper(banner) = 'SS' then 8 else 7 end END
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
	  ,CASE WHEN RecordStatus = 820 THEN GETDATE() ELSE NULL END
	  ,CASE WHEN RecordStatus = 820 THEN 1 ELSE 0 END
	  ,CASE WHEN RecordStatus = 820 THEN GETDATE() ELSE NULL END
	  ,[ProcessID] 
			--select *
  FROM [DataTrue_Main].[dbo].[InvoiceDetails] with (index(1))
	where InvoiceDetailID not in (select InvoiceDetailID from DataTrue_EDI..InvoiceDetails_Shrink with (index(20)))
	and RetailerInvoiceID is not null
	and RetailerInvoiceID not in  (-33, -1)
	and InvoiceDetailID > @lastarchivemaxrowid
	and InvoiceDetailTypeID in (3, 9, 11)
	and ChainID <> @cvsChainID
	AND ISNULL(ProcessID, 0) NOT IN (SELECT ProcessID FROM DataTrue_Main.dbo.JobProcesses WHERE JobRunningID = 11)
	--option (merge join, maxdop 1)

--STEP 6
EXEC dbo.[Audit_Log_SP] 'STEP 005.1 => INSERT INTO [DataTrue_EDI].[dbo].[InvoiceDetails_Shrink] FROM [DataTrue_Main].[dbo].[InvoiceDetails]', @source


update eid set eid.SupplierInvoiceID = did.SupplierInvoiceID
from DataTrue_Main..InvoiceDetails did
inner join DataTrue_EDI..InvoiceDetails eid
on did.InvoiceDetailID = eid.InvoiceDetailID
where eid.SupplierInvoiceID is null
and did.SupplierInvoiceID is not null

--- STEP 6
EXEC dbo.[Audit_Log_SP] 'STEP 006 => UPDATE DataTrue_EDI..InvoiceDetails SET SupplierInvoiceID FROM DataTrue_Main..InvoiceDetails', @source


update eid set eid.RetailerInvoiceID = did.RetailerInvoiceID
from DataTrue_Main..InvoiceDetails did
inner join DataTrue_EDI..InvoiceDetails eid
on did.InvoiceDetailID = eid.InvoiceDetailID
where eid.RetailerInvoiceID is null

--- STEP 7
EXEC dbo.[Audit_Log_SP] 'STEP 007 => UPDATE DataTrue_EDI..InvoiceDetails SET RetailerInvoiceID FROM DataTrue_Main..InvoiceDetails', @source

--*******************************************************************************************************

--CHECK WITH NIK B BEFORE MAKING CHANGED TO BELOW STATEMENT
update h set h.OriginalAmount = d.IDSum, h.OpenAmount = d.IDSum
from InvoicesRetailer h
 inner join
 (
 select retailerinvoiceid, SUM(isnull(totalcost,0)) as IDsum
 from datatrue_main.dbo.Invoicedetails
 where 1 = 1
 group by RetailerInvoiceID
 ) d
 on h.RetailerInvoiceID = d.RetailerInvoiceID
 and d.IDSum <> h.OriginalAmount


--- STEP 8
EXEC dbo.[Audit_Log_SP] 'STEP 008 => UPDATE datatrue_main.InvoicesRetailer SET OriginalAmount, OpenAmount FROM DataTrue_Main..InvoiceDetails', @source


--CHECK WITH NIK B BEFORE MAKING CHANGES TO BELOW STATEMENT
update h set h.OriginalAmount = d.IDSum, h.OpenAmount = d.IDSum
from InvoicesSupplier h
 inner join
 (
 select supplierinvoiceid, SUM(isnull(totalcost,0)) as IDsum
 from datatrue_main.dbo.Invoicedetails
 where 1 = 1
 --and InvoiceDetailTypeID = 11
 --and saledate > '11/30/2011'
 group by supplierinvoiceid
 ) d
 on h.supplierinvoiceid = d.supplierinvoiceid
 and d.IDSum <> h.OriginalAmount
  


--- STEP 9
EXEC dbo.[Audit_Log_SP] 'STEP 009 => UPDATE datatrue_main.InvoicesSupplier SET OriginalAmount, OpenAmount FROM DataTrue_Main..InvoiceDetails', @source



--drop table DataTrue_EDI..InvoicesRetailer
insert into DataTrue_EDI..InvoicesRetailer 
select * from DataTrue_Main..InvoicesRetailer
where retailerinvoiceid not in (select retailerinvoiceid from DataTrue_EDI..InvoicesRetailer)
and ChainID <> @cvsChainID
--drop table DataTrue_EDI..InvoicesSupplier
--select * into DataTrue_EDI..InvoicesSupplier from InvoicesSupplier

--- STEP 10
EXEC dbo.[Audit_Log_SP] 'STEP 010 => INSERT DataTrue_EDI..InvoicesRetailer FROM DataTrue_Main..InvoicesRetailer', @source


insert into DataTrue_EDI..InvoicesSupplier 
select * from DataTrue_Main..InvoicesSupplier
where Supplierinvoiceid not in (select Supplierinvoiceid from DataTrue_EDI..InvoicesSupplier)


--- STEP 11
EXEC dbo.[Audit_Log_SP] 'STEP 011 => INSERT DataTrue_EDI..InvoicesSupplier FROM DataTrue_Main..InvoicesSupplier', @source

--CHECK WITH NIK B BEFORE MAKING CHANGES TO BELOW STATEMENT
update h set h.OriginalAmount = d.IDSum, h.OpenAmount = d.IDSum
from datatrue_edi.dbo.InvoicesSupplier h
 inner join
 (
 select supplierinvoiceid, SUM(isnull(totalcost,0)) as IDsum
 from datatrue_main.dbo.Invoicedetails
 where 1 = 1
 --and InvoiceDetailTypeID = 11
 --and saledate > '11/30/2011'
 group by supplierinvoiceid
 ) d
 on h.supplierinvoiceid = d.supplierinvoiceid
 and d.IDSum <> h.OriginalAmount
 

--- STEP 12
EXEC dbo.[Audit_Log_SP] 'STEP 012 => UPDATE Ddatatrue_edi.dbo.InvoicesSupplier SET OriginalAmount, OpenAmount FROM datatrue_edi.dbo.InvoicesSupplier', @source

--CHECK WITH NIK B BEFORE MAKING CHANGES TO BELOW STATEMENT
update h set h.OriginalAmount = d.IDSum, h.OpenAmount = d.IDSum
 from datatrue_edi.dbo.InvoicesRetailer h
 inner join
 (
 select retailerinvoiceid, SUM(isnull(totalcost,0)) as IDsum
 from datatrue_main.dbo.Invoicedetails
 where 1 = 1
 --and InvoiceDetailTypeID = 11
 --and saledate > '11/30/2011'
 group by RetailerInvoiceID
 ) d
 on h.RetailerInvoiceID = d.RetailerInvoiceID
 and d.IDSum <> h.OriginalAmount
  
 
 
 --- STEP 13
EXEC dbo.[Audit_Log_SP] 'STEP 013 => UPDATE datatrue_edi.dbo.InvoicesRetailer SET OriginalAmount, OpenAmount FROM datatrue_main.dbo.Invoicedetails', @source


 update d set d.ReferenceIdentification = w.ReferenceIdentification, d.GLN = w.GLN, 
d.GTIN = w.GTIN, d.RetailerItemNo = w.RetailerItemNo, d.SupplierItemNo = w.SupplierItemNo, 
d.PackSize = w.PackSize
--select *
from datatrue_edi.dbo.invoicedetails d
inner join datatrue_main.dbo.storetransactions_working w
on d.chainid = 62348
and d.storeid = w.storeid
and d.productid = w.productid
and d.supplierid = w.supplierid
and cast(d.SaleDate as date) = cast(w.saledatetime as date)
and cast(d.DateTimeCreated as date) = cast(getdate() as date)

--- STEP 14
EXEC dbo.[Audit_Log_SP] 'STEP 014 => UPDATE datatrue_edi.dbo.invoicedetails SET ReferenceIdentification, GLN... FROM datatrue_main.dbo.storetransactions_working', @source

update r set r.aggregationid = m.aggregationid
from datatrue_edi.dbo.InvoicesRetailer r --with (nolock)
inner join datatrue_main.dbo.InvoicesRetailer m
on r.RetailerInvoiceid = m.RetailerInvoiceID
and r.aggregationid is null
and M.aggregationid is not null

--- STEP 15
EXEC dbo.[Audit_Log_SP] 'update r set r.aggregationid = m.aggregationid
from datatrue_edi.dbo.InvoicesRetailer r --with (nolock)
inner join datatrue_main.dbo.InvoicesRetailer m
on r.RetailerInvoiceid = m.RetailerInvoiceID
and r.aggregationid is null
and M.aggregationid is not null', @source


Update D Set D.PaymentID = I.Paymentid 
from InvoiceDetails I
inner join DataTrue_EDI..InvoiceDetails D
on D.InvoiceDetailID = I.InvoiceDetailID
where I.PaymentID is not null
and D.PaymentID is null

--- STEP 16
EXEC dbo.[Audit_Log_SP] 'Update D Set D.PaymentID = I.Paymentid 
from InvoiceDetails I
inner join DataTrue_EDI..InvoiceDetails D
on D.InvoiceDetailID = I.InvoiceDetailID
where I.PaymentID is not null
and D.PaymentID is null', @source

--CHECK WITH NIK B BEFORE MAKING CHANGES TO BELOW STATEMENT
INSERT INTO [DataTrue_EDI].[dbo].[ProductPrices]
           ([ProductPriceID]
           ,[ProductPriceTypeID]
           ,[ProductID]
           ,[ChainID]
           ,[StoreID]
           ,[BrandID]
           ,[SupplierID]
           ,[UnitPrice]
           ,[UnitRetail]
           ,[PricePriority]
           ,[ActiveStartDate]
           ,[ActiveLastDate]
         ,[PriceReportedToRetailerDate]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[BaseCost]
           ,[Allowance]
           ,[NewActiveStartDateNeeded]
           ,[NewActiveLastDateNeeded]
           ,[OldStartDate]
           ,[OldEndDate]
           ,[TradingPartnerPromotionIdentifier]
           ,[SupplierPackageID]
           ,[IncludeInAdjustments]
           ,[CostPlusPercentOfRetail])
		select [ProductPriceID]
           ,[ProductPriceTypeID]
           ,[ProductID]
           ,[ChainID]
           ,[StoreID]
           ,[BrandID]
           ,[SupplierID]
           ,[UnitPrice]
           ,[UnitRetail]
           ,[PricePriority]
           ,[ActiveStartDate]
           ,[ActiveLastDate]
           ,[PriceReportedToRetailerDate]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[BaseCost]
           ,[Allowance]
           ,[NewActiveStartDateNeeded]
           ,[NewActiveLastDateNeeded]
           ,[OldStartDate]
           ,[OldEndDate]
           ,[TradingPartnerPromotionIdentifier]
           ,[SupplierPackageID]
           ,[IncludeInAdjustments]
           ,[CostPlusPercentOfRetail]
from datatrue_main.dbo.productprices with (nolock)
where productpriceid not in
(select productpriceid from datatrue_edi.dbo.productprices  with (nolock))
option (merge join, maxdop 1)

update pe set pe.UnitPrice = pm.UnitPrice, pe.UnitRetail = pm.UnitRetail, 
pe.CostPlusPercentOfRetail = pm.CostPlusPercentOfRetail, 
pe.ActiveStartDate = pm.ActiveStartDate, pe.ActiveLastDate = pm.ActiveLastDate
from datatrue_main.dbo.productprices pm with (nolock)
inner join datatrue_edi.dbo.productprices pe --with (nolock)
on pm.productpriceid = pe.productpriceid
where 1 = 1
and pm.chainid = 60634
and (
pm.UnitPrice <> pe.UnitPrice
or pm.UnitRetail <> pe.UnitRetail
or isnull(pm.CostPlusPercentOfRetail, 0) <> isnull(pe.CostPlusPercentOfRetail, 0)
or pm.ActiveStartDate <> pe.ActiveStartDate
or pm.ActiveLastDate <> pe.ActiveLastDate
)

--exec [dbo].[prCDCGetSuppliersLSN]

--exec dbo.prCDCGetStoresLSN

--exec dbo.prCDCGetProductsLSN

--exec dbo.prCDCGetPaymentsLSN

--exec dbo.prCDCGetPaymentHistoryLSN

--exec dbo.prCDCGetStatusesLSN

--exec dbo.prCDCGetInvoicesRetailerLSN

--exec dbo.prCDCGetInvoiceDetailsLSN

--exec dbo.prCDCGetStoreTransactionsLSN

--- STEP 16
EXEC dbo.[Audit_Log_SP] 'STEP 015 => FINISH !!!', @source
GO
