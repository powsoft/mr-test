USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInventoryPerpetual_UpdateFromStoreTransactions]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--select * from DataTrue_Main.dbo.InventoryPerpetual 
CREATE procedure [dbo].[prInventoryPerpetual_UpdateFromStoreTransactions]
	@ChainID int,
	@SupplierID int
As
Begin
--drop table #tempStoreTransactions
--Getting the distinct Store-Product combination on the basis of the ChainID and SupplierID
select distinct ChainID,SupplierID,Banner,StoreID,ProductID,BrandID,
CAST(0 as int) as "Deliveries",CAST(0 as int) as "Pickups",
CAST(0 as int) as "Sales",CAST(0 as int) as "CurrentOnHand",
Cast(Null as date) as "LastInventoryCountDate"
into #tempStoreTransactions
from DataTrue_Main.dbo.StoreTransactions s join DataTrue_Main.dbo.TransactionTypes t
on s.TransactionTypeID=t.TransactionTypeID
where 1=1
and t.BucketType=0
and ChainID=40393
and SupplierID=40562

--getting the lastinventory count date for each store product combination
select ChainID,SupplierID,Banner,StoreID,ProductID,BrandID,
MAX(Cast(SaleDateTime as date)) as "LastInventoryCountDate"
into #tempLastCountDate
from DataTrue_Main.dbo.StoreTransactions s join DataTrue_Main.dbo.TransactionTypes t
on s.TransactionTypeID=t.TransactionTypeID
where 1=1
and t.BucketType=0
and ChainID=40393
and SupplierID=40562
group by ChainID,SupplierID,Banner,StoreID,ProductID,BrandID

--getting the last inventory count date
update t set t.LastInventoryCountDate=c.LastInventoryCountDate
--select * 
from #tempStoreTransactions t join #tempLastCountDate c
on t.ChainID=c.ChainID
and t.SupplierID=c.SupplierID
and t.StoreID=c.StoreID
and t.ProductID=c.ProductID
and t.BrandID=c.BrandID

--getting the qty on last inventory count date
update t set t.CurrentOnHand=s.Qty
--select * 
from #tempStoreTransactions t join DataTrue_Main.dbo.StoreTransactions s
on t.ChainID=s.ChainID
and t.SupplierID=s.SupplierID
and t.StoreID=s.StoreID
and t.ProductID=s.ProductID
and t.BrandID=s.BrandID
--and t.Banner=s.Banner
and CAST(t.LastInventoryCountDate as date)=CAST(s.SaleDateTime as date)
join DataTrue_Main.dbo.TransactionTypes y
on s.TransactionTypeID=y.TransactionTypeID
where y.BucketType=0

--getting deliveries for chain and supplier
select s.ChainID,s.SupplierID,s.Banner,s.StoreID,s.ProductID,s.BrandID,SUM(Qty) as "Deliveries"
into #tempDeliveries
from DataTrue_Main.dbo.StoreTransactions s
join dbo.InventoryRulesTimesBySupplierID i ON s.SupplierID = i.SupplierID AND s.ChainID = i.ChainID 
join #tempStoreTransactions t on
s.ChainID=t.ChainID and s.StoreID=t.StoreID and s.SupplierID=t.SupplierID
and s.BrandID=t.BrandID and s.ProductID=t.ProductID
and Cast(s.SaleDateTime as date)>= Case i.InventoryTakenBeforeDeliveries when 1
									then 
										CAST(ISNULL(t.LastInventoryCountDate,  '2011-12-01 00:00:00') as date)
									else	
										(DATEADD(d,1,CAST(ISNULL( t.LastInventoryCountDate, '2011-12-01 00:00:00') as date)))  
									End
where s.TransactionTypeID in (5)
and s.ChainID=40393
and s.SupplierID=40562
and (s.SaleDateTime >= CONVERT(DATETIME, '2011-12-01 00:00:00', 102)) 
group by s.ChainID,s.SupplierID,s.Banner,s.StoreID,s.ProductID,s.BrandID

--select * from InventoryRulesTimesBySupplierID

update t set t.Deliveries=d.Deliveries
--select * 
from #tempStoreTransactions t join #tempDeliveries d
on t.ChainID=d.ChainID
and t.SupplierID=d.SupplierID
and t.StoreID=d.StoreID
and t.ProductID=d.ProductID
and t.BrandID=d.BrandID

--getting pickup for chain and supplier
select s.ChainID,s.SupplierID,s.Banner,s.StoreID,s.ProductID,s.BrandID,SUM(Qty) as "Pickup"
into #tempPickup
from DataTrue_Main.dbo.StoreTransactions s
join dbo.InventoryRulesTimesBySupplierID i ON s.SupplierID = i.SupplierID AND s.ChainID = i.ChainID 
join #tempStoreTransactions t on
s.ChainID=t.ChainID and s.StoreID=t.StoreID and s.SupplierID=t.SupplierID
and s.BrandID=t.BrandID and s.ProductID=t.ProductID
and Cast(s.SaleDateTime as date)>= Case i.InventoryTakenBeforeDeliveries when 1
									then 
										CAST(ISNULL(t.LastInventoryCountDate,  '2011-12-01 00:00:00') as date)
									else	
										(DATEADD(d,1,CAST(ISNULL( t.LastInventoryCountDate, '2011-12-01 00:00:00') as date)))  
									End
where s.TransactionTypeID in (8)
and s.ChainID=40393
and s.SupplierID=40562
group by s.ChainID,s.SupplierID,s.Banner,s.StoreID,s.ProductID,s.BrandID

update t set t.Pickups=p.Pickup
--select * 
from #tempStoreTransactions t join #tempPickup p
on t.ChainID=p.ChainID
and t.SupplierID=p.SupplierID
and t.StoreID=p.StoreID
and t.ProductID=p.ProductID
and t.BrandID=p.BrandID

--getting sale for chain and supplier
select s.ChainID,s.SupplierID,s.Banner,s.StoreID,s.ProductID,s.BrandID,SUM(Qty) as "Sale"
into #tempSale
from DataTrue_Main.dbo.StoreTransactions s join DataTrue_Main.dbo.TransactionTypes tt
on s.TransactionTypeID=tt.TransactionTypeID
join dbo.InventoryRulesTimesBySupplierID i ON s.SupplierID = i.SupplierID AND s.ChainID = i.ChainID 
join #tempStoreTransactions t on
s.ChainID=t.ChainID and s.StoreID=t.StoreID and s.SupplierID=t.SupplierID
and s.BrandID=t.BrandID and s.ProductID=t.ProductID
and Cast(s.SaleDateTime as date)>= Case i.InventoryTakenBeforeDeliveries when 1
									then 
										CAST(ISNULL(t.LastInventoryCountDate,  '2011-12-01 00:00:00') as date)
									else	
										(DATEADD(d,1,CAST(ISNULL( t.LastInventoryCountDate, '2011-12-01 00:00:00') as date)))  
									End

where 1=1
and tt.BucketType=1
and s.ChainID=40393
and s.SupplierID=40562
group by s.ChainID,s.SupplierID,s.Banner,s.StoreID,s.ProductID,s.BrandID

update t set t.Sales=s.Sale
--select * 
from #tempStoreTransactions t join #tempSale s
on t.ChainID=s.ChainID
and t.SupplierID=s.SupplierID
and t.StoreID=s.StoreID
and t.ProductID=s.ProductID
and t.BrandID=s.BrandID

/*
select t.Deliveries,i.Deliveries,t.Pickups,i.Pickups,t.Sales,i.SBTSales 
from #tempStoreTransactions t join DataTrue_Main.dbo.InventoryPerpetual i
on t.ChainID=i.ChainID
and t.StoreID=i.StoreID
and t.ProductID=i.ProductID
*/
--Updating the Inventory Perpetual table
--update i set i.Deliveries=t.Deliveries,i.Pickups=t.Pickups,i.SBTSales=t.Sales,i.CurrentOnHandQty=t.CurrentOnHand,
select * 
from #tempStoreTransactions t join InventoryPerpetual i
on t.ChainID=i.ChainID
and t.StoreID=i.StoreID
and t.ProductID=i.ProductID
and t.BrandID=i.BrandID



End
GO
