USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetInvoiceDetailsLSN_New]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetInvoiceDetailsLSN_New]
as

declare @MyID int
declare @startlsn binary(10)
declare @endlsn binary(10)
declare @count int
declare @from_lsn binary(10)
declare @to_lsn binary(10)

set @MyID = 0

begin try

--begin transaction


exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMinLSN_TableName 'dbo_InvoiceDetails',@from_lsn output

exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMaxLSN @to_lsn output--sys.fn_cdc_get_max_lsn();

--print @from_lsn

--print @to_lsn

--Archive all CDC records

/*

insert into [IC-HQSQL1INST2].DataTrue_Archive.dbo.dbo_InvoiceDetails_CT 
select * from [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_InvoiceDetails_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn

MERGE INTO [DataTrue_Report].[dbo].invoicedetails t

USING (SELECT __$operation, [InvoiceDetailID]
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
      ,[PromoTypeID]
      ,[PromoAllowance]
      ,[InventorySettlementID]
      ,[SBTNumber]
      ,[FinalInvoiceUnitCost]
      ,[FinalInvoiceUnitPromo]
      ,[FinalInvoiceTotalCost]
      ,[FinalInvoiceQty]
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
      ,[SourceID]
    From [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_InvoiceDetails_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
	and __$operation<>3
	order by __$start_lsn
		) s
		on t.InvoiceDetailId = s.InvoiceDetailId

WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
	
WHEN MATCHED THEN

update set  

      [RetailerInvoiceID]=s.RetailerInvoiceID
      ,[SupplierInvoiceID]=s.SupplierInvoiceID
      ,[ChainID]=s.ChainID
      ,[StoreID]=s.StoreID
      ,[ProductID]=s.ProductID
      ,[BrandID]=s.BrandID
      ,[SupplierID]=s.SupplierID
      ,[InvoiceDetailTypeID]=s.InvoiceDetailTypeID
      ,[TotalQty]=s.[TotalQty]
      ,[UnitCost]=s.[UnitCost]
      ,[UnitRetail]=s.[UnitRetail]
      ,[TotalCost]=s.[TotalCost]
      ,[TotalRetail]=s.[TotalRetail]
      ,[SaleDate]=s.[SaleDate]
      ,[RecordStatus]=s.[RecordStatus]
      ,[DateTimeCreated]=s.[DateTimeCreated]
      ,[LastUpdateUserID]=s.[LastUpdateUserID]
      ,[DateTimeLastUpdate]=s.[DateTimeLastUpdate]
      ,[BatchID]=s.[BatchID]
      ,[ChainIdentifier]=s.[ChainIdentifier]
      ,[StoreIdentifier]=s.[StoreIdentifier]
      ,[StoreName]=s.[StoreName]
      ,[ProductIdentifier]=s.[ProductIdentifier]
      ,[ProductQualifier]=s.[ProductQualifier]
      ,[RawProductIdentifier]=s.[RawProductIdentifier]
      ,[SupplierName]=s.[SupplierName]
      ,[SupplierIdentifier]=s.[SupplierIdentifier]
      ,[BrandIdentifier]=s.[BrandIdentifier]
      ,[DivisionIdentifier]=s.[DivisionIdentifier]
      ,[UOM]=s.[UOM]
      ,[SalePrice]=s.[SalePrice]
      ,[Allowance]=s.[Allowance]
      ,[InvoiceNo]=s.[InvoiceNo]
      ,[PONo]=s.[PONo]
      ,[CorporateName]=s.[CorporateName]
      ,[CorporateIdentifier]=s.[CorporateIdentifier]
      ,[Banner]=s.[Banner]
      ,[PromoTypeID]=s.[PromoTypeID]
      ,[PromoAllowance]=s.[PromoAllowance]
      ,[InventorySettlementID]=s.[InventorySettlementID]
      ,[SBTNumber]=s.[SBTNumber]
      ,[FinalInvoiceUnitCost]=s.[FinalInvoiceUnitCost]
      ,[FinalInvoiceUnitPromo]=s.[FinalInvoiceUnitPromo]
      ,[FinalInvoiceTotalCost]=s.[FinalInvoiceTotalCost]
      ,[FinalInvoiceQty]=s.[FinalInvoiceQty]
      ,[OriginalShrinkTotalQty]=s.[OriginalShrinkTotalQty]
      ,[PaymentDueDate]=s.[PaymentDueDate]
      ,[PaymentID]=s.[PaymentID]
      ,[Adjustment1]=s.[Adjustment1]
      ,[Adjustment2]=s.[Adjustment2]
      ,[Adjustment3]=s.[Adjustment3]
      ,[Adjustment4]=s.[Adjustment4]
      ,[Adjustment5]=s.[Adjustment5]
      ,[Adjustment6]=s.[Adjustment6]
      ,[Adjustment7]=s.[Adjustment7]
      ,[Adjustment8]=s.[Adjustment8]
      ,[PDIParticipant]=s.[PDIParticipant]
      ,[RetailUOM]=s.[RetailUOM]
      ,[RetailTotalQty]=s.[RetailTotalQty]
      ,[VIN]=s.[VIN]
      ,[RawStoreIdentifier]=s.[RawStoreIdentifier]
      ,[Route]=s.[Route]
      ,[SourceID]=s.[SourceID]
     
	
WHEN NOT MATCHED 

THEN INSERT 
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
      ,[PromoTypeID]
      ,[PromoAllowance]
      ,[InventorySettlementID]
      ,[SBTNumber]
      ,[FinalInvoiceUnitCost]
      ,[FinalInvoiceUnitPromo]
      ,[FinalInvoiceTotalCost]
      ,[FinalInvoiceQty]
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
      ,[SourceID]
           )
     VALUES
           (s.[InvoiceDetailID]
      ,s.[RetailerInvoiceID]
      ,s.[SupplierInvoiceID]
      ,s.[ChainID]
      ,s.[StoreID]
      ,s.[ProductID]
      ,s.[BrandID]
      ,s.[SupplierID]
      ,s.[InvoiceDetailTypeID]
      ,s.[TotalQty]
      ,s.[UnitCost]
      ,s.[UnitRetail]
      ,s.[TotalCost]
      ,s.[TotalRetail]
      ,s.[SaleDate]
      ,s.[RecordStatus]
      ,s.[DateTimeCreated]
      ,s.[LastUpdateUserID]
      ,s.[DateTimeLastUpdate]
      ,s.[BatchID]
      ,s.[ChainIdentifier]
      ,s.[StoreIdentifier]
      ,s.[StoreName]
      ,s.[ProductIdentifier]
      ,s.[ProductQualifier]
      ,s.[RawProductIdentifier]
      ,s.[SupplierName]
      ,s.[SupplierIdentifier]
      ,s.[BrandIdentifier]
      ,s.[DivisionIdentifier]
      ,s.[UOM]
      ,s.[SalePrice]
      ,s.[Allowance]
      ,s.[InvoiceNo]
      ,s.[PONo]
      ,s.[CorporateName]
      ,s.[CorporateIdentifier]
      ,s.[Banner]
      ,s.[PromoTypeID]
      ,s.[PromoAllowance]
      ,s.[InventorySettlementID]
      ,s.[SBTNumber]
      ,s.[FinalInvoiceUnitCost]
      ,s.[FinalInvoiceUnitPromo]
      ,s.[FinalInvoiceTotalCost]
      ,s.[FinalInvoiceQty]
      ,s.[OriginalShrinkTotalQty]
      ,s.[PaymentDueDate]
      ,s.[PaymentID]
      ,s.[Adjustment1]
      ,s.[Adjustment2]
      ,s.[Adjustment3]
      ,s.[Adjustment4]
      ,s.[Adjustment5]
      ,s.[Adjustment6]
      ,s.[Adjustment7]
      ,s.[Adjustment8]
      ,s.[PDIParticipant]
      ,s.[RetailUOM]
      ,s.[RetailTotalQty]
      ,s.[VIN]
      ,s.[RawStoreIdentifier]
      ,s.[Route]
      ,s.[SourceID]
           );	


	delete [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_InvoiceDetails_CT
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
		--print @errormessage;
		exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
end catch
	

return
GO
