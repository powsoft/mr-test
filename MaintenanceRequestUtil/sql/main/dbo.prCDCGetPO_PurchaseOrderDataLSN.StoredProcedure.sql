USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetPO_PurchaseOrderDataLSN]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetPO_PurchaseOrderDataLSN]

as

declare @MyID int
declare @startlsn binary(10)
declare @endlsn binary(10)
declare @count int
declare @from_lsn binary(10)
declare @to_lsn binary(10)

set @MyID = 0

begin try

begin transaction



SET @from_lsn = sys.fn_cdc_get_min_lsn(N'dbo_PO_PurchaseOrderData');
SET @to_lsn = sys.fn_cdc_get_max_lsn();


--print @from_lsn

--print @to_lsn

--Archive all CDC records

--select * from [DataTrue_edi].[dbo].[PO_PurchaseOrderData]
--select * from [DataTrue_main].[dbo].[PO_PurchaseOrderData]
--/*

INSERT INTO [DataTrue_Archive].[dbo].[dbo_PO_PurchaseOrderData_CT]
           ([__$start_lsn]
           ,[__$end_lsn]
           ,[__$seqval]
           ,[__$operation]
           ,[__$update_mask]
           ,[RecordID]
           ,[StoreSetupId]
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
           ,[LeadTime]
           ,[DaysToDelivery]
           ,[Upcoming Delivery Date]
           ,[Upcoming Delivery Time]
           ,[DaysToNextDelivery]
           ,[Subsequent Delivery Date]
           ,[Subsequent Delivery Time]
           ,[LastCountQty]
           ,[CreditUnits]
           ,[DeliveredUnits]
           ,[AvgDailySales]
           ,[QtyNeeded]
           ,[Inventory Availble By Next Delivery Time]
           ,[Sale Driven Reorder Qty]
           ,[Min Capacity]
           ,[Max Capacity]
           ,[PO Units]
           ,[Order Units]
           ,[Shortage Before Delivery]
           ,[Potential Shortage]
           ,[Potential Surplus]
           ,[DeleteFlag])
SELECT [__$start_lsn]
      ,[__$end_lsn]
      ,[__$seqval]
      ,[__$operation]
      ,[__$update_mask]
      ,[RecordID]
      ,[StoreSetupId]
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
      ,[LeadTime]
      ,[DaysToDelivery]
      ,[Upcoming Delivery Date]
      ,[Upcoming Delivery Time]
      ,[DaysToNextDelivery]
      ,[Subsequent Delivery Date]
      ,[Subsequent Delivery Time]
      ,[LastCountQty]
      ,[CreditUnits]
      ,[DeliveredUnits]
      ,[AvgDailySales]
      ,[QtyNeeded]
      ,[Inventory Availble By Next Delivery Time]
      ,[Sale Driven Reorder Qty]
      ,[Min Capacity]
      ,[Max Capacity]
      ,[PO Units]
      ,[Order Units]
      ,[Shortage Before Delivery]
      ,[Potential Shortage]
      ,[Potential Surplus]
      ,[DeleteFlag]
  FROM [DataTrue_Main].[cdc].[dbo_PO_PurchaseOrderData_CT]
  where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
--*/

MERGE INTO [DataTrue_EDI].[dbo].PO_PurchaseOrderData t

USING (SELECT 
      [__$operation]
      ,[RecordID]
      ,[StoreSetupId]
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
      ,[LeadTime]
      ,[DaysToDelivery]
      ,[Upcoming Delivery Date]
      ,[Upcoming Delivery Time]
      ,[DaysToNextDelivery]
      ,[Subsequent Delivery Date]
      ,[Subsequent Delivery Time]
      ,[LastCountQty]
      ,[CreditUnits]
      ,[DeliveredUnits]
      ,[AvgDailySales]
      ,[QtyNeeded]
      ,[Inventory Availble By Next Delivery Time]
      ,[Sale Driven Reorder Qty]
      ,[Min Capacity]
      ,[Max Capacity]
      ,[PO Units]
      ,[Order Units]
      ,[Shortage Before Delivery]
      ,[Potential Shortage]
      ,[Potential Surplus]
      ,[DeleteFlag]
      	FROM cdc.fn_cdc_get_net_changes_dbo_PO_PurchaseOrderData(@from_lsn, @to_lsn, 'all')
		where 1 = 1
		) s
		on t.[RecordID] = s.[RecordID]
		
WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
	
WHEN MATCHED THEN

   UPDATE 
   SET [StoreSetupId] = s.StoreSetupId
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
      ,[LeadTime] = s.LeadTime
      ,[DaysToDelivery] = s.DaysToDelivery
      ,[Upcoming Delivery Date] = s.[Upcoming Delivery Date]
      ,[Upcoming Delivery Time] = s.[Upcoming Delivery Time]
      ,[DaysToNextDelivery] = s.DaysToNextDelivery
      ,[Subsequent Delivery Date] = s.[Subsequent Delivery Date]
      ,[Subsequent Delivery Time] = s.[Subsequent Delivery Time]
      ,[LastCountQty] = s.LastCountQty
      ,[CreditUnits] = s.CreditUnits
      ,[DeliveredUnits] = s.DeliveredUnits
      ,[AvgDailySales] = s.AvgDailySales
      ,[QtyNeeded] = s.QtyNeeded
      ,[Inventory Availble By Next Delivery Time] = s.[Inventory Availble By Next Delivery Time]
      ,[Sale Driven Reorder Qty] = s.[Sale Driven Reorder Qty]
      ,[Min Capacity] = s.[Min Capacity]
      ,[Max Capacity] = s.[Max Capacity]
      ,[PO Units] = s.[PO Units]
      ,[Order Units] = s.[Order Units]
      ,[Shortage Before Delivery] = s.[Shortage Before Delivery]
      ,[Potential Shortage] = s.[Potential Shortage]
      ,[Potential Surplus] = s.[Potential Surplus]
      ,[DeleteFlag] = s.[DeleteFlag]


WHEN NOT MATCHED 

THEN INSERT 
           ([RecordID]
           ,[StoreSetupId]
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
           ,[LeadTime]
           ,[DaysToDelivery]
           ,[Upcoming Delivery Date]
           ,[Upcoming Delivery Time]
           ,[DaysToNextDelivery]
           ,[Subsequent Delivery Date]
           ,[Subsequent Delivery Time]
           ,[LastCountQty]
           ,[CreditUnits]
           ,[DeliveredUnits]
           ,[AvgDailySales]
           ,[QtyNeeded]
           ,[Inventory Availble By Next Delivery Time]
           ,[Sale Driven Reorder Qty]
           ,[Min Capacity]
           ,[Max Capacity]
           ,[PO Units]
           ,[Order Units]
           ,[Shortage Before Delivery]
           ,[Potential Shortage]
           ,[Potential Surplus]
           ,[DeleteFlag])
     VALUES
           (s.[RecordID]
           ,s.[StoreSetupId]
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
           ,s.[LeadTime]
           ,s.[DaysToDelivery]
           ,s.[Upcoming Delivery Date]
           ,s.[Upcoming Delivery Time]
           ,s.[DaysToNextDelivery]
           ,s.[Subsequent Delivery Date]
           ,s.[Subsequent Delivery Time]
           ,s.[LastCountQty]
           ,s.[CreditUnits]
           ,s.[DeliveredUnits]
           ,s.[AvgDailySales]
           ,s.[QtyNeeded]
           ,s.[Inventory Availble By Next Delivery Time]
           ,s.[Sale Driven Reorder Qty]
           ,s.[Min Capacity]
           ,s.[Max Capacity]
           ,s.[PO Units]
           ,s.[Order Units]
           ,s.[Shortage Before Delivery]
           ,s.[Potential Shortage]
           ,s.[Potential Surplus]
           ,s.[DeleteFlag]
           );

	delete cdc.dbo_PO_PurchaseOrderData_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
	
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
