USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetStoreTransactions_ForwardLSN_New]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetStoreTransactions_ForwardLSN_New]
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

exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMinLSN_TableName 'dbo_StoreTransactions_Forward',@from_lsn output

exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMaxLSN @to_lsn output--sys.fn_cdc_get_max_lsn();

/*
--print @from_lsn

--print @to_lsn

--Archive all CDC records

--/*

insert into [IC-HQSQL1INST2].DataTrue_Archive.dbo.StoreTransactions_Forward
([__$start_lsn]
      ,[__$end_lsn]
      ,[__$seqval]
      ,[__$operation]
      ,[__$update_mask]
      ,[StoreTransactionForwardID]
      ,[ChainID]
      ,[StoreID]
      ,[ProductID]
      ,[SupplierID]
      ,[TransactionTypeID]
      ,[BrandID]
      ,[Qty]
      ,[RuleCost]
      ,[SetupCost]
      ,[RuleRetail]
      ,[SetupRetail]
      ,[SaleDateTime]
      ,[UPC]
      ,[TransactionStatus]
      ,[SourceID]
      ,[Comments]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[PODReceived]
 )
SELECT [__$start_lsn]
      ,[__$end_lsn]
      ,[__$seqval]
      ,[__$operation]
      ,[__$update_mask]
      ,[StoreTransactionForwardID]
      ,[ChainID]
      ,[StoreID]
      ,[ProductID]
      ,[SupplierID]
      ,[TransactionTypeID]
      ,[BrandID]
      ,[Qty]
      ,[RuleCost]
      ,[SetupCost]
      ,[RuleRetail]
      ,[SetupRetail]
      ,[SaleDateTime]
      ,[UPC]
      ,[TransactionStatus]
      ,[SourceID]
      ,[Comments]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[PODReceived]
  FROM [IC-HQSQL1\DataTrue].[DataTrue_Main].[cdc].[dbo_StoreTransactions_Forward_CT]
  where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
--*/

MERGE INTO [DataTrue_Report].[dbo].[StoreTransactions_Forward] i

USING (SELECT 
      [__$operation]
      ,[StoreTransactionForwardID]
      ,[ChainID]
      ,[StoreID]
      ,[ProductID]
      ,[SupplierID]
      ,[TransactionTypeID]
      ,[BrandID]
      ,[Qty]
      ,[RuleCost]
      ,[SetupCost]
      ,[RuleRetail]
      ,[SetupRetail]
      ,[SaleDateTime]
      ,[UPC]
      ,[TransactionStatus]
      ,[SourceID]
      ,[Comments]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[PODReceived]
		--FROM cdc.fn_cdc_get_net_changes_dbo_StoreTransactions_Forward(@from_lsn, @to_lsn, 'all')
		FROM [IC-HQSQL1\DataTrue].[DataTrue_Main].[cdc].[dbo_StoreTransactions_Forward_CT]
		where __$start_lsn >= @from_lsn
		and __$start_lsn <= @to_lsn
		--and TransactionTypeID in (2,7) --Original POS
		--and __$operation in (2, 4)
		) S
		on i.StoreTransactionForwardID = s.StoreTransactionForwardID
WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
	
WHEN MATCHED THEN

update SET
       [ChainID] = s.ChainID
      ,[StoreID] = s.StoreID
      ,[ProductID] = s.ProductID
      ,[SupplierID] = s.SupplierID
      ,[TransactionTypeID] = s.TransactionTypeID
      ,[BrandID] = s.BrandID
      ,[Qty] = s.Qty
      ,[RuleCost] = s.RuleCost
      ,[SetupCost] = s.SetupCost
      ,[RuleRetail] = s.RuleRetail
      ,[SetupRetail] = s.SetupRetail
      ,[SaleDateTime] = s.SaleDateTime
      ,[UPC] = s.UPC
      ,[TransactionStatus] = s.TransactionStatus
      ,[SourceID] = s.SourceID
      ,[Comments] = s.Comments
      ,[DateTimeCreated] = s.DateTimeCreated
      ,[LastUpdateUserID] = s.LastUpdateUserID
      ,[DateTimeLastUpdate] = s.DateTimeLastUpdate
      ,[PODReceived] = s.PODReceived

	
WHEN NOT MATCHED 

THEN INSERT 
      (
           [StoreTransactionForwardID]
           ,[ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[SupplierID]
           ,[TransactionTypeID]
           ,[BrandID]
           ,[Qty]
           ,[RuleCost]
           ,[SetupCost]
           ,[RuleRetail]
           ,[SetupRetail]
           ,[SaleDateTime]
           ,[UPC]
           ,[TransactionStatus]
           ,[SourceID]
           ,[Comments]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[PODReceived])
     VALUES
           (s.StoreTransactionForwardID
           ,s.ChainID
           ,s.StoreID
           ,s.ProductID
           ,s.SupplierID
           ,s.TransactionTypeID
           ,s.BrandID
           ,s.Qty
           ,s.RuleCost
           ,s.SetupCost
           ,s.RuleRetail
           ,s.SetupRetail
           ,s.SaleDateTime
           ,s.UPC
           ,s.TransactionStatus
           ,s.SourceID
           ,s.Comments
           ,s.DateTimeCreated
           ,s.LastUpdateUserID
           ,s.DateTimeLastUpdate
           ,s.PODReceived);
	
--EDI
MERGE INTO FROM [IC-HQSQL1\DataTrue].[DataTrue_EDI].[dbo].[StoreTransactions_Forward] i

USING (SELECT 
      [__$operation]
      ,[StoreTransactionForwardID]
      ,[ChainID]
      ,[StoreID]
      ,[ProductID]
      ,[SupplierID]
      ,[TransactionTypeID]
      ,[BrandID]
      ,[Qty]
      ,[RuleCost]
      ,[SetupCost]
      ,[RuleRetail]
      ,[SetupRetail]
      ,[SaleDateTime]
      ,[UPC]
      ,[TransactionStatus]
      ,[SourceID]
      ,[Comments]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[PODReceived]
		--FROM cdc.fn_cdc_get_net_changes_dbo_StoreTransactions_Forward(@from_lsn, @to_lsn, 'all')
		FROM [IC-HQSQL1\DataTrue].[DataTrue_Main].[cdc].[dbo_StoreTransactions_Forward_CT]
		where __$start_lsn >= @from_lsn
		and __$start_lsn <= @to_lsn
		and __$operation<>3
    order by __$start_lsn
		--and TransactionTypeID in (2,7) --Original POS
		--and __$operation in (2, 4)
		) S
		on i.StoreTransactionForwardID = s.StoreTransactionForwardID
WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
	
WHEN MATCHED THEN

update SET
       [ChainID] = s.ChainID
      ,[StoreID] = s.StoreID
      ,[ProductID] = s.ProductID
      ,[SupplierID] = s.SupplierID
      ,[TransactionTypeID] = s.TransactionTypeID
      ,[BrandID] = s.BrandID
      ,[Qty] = s.Qty
      ,[RuleCost] = s.RuleCost
      ,[SetupCost] = s.SetupCost
      ,[RuleRetail] = s.RuleRetail
      ,[SetupRetail] = s.SetupRetail
      ,[SaleDateTime] = s.SaleDateTime
      ,[UPC] = s.UPC
      ,[TransactionStatus] = s.TransactionStatus
      ,[SourceID] = s.SourceID
      ,[Comments] = s.Comments
      ,[DateTimeCreated] = s.DateTimeCreated
      ,[LastUpdateUserID] = s.LastUpdateUserID
      ,[DateTimeLastUpdate] = s.DateTimeLastUpdate
      ,[PODReceived] = s.PODReceived

	
WHEN NOT MATCHED 

THEN INSERT 
      (
           [StoreTransactionForwardID]
           ,[ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[SupplierID]
           ,[TransactionTypeID]
           ,[BrandID]
           ,[Qty]
           ,[RuleCost]
           ,[SetupCost]
           ,[RuleRetail]
           ,[SetupRetail]
           ,[SaleDateTime]
           ,[UPC]
           ,[TransactionStatus]
           ,[SourceID]
           ,[Comments]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[PODReceived])
     VALUES
           (s.StoreTransactionForwardID
           ,s.ChainID
           ,s.StoreID
           ,s.ProductID
           ,s.SupplierID
           ,s.TransactionTypeID
           ,s.BrandID
           ,s.Qty
           ,s.RuleCost
           ,s.SetupCost
           ,s.RuleRetail
           ,s.SetupRetail
           ,s.SaleDateTime
           ,s.UPC
           ,s.TransactionStatus
           ,s.SourceID
           ,s.Comments
           ,s.DateTimeCreated
           ,s.LastUpdateUserID
           ,s.DateTimeLastUpdate
           ,s.PODReceived);
	

	delete FROM [IC-HQSQL1\DataTrue].[DataTrue_Main].cdc.dbo_StoreTransactions_Forward_CT
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
		
		exec [IC-HQSQL1\DataTrue].[DataTrue_Main].dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
end catch
	

return
GO
