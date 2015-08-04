USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetInventoryPerpetualUpdatesLSN_New]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetInventoryPerpetualUpdatesLSN_New]
as

DECLARE @from_lsn binary(10)
declare @to_lsn binary(10)
declare @MyID int
set @MyID = 7607

--begin transaction

exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMinLSN_TableName 'dbo_InventoryPerpetual',@from_lsn output
--SET @to_lsn = 
exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMaxLSN @to_lsn output--sys.fn_cdc_get_max_lsn();

/*

INSERT INTO [IC-HQSQL1INST2].[DataTrue_Archive].[dbo].[InventoryPerpetual]
           ([__$start_lsn]
           ,[__$end_lsn]
           ,[__$seqval]
           ,[__$operation]
           ,[__$update_mask]
           ,[RecordID]
           ,[ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[BrandID]
           ,[OriginalQty]
           ,[Deliveries]
           ,[Pickups]
           ,[SBTSales]
           ,[CurrentOnHandQty]
           ,[ShrinkRevision]
           ,[Cost]
           ,[Retail]
           ,[EffectiveDateTime]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[TempID]
           ,[OriginatingStoreTransactionID]
           ,[TempStoreIDTest]
           ,[TempAddThisRecord]
           ,[ShrinkPerpetual])
SELECT [__$start_lsn]
      ,[__$end_lsn]
      ,[__$seqval]
      ,[__$operation]
      ,[__$update_mask]
      ,[RecordID]
      ,[ChainID]
      ,[StoreID]
      ,[ProductID]
      ,[BrandID]
      ,[OriginalQty]
      ,[Deliveries]
      ,[Pickups]
      ,[SBTSales]
      ,[CurrentOnHandQty]
      ,[ShrinkRevision]
      ,[Cost]
      ,[Retail]
      ,[EffectiveDateTime]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[TempID]
      ,[OriginatingStoreTransactionID]
      ,[TempStoreIDTest]
      ,[TempAddThisRecord]
      ,[ShrinkPerpetual]
  FROM [IC-HQSQL1\DataTrue].[DataTrue_Main].[cdc].[dbo_InventoryPerpetual_CT]
where __$start_lsn >= @from_lsn
and __$start_lsn <= @to_lsn

--******************************************
MERGE INTO [IC-HQSQL1INST2].[DataTrue_Report].[dbo].[InventoryPerpetual] i

USING (SELECT __$operation,[RecordID]
      ,[ChainID]
      ,[StoreID]
      ,[ProductID]
      ,[BrandID]
      ,[OriginalQty]
      ,[Deliveries]
      ,[Pickups]
      ,[SBTSales]
      ,[CurrentOnHandQty]
      ,[ShrinkRevision]
      ,[Cost]
      ,[Retail]
      ,[EffectiveDateTime]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[TempID]
      ,[OriginatingStoreTransactionID]
      ,[TempStoreIDTest]
      ,[TempAddThisRecord]
      ,[ShrinkPerpetual]
  --FROM cdc.fn_cdc_get_net_changes_dbo_InventoryPerpetual(@from_lsn, @to_lsn, 'all')
	FROM [IC-HQSQL1\DataTrue].[DataTrue_Main].[cdc].[dbo_InventoryPerpetual_CT]
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
	and __$operation<>3
	order by __$start_lsn
  ) S
	on i.StoreID = s.StoreID
	and i.ProductID = s.ProductID
	and i.BrandID = s.BrandID

WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
	
WHEN MATCHED THEN

update set  
	  [OriginalQty] = s.[OriginalQty]
      ,[Deliveries] = s.[Deliveries]
      ,[Pickups] = s.[Pickups]
      ,[SBTSales] = s.[SBTSales]
      ,[ShrinkRevision] = s.[ShrinkRevision]
      ,[CurrentOnHandQty] = s.[CurrentOnHandQty]
      ,[DateTimeCreated] = s.[DateTimeCreated]
      ,[LastUpdateUserID] = s.[LastUpdateUserID]
      ,[DateTimeLastUpdate] = s.[DateTimeLastUpdate]
      ,[EffectiveDateTime] = s.[EffectiveDateTime]
      ,[Cost] = s.[Cost]
      ,[Retail] = s.[Retail]
      ,[TempID]=s.[TempID]
      ,[OriginatingStoreTransactionID]=s.[OriginatingStoreTransactionID]
      ,[TempStoreIDTest]=s.[TempStoreIDTest]
      ,[TempAddThisRecord]=s.[TempAddThisRecord]
      ,[ShrinkPerpetual]=s.[ShrinkPerpetual]
	
WHEN NOT MATCHED 

THEN INSERT 
	  ([RecordID]
      ,[ChainID]
      ,[StoreID]
      ,[ProductID]
      ,[BrandID]
      ,[OriginalQty]
      ,[Deliveries]
      ,[Pickups]
      ,[SBTSales]
      ,[ShrinkRevision]
      ,[CurrentOnHandQty]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[EffectiveDateTime]
      ,[Cost]
      ,[Retail]
      ,[TempID]
      ,[OriginatingStoreTransactionID]
      ,[TempStoreIDTest]
      ,[TempAddThisRecord]
      ,[ShrinkPerpetual]
      )
     VALUES
      (s.[RecordID]
      ,s.[ChainID]
      ,s.[StoreID]
      ,s.[ProductID]
      ,s.[BrandID]
      ,s.[OriginalQty]
      ,s.[Deliveries]
      ,s.[Pickups]
      ,s.[SBTSales]
      ,s.[ShrinkRevision]
      ,s.[CurrentOnHandQty]
      ,s.[DateTimeCreated]
      ,s.[LastUpdateUserID]
      ,s.[DateTimeLastUpdate]
      ,s.[EffectiveDateTime]
      ,s.[Cost]
      ,s.[Retail]
      ,s.[TempID]
      ,s.[OriginatingStoreTransactionID]
      ,s.[TempStoreIDTest]
      ,s.[TempAddThisRecord]
      ,s.[ShrinkPerpetual]);

--******************************************

delete from FROM [IC-HQSQL1\DataTrue].[DataTrue_Main].[cdc].[dbo_InventoryPerpetual_CT]
where __$start_lsn >= @from_lsn
and __$start_lsn <= @to_lsn
*/
--if @@ERROR = 0
--	commit transaction
--else
--	rollback transaction
	
return
GO
