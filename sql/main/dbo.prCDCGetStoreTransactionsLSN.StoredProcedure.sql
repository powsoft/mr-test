USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetStoreTransactionsLSN]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetStoreTransactionsLSN]
as
/*
select count(*) from [DataTrue_Report].[dbo].[StoreTransactions]
select * from [DataTrue_Report].[dbo].[StoreTransactions] where storeid = 12 and productid = 865
*/
declare @MyID int
declare @startlsn binary(10)
declare @endlsn binary(10)
declare @count int
declare @from_lsn binary(10)
declare @to_lsn binary(10)

set @MyID = 7607

begin try

begin transaction



SET @from_lsn = sys.fn_cdc_get_min_lsn(N'dbo_StoreTransactions');
SET @to_lsn = sys.fn_cdc_get_max_lsn();


--print @from_lsn

--print @to_lsn

--Archive all CDC records

--/*
insert into DataTrue_Archive..StoreTransactions 
([__$start_lsn]
      ,[__$end_lsn]
      ,[__$seqval]
      ,[__$operation]
      ,[__$update_mask]
      ,[StoreTransactionID]
      ,[ChainID]
      ,[StoreID]
      ,[ProductID]
      ,[SupplierID]
      ,[TransactionTypeID]
      ,[ProductPriceTypeID]
      ,[BrandID]
      ,[Qty]
      ,[SetupCost]
      ,[SetupRetail]
      ,[SaleDateTime]
      ,[UPC]
      ,[SupplierInvoiceNumber]
      ,[ReportedCost]
      ,[ReportedRetail]
      ,[ReportedAllowance]
      ,[ReportedPromotionPrice]
      ,[RuleCost]
      ,[RuleRetail]
      ,[CostMisMatch]
      ,[RetailMisMatch]
      ,[TrueCost]
      ,[TrueRetail]
      ,[ActualCostNetFee]
      ,[TransactionStatus]
      ,[Reversed]
      ,[ProcessingErrorDesc]
      ,[SourceID]
      ,[Comments]
      ,[InvoiceID]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[WorkingTransactionID]
      ,[InvoiceBatchID]
      ,[InventoryCost]
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
      ,[InvoiceNo]
      ,[PONo]
      ,[CorporateName]
      ,[CorporateIdentifier]
      ,[Banner]
      ,[PromoTypeID]
      ,[PromoAllowance]
      ,[SBTNumber]
      ,[SourceOrDestinationID]
      ,[CreditType]
      ,[PODReceived]
 )
SELECT [__$start_lsn]
      ,[__$end_lsn]
      ,[__$seqval]
      ,[__$operation]
      ,[__$update_mask]
      ,[StoreTransactionID]
      ,[ChainID]
      ,[StoreID]
      ,[ProductID]
      ,[SupplierID]
      ,[TransactionTypeID]
      ,[ProductPriceTypeID]
      ,[BrandID]
      ,[Qty]
      ,[SetupCost]
      ,[SetupRetail]
      ,[SaleDateTime]
      ,[UPC]
      ,[SupplierInvoiceNumber]
      ,[ReportedCost]
      ,[ReportedRetail]
      ,[ReportedAllowance]
      ,[ReportedPromotionPrice]
      ,[RuleCost]
      ,[RuleRetail]
      ,[CostMisMatch]
      ,[RetailMisMatch]
      ,[TrueCost]
      ,[TrueRetail]
      ,[ActualCostNetFee]
      ,[TransactionStatus]
      ,[Reversed]
      ,[ProcessingErrorDesc]
      ,[SourceID]
      ,[Comments]
      ,[InvoiceID]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[WorkingTransactionID]
      ,[InvoiceBatchID]
      ,[InventoryCost]
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
      ,[InvoiceNo]
      ,[PONo]
      ,[CorporateName]
      ,[CorporateIdentifier]
      ,[Banner]
      ,[PromoTypeID]
      ,[PromoAllowance]
      ,[SBTNumber]
      ,[SourceOrDestinationID]
      ,[CreditType]
      ,[PODReceived]
  FROM [DataTrue_Main].[cdc].[dbo_StoreTransactions_CT]
  where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
--*/

MERGE INTO [DataTrue_Report].[dbo].[StoreTransactions] i

USING (SELECT __$operation, [StoreTransactionID]
      ,[ChainID]
      ,[StoreID]
      ,[ProductID]
      ,[SupplierID]
      ,[TransactionTypeID]
      ,[ProductPriceTypeID]
      ,[BrandID]
      ,[Qty]
      ,[SetupCost]
      ,[SetupRetail]
      ,[SaleDateTime]
      ,[UPC]
      ,[SupplierInvoiceNumber]
      ,[ReportedCost]
      ,[ReportedRetail]
      ,[ReportedAllowance]
      ,[ReportedPromotionPrice]
      ,[RuleCost]
      ,[RuleRetail]
      ,[CostMisMatch]
      ,[RetailMisMatch]
      ,[TrueCost]
      ,[TrueRetail]
      ,[ActualCostNetFee]
      ,[TransactionStatus]
      ,[Reversed]
      ,[ProcessingErrorDesc]
      ,[SourceID]
      ,[Comments]
      ,[InvoiceID]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[WorkingTransactionID]
      ,[InvoiceBatchID]
      ,[InventoryCost]
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
      ,[InvoiceNo]
      ,[PONo]
      ,[CorporateName]
      ,[CorporateIdentifier]
      ,[Banner]
      ,[PromoTypeID]
      ,[PromoAllowance]
      ,[SBTNumber]
      ,[SourceOrDestinationID]
      ,[CreditType]
      ,[PODReceived]
		FROM cdc.fn_cdc_get_net_changes_dbo_StoreTransactions(@from_lsn, @to_lsn, 'all')
		where 1 = 1
		--and TransactionTypeID in (2,7) --Original POS
		--and __$operation in (2, 4)
		) S
		on i.StoreTransactionID = s.StoreTransactionID
WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
	
WHEN MATCHED THEN

update set  
	  [ChainID] = s.[ChainID]
	  ,[StoreID] = s.[StoreID]
      ,[ProductID] = s.[ProductID]
      ,[SupplierID] = s.[SupplierID]
      ,[TransactionTypeID] = s.[TransactionTypeID]
      ,[ProductPriceTypeID] = s.[ProductPriceTypeID]
      ,[BrandID] = s.[BrandID]
      ,[Qty] = s.[Qty]
      ,[SetupCost] = s.[SetupCost]
      ,[SetupRetail] = s.[SetupRetail]
      ,[SaleDateTime] = s.[SaleDateTime]
      ,[UPC] = s.[UPC]
      ,[SupplierInvoiceNumber] = s.[SupplierInvoiceNumber]
      ,[ReportedCost] = s.[ReportedCost]
      ,[ReportedRetail] = s.[ReportedRetail]
      ,[ReportedAllowance] = s.[ReportedAllowance]
      ,[ReportedPromotionPrice] = s.[ReportedPromotionPrice]
      ,[TransactionStatus] = s.[TransactionStatus]
      ,[Reversed] = s.[Reversed]
      ,[ProcessingErrorDesc] = s.[ProcessingErrorDesc]
      ,[SourceID] = s.[SourceID]
      ,[Comments] = s.[Comments]
      ,[InvoiceID] = s.[InvoiceID]
      ,[LastUpdateUserID] = s.[LastUpdateUserID]
      ,[DateTimeLastUpdate] = getdate()
      ,[WorkingTransactionID] = s.[WorkingTransactionID]
      ,[ReportingStatus] = 0
      ,[InvoiceBatchID] = s.[InvoiceBatchID]
      ,[InventoryCost] = s.[InventoryCost]
      ,[PromoTypeID] = s.[PromoTypeID]
      ,[PromoAllowance] = s.[PromoAllowance]
      ,[SBTNumber] = s.[SBTNumber]
      ,[RuleRetail] = s.[RuleRetail]
      ,[SourceOrDestinationID] = s.[SourceOrDestinationID]
      ,[CreditType] = s.[CreditType]
      ,[PODReceived]=s.[PODReceived]
	
WHEN NOT MATCHED 

THEN INSERT 
      ([StoreTransactionID]
      ,[ChainID]
      ,[StoreID]
      ,[ProductID]
      ,[SupplierID]
      ,[TransactionTypeID]
      ,[ProductPriceTypeID]
      ,[BrandID]
      ,[Qty]
      ,[SetupCost]
      ,[SetupRetail]
      ,[SaleDateTime]
      ,[UPC]
      ,[SupplierInvoiceNumber]
      ,[ReportedCost]
      ,[ReportedRetail]
      ,[RuleCost]
      ,[RuleRetail]
      ,[TrueCost]
      ,[TrueRetail]
      ,[CostMisMatch]
      ,[RetailMisMatch]
      ,[ActualCostNetFee]
      ,[TransactionStatus]
      ,[Reversed]
      ,[ProcessingErrorDesc]
      ,[SourceID]
      ,[Comments]
      ,[InvoiceID]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[WorkingTransactionID]
      ,[InvoiceBatchID]
      ,[InventoryCost]
      ,[ReportedAllowance]
      ,[ReportedPromotionPrice]
      ,[PromoTypeID]
      ,[PromoAllowance]
      ,[SBTNumber]
      ,[SourceOrDestinationID]
      ,[CreditType]
      ,[PODReceived])
     VALUES
      (s.[StoreTransactionID]
      ,s.[ChainID]
      ,s.[StoreID]
      ,s.[ProductID]
      ,s.[SupplierID]
      ,s.[TransactionTypeID]
      ,s.[ProductPriceTypeID]
      ,s.[BrandID]
      ,s.[Qty]
      ,s.[SetupCost]
      ,s.[SetupRetail]
      ,s.[SaleDateTime]
      ,s.[UPC]
      ,s.[SupplierInvoiceNumber]
      ,s.[ReportedCost]
      ,s.[ReportedRetail]
      ,s.[RuleCost]
      ,s.[RuleRetail]
      ,s.[TrueCost]
      ,s.[TrueRetail]
      ,s.[CostMisMatch]
      ,s.[RetailMisMatch]
      ,s.[ActualCostNetFee]
      ,s.[TransactionStatus]
      ,s.[Reversed]
      ,s.[ProcessingErrorDesc]
      ,s.[SourceID]
      ,s.[Comments]
      ,s.[InvoiceID]
      ,s.[DateTimeCreated]
      ,s.[LastUpdateUserID]
      ,s.[DateTimeLastUpdate]
      ,s.[WorkingTransactionID]
      ,s.[InvoiceBatchID]
      ,s.[InventoryCost]
      ,s.[ReportedAllowance]
      ,s.[ReportedPromotionPrice]
      ,s.[PromoTypeID]
      ,s.[PromoAllowance]
      ,s.[SBTNumber]
      ,s.[SourceOrDestinationID]
      ,s.[CreditType]
      ,s.[PODReceived]);	


	delete cdc.dbo_StoreTransactions_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn

/*


	delete cdc.dbo_StoreTransactions_CT
	where 1 = 1
	--and __$start_lsn >= 0x0000309F0000096900CD
	and __$end_lsn <= 0x000030CD000006000004

	select count(*) from cdc.dbo_StoreTransactions_CT
	
	FROM cdc.fn_cdc_get_net_changes_dbo_StoreTransactions(@from_lsn, @to_lsn, 'all')
*/		
 
commit transaction
	
end try
	
begin catch
		rollback transaction
		declare @errormessage varchar(4500)
		declare @errorlocation varchar(255)
		declare @errorsenderstring nvarchar(255)

		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring =  ERROR_PROCEDURE()
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
end catch
	

return
GO
