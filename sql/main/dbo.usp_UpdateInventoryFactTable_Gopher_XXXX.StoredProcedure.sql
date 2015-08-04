USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UpdateInventoryFactTable_Gopher_XXXX]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec [usp_UpdateInventoryFactTable_Gopher_Test] '12/01/2011', '08/05/2012' 
CREATE PROCEDURE [dbo].[usp_UpdateInventoryFactTable_Gopher_XXXX]
	@LastSettlementDate as varchar(20),
	@LastCountDate as varchar(20)
as
Begin

Select top 1 ChainID,StoreId, ProductId, SupplierId, TransactionTypeId, ProductPriceTypeID, BrandID,Qty,SetupCost,PromoAllowance, SetupRetail, SaleDateTime, UPC,RuleCost,
RuleRetail, CostMisMatch, RetailMisMatch, TransactionStatus, Reversed, SourceID, DateTimeCreated, LastUpdateUserID, DateTimeLastUpdate, WorkingTransactionID into #tmpStoreTransactionTable 
from StoreTransactions where 1=2

Insert into #tmpStoreTransactionTable
select ChainID,StoreId, ProductId, SupplierId, TransactionTypeId, ProductPriceTypeID, BrandID,Qty,SetupCost,PromoAllowance, SetupRetail, SaleDateTime, UPC,RuleCost,
RuleRetail, CostMisMatch, RetailMisMatch, TransactionStatus, Reversed, SourceID, DateTimeCreated, LastUpdateUserID, DateTimeLastUpdate, WorkingTransactionID 
from DataTrue_Report.dbo.StoreTransactions S where S.SupplierID=40558 and ChainID=40393

Insert into #tmpStoreTransactionTable

(ChainID,StoreId, ProductId, SupplierId, TransactionTypeId, ProductPriceTypeID, BrandID,Qty,SetupCost,PromoAllowance, SetupRetail, SaleDateTime, UPC,RuleCost,
RuleRetail, CostMisMatch, RetailMisMatch, TransactionStatus, Reversed, SourceID, DateTimeCreated, LastUpdateUserID, DateTimeLastUpdate, WorkingTransactionID )

select distinct I.ChainID, i.StoreID, i.ProductID, i.SupplierID, 11, 3, 0, 0, 0, 0,0, @LastCountDate, I.UPC, 0, 0, 1, 1, 2, 0, 0, GETDATE(), 40384,
 GETDATE(), 40558  from [InventoryReport_New_FactTable_Active]  I where SupplierId=40558 and LastSettlementDate=@LastSettlementDate
and (Settle is null  or Settle=0)
union all 

Select distinct I.ChainID, i.StoreID, i.ProductID, i.SupplierID, 11, 3, 0, 0, 0,0, 0, @LastCountDate, I.UPC, 0, 0, 1, 1, 2, 0, 0, GETDATE(), 40384,
 GETDATE(), 40558 from #tmpStoreTransactionTable  I 
 Left Join StoreTransactions S on S.SupplierID=I.SupplierID and S.ChainID=I.ChainID and S.StoreID=I.StoreID and S.UPC=I.UPC and S.TransactionTypeID in (10,11) and S.SaleDateTime>@LastSettlementDate
 where I.SupplierId=40558 and S.StoreTransactionID is null 

--last settelment date
SELECT     StoreID, Settle, MAX(PhysicalInventoryDate) AS LastSettlementDate, supplierId, UPC
Into #tmpLSD
FROM         dbo.InventorySettlementRequests

Where supplierId=40558 and retailerId=40393

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
                      #tmpStoreTransactionTable IC ON 
						  LSD.StoreID = IC.StoreID AND 
						  LSD.supplierId = IC.SupplierID AND 
						  LSD.LastSettlementDate = IC.SaleDateTime  AND 
						  LSD.UPC = IC.UPC and ic.TransactionTypeID in(10,11)
WHERE     (LSD.LastSettlementDate >= CONVERT(DATETIME, @LastSettlementDate, 102))


--Clean the main table

truncate table InventoryReport_New_FactTable_Gopher

insert Into InventoryReport_New_FactTable_Gopher
	SELECT     SP.SupplierName, dbo.Chains.ChainName, ST.StoreIdentifier AS StoreNo, NULL AS SupplierAcctNo, 
						  ST.Custom1 AS Banner, CONVERT(varchar, s.SaleDateTime, 101) AS LastInventoryCountDate, CONVERT(varchar, 
						  ISNULL(LSFT.LastSettlementDate,@LastSettlementDate) , 101) AS LastSettlementDate, s.UPC, 
						  LSFT.LS_TTLQnt  AS [BI Count], LSFT.LS_TTLCost AS BI$, NULL 
						  AS [Net Deliveries], NULL AS [Net Deliveries$], NULL AS [Net POS], NULL AS POS$, NULL AS [Expected EI], NULL AS [Expected EI$], SUM(s.Qty) AS LastCountQty, 
						  SUM(s.Qty * (ISNULL(s.RuleCost,0) - ISNULL(s.PromoAllowance, 0))) AS LastCount$, NULL AS ShrinkUnits, NULL AS Shrink$, 
						  s.SupplierID, dbo.Chains.ChainID, s.StoreID, s.ProductID, NULL AS SupplierUniqueProductID, 
						  NULL AS LastCountCost, NULL AS LastCountBaseCost, null AS WeightedAvgCost, Null AS SharedShrinkUnits, Null as Settle

	FROM         #tmpStoreTransactionTable AS s INNER JOIN
						  dbo.Stores ST ON s.StoreID = ST.StoreID INNER JOIN
						  dbo.Chains ON s.ChainID = dbo.Chains.ChainID INNER JOIN
						  dbo.Suppliers  SP ON s.SupplierID = SP.SupplierID LEFT OUTER JOIN
						  #tmpLS_FactTable  LSFT ON s.SupplierID = LSFT.SupplierID AND 
						  s.StoreID = LSFT.StoreID AND s.UPC = LSFT.UPC 
	WHERE     (s.TransactionTypeID IN (11, 10)) AND (s.SaleDateTime >= ISNULL(LSFT.LastSettlementDate,CONVERT(DATETIME, @LastSettlementDate, 102)))
				and s.SupplierID=40558 and s.ChainID=40393
	GROUP BY s.SupplierID, s.StoreID, s.UPC, CONVERT(varchar, s.SaleDateTime, 101), CONVERT(varchar, 
						  ISNULL(LSFT.LastSettlementDate,@LastSettlementDate) , 101), LSFT.LS_TTLCost, 
						  LSFT.LS_TTLQnt , s.ProductID, SP.SupplierName, dbo.Chains.ChainID, dbo.Chains.ChainName, 
						  ST.StoreIdentifier, ST.Custom1
	ORDER BY s.SupplierID, s.StoreID, LastInventoryCountDate DESC

--DeliveriesRecords
SELECT     SUM(s.Qty * TT.QtySign) AS NetDeliveries, SUM((s.Qty * TT.QtySign) * (ISNULL(s.RuleCost,0) 
                      - ISNULL(s.PromoAllowance, 0))) AS NetDeliveries$, FA.LastSettlementDate, 
                      FA.LastInventoryCountDate, FA.UPC, ST.StoreIdentifier AS StoreNumber, s.StoreID, 
                      s.ProductID, s.SupplierID
into #tmpDeliveries                      
FROM         dbo.InventoryReport_New_FactTable_Gopher FA 
			 INNER JOIN
			 dbo.stores st on st.storeid = fa.storeid
			 inner join
				#tmpStoreTransactionTable s  ON FA.ProductID = s.ProductID AND
                       FA.StoreID = s.StoreID AND FA.SupplierID = s.SupplierID            
                      
                      
             inner join
              dbo.TransactionTypes TT on TT.TransactionTypeID = s.TransactionTypeID and (TT.BucketType = 2)
             
             INNER JOIN
             dbo.InventoryRulesTimesBySupplierID IRS ON FA.SupplierID = IRS.SupplierID AND FA.ChainID = IRS.ChainID 
             and (IRS.InventoryTakenBeforeDeliveries = 0) 
where  
                      (s.SaleDateTime >= CONVERT(DATETIME, @LastSettlementDate, 102)) AND 
                      (s.SaleDateTime >= ISNULL(FA.LastSettlementDate, CONVERT(DATETIME, @LastSettlementDate, 102))) AND 
                      (s.SaleDateTime < @LastCountDate)

GROUP BY FA.LastSettlementDate, FA.LastInventoryCountDate, FA.UPC, 
                      ST.StoreIdentifier, s.StoreID, s.ProductID, s.SupplierID

--Added the Union to take care of InventoryTakenBeforeDeliveries flag, 
--if its 1 then check against s.SaleDateTime <= @LastCountDate
--else if =0 then check against s.SaleDateTime < @LastCountDate

Union

SELECT     SUM(s.Qty * TT.QtySign) AS NetDeliveries, SUM((s.Qty * TT.QtySign) * (ISNULL(s.RuleCost,0) 
                      - ISNULL(s.PromoAllowance, 0))) AS NetDeliveries$, FA.LastSettlementDate, 
                      FA.LastInventoryCountDate, FA.UPC, ST.StoreIdentifier AS StoreNumber, s.StoreID, 
                      s.ProductID, s.SupplierID
FROM         dbo.InventoryReport_New_FactTable_Gopher FA 
			 INNER JOIN
			 dbo.stores st on st.storeid = fa.storeid
			 inner join
				#tmpStoreTransactionTable s  ON FA.ProductID = s.ProductID AND
                       FA.StoreID = s.StoreID AND FA.SupplierID = s.SupplierID            
                      
                      
             inner join
              dbo.TransactionTypes TT on TT.TransactionTypeID = s.TransactionTypeID and (TT.BucketType = 2)
             
             INNER JOIN
             dbo.InventoryRulesTimesBySupplierID IRS ON FA.SupplierID = IRS.SupplierID AND FA.ChainID = IRS.ChainID 
             and (IRS.InventoryTakenBeforeDeliveries = 1) 
where  
                      (s.SaleDateTime >= CONVERT(DATETIME, @LastSettlementDate, 102)) AND 
                      (s.SaleDateTime >= ISNULL(FA.LastSettlementDate, CONVERT(DATETIME, @LastSettlementDate, 102))) AND 
                      (s.SaleDateTime <= @LastCountDate)

GROUP BY FA.LastSettlementDate, FA.LastInventoryCountDate, FA.UPC, 
                      ST.StoreIdentifier, s.StoreID, s.ProductID, s.SupplierID
                      
--update Deliveries

update InventoryReport_New_FactTable_Gopher 

set [Net Deliveries] = a.NetDeliveries   ,[Net Deliveries$]=a.NetDeliveries$   

from	(select * from #tmpDeliveries ) a

inner join InventoryReport_New_FactTable_Gopher
	on InventoryReport_New_FactTable_Gopher.storeid = a.storeid
	and InventoryReport_New_FactTable_Gopher.supplierid = a.supplierid	
	and InventoryReport_New_FactTable_Gopher.ProductID  = a.productid
	and InventoryReport_New_FactTable_Gopher.LastInventoryCountDate =a.LastInventoryCountDate
	and InventoryReport_New_FactTable_Gopher.LastSettlementDate  =a.LastSettlementDate 
	
--update deliveries for Settlement Dates= Null 
update InventoryReport_New_FactTable_Gopher 

set [Net Deliveries] = a.NetDeliveries   ,[Net Deliveries$]=a.NetDeliveries$   

from	(select * from #tmpDeliveries ) a

inner join InventoryReport_New_FactTable_Gopher
	on InventoryReport_New_FactTable_Gopher.storeid = a.storeid
	and InventoryReport_New_FactTable_Gopher.supplierid = a.supplierid	
	and InventoryReport_New_FactTable_Gopher.ProductID  = a.productid
	and InventoryReport_New_FactTable_Gopher.LastInventoryCountDate =a.LastInventoryCountDate

where  (a.LastSettlementDate) is null


--POS SALES Records
SELECT     SUM(s.Qty * TT.QtySign) AS NetPOS, SUM((s.Qty * TT.QtySign) * (ISNULL(s.RuleCost,0) 
                      - ISNULL(s.PromoAllowance, 0))) AS NetPOS$, FA.LastSettlementDate, 
                      FA.LastInventoryCountDate, FA.UPC, ST.StoreIdentifier AS StoreNumber, s.StoreID, 
                      s.ProductID, s.SupplierID
Into #tmpPOS
FROM         dbo.InventoryReport_New_FactTable_Gopher FA 
			 INNER JOIN
			 dbo.stores st on st.storeid = fa.storeid
			 inner join
				#tmpStoreTransactionTable s  ON FA.ProductID = s.ProductID AND
                       FA.StoreID = s.StoreID AND FA.SupplierID = s.SupplierID            
                      and 
                      (s.SaleDateTime >= CONVERT(DATETIME, @LastSettlementDate, 102)) AND 
                      (s.SaleDateTime >= ISNULL(FA.LastSettlementDate, CONVERT(DATETIME, @LastSettlementDate, 102))) AND 
                      (s.SaleDateTime <= @LastCountDate)
                      
             inner join
              dbo.TransactionTypes TT on TT.TransactionTypeID = s.TransactionTypeID and (TT.BucketType = 1)
             
             INNER JOIN
             dbo.InventoryRulesTimesBySupplierID IRS ON FA.SupplierID = IRS.SupplierID AND FA.ChainID = IRS.ChainID 
             and (IRS.InventoryTakenBeginOfDay = 1) 


GROUP BY FA.LastSettlementDate, FA.LastInventoryCountDate, FA.UPC, 
                      ST.StoreIdentifier, s.StoreID, s.ProductID, s.SupplierID

--Added the Union to take care of InventoryTakenBeginOfDay flag, 
--if its 1 then check against s.SaleDateTime <= @LastCountDate
--else if =0 then check against s.SaleDateTime < @LastCountDate
union 

SELECT     SUM(s.Qty * TT.QtySign) AS NetPOS, SUM((s.Qty * TT.QtySign) * (ISNULL(s.RuleCost,0) 
                      - ISNULL(s.PromoAllowance, 0))) AS NetPOS$, FA.LastSettlementDate, 
                      FA.LastInventoryCountDate, FA.UPC, ST.StoreIdentifier AS StoreNumber, s.StoreID, 
                      s.ProductID, s.SupplierID
FROM         dbo.InventoryReport_New_FactTable_Gopher FA 
			 INNER JOIN
			 dbo.stores st on st.storeid = fa.storeid
			 inner join
				#tmpStoreTransactionTable s  ON FA.ProductID = s.ProductID AND
                       FA.StoreID = s.StoreID AND FA.SupplierID = s.SupplierID            
                      and 
                      (s.SaleDateTime >= CONVERT(DATETIME, @LastSettlementDate, 102)) AND 
                      (s.SaleDateTime >= ISNULL(FA.LastSettlementDate, CONVERT(DATETIME, @LastSettlementDate, 102))) AND 
                      (s.SaleDateTime < @LastCountDate)
                      
             inner join
              dbo.TransactionTypes TT on TT.TransactionTypeID = s.TransactionTypeID and (TT.BucketType = 1)
             
             INNER JOIN
             dbo.InventoryRulesTimesBySupplierID IRS ON FA.SupplierID = IRS.SupplierID AND FA.ChainID = IRS.ChainID 
             and (IRS.InventoryTakenBeginOfDay = 0) 


GROUP BY FA.LastSettlementDate, FA.LastInventoryCountDate, FA.UPC, 
                      ST.StoreIdentifier, s.StoreID, s.ProductID, s.SupplierID
--update POS

update InventoryReport_New_FactTable_Gopher

set [Net POS]   =a.NetPOS   ,POS$   =a.NetPOS$ ,  WeightedAvgCost=a.NetPOS$/a.NetPOS

from	(select * from #tmpPOS ) a

inner join InventoryReport_New_FactTable_Gopher
	on InventoryReport_New_FactTable_Gopher.storeid = a.storeid
	and InventoryReport_New_FactTable_Gopher.supplierid = a.supplierid	
	and InventoryReport_New_FactTable_Gopher.ProductID  = a.productid
	and InventoryReport_New_FactTable_Gopher.LastInventoryCountDate =a.LastInventoryCountDate
	and InventoryReport_New_FactTable_Gopher.LastSettlementDate  =a.LastSettlementDate 
	and a.NetPOS <>0

--update POS for Settlement Dates= Null 

update InventoryReport_New_FactTable_Gopher

set [Net POS]   =a.NetPOS   ,POS$   =a.NetPOS$,  WeightedAvgCost=a.NetPOS$/a.NetPOS

from	(select * from #tmpPOS ) a

inner join InventoryReport_New_FactTable_Gopher
	on InventoryReport_New_FactTable_Gopher.storeid = a.storeid
	and InventoryReport_New_FactTable_Gopher.supplierid = a.supplierid	
	and InventoryReport_New_FactTable_Gopher.ProductID  = a.productid
	and InventoryReport_New_FactTable_Gopher.LastInventoryCountDate =a.LastInventoryCountDate	
	and a.NetPOS <>0

where  (a.LastSettlementDate) is null

		
--update SupplierUniqueAccounttNumber

update InventoryReport_New_FactTable_Gopher

set SupplierAcctNo =a.SupplierAccountNumber 

from	(select * from dbo.StoresUniqueValues ) a

inner join InventoryReport_New_FactTable_Gopher
	on InventoryReport_New_FactTable_Gopher.storeid = a.storeid
	and InventoryReport_New_FactTable_Gopher.supplierid = a.supplierid	
	
--update SupplierUniqueProductNumber

update InventoryReport_New_FactTable_Gopher

set SupplierUniqueProductID  =a.IdentifierValue

from	(select * from dbo.ProductIdentifiers   where ProductIdentifierTypeID=3) a

inner join InventoryReport_New_FactTable_Gopher
	on InventoryReport_New_FactTable_Gopher.ProductID = a.ProductID
	and InventoryReport_New_FactTable_Gopher.supplierid = a.OwnerEntityId	



--update Null values to Zero , 

update InventoryReport_New_FactTable_Gopher 
set [Net Deliveries] =ISNULL([Net Deliveries] ,0),[Net Deliveries$] =ISNULL([Net Deliveries$],0),[Net POS]=ISNULL([Net POS],0),POS$ =ISNULL(POS$  ,0)


	--do not update Bimbo (40557)  Last Settlment Date to 12/1/2011 becuase they have multiple initialization dates based on banners
update InventoryReport_New_FactTable_Gopher 
set [BI Count] =ISNULL([BI Count] ,0),BI$ =ISNULL(BI$,0), LastSettlementDate =isnull(LastSettlementDate,@LastSettlementDate)
where (ChainID =40393 and SupplierID  <> 40557)  or (ChainID =40393 and SupplierID  = 40557 and Banner not like 'Farm Fresh Markets')


--update EI , 

update InventoryReport_New_FactTable_Gopher

set [Expected EI]=[BI Count]-[Net POS]+[Net Deliveries],[Expected EI$]=BI$-POS$+[Net Deliveries$]
	

--update ShrinkUnits
update InventoryReport_New_FactTable_Gopher

set 	ShrinkUnits =[Expected EI]-LastCountQty,Shrink$=[Expected EI$]-LastCount$ 
where LastCountQty =0

update InventoryReport_New_FactTable_Gopher

set 	ShrinkUnits =[Expected EI]-LastCountQty,Shrink$=(LastCount$/LastCountQty )*([Expected EI]-LastCountQty )
where LastCountQty <>0

--Final Clean Up
Delete  from InventoryReport_New_FactTable_Gopher
where LastSettlementDate  is null and LastCountQty =0 and [Net Deliveries] =0


                   
--Update UnitCost at LastCountDate	
		update f set f. NetUnitCostLastCountDate = s.NetCost, f.BaseCostLastCountDate=s.basecost 
		from InventoryReport_New_FactTable_Gopher f
		inner join
		(select i.ProductID ,i.StoreID,i.LastInventoryCountDate  ,p3.UnitPrice-ISNULL(p8.unitprice,0) as NetCost, p3.UnitPrice as basecost
		from InventoryReport_New_FactTable_Gopher I
		 inner join 		
			  ProductPrices p3 on p3.ProductID=i.ProductID  and p3.StoreID =i.StoreID and p3.SupplierID =i.SupplierID and p3.ProductPriceTypeID =3 
		 left join ProductPrices P8 on p3.ProductID=p8.ProductID  and p3.SupplierID =p8.SupplierID and p3.StoreID =p8.StoreID
					and p3.ActiveStartDate <=p8.ActiveStartDate and p8.ActiveLastDate <=p3.ActiveLastDate 	 and p8.ProductPriceTypeID =8 
					and i.LastInventoryCountDate between p8.ActiveStartDate  and p8.ActiveLastDate 
			 
		 where  i.LastInventoryCountDate between p3.ActiveStartDate  and p3.ActiveLastDate  ) s
		 on f.ProductID = s.ProductID
		 and f.StoreID = s.StoreID
		 and f.LastInventoryCountDate = s.LastInventoryCountDate


--update POS, Deliveries and BI to be calculated based on the most recent BASE unit cost
update f
set [Net Deliveries$] = s.Deliveries$, [Expected EI$]=s.Expected$ , [POS$]=s.POS$,[BI$]=s.BI$ ,[Shrink$]=s.Shrink$, [lastcount$]=s.lastcount$ 
from InventoryReport_New_FactTable_Gopher f
inner join
(select i.ProductID,i.StoreID,i.LastInventoryCountDate, 
i.[Net Deliveries]*i.BaseCostLastCountDate  as Deliveries$, 
i.[Expected EI]*i.BaseCostLastCountDate as Expected$,
i.[BI Count]*i.BaseCostLastCountDate as BI$,
i.[Net POS] *i.BaseCostLastCountDate  as POS$,
i.ShrinkUnits *i.BaseCostLastCountDate as Shrink$,
i.LastCountQty *i.BaseCostLastCountDate as LastCount$

 from InventoryReport_New_FactTable_Gopher  i ) s
 
 on f.ProductID = s.ProductID
		 and f.StoreID = s.StoreID
		 and f.LastInventoryCountDate = s.LastInventoryCountDate
		 

--ADDED 4/26/2012--update POS, Deliveries and BI to be calculated based on the most recent WEIGHTED AVG unit cost (ONLY for records that there WeightCost >0)
update f
set [Net Deliveries$] = s.Deliveries$, [Expected EI$]=s.Expected$ , [POS$]=s.POS$,[BI$]=s.BI$ ,[Shrink$]=s.Shrink$, [lastcount$]=s.lastcount$ 
from InventoryReport_New_FactTable_Gopher f
inner join
(select i.ProductID,i.StoreID,i.LastInventoryCountDate, 
i.[Net Deliveries]*i.WeightedAvgCost  as Deliveries$, 
i.[Expected EI]*i.WeightedAvgCost as Expected$,
i.[BI Count]*i.WeightedAvgCost as BI$,
i.[Net POS] *i.WeightedAvgCost  as POS$,
i.ShrinkUnits *i.WeightedAvgCost as Shrink$,
i.LastCountQty *i.WeightedAvgCost as LastCount$

 from InventoryReport_New_FactTable_Gopher  i ) s
 
 on f.ProductID = s.ProductID
		 and f.StoreID = s.StoreID
		 and f.LastInventoryCountDate = s.LastInventoryCountDate
		 and f.WeightedAvgCost>0

Drop Table #tmpStoreTransactionTable

END
GO
