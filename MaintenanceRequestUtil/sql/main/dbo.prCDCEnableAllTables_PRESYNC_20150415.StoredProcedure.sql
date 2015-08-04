USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCEnableAllTables_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCEnableAllTables_PRESYNC_20150415]
as
/*
To enable CDC in the current database context

sys.sp_cdc_help_jobs

EXECUTE sys.sp_cdc_enable_db;

EXECUTE sys.sp_cdc_disable_db;


sys.sp_cdc_start_job

sys.sp_cdc_stop_job. 

EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  '' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
GO 
*/

/* 
EXEC Sp_cdc_disable_table 
 @source_schema =  'dbo', 
  @source_name =  'PO_PurchaseOrderHistoryData',  
  @capture_instance='all'
*/  


EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'addresses' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1

EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'AttributeDefinitions' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1

EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'AttributeValues' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
  
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'AutomatedReportsList' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1  
  
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'AutomatedReportsRequests' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1  
  
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'Brands' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1  
  
  
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'Batch' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
  
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'BillingControl' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1    
  
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'BillingRules' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
  
/* 
EXEC Sp_cdc_disable_table 
 @source_schema =  'dbo', 
  @source_name =  'BillingRules',  
  @capture_instance='all'
*/   
  
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'ChainProductFactors' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1  
 
 EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'Chains' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
  
  EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'Clusters' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
  
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'ContactInfo' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
  
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'CostZoneRelations' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
  
 EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'CostZones' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1  

EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'CreateStores' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
  
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'EntityTypes' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1 

EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'InventoryCost' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
  
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'InventoryPerpetual' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
  
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'InventorySettlementRequests' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
/*  
EXEC Sp_cdc_disable_table 
 @source_schema =  'dbo', 
  @source_name =  'InventoryPerpetual',  
  @capture_instance='all'
*/     
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'InvoiceDetails' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
/*  
EXEC Sp_cdc_disable_table 
 @source_schema =  'dbo', 
  @source_name =  'InvoiceDetails',  
  @capture_instance='all'
*/   
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'InvoiceDetailStatus' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
/*  
EXEC Sp_cdc_disable_table 
 @source_schema =  'dbo', 
  @source_name =  'InvoiceDetailStatus',  
  @capture_instance='all'
*/   
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'InvoiceDetailTypes' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
 
 EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'InvoicePaymentsFromRetailer' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1

EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'InvoicePaymentsToSupplier' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
     
 EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'InvoicesRetailer' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
/* 
EXEC Sp_cdc_disable_table 
 @source_schema =  'dbo', 
  @source_name =  'InvoicesSupplier',  
  @capture_instance='all'
*/ 

EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'InvoiceSeparationTypes' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1

EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'InvoicesSupplier' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
  

EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'InvoiceTypes' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
  
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'Logins' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1

EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'MaintananceRequestsTypes' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1

EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'MaintenanceRequests' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1

EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'MaintenanceRequestStores' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
    
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'Manufacturers' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
  
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'Memberships' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 0
/* 
EXEC Sp_cdc_disable_table 
 @source_schema =  'dbo', 
  @source_name =  'Memberships',  
  @capture_instance='all'
*/     
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'MembershipTypes' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
  
  EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'PaymentDisbursements' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
  
  EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'PaymentHistory' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
  
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'Payments' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1

EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'PaymentTypes' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1  
     
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'Persons' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
  
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'ProductBrandAssignments' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
    
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'ProductCategories' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1

EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'ProductCategoryAssignments' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
      
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'ProductIdentifiers' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
/* 
EXEC Sp_cdc_disable_table 
 @source_schema =  'dbo', 
  @source_name =  'ProductIdentifiers',  
  @capture_instance='all'
*/       
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'ProductIdentifierTypes' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
      
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'ProductPrices' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
 
 EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'ProductPriceTypes' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
  
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'Products' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
  
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'PO_PurchaseOrderData' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 0

EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'PO_PurchaseOrderHistoryData' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
  

EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'RelatedTransactions' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1

EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'RelatedTransactionTypes' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
 
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'Roles' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
     
 EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'ServiceFees' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
 
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'ServiceFeeTypes' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1


EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'SharedShrinkValues' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
    
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'Source' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
  
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'SourceTypes' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
  
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'Statuses' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
  
 EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'StatusTypes' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
  
/* 
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'StoreRules' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
*/
  
 EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'Stores' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
 
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'StoreSetup' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
/*  
EXEC Sp_cdc_disable_table 
 @source_schema =  'dbo', 
  @source_name =  'StoreSetup',  
  @capture_instance='all'
*/   
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'StoreTransactions',
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
  
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'StoreTransactions_Forward',
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
/*  
EXEC Sp_cdc_disable_table 
 @source_schema =  'dbo', 
  @source_name =  'StoreTransactions',  
  @capture_instance='all'
*/  

EXEC sys.sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'StoresUniqueValues' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
  
  --exec sys.sp_cdc_disable_table 
  --@source_schema = 'dbo', 
  --@source_name = 'StoresUniqueValues',
  --@capture_instance = 'dbo_StoresUniqueValues' -- or 'all'
  
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'Suppliers' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
  
 EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'SupplierBanners' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
  
 
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'SystemEntities' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
    
EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'TransactionTypes' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
GO
