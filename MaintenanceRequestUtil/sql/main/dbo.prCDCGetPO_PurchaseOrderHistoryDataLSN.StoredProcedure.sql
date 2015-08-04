USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetPO_PurchaseOrderHistoryDataLSN]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetPO_PurchaseOrderHistoryDataLSN]

as

declare @MyID int
declare @startlsn binary(10)
declare @endlsn binary(10)
declare @count int
declare @from_lsn binary(10)
declare @to_lsn binary(10)
/*
select * from [DataTrue_EDI].[dbo].PO_PurchaseOrderHistoryData where chainid = 44199
select * from [DataTrue_Main].[dbo].PO_PurchaseOrderHistoryData set deleteflag = 0

truncate table [DataTrue_EDI].[dbo].PO_PurchaseOrderHistoryData
*/
set @MyID = 0

begin try

begin transaction



SET @from_lsn = sys.fn_cdc_get_min_lsn(N'dbo_PO_PurchaseOrderHistoryData');
SET @to_lsn = sys.fn_cdc_get_max_lsn();

if @from_lsn is not null and @to_lsn is not null and     (@from_lsn = [sys].[fn_cdc_increment_lsn](@to_lsn)) 
    return 

--print @from_lsn

--print @to_lsn

--Archive all CDC records

--select * from [DataTrue_edi].[dbo].[PO_PurchaseOrderHistoryData]
--select * from [DataTrue_main].[dbo].[PO_PurchaseOrderHistoryData]
--select * from [DataTrue_Archive].[dbo].[dbo_PO_PurchaseOrderHistoryData_CT]
--/*

INSERT INTO [DataTrue_Archive].[dbo].[dbo_PO_PurchaseOrderHistoryData_CT]
           ([__$start_lsn]
           ,[__$end_lsn]
           ,[__$seqval]
           ,[__$operation]
           ,[__$update_mask]
           ,[RecordID]
           ,[StoreSetupId]
           ,[POGenerationDate]
           ,[SupplierId]
           ,[SupplierName]
           ,[ChainId]
           ,[ChainName]
           ,[Banner]
           ,[StoreId]
           ,[StoreIdentifier]
           ,[ProductId]
           ,[ProductName]
           ,[UPC]
           ,[LastCountDate]
           ,[LastCountTime]
           ,[LastPOSDate]
           ,[LastDeliveryDate]
           ,[LastDeliveryTime]
           ,[InventoryOnLastDelivery]
           ,[LeadTime]
           ,[DaysToDelivery]
           ,[MissingPOSDaysToDelivery]
           ,[Upcoming Delivery Date]
           ,[Upcoming Delivery Time]
           ,[DaysToNextDelivery]
           ,[Subsequent Delivery Date]
           ,[Subsequent Delivery Time]
           ,[POSUnits]
           ,[LastCountQty]
           ,[CreditUnits]
           ,[DeliveredUnits]
           ,[AvgDailySales]
           ,[QtyNeeded]
           ,[EndingInventoryOnNextDeliveryDate]
           ,[Sale Driven Reorder Qty]
           ,[Min Capacity]
           ,[Max Capacity]
           ,[PO Units]
           ,[Order Units]
           ,[Shortage Before Delivery]
           ,[Potential Shortage]
           ,[Potential Surplus]
           ,[DeleteFlag]
           ,SupplierItemNumber
           ,RawStoreIdentifier
           ,Route
           ,DateTimeCreated)
SELECT [__$start_lsn]
      ,[__$end_lsn]
      ,[__$seqval]
      ,[__$operation]
      ,[__$update_mask]
      ,[RecordID]
      ,[StoreSetupId]
      ,[POGenerationDate]
      ,[SupplierId]
      ,[SupplierName]
      ,[ChainId]
      ,[ChainName]
      ,[Banner]
      ,[StoreId]
      ,[StoreIdentifier]
      ,[ProductId]
      ,[ProductName]
      ,[UPC]
      ,[LastCountDate]
      ,[LastCountTime]
      ,[LastPOSDate]
      ,[LastDeliveryDate]
      ,[LastDeliveryTime]
      ,[InventoryOnLastDelivery]
      ,[LeadTime]
      ,[DaysToDelivery]
      ,[MissingPOSDaysToDelivery]
      ,[Upcoming Delivery Date]
      ,[Upcoming Delivery Time]
      ,[DaysToNextDelivery]
      ,[Subsequent Delivery Date]
      ,[Subsequent Delivery Time]
      ,[POSUnits]
      ,[LastCountQty]
      ,[CreditUnits]
      ,[DeliveredUnits]
      ,[AvgDailySales]
      ,[QtyNeeded]
      ,[EndingInventoryOnNextDeliveryDate]
      ,[Sale Driven Reorder Qty]
      ,[Min Capacity]
      ,[Max Capacity]
      ,[PO Units]
      ,[Order Units]
      ,[Shortage Before Delivery]
      ,[Potential Shortage]
      ,[Potential Surplus]
      ,[DeleteFlag]
      ,SupplierItemNumber
       ,RawStoreIdentifier
       ,Route
       ,DateTimeCreated
  FROM [DataTrue_Main].[cdc].[dbo_PO_PurchaseOrderHistoryData_CT]
  where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
--*/

MERGE INTO [DataTrue_EDI].[dbo].PO_PurchaseOrderHistoryData t

USING (SELECT 
      [__$operation]
      ,[RecordID]
      ,[StoreSetupId]
      ,[POGenerationDate]
      ,[SupplierId]
      ,[SupplierName]
      ,[ChainId]
      ,[ChainName]
      ,[Banner]
      ,[StoreId]
      ,[StoreIdentifier]
      ,[ProductId]
      ,[ProductName]
      ,[UPC]
      ,[LastCountDate]
      ,[LastCountTime]
      ,[LastPOSDate]
      ,[LastDeliveryDate]
      ,[LastDeliveryTime]
      ,[InventoryOnLastDelivery]
      ,[LeadTime]
      ,[DaysToDelivery]
      ,[MissingPOSDaysToDelivery]
      ,[Upcoming Delivery Date]
      ,[Upcoming Delivery Time]
      ,[DaysToNextDelivery]
      ,[Subsequent Delivery Date]
      ,[Subsequent Delivery Time]
      ,[POSUnits]
      ,[LastCountQty]
      ,[CreditUnits]
      ,[DeliveredUnits]
      ,[AvgDailySales]
      ,[QtyNeeded]
      ,[EndingInventoryOnNextDeliveryDate]
      ,[Sale Driven Reorder Qty]
      ,[Min Capacity]
      ,[Max Capacity]
      ,[PO Units]
      ,[Order Units]
      ,[Shortage Before Delivery]
      ,[Potential Shortage]
      ,[Potential Surplus]
      ,[DeleteFlag]
      ,[Route] as RouteNo
      ,[SupplierItemNumber]
      ,[RawStoreIdentifier] as RawStoreNo
      ,DateTimeCreated   
      	FROM cdc.fn_cdc_get_net_changes_dbo_PO_PurchaseOrderHistoryData(@from_lsn, @to_lsn, 'all')
		where 1 = 1
		) s
		on t.[RecordID] = s.[RecordID]
		
WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
	
WHEN MATCHED THEN

   UPDATE 
   SET [StoreSetupId] = s.StoreSetupId
      ,[POGenerationDate] = s.POGenerationDate
      ,[SupplierId] = s.SupplierId
      ,[SupplierName] = s.SupplierName
      ,[ChainId] = s.ChainId
      ,[ChainName] = s.ChainName
      ,[Banner] = s.Banner
      ,[StoreId] = s.StoreId
      ,[StoreIdentifier] = s.StoreIdentifier
      ,[ProductId] = s.ProductId
      ,[ProductName] = s.ProductName
      ,[UPC] = s.UPC
      ,[LastCountDate] = s.LastCountDate
      ,[LastCountTime] = s.LastCountTime
      ,[LastPOSDate] = s.LastPOSDate
      ,[LastDeliveryDate] = s.LastDeliveryDate
      ,[LastDeliveryTime] = s.LastDeliveryTime
      ,[InventoryOnLastDelivery] = s.InventoryOnLastDelivery
      ,[LeadTime] = s.LeadTime
      ,[DaysToDelivery] = s.DaysToDelivery
      ,[MissingPOSDaysToDelivery] = s.[MissingPOSDaysToDelivery]
      ,[Upcoming Delivery Date] = s.[Upcoming Delivery Date]
      ,[Upcoming Delivery Time] = s.[Upcoming Delivery Time]
      ,[DaysToNextDelivery] = s.[DaysToNextDelivery]
      ,[Subsequent Delivery Date] = s.[Subsequent Delivery Date]
      ,[Subsequent Delivery Time] = s.[Subsequent Delivery Time]
      ,[POSUnits] = s.POSUnits
      ,[LastCountQty] = s.LastCountQty
      ,[CreditUnits] = s.CreditUnits
      ,[DeliveredUnits] = s.DeliveredUnits
      ,[AvgDailySales] = s.AvgDailySales
      ,[QtyNeeded] = s.QtyNeeded
      ,[EndingInventoryOnNextDeliveryDate] = s.[EndingInventoryOnNextDeliveryDate]
      ,[Sale Driven Reorder Qty] = s.[Sale Driven Reorder Qty]
      ,[Min Capacity] = s.[Min Capacity]
      ,[Max Capacity] = s.[Max Capacity]
      ,[PO Units] = s.[PO Units]
      ,[Order Units] = s.[Order Units]
      ,[Shortage Before Delivery] = s.[Shortage Before Delivery]
      ,[Potential Shortage] = s.[Potential Shortage]
      ,[Potential Surplus] = s.[Potential Surplus]
      ,[DeleteFlag] = s.DeleteFlag
      ,[RouteNo] = s.RouteNo
      ,[SupplierItemNumber] = s.SupplierItemNumber
      ,[RawStoreNo] = s.RawStoreNo
      ,DateTimeCreated=s.DateTimeCreated
WHEN NOT MATCHED 

THEN INSERT 
           ([recordID]
           ,[StoreSetupId]
           ,[POGenerationDate]
           ,[SupplierId]
           ,[SupplierName]
           ,[ChainId]
           ,[ChainName]
           ,[Banner]
           ,[StoreId]
           ,[StoreIdentifier]
           ,[ProductId]
           ,[ProductName]
           ,[UPC]
           ,[LastCountDate]
           ,[LastCountTime]
           ,[LastPOSDate]
           ,[LastDeliveryDate]
           ,[LastDeliveryTime]
           ,[InventoryOnLastDelivery]
           ,[LeadTime]
           ,[DaysToDelivery]
           ,[MissingPOSDaysToDelivery]
           ,[Upcoming Delivery Date]
           ,[Upcoming Delivery Time]
           ,[DaysToNextDelivery]
           ,[Subsequent Delivery Date]
           ,[Subsequent Delivery Time]
           ,[POSUnits]
           ,[LastCountQty]
           ,[CreditUnits]
           ,[DeliveredUnits]
           ,[AvgDailySales]
           ,[QtyNeeded]
           ,[EndingInventoryOnNextDeliveryDate]
           ,[Sale Driven Reorder Qty]
           ,[Min Capacity]
           ,[Max Capacity]
           ,[PO Units]
           ,[Order Units]
           ,[Shortage Before Delivery]
           ,[Potential Shortage]
           ,[Potential Surplus]
           ,[DeleteFlag]
			,[RouteNo]
           ,[SupplierItemNumber]
           ,[RawStoreNo]
           ,DateTimeCreated
           )
     VALUES
           ( s.[RecordID]
      ,s.[StoreSetupId]
      ,s.[POGenerationDate]
      ,s.[SupplierId]
      ,s.[SupplierName]
      ,s.[ChainId]
      ,s.[ChainName]
      ,s.[Banner]
      ,s.[StoreId]
      ,s.[StoreIdentifier]
      ,s.[ProductId]
      ,s.[ProductName]
      ,s.[UPC]
      ,s.[LastCountDate]
      ,s.[LastCountTime]
      ,s.[LastPOSDate]
      ,s.[LastDeliveryDate]
      ,s.[LastDeliveryTime]
      ,s.[InventoryOnLastDelivery]
      ,s.[LeadTime]
      ,s.[DaysToDelivery]
      ,s.[MissingPOSDaysToDelivery]
      ,s.[Upcoming Delivery Date]
      ,s.[Upcoming Delivery Time]
      ,s.[DaysToNextDelivery]
      ,s.[Subsequent Delivery Date]
      ,s.[Subsequent Delivery Time]
      ,s.[POSUnits]
      ,s.[LastCountQty]
      ,s.[CreditUnits]
      ,s.[DeliveredUnits]
      ,s.[AvgDailySales]
      ,s.[QtyNeeded]
      ,s.[EndingInventoryOnNextDeliveryDate]
      ,s.[Sale Driven Reorder Qty]
      ,s.[Min Capacity]
      ,s.[Max Capacity]
      ,s.[PO Units]
      ,s.[Order Units]
      ,s.[Shortage Before Delivery]
      ,s.[Potential Shortage]
      ,s.[Potential Surplus]
      ,s.[DeleteFlag]
      ,s.[RouteNo]
      ,s.[SupplierItemNumber]
      ,s.[RawStoreNo]
      ,s.DateTimeCreated
	);

	delete cdc.dbo_PO_PurchaseOrderHistoryData_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn

/*
INSERT INTO [DataTrue_EDI].[dbo].[PO_PurchaseOrderHistoryData]
           ([RecordID]
           ,[StoreSetupId]
           ,[POGenerationDate]
           ,[SupplierId]
           ,[SupplierName]
           ,[ChainId]
           ,[ChainName]
           ,[Banner]
           ,[StoreId]
           ,[StoreIdentifier]
           ,[ProductId]
           ,[ProductName]
           ,[UPC]
           ,[LastCountDate]
           ,[LastCountTime]
           ,[LastPOSDate]
           ,[LastDeliveryDate]
           ,[LastDeliveryTime]
           ,[InventoryOnLastDelivery]
           ,[LeadTime]
           ,[DaysToDelivery]
           ,[MissingPOSDaysToDelivery]
           ,[Upcoming Delivery Date]
           ,[Upcoming Delivery Time]
           ,[DaysToNextDelivery]
           ,[Subsequent Delivery Date]
           ,[Subsequent Delivery Time]
           ,[POSUnits]
           ,[LastCountQty]
           ,[CreditUnits]
           ,[DeliveredUnits]
           ,[AvgDailySales]
           ,[QtyNeeded]
           ,[EndingInventoryOnNextDeliveryDate]
           ,[Sale Driven Reorder Qty]
           ,[Min Capacity]
           ,[Max Capacity]
           ,[PO Units]
           ,[Order Units]
           ,[Shortage Before Delivery]
           ,[Potential Shortage]
           ,[Potential Surplus]
           ,[DeleteFlag]
           ,[SupplierItemNumber]
           ,[RawStoreNo]
           ,[RouteNo]
           ,[DateTimeCreated])
SELECT [RecordID]
      ,[StoreSetupId]
      ,[POGenerationDate]
      ,[SupplierId]
      ,[SupplierName]
      ,[ChainId]
      ,[ChainName]
      ,[Banner]
      ,[StoreId]
      ,[StoreIdentifier]
      ,[ProductId]
      ,[ProductName]
      ,[UPC]
      ,[LastCountDate]
      ,[LastCountTime]
      ,[LastPOSDate]
      ,[LastDeliveryDate]
      ,[LastDeliveryTime]
      ,[InventoryOnLastDelivery]
      ,[LeadTime]
      ,[DaysToDelivery]
      ,[MissingPOSDaysToDelivery]
      ,[Upcoming Delivery Date]
      ,[Upcoming Delivery Time]
      ,[DaysToNextDelivery]
      ,[Subsequent Delivery Date]
      ,[Subsequent Delivery Time]
      ,[POSUnits]
      ,[LastCountQty]
      ,[CreditUnits]
      ,[DeliveredUnits]
      ,[AvgDailySales]
      ,[QtyNeeded]
      ,[EndingInventoryOnNextDeliveryDate]
      ,[Sale Driven Reorder Qty]
      ,[Min Capacity]
      ,[Max Capacity]
      ,[PO Units]
      ,[Order Units]
      ,[Shortage Before Delivery]
      ,[Potential Shortage]
      ,[Potential Surplus]
      ,[DeleteFlag]
      ,[SupplierItemNumber]
      ,[RawStoreIdentifier]
      ,[Route]
      ,[DateTimeCreated]
  FROM [DataTrue_Main].[dbo].[PO_PurchaseOrderHistoryData] h
where 1 = 1
and recordid not in (select recordid from [DataTrue_EDI].[dbo].[PO_PurchaseOrderHistoryData])
*/

begin try
INSERT INTO [DataTrue_EDI].[dbo].[ProcessStatus]
           ([ChainName]
           ,[Date]
           ,[AllFilesReceived]
           ,[BillingComplete]
           ,[BillingIsRunning])
     VALUES
           ('ACK' --<ChainName, nchar(10),>
           ,CAST(getdate() as DATE) --<Date, date,>
           ,1 --<AllFilesReceived, tinyint,>
           ,1 --<BillingComplete, tinyint,>
           ,1) --<BillingIsRunning, tinyint,>)
     end try
     begin catch
     end catch
	
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
		print @errormessage
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
end catch
	

return
GO
