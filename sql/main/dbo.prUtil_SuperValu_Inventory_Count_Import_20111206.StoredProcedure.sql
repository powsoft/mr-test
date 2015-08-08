USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_SuperValu_Inventory_Count_Import_20111206]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_SuperValu_Inventory_Count_Import_20111206]
as

--The first file is Pepperidge Farm only 40562

select * from import.dbo.SVINVCOUNTONE

select distinct LEN(UPC) from import.dbo.SVINVCOUNTONE

select *
--update c set c.dtproductid = i.productid
from import.dbo.SVINVCOUNTONE c
inner join ProductIdentifiers i
on LTRIM(rtrim(UPC)) = right(LTRIM(rtrim(IdentifierValue)),11)

--on SUBSTRING(LTRIM(rtrim(UPC)), 2, 10) = SUBSTRING(LTRIM(rtrim(IdentifierValue)), 2, 10)
--on right(LTRIM(rtrim(UPC)),11) = right(LTRIM(rtrim(IdentifierValue)),11)

alter table import.dbo.SVINVCOUNTONE
add pricetypeid int--storeid int,
--productid int,
--dtbanner nvarchar(50)
--ReportedCost money,
--ReportedRetail money

select distinct Name from import.dbo.SVINVCOUNTONE

update import.dbo.SVINVCOUNTONE set dtbanner = 'Shoppers Food and Pharmacy' where name = 'SHOPPERS FOOD WAREHOUSE'
update import.dbo.SVINVCOUNTONE set dtbanner = 'Shop N Save Warehouse Foods Inc' where name = 'SHOP N SAVE WAREHOUSE'
update import.dbo.SVINVCOUNTONE set dtbanner = 'Farm Fresh Markets' where name = 'FARM FRESH SUPERMARKET'
update import.dbo.SVINVCOUNTONE set dtbanner = 'Cub Foods' where name = 'CUB FOODS'
update import.dbo.SVINVCOUNTONE set dtbanner = 'Albertsons - ACME' where name = 'ACME MARKET'

select distinct dtbanner from import.dbo.SVINVCOUNTONE

/*
SHOPPERS FOOD WAREHOUSE
SHOP N SAVE WAREHOUSE
FARM FRESH SUPERMARKET
CUB FOODS
ACME MARKET
*/

select distinct custom1 from stores
select * from import.dbo.SVINVCOUNTONE --15859 - 13608


select *
--update c set c.dtstoreid = s.storeid
from import.dbo.SVINVCOUNTONE c
inner join stores s
--on CAST(c.storenumber as int) = CAST(s.custom2 as int)
on CAST(c.storenumber as int) = CAST(s.StoreIdentifier as int)
and ltrim(rtrim(c.dtbanner)) = ltrim(rtrim(s.custom1))
and s.ChainID = 40393



select distinct storenumber, Name from import.dbo.SVINVCOUNTONE
where CAST(storenumber as int) not in
(select CAST(storeidentifier as int) from stores)

select CAST(storeidentifier as int) from stores order by CAST(storeidentifier as int)
select CAST(storenumber as int) from Import.dbo.SVStores order by CAST(storenumber as int)

select * from import.dbo.SVINVCOUNTONE where storenumber = '000197'

select distinct storenumber from import.dbo.SVINVCOUNTONE

declare @storenumber nvarchar(50)= '155933'
select * from stores where CAST(storeidentifier as int) = CAST(@storenumber as int)
select * from stores where CAST(custom2 as int) = CAST(@storenumber as int)

select distinct custom2 from stores
/*
storenumber	Name
000197	FARM FRESH SUPERMARKET
000405	FARM FRESH SUPERMARKET
000664	FARM FRESH SUPERMARKET
002622	SHOPPERS FOOD WAREHOUSE
002642	SHOPPERS FOOD WAREHOUSE
002647	SHOPPERS FOOD WAREHOUSE
005209	CUB FOODS
007865	ACME MARKET
155051	CUB FOODS
155112	CUB FOODS
155118	CUB FOODS
155139	CUB FOODS
155506	CUB FOODS
155530	CUB FOODS
155933	CUB FOODS
*/

select *

from import.dbo.SVINVCOUNTONE c
inner join stores s
on CAST(c.storenumber as int) = CAST(s.custom2 as int)
and s.ChainID = 40393


select p.StoreID, p.ProductID, COUNT(UnitPrice)

from import.dbo.SVINVCOUNTONE c --where dtstoreid <> 0 = 13608
inner join productprices p
on c.dtstoreid = p.storeid
and c.dtproductid = p.productid
--and c.pricetypeid = p.productpricetypeid
where p.ProductPriceTypeID = 3
and p.SupplierID = 40562
group by p.StoreID, p.ProductID
order by COUNT(UnitPrice) desc

update import.dbo.SVINVCOUNTONE  set pricetypeid = 3

select *
--select distinct storeid, productid
 from ProductPrices
where 1 = 1
--and StoreID = 41264
and ProductID = 5135
and ProductPriceTypeID = 3
order by StoreID
/*
41264	5135
41246	5135
41296	5135
41314	5135
41282	5135
40428	5135
41335	5135
41285	5135
41249	5135
40432	5135
*/

select * from ProductPrices z
inner join
(select p.StoreID, p.ProductId
from import.dbo.SVINVCOUNTONE c --where dtstoreid <> 0 = 13608
inner join productprices p
on c.dtstoreid = p.storeid
and c.dtproductid = p.productid
and p.SupplierID = 40562
and ProductPriceTypeID = 3
group by p.StoreID, p.ProductID
having COUNT(UnitPrice) > 1) g
on z.StoreID = z.StoreID
and z.ProductID = z.ProductID
where z.SupplierID = 40562
order by z.StoreID, z.productid


select StoreNumber, UPC, COUNT(Total)
from import.dbo.SVINVCOUNTONE c --where dtstoreid <> 0 = 13608
group by storenumber, [UPC]
order by COUNT(Total) desc


select * from import.dbo.SVINVCOUNTONE
where storenumber = '155506'
and [UPC]= '14100094036'

/*
155506	14100094036
155530	14100094036
155933	14100094036
000168	14100094036
000188	14100094036
000190	14100094036
000193	14100094036
000196	14100094036
000198	14100094036
*/

select distinct *

from import.dbo.SVINVCOUNTONE c --where dtstoreid <> 0 = 13608
inner join productprices p
on c.dtstoreid = p.storeid
and c.dtproductid = p.productid
and p.SupplierID = 40562
and ProductPriceTypeID = 3

return
GO
