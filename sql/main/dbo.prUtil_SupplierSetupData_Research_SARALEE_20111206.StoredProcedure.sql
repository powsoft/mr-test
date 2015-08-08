USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_SupplierSetupData_Research_SARALEE_20111206]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prUtil_SupplierSetupData_Research_SARALEE_20111206]
as

select top 10000 * from dbo.SuppliersSetupData

select *  from dbo.SuppliersSetupData
where SupplierName = 'SARA LEE'

select distinct suppliername from dbo.SuppliersSetupData


--SARA LEE

select p.UnitPrice, sd.Cost, *
from dbo.SuppliersSetupData sd
inner join ProductPrices p
on sd.StoreID = p.StoreID
and sd.ProductID = p.ProductID
and sd.SupplierID = p.SupplierID
where sd.SupplierName = 'SARA LEE'
and p.ProductPriceTypeID = 3
and  p.UnitPrice <> sd.Cost

select p.UnitPrice, sd.Allowance, p.ActiveStartDate, sd.StartDate, *
from dbo.SuppliersSetupData sd
inner join ProductPrices p
on sd.StoreID = p.StoreID
and sd.ProductID = p.ProductID
and sd.SupplierID = p.SupplierID
and sd.StartDate = p.ActiveStartDate
and sd.EndDate = p.ActiveLastDate
where sd.SupplierName = 'SARA LEE'
and p.ProductPriceTypeID = 8
and  p.UnitPrice <> sd.Allowance

select sd.Allowance as AL, StartDate, EndDate, *
from dbo.SuppliersSetupData sd
inner join ProductPrices p
on sd.StoreID = p.StoreID
and sd.ProductID = p.ProductID
and sd.SupplierID = p.SupplierID
and p.UnitPrice = sd.Allowance
and sd.StartDate = p.ActiveStartDate
and sd.EndDate = p.ActiveLastDate
where sd.SupplierName = 'SARA LEE'
and sd.Allowance is not null
--and sd.EndDate = '12/4/2011'
order by p.StoreID, p.productid

select UnitPrice as AL, *
from ProductPrices
where SupplierID = 41465
and productpricetypeid = 8
and ActiveLastDate = '12/4/2011'
order by StoreID, productid

select *
from ProductPrices
where SupplierID = 41465
and ProductPriceTypeID = 8
order by ActiveStartDate


select * from dbo.SuppliersSetupData
where storeid = 40947
and ProductId = 17042



select * from Import.dbo.tmpPromotionsGilad
where SupplierName = 'SARA LEE'


select p.UnitPrice, sd.Cost, *
from Import.dbo.tmpPromotionsGilad sd
inner join ProductPricesTest20111205 p
--on sd.StoreID = p.StoreID
on sd.datatrueProductID = p.ProductID
and sd.SupplierID = p.SupplierID
where sd.SupplierName = 'SARA LEE'
and p.ProductPriceTypeID = 3
and  p.UnitPrice <> sd.Cost


return
GO
