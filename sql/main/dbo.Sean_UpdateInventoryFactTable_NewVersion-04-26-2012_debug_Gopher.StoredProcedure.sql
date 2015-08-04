USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[Sean_UpdateInventoryFactTable_NewVersion-04-26-2012_debug_Gopher]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sean_UpdateInventoryFactTable_NewVersion-04-26-2012_debug_Gopher]
	
	
as
Begin


--last settelment date
SELECT     StoreID, Settle, MAX(PhysicalInventoryDate) AS LastSettlementDate, supplierId, UPC
Into #tmpLSD
FROM         dbo.InventorySettlementRequests
where 1 = 1
and storeid = 40455
and supplierId = 40558
GROUP BY StoreID, Settle, supplierId, UPC
HAVING      (Settle = 'y')

--Get Last Settlment UnitCount (from Store Transactions)
SELECT     LSD.supplierId, LSD.StoreID, LSD.LastSettlementDate, 
                      ISNULL(IC.qty, 0) AS LS_TTLQnt, 
                      ISNULL(IC.Qty*(ic.rulecost-isnull(ic.PromoAllowance,0)), 0) AS LS_TTLCost, 
                      LSD.UPC
into #tmpLS_FactTable
FROM         #tmpLSD LSD 
				LEFT OUTER JOIN
                      dbo.StoreTransactions IC ON 
						  LSD.StoreID = IC.StoreID AND 
						  LSD.supplierId = IC.SupplierID AND 
						  LSD.LastSettlementDate = IC.SaleDateTime  AND 
						  LSD.UPC = IC.UPC and ic.TransactionTypeID in(10,11)
WHERE     (LSD.LastSettlementDate >= CONVERT(DATETIME, '2011-11-30 00:00:00', 102))

--Clean the main table
--drop table InventoryReport_New_FactTable_Debug_Gopher
truncate table InventoryReport_New_FactTable_Debug_Gopher
--select top 1 * into InventoryReport_New_FactTable_Debug_Gopher from InventoryReport_New_FactTable_Debug
--select * from InventoryReport_New_FactTable_Debug_Gopher order by shrinkunits
--select sum(shrinkunits * LastCountCost) from InventoryReport_New_FactTable_Debug_Gopher
insert Into InventoryReport_New_FactTable_Debug_Gopher
	SELECT     SP.SupplierName, dbo.Chains.ChainName, ST.StoreIdentifier AS StoreNo, NULL AS SupplierAcctNo, 
						  ST.Custom1 AS Banner, CONVERT(varchar, s.SaleDateTime, 101) AS LastInventoryCountDate, CONVERT(varchar, 
						  LSFT.LastSettlementDate , 101) AS LastSettlementDate, s.UPC, 
						  LSFT.LS_TTLQnt  AS [BI Count], LSFT.LS_TTLCost AS BI$, NULL 
						  AS [Net Deliveries], NULL AS [Net Deliveries$], NULL AS [Net POS], NULL AS POS$, NULL AS [Expected EI], NULL AS [Expected EI$], SUM(s.Qty) AS LastCountQty, 
						  SUM(s.Qty * (ISNULL(s.RuleCost,0) - ISNULL(s.PromoAllowance, 0))) AS LastCount$, NULL AS ShrinkUnits, NULL AS Shrink$, 
						  s.SupplierID, dbo.Chains.ChainID, s.StoreID, s.ProductID, NULL AS SupplierUniqueProductID, 
						  NULL AS LastCountCost, NULL AS LastCountBaseCost, null AS WeightedAvgCost, Null AS SharedShrinkUnits, Null as Settle, Null as GLCode

	FROM         dbo.StoreTransactions AS s INNER JOIN
						  dbo.Stores ST ON s.StoreID = ST.StoreID INNER JOIN
						  dbo.Chains ON s.ChainID = dbo.Chains.ChainID INNER JOIN
						  dbo.Suppliers  SP ON s.SupplierID = SP.SupplierID LEFT OUTER JOIN
						  #tmpLS_FactTable  LSFT ON s.SupplierID = LSFT.SupplierID AND 
						  s.StoreID = LSFT.StoreID AND s.UPC = LSFT.UPC 
	WHERE     1 = 1 and s.storeid = 40455
and s.supplierId = 40558 and (s.TransactionTypeID IN (11, 10)) AND (s.SaleDateTime > ISNULL(LSFT.LastSettlementDate,CONVERT(DATETIME, '2000-01-01 00:00:00', 102)))
	GROUP BY s.SupplierID, s.StoreID, s.UPC, CONVERT(varchar, s.SaleDateTime, 101), CONVERT(varchar, 
						  LSFT.LastSettlementDate , 101), LSFT.LS_TTLCost, 
						  LSFT.LS_TTLQnt , s.ProductID, SP.SupplierName, dbo.Chains.ChainID, dbo.Chains.ChainName, 
						  ST.StoreIdentifier, ST.Custom1
	ORDER BY s.SupplierID, s.StoreID, LastInventoryCountDate DESC

-- Update Null Last Settlement Dates of Products that were not settled during the last settlement date where other products within the same supplier and store got settled
	select distinct SupplierID, StoreID, LastSettlementDate into #t1 from  InventoryReport_New_FactTable_Debug_Gopher where LastSettlementDate is not null
	select distinct SupplierID, StoreID, UPC, LastSettlementDate into #t2  from  InventoryReport_New_FactTable_Debug_Gopher where LastSettlementDate is null
	
	select #t2.*, #t1.LastSettlementDate as datetoupdate into #t3 from  #t1
	inner join #t2 on #t1.SupplierID=#t2.SupplierID  and #t1.StoreID=#t2.StoreID 
		
	update i
	set LastSettlementDate = #t3.datetoupdate
	from InventoryReport_New_FactTable_Debug_Gopher i
	inner join #t3 on #t3.SupplierID=i.SupplierID and #t3.StoreID=i.StoreID and #t3.UPC=i.UPC

--DeliveriesRecords
SELECT     SUM(s.Qty * TT.QtySign) AS NetDeliveries, SUM((s.Qty * TT.QtySign) * (ISNULL(s.RuleCost,0) 
                      - ISNULL(s.PromoAllowance, 0))) AS NetDeliveries$, FA.LastSettlementDate, 
                      FA.LastInventoryCountDate, FA.UPC, ST.StoreIdentifier AS StoreNumber, s.StoreID, 
                      s.ProductID, s.SupplierID
into #tmpDeliveries                      
FROM         dbo.InventoryReport_New_FactTable_Debug_Gopher FA 
			 INNER JOIN
			 dbo.stores st on st.storeid = fa.storeid
			 inner join
				dbo.StoreTransactions s  ON FA.ProductID = s.ProductID AND
                       FA.StoreID = s.StoreID AND FA.SupplierID = s.SupplierID            
                      and 
                      (s.SaleDateTime >= CONVERT(DATETIME, '2011-12-01 00:00:00', 102)) AND 
                      (s.SaleDateTime >= ISNULL(FA.LastSettlementDate, CONVERT(DATETIME, '2011-12-01 00:00:00', 102))) AND 
                      (s.SaleDateTime < FA.LastInventoryCountDate)
                      
             inner join
              dbo.TransactionTypes TT on TT.TransactionTypeID = s.TransactionTypeID and (TT.BucketType = 2)
             
             INNER JOIN
             dbo.InventoryRulesTimesBySupplierID IRS ON FA.SupplierID = IRS.SupplierID AND FA.ChainID = IRS.ChainID and (IRS.InventoryTakenBeforeDeliveries = 1) 
where 1 = 1 and s.storeid = 40455
and s.supplierId = 40558

GROUP BY FA.LastSettlementDate, FA.LastInventoryCountDate, FA.UPC, 
                      ST.StoreIdentifier, s.StoreID, s.ProductID, s.SupplierID



--update Deliveries

update InventoryReport_New_FactTable_Debug_Gopher 

set [Net Deliveries] = a.NetDeliveries   ,[Net Deliveries$]=a.NetDeliveries$   

from	(select * from #tmpDeliveries ) a

inner join InventoryReport_New_FactTable_Debug_Gopher
	on InventoryReport_New_FactTable_Debug_Gopher.storeid = a.storeid
	and InventoryReport_New_FactTable_Debug_Gopher.supplierid = a.supplierid	
	and InventoryReport_New_FactTable_Debug_Gopher.ProductID  = a.productid
	and InventoryReport_New_FactTable_Debug_Gopher.LastInventoryCountDate =a.LastInventoryCountDate
	and InventoryReport_New_FactTable_Debug_Gopher.LastSettlementDate  =a.LastSettlementDate 
	
--update deliveries for Settlement Dates= Null 
update InventoryReport_New_FactTable_Debug_Gopher 

set [Net Deliveries] = a.NetDeliveries   ,[Net Deliveries$]=a.NetDeliveries$   

from	(select * from #tmpDeliveries ) a

inner join InventoryReport_New_FactTable_Debug_Gopher
	on InventoryReport_New_FactTable_Debug_Gopher.storeid = a.storeid
	and InventoryReport_New_FactTable_Debug_Gopher.supplierid = a.supplierid	
	and InventoryReport_New_FactTable_Debug_Gopher.ProductID  = a.productid
	and InventoryReport_New_FactTable_Debug_Gopher.LastInventoryCountDate =a.LastInventoryCountDate

where  (a.LastSettlementDate) is null


--POS SALES Records
SELECT     SUM(s.Qty * TT.QtySign) AS NetPOS, SUM((s.Qty * TT.QtySign) * (ISNULL(s.RuleCost,0) 
                      - ISNULL(s.PromoAllowance, 0))) AS NetPOS$, FA.LastSettlementDate, 
                      FA.LastInventoryCountDate, FA.UPC, ST.StoreIdentifier AS StoreNumber, s.StoreID, 
                      s.ProductID, s.SupplierID
Into #tmpPOS
FROM         dbo.InventoryReport_New_FactTable_Debug_Gopher FA 
			 INNER JOIN
			 dbo.stores st on st.storeid = fa.storeid
			 inner join
				dbo.StoreTransactions s  ON FA.ProductID = s.ProductID AND
                       FA.StoreID = s.StoreID AND FA.SupplierID = s.SupplierID            
                      and 
                      (s.SaleDateTime >= CONVERT(DATETIME, '2011-12-01 00:00:00', 102)) AND 
                      (s.SaleDateTime >= ISNULL(FA.LastSettlementDate, CONVERT(DATETIME, '2011-12-01 00:00:00', 102))) AND 
                      (s.SaleDateTime < FA.LastInventoryCountDate)
                      
             inner join
              dbo.TransactionTypes TT on TT.TransactionTypeID = s.TransactionTypeID and (TT.BucketType = 1)
             
             INNER JOIN
             dbo.InventoryRulesTimesBySupplierID IRS ON FA.SupplierID = IRS.SupplierID AND FA.ChainID = IRS.ChainID and (IRS.InventoryTakenBeforeDeliveries = 1) 
where 1 = 1 and s.storeid = 40455
and s.supplierId = 40558

GROUP BY FA.LastSettlementDate, FA.LastInventoryCountDate, FA.UPC, 
                      ST.StoreIdentifier, s.StoreID, s.ProductID, s.SupplierID


--update POS

update InventoryReport_New_FactTable_Debug_Gopher

set [Net POS]   =a.NetPOS   ,POS$   =a.NetPOS$ ,  WeightedAvgCost=a.NetPOS$/a.NetPOS

from	(select * from #tmpPOS ) a

inner join InventoryReport_New_FactTable_Debug_Gopher
	on InventoryReport_New_FactTable_Debug_Gopher.storeid = a.storeid
	and InventoryReport_New_FactTable_Debug_Gopher.supplierid = a.supplierid	
	and InventoryReport_New_FactTable_Debug_Gopher.ProductID  = a.productid
	and InventoryReport_New_FactTable_Debug_Gopher.LastInventoryCountDate =a.LastInventoryCountDate
	and InventoryReport_New_FactTable_Debug_Gopher.LastSettlementDate  =a.LastSettlementDate 
	and a.NetPOS <>0

--update POS for Settlement Dates= Null 

update InventoryReport_New_FactTable_Debug_Gopher

set [Net POS]   =a.NetPOS   ,POS$   =a.NetPOS$,  WeightedAvgCost=a.NetPOS$/a.NetPOS

from	(select * from #tmpPOS ) a

inner join InventoryReport_New_FactTable_Debug_Gopher
	on InventoryReport_New_FactTable_Debug_Gopher.storeid = a.storeid
	and InventoryReport_New_FactTable_Debug_Gopher.supplierid = a.supplierid	
	and InventoryReport_New_FactTable_Debug_Gopher.ProductID  = a.productid
	and InventoryReport_New_FactTable_Debug_Gopher.LastInventoryCountDate =a.LastInventoryCountDate	
	and a.NetPOS <>0

where  (a.LastSettlementDate) is null

		
--update SupplierUniqueAccounttNumber

update InventoryReport_New_FactTable_Debug_Gopher

set SupplierAcctNo =a.SupplierAccountNumber 

from	(select * from dbo.StoresUniqueValues ) a

inner join InventoryReport_New_FactTable_Debug_Gopher
	on InventoryReport_New_FactTable_Debug_Gopher.storeid = a.storeid
	and InventoryReport_New_FactTable_Debug_Gopher.supplierid = a.supplierid	
	
--update SupplierUniqueProductNumber

update InventoryReport_New_FactTable_Debug_Gopher

set SupplierUniqueProductID  =a.IdentifierValue

from	(select * from dbo.ProductIdentifiers   where ProductIdentifierTypeID=3) a

inner join InventoryReport_New_FactTable_Debug_Gopher
	on InventoryReport_New_FactTable_Debug_Gopher.ProductID = a.ProductID
	and InventoryReport_New_FactTable_Debug_Gopher.supplierid = a.OwnerEntityId	



--update Null values to Zero , 

update InventoryReport_New_FactTable_Debug_Gopher 
set [Net Deliveries] =ISNULL([Net Deliveries] ,0),[Net Deliveries$] =ISNULL([Net Deliveries$],0),[Net POS]=ISNULL([Net POS],0),POS$ =ISNULL(POS$  ,0)

--Next update added 4/19/2012 by charlie and Mandeep to manage Lewis lastsettlement date to 12/10/2011
update InventoryReport_New_FactTable_Debug_Gopher 
set [BI Count] =ISNULL([BI Count] ,0),BI$ =ISNULL(BI$,0), LastSettlementDate =isnull(LastSettlementDate,'12/10/2011')
where (ChainID =40393 and SupplierID  = 41464)


	--do not update Bimbo (40557)  Last Settlment Date to 12/1/2011 becuase they have multiple initialization dates based on banners
update InventoryReport_New_FactTable_Debug_Gopher 
set [BI Count] =ISNULL([BI Count] ,0),BI$ =ISNULL(BI$,0), LastSettlementDate =isnull(LastSettlementDate,'12/1/2011')
where (ChainID =40393 and SupplierID  <> 40557)  or (ChainID =40393 and SupplierID  = 40557 and Banner not like 'Farm Fresh Markets')

	--update Bimbo (40557)  Last Settlment Date to 1/2/2012 (for Farm Fresh) becuase they have multiple initialization dates based on banners
update InventoryReport_New_FactTable_Debug_Gopher 
set [BI Count] =ISNULL([BI Count] ,0),BI$ =ISNULL(BI$,0), LastSettlementDate =isnull(LastSettlementDate,'1/2/2012')
where ChainID =40393 and SupplierID  = 40557 and Banner = 'Farm Fresh Markets'


--update EI , 

update InventoryReport_New_FactTable_Debug_Gopher

set [Expected EI]=[BI Count]-[Net POS]+[Net Deliveries],[Expected EI$]=BI$-POS$+[Net Deliveries$]
	

--update ShrinkUnits
update InventoryReport_New_FactTable_Debug_Gopher

set 	ShrinkUnits =[Expected EI]-LastCountQty,Shrink$=[Expected EI$]-LastCount$ 
where LastCountQty =0

update InventoryReport_New_FactTable_Debug_Gopher

set 	ShrinkUnits =[Expected EI]-LastCountQty,Shrink$=(LastCount$/LastCountQty )*([Expected EI]-LastCountQty )
where LastCountQty <>0

--Final Clean Up
Delete  from InventoryReport_New_FactTable_Debug_Gopher
where LastSettlementDate  is null and LastCountQty =0 and [Net Deliveries] =0


                   
--Update UnitCost at LastCountDate	
		update f set f. LastCountCost = s.NetCost, f.LastCountBaseCost=s.basecost 
		from InventoryReport_New_FactTable_Debug_Gopher f
		inner join
		(select i.ProductID ,i.StoreID,i.LastInventoryCountDate  ,p3.UnitPrice-ISNULL(p8.unitprice,0) as NetCost, p3.UnitPrice as basecost
		from InventoryReport_New_FactTable_Debug_Gopher I
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

	update InventoryReport_New_FactTable_Debug_Gopher set LastCountBaseCost=POS$/[Net POS]
	where LastCountBaseCost is null and isnull(POS$,0) <>0 and isnull([Net POS],0) <>0
	
	update InventoryReport_New_FactTable_Debug_Gopher set LastCountBaseCost=[Net Deliveries$]/[Net Deliveries]
	where LastCountBaseCost is null and isnull([Net Deliveries],0) <>0 and isnull([Net Deliveries$],0) <>0
	
	update InventoryReport_New_FactTable_Debug_Gopher set LastCountBaseCost= BI$/[BI Count]
	where LastCountBaseCost is null and isnull([BI Count],0) <>0 and isnull(BI$,0) <>0

	update InventoryReport_New_FactTable_Debug_Gopher set LastCountBaseCost= 0
	where LastCountBaseCost is null and ShrinkUnits<>0


--update POS, Deliveries and BI to be calculated based on the most recent BASE unit cost
update f
set [Net Deliveries$] = s.Deliveries$, [Expected EI$]=s.Expected$ , [POS$]=s.POS$,[BI$]=s.BI$ ,[Shrink$]=s.Shrink$, [lastcount$]=s.lastcount$ 
from InventoryReport_New_FactTable_Debug_Gopher f
inner join
(select i.SupplierID, i.ProductID,i.StoreID,i.LastInventoryCountDate, 
i.[Net Deliveries]*i.LastCountBaseCost  as Deliveries$, 
i.[Expected EI]*i.LastCountBaseCost as Expected$,
i.[BI Count]*i.LastCountBaseCost as BI$,
i.[Net POS] *i.LastCountBaseCost  as POS$,
i.ShrinkUnits *i.LastCountBaseCost as Shrink$,
i.LastCountQty *i.LastCountBaseCost as LastCount$

 from InventoryReport_New_FactTable_Debug_Gopher  i where LastCountBaseCost is not null) s
 
 on f.SupplierID=s.SupplierID
		 and f.ProductID = s.ProductID
		 and f.StoreID = s.StoreID
		 and f.LastInventoryCountDate = s.LastInventoryCountDate
		 

--Fix Null value in Weighted Avg Cost that are Null becuase no POS activity was recorded. 08/16/2012
    update InventoryReport_New_FactTable_Debug_Gopher set WeightedAvgCost=Shrink$/ShrinkUnits
	where WeightedAvgCost is null and isnull(ShrinkUnits,0) <>0 and isnull(Shrink$,0) <>0
	
	update InventoryReport_New_FactTable_Debug_Gopher set WeightedAvgCost=[Net Deliveries$]/[Net Deliveries]
	where WeightedAvgCost is null and isnull([Net Deliveries],0) <>0 and isnull([Net Deliveries$],0) <>0
	
	update InventoryReport_New_FactTable_Debug_Gopher set WeightedAvgCost=POS$/[Net POS]
	where WeightedAvgCost is null and isnull(POS$,0) <>0 and isnull([Net POS],0) <>0
	
	update InventoryReport_New_FactTable_Debug_Gopher set WeightedAvgCost=[Expected EI$]/[Expected EI]
	where WeightedAvgCost is null and isnull([Expected EI$],0) <>0 and isnull([Expected EI],0) <>0

	
--ADDED 4/26/2012--update POS, Deliveries and BI to be calculated based on the most recent WEIGHTED AVG unit cost (ONLY for records that there WeightCost >0)
update f
set [Net Deliveries$] = s.Deliveries$, [Expected EI$]=s.Expected$ , [POS$]=s.POS$,[BI$]=s.BI$ ,[Shrink$]=s.Shrink$, [lastcount$]=s.lastcount$ 
from InventoryReport_New_FactTable_Debug_Gopher f
inner join
(select i.SupplierID,i.ProductID,i.StoreID,i.LastInventoryCountDate, 
i.[Net Deliveries]*i.WeightedAvgCost  as Deliveries$, 
i.[Expected EI]*i.WeightedAvgCost as Expected$,
i.[BI Count]*i.WeightedAvgCost as BI$,
i.[Net POS] *i.WeightedAvgCost  as POS$,
i.ShrinkUnits *i.WeightedAvgCost as Shrink$,
i.LastCountQty *i.WeightedAvgCost as LastCount$

 from InventoryReport_New_FactTable_Debug_Gopher  i ) s
 
 on f.SupplierID =s.SupplierID
		 and f.ProductID = s.ProductID
		 and f.StoreID = s.StoreID
		 and f.LastInventoryCountDate = s.LastInventoryCountDate
		 and f.WeightedAvgCost>0
where f.SupplierID <>40562 --Condition added by Vishal on 8/22 to skip Shrink $ calculation based on weighted Avg Cost. (FB: 14636)


END
GO
