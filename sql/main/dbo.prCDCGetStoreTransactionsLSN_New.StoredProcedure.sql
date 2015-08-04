USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetStoreTransactionsLSN_New]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetStoreTransactionsLSN_New]
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

--begin transaction

exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMinLSN_TableName 'dbo_StoreTransactions',@from_lsn output

exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMaxLSN @to_lsn output--sys.fn_cdc_get_max_lsn();

--print @from_lsn

--print @to_lsn

--Archive all CDC records

/*
insert into [IC-HQSQL1INST2].DataTrue_Archive.dbo.StoreTransactions 
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
      ,[ShrinkLocked],
	[InvoiceDueDate],
	[Adjustment1] ,
	[Adjustment2],
	[Adjustment3],
	[Adjustment4],
	[Adjustment5],
	[Adjustment6],
	[Adjustment7],
	[Adjustment8],
	[Route],
	[SupplierItemNumber],
	[ProductDescriptionReported],
	[RawStoreIdentifier],
	[CaseUPC],
	[UnAuthorizedAssignment]
	,[Rowversion],
	[SetupAllowance]
	
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
      ,[ShrinkLocked],
	[InvoiceDueDate],
	[Adjustment1] ,
	[Adjustment2],
	[Adjustment3],
	[Adjustment4],
	[Adjustment5],
	[Adjustment6],
	[Adjustment7],
	[Adjustment8],
	[Route],
	[SupplierItemNumber],
	[ProductDescriptionReported],
	[RawStoreIdentifier],
	[CaseUPC],
	[UnAuthorizedAssignment],
	[Rowversion],
	[SetupAllowance]
--	select COUNT(*)
  FROM [IC-HQSQL1\DataTrue].DataTrue_Main.[cdc].[dbo_StoreTransactions_CT] with (nolock)
  where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn


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
      ,[ShrinkLocked],
	[InvoiceDueDate],
	[Adjustment1] ,
	[Adjustment2],
	[Adjustment3],
	[Adjustment4],
	[Adjustment5],
	[Adjustment6],
	[Adjustment7],
	[Adjustment8],
	[Route],
	[SupplierItemNumber],
	[ProductDescriptionReported],
	[RawStoreIdentifier],
	[CaseUPC],
	[UnAuthorizedAssignment],
	[Rowversion],
	[SetupAllowance]
		FROM [IC-HQSQL1\DataTrue].DataTrue_Main.[cdc].[dbo_StoreTransactions_CT] with (nolock)
  where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
	and __$operation<>3
    order by __$start_lsn
		) S
		on i.StoreTransactionID = s.StoreTransactionID
WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
	
WHEN MATCHED THEN

update set 
[ChainID]= s.[ChainID]
      ,[StoreID]= s.[StoreID]
      ,[ProductID]= s.[ProductID]
      ,[SupplierID]= s.[SupplierID]
      ,[TransactionTypeID]= s.[TransactionTypeID]
      ,[ProductPriceTypeID]= s.[ProductPriceTypeID]
      ,[BrandID]= s.[BrandID]
      ,[Qty]= s.[Qty]
      ,[SetupCost]= s.[SetupCost]
      ,[SetupRetail]= s.[SetupRetail]
      ,[SaleDateTime]= s.[SaleDateTime]
      ,[UPC]= s.[UPC]
      ,[SupplierInvoiceNumber]= s.[SupplierInvoiceNumber]
      ,[ReportedCost]= s.[ReportedCost]
      ,[ReportedRetail]= s.[ReportedRetail]
      ,[ReportedAllowance]= s.[ReportedAllowance]
      ,[ReportedPromotionPrice]= s.[ReportedPromotionPrice]
      ,[RuleCost]= s.[RuleCost]
      ,[RuleRetail]= s.[RuleRetail]
      ,[CostMisMatch]= s.[CostMisMatch]
      ,[RetailMisMatch]= s.[RetailMisMatch]
      ,[TrueCost]= s.[TrueCost]
      ,[TrueRetail]= s.[TrueRetail]
      ,[ActualCostNetFee]= s.[ActualCostNetFee]
      ,[TransactionStatus]= s.[TransactionStatus]
      ,[Reversed]= s.[Reversed]
      ,[ProcessingErrorDesc]= s.[ProcessingErrorDesc]
      ,[SourceID]= s.[SourceID]
      ,[Comments]= s.[Comments]
      ,[InvoiceID]= s.[InvoiceID]
      ,[DateTimeCreated]= s.[DateTimeCreated]
      ,[LastUpdateUserID]= s.[LastUpdateUserID]
      ,[DateTimeLastUpdate]= s.[DateTimeLastUpdate]
      ,[WorkingTransactionID]= s.[WorkingTransactionID]
      ,[InvoiceBatchID]= s.[InvoiceBatchID]
      ,[InventoryCost]= s.[InventoryCost]
      ,[ChainIdentifier]= s.[ChainIdentifier]
      ,[StoreIdentifier]= s.[StoreIdentifier]
      ,[StoreName]= s.[StoreName]
      ,[ProductIdentifier]= s.[ProductIdentifier]
      ,[ProductQualifier]= s.[ProductQualifier]
      ,[RawProductIdentifier]= s.[RawProductIdentifier]
      ,[SupplierName]= s.[SupplierName]
      ,[SupplierIdentifier]= s.[SupplierIdentifier]
      ,[BrandIdentifier]= s.[BrandIdentifier]
      ,[DivisionIdentifier]= s.[DivisionIdentifier]
      ,[UOM]= s.[UOM]
      ,[SalePrice]= s.[SalePrice]
      ,[InvoiceNo]= s.[InvoiceNo]
      ,[PONo]= s.[PONo]
      ,[CorporateName]= s.[CorporateName]
      ,[CorporateIdentifier]= s.[CorporateIdentifier]
      ,[Banner]= s.[Banner]
      ,[PromoTypeID]= s.[PromoTypeID]
      ,[PromoAllowance]= s.[PromoAllowance]
      ,[SBTNumber]= s.[SBTNumber]
      ,[SourceOrDestinationID]= s.[SourceOrDestinationID]
      ,[CreditType]= s.[CreditType]
      ,[PODReceived]= s.[PODReceived]
      ,[ShrinkLocked]= s.[ShrinkLocked],
	[InvoiceDueDate]= s.[InvoiceDueDate],
	[Adjustment1]= s.[Adjustment1] ,
	[Adjustment2]= s.[Adjustment2],
	[Adjustment3]= s.[Adjustment3],
	[Adjustment4]= s.[Adjustment4],
	[Adjustment5]= s.[Adjustment5],
	[Adjustment6]= s.[Adjustment6],
	[Adjustment7]= s.[Adjustment7],
	[Adjustment8]= s.[Adjustment8],
	[Route]= s.[Route],
	[SupplierItemNumber]= s.[SupplierItemNumber],
	[ProductDescriptionReported]= s.[ProductDescriptionReported],
	[RawStoreIdentifier]= s.[RawStoreIdentifier],
	[CaseUPC]= s.[CaseUPC],
	[UnAuthorizedAssignment]= s.[UnAuthorizedAssignment]
	 
	--  [ChainID] = s.[ChainID]
	--  ,[StoreID] = s.[StoreID]
 --     ,[ProductID] = s.[ProductID]
 --     ,[SupplierID] = s.[SupplierID]
 --     ,[TransactionTypeID] = s.[TransactionTypeID]
 --     ,[ProductPriceTypeID] = s.[ProductPriceTypeID]
 --     ,[BrandID] = s.[BrandID]
 --     ,[Qty] = s.[Qty]
 --     ,[SetupCost] = s.[SetupCost]
 --     ,[SetupRetail] = s.[SetupRetail]
 --     ,[SaleDateTime] = s.[SaleDateTime]
 --     ,[UPC] = s.[UPC]
 --     ,[SupplierInvoiceNumber] = s.[SupplierInvoiceNumber]
 --     ,[ReportedCost] = s.[ReportedCost]
 --     ,[ReportedRetail] = s.[ReportedRetail]
 --     ,[ReportedAllowance] = s.[ReportedAllowance]
 --     ,[ReportedPromotionPrice] = s.[ReportedPromotionPrice]
 --     ,[TransactionStatus] = s.[TransactionStatus]
 --     ,[Reversed] = s.[Reversed]
 --     ,[ProcessingErrorDesc] = s.[ProcessingErrorDesc]
 --     ,[SourceID] = s.[SourceID]
 --     ,[Comments] = s.[Comments]
 --     ,[InvoiceID] = s.[InvoiceID]
 --     ,[LastUpdateUserID] = s.[LastUpdateUserID]
 --     ,[DateTimeLastUpdate] = getdate()
 --     ,[WorkingTransactionID] = s.[WorkingTransactionID]
 --     ,[ReportingStatus] = 0
 --     ,[InvoiceBatchID] = s.[InvoiceBatchID]
 --     ,[InventoryCost] = s.[InventoryCost]
 --     ,[PromoTypeID] = s.[PromoTypeID]
 --     ,[PromoAllowance] = s.[PromoAllowance]
 --     ,[SBTNumber] = s.[SBTNumber]
 --     ,[RuleRetail] = s.[RuleRetail]
 --     ,[SourceOrDestinationID] = s.[SourceOrDestinationID]
 --     ,[CreditType] = s.[CreditType]
 --     ,[PODReceived]=s.[PODReceived]
 --     ,[ShrinkLocked]=s.[ShrinkLocked]
 --     ,[InvoiceDueDate]=s.[InvoiceDueDate]
 --     ,[Adjustment1] =s.[Adjustment1]
 --     ,[Adjustment2]=s.[Adjustment2]
	--,[Adjustment3]=s.[Adjustment3]
	--,[Adjustment4]=s.[Adjustment4]
	--,[Adjustment5]=s.[Adjustment5]
	--,[Adjustment6]=s.[Adjustment6]
	--,[Adjustment7]=s.[Adjustment7]
	--,[Adjustment8]=s.[Adjustment8]
	--,[Route]=s.[Route]
	--,[SupplierItemNumber]=s.[SupplierItemNumber]
	--,[ProductDescriptionReported]=s.[ProductDescriptionReported]
	--,[RawStoreIdentifier]=s.[RawStoreIdentifier]
	--,[CaseUPC]=s.[CaseUPC]
	--,[UnAuthorizedAssignment]=s.[UnAuthorizedAssignment]
	--,[rv]=s.[Rowversion]
	,[SetupAllowance]=s.[SetupAllowance]
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
      ,[PODReceived]
       ,[ShrinkLocked],
	[InvoiceDueDate],
	[Adjustment1] ,
	[Adjustment2],
	[Adjustment3],
	[Adjustment4],
	[Adjustment5],
	[Adjustment6],
	[Adjustment7],
	[Adjustment8],
	[Route],
	[SupplierItemNumber],
	[ProductDescriptionReported],
	[RawStoreIdentifier],
	[CaseUPC],
	[UnAuthorizedAssignment],
	[SetupAllowance]
      )
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
      ,s.[PODReceived]
       ,s.[ShrinkLocked],
	s.[InvoiceDueDate],
	s.[Adjustment1] ,
	s.[Adjustment2],
	s.[Adjustment3],
	s.[Adjustment4],
	s.[Adjustment5],
	s.[Adjustment6],
	s.[Adjustment7],
	s.[Adjustment8],
	s.[Route],
	s.[SupplierItemNumber],
	s.[ProductDescriptionReported],
	s.[RawStoreIdentifier],
	s.[CaseUPC],
	s.[UnAuthorizedAssignment],
	--, s.[Rowversion]
    [SetupAllowance]
      
      );	


	delete [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_StoreTransactions_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn

*/

 
--commit transaction
	
end try
	
begin catch

		--rollback transaction
		
		declare @errormessage varchar(4500)
		declare @errorlocation varchar(255)
		declare @errorsenderstring nvarchar(255)

		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring =  ERROR_PROCEDURE()
		--print(@errormessage);
		exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
end catch
	

return
GO
