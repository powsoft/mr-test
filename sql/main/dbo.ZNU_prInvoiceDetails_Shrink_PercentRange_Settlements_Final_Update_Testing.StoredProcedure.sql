USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[ZNU_prInvoiceDetails_Shrink_PercentRange_Settlements_Final_Update_Testing]    Script Date: 06/25/2015 18:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[ZNU_prInvoiceDetails_Shrink_PercentRange_Settlements_Final_Update_Testing]
as
/*
20120314 Updates below for FogBugz case 12876 by C&M

select r.*, d.*
from invoicedetails d
inner join InventorySettlementRequests r
on d.InventorySettlementID = r.InventorySettlementRequestID
where InventorySettlementID is not null
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
--and UPPER(sr.Settle) = 'Y'
and sr.supplierId = 40561

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

/*
select * from #tempstoreupc order by adjustmentqty desc
select * from #tempsettlement   where storeid = 40508	and productid = 5424
*/
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

--*****************STOREUPC Aggregation**********drop table #tempchainupc*********select * from  #tempchainupc********
select chainid, ProductId, Supplierid, SUM(TotalQty) as TotalShrinkQty, 
SUM(TotalCost) as TotalShrinkCost, 
SUM(TotalCost)/case when SUM(TotalQty) = 0 then 1 else SUM(TotalQty) end as ShrinkUnitCost,
max(CurrentSettleDate) as CurrentSettlementDate, LastSettleDate, 
CAST(0 as int) as POSQtySinceLastSettlmentDate, CAST(0 as money) as ShrinkUnitsDIVPOSUnits,
CAST(0 as money) as MaximumPercentToInvoice, cast(0 as money) as MaximumQtyToInvoice,
CAST(0 as money) as RetailerSharePercent,
Cast(0 as money) as ShrinkPercentToInvoice, Cast(0 as money) as ShrinkQtyToInvoice,
upper(ShrinkPercentRangeAggregationMethod) as ShrinkPercentRangeAggregationMethod,
CAST(0 as int) as AdjustmentQty
into #tempchainupc
from #tempsettlement
where upper(ShrinkPercentRangeAggregationMethod) = 'CHAINUPC'
group by chainid, ProductId, Supplierid, LastSettleDate, ShrinkPercentRangeAggregationMethod

/*
select * from #tempstoreupc order by adjustmentqty desc
select * from #tempsettlement   where storeid = 40508	and productid = 5424
*/
--*****************Get POS Units Between Settlement Dates*********
--STOREUPC
update #tempstoreupc
set POSQtySinceLastSettlmentDate =  (select SUM(isnull(totalqty, 0))
from invoicedetails id
where InvoiceDetailTypeID in (1,7)
and id.StoreID = #tempstoreupc.StoreID
and id.ProductID = #tempstoreupc.ProductID
and id.SaleDate between #tempstoreupc.LastSettleDate and dateadd(day, -1, #tempstoreupc.CurrentSettlementDate))

--CHAINUPC select * from  #tempchainupc order by POSQtySinceLastSettlmentDate 
update #tempchainupc
set POSQtySinceLastSettlmentDate =  (select SUM(isnull(totalqty, 0))
from invoicedetails id
where InvoiceDetailTypeID in (1,7)
and id.ProductID = #tempchainupc.ProductID
and id.SaleDate between #tempchainupc.LastSettleDate and dateadd(day, -1, #tempchainupc.CurrentSettlementDate))

update #tempchainupc
set POSQtySinceLastSettlmentDate =  0
where POSQtySinceLastSettlmentDate is null

--*****************Update ShrinkUnitsDIVPOSUnits*********select * from #tempstoreupc order by ShrinkUnitsDIVPOSUnits**********
--STOREUPC
update #tempstoreupc
--update import.dbo.tempstoreupcfortesting
set ShrinkUnitsDIVPOSUnits = abs(TotalShrinkQty/case when cast(isnull(POSQtySinceLastSettlmentDate, 0) AS money) = 0 then 1 else cast(POSQtySinceLastSettlmentDate AS money) end )

--CHAINUPC  select * from  #tempchainupc 
update #tempchainupc
--update import.dbo.tempstoreupcfortesting
set ShrinkUnitsDIVPOSUnits = abs(TotalShrinkQty/case when cast(isnull(POSQtySinceLastSettlmentDate, 0) AS money) = 0 then 1 else cast(POSQtySinceLastSettlmentDate AS money) end )

/*
select * from #tempstoreupc where storeid = 40496 and productid = 5523
select * from #tempsettlement   where storeid = 40496 and productid = 5523
*/
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

--CHAINUPC select * from  #tempchainupc 
update t set t.RetailerSharePercent = v.RetailerShrinkRatio,
t.MaximumPercentToInvoice = v.ToShrinkUnitsDIVPOSUnits,
t.MaximumQtyToInvoice = v.ToShrinkUnitsDIVPOSUnits * t.POSQtySinceLastSettlmentDate
from #tempchainupc t
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

--CHAINUPC select * from  #tempchainupc 
update t set 
t.ShrinkPercentToInvoice = case when t.MaximumPercentToInvoice/t.ShrinkUnitsDIVPOSUnits >= 1 then v.RetailerShrinkRatio else abs(t.MaximumPercentToInvoice/t.ShrinkUnitsDIVPOSUnits*v.RetailerShrinkRatio) end,
t.ShrinkQtyToInvoice = TotalShrinkQty * case when t.MaximumPercentToInvoice/t.ShrinkUnitsDIVPOSUnits >= 1 then v.RetailerShrinkRatio else abs(t.MaximumPercentToInvoice/t.ShrinkUnitsDIVPOSUnits*v.RetailerShrinkRatio) end
from #tempchainupc t
--from import.dbo.tempstoreupcfortesting t
inner join dbo.SharedShrinkValues v
on t.ChainID = v.ChainID
and t.SupplierID = v.SupplierID
and t.CurrentSettlementDate between v.ActiveStartDate and v.ActiveLastDate
and v.FromShrinkUnitsDIVPOSUnits = 0
and t.ShrinkPercentRangeAggregationMethod = UPPER(v.ShrinkPercentRangeAggregationMethod)
and t.TotalShrinkQty <> 0

/*
select * from #tempstoreupc
select * from import.dbo.tempstoreupcfortesting
select * from import.dbo.tempsettlementfortesting
*/
/*
--*****************************************Temp Queries**********************************************

select SUM(TotalQty), SUM(FinalInvoiceQty) from #tempsettlement where productid = 5426 
select * from #tempchainupc  where productid = 5426 
select * from #tempsettlement where productid = 5426
 --*****************************************Temp Queries**********************************************
 */
--********************************Round******************select * from #tempstoreupc*******************
--STOREUPC
update #tempchainupc
--update import.dbo.tempstoreupcfortesting
set ShrinkQtyToInvoice = Round(ShrinkQtyToInvoice, 0)

--CHAINUPC select * from  #tempchainupc 
update #tempchainupc
--update import.dbo.tempstoreupcfortesting
set ShrinkQtyToInvoice = Round(ShrinkQtyToInvoice, 0)

--set MaximumQtyToInvoice = case when FLOOR(MaximumQtyToInvoice) = 0 then 1 else FLOOR(MaximumQtyToInvoice) end
--case when MaximumQtyToInvoice % 1 = 0 then MaximumQtyToInvoice else cast(MaximumQtyToInvoice + case when TotalShrinkQty > 1 then 1.0000 else -1 end as int) end
/*
select * from #tempstoreupc where storeid = 40496 and productid = 5523
select * from #tempsettlement   where storeid = 40496 and productid = 5523
*/

--*********************Update Settlement FinalInvoiceQty***************************
--STOREUPC
update s set s.FinalInvoiceQty = Round(s.TotalQty * t.ShrinkPercentToInvoice, 0) 
from #tempsettlement s
inner join #tempstoreupc t
on s.StoreID = t.StoreID
and s.ProductID = t.productid
/*
--*****************************************Temp Queries**********************************************

select SUM(TotalQty), SUM(FinalInvoiceQty) from #tempsettlement where productid = 5426 
select * from #tempchainupc  where productid = 5426 
select FinalInvoiceQty as fqty, * from #tempsettlement where productid = 5426
 --*****************************************Temp Queries**********************************************
*/
--CHAINUPC select * from  #tempchainupc select * from #tempsettlement where productid = 5426 detailadjustmentqty is not null
update s set s.FinalInvoiceQty = Round(s.TotalQty * t.ShrinkPercentToInvoice, 0) 
from #tempsettlement s
inner join #tempchainupc t
on s.ProductID = t.productid

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

--CHAINUPC select * from  #tempchainupc select * from #tempsettlement  where productid = 5515 order by finalinvoiceqty 
update a set a.AdjustmentQty = a.ShrinkQtyToInvoice - d.FinalInvoiceQtySum
--select *
from #tempchainupc a
inner join 
(
select ProductId, SUM(FinalInvoiceQty) as FinalInvoiceQtySum
from #tempsettlement s
group by productid) d
on a.productid = d.productid
/*
select * from #tempstoreupc where storeid = 40470 and productid = 5510
select * from #tempsettlement   where storeid = 40508 and productid = 5424
select * from #tempsettlement   where storeid = 40501 and productid = 5511
select * from #tempsettlement   where storeid = 40460 and productid = 5509
select * from #tempstoreupc where adjustmentqty <> 0 order by adjustmentqty desc
Positive adj 40393	40508	5424	40561	2	1.74	0.87	2012-02-20 00:00:00.000	2011-12-01	121	0.0165	0.015	1.815	0.50	0.4545	1.00	STOREUPC	3
Negative adj 40393	40501	5511	40561	25	52.25	2.09	2012-02-27 00:00:00.000	2011-12-01	2056	0.0121	0.015	30.84	0.50	0.50	13.00	STOREUPC	-2
Zero adj 40393	40460	5509	40561	-1	-2.02	2.02	2012-02-20 00:00:00.000	2011-12-01	220	0.0045	0.015	3.30	0.50	0.50	-1.00	STOREUPC	0
select * from import.dbo.tempstoreupcfortesting
select * from import.dbo.tempsettlementfortesting
select * from #tempstoreupc
select * from #tempmaxFinalInvoiceQty where maxstoreid = 40508 and maxproductid = 5424
--drop table #tempmaxFinalInvoiceQty
*/
/*
--*****************************************Temp Queries**********************************************

select SUM(TotalQty), SUM(FinalInvoiceQty) from #tempsettlement where productid = 5426 
select * from  #tempsettlement where invoicedetailid = 6130156
select * from #tempchainupc  where productid = 5426 
select FinalInvoiceQty as fqty, * from #tempsettlement where productid = 5426
drop table #tempmaxFinalInvoiceQty_CHAINUPC
select * from #tempmaxFinalInvoiceQty_CHAINUPC  where maxproductid = 5426 
 --*****************************************Temp Queries**********************************************
 */
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
--CHAINUPC
		select a.ProductId as Maxproductid,
		a.AdjustmentQty, 
		d.LimitQty, CAST(0 as int) as LimitQtyInvoiceDetailID
		into #tempmaxFinalInvoiceQty_CHAINUPC
		from #tempchainupc a
		--from import.dbo.tempstoreupcfortesting a
		inner join 
		(
		select ProductId, case when sum(TotalQty) > 0 then MAX(TotalQty) else Min(TotalQty) end as LimitQty
		from #tempsettlement s
		--from import.dbo.tempsettlementfortesting
		where DetailadjustmentQtyApplied = 0
		group by productid) d
		on a.productid = d.productid
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
		
--CHAINUPC
		update t set LimitQtyInvoiceDetailID = s.InvoicedetailID
		--select *
		from  #tempmaxFinalInvoiceQty_CHAINUPC t
		inner join #tempsettlement s
		--from import.dbo.tempsettlementfortesting s
		on s.productid = Maxproductid
		and s.TotalQty = LimitQty
		and DetailadjustmentQtyApplied = 0
/*
select * from #tempstoreupc where storeid = 40470 and productid = 5510
select * from #tempsettlement   where storeid = 40470 and productid = 5510
select sum(FinalInvoiceQty) from #tempsettlement   where storeid = 40470 and productid = 5510
select * from #tempmaxFinalInvoiceQty   where LimitQtyInvoicedetailid in (9641558)
		select * from import.dbo.tempstoreupcfortesting
		select * from import.dbo.tempsettlementfortesting

		update  #tempmaxFinalInvoiceQty set Adjustmentqty = -4
		--drop table #tempmaxFinalInvoiceQty
		update import.dbo.tempsettlementfortesting set DetailAdjustmentQty = null
		*/

--STOREUPC
		update s set FinalInvoiceQty = s.FinalInvoiceQty + t.AdjustmentQty
		,s.DetailAdjustmentQty =  t.AdjustmentQty 
		--select *
		from #tempmaxFinalInvoiceQty t
		inner join #tempsettlement s
		on t.LimitQtyInvoiceDetailID = s.InvoicedetailID
--CHAINUPC
		update s set FinalInvoiceQty = s.FinalInvoiceQty + t.AdjustmentQty
		,s.DetailAdjustmentQty =  t.AdjustmentQty 
		--select *
		from #tempmaxFinalInvoiceQty_CHAINUPC t
		inner join #tempsettlement s
		on t.LimitQtyInvoiceDetailID = s.InvoicedetailID
/*
--*****************************************Temp Queries**********************************************

select SUM(TotalQty), SUM(FinalInvoiceQty) from #tempsettlement where productid = 5426 
select * from  #tempsettlement where invoicedetailid = 6130156
select * from #tempchainupc  where productid = 5426 
select FinalInvoiceQty as fqty, * from #tempsettlement where productid = 5426
drop table #tempmaxFinalInvoiceQty_CHAINUPC
select * from #tempmaxFinalInvoiceQty_CHAINUPC  where maxproductid = 5426 
 --*****************************************Temp Queries**********************************************
 */
--STOREUPC
		update A set a.AdjustmentQty = case when a.AdjustmentQty = s.DetailAdjustmentQty  then 0 else a.AdjustmentQty - s.DetailAdjustmentQty  end
		from #tempmaxFinalInvoiceQty a
		inner join #tempsettlement s
		on a.LimitQtyInvoiceDetailID = s.InvoicedetailID
		and s.DetailadjustmentQtyApplied = 0
--CHAINUPC
		update A set a.AdjustmentQty = case when a.AdjustmentQty = s.DetailAdjustmentQty  then 0 else a.AdjustmentQty - s.DetailAdjustmentQty  end
		from #tempmaxFinalInvoiceQty_CHAINUPC a
		inner join #tempsettlement s
		on a.LimitQtyInvoiceDetailID = s.InvoicedetailID
		and s.DetailadjustmentQtyApplied = 0

--STOREUPC & CHAINUPC			
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

--CHAINUPC				
		update A set a.AdjustmentQty = t.AdjustmentQty
		from #tempmaxFinalInvoiceQty_CHAINUPC t
		inner join #tempsettlement d
		on t.LimitQtyInvoiceDetailID = d.InvoicedetailID
		inner join #tempchainupc a
		on a.productid = d.productid
				
		select @countholder = 
		--select 
		COUNT(ProductID)
		from #tempchainupc
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
and t.CurrentSettleDate between p.ActiveStartDate and p.ActiveLastDate	
and t.FinalInvoiceUnitCost is null
and upper(ltrim(rtrim(t.SettlementCostRule))) = 'SETTLEMENTDATECOST'


/*
update #tempsettlement
set FinalInvoiceQty =
case when cast(TotalQty as money) * isnull(RetailerShrinkRatio,1) % 1 = 0 then cast(TotalQty as money) * isnull(RetailerShrinkRatio,1) else cast(cast(TotalQty as money) * cast(RetailerShrinkRatio as money) + 1.0000  as int) end
where TotalQty > 0

update #tempsettlement
set FinalInvoiceQty =
case when cast(TotalQty as money) * isnull(RetailerShrinkRatio,1) % 1 = 0 then cast(TotalQty as money) * isnull(RetailerShrinkRatio,1) else cast(cast(TotalQty as money) * cast(RetailerShrinkRatio as money) - 1.0000  as int) end
where TotalQty < 0
select * from invoicedetails where FinalInvoiceQty is not null
select sum(FinalInvoiceQty), sum(FinalInvoiceTotalCost) from invoicedetails where supplierid = 40561
--CHAINUPC 1458	2571.52
update d set d.FinalInvoiceUnitCost = null
,d.FinalInvoiceUnitPromo = null
,d.FinalInvoiceTotalCost = null
,d.FinalInvoiceQty = null
--select *
from invoicedetails d
where d.FinalInvoiceTotalCost is not null
*/

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
