USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoiceDetails_Shrink_Settlement_Final_Update]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prInvoiceDetails_Shrink_Settlement_Final_Update]
as
/*
20120314 Updates below for FogBugz case 12876 by C&M
*/

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 41721

begin try

begin transaction

--***********************Create Memory Working Table**************************
select InvoiceDetailID, ChainID, SupplierID, StoreID, ProductID, BrandID, 
InventorySettlementID, TotalQty, CAST('1/1/1900' as date) as SettleDate, 
CAST(0 as money) as SupplierShrinkRatio, CAST(0 as money) as RetailerShrinkRatio,
CAST(0 as money) as FinalInvoiceUnitCost, CAST(0 as money) as FinalInvoiceUnitPromo,
CAST(0 as money) as FinalInvoiceTotalCost, CAST(0 as money) as FinalInvoiceQty,
CAST('' as nvarchar(50)) as SettlementCostRule
into #tempsettlement
from invoicedetails 
where Invoicedetailtypeid in (3, 9)
and InventorySettlementID is not null
and FinalInvoiceTotalCost is null

--*****************Get Shared Shrink Ratios***********************
update t set t.SupplierShrinkRatio = cast(v.SupplierShrinkRatio as money)
,t.RetailerShrinkRatio = cast(v.RetailerShrinkRatio as money)
from #tempsettlement t
inner join dbo.SharedShrinkValues v
on t.ChainID = v.ChainID
and t.SupplierID = v.SupplierID
--left join dbo.SharedShrinkValueExceptions e
--on v.SharedShrinkID = e.SharedShrinkID
--and t.ProductID

--****************Update SetlementCostRule************************
update t set t.SettlementCostRule = s.InventoryUnitCostRule
from #tempsettlement t
inner join dbo.InventoryRulesTimesBySupplierID s
on t.ChainID = s.ChainID
and t.SupplierID = s.SupplierID

--****************Update Settlement Date***************************

update t set t.SettleDate = r.PhysicalInventoryDate
from #tempsettlement t
inner join InventorySettlementRequests r
on t.InventorySettlementID = r.InventorySettlementRequestID

--**********************FIFO Cost Update***********************************
update t set t.FinalInvoiceUnitCost = d.UnitCost, 
t.FinalInvoiceUnitPromo = ISNULL(d.PromoAllowance, 0.0)
from #tempsettlement t
inner join dbo.InvoiceDetails d
on t.InvoiceDetailID = d.InvoiceDetailID
and upper(ltrim(rtrim(t.SettlementCostRule))) = 'FIFO'

--*******************Settlement Date Cost and Promo Lookup******************
update t set t.FinalInvoiceUnitCost = st.RuleCost, 
t.FinalInvoiceUnitPromo = ISNULL(PromoAllowance, 0.0)
--select *
from #tempsettlement t
inner join StoreTransactions st
on t.ChainID = st.ChainID
and t.StoreID = st.StoreID
and t.ProductID = st.ProductID
and t.SupplierID = st.SupplierID
and CAST(t.SettleDate as date) = CAST(st.saledatetime as date)
and st.TransactionTypeID = 11
and upper(ltrim(rtrim(t.SettlementCostRule))) = 'SETTLEMENTDATECOST'

/*20120314 Commented out promo lookup for Fogbugz Case 12876 by C&M
--***************Auxillary Promo Lookup**************************

update t set t.FinalInvoiceUnitPromo = p.UnitPrice
from #tempsettlement t
inner join [dbo].[ProductPrices] p
on t.ProductID = p.ProductID 
and t.BrandID = p.BrandID
and t.ChainID = p.ChainID 
and t.StoreID = p.StoreID 
and t.SupplierID = p.SupplierID 
where p.ProductPriceTypeID in 
(8)
and t.SettleDate between p.ActiveStartDate and p.ActiveLastDate
and t.FinalInvoiceUnitCost is null
and upper(ltrim(rtrim(t.SettlementCostRule))) = 'SETTLEMENTDATECOST'
*/

--***************Auxillary Cost Lookup Start**************************

update t set t.FinalInvoiceUnitCost = p.UnitPrice
--select t.*
from #tempsettlement t
inner join [dbo].[ProductPrices] p
on t.ProductID = p.ProductID 
and t.BrandID = p.BrandID
and t.ChainID = p.ChainID 
and t.StoreID = p.StoreID 
and t.SupplierID = p.SupplierID 
where 1 = 1
and p.ProductPriceTypeID = 3 
and t.SettleDate between p.ActiveStartDate and p.ActiveLastDate	
--and t.FinalInvoiceUnitCost is null
and upper(ltrim(rtrim(t.SettlementCostRule))) = 'SETTLEMENTDATECOST'


update #tempsettlement
set FinalInvoiceQty =
case when cast(TotalQty as money) * isnull(RetailerShrinkRatio,1) % 1 = 0 then cast(TotalQty as money) * isnull(RetailerShrinkRatio,1) else cast(cast(TotalQty as money) * cast(RetailerShrinkRatio as money) + 1.0000  as int) end
where TotalQty > 0

update #tempsettlement
set FinalInvoiceQty =
case when cast(TotalQty as money) * isnull(RetailerShrinkRatio,1) % 1 = 0 then cast(TotalQty as money) * isnull(RetailerShrinkRatio,1) else cast(cast(TotalQty as money) * cast(RetailerShrinkRatio as money) - 1.0000  as int) end
where TotalQty < 0

update #tempsettlement
set FinalInvoiceTotalCost = FinalInvoiceQty * FinalInvoiceUnitCost
/******************************************************************************
20120314 Replaced with line above for FogBugz case 12876 by C&M
set FinalInvoiceTotalCost = FinalInvoiceQty * (FinalInvoiceUnitCost - isnull(FinalInvoiceUnitPromo, 0.00))
*************************************************************************************/
update d set d.FinalInvoiceUnitCost = t.FinalInvoiceUnitCost
,d.FinalInvoiceUnitPromo = t.FinalInvoiceUnitPromo
,d.FinalInvoiceTotalCost = t.FinalInvoiceTotalCost
,d.FinalInvoiceQty = t.FinalInvoiceQty
from invoicedetails d
inner join #tempsettlement t
on d.InvoiceDetailID = t.InvoiceDetailID


	commit transaction
	
end try
	
begin catch

		rollback transaction
		
		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
end catch
GO
