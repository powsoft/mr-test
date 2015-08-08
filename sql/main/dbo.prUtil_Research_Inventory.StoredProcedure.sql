USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Research_Inventory]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Research_Inventory]
as


select distinct activitycode from datatrue_edi.dbo.X12_SuppliersDeliveriesAndInventories
select * from datatrue_edi.dbo.X12_SuppliersDeliveriesAndInventories where activitycode = 'QA'


select * 
--update t set RuleCost = SetupCost, RuleRetail = 0.00, TrueCost = SetupCost, TrueRetail = 0.00, CostMisMatch = 0, RetailMisMatch = 0
from StoreTransactions t
where TransactionTypeID in (5,8)
--and SaleDateTime >= '11/30/2011'
and DateTimeCreated > '12/22/2011'
and SetupCost is not null
order by DateTimeCreated desc

select distinct inventorycostmethod from storesetup where ChainID = 40393

select * from productidentifiers where identifiervalue = '007294560198'

select upc 
from StoreTransactions_Working w
where WorkingStatus = 1

select upc 
from StoreTransactions_Working w
inner join productidentifiers p
on LTRIM(rtrim(w.upc)) = LTRIM(rtrim(p.identifiervalue))
where WorkingStatus = 1





select *
from InventoryPerpetual
where ChainID = 40393
and Deliveries > 0

select *
from datatrue_report.dbo.InventoryPerpetual
where ChainID = 40393
and Deliveries > 0

select * from StoreTransactions where StoreID = 40427 and ProductID = 5027
select * from StoreTransactions where StoreID = 40427 and ProductID = 5031
select * from StoreTransactions where StoreID = 40427 and ProductID = 5035
select * from StoreTransactions where StoreID = 40427 and ProductID = 15524

declare @rec cursor
declare @recordid int
declare @storeid int
declare @productid int
declare @onhand int
declare @saleqty int

set @rec = CURSOR local fast_forward FOR
select RecordID, StoreID, ProductID, currentonhandqty
from InventoryPerpetual
where ChainID = 40393
and Deliveries > 0

open @rec

fetch next from @rec into
	@recordid
	,@storeid
	,@productid
	,@onhand
	
while @@FETCH_STATUS = 0
	begin
		select @saleqty = SUM(qty)
		from StoreTransactions
		where CAST(saledatetime as date) >= '12/1/2011'
		and StoreID = @storeid
		and ProductID = @productid
		
		update InventoryPerpetual set CurrentOnHandQty = CurrentOnHandQty - @saleqty, SBTSales = @saleqty
		where recordid = @recordid
	
		fetch next from @rec into
			@recordid
			,@storeid
			,@productid
			,@onhand	
	end
	
close @rec
deallocate @rec




exec prGetInbound846Inventory
exec prValidateStoresInStoreTransactions_Working_INV
exec prValidateProductsInStoreTransactions_Working_INV
exec prValidateSuppliersInStoreTransactions_Working_INV
exec prValidateSourceInStoreTransactions_Working_INV
exec prValidateTransactionTypeInStoreTransactions_Working_INV
exec prApplyINVStoreTransactionsToInventory
exec prApplyINVStoreTransactionsToInventoryCost --************************************************************************
--*************For Initial Count Zero Shrink Revision**************************
exec prProcessShrink_Initial
--*************For Non-Initial Count Apply Shrink Revision**************************
exec prProcessShrink
--*************For Non-Initial Count Apply Shrink Revision**************************
exec prInventory_WAVG_ProcessTransactions
exec prInventory_FIFO_ProcessTransactions

exec prCDCGetStoreTransactionsLSN
exec prCDCGetInventoryPerpetualUpdatesLSN
--*************Supplier Store Transactions Import*************************
--update DataTrue_EDI..InBoundSuppliers set RecordStatus = 0 where RecordID in (1,2,3)
--update storetransactions set InventoryCost = null where storetransactionid = 499221
--*****************Views*************************
exec prUtil_GetInventoryCostView 7608
exec prUtil_GetInventoryPerpetualView 7608
exec prUtil_GetStoreTransactionView 7608
exec prUtil_GetInvoiceDetailsView 7608
exec prUtil_GetInvoiceHeaderView 7608
--***********************************************

exec prGetInboundSUPTransactions
exec prValidateStoresInStoreTransactions_Working_SUP
exec prValidateProductsInStoreTransactions_Working_SUP
exec prValidateSuppliersInStoreTransactions_Working_SUP
exec prValidateSourceInStoreTransactions_Working_SUP
exec prValidateTransactionTypeInStoreTransactions_Working_SUP
exec prProcessSUPDeliveriesForShrinkReversal
exec prProcessSUPPickupsForShrinkReversal
exec prApplySUPStoreTransactionsToInventoryCost--************************************************************************
select top 2000000 * from inventorycost order by DateTimeCreated desc
select * from InventoryPerpetual where chainid = 40393 and deliveries <> 0 order by DateTimeCreated desc
select * from StoreTransactions where SupplierID = 41465 and TransactionTypeID in (2,6,7,16)

exec prInventory_WAVG_ProcessTransactions
exec prInventory_FIFO_ProcessTransactions
exec prApplySUPStoreTransactionsToInventory
exec prApplyShrinkReversalToInventory

exec prCDCGetStoreTransactionsLSN
exec prCDCGetInventoryPerpetualUpdatesLSN
--*************POS Transactions*******************************
--update DataTrue_EDI..Inbound852Sales set Recordstatus = 0 where chainname = 'RA'
--select * from DataTrue_EDI..Inbound852Sales where Recordstatus = 0
--*****************Views*************************
exec prUtil_GetInventoryCostView 40393
exec prUtil_GetInventoryPerpetualView 40393
exec prUtil_GetStoreTransactionView 7608
exec prUtil_GetInvoiceDetailsView 7608
exec prUtil_GetInvoiceHeaderView 7608
--***********************************************

exec prGetInboundPOSTransactions
exec prValidateStoresInStoreTransactions_Working
exec prValidateProductsInStoreTransactions_Working
exec prValidateSuppliersInStoreTransactions_Working
exec prValidateSourceInStoreTransactions_Working
exec prValidateTransactionTypeInStoreTransactions_Working
exec prProcessPOSForShrinkReversal
exec prInventory_WAVG_ProcessTransactions
exec prInventory_FIFO_ProcessTransactions
exec prApplyPOSStoreTransactionsToInventory
exec prApplyShrinkReversalToInventory

exec prCDCGetStoreTransactionsLSN
exec prCDCGetInventoryPerpetualUpdatesLSN
return
GO
