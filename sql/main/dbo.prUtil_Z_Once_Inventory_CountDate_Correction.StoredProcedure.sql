USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Z_Once_Inventory_CountDate_Correction]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Z_Once_Inventory_CountDate_Correction]
as


select * from InventoryCost where ChainID = 40393
select * from InventoryPerpetual where ChainID = 40393

/*


select s.Postcountsales, p.currentonhandqty, p.currentonhandqty - s.Postcountsales, p.*
from InventoryPerpetual p
inner join
(
select storeid, ProductId, brandid, sum(qty) as postcountsales
from storetransactions t
where cast(saledatetime as date) between '12/1/2011' and '12/4/2011'
and supplierid = 40562
group by storeid, ProductId, brandid, supplierid
) s
on p.storeid = s.storeid and p.productid = s.productid and p.brandid = s.brandid --and p.supplierid = s.supplierid
order by p.currentonhandqty - s.Postcountsales 

select * from inventoryperpetual where SBTSales = 0 and chainid = 40393

select * from inventoryperpetual where chainid = 40393 order by OriginalQty desc

select * into import.dbo.inventoryperpetual_20111210BeforeCountDateCorrection from  inventoryperpetual
select * into import.dbo.inventorycost_20111210BeforeCountDateCorrection from  inventorycost

select p.qty, s.originalqty, s.currentonhandqty, s.*
--update s set s.originalqty = p.qty, s.CurrentOnHandQty = p.qty - s.SBTSales
from storetransactions p
inner join inventoryperpetual s
on p.storeid = s.storeid 
and p.productid = s.productid 
and p.brandid = s.brandid 
and p.transactiontypeid = 11
and p.supplierid = 40562

select * from inventorycost where storeid = 40400	and productid = 5113	and supplierid = 40562
40400	5106	40562
40400	5106	40562
40400	5121	40562
40400	5128	40562
40400	5128	40562
40400	5112	40562

select s.activecost, p.originalqty, p.sbtsales, p.currentonhandqty,  s.QtyAvailableAtThisCost, s.*
--update s set s.QtyAvailableAtThisCost = p.currentonhandqty
from inventoryperpetual p
inner join inventorycost s
on p.storeid = s.storeid 
and p.productid = s.productid 
and p.brandid = s.brandid 
and s.supplierid = 40562
--where p.currentonhandqty <> s.QtyAvailableAtThisCost
--and s.activecost = 1
order by s.activecost
*/

select distinct storeid, ProductId, brandid, supplierid
into import.dbo.ztmpInventoryAssignments20111210
--delete
from InventoryCost
where SupplierID = 40562

select distinct StoreID, ProductID, brandid from InventoryPerpetual where ChainID = 40393 --and supplierid = 40562
select distinct StoreID, ProductID, brandid from InventoryCost where ChainID = 40393

select top 100 * from InventoryCost
select top 100 * from InventoryPerpetual
--where StoreID inIn
--(select StoreID from 

INSERT INTO [DataTrue_Main].[dbo].[InventoryCost]
           ([ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[SupplierID]
           ,[BrandID]
           ,[ActiveCost]
           ,[Cost]
           ,[Retail]
           ,[QtyAvailableAtThisCost]
           ,[ReceivedAtThisCostDate]
           ,[LastUpdateUserID]
           ,[MaxQtyAvailableAtThisCost])
SELECT Distinct p.[ChainID]
      ,p.[StoreID]
      ,p.[ProductID]
      ,40562
      ,p.[BrandID]
      ,1
      ,[Cost]
      ,[Retail]
      ,CurrentOnHandQty
      ,'12/1/2011'
      ,2
      ,case when OriginalQty > 0 then OriginalQty else 0 end
  FROM [DataTrue_Main].[dbo].[InventoryPerpetual] p
  inner join import.dbo.ztmpInventoryAssignments20111210 a
  on p.StoreID = a.StoreID
  and p.ProductID = a.ProductID
  and p.BrandID = a.BrandID
  where ChainID = 40393







return
GO
