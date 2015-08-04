USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoiceDetails_Shrink_PercentRange_Settlements_Final_Update_STOREUPC]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prInvoiceDetails_Shrink_PercentRange_Settlements_Final_Update_STOREUPC]
as
/*
20120314 Updates below for FogBugz case 12876 by C&M

select r.*, d.*
from invoicedetails d
inner join InventorySettlementRequests r
on d.InventorySettlementID = r.InventorySettlementRequestID
where InventorySettlementID is not null

update d set d.FinalInvoiceUnitCost = null
,d.FinalInvoiceUnitPromo = null
,d.FinalInvoiceTotalCost = null
,d.FinalInvoiceQty = null
--select * --into import.dbo.STOREUPC_TEST_INOICEDETAILS_20120403
--select sum(FinalInvoiceQty), sum(FinalInvoiceTotalCost)
from invoicedetails d
where d.FinalInvoiceTotalCost is not null
*/

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 41721

begin try

begin transaction
--select * into import.dbo.SettlementRequestSchmit_20120327 from #tempsettlement
--***********************Create Memory Working Table*******drop table #tempsettlement*******************
select InvoiceDetailID, ChainID, id.SupplierID, id.StoreID, id.ProductID, id.BrandID, 
InventorySettlementID, id.TotalQty, TotalCost, PhysicalInventoryDate as CurrentSettleDate, 
CAST('1/1/1900' as date) as LastSettleDate,
CAST(0 as money) as SupplierShrinkRatio, CAST(0 as money) as RetailerShrinkRatio,
CAST(0 as money) as FinalInvoiceUnitCost, CAST(0 as money) as FinalInvoiceUnitPromo,
CAST(0 as money) as FinalInvoiceTotalCost, CAST(0 as money) as FinalInvoiceQty,
CAST('' as nvarchar(50)) as SettlementCostRule, CAST('' as nvarchar(50)) as ShrinkPercentRangeAggregationMethod
,CAST(null as int) as DetailAdjustmentQty, CAST(0 as bit) as DetailAdjustmentQtyApplied
into #tempsettlement
from invoicedetails id
inner join InventorySettlementRequests sr 
on id.InventorySettlementID = sr.InventorySettlementRequestID
and Invoicedetailtypeid in (3, 9)
and InventorySettlementID is not null
and sr.SettlementFinalized = 0
and UPPER(sr.Settle) = 'Y'
--and sr.supplierId = 40561

--****************Update Last SettleDate************select * from #tempsettlement order by LastSettleDate*********update #tempsettlement set LastSettleDate = '12/01/2011'******
update t set t.LastSettleDate = s.LastSettleDate
--select *
from #tempsettlement t
inner join 
(select storeid, ProductId, MAX(PhysicalInventoryDate) As LastSettleDate
from InventorySettlementRequests
where upper(Settle) = 'Y'
and SettlementFinalized = 1
group by storeid, ProductId) s
on t.StoreID = s.StoreID
and t.ProductID = s.ProductID

--******************Update AggregationMethod********************

update t set t.ShrinkPercentRangeAggregationMethod = s.ShrinkPercentRangeAggregationMethod
--select t.ShrinkPercentRangeAggregationMethod, s.ShrinkPercentRangeAggregationMethod, *
from #tempsettlement t
inner join dbo.SharedShrinkValues s
on t.ChainID = s.ChainID
and t.SupplierID = s.SupplierID

--*****************STOREUPC Aggregation**********drop table #tempstoreupc*****************
select chainid, storeid, ProductId, Supplierid, SUM(TotalQty) as TotalShrinkQty, 
SUM(TotalCost) as TotalShrinkCost, 
SUM(TotalCost)/case when SUM(TotalQty) = 0 then 1 else SUM(TotalQty) end as ShrinkUnitCost,
max(CurrentSettleDate) as CurrentSettlementDate, LastSettleDate, 
CAST(0 as int) as POSQtySinceLastSettlmentDate, CAST(0 as money) as ShrinkUnitsDIVPOSUnits,
CAST(0 as money) as MaximumPercentToInvoice, cast(0 as money) as MaximumQtyToInvoice,
CAST(0 as money) as RetailerSharePercent,
Cast(0 as money) as ShrinkPercentToInvoice, Cast(0 as money) as ShrinkQtyToInvoice,
upper(ShrinkPercentRangeAggregationMethod) as ShrinkPercentRangeAggregationMethod,
CAST(0 as int) as AdjustmentQty
into #tempstoreupc
from #tempsettlement
where upper(ShrinkPercentRangeAggregationMethod) = 'STOREUPC'
group by chainid, storeid, ProductId, Supplierid, LastSettleDate, ShrinkPercentRangeAggregationMethod


--*****************Get POS Units Between Settlement Dates*********
--STOREUPC
update #tempstoreupc
set POSQtySinceLastSettlmentDate =  (select SUM(isnull(totalqty, 0))
from invoicedetails id
where InvoiceDetailTypeID in (1,7)
and id.StoreID = #tempstoreupc.StoreID
and id.ProductID = #tempstoreupc.ProductID
and id.SaleDate between #tempstoreupc.LastSettleDate and dateadd(day, -1, #tempstoreupc.CurrentSettlementDate))

--*****************Update ShrinkUnitsDIVPOSUnits*********select * from #tempstoreupc order by ShrinkUnitsDIVPOSUnits**********
--STOREUPC
update #tempstoreupc
--update import.dbo.tempstoreupcfortesting
set ShrinkUnitsDIVPOSUnits = abs(TotalShrinkQty/case when cast(isnull(POSQtySinceLastSettlmentDate, 0) AS money) = 0 then 1 else cast(POSQtySinceLastSettlmentDate AS money) end )


--*****************Get Shared Shrink Ratios***********************
--STOREUPC
update t set t.RetailerSharePercent = v.RetailerShrinkRatio,
t.MaximumPercentToInvoice = v.ToShrinkUnitsDIVPOSUnits,
t.MaximumQtyToInvoice = v.ToShrinkUnitsDIVPOSUnits * t.POSQtySinceLastSettlmentDate
from #tempstoreupc t
--from import.dbo.tempstoreupcfortesting t
inner join dbo.SharedShrinkValues v
on t.ChainID = v.ChainID
and t.SupplierID = v.SupplierID
and t.CurrentSettlementDate between v.ActiveStartDate and v.ActiveLastDate
and v.FromShrinkUnitsDIVPOSUnits = 0
and t.ShrinkPercentRangeAggregationMethod = UPPER(v.ShrinkPercentRangeAggregationMethod)
and t.TotalShrinkQty <> 0

--*****************Update All Ratios***********************
--STOREUPC
update t set 
t.ShrinkPercentToInvoice = case when t.MaximumPercentToInvoice/t.ShrinkUnitsDIVPOSUnits >= 1 then v.RetailerShrinkRatio else abs(t.MaximumPercentToInvoice/t.ShrinkUnitsDIVPOSUnits*v.RetailerShrinkRatio) end,
t.ShrinkQtyToInvoice = TotalShrinkQty * case when t.MaximumPercentToInvoice/t.ShrinkUnitsDIVPOSUnits >= 1 then v.RetailerShrinkRatio else abs(t.MaximumPercentToInvoice/t.ShrinkUnitsDIVPOSUnits*v.RetailerShrinkRatio) end
from #tempstoreupc t
--from import.dbo.tempstoreupcfortesting t
inner join dbo.SharedShrinkValues v
on t.ChainID = v.ChainID
and t.SupplierID = v.SupplierID
and t.CurrentSettlementDate between v.ActiveStartDate and v.ActiveLastDate
and v.FromShrinkUnitsDIVPOSUnits = 0
and t.ShrinkPercentRangeAggregationMethod = UPPER(v.ShrinkPercentRangeAggregationMethod)
and t.TotalShrinkQty <> 0

--********************************Round******************select * from #tempstoreupc*******************
--STOREUPC
update #tempstoreupc
--update import.dbo.tempstoreupcfortesting
set ShrinkQtyToInvoice = Round(ShrinkQtyToInvoice, 0)


--*********************Update Settlement FinalInvoiceQty***************************
--STOREUPC
update s set s.FinalInvoiceQty = Round(s.TotalQty * t.ShrinkPercentToInvoice, 0) 
from #tempsettlement s
inner join #tempstoreupc t
on s.StoreID = t.StoreID
and s.ProductID = t.productid
--**********************Update AdjustmentQty****************************
--STOREUPC
update a set a.AdjustmentQty = a.ShrinkQtyToInvoice - d.FinalInvoiceQtySum
--select *
from #tempstoreupc a
inner join 
(
select storeid, ProductId, SUM(FinalInvoiceQty) as FinalInvoiceQtySum
from #tempsettlement s
group by storeid, productid) d
on a.storeid = d.storeid
and a.productid = d.productid

--***********************Clean Up Overages******************drop table #tempmaxFinalInvoiceQty**********************
declare @allquantitiesok bit
declare @countholder int

set @allquantitiesok = 0

While @allquantitiesok = 0
	begin
--STOREUPC
		select a.storeid as Maxstoreid, 
		a.ProductId as Maxproductid,
		a.AdjustmentQty, 
		d.LimitQty, CAST(0 as int) as LimitQtyInvoiceDetailID
		into #tempmaxFinalInvoiceQty
		from #tempstoreupc a
		--from import.dbo.tempstoreupcfortesting a
		inner join 
		(
		select storeid, ProductId, case when sum(TotalQty) > 0 then MAX(TotalQty) else Min(TotalQty) end as LimitQty
		from #tempsettlement s
		--from import.dbo.tempsettlementfortesting
		where DetailadjustmentQtyApplied = 0
		group by storeid, productid) d
		on a.storeid = d.storeid
		and a.productid = d.productid
		and a.AdjustmentQty <> 0		
--STOREUPC
		update t set LimitQtyInvoiceDetailID = s.InvoicedetailID
		--select *
		from  #tempmaxFinalInvoiceQty t
		inner join #tempsettlement s
		--from import.dbo.tempsettlementfortesting s
		on s.storeid = Maxstoreid
		and s.productid = Maxproductid
		and s.TotalQty = LimitQty
		and DetailadjustmentQtyApplied = 0
--STOREUPC
		update s set FinalInvoiceQty = s.FinalInvoiceQty + t.AdjustmentQty
		,s.DetailAdjustmentQty =  t.AdjustmentQty 
		--select *
		from #tempmaxFinalInvoiceQty t
		inner join #tempsettlement s
		on t.LimitQtyInvoiceDetailID = s.InvoicedetailID
--STOREUPC
		update A set a.AdjustmentQty = case when a.AdjustmentQty = s.DetailAdjustmentQty  then 0 else a.AdjustmentQty - s.DetailAdjustmentQty  end
		from #tempmaxFinalInvoiceQty a
		inner join #tempsettlement s
		on a.LimitQtyInvoiceDetailID = s.InvoicedetailID
		and s.DetailadjustmentQtyApplied = 0


--STOREUPC
		update #tempsettlement --s
		set DetailadjustmentQtyApplied = 1
		where DetailAdjustmentQty is not null

--STOREUPC				
		update A set a.AdjustmentQty = t.AdjustmentQty
		from #tempmaxFinalInvoiceQty t
		inner join #tempsettlement d
		on t.LimitQtyInvoiceDetailID = d.InvoicedetailID
		inner join #tempstoreupc a
		on a.storeid = d.storeid
		and a.productid = d.productid
				
		select @countholder = 
		--select 
		COUNT(ProductID)
		from #tempstoreupc
		--from import.dbo.tempstoreupcfortesting
		where AdjustmentQty <> 0
		
		If @countholder < 1
			set @allquantitiesok = 1


		drop table #tempmaxFinalInvoiceQty

	end

--****************Update SetlementCostRule***********select * from #tempstoreupc***select * from #tempsettlement order by finalinvoiceqty desc**********
update t set t.SettlementCostRule = s.InventoryUnitCostRule
from #tempsettlement t
inner join dbo.InventoryRulesTimesBySupplierID s
on t.ChainID = s.ChainID
and t.SupplierID = s.SupplierID

--**********************FIFO Cost Update******************select * from #tempsettlement*****************
update t set t.FinalInvoiceUnitCost = d.UnitCost, 
t.FinalInvoiceUnitPromo = ISNULL(d.PromoAllowance, 0.0)
from #tempsettlement t
inner join dbo.InvoiceDetails d
on t.InvoiceDetailID = d.InvoiceDetailID
and upper(ltrim(rtrim(t.SettlementCostRule))) = 'FIFO'

--*******************Settlement Date Cost and Promo Lookup******************
update t set t.FinalInvoiceUnitCost = st.RuleCost
--select *
from #tempsettlement t
inner join StoreTransactions st
on t.ChainID = st.ChainID
and t.StoreID = st.StoreID
and t.ProductID = st.ProductID
and t.SupplierID = st.SupplierID
and CAST(t.CurrentSettleDate as date) = CAST(st.saledatetime as date)
and st.TransactionTypeID = 11
and upper(ltrim(rtrim(t.SettlementCostRule))) = 'SETTLEMENTDATECOST'

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
and t.CurrentSettleDate between p.ActiveStartDate and p.ActiveLastDate	
and t.FinalInvoiceUnitCost is null
and upper(ltrim(rtrim(t.SettlementCostRule))) = 'SETTLEMENTDATECOST'


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


update sr set sr.SettlementFinalized = 1
from InventorySettlementRequests sr
inner join InvoiceDetailS d
on sr.InventorySettlementRequestID = d.InventorySettlementID
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
