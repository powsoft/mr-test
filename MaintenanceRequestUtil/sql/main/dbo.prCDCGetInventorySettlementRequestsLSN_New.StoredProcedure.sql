USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetInventorySettlementRequestsLSN_New]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetInventorySettlementRequestsLSN_New]
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

exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMinLSN_TableName 'dbo_InventorySettlementRequests',@from_lsn output
exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMaxLSN @to_lsn output--sys.fn_cdc_get_max_lsn();

--print @from_lsn

--print @to_lsn

--Archive all CDC records

/*

INSERT INTO [IC-HQSQL1INST2].[DataTrue_Archive].[dbo].[dbo_InventorySettlementRequests_CT]
           ([__$start_lsn]
           ,[__$end_lsn]
           ,[__$seqval]
           ,[__$operation]
           ,[__$update_mask]
           ,[InventorySettlementRequestID]
           ,[StoreNumber]
           ,[StoreID]
           ,[PhysicalInventoryDate]
           ,[InvoiceAmount]
           ,[Settle]
           ,[UnsettledShrink]
           ,[RequestingPersonID]
           ,[RequestDate]
           ,[ApprovingPersonID]
           ,[ApprovedDate]
           ,[supplierId]
           ,[retailerId]
           ,[DenialReason]
           ,[UPC]
           ,[ProductID]
           ,[TotalQty]
           ,[FinalInvoiceTotalCost]
           ,[SettlementFinalized]
           ,[PriorInventoryCountDate]
           ,[BI Count]
           ,[BI$]
           ,[NetDeliveries]
           ,[NetDeliveries$]
           ,[Net POS]
           ,[POS$]
           ,[Expected EI]
           ,[Expected EI$]
           ,[LastCountQty]
           ,[LastCount$]
           ,[ShrinkUits]
           ,[Shrink$]
           ,[SupplierUniqueProductID]
           ,[NetUnitCostLastCountDate]
           ,[BaseCostLastCountdate]
           ,[WeightedAvgCost]
           ,[SharedShrinkUnits]
           ,[SupplierAcctNo]
           ,[SharedShrink$]
           ,GLCode
           ,RouteNo)
SELECT [__$start_lsn]
      ,[__$end_lsn]
      ,[__$seqval]
      ,[__$operation]
      ,[__$update_mask]
      ,[InventorySettlementRequestID]
      ,[StoreNumber]
      ,[StoreID]
      ,[PhysicalInventoryDate]
      ,[InvoiceAmount]
      ,[Settle]
      ,[UnsettledShrink]
      ,[RequestingPersonID]
      ,[RequestDate]
      ,[ApprovingPersonID]
      ,[ApprovedDate]
      ,[supplierId]
      ,[retailerId]
      ,[DenialReason]
      ,[UPC]
      ,[ProductID]
      ,[TotalQty]
      ,[FinalInvoiceTotalCost]
      ,[SettlementFinalized]
      ,[PriorInventoryCountDate]
      ,[BI Count]
      ,[BI$]
      ,[Net Deliveries]
      ,[Net Deliveries$]
      ,[Net POS]
      ,[POS$]
      ,[Expected EI]
      ,[Expected EI$]
      ,[LastCountQty]
      ,[LastCount$]
      ,[ShrinkUnits]
      ,[Shrink$]
      ,[SupplierUniqueProductID]
      ,[NetUnitCostLastCountDate]
      ,[BaseCostLastCountDate]
      ,[WeightedAvgCost]
      ,[SharedShrinkUnits]
      ,[SupplierAcctNo]
      ,[SharedShrink$]
      ,GLCode
      ,RouteNo
      --select *
  FROM [IC-HQSQL1\DataTrue].DataTrue_Main.[cdc].[dbo_InventorySettlementRequests_CT]
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn


MERGE INTO [DataTrue_Report].[dbo].InventorySettlementRequests t

USING (SELECT __$operation, [InventorySettlementRequestID]
      ,[StoreNumber]
      ,[StoreID]
      ,[PhysicalInventoryDate]
      ,[InvoiceAmount]
      ,[Settle]
      ,[UnsettledShrink]
      ,[RequestingPersonID]
      ,[RequestDate]
      ,[ApprovingPersonID]
      ,[ApprovedDate]
      ,[supplierId]
      ,[retailerId]
      ,[DenialReason]
      ,[UPC]
      ,[ProductID]
      ,[TotalQty]
      ,[FinalInvoiceTotalCost]
      ,[SettlementFinalized]
      ,[PriorInventoryCountDate]
      ,[BI Count]
      ,[BI$]
      ,[Net Deliveries]
      ,[Net Deliveries$]
      ,[Net POS]
      ,[POS$]
      ,[Expected EI]
      ,[Expected EI$]
      ,[LastCountQty]
      ,[LastCount$]
      ,[ShrinkUnits]
      ,[Shrink$]
      ,[SupplierUniqueProductID]
      ,[NetUnitCostLastCountDate]
      ,[BaseCostLastCountDate]
      ,[WeightedAvgCost]
      ,[SharedShrinkUnits]
      ,[SupplierAcctNo]
      ,[SharedShrink$]
      ,GLCode
      ,RouteNo
  FROM [IC-HQSQL1\DataTrue].DataTrue_Main.[cdc].[dbo_InventorySettlementRequests_CT]
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
	and __$operation<>3
	order by __$start_lsn
		) s
		on t.[InventorySettlementRequestID] = s.[InventorySettlementRequestID]
WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
	
WHEN MATCHED THEN

update 	
   SET [StoreNumber] = s.StoreNumber
      ,[StoreID] = s.StoreID
      ,[PhysicalInventoryDate] = s.PhysicalInventoryDate
      ,[InvoiceAmount] = s.InvoiceAmount
      ,[Settle] = s.Settle
      ,[UnsettledShrink] = s.UnsettledShrink
      ,[RequestingPersonID] = s.RequestingPersonID
      ,[RequestDate] = s.RequestDate
      ,[ApprovingPersonID] = s.ApprovingPersonID
      ,[ApprovedDate] = s.ApprovedDate
      ,[supplierId] = s.supplierId
      ,[retailerId] = s.retailerId
      ,[DenialReason] = s.DenialReason
      ,[UPC] = s.UPC
      ,[ProductID] = s.ProductID
      ,[TotalQty] = s.TotalQty
      ,[FinalInvoiceTotalCost] = s.FinalInvoiceTotalCost
      ,[SettlementFinalized] = s.SettlementFinalized
      ,[PriorInventoryCountDate] = s.PriorInventoryCountDate
      ,[BI Count] = s.[BI Count]
      ,[BI$] = s.BI$
      ,[Net Deliveries] = s.[Net Deliveries]
      ,[Net Deliveries$] = s.[Net Deliveries$]
      ,[Net POS] = s.[Net POS]
      ,[POS$] = s.POS$
      ,[Expected EI] = s.[Expected EI]
      ,[Expected EI$] = s.[Expected EI$]
      ,[LastCountQty] = s.LastCountQty
      ,[LastCount$] = s.LastCount$
      ,[ShrinkUnits] = s.ShrinkUnits
      ,[Shrink$] = s.Shrink$
      ,[SupplierUniqueProductID] = s.SupplierUniqueProductID
      ,[NetUnitCostLastCountDate] = s.NetUnitCostLastCountDate
      ,[BaseCostLastCountDate] = s.BaseCostLastCountDate
    --  ,[WeightedAvgCost] = WeightedAvgCost
      ,[SharedShrinkUnits] = s.SharedShrinkUnits
      ,[SupplierAcctNo] = s.SupplierAcctNo
      ,[SharedShrink$] = s.SharedShrink$
--      ,[datetimecreated] = s.datetimecreated
		,GLCode=s.GLCode
		,RouteNo=s.RouteNo
	WHEN NOT MATCHED 

THEN INSERT 
           ([InventorySettlementRequestID],[StoreNumber]
           ,[StoreID]
           ,[PhysicalInventoryDate]
           ,[InvoiceAmount]
           ,[Settle]
           ,[UnsettledShrink]
           ,[RequestingPersonID]
           ,[RequestDate]
           ,[ApprovingPersonID]
           ,[ApprovedDate]
           ,[supplierId]
           ,[retailerId]
           ,[DenialReason]
           ,[UPC]
           ,[ProductID]
           ,[TotalQty]
           ,[FinalInvoiceTotalCost]
           ,[SettlementFinalized]
           ,[PriorInventoryCountDate]
           ,[BI Count]
           ,[BI$]
           ,[Net Deliveries]
           ,[Net Deliveries$]
           ,[Net POS]
           ,[POS$]
           ,[Expected EI]
           ,[Expected EI$]
           ,[LastCountQty]
           ,[LastCount$]
           ,[ShrinkUnits]
           ,[Shrink$]
           ,[SupplierUniqueProductID]
           ,[NetUnitCostLastCountDate]
           ,[BaseCostLastCountDate]
           ,[WeightedAvgCost]
           ,[SharedShrinkUnits]
           ,[SupplierAcctNo]
           ,[SharedShrink$]
           --,[datetimecreated]
           ,GLCode
           ,RouteNo
           )
     VALUES
           (s.[InventorySettlementRequestID],s.StoreNumber
           ,s.StoreID
           ,s.PhysicalInventoryDate
           ,s.InvoiceAmount
           ,s.Settle
           ,s.UnsettledShrink
           ,s.RequestingPersonID
           ,s.RequestDate
           ,s.ApprovingPersonID
           ,s.ApprovedDate
           ,s.supplierId
           ,s.retailerId
           ,s.DenialReason
           ,s.UPC
           ,s.ProductID
           ,s.TotalQty
           ,s.FinalInvoiceTotalCost
           ,s.SettlementFinalized
           ,s.PriorInventoryCountDate
           ,s.[BI Count]
           ,s.BI$
           ,s.[Net Deliveries]
           ,s.[Net Deliveries$]
           ,s.[Net POS]
           ,s.POS$
           ,s.[Expected EI]
           ,s.[Expected EI$]
           ,s.LastCountQty
           ,s.LastCount$
           ,s.ShrinkUnits
           ,s.Shrink$
           ,s.SupplierUniqueProductID
           ,s.NetUnitCostLastCountDate
           ,s.BaseCostLastCountDate
           ,s.WeightedAvgCost
           ,s.SharedShrinkUnits
           ,s.SupplierAcctNo
           ,s.SharedShrink$
           --,s.datetimecreated
           ,GLCode
           ,RouteNo
           );

	delete [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_InventorySettlementRequests_CT
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
		
		exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
end catch
	

return
GO
