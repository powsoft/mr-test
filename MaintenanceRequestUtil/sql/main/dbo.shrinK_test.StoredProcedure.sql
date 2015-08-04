USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[shrinK_test]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[shrinK_test]
	
as
Begin

-- Remove the zero count records being created for new store/products by some unknown process.
-- Commeneted the following statement after disabling the InventorySettlementRequests_MissingInitializations_Insert job 
--that was creating zero records in Settlement Table.
--Delete I
--from InventorySettlementRequests I
--where 1=1 and RequestingPersonID=0 and ApprovingPersonID=0 and Settle='Y' and [Shrink$] is null
--and I.DateTimeCreated > isnull((Select max(t.PhysicalInventoryDate) from InventorySettlementRequests t 
--						 where t.StoreID=i.StoreID and t.SupplierID=i.supplierId and t.retailerId=i.retailerId
--						 and RequestingPersonID>0),'01/01/2012')
						 
-- Check for Stores/Products that don't have last settlement date in InventorySettlementRequests Table
--Step 1: Getting the Products with Min Sale Date (1:50 Mins)
if OBJECT_ID('tempdb..#tmpStoreProducts') IS NOT NULL DROP TABLE #tmpStoreProducts

SELECT S.ChainId, S.SupplierId, S.StoreId, S.ProductId, S1.BiDate as BIDate
into #tmpStoreProducts
from 
		(select S.ChainId, S.SupplierId, S.StoreId, S.ProductId
		 from
		 StoreTransactions S with (nolock)
		 group by S.ChainId, S.SupplierId, S.StoreId, S.ProductId
		 )s 
inner join (Select S.ChainId, S.supplierId, S.StoreID, MIN(S.SaleDateTime) as BiDate 
            from StoreTransactions S with (nolock,index(4))
            where TransactionTypeID in (10,11)
            group by S.ChainID, S.SupplierId, S.StoreID
            ) S1 
on S1.ChainID=S.ChainID and S1.SupplierID=S.SupplierID and S1.StoreID=S.StoreID
Left join (Select distinct RetailerId, SupplierId, StoreId, ProductId from InventorySettlementRequests I with (nolock)) I on I.retailerId=S.ChainID and I.supplierId=S.SupplierId and I.StoreID=S.StoreID and I.ProductID=S.ProductID
where I.ProductID is null 
and S.SupplierId in (Select distinct SupplierId from SharedShrinkTerms)

--last settelment date (18 Secs)
if OBJECT_ID('tempdb..#tmpLSD') IS NOT NULL DROP TABLE #TMPLSD
SELECT retailerId, StoreID, Settle, MAX(PhysicalInventoryDate) AS LastSettlementDate, supplierId, UPC, ProductID
Into #tmpLSD
FROM         dbo.InventorySettlementRequests with (nolock)
where 1 = 1 and supplierId > 0 and  (Settle <>'Pending' )
GROUP BY retailerId, StoreID, Settle, supplierId, UPC, ProductID

Union All
select distinct t.ChainID, t.StoreID, 'Y', t.BIDate, t.SupplierID, P.IdentifierValue as UPC, t.ProductID
from ProductIdentifiers P 
join #tmpStoreProducts t on P.ProductID=t.ProductID and P.ProductIdentifierTypeID=2
where t.ChainID>0 and t.SupplierId>0
		
-- update the last settlementdate for Products to max settlement date for Store (2 Sec)
Update t set t.LastSettlementDate= i.PhysicalInventoryDate
	from #tmpLSD t 
	join (select retailerId, supplierId, StoreID, MAX(PhysicalInventoryDate) as PhysicalInventoryDate
			from InventorySettlementRequests 
			where  (Settle <>'Pending' )
			group by retailerId,supplierId,StoreID
	) i on t.StoreID=i.StoreID and t.SupplierID=i.supplierId and t.retailerId=i.retailerId

--select * from #tmpLSD where UPC ='048121102081' and StoreID=40513

--Get Last Settlment UnitCount (from Store Transactions) -- 42 secs
if OBJECT_ID('tempdb..#tmpLS_FactTable') IS NOT NULL DROP TABLE #tmpLS_FactTable
SELECT distinct LSD.retailerId, LSD.supplierId, LSD.StoreID, LSD.LastSettlementDate, isnull(IC.SaleDateTime, LSD.LastSettlementDate) as InventoryCountDate,
  					 0 as LS_TTLQnt, convert(money,0) AS LS_TTLCost,
                      LSD.UPC, LSD.ProductId
into #tmpLS_FactTable
FROM         #tmpLSD LSD 
LEFT OUTER JOIN (Select IC.ChainId, IC.SupplierId, IC.StoreId, IC.ProductId, max(SaleDateTime) as SaleDateTime
					 from dbo.StoreTransactions IC WITH (NOLOCK) 
					 left join #tmpLSD LSD on LSD.StoreID = IC.StoreID AND 
						  LSD.supplierId = IC.SupplierID AND 
						  IC.SaleDateTime <= LSD.LastSettlementDate  AND 
						  LSD.ProductID = IC.ProductID AND
						  LSD.retailerId=IC.ChainId
						  WHERE     (LSD.LastSettlementDate >= CONVERT(DATETIME, '2011-11-30 00:00:00', 102)) and ic.TransactionTypeID in(10,11)
					group by IC.ChainId, IC.SupplierId, IC.StoreId, IC.ProductId
                     ) IC ON 
						  LSD.retailerId = IC.ChainID AND
						  LSD.StoreID = IC.StoreID AND 
						  LSD.supplierId = IC.SupplierID AND 
						  IC.SaleDateTime <= LSD.LastSettlementDate  AND 
						  LSD.ProductID = IC.ProductID 


update LSD set LS_TTLQnt=ISNULL(IC.qty, 0), LS_TTLCost=ISNULL(IC.Qty*(ic.rulecost-isnull(ic.PromoAllowance,0)), 0) 
from #tmpLS_FactTable LSD 
Left Join (Select distinct IC.ChainID, IC.SupplierId, IC.StoreId, IC.Productid, LSD.LastSettlementDate, Qty, IC.RuleCost, IC.PromoAllowance
			from dbo.StoreTransactions IC WITH (NOLOCK) 
			inner join #tmpLS_FactTable LSD  on LSD.StoreID = IC.StoreID AND IC.ChainID=LSD.retailerId AND
			LSD.supplierId = IC.SupplierID AND LSD.ProductID = IC.ProductID And
			IC.SaleDateTime =LSD.LastSettlementDate 
			where TransactionTypeID in (10,11) and Qty>0
		) IC on LSD.StoreID = IC.StoreID AND LSD.supplierId = IC.SupplierID and IC.ChainID=LSD.retailerId
		AND LSD.ProductID = IC.ProductID and LSD.LastSettlementDate = IC.LastSettlementDate
   option (hash join,hash group)
   
 
   
   

Update LSD set LS_TTLQnt=LS_TTLQnt-isnull(IC.SaleQty,0)+isnull(IC.DeliveryQty,0), LS_TTLCost=LS_TTLCost-isnull(IC.SaleCost,0)+ isnull(IC.DeliveryCost,0)
from #tmpLS_FactTable LSD 
Left Join (Select IC.ChainID, IC.SupplierId, IC.StoreId, IC.Productid, LSD.LastSettlementDate, 
			Sum(case buckettype when 1 then Qty* TT.QtySign else 0 end) as SaleQty,
			SUM(case buckettype when 1 then ISNULL(IC.Qty*(ic.rulecost-isnull(ic.PromoAllowance,0)), 0) else 0 end) as SaleCost,
			Sum(case buckettype when 2 then Qty* TT.QtySign else 0 end) as DeliveryQty,
			SUM(case buckettype when 2 then ISNULL(IC.Qty*(ic.rulecost-isnull(ic.PromoAllowance,0)), 0) else 0 end) as DeliveryCost
			from dbo.StoreTransactions IC WITH (NOLOCK) 
			inner join dbo.TransactionTypes TT with(nolock) on TT.TransactionTypeId=IC.TransactionTypeId
			inner join #tmpLS_FactTable LSD  on LSD.StoreID = IC.StoreID AND 
			LSD.supplierId = IC.SupplierID AND LSD.ProductID = IC.ProductID And LSD.retailerId=IC.ChainID AND
			IC.SaleDateTime  between LSD.InventoryCountDate AND LSD.LastSettlementDate 
			where IC.TransactionTypeId in (2, 6, 7, 16,  5, 8, 9, 14, 20, 21) and LSD.InventoryCountDate < LSD.LastSettlementDate
			group by IC.ChainID, IC.SupplierId, IC.StoreId, IC.Productid, LSD.LastSettlementDate
		) IC on LSD.StoreID = IC.StoreID AND LSD.supplierId = IC.SupplierID AND LSD.retailerId=IC.ChainID 
		AND LSD.ProductID = IC.ProductID and LSD.LastSettlementDate = IC.LastSettlementDate
   option (hash join,hash group)
 ----------------------------------------------------

--select * from(
--select *,'new' as version from #tmpLS_FactTable2
--except
--select *,'new' from #tmpLS_FactTable
--union all
--select *,'old' from #tmpLS_FactTable
--except
--select *,'old' from #tmpLS_FactTable2)x
--order by retailerid,SupplierID,storeid,productid,version







	--Clean the main table
	truncate table nik_test
	
	insert Into nik_test with (tablock)
		([SupplierName], [ChainName], [StoreNo], [SupplierAcctNo], [Banner], [LastInventoryCountDate], [LastSettlementDate], [UPC]
		, [BI Count], [BI$], [Net Deliveries], [Net Deliveries$], [Net POS], [POS$], [Expected EI], [Expected EI$]
		, [LastCountQty], [LastCount$], [ShrinkUnits], [Shrink$], [SupplierID], [ChainID], [StoreID], [ProductID], [SupplierUniqueProductID]
		, [NetUnitCostLastCountDate], [BaseCostLastCountDate], [WeightedAvgCost], [SharedShrinkUnits], [Settle], [GLCode], [RuleRetail], [RouteNo])
      
	SELECT     SP.SupplierName, dbo.Chains.ChainName, ST.StoreIdentifier AS StoreNo, NULL AS SupplierAcctNo, 
						  ST.Custom1 AS Banner, CONVERT(varchar, s.SaleDateTime, 101) AS LastInventoryCountDate, CONVERT(varchar, 
						  LSFT.LastSettlementDate , 101) AS LastSettlementDate, s.UPC, 
						  LSFT.LS_TTLQnt  AS [BI Count], LSFT.LS_TTLCost AS BI$, NULL 
						  AS [Net Deliveries], NULL AS [Net Deliveries$], NULL AS [Net POS], NULL AS POS$, NULL AS [Expected EI], NULL AS [Expected EI$], 
						  SUM(s.Qty) AS LastCountQty, SUM(s.Qty * (ISNULL(s.RuleCost,0) - ISNULL(s.PromoAllowance, 0))) AS LastCount$, 
						  NULL AS ShrinkUnits, NULL AS Shrink$, 
						  s.SupplierID, dbo.Chains.ChainID, s.StoreID, s.ProductID, NULL AS SupplierUniqueProductID, 
						  NULL AS LastCountCost, NULL AS LastCountBaseCost, null AS WeightedAvgCost, Null AS SharedShrinkUnits, Null as Settle, Null as GLCode, s.RuleRetail, Null as RouteNo 

	FROM dbo.StoreTransactions S with (nolock) 
	INNER JOIN Stores ST ON s.StoreID = ST.StoreID and ST.ChainID=S.ChainID
	INNER JOIN Chains ON s.ChainID = dbo.Chains.ChainID 
	INNER JOIN Suppliers  SP ON s.SupplierID = SP.SupplierID 
	--Inner join SharedShrinkTerms SST on SSt.ChainID=S.ChainID and SST.SupplierID=S.SupplierID
	LEFT OUTER JOIN #tmpLS_FactTable  LSFT ON s.SupplierID = LSFT.SupplierID AND 
						  s.StoreID = LSFT.StoreID AND s.ProductID = LSFT.ProductID and S.ChainID=LSFT.retailerId
	WHERE  (s.TransactionTypeID IN (11, 10)) AND (s.SaleDateTime > ISNULL(LSFT.LastSettlementDate,CONVERT(DATETIME, '2000-01-01 00:00:00', 102)))
	GROUP BY s.SupplierID, s.StoreID, s.UPC, CONVERT(varchar, s.SaleDateTime, 101), CONVERT(varchar, 
						  LSFT.LastSettlementDate , 101), LSFT.LS_TTLCost, 
						  LSFT.LS_TTLQnt , s.ProductID, SP.SupplierName, dbo.Chains.ChainID, dbo.Chains.ChainName, 
						  ST.StoreIdentifier, ST.Custom1, s.RuleRetail
	
	
	--select COUNT(*) from nik_test where LastSettlementDate is null and UPC ='048121102081' and StoreID=40513
	
	-- Update Null Last Settlement Dates of Products that were not settled during the last settlement date where other products within the same supplier and store got settled
 	--select distinct SupplierID, StoreID, LastSettlementDate into #t1 from  nik_test where LastSettlementDate is not null
	--select distinct SupplierID, StoreID, UPC, LastSettlementDate into #t2  from  nik_test where LastSettlementDate is null
	
	--select #t2.*, #t1.LastSettlementDate as datetoupdate into #t3 from  #t1
	--inner join #t2 on #t1.SupplierID=#t2.SupplierID  and #t1.StoreID=#t2.StoreID 
		
	--update i
	--set LastSettlementDate = #t3.datetoupdate
	--from nik_test i
	--inner join #t3 on #t3.SupplierID=i.SupplierID and #t3.StoreID=i.StoreID and #t3.UPC=i.UPC

	--select distinct I1.SupplierID, I1.StoreID, I1.LastSettlementDate, I2.LastSettlementDate 
	
	--create clustered index ix_supprod_nik_test on [nik_test] (storeid,supplierid,productid)
    --with (maxdop=0,sort_in_tempdb=on,fillfactor=100,drop_existing=on)

	update nik_test
	set PreviousInventoryCountDate=(select MAX(LastInventoryCountDate) from
									nik_test i where
									i.productid=nik_test.ProductID and
									nik_test.SupplierID=i.SupplierID and
									nik_test.StoreID=i.StoreID and
									i.LastInventoryCountDate<nik_test.LastInventoryCountDate)
								 
	Update I1 set I1.LastSettlementDate=I2.LastSettlementDate
	from nik_test I1
	inner join (Select distinct ChainId, SupplierId, StoreId, MAX(LastSettlementDate) as LastSettlementDate
				 from nik_test 
				 where LastSettlementDate is not null
				 group by ChainId, SupplierID, StoreID
				) as I2 on I1.SupplierID=I2.SupplierID and I1.StoreID=I2.StoreID and I1.ChainID=I2.ChainID
	Where I1.LastSettlementDate is null				
	
	update nik_test
	set PreviousInventoryCountDate=LastSettlementDate
	where PreviousInventoryCountDate is null
	
	delete from nik_test where SupplierID not in (41464, 40562,40557, 40559,40561,40567,62596, 50721, 74796)
	--select * from nik_test where  UPC ='048121102081' and StoreID=40513
	--select COUNT(*) from nik_test where LastSettlementDate is not null
	

--UPDATE STATISTICS nik_test WITH COLUMNS

--DeliveriesRecords (36 mins)
if OBJECT_ID('tmpdeliveries') IS NOT NULL DROP TABLE tmpdeliveries

SELECT     SUM(s.Qty* TT.QtySign) AS NetDeliveries, SUM((s.Qty* TT.QtySign) * (ISNULL(s.RuleCost,0) 
                      - ISNULL(s.PromoAllowance, 0))) AS NetDeliveries$, FA.PreviousInventoryCountDate, 
                      FA.LastInventoryCountDate, FA.UPC, ST.StoreIdentifier AS StoreNumber, s.StoreID, 
                      s.ProductID, s.SupplierID, s.ChainID
into tmpdeliveries                      
FROM         dbo.nik_test FA with (nolock)
			 INNER JOIN dbo.stores st on st.storeid = fa.storeid and st.ChainID=fa.ChainID
			 INNER JOIN dbo.InventoryRulesTimesBySupplierID IRS ON FA.SupplierID = IRS.SupplierID AND FA.ChainID = IRS.ChainID --and (IRS.InventoryTakenBeforeDeliveries = 1) 
			 inner join
				dbo.StoreTransactions s WITH (NOLOCK) ON FA.ProductID = s.ProductID AND
                       FA.StoreID = s.StoreID AND FA.SupplierID = s.SupplierID and FA.ChainID=S.ChainID           
                      and 
	--                Cast(s.SaleDateTime as date)>=

	--                Case IRS.InventoryTakenBeforeDeliveries when 1
	--				  then
	--						Cast(ISNULL(FA.LastSettlementDate,  '2011-12-01 00:00:00') as date)
	--                else
	--						(DATEADD(d,1,CAST(ISNULL( FA.LastSettlementDate, '2011-12-01 00:00:00') as date)))  
	--                end
      
                      Cast(s.SaleDateTime as date)>=
                      
					  Case IRS.InventoryTakenBeforeDeliveries when 1
					  then
							Cast(ISNULL(FA.PreviousInventoryCountDate,  '2011-12-01 00:00:00') as date)
					  else
							(DATEADD(d,1,CAST(ISNULL( FA.PreviousInventoryCountDate, '2011-12-01 00:00:00') as date)))  
					  end
					  
					  and Cast(s.SaleDateTime as date)<
					  Case IRS.InventoryTakenBeforeDeliveries when 1 then 
							CAST(FA.LastInventoryCountDate as date)
					  else 
							Cast(DATEADD(d,1,FA.LastInventoryCountDate)as date) 
					  end
				      
             inner join
              dbo.TransactionTypes TT on TT.TransactionTypeID = s.TransactionTypeID and (s.TransactionTypeId in (5, 8, 9, 14, 20, 21))

GROUP BY FA.PreviousInventoryCountDate, FA.LastInventoryCountDate, FA.UPC, 
 ST.StoreIdentifier, s.StoreID, s.ProductID, s.SupplierID, s.ChainID

;with t as (	select a.StoreID, a.ProductID, a.SupplierID, a.ChainID,
				a.LastInventoryCountDate, SUM(b.NetDeliveries) as NetDeliveries, SUM(b.NetDeliveries$) as NetDeliveries$
				from tmpdeliveries a
				join tmpdeliveries b on a.StoreID=b.storeid and a.ProductID=b.productid and a.SupplierID=b.supplierid and a.ChainID=b.chainid 
				and a.LastInventoryCountDate >= b.LastInventoryCountDate
				group by a.StoreID, a.ProductID, a.SupplierID, a.ChainID, a.LastInventoryCountDate
			)
			
update tmpdeliveries set NetDeliveries=t.NetDeliveries, NetDeliveries$=t.NetDeliveries$
from tmpdeliveries
join t on tmpdeliveries.StoreID=t.storeid and tmpdeliveries.ProductID=t.productid and tmpdeliveries.SupplierID=t.supplierid and tmpdeliveries.ChainID=t.chainid
and tmpdeliveries.LastInventoryCountDate=t.LastInventoryCountDate

---------------------------------------------------------------
---------------------------------------------------------------
select *,
	(select coalesce(min(lastinventorycountdate),'2199-12-31') from tmpdeliveries t2 where t2.ProductID=t.ProductID and t2.StoreID=t.StoreID and t2.SupplierID=t.SupplierID and t2.LastInventoryCountDate>t.LastInventoryCountDate)NextCountDate
		into #DELIVERIESFIX		 
			from tmpdeliveries t

insert tmpdeliveries with(tablockx)(NetDeliveries,NetDeliveries$,PreviousInventoryCountDate,LastInventoryCountDate,UPC,StoreNumber,StoreID,ProductID,SupplierID,ChainID)
select l.NetDeliveries,l.NetDeliveries$,i.PreviousInventoryCountDate,i.LastInventoryCountDate,l.UPC,l.storenumber,l.StoreID,l.ProductID,l.SupplierID,l.ChainID
from #DELIVERIESFIX	 l 
join nik_test i
on l.StoreID=i.StoreID and l.ProductID=i.ProductID and l.SupplierID=i.SupplierID
and i.LastInventoryCountDate >l.LastInventoryCountDate 
and i.LastInventoryCountDate < l.NextCountDate

drop table #DELIVERIESFIX	
----------------------------------------------------------------
----------------------------------------------------------------



Update I set I.[Net Deliveries]= isnull(a.NetDeliveries,0), I.[Net Deliveries$]=isnull(a.NetDeliveries$,0)   
from nik_test I
inner join tmpdeliveries A on I.storeid = a.storeid
	and I.ChainID = a.ChainID
	and I.supplierid = a.supplierid	
	and I.ProductID  = a.productid
	and I.LastInventoryCountDate =a.LastInventoryCountDate
	and I.PreviousInventoryCountDate   =a.PreviousInventoryCountDate  

--POS SALES Records (28:56)
if OBJECT_ID('tmpPOS') IS NOT NULL DROP TABLE tmpPOS

SELECT     SUM(s.Qty* TT.QtySign) AS NetPOS, SUM((s.Qty* TT.QtySign) * (ISNULL(s.RuleCost,0) 
                      - ISNULL(s.PromoAllowance, 0))) AS NetPOS$, FA.PreviousInventoryCountDate, 
                      FA.LastInventoryCountDate, FA.UPC, ST.StoreIdentifier AS StoreNumber, s.StoreID, 
                      s.ProductID, s.SupplierID, s.ChainID
into tmpPOS                      
FROM         dbo.nik_test FA with (nolock)
			 INNER JOIN dbo.stores st on st.storeid = fa.storeid and st.ChainID=fa.ChainID
			 INNER JOIN dbo.InventoryRulesTimesBySupplierID IRS ON FA.SupplierID = IRS.SupplierID AND FA.ChainID = IRS.ChainID --and (IRS.InventoryTakenBeforeDeliveries = 1) 
			 inner join
				dbo.StoreTransactions s WITH (NOLOCK) ON FA.ProductID = s.ProductID AND
                       FA.StoreID = s.StoreID AND FA.SupplierID = s.SupplierID  AND FA.ChainID=s.ChainID and 
    --                Cast(s.SaleDateTime as date)>=

	--                Case IRS.InventoryTakenBeforeDeliveries when 1
	--				  then
	--						Cast(ISNULL(FA.LastSettlementDate,  '2011-12-01 00:00:00') as date)
	--                else
	--						(DATEADD(d,1,CAST(ISNULL( FA.LastSettlementDate, '2011-12-01 00:00:00') as date)))  
	--                end
      
                      Cast(s.SaleDateTime as date)>=
                      
					  Case IRS.InventoryTakenBeforeDeliveries when 1
					  then
							Cast(ISNULL(FA.PreviousInventoryCountDate,  '2011-12-01 00:00:00') as date)
					  else
							(DATEADD(d,1,CAST(ISNULL( FA.PreviousInventoryCountDate, '2011-12-01 00:00:00') as date)))  
					  end
					  
					  and Cast(s.SaleDateTime as date)<
					  Case IRS.InventoryTakenBeforeDeliveries when 1 then 
							CAST(FA.LastInventoryCountDate as date)
					  else 
							Cast(DATEADD(d,1,FA.LastInventoryCountDate)as date) 
					  end

             inner join
              dbo.TransactionTypes TT on TT.TransactionTypeID = s.TransactionTypeID and (s.TransactionTypeId in (2, 6, 7, 16))

GROUP BY FA.PreviousInventoryCountDate, FA.LastInventoryCountDate, FA.UPC, 
                      ST.StoreIdentifier, s.StoreID, s.ProductID, s.SupplierID, s.ChainID

;with t as (	select a.StoreID, a.ProductID, a.SupplierID, a.ChainID,
				a.LastInventoryCountDate, SUM(b.NetPOS) as NetPOS, SUM(b.NetPOS$) as NetPOS$
				from tmpPOS a
				join tmpPOS b on a.StoreID=b.storeid and a.ProductID=b.productid and a.SupplierID=b.supplierid and a.ChainID=b.chainid 
				and a.LastInventoryCountDate >= b.LastInventoryCountDate
				group by a.StoreID, a.ProductID, a.SupplierID, a.ChainID, a.LastInventoryCountDate
			)
			
update tmpPOS set NetPOS=isnull(t.NetPOS,0), NetPOS$=isnull(t.NetPOS$,0)
from tmpPOS
join t on tmpPOS.StoreID=t.storeid and tmpPOS.ProductID=t.productid and tmpPOS.SupplierID=t.supplierid and tmpPOS.ChainID=t.chainid 
and tmpPOS.LastInventoryCountDate=t.LastInventoryCountDate
                  
---------------------------------------------------------------
---------------------------------------------------------------
select *,
	(select coalesce(min(lastinventorycountdate),'2199-12-31') from tmpPOS t2 where t2.ProductID=t.ProductID and t2.StoreID=t.StoreID and t2.SupplierID=t.SupplierID and t2.LastInventoryCountDate>t.LastInventoryCountDate)NextCountDate
		into #POSFIX		 
			from tmpPOS t

insert tmpPOS with(tablockx)(NetPOS,NetPOS$,PreviousInventoryCountDate,LastInventoryCountDate,UPC,StoreNumber,StoreID,ProductID,SupplierID,ChainID)
select l.NetPOS,l.NetPOS$,i.PreviousInventoryCountDate,i.LastInventoryCountDate,l.UPC,l.storenumber,l.StoreID,l.ProductID,l.SupplierID,l.ChainID
from #POSFIX l 
join nik_test i
on l.StoreID=i.StoreID and l.ProductID=i.ProductID and l.SupplierID=i.SupplierID
and i.LastInventoryCountDate >l.LastInventoryCountDate 
and i.LastInventoryCountDate < l.NextCountDate

drop table #POSFIX
----------------------------------------------------------------
----------------------------------------------------------------



--update POS (0:50)

Update I set I.[Net POS] =a.NetPOS, I.POS$=a.NetPOS$, I.WeightedAvgCost=a.NetPOS$/a.NetPOS 
from nik_test I 
inner join tmpPOS A on I.storeid = a.storeid
	and I.ChainID = a.ChainID
	and I.supplierid = a.supplierid	
	and I.ProductID  = a.productid
	and I.LastInventoryCountDate = a.LastInventoryCountDate
	and I.PreviousInventoryCountDate = a.PreviousInventoryCountDate  
	and a.NetPOS <>0

		
--update SupplierUniqueAccounttNumber (0:11)

Update I set I.SupplierAcctNo =a.SupplierAccountNumber 
from nik_test I 
inner join StoresUniqueValues A on I.storeid = a.storeid and I.supplierid = a.supplierid	

--update SupplierUniqueProductNumber (0:01)

Update I set I.SupplierUniqueProductID =a.IdentifierValue 
from nik_test I
inner join ProductIdentifiers A on I.SupplierId = a.OwnerEntityId and I.ProductID = a.ProductID	
where a.ProductIdentifierTypeID=3


--update Null values to Zero , (0:13)

update nik_test 
set [Net Deliveries] =ISNULL([Net Deliveries] ,0),[Net Deliveries$] =ISNULL([Net Deliveries$],0),[Net POS]=ISNULL([Net POS],0),POS$ =ISNULL(POS$  ,0)
where [Net Deliveries] is null or [Net Deliveries$] is null or [net pos] is null or POS$ is null

--Next update added 4/19/2012 by charlie and Mandeep to manage Lewis lastsettlement date to 12/10/2011 (00:01)
update nik_test 
set [BI Count] =ISNULL([BI Count] ,0),BI$ =ISNULL(BI$,0), LastSettlementDate =isnull(LastSettlementDate,'12/10/2011')
where (ChainID =40393 and SupplierID  = 41464) and ([BI Count] is null or BI$ is null or LastSettlementDate is null)

--do not update Bimbo (40557)  Last Settlment Date to 12/1/2011 becuase they have multiple initialization dates based on banners
update nik_test 
set [BI Count] =ISNULL([BI Count] ,0),BI$ =ISNULL(BI$,0), LastSettlementDate =isnull(LastSettlementDate,'12/1/2011')
where (ChainID =40393 and SupplierID  <> 40557)  or (ChainID =40393 and SupplierID  = 40557 and Banner not like 'Farm Fresh Markets')

--update Bimbo (40557)  Last Settlment Date to 1/2/2012 (for Farm Fresh) becuase they have multiple initialization dates based on banners
update nik_test 
set [BI Count] =ISNULL([BI Count] ,0),BI$ =ISNULL(BI$,0), LastSettlementDate =isnull(LastSettlementDate,'1/2/2012')
where ChainID =40393 and SupplierID  = 40557 and Banner = 'Farm Fresh Markets'


--update EI , (0:35)

update nik_test
set [Expected EI]=[BI Count]-[Net POS]+[Net Deliveries],[Expected EI$]=BI$-POS$+[Net Deliveries$]
	
--update ShrinkUnits (0:39)
update nik_test
set 	ShrinkUnits =[Expected EI]-LastCountQty,Shrink$=[Expected EI$]-LastCount$ 
where LastCountQty =0

update nik_test
set 	ShrinkUnits =[Expected EI]-LastCountQty,Shrink$=(LastCount$/LastCountQty )*([Expected EI]-LastCountQty )
where LastCountQty <>0

--Final Clean Up
Delete  from nik_test
where LastSettlementDate  is null and LastCountQty =0 and [Net Deliveries] =0

                
--Update UnitCost at LastCountDate	(1:18)
		update f set f. NetUnitCostLastCountDate = s.NetCost, f.BaseCostLastCountDate=s.basecost 
		from nik_test f
		inner join
		(select i.ChainId, i.ProductID ,i.StoreID,i.SupplierID, i.LastInventoryCountDate  ,p3.UnitPrice-ISNULL(p8.unitprice,0) as NetCost, p3.UnitPrice as basecost
		from nik_test I
		 inner join ProductPrices p3 on p3.ChainID=i.ChainID and p3.ProductID=i.ProductID  and p3.StoreID =i.StoreID and p3.SupplierID =i.SupplierID and p3.ProductPriceTypeID =3 
		 left join ProductPrices P8 on  p3.ChainID=P8.ChainID and p3.ProductID=p8.ProductID  and p3.SupplierID =p8.SupplierID and p3.StoreID =p8.StoreID
					and p3.ActiveStartDate <=p8.ActiveStartDate and p8.ActiveLastDate <=p3.ActiveLastDate 	 and p8.ProductPriceTypeID =8 
					and i.LastInventoryCountDate between p8.ActiveStartDate  and p8.ActiveLastDate 
			 
		 where  i.LastInventoryCountDate between p3.ActiveStartDate  and p3.ActiveLastDate  ) s
		 on f.ProductID = s.ProductID
		 and f.StoreID = s.StoreID
		 and f.ChainID = s.ChainID
		 and f.SupplierID = s.SupplierID
		 and f.LastInventoryCountDate = s.LastInventoryCountDate
	

--Fix Null value in Base Cost that are Null becuase no POS activity was recorded. 08/20/2012

	update nik_test set BaseCostLastCountDate=POS$/[Net POS]
	where BaseCostLastCountDate is null and isnull(POS$,0) <>0 and isnull([Net POS],0) <>0
	
	update nik_test set BaseCostLastCountDate=[Net Deliveries$]/[Net Deliveries]
	where BaseCostLastCountDate is null and isnull([Net Deliveries],0) <>0 and isnull([Net Deliveries$],0) <>0
	
	update nik_test set BaseCostLastCountDate= BI$/[BI Count]
	where BaseCostLastCountDate is null and isnull([BI Count],0) <>0 and isnull(BI$,0) <>0

	update nik_test set BaseCostLastCountDate= 0
	where BaseCostLastCountDate is null and ShrinkUnits<>0


--update POS, Deliveries and BI to be calculated based on the most recent BASE unit cost (0:38)
update f
set [Net Deliveries$] = s.Deliveries$, [Expected EI$]=s.Expected$ , [POS$]=s.POS$,[BI$]=s.BI$ ,[Shrink$]=s.Shrink$, [lastcount$]=s.lastcount$ 
from nik_test f
inner join
(select i.ChainID, i.SupplierID, i.ProductID,i.StoreID,i.LastInventoryCountDate, 
i.[Net Deliveries]*i.BaseCostLastCountDate  as Deliveries$, 
i.[Expected EI]*i.BaseCostLastCountDate as Expected$,
i.[BI Count]*i.BaseCostLastCountDate as BI$,
i.[Net POS] *i.BaseCostLastCountDate  as POS$,
i.ShrinkUnits *i.BaseCostLastCountDate as Shrink$,
i.LastCountQty *i.BaseCostLastCountDate as LastCount$

 from nik_test  i where BaseCostLastCountDate is not null) s
 
 on f.SupplierID=s.SupplierID
		 and f.ProductID = s.ProductID
		 and f.StoreID = s.StoreID
		 and f.ChainID = s.ChainID
		 and f.LastInventoryCountDate = s.LastInventoryCountDate
		
		 

--Fix Null value in Weighted Avg Cost that are Null becuase no POS activity was recorded. 08/16/2012
    update nik_test set WeightedAvgCost=Shrink$/ShrinkUnits
	where WeightedAvgCost is null and isnull(ShrinkUnits,0) <>0 and isnull(Shrink$,0) <>0
	
	update nik_test set WeightedAvgCost=[Net Deliveries$]/[Net Deliveries]
	where WeightedAvgCost is null and isnull([Net Deliveries],0) <>0 and isnull([Net Deliveries$],0) <>0
	
	update nik_test set WeightedAvgCost=POS$/[Net POS]
	where WeightedAvgCost is null and isnull(POS$,0) <>0 and isnull([Net POS],0) <>0
	
	update nik_test set WeightedAvgCost=[Expected EI$]/[Expected EI]
	where WeightedAvgCost is null and isnull([Expected EI$],0) <>0 and isnull([Expected EI],0) <>0

	
--ADDED 4/26/2012--update POS, Deliveries and BI to be calculated based on the most recent WEIGHTED AVG unit cost (ONLY for records that there WeightCost >0) (0:28)
update f
set [Net Deliveries$] = s.Deliveries$, [Expected EI$]=s.Expected$ , [POS$]=s.POS$,[BI$]=s.BI$ ,[Shrink$]=s.Shrink$, [lastcount$]=s.lastcount$ 
from nik_test f
inner join
(select i.ChainId, i.SupplierID,i.ProductID,i.StoreID,i.LastInventoryCountDate, 
i.[Net Deliveries]*i.WeightedAvgCost  as Deliveries$, 
i.[Expected EI]*i.WeightedAvgCost as Expected$,
i.[BI Count]*i.WeightedAvgCost as BI$,
i.[Net POS] *i.WeightedAvgCost  as POS$,
i.ShrinkUnits *i.WeightedAvgCost as Shrink$,
i.LastCountQty *i.WeightedAvgCost as LastCount$

 from nik_test  i ) s
 
 on f.SupplierID =s.SupplierID
		 and f.ProductID = s.ProductID
		 and f.StoreID = s.StoreID
		 and f.ChainID = s.ChainID
		 and f.LastInventoryCountDate = s.LastInventoryCountDate
		 and f.WeightedAvgCost>0
where f.SupplierID <>40562 --Condition added by Vishal on 8/22 to skip Shrink $ calculation based on weighted Avg Cost. (FB: 14636)


-- added by Vishal on 10/18/13 to update Route Nos in Inventory Fact Table (0:57)
update A set RouteNo=ISNULL(S.Route, V.RouteNumber) 
from nik_test A with(nolock)
inner join (select distinct ChainId, SupplierId, StoreId, max(SaleDateTime) as SaleDateTime, max(Route) as Route
				from dbo.StoreTransactions S with(nolock)
				where TransactionTypeID=5 and Route is not null and SaleDateTime>getdate()-30
				group by ChainId, SupplierId, StoreId
			) S on S.SupplierID=A.SupplierID and S.ChainID=A.ChainID
and S.StoreID=A.StoreID and S.SaleDateTime>A.LastInventoryCountDate 
left join StoresUniqueValues V with(nolock) on V.SupplierID=A.SupplierID and V.StoreID=A.StoreID 
where A.RouteNo is null


update A set RouteNo=V.RouteNumber
from nik_test A
left join StoresUniqueValues V on V.SupplierID=A.SupplierID and V.StoreID=A.StoreID 
where A.RouteNo is null and V.RouteNumber is not null

--Added on 7/10/2014 by vishal to update GL Codes for Nestle.
Update A set A.GLCode = isnull(E.SupplierProductID, S.RawProductIdentifier)
from nik_test A
left join DataTrue_EDI..ProductsSuppliersItemsConversion E on E.SupplierID=A.SupplierID and E.ProductID=A.ProductID
left join StoreTransactions S with (nolock) on S.ChainId=A.ChainID and  S.SupplierID=A.SupplierID and S.StoreId=A.StoreId 
	and S.ProductID=A.ProductID and S.TransactionTypeID in (10,11)
where A.SupplierID=40559 

if OBJECT_ID('tempdb..#tmpLSD') IS NOT NULL DROP TABLE #TMPLSD
if OBJECT_ID('tempdb..#tmpLS_FactTable') IS NOT NULL DROP TABLE #tmpLS_FactTable
if OBJECT_ID('tmpdeliveries') IS NOT NULL DROP TABLE tmpdeliveries
if OBJECT_ID('tmpPOS') IS NOT NULL DROP TABLE tmpPOS

END
GO
