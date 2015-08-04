USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[Sean_UpdateInventoryFactTable_GLCodeGrouping_20130204]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sean_UpdateInventoryFactTable_GLCodeGrouping_20130204]
	
	
as
Begin

drop table #tmpLSD
--last settelment date
SELECT     StoreID, Settle, MAX(PhysicalInventoryDate) AS LastSettlementDate, supplierId, UPC
Into #tmpLSD --select * from #tmpLSD
FROM         dbo.InventorySettlementRequests
where supplierId = 40559
--and StoreID = 40494
GROUP BY StoreID, Settle, supplierId, UPC
HAVING      (Settle = 'y')

drop table #tmpLS_FactTable
--Get Last Settlment UnitCount (from Store Transactions)
SELECT     LSD.supplierId, LSD.StoreID, LSD.LastSettlementDate, 
                      ISNULL(IC.qty, 0) AS LS_TTLQnt, 
                      ISNULL(IC.Qty*(ic.rulecost-isnull(ic.PromoAllowance,0)), 0) AS LS_TTLCost, 
                      LSD.UPC, IC.GLCode, ic.ProductID
into #tmpLS_FactTable
FROM         #tmpLSD LSD 
				LEFT OUTER JOIN
                   DataTrue_CustomResultSets.dbo.temp_StoreTransactions IC ON 
						  LSD.StoreID = IC.StoreID AND 
						  LSD.supplierId = IC.SupplierID AND 
						  LSD.LastSettlementDate = IC.SaleDateTime  AND 
						  LSD.UPC = IC.GLCodeUPC and ic.TransactionTypeID in(10,11)
						  --and ic.SupplierID = 40559
WHERE     (LSD.LastSettlementDate >= CONVERT(DATETIME, '2011-11-30 00:00:00', 102))
and IC.supplierId = 40559


/*
select *
--delete
from #tmpLS_FactTable
where 1 = 1
and storeid = 41270
and GLCode = 10048
and productid in (14351,8476)
--and LEN(GLCode) < 1
order by GLCode
order by LastSettlementDate

14351
8476


select *
from #tmpLS_FactTable f
order by GLCode, StoreID, ProductID

update f set f.ProductID = i.productid
--select *
from #tmpLS_FactTable f
inner join ProductIdentifiers i
on LTRIM(rtrim(UPC)) = LTRIM(rtrim(i.IdentifierValue))
where (GLCode is null or f.ProductID is null)
*/

--drop table #tempGLC
--select Distinct ProductID, SupplierProductID, UPC12
--into #tempGLC
--from datatrue_edi.dbo.ProductsSuppliersItemsConversion
--where master = 1
--and SupplierName = 'NST'

/*
select *
from #tempGLC

select *
--update t set t.GLCode = cast(c.SupplierProductID as int)
from #tempGLC c
inner join #tmpLS_FactTable t
on c.ProductID = t.ProductID
and t.SupplierID = 40559
--and c.Master = 1
and LEN(t.GLCode) < 1
*/





--Clean the main table
delete from InventoryReport_New_FactTable_Debug where supplierid = 40559

INSERT INTO [DataTrue_Main].[dbo].[InventoryReport_New_FactTable_Debug]
           ([SupplierName]
           ,[ChainName]
           ,[StoreNo]
           ,[SupplierAcctNo]
           ,[Banner]
           ,[LastInventoryCountDate]
           ,[LastSettlementDate]
           ,[UPC]
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
           ,[SupplierID]
           ,[ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[SupplierUniqueProductID]
           ,[NetUnitCostLastCountDate]
           ,[BaseCostLastCountDate]
           ,[WeightedAvgCost]
           ,[SharedShrinkUnits]
           ,[Settle]
           ,[GLCode])
	SELECT    SP.SupplierName, dbo.Chains.ChainName, ST.StoreIdentifier AS StoreNo, NULL AS SupplierAcctNo, 
						  ST.Custom1 AS Banner, CONVERT(varchar, s.SaleDateTime, 101) AS LastInventoryCountDate, CONVERT(varchar, 
						  LSFT.LastSettlementDate , 101) AS LastSettlementDate, cast(null as nvarchar(50)) as UPC, 
						  Sum(LSFT.LS_TTLQnt)  AS [BI Count], Sum(LSFT.LS_TTLCost) AS BI$, NULL 
						  AS [Net Deliveries], NULL AS [Net Deliveries$], NULL AS [Net POS], NULL AS POS$, NULL AS [Expected EI], NULL AS [Expected EI$], SUM(s.Qty) AS LastCountQty, 
						  SUM(s.Qty * (ISNULL(s.RuleCost,0) - ISNULL(s.PromoAllowance, 0))) AS LastCount$, NULL AS ShrinkUnits, NULL AS Shrink$, 
						  s.SupplierID, dbo.Chains.ChainID, s.StoreID, cast(null as int) as ProductID, NULL AS SupplierUniqueProductID, 
						  NULL AS LastCountCost, NULL AS LastCountBaseCost, null AS WeightedAvgCost, Null AS SharedShrinkUnits, Null as Settle, s.GLCode

	FROM         DataTrue_CustomResultSets.dbo.temp_StoreTransactions AS s INNER JOIN
						  dbo.Stores ST ON s.StoreID = ST.StoreID INNER JOIN
						  dbo.Chains ON s.ChainID = dbo.Chains.ChainID INNER JOIN
						  dbo.Suppliers  SP ON s.SupplierID = SP.SupplierID LEFT OUTER JOIN
						  #tmpLS_FactTable  LSFT ON s.SupplierID = LSFT.SupplierID AND 
						  s.StoreID = LSFT.StoreID AND s.GLCode = LSFT.GLCode
	WHERE     (s.TransactionTypeID IN (11, 10)) AND (s.SaleDateTime > ISNULL(LSFT.LastSettlementDate,CONVERT(DATETIME, '2000-01-01 00:00:00', 102)))
	and s.SupplierID = 40559
	GROUP BY s.SupplierID, s.StoreID, s.GLCode, CONVERT(varchar, s.SaleDateTime, 101), CONVERT(varchar, 
						  LSFT.LastSettlementDate , 101), 
						  --LSFT.LS_TTLCost, LSFT.LS_TTLQnt, 
						  SP.SupplierName, dbo.Chains.ChainID, dbo.Chains.ChainName, 
						  ST.StoreIdentifier, ST.Custom1
	ORDER BY s.SupplierID, s.StoreID, LastInventoryCountDate DESC


--select *
--from InventorySettlementRequests
--where StoreID = 40503

--select d.StoreID, s.storeid, d.LastSettlementDate, s.LastSettlementDate, *

update d set d.LastSettlementDate = s.LastSettlementDate
--select storeid as sid, *
from [DataTrue_Main].[dbo].[InventoryReport_New_FactTable_Debug] d
--where supplierid = 40559 and lastsettlementdate is null and banner <> 'SHAWS' order by LastInventoryCountDate, storeid 
--where LastSettlementDate is null and supplierid = 40559
inner join
(select storeid, SupplierID, MAX(PhysicalInventoryDate) as LastSettlementDate
from InventorySettlementRequests
where supplierid = 40559
and settle = 'Y'
group by storeid, supplierid) S
on d.storeid = s.storeid
and d.supplierid = s.supplierid
and d.LastsettlementDate is null


update one set one.LastSettlementDate = FirstInvDate
--select FirstInvDate, *
from [DataTrue_Main].[dbo].[InventoryReport_New_FactTable_Debug] one
inner join 
(
select storeid, Supplierid, MIN(LastINventoryCountDate) as FirstInvDate
from [DataTrue_Main].[dbo].[InventoryReport_New_FactTable_Debug]
where LastSettlementDate is null and SupplierID = 40559
group by storeid, supplierid) two
on one.StoreID = two.StoreID
and one.SupplierID = two.SupplierID

	
update d set d.[BI Count] = BIQty
--select BIQty, d.*
from InventoryReport_New_FactTable_Debug d
inner join
(
select storeid, GLCode, CAST(saledatetime as date) as saledate, SUM(qty) as BIQty
from DataTrue_CustomResultSets.dbo.temp_storetransactions t
where t.transactiontypeid in (10, 11)
and supplierid = 40559
group by storeid, GLCode, CAST(saledatetime as date)
)s
on d.storeid = s.storeid
and d.GLCode = s.GLCode
and s.Saledate =  CAST(Lastsettlementdate as date)
--order by [BI Count] Desc
	
update d set d.LastCountQty = LastQty
--select LastQty, d.LastCountQty, d.*
from InventoryReport_New_FactTable_Debug d
inner join
(
select storeid, GLCode, CAST(saledatetime as date) as saledate, SUM(qty) as LastQty
from DataTrue_CustomResultSets.dbo.temp_storetransactions t
where t.transactiontypeid in (10, 11)
and supplierid = 40559
group by storeid, GLCode, CAST(saledatetime as date)
)s
on d.storeid = s.storeid
and d.GLCode = s.GLCode
and s.Saledate =  CAST(d.LastInventoryCountDate as date)
--order by [BI Count] Desc


/*

select * from InventoryReport_New_FactTable_Debug where supplierid = 40559 and [BI Count] is null and storeid = 40400 and glcode in (27509)
select * from inventorysettlementrequests where storeid = 40400 and supplierid = 40559 and CAST(physicalinventorydate as date) = '6/27/2012'
select * from temp_storetransactions where storeid = 40400 and supplierid = 40559 and CAST(saledatetime as date) = '6/27/2012' and transactiontypeid in (10, 11) and upc = '041548610108' --order by upc --glcode
select * from import.dbo.NestleGlCodeUPC order by SupplierProductID

select * from temp_storetransactions where supplierid = 40559 and upc = '041548610108'  and transactiontypeid = 11 and storeid = 40440 order by CAST(saledatetime as date)

select * from InventoryReport_New_FactTable_Debug where supplierid = 40559 order by GLCode 
select * from InventoryReport_New_FactTable_Debug where supplierid = 40559 order by LastSettlementDate

select max(saledatetime) from temp_storetransactions where storeid = 40462 and supplierid = 40559 and transactiontypeid in (10, 11)



select * from inventorysettlementrequests where supplierid = 40559 and storeid = 40462
select Max(PhysicalInventoryDate) from inventorysettlementrequests where supplierid = 40559 and storeid = 40462

alter table InventoryReport_New_FactTable_Debug
alter column Productid int null



select * from InventoryReport_New_FactTable_Debug where supplierid = 40559 order by [BI Count] desc

select * from temp_storetransactions where storeid = 40471 and glcode = 29116 and cast(saledatetime as date) = '8/28/2012'

select * from InventoryReport_New_FactTable_Debug where supplierid = 40559 order by shrinkunits

select * from InventoryReport_New_FactTable_Debug where supplierid = 40559 order by 

select StoreID as sid, GLCode as gl, UPC as upcc, * from InventoryReport_New_FactTable_Debug where supplierid = 40559 order by StoreID, GLCode, UPC

select * from #GLCodeUPC where supplierproductid = '10048'

select * from InventoryReport_New_FactTable_Debug where supplierid = 40559 and GLCode = 10048

select * from InventoryReport_New_FactTable_Active where supplierid = 40559 and GLCode = 10048

select sum(shrink$) from InventoryReport_New_FactTable_Debug where supplierid = 40559

select * from InventoryReport_New_FactTable_Debug where supplierid = 40559 and storeid in (select storeid from stores where custom1 = 'Albertsons - IMW') and LastSettlementDate = '1/18/2012' and LastInventoryCountDate = '5/10/2012'
select sum([BI Count]), sum([LastCountQty]), sum([Expected EI]), sum([BI Count]) + sum([Net Deliveries]) - sum([Net POS]) as EI from InventoryReport_New_FactTable_Debug where supplierid = 40559 and storeid in (select storeid from stores where custom1 = 'Albertsons - IMW') and LastSettlementDate = '1/18/2012' and LastInventoryCountDate = '5/10/2012'


select *
from temp_storetransactions
where storeid = 41043
and GLCode = 10860
and cast(saledatetime as date) = '10/24/2012'

select *
from datatrue_archive.dbo.storetransactions_working
where storeid = 41043
--and GLCode = 10860
and charindex('INV', workingsource) > 0
and cast(saledatetime as date) = '10/24/2012'
order by qty desc

select *
from datatrue_edi.dbo.ProductsSuppliersItemsConversion
where 1 = 1
and SupplierProductID = '10860'
and productid = 5305

select sum(qty)
from temp_storetransactions
where storeid = 41043
and GLCode = 10860
and transactiontypeid in (2, 6)
and cast(saledatetime as date) between '8/30/2012' and  '10/23/2012'
*/
--drop table #GLCodeUPC

--select g.UPC12, g.ProductID, g.SupplierProductID, sum(Qty) as TotalQty
--into #GLCodeUPC
--from #tempGLC g
--inner join temp_storetransactions t
--on g.ProductID = t.ProductID
--and t.transactiontypeid in (2, 6)
--and t.supplierid = 40559
--group by g.UPC12, g.ProductID, g.SupplierProductID
--order by SUM(Qty) desc

--select * into import.dbo.NestleGlCodeUPC from #GLCodeUPC
--select * from import.dbo.NestleGlCodeUPC

update d set d.UPC = g.UPC12, d.ProductID = g.ProductID
--select *
from InventoryReport_New_FactTable_Debug d
inner join import.dbo.NestleGlCodeUPC g
on d.GLCode = cast(g.SupplierProductID as int)
and g.Master = 1

--update d
--set d.UPC = g.UPC12, d.ProductID = g.ProductID
--from InventoryReport_New_FactTable_Debug d
--inner join #GLCodeUPC g
--on d.GLCode = g.SupplierProductID

--Initialize
/*
select storeid, MIN(LastInventoryCountDate) as LastSettlementDate
into #tempInitdate
from InventoryReport_New_FactTable_Debug
where supplierid = 40559
group by storeid
order by MIN(LastInventoryCountDate)

select *
--update d set LastSettlementDate = t.LastSettlementDate
from #tempInitdate t
inner join InventoryReport_New_FactTable_Debug d
on t.StoreID = d.StoreID
and d.SupplierID = 40559

select *
from InventoryReport_New_FactTable_Debug
*/
drop table #t1 drop table #t2 drop table #t3

-- Update Null Last Settlement Dates of Products that were not settled during the last settlement date where other products within the same supplier and store got settled
	select distinct SupplierID, StoreID, LastSettlementDate into #t1 from  InventoryReport_New_FactTable_Debug where LastSettlementDate is not null
	select distinct SupplierID, StoreID, GLCode, LastSettlementDate into #t2  from  InventoryReport_New_FactTable_Debug where LastSettlementDate is null
	
	select #t2.*, #t1.LastSettlementDate as datetoupdate into #t3 from  #t1
	inner join #t2 on #t1.SupplierID=#t2.SupplierID  and #t1.StoreID=#t2.StoreID 
		
	update i
	set LastSettlementDate = #t3.datetoupdate
	from InventoryReport_New_FactTable_Debug i
	inner join #t3 on #t3.SupplierID=i.SupplierID and #t3.StoreID=i.StoreID and #t3.GLCode=i.GLCode

drop table #tmpDeliveries
--DeliveriesRecords
SELECT     SUM(s.Qty * TT.QtySign) AS NetDeliveries, SUM((s.Qty * TT.QtySign) * (ISNULL(s.RuleCost,0) 
                      - ISNULL(s.PromoAllowance, 0))) AS NetDeliveries$, FA.LastSettlementDate, 
                      FA.LastInventoryCountDate, FA.GLCode, ST.StoreIdentifier AS StoreNumber, s.StoreID, 
                      s.SupplierID
into #tmpDeliveries                      
FROM         dbo.InventoryReport_New_FactTable_Debug FA 
			 INNER JOIN
			 dbo.stores st on st.storeid = fa.storeid and FA.SupplierID = 40559
			 inner join
				DataTrue_CustomResultSets.dbo.temp_StoreTransactions s  ON FA.GLCode = s.GLCode --FA.ProductID = s.ProductID AND
                       and FA.StoreID = s.StoreID AND FA.SupplierID = s.SupplierID            
                      and 
                      (s.SaleDateTime >= CONVERT(DATETIME, '2011-12-01 00:00:00', 102)) AND 
                      (s.SaleDateTime >= ISNULL(FA.LastSettlementDate, CONVERT(DATETIME, '2011-12-01 00:00:00', 102))) AND 
                      (s.SaleDateTime < FA.LastInventoryCountDate)
                      
             inner join
              dbo.TransactionTypes TT on TT.TransactionTypeID = s.TransactionTypeID and (TT.BucketType = 2)
             
             INNER JOIN
             dbo.InventoryRulesTimesBySupplierID IRS ON FA.SupplierID = IRS.SupplierID AND FA.ChainID = IRS.ChainID and (IRS.InventoryTakenBeforeDeliveries = 1) 


GROUP BY FA.LastSettlementDate, FA.LastInventoryCountDate, FA.GLCode, 
                      ST.StoreIdentifier, s.StoreID, s.SupplierID



--update Deliveries

update InventoryReport_New_FactTable_Debug 

set [Net Deliveries] = a.NetDeliveries   ,[Net Deliveries$]=a.NetDeliveries$   

from	(select * from #tmpDeliveries ) a

inner join InventoryReport_New_FactTable_Debug
	on InventoryReport_New_FactTable_Debug.storeid = a.storeid
	and InventoryReport_New_FactTable_Debug.supplierid = a.supplierid	
	and InventoryReport_New_FactTable_Debug.GLCode = a.GlCode
	--and InventoryReport_New_FactTable_Debug.ProductID  = a.productid
	and InventoryReport_New_FactTable_Debug.LastInventoryCountDate =a.LastInventoryCountDate
	and InventoryReport_New_FactTable_Debug.LastSettlementDate  =a.LastSettlementDate 
	
--update deliveries for Settlement Dates= Null 
update InventoryReport_New_FactTable_Debug 

set [Net Deliveries] = a.NetDeliveries   ,[Net Deliveries$]=a.NetDeliveries$   

from	(select * from #tmpDeliveries ) a

inner join InventoryReport_New_FactTable_Debug
	on InventoryReport_New_FactTable_Debug.storeid = a.storeid
	and InventoryReport_New_FactTable_Debug.supplierid = a.supplierid
		and InventoryReport_New_FactTable_Debug.GLCode = a.GlCode
	
	--and InventoryReport_New_FactTable_Debug.ProductID  = a.productid
	and InventoryReport_New_FactTable_Debug.LastInventoryCountDate =a.LastInventoryCountDate

where  (a.LastSettlementDate) is null

drop table #tmpPOS
--POS SALES Records
SELECT     SUM(s.Qty * TT.QtySign) AS NetPOS, SUM((s.Qty * TT.QtySign) * (ISNULL(s.RuleCost,0) 
                      - ISNULL(s.PromoAllowance, 0))) AS NetPOS$, FA.LastSettlementDate, 
                      FA.LastInventoryCountDate, FA.GLCode, ST.StoreIdentifier AS StoreNumber, s.StoreID, 
                      s.SupplierID
Into #tmpPOS
FROM         dbo.InventoryReport_New_FactTable_Debug FA 
			 INNER JOIN
			 dbo.stores st on st.storeid = fa.storeid and FA.SupplierID = 40559
			 inner join
				DataTrue_CustomResultSets.dbo.temp_StoreTransactions s  ON FA.GLCode = s.GLCode --FA.ProductID = s.ProductID AND
                       and FA.StoreID = s.StoreID AND FA.SupplierID = s.SupplierID            
                      and 
                      (s.SaleDateTime >= CONVERT(DATETIME, '2011-12-01 00:00:00', 102)) AND 
                      (s.SaleDateTime >= ISNULL(FA.LastSettlementDate, CONVERT(DATETIME, '2011-12-01 00:00:00', 102))) AND 
                      (s.SaleDateTime < FA.LastInventoryCountDate)
                      
             inner join
              dbo.TransactionTypes TT on TT.TransactionTypeID = s.TransactionTypeID and (TT.BucketType = 1)
             
             INNER JOIN
             dbo.InventoryRulesTimesBySupplierID IRS ON FA.SupplierID = IRS.SupplierID AND FA.ChainID = IRS.ChainID and (IRS.InventoryTakenBeforeDeliveries = 1) 


GROUP BY FA.LastSettlementDate, FA.LastInventoryCountDate, FA.GLCode, 
                      ST.StoreIdentifier, s.StoreID, s.SupplierID
--select * from #tmpPOS

--update POS

update InventoryReport_New_FactTable_Debug

set [Net POS]   =a.NetPOS   ,POS$   =a.NetPOS$ ,  WeightedAvgCost=a.NetPOS$/a.NetPOS

from	(select * from #tmpPOS ) a

inner join InventoryReport_New_FactTable_Debug
	on InventoryReport_New_FactTable_Debug.storeid = a.storeid
	and InventoryReport_New_FactTable_Debug.supplierid = a.supplierid
	and InventoryReport_New_FactTable_Debug.GLCode = a.GlCode	
	--and InventoryReport_New_FactTable_Debug.ProductID  = a.productid
	and InventoryReport_New_FactTable_Debug.LastInventoryCountDate =a.LastInventoryCountDate
	and InventoryReport_New_FactTable_Debug.LastSettlementDate  =a.LastSettlementDate 
	and a.NetPOS <>0

--update POS for Settlement Dates= Null 

update InventoryReport_New_FactTable_Debug

set [Net POS]   =a.NetPOS   ,POS$   =a.NetPOS$,  WeightedAvgCost=a.NetPOS$/a.NetPOS

from	(select * from #tmpPOS ) a

inner join InventoryReport_New_FactTable_Debug
	on InventoryReport_New_FactTable_Debug.storeid = a.storeid
	and InventoryReport_New_FactTable_Debug.supplierid = a.supplierid	
	and InventoryReport_New_FactTable_Debug.GLCode = a.GlCode	
	--and InventoryReport_New_FactTable_Debug.ProductID  = a.productid
	and InventoryReport_New_FactTable_Debug.LastInventoryCountDate =a.LastInventoryCountDate	
	and a.NetPOS <>0

where  (a.LastSettlementDate) is null

		
--update SupplierUniqueAccounttNumber

update InventoryReport_New_FactTable_Debug

set SupplierAcctNo =a.SupplierAccountNumber 

from	(select * from dbo.StoresUniqueValues ) a

inner join InventoryReport_New_FactTable_Debug
	on InventoryReport_New_FactTable_Debug.storeid = a.storeid
	and InventoryReport_New_FactTable_Debug.supplierid = a.supplierid	
	
--update SupplierUniqueProductNumber

update InventoryReport_New_FactTable_Debug

set SupplierUniqueProductID  =a.IdentifierValue

from	(select * from dbo.ProductIdentifiers   where ProductIdentifierTypeID=3) a

inner join InventoryReport_New_FactTable_Debug
	on InventoryReport_New_FactTable_Debug.ProductID = a.ProductID
	and InventoryReport_New_FactTable_Debug.supplierid = a.OwnerEntityId	



--update Null values to Zero , 

update InventoryReport_New_FactTable_Debug 
set [Net Deliveries] =ISNULL([Net Deliveries] ,0),[Net Deliveries$] =ISNULL([Net Deliveries$],0),[Net POS]=ISNULL([Net POS],0),POS$ =ISNULL(POS$  ,0)

--Next update added 4/19/2012 by charlie and Mandeep to manage Lewis lastsettlement date to 12/10/2011
update InventoryReport_New_FactTable_Debug 
set [BI Count] =ISNULL([BI Count] ,0),BI$ =ISNULL(BI$,0), LastSettlementDate =isnull(LastSettlementDate,'12/10/2011')
where (ChainID =40393 and SupplierID  = 41464)


	--do not update Bimbo (40557)  Last Settlment Date to 12/1/2011 becuase they have multiple initialization dates based on banners
update InventoryReport_New_FactTable_Debug 
set [BI Count] =ISNULL([BI Count] ,0),BI$ =ISNULL(BI$,0), LastSettlementDate =isnull(LastSettlementDate,'12/1/2011')
where (ChainID =40393 and SupplierID  <> 40557)  or (ChainID =40393 and SupplierID  = 40557 and Banner not like 'Farm Fresh Markets')

	--update Bimbo (40557)  Last Settlment Date to 1/2/2012 (for Farm Fresh) becuase they have multiple initialization dates based on banners
update InventoryReport_New_FactTable_Debug 
set [BI Count] =ISNULL([BI Count] ,0),BI$ =ISNULL(BI$,0), LastSettlementDate =isnull(LastSettlementDate,'1/2/2012')
where ChainID =40393 and SupplierID  = 40557 and Banner = 'Farm Fresh Markets'


--update EI , 

update InventoryReport_New_FactTable_Debug

set [Expected EI]=[BI Count]-[Net POS]+[Net Deliveries],[Expected EI$]=BI$-POS$+[Net Deliveries$]
	

--update ShrinkUnits
update InventoryReport_New_FactTable_Debug

set 	ShrinkUnits =[Expected EI]-LastCountQty,Shrink$=[Expected EI$]-LastCount$ 
where LastCountQty =0

update InventoryReport_New_FactTable_Debug

set 	ShrinkUnits =[Expected EI]-LastCountQty,Shrink$=(LastCount$/LastCountQty )*([Expected EI]-LastCountQty )
where LastCountQty <>0

--Final Clean Up
Delete  from InventoryReport_New_FactTable_Debug
where LastSettlementDate  is null and LastCountQty =0 and [Net Deliveries] =0

/*
select * from InventoryReport_New_FactTable_Debug where SupplierID = 40559 order by LastCountQty
select sum(Shrink$) from InventoryReport_New_FactTable_Debug where SupplierID = 40559
*/
                  
--Update UnitCost at LastCountDate	
		update f set f. NetUnitCostLastCountDate = s.NetCost, f.BaseCostLastCountDate=s.basecost 
		from InventoryReport_New_FactTable_Debug f
		inner join
		(select i.ProductID ,i.StoreID,i.LastInventoryCountDate  ,p3.UnitPrice-ISNULL(p8.unitprice,0) as NetCost, p3.UnitPrice as basecost
		from InventoryReport_New_FactTable_Debug I
		 inner join 		
			  ProductPrices p3 on p3.ProductID=i.ProductID  and p3.StoreID =i.StoreID and p3.SupplierID =i.SupplierID and p3.ProductPriceTypeID =3 
		 left join ProductPrices P8 on p3.ProductID=p8.ProductID  and p3.SupplierID =p8.SupplierID and p3.StoreID =p8.StoreID
					and p3.ActiveStartDate <=p8.ActiveStartDate and p8.ActiveLastDate <=p3.ActiveLastDate 	 and p8.ProductPriceTypeID =8 
					and i.LastInventoryCountDate between p8.ActiveStartDate  and p8.ActiveLastDate 
			 
		 where  i.LastInventoryCountDate between p3.ActiveStartDate  and p3.ActiveLastDate  ) s
		 on f.ProductID = s.ProductID
		 and f.StoreID = s.StoreID
		 and f.LastInventoryCountDate = s.LastInventoryCountDate

--Fix Null value in Base Cost that are Null becuase no POS activity was recorded. 08/20/2012

	update InventoryReport_New_FactTable_Debug set BaseCostLastCountDate=POS$/[Net POS]
	where BaseCostLastCountDate is null and isnull(POS$,0) <>0 and isnull([Net POS],0) <>0
	
	update InventoryReport_New_FactTable_Debug set BaseCostLastCountDate=[Net Deliveries$]/[Net Deliveries]
	where BaseCostLastCountDate is null and isnull([Net Deliveries],0) <>0 and isnull([Net Deliveries$],0) <>0
	
	update InventoryReport_New_FactTable_Debug set BaseCostLastCountDate= BI$/[BI Count]
	where BaseCostLastCountDate is null and isnull([BI Count],0) <>0 and isnull(BI$,0) <>0

	update InventoryReport_New_FactTable_Debug set BaseCostLastCountDate= 0
	where BaseCostLastCountDate is null and ShrinkUnits<>0


--update POS, Deliveries and BI to be calculated based on the most recent BASE unit cost
update f
set [Net Deliveries$] = s.Deliveries$, [Expected EI$]=s.Expected$ , [POS$]=s.POS$,[BI$]=s.BI$ ,[Shrink$]=s.Shrink$, [lastcount$]=s.lastcount$ 
from InventoryReport_New_FactTable_Debug f
inner join
(select i.SupplierID, i.ProductID,i.StoreID,i.LastInventoryCountDate, 
i.[Net Deliveries]*i.BaseCostLastCountDate  as Deliveries$, 
i.[Expected EI]*i.BaseCostLastCountDate as Expected$,
i.[BI Count]*i.BaseCostLastCountDate as BI$,
i.[Net POS] *i.BaseCostLastCountDate  as POS$,
i.ShrinkUnits *i.BaseCostLastCountDate as Shrink$,
i.LastCountQty *i.BaseCostLastCountDate as LastCount$

 from InventoryReport_New_FactTable_Debug  i where BaseCostLastCountDate is not null) s
 
 on f.SupplierID=s.SupplierID
		 and f.ProductID = s.ProductID
		 and f.StoreID = s.StoreID
		 and f.LastInventoryCountDate = s.LastInventoryCountDate
		 

--Fix Null value in Weighted Avg Cost that are Null becuase no POS activity was recorded. 08/16/2012
    update InventoryReport_New_FactTable_Debug set WeightedAvgCost=Shrink$/ShrinkUnits
	where WeightedAvgCost is null and isnull(ShrinkUnits,0) <>0 and isnull(Shrink$,0) <>0
	
	update InventoryReport_New_FactTable_Debug set WeightedAvgCost=[Net Deliveries$]/[Net Deliveries]
	where WeightedAvgCost is null and isnull([Net Deliveries],0) <>0 and isnull([Net Deliveries$],0) <>0
	
	update InventoryReport_New_FactTable_Debug set WeightedAvgCost=POS$/[Net POS]
	where WeightedAvgCost is null and isnull(POS$,0) <>0 and isnull([Net POS],0) <>0
	
	update InventoryReport_New_FactTable_Debug set WeightedAvgCost=[Expected EI$]/[Expected EI]
	where WeightedAvgCost is null and isnull([Expected EI$],0) <>0 and isnull([Expected EI],0) <>0

	
--ADDED 4/26/2012--update POS, Deliveries and BI to be calculated based on the most recent WEIGHTED AVG unit cost (ONLY for records that there WeightCost >0)
update f
set [Net Deliveries$] = s.Deliveries$, [Expected EI$]=s.Expected$ , [POS$]=s.POS$,[BI$]=s.BI$ ,[Shrink$]=s.Shrink$, [lastcount$]=s.lastcount$ 
from InventoryReport_New_FactTable_Debug f
inner join
(select i.SupplierID,i.ProductID,i.StoreID,i.LastInventoryCountDate, 
i.[Net Deliveries]*i.WeightedAvgCost  as Deliveries$, 
i.[Expected EI]*i.WeightedAvgCost as Expected$,
i.[BI Count]*i.WeightedAvgCost as BI$,
i.[Net POS] *i.WeightedAvgCost  as POS$,
i.ShrinkUnits *i.WeightedAvgCost as Shrink$,
i.LastCountQty *i.WeightedAvgCost as LastCount$

 from InventoryReport_New_FactTable_Debug  i ) s
 
 on f.SupplierID =s.SupplierID
		 and f.ProductID = s.ProductID
		 and f.StoreID = s.StoreID
		 and f.LastInventoryCountDate = s.LastInventoryCountDate
		 and f.WeightedAvgCost>0
where f.SupplierID <>40562 --Condition added by Vishal on 8/22 to skip Shrink $ calculation based on weighted Avg Cost. (FB: 14636)

/*
select * from InventoryReport_New_FactTable_Debug where supplierid = 40559 order by shrinkunits

select * from temp_storetransactions where storeid = 41130 and supplierid = 40559 and GLCode = 27361 and CAST(saledatetime as date) >= '8/30/2012'

select * from InventoryReport_New_FactTable_Debug where supplierid = 40559 and [BI Count] is null and storeid = 40400 and glcode in (27509)
select * from inventorysettlementrequests where storeid = 41043 and supplierid = 40559 and CAST(physicalinventorydate as date) = '6/27/2012'
select * from temp_storetransactions where storeid = 41043 and supplierid = 40559 and CAST(saledatetime as date) = '6/27/2012' and transactiontypeid in (10, 11) and upc = '041548610108' --order by upc --glcode
select * from import.dbo.NestleGlCodeUPC order by SupplierProductID


select Glcode as gl,* from temp_storetransactions where storeid = 41043 and supplierid = 40559 and CAST(saledatetime as date) >= '8/30/2012' order by glcode

select custom2 as sbt, *
from stores
where custom1 = 'albertsons - scal'
order by custom2



select * from datatrue_archive.dbo.storetransactions_working where storetransactionid = 62322368
select * from datatrue_edi.dbo.inbound846inventory where recordid = 17226848

select * from datatrue_edi.dbo.inbound846inventory where storenumber = '6525' and ediname = 'NST' and rawproductidentifier = '27361'


select *
from import.dbo.NestleGlCodeUPC g
where 1 = 1
--and g.Master = 1
and cast(g.SupplierProductID as int) = 27361
order by cast(g.SupplierProductID as int)

select * from InventoryReport_New_FactTable_Debug where supplierid = 40559
and storeid = 40494
and GLCode = 27024

select *
from temp_storetransactions
where storeid = 40494
and GLCode = 27024
and transactiontypeid = 11

select *
from inventorysettlementrequests
where supplierid = 40559
and storeid = 40494
and productid = 5287



select * from InventoryReport_New_FactTable_Debug where supplierid = 40559 order by [BI Count] desc

select * from InventoryReport_New_FactTable_Debug where supplierid = 40559 order by shrinkunits

select * from InventoryReport_New_FactTable_Debug where supplierid = 40559 order by 

select StoreID as sid, GLCode as gl, UPC as upcc, * from InventoryReport_New_FactTable_Debug where supplierid = 40559 order by StoreID, GLCode, UPC

select * from #GLCodeUPC where supplierproductid = '10048'

select * from InventoryReport_New_FactTable_Debug where supplierid = 40559 and GLCode = 10048

select * from InventoryReport_New_FactTable_Active where supplierid = 40559 and GLCode = 10048

select sum(shrink$) from InventoryReport_New_FactTable_Debug where supplierid = 40559

select * from InventoryReport_New_FactTable_Debug where supplierid = 40559 and storeid in (select storeid from stores where custom1 = 'Albertsons - IMW') and LastSettlementDate = '1/18/2012' and LastInventoryCountDate = '5/10/2012'
select sum([BI Count]), sum([LastCountQty]), sum([Expected EI]), sum([BI Count]) + sum([Net Deliveries]) - sum([Net POS]) as EI from InventoryReport_New_FactTable_Debug where supplierid = 40559 and storeid in (select storeid from stores where custom1 = 'Albertsons - IMW') and LastSettlementDate = '1/18/2012' and LastInventoryCountDate = '5/10/2012'


*/
--select StoreID as stid, glcode as gl, *
--from  InventoryReport_New_FactTable_Debug d
--where supplierid = 40559
----order by StoreID, glcode
--and StoreID in 
--(select StoreID from stores where Custom1 = 'Albertsons - ACME')
--order by StoreID, glcode

delete
--select *
from [DataTrue_Main].[dbo].[InventoryReport_New_FactTable_Active]
where supplierid = 40559

INSERT INTO [DataTrue_Main].[dbo].[InventoryReport_New_FactTable_Active]
           ([SupplierName]
           ,[ChainName]
           ,[StoreNo]
           ,[SupplierAcctNo]
           ,[Banner]
           ,[LastInventoryCountDate]
           ,[LastSettlementDate]
           ,[UPC]
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
           ,[SupplierID]
           ,[ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[SupplierUniqueProductID]
           ,[NetUnitCostLastCountDate]
           ,[BaseCostLastCountDate]
           ,[WeightedAvgCost]
           ,[SharedShrinkUnits]
           ,[Settle]
           ,[GLCode])
SELECT [SupplierName]
      ,[ChainName]
      ,[StoreNo]
      ,[SupplierAcctNo]
      ,[Banner]
      ,[LastInventoryCountDate]
      ,[LastSettlementDate]
      ,[UPC]
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
      ,[SupplierID]
      ,[ChainID]
      ,[StoreID]
      ,[ProductID]
      ,[SupplierUniqueProductID]
      ,[NetUnitCostLastCountDate]
      ,[BaseCostLastCountDate]
      ,[WeightedAvgCost]
      ,[SharedShrinkUnits]
      ,[Settle]
      ,[GLCode]
  FROM [DataTrue_Main].[dbo].[InventoryReport_New_FactTable_Debug]
where SupplierID = 40559
and ProductID is not null
--order by productid







/*

select sum(TotalCost) from invoicedetails where supplierid = 40559 and invoicedetailtypeid = 1 and saledate between '9/1/2012' and '12/31/2012'

select *
--delete
from inventorysettlementrequests
where supplierid = 40559
and settle <> 'Y'

set Identity_INsert temp_storetransactions on 


INSERT INTO [DataTrue_Main].[dbo].[temp_storetransactions]
           ([StoreTransactionID]
           ,[ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[SupplierID]
           ,[TransactionTypeID]
           ,[ProductPriceTypeID]
           ,[BrandID]
           ,[Qty]
           ,[SetupCost]
           ,[SetupRetail]
           ,[SaleDateTime]
           ,[UPC]
           ,[SupplierInvoiceNumber]
           ,[ReportedCost]
           ,[ReportedRetail]
           ,[ReportedAllowance]
           ,[ReportedPromotionPrice]
           ,[RuleCost]
           ,[RuleRetail]
           ,[CostMisMatch]
           ,[RetailMisMatch]
           ,[TrueCost]
           ,[TrueRetail]
           ,[ActualCostNetFee]
           ,[TransactionStatus]
           ,[Reversed]
           ,[ProcessingErrorDesc]
           ,[SourceID]
           ,[Comments]
           ,[InvoiceID]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[WorkingTransactionID]
           ,[InvoiceBatchID]
           ,[InventoryCost]
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
           ,[InvoiceNo]
           ,[PONo]
           ,[CorporateName]
           ,[CorporateIdentifier]
           ,[Banner]
           ,[PromoTypeID]
           ,[PromoAllowance]
           ,[SBTNumber]
           ,[SourceOrDestinationID]
           ,[CreditType]
           ,[PODReceived]
           ,[ShrinkLocked]
           ,[InvoiceDueDate])

SELECT [StoreTransactionID]
      ,[ChainID]
      ,[StoreID]
      ,[ProductID]
      ,[SupplierID]
      ,[TransactionTypeID]
      ,[ProductPriceTypeID]
      ,[BrandID]
      ,[Qty]
      ,[SetupCost]
      ,[SetupRetail]
      ,[SaleDateTime]
      ,[UPC]
      ,[SupplierInvoiceNumber]
      ,[ReportedCost]
      ,[ReportedRetail]
      ,[ReportedAllowance]
      ,[ReportedPromotionPrice]
      ,[RuleCost]
      ,[RuleRetail]
      ,[CostMisMatch]
      ,[RetailMisMatch]
      ,[TrueCost]
      ,[TrueRetail]
      ,[ActualCostNetFee]
      ,[TransactionStatus]
      ,[Reversed]
      ,[ProcessingErrorDesc]
      ,[SourceID]
      ,[Comments]
      ,[InvoiceID]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[WorkingTransactionID]
      ,[InvoiceBatchID]
      ,[InventoryCost]
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
      ,[InvoiceNo]
      ,[PONo]
      ,[CorporateName]
      ,[CorporateIdentifier]
      ,[Banner]
      ,[PromoTypeID]
      ,[PromoAllowance]
      ,[SBTNumber]
      ,[SourceOrDestinationID]
      ,[CreditType]
      ,[PODReceived]
      ,[ShrinkLocked]
      ,[InvoiceDueDate]
  FROM [DataTrue_Main].[dbo].[StoreTransactions]
where transactiontypeid = 11
and supplierid = 40559
and storetransactionid not in 
(select storetransactionid from temp_storetransactions)







select *
from datatrue_edi.dbo.ProductsSuppliersItemsConversion
where 1 = 1
and SupplierName = 'NST'
order by ProductID2

select *
--update c set c.ProductID = c.ProductID2
from datatrue_edi.dbo.ProductsSuppliersItemsConversion c
where 1 = 1
and SupplierName = 'NST'
and ProductID2 is not null
and ProductID <> ProductID2
and (ProductID = 0 or ProductID is null)

select *
from datatrue_edi.dbo.ProductsSuppliersItemsConversion
where 1 = 1
and productid in (14351,8476)
--and productid = 0

select *
from storetransactions
where 1 = 1
and productid in (14351,8476)

update f set f.ProductID = i.productid
--select *
from datatrue_edi.dbo.ProductsSuppliersItemsConversion f
inner join ProductIdentifiers i
on LTRIM(rtrim(UPC)) = LTRIM(rtrim(i.IdentifierValue))
where (GLCode is null or f.ProductID is null)

select productID, count(distinct SupplierProductID)
from datatrue_edi.dbo.ProductsSuppliersItemsConversion
where SupplierName = 'NST'
and productid <> 0
group by productid
having count(distinct SupplierProductID) > 1
order by count(distinct SupplierProductID) desc

select productID, count(distinct SupplierProductID) as count 
--into #tempProd
from datatrue_edi.dbo.ProductsSuppliersItemsConversion
where SupplierName = 'NST'
and productid <> 0
group by productid
having count(distinct SupplierProductID) = 1

update datatrue_edi.dbo.ProductsSuppliersItemsConversion
set Master = 1
where ProductId in (select ProductID from #tempProd)

select 

select *
from datatrue_edi.dbo.ProductsSuppliersItemsConversion
where productid = 5296

select rawproductidentifier, comments, *
from storetransactions t
where 1 = 1
and t.ProductID = 5296
and t.transactiontypeid in (10, 11)

select ltrim(rtrim(ISNULL(t.rawproductidentifier, ''))), ltrim(rtrim(ISNULL(c.SupplierProductID, ''))), *
--update t set t.rawproductidentifier = ltrim(rtrim(c.SupplierProductID)), t.comments = t.comments + '////' + ltrim(rtrim(c.SupplierProductID))
from datatrue_edi.dbo.ProductsSuppliersItemsConversion c
inner join storetransactions t
on c.ProductID = t.ProductID
and t.TransactionTypeID in (10,11)
and t.SupplierID = 40559
--and (t.rawproductidentifier is null or LEN(t.rawproductidentifier) < 1)
and ltrim(rtrim(ISNULL(t.rawproductidentifier, ''))) <> ltrim(rtrim(ISNULL(c.SupplierProductID, '')))
order by ltrim(rtrim(ISNULL(t.rawproductidentifier, '')))


select cast(saledatetime as date), ltrim(rtrim(rawproductidentifier)), comments
--select *
from storetransactions t
where 1 = 1
--and t.ProductID = 5213
and t.TransactionTypeID in (10,11)
and charindex('///', comments) > 0
order by cast(saledatetime as date), ltrim(rtrim(rawproductidentifier))

select *
from datatrue_edi.dbo.ProductsSuppliersItemsConversion
where supplierproductid in ('10048',	'10068')
order by SupplierProductID, ProductIdentifier


10003	10009	9241	40559	10778	10009	041548034034        	Dreyer'S Edy'S Grand 14oz                                                                                                                                                                                                                                 
10003	10011	9242	40559	10778	10011	041548034034        	Dreyer'S Edy'S Grand International 14oz                                                                                                                                                                                                                   
10003	10009	9241	40559	10778	10009	041548034034        	Dreyer'S Edy'S Grand 14oz                                                                                                                                                                                                                                 
10003	10011	9242	40559	10778	10011	041548034034        	Dreyer'S Edy'S Grand International 14oz                                                                                                                                                                                                                   
10048	10068	9034	40559	5296	10068	041548751030        	D/E Fun Flavors Fdd Pkg 1.5q                                                                                                                                                                                                                              
10048	10068	9034	40559	5296	10068	041548751030        	D/E Fun Flavors Fdd Pkg 1.5q                                                                                                                                                                                                                              
10048	10068	9034	40559	5296	10068	041548751030        	D/E Fun Flavors Fdd Pkg 1.5q                                                                                                                                                                                                                              
10048	10068	9034	40559	5296	10068	041548751030        	D/E Fun Flavors Fdd Pkg 1.5q                                                                                                                                                                                                                              
10048	10050	9287	40559	5213	10050	041548007854        	D/E International Ice Cream 1.5q Sl6                                                                                                                                                                                                                      
10048	10050	9287	40559	5213	10050	041548007854        	D/E International Ice Cream 1.5q Sl6                                                                                                                                                                                                                      
10048	10068	9034	40559	5296	10068	041548751030        	D/E Fun Flavors Fdd Pkg 1.5q                                                                                                                                                                                                                              
10048	10068	9034	40559	5296	10068	041548751030        	D/E Fun Flavors Fdd Pkg 1.5q                                                                                                                                                                                                                              
10048	10068	9034	40559	5296	10068	041548751030        	D/E Fun Flavors Fdd Pkg 1.5q                                                                                                                                                                                                                              
10048	10068	9034	40559	5296	10068	041548751030        	D/E Fun Flavors Fdd Pkg 1.5q                                                                                                                                                                                                                              
10048	10050	9287	40559	5213	10050	041548007854        	D/E International Ice Cream 1.5q Sl6                                                                                                                                                                                                                      
10048	10050	9287	40559	5213	10050	041548007854        	D/E International Ice Cream 1.5q Sl6                                                                                                                                                                                                                      
10048	10068	9034	40559	5296	10068	041548751030        	D/E Fun Flavors Fdd Pkg 1.5q                                                                                                                                                                                                                              
10048	10050	9287	40559	5213	10050	041548007854        	D/E International Ice Cream 1.5q Sl6                                                                                                                                                                                                                      
10048	10050	9287	40559	5213	10050	041548007854        	D/E International Ice Cream 1.5q Sl6                                                                                                                                                                                                                      
10048	10050	9287	40559	5213	10050	041548007854        	D/E International Ice Cream 1.5q Sl6                                                                                                                                                                                                                      
10048	10050	9287	40559	5213	10050	041548007854        	D/E International Ice Cream 1.5q Sl6                                                                                                                                                                                                                      
10048	10050	9287	40559	5213	10050	041548007854        	D/E International Ice Cream 1.5q Sl6 




 select *
 from datatrue_edi.dbo.ProductsSuppliersItemsConversion
 where master <> 0 
 
 
 declare @rec cursor
declare @productid int
declare @masterglcode nvarchar(50)



set @rec = cursor local fast_forward for

	select productID--, count(distinct SupplierProductID)
	from datatrue_edi.dbo.ProductsSuppliersItemsConversion
	where SupplierName = 'NST'
	and productid <> 0
	and ProductID <> 8260
	group by productid
	having count(distinct SupplierProductID) > 1
	order by count(distinct SupplierProductID) desc

open @rec

fetch next from @rec into @productid

while @@fetch_status = 0
	begin
	
		select @productid
		
		select ltrim(rtrim(isnull(rawproductidentifier, ''))) as rawproductidentifier, isnull(comments, '') as comments, count(storetransactionid) as count
		into #tempGLData
		from storetransactions t
		where 1 = 1
		and t.ProductID = @productid
		and t.TransactionTypeID in (10,11)
		--and charindex('///', comments) < 0
		group by ltrim(rtrim(isnull(rawproductidentifier, ''))), isnull(comments, '') 
		order by count(storetransactionid) desc
	
		select *
		from #tempGLData t
		where 1 = 1
		order by count desc
			
		select top 1 ltrim(rtrim(isnull(rawproductidentifier, ''))) as masterglcode
		into #tempGLDatamaster
		from #tempGLData t
		where 1 = 1
		order by count desc
		
		set @masterglcode = null
		
		select @masterglcode = masterglcode
		from #tempGLDatamaster
		
		if @masterglcode is null
			print @productid
		
		update c set c.Master = 1
		from datatrue_edi.dbo.ProductsSuppliersItemsConversion c
		where 1 = 1
		and ProductId = @productid
		and SupplierProductID = @masterglcode
		drop table #tempGLData
		drop table #tempGLDatamaster
		
	
		fetch next from @rec into @productid	
	end
	
close @rec
deallocate @rec
   
drop table import.dbo.Storetransactions_Nestle_CountsBeforeGLCodeUpdate_20130205   

Select t.* into import.dbo.Storetransactions_Nestle_CountsBeforeGLCodeUpdate_20130205
   
from storetransactions t
where t.TransactiontypeID in (10, 11)
and t.supplierid = 40559

select count(*) from import.dbo.Storetransactions_Nestle_CountsBeforeGLCodeUpdate_20130205 --(581421)

drop table #tempGLC

select Distinct ProductID, SupplierProductID
into #tempGLC
from datatrue_edi.dbo.ProductsSuppliersItemsConversion
where master = 1
and SupplierName = 'NST'

Select t.GLCode, c.SupplierProductID,t.* --into import.dbo.Storetransactions_Nestle_CountsBeforeGLCodeUpdate_20130205
--update t set t.rawproductidentifier = ltrim(rtrim(c.SupplierProductID))
--update t set t.GLCode = cast(c.SupplierProductID as int)
--select count(storetransactionid)   
from #tempGLC c --datatrue_edi.dbo.ProductsSuppliersItemsConversion c 
--inner join #tempGLC t  
inner join temp_storetransactions t
on c.ProductID = t.ProductID
and cast(c.SupplierProductID as int) <> isnull(t.GLCode, 0)
--and t.TransactiontypeID in (10, 11)
--and t.supplierid = 40559
--and len(t.rawproductidentifier) < 1
--and t.rawproductidentifier is null
and ltrim(rtrim(ISNULL(t.rawproductidentifier, ''))) <> ltrim(rtrim(ISNULL(c.SupplierProductID, '')))

and ltrim(rtrim(ISNULL(t.rawproductidentifier, ''))) <> ltrim(rtrim(ISNULL(c.SupplierProductID, '')))
order by SupplierProductID
and c.Master = 1

Select t.rawproductidentifier, c.SupplierProductID, t.* --into import.dbo.Storetransactions_Nestle_CountsBeforeGLCodeUpdate_20130205
--update t set t.rawproductidentifier = ltrim(rtrim(c.SupplierProductID))
--select count(storetransactionid)   
from datatrue_edi.dbo.ProductsSuppliersItemsConversion c   
inner join temp_storetransactions t
on c.ProductID = t.ProductID
and t.TransactiontypeID in (10, 11)
and t.supplierid = 40559
and ltrim(rtrim(ISNULL(t.rawproductidentifier, ''))) <> ltrim(rtrim(ISNULL(c.SupplierProductID, '')))
order by t.rawproductidentifier
and c.Master = 1




select ltrim(rtrim(ISNULL(t.rawproductidentifier, ''))), ltrim(rtrim(ISNULL(c.SupplierProductID, ''))), *
--update t set t.rawproductidentifier = ltrim(rtrim(c.SupplierProductID)), t.comments = t.comments + '////' + ltrim(rtrim(c.SupplierProductID))
from datatrue_edi.dbo.ProductsSuppliersItemsConversion c
inner join storetransactions t
on c.ProductID = t.ProductID
and t.TransactionTypeID in (10,11)
and t.SupplierID = 40559
--and (t.rawproductidentifier is null or LEN(t.rawproductidentifier) < 1)
and ltrim(rtrim(ISNULL(t.rawproductidentifier, ''))) <> ltrim(rtrim(ISNULL(c.SupplierProductID, '')))
order by ltrim(rtrim(ISNULL(t.rawproductidentifier, '')))



select *
--update r set Settle = 'Y', ApprovingPersonID = 0, ApprovedDate = '2/6/2013', SettlementFinalized = 1
from inventorysettlementrequests r
where supplierid = 40559
and cast(requestdate as date) = '2/6/2013'
and Settle <> 'Pending'


CREATE NONCLUSTERED INDEX IX_temp_supplierid 
    ON dbo.temp_storetransactions (SupplierID)  
    
CREATE NONCLUSTERED INDEX IX_temp_glcode 
    ON dbo.temp_storetransactions (GLCode)  
    
CREATE NONCLUSTERED INDEX IX_temp_saledatetime 
    ON dbo.temp_storetransactions (saledatetime)  
    
    
alter table temp_storetransactions
add GLCodeUPC nvarchar(50) null  

alter table temp_storetransactions
add GLCodeProductID int null 

update d set d.GLCodeUPC = g.UPC12, d.GLCodeProductID = g.ProductID
--select *
from temp_storetransactions d
inner join import.dbo.NestleGlCodeUPC g
on d.GLCode = cast(g.SupplierProductID as int)
and d.transactiontypeid in (10, 11)
and g.Master = 1



/****** Script for SelectTopNRows command from SSMS  ******/
SELECT distinct [ID]
      ,[SupplierID]
      ,[ProductID]
      ,[SupplierProductID]
      ,[ProductIdentifier]
      ,[ProductName]
      ,[supplierName]
      ,[OurProductIdentifier]
  FROM [DataTrue_EDI].[dbo].[ProductsSuppliersItemsConversion]
  where 1 = 1
  and SupplierProductID = '12712'
  and ProductId <> 0
  --order by ProductIdentifier
  --and ProductID = 5227
  
   select supplierproductid, COUNT(distinct ProductIdentifier)
    FROM [DataTrue_EDI].[dbo].[ProductsSuppliersItemsConversion]
    where ProductID <> 0
    group by supplierproductid
    order by COUNT(distinct ProductIdentifier) desc 
  
  
  select productid, COUNT(supplierproductid)
    FROM [DataTrue_EDI].[dbo].[ProductsSuppliersItemsConversion]
    group by ProductID
    order by COUNT(supplierproductid) desc

select distinct w.upc
  from datatrue_archive.dbo.storetransactions_working w
  inner join [DataTrue_EDI].[dbo].[ProductsSuppliersItemsConversion] c
  on w.UPC = c.ProductIdentifier
  and c.SupplierProductID = '29050'
  and charindex('inv', w.WorkingSource) > 0
  and w.EDIName = 'NST'
  
 071921612412   
071921175047   
071921109103   

 select distinct w.workingsource
  from datatrue_archive.dbo.storetransactions_working w
  where 1 = 1
  and w.upc = '071921612412'
  
   select *
  from datatrue_archive.dbo.storetransactions_working w
  where 1 = 1
  and w.upc = '071921612412'
  and charindex('inv', w.WorkingSource) > 0   
  order by SaleDateTime
   
29050    Tmbs Double Top 12in 12ct          071921696092       
      
12751    Haagen Dazs Gelato 14oz             074570979103   

12751    Haagen Dazs Gelato 14oz             074570464593   

12751    Haagen Dazs Gelato 14oz             074570134007   

12751    Haagen Dazs Gelato 14oz             074570683864   

12751    Haagen Dazs Gelato 14oz             074570730575   

12751    Haagen Dazs Gelato 14oz             074570193462   

12751    Haagen Dazs Gelato 14oz             074570123728
   
    
  select *
  from datatrue_edi.dbo.productidentifiers 
  where CHARINDEX('074570979103', identifiervalue) > 0  
  
  select *
  from datatrue_archive.dbo.storetransactions_working
  where ProductID = 31011
  
  select productid as prd, *
  from MaintenanceRequests 
  where productid in (30760, 31010, 31011, 31012, 31019, 31020, 31026)
  order by productid
  
   select *
  from storetransactions
  where  productid in (30760, 31010, 31011, 31012, 31019, 31020, 31026)
  and TransactionTypeID = 11
  order by productid
    
  select *
  from datatrue_edi.dbo.Inbound846Inventory
  where EdiName = 'NST'
  and RawProductIdentifier = '12751'
  
  
  select upc, MIN(saledatetime)
  from datatrue_archive.dbo.storetransactions_working
  where 1 = 1
  and CHARINDEX('INV', WorkingSource) > 0
  group by upc
  order by MIN(saledatetime)
  
  select *
    FROM [DataTrue_EDI].[dbo].[ProductsSuppliersItemsConversion] c
    inner join datatrue_archive.dbo.storetransactions_working w
    on c.ProductIdentifier = w.upc
  
  
    select UPC, ProductID, SaleDateTime as SaleDate, *
  from datatrue_archive.dbo.storetransactions_working
  where 1 = 1
  and EDIName = 'NST'
  and CHARINDEX('INV', WorkingSource) > 0
  and RawProductIdentifier =  '12712'
  and CAST(SaleDateTime as date) >= '12/1/2011'
  order by saledatetime
  
  
  SELECT distinct ID, [SupplierID]
      ,[ProductID]
      ,[SupplierProductID]
      ,[ProductIdentifier]
      ,[ProductName]
      ,[supplierName]
      ,[OurProductIdentifier]
  FROM [DataTrue_EDI].[dbo].[ProductsSuppliersItemsConversion]
  where 1 = 1
  and SupplierProductID = '12712'
  
  
  select *
  from datatrue_archive.dbo.storetransactions_working
  where 1 = 1
  and EDIName = 'NST'
  and CHARINDEX('INV', WorkingSource) > 0
  and upc in
  (
  SELECT distinct [ProductIdentifier]
  FROM [DataTrue_EDI].[dbo].[ProductsSuppliersItemsConversion]
  where 1 = 1
  and SupplierProductID = '12712'
  and ProductId <> 0
  )
  order by saledatetime
  
  
      select UPC, ProductID, SaleDateTime as SaleDate, *
  from datatrue_archive.dbo.storetransactions_working
  where 1 = 1
  and EDIName = 'NST'
  and CHARINDEX('INV', WorkingSource) > 0
  --and RawProductIdentifier =  '12712'
  and CAST(SaleDateTime as date) >= '12/1/2011'
  --and WorkingStatus <> 5
  order by saledatetime
  
  
  SELECT distinct [ID]
      ,[SupplierID]
      ,[ProductID]
      ,[SupplierProductID]
      ,[ProductIdentifier]
      ,[ProductName]
      ,[supplierName]
      ,[OurProductIdentifier]
  FROM [DataTrue_EDI].[dbo].[ProductsSuppliersItemsConversion]
  where 1 = 1
  and SupplierProductID = '12712'
  and ProductId <> 0                                                                                                                                                                                                    
*/


END
GO
