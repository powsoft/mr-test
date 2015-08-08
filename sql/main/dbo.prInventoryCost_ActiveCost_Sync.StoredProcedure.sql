USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInventoryCost_ActiveCost_Sync]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prInventoryCost_ActiveCost_Sync]
as


update InventoryCost
set ActiveCost = 0

update ic
set ic.ActiveCost = 1
from InventoryCost ic
inner join
(select storeid, productid, brandid, min(ReceivedAtThisCostDate) as MinDate --min(ReceivedAtThisCostDate) as MinDate
from InventoryCost 
where QtyAvailableAtThisCost > 0
group by storeid, productid, brandid) aic
on ic.storeid = aic.storeid
and ic.productid = aic.productid
and ic.brandid = aic.brandid
and ic.ReceivedAtThisCostDate = aic.MinDate



update ic
set ic.ActiveCost = 1
from InventoryCost ic
inner join
(select storeid, productid, brandid, max(QtyAvailableAtThisCost) as MaxQtyLessThanOne
,max(ReceivedAtThisCostDate) as MaxDate
from InventoryCost 
group by storeid, productid, brandid
having max(QtyAvailableAtThisCost) < 1) aic
on ic.StoreID = aic.StoreID
and ic.ProductID = aic.ProductID
and ic.BrandID = aic.BrandID
and ic.ReceivedAtThisCostDate = aic.MaxDate



return
GO
