USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Inventory_Count_Import_PepperidgeFarm_20111208]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Inventory_Count_Import_PepperidgeFarm_20111208]
as
--40562 is Pepperidge Farm

alter table import.dbo.SVINVCOUNTONE
add upc12 nvarchar(50)

select * from datatrue_edi.dbo.EDI_SupplierCrossReference
select * from Suppliers where SupplierID = 40562
select * from import.dbo.SVINVCOUNTONE

select distinct LEN(upc) from import.dbo.SVINVCOUNTONE

drop table #distinctupc
select distinct ltrim(rtrim(upc)) as UPC into #distinctupc from import.dbo.SVINVCOUNTONE


select distinct workingstatus from StoreTransactions_Working
/*
-99
-44
-9
-6
-5
-4
-2
4
5
1204
1205
*/
select * from StoreTransactions_Working where WorkingStatus = -4

select * from suppliers where supplieridentifier = '6807515'

select * from StoreTransactions_Working where WorkingStatus = 0

update w set w.chainid = 40393
from StoreTransactions_Working w
where WorkingStatus = 0

select * 
from StoreTransactions_Working w
inner join stores s
on CAST(w.StoreIdentifier as int) = CAST(s.StoreIdentifier as int)
 where WorkingStatus = 0
 
 select distinct custom1
 from stores
 where StoreID in
 (
 select distinct storeid
 from StoreTransactions
where SupplierID = 40562
)

select *
--update t set t.StoreID = c.StoreID
from [dbo].[StoreTransactions_Working] t
inner join [dbo].[Stores] c
on t.ChainID = c.ChainID
and '55' + RIGHT(t.storeidentifier, 3) = LTRIM(rtrim(custom2))
--and CAST(t.StoreIdentifier as int) = CAST(c.StoreIdentifier as int)
where t.WorkingStatus = 0

select *
from [dbo].[StoreTransactions_Working] t
where CAST(t.StoreIdentifier as int) not in
(
select CAST(c.StoreIdentifier as int)
from [dbo].[StoreTransactions_Working] t
inner join [dbo].[Stores] c
on t.ChainID = c.ChainID
and '55' + RIGHT(t.storeidentifier, 3) = LTRIM(rtrim(custom2))
--and CAST(t.StoreIdentifier as int) = CAST(c.StoreIdentifier as int)
where t.WorkingStatus = 0
)
and t.WorkingStatus = 0

select * from import.dbo.SVINVCOUNTONE

select * from import.dbo.SVINVCOUNTONE
where storenumber in
(
	select t.StoreIdentifier
	from [dbo].[StoreTransactions_Working] t
	where CAST(t.StoreIdentifier as int) not in
	(
	select CAST(c.StoreIdentifier as int)
	from [dbo].[StoreTransactions_Working] t
	inner join [dbo].[Stores] c
	on t.ChainID = c.ChainID
	and CAST(t.StoreIdentifier as int) = CAST(c.StoreIdentifier as int)
	where t.WorkingStatus = 0
	)
	and t.WorkingStatus = 0
)

select top 10000 *
--update w set w.reportedcost = 0.00, reportedretail = 0.00
from StoreTransactions_Working w
where WorkingStatus = 4
--order by DateTimeCreated desc
and WorkingSource = 'INV'
and ReportedCost is null

select * from Source where SourceName = 'supervalue inventory initial upload 12-5-11.xls'


select dtproductid, dtStoreID, * 
--update t set t.storeid = i.dtstoreid, t.productid = i.dtproductid, t.brandid = 0, t.SupplierID = 40562, t.sourceid = 2109, t.workingstatus = 4, t.saledatetime = '2011-12-01 00:00:00.000'
from import.dbo.SVINVCOUNTONE i
inner join [dbo].[StoreTransactions_Working] t
on i.storenumber = t.StoreIdentifier
and i.upc12 = t.UPC
and t.WorkingStatus = -9997
order by i.dtProductID

select t.rulecost, *
--update w set w.reportedcost = t.rulecost, w.reportedretail = t.ruleretail
from [dbo].[StoreTransactions_Working] w
inner join 
(
select storeid, ProductId, brandid, MAX(RuleCost) as rulecost, 0.00 as ruleretail
from StoreTransactions
group by storeid, ProductId, brandid
) t
on w.StoreID = t.StoreID
and w.ProductID = t.ProductID
and w.BrandID = t.BrandID
where w.WorkingStatus = 4
and w.ReportedCost is null
and ReportedCost = 99999


select StoreID, ProductID, COUNT(storetransactionid)
from StoreTransactions_Working w
where WorkingStatus = 4
and WorkingSource = 'INV'
group by StoreID, ProductID
order by COUNT(storetransactionid) desc

select * from StoreTransactions 
where TransactionTypeID = 11
and SupplierID = 40562

select distinct transactionstatus from StoreTransactions 
where TransactionTypeID = 11
and SupplierID = 40562

select * 
from StoreTransactions 
where TransactionTypeID = 11
and SupplierID = 40562
and TransactionStatus = 0
order by DateTimeCreated desc

select t.qty, i.OriginalQty, i.*
--update i set i.OriginalQty = t.qty
from InventoryPerpetual i
inner join
(
select distinct storeid, ProductId, brandid, qty
from StoreTransactions
where SupplierID = 40562
and TransactionTypeID = 11
) t
on i.StoreID = t.StoreID
and i.ProductID = t.ProductID
and i.BrandID = t.BrandID
where 1 = 1
--and Qty <> i.OriginalQty
order by DateTimeCreated desc

update i set ShrinkRevision = 0
from InventoryPerpetual i

declare @rec cursor
declare @upc nvarchar(50)
declare @upc11 nvarchar(50)
declare @upc12 nvarchar(50)
declare @recordid int
declare @checkdigit char(1)

set @rec = CURSOR local fast_forward FOR
--	select recordid, UPC from [Import].[dbo].[SBTCostAllowanceBook] where LEN(UPC) = 10 and upc12 is null
	select UPC from  #distinctupc
open @rec

fetch next from @rec into @upc
--fetch next from @rec into @recordid, @upc

while @@FETCH_STATUS = 0
	begin

	set @checkdigit = ''
	set @upc11 = @UPC
	
	exec [dbo].[prUtil_UPC_GetCheckDigit]
	 @upc11,
	 @CheckDigit OUT
	 
	 update import.dbo.SVINVCOUNTONE set upc12 = @upc11 + @CheckDigit
	 where upc = @upc
	
		fetch next from @rec into @upc
--fetch next from @rec into @recordid, @upc
	end
	
close @rec
deallocate @rec


select * 
from stores 
where Custom1 = 'FARM FRESH MARKETS'
order by StoreIdentifier

select distinct cast(StoreIdentifier as int), * 
from stores 
where Custom1 = 'FARM FRESH MARKETS'
and CAST(storeidentifier as int) not in
(select distinct CAST(storenumber as int) from import.dbo.SVINVCOUNTONE where dtbanner = 'FARM FRESH MARKETS')
order by cast(StoreIdentifier as int)

select distinct CAST(storenumber as int)
from import.dbo.SVINVCOUNTONE
where dtbanner = 'FARM FRESH MARKETS'
order by CAST(storenumber as int)

--The first file is Pepperidge Farm only 40562

select * from import.dbo.SVINVCOUNTONE

select distinct LEN(UPC) from import.dbo.SVINVCOUNTONE

update import.dbo.SVINVCOUNTONE set dtproductid = 0

update import.dbo.SVINVCOUNTONE set upc12 = '0' + UPC

select *
--update c set c.dtproductid = i.productid
from import.dbo.SVINVCOUNTONE c
inner join ProductIdentifiers i
on LTRIM(rtrim(c.UPC12)) = LTRIM(rtrim(IdentifierValue))

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

select top 1000 s.StoreName, a.* 
from Addresses a
inner join stores s
on OwnerEntityID = storeid
where Address1 like '%175%' 
or City like '%FALLON%'
and ChainID = 40393
order by city
/*
006028	2000114648	Pepperidge Farm, Inc.	18217	SUPERVALU/SHOP N SAVE	235 HWY 175	O FALLON
007865	2000089789	Pepperidge Farm, Inc.	10250	ACME MARKETS/PHILADELPHIA	5300 PARK BLVD	WILDWOOD
030584	2000103372	Pepperidge Farm, Inc.	15851	SUPERVALU/CUB FOODS	5001 NORTH BIG HOLLOW ROAD	PEORIA
030914	2000103457	Pepperidge Farm, Inc.	15851	CUB FOODS/ILL DIV	1512 SW RTE 26	FREEPORT
030394	2000103459	Pepperidge Farm, Inc.	15851	CUB FOODS/ILL DIV	4141 NAKOOSA TRL	MADISON
155118	2000116810	Pepperidge Farm, Inc.	15848	SUPERVALU/CUB FOODS	100 XYLITE ST NE	CAMBRIDGE
155112	2000116814	Pepperidge Farm, Inc.	15848	SUPERVALU/CUB FOODS	8600 114TH AVE N	CHAMPLIN
155139	2000116816	Pepperidge Farm, Inc.	15848	SUPERVALU/CUB FOODS	7900 MARKET BLVD	CHANHASSEN
005209	2000124654	Pepperidge Farm, Inc.	15848	SUPERVALU/CUB FOODS	2013 BROADWAY AVE W	FOREST LAKE
155051	2000132806	Pepperidge Farm, Inc.	15848	SUPERVALU/CUB FOODS	3717 LEXINGTON AVE	ARDEN HILLS
155506	2000132807	Pepperidge Farm, Inc.	15848	SUPERVALU/CUB FOODS	14075 HWY 13	SAVAGE
155530	2000132808	Pepperidge Farm, Inc.	15848	SUPERVALU/CUB FOODS	23800 STATE HWY 7	SHOREWOOD
155933	2000140389	Pepperidge Farm, Inc.	15848	SUPERVALU/CUB FOODS	300 E TRAVELERS TRAIL	BURNSVILLE
6013	2000177723	Pepperidge Farm, Inc.	18217	SUPERVALU/SHOP N SAVE	9529 COLLINSVILLE RD	COLLINSVILLE

*/

select *
--update c set c.dtstoreid = s.storeid
from import.dbo.SVINVCOUNTONE c
inner join stores s
--on CAST(c.storenumber as int) = CAST(s.custom2 as int)
on CAST(c.storenumber as int) = CAST(s.StoreIdentifier as int)
and ltrim(rtrim(c.dtbanner)) = ltrim(rtrim(s.custom1))
and s.ChainID = 40393

select * 
from import.dbo.SVINVCOUNTONE
where CAST(storenumber as int) not in
(select CAST(storeidentifier as int) from stores)
order by Total desc

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

update c set c.ReportedCost = null, c.reportedRetail = null
from import.dbo.SVINVCOUNTONE c
/*
select distinct dtproductid from import.dbo.SVINVCOUNTONE where dtstoreid <> 0 --13608
and dtstoreid not in
(
select p.StoreID, p.ProductId
--update c set c.ReportedCost = p.UnitPrice, c.reportedRetail = p.UnitRetail
from import.dbo.SVINVCOUNTONE c --where dtstoreid <> 0 = 13608
inner join productprices p
on c.dtstoreid = p.storeid
and c.dtproductid = p.productid
and p.SupplierID = 40562
and ProductPriceTypeID = 3
and dtStoreID <> 0
and c.loadstatus = 0
and c.reportedcost is null
and '12/1/2011' between p.ActiveStartDate and p.ActiveLastDate
)
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

select distinct [Count date] from import.dbo.SVINVCOUNTONE

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

select distinct [COUNT Date]

from import.dbo.SVINVCOUNTONE c --where dtstoreid <> 0 = 13608
inner join productprices p
on c.dtstoreid = p.storeid
and c.dtproductid = p.productid
and p.SupplierID = 40562
and ProductPriceTypeID = 3

select * from InventoryPerpetual where StoreID in (select StoreID from stores where ChainID = 40393)

select *

from import.dbo.SVINVCOUNTONE c --where dtstoreid <> 0 = 13608
inner join inventoryperpetual p
on c.dtstoreid = p.storeid
and c.dtproductid = p.productid

select *
from import.dbo.SVINVCOUNTONE
where dtstoreid <> 0
and loadstatus = 0
order by dtStoreID, dtProductID

select * from import.dbo.SVINVCOUNTONE where total < 0 and dtstoreid <> 0
select * from [DataTrue_EDI].[dbo].[Inbound846Inventory] where recordstatus = 0

INSERT INTO [DataTrue_EDI].[dbo].[Inbound846Inventory]
           ([ChainName]
           ,[ProductIdentifier]
           ,[StoreNumber]
           ,[Qty]
           ,[Cost]
           ,[Retail]
           ,[EffectiveDate]
           ,[RecordStatus]
           ,[FileName]
           ,[SupplierIdentifier])
select 'SV'
,UPC12
,StoreNumber
,SUM(Total)
,Max(ReportedCost)
,Max(isnull(ReportedRetail, 0.00))
,'12/5/2011'
,0
,'supervalue inventory initial upload 12-5-11.xls'
,'6807515'
--select *
from import.dbo.SVINVCOUNTONE
where dtStoreID <> 0
--and ReportedCost is not null
and Loadstatus = 0
--and storenumber <> '007998'
--and UPC12 <> '014100094036'
group by upc12, storenumber


select *
--update c set loadstatus = 2
from import.dbo.SVINVCOUNTONE c
where dtStoreID <> 0
and ReportedCost is not null
and Loadstatus = 1

select *
--update c set loadstatus = 1
from import.dbo.SVINVCOUNTONE c
where dtStoreID <> 0
and ReportedCost is not null
and Loadstatus = 0

select *
--update c set loadstatus = 2
from import.dbo.SVINVCOUNTONE c
where dtStoreID = 41340
and dtProductID = 5135

--41340	5135
--40562 Pepperidge Farm SupplierID
--*************Update Reported Cost from StoreTransactions**********************

select *
--update c set c.reportedcost = 99999.00
from import.dbo.SVINVCOUNTONE c
where ReportedCost is null
and dtstoreid <> 0


select *

from storetransactions t
inner join import.dbo.SVINVCOUNTONE c
on dtStoreID = t.StoreID
and dtProductID = t.productid
where dtStoreID <> 0
and c.ReportedCost is not null
and storenumber = '007998'
and UPC12 = '014100094036'
and CAST(saledatetime as date) >= '12/1/2011'



--manage cost and retail mismatches
select distinct InventoryCostMethod
--update s set InventoryCostMethod = 'FIFO'
from storesetup s
where ChainID = 40393
--41340	5135

select *
from StoreTransactions
where StoreID = 41340
and ProductID = 5135
and SaleDateTime > '11/29/2011'
and TransactionTypeID not in ('11','10')
order by saledatetime

--**************Store Transactions Research***********************
select ss.*, t.*
from [dbo].[StoreTransactions] t
inner join StoreSetup ss
on t.storeid = ss.storeid
and t.productid = ss.productid
and t.brandid = ss.brandid
and t.SupplierID = ss.supplierid
where TransactionStatus in (0, 811)
and TransactionTypeID in (2,6,7,16,17,18,22)
and CostMisMatch = 0
and RetailMisMatch = 0
and Qty <> 0
and t.saledatetime between ss.ActiveStartDate and ss.ActiveLastDate
and ss.InventoryCostMethod = 'WAVG'
and cast(t.SaleDateTime as date) >= '11/30/2011'
order by SaleDateTime desc

select *
from StoreTransactions
where PromoAllowance < 0

select *
from ProductPrices
where ProductPriceTypeID = 8
and UnitPrice < 0

select distinct storeid, brandid, ProductId, supplierid 
from StoreTransactions 
where ChainID = 40393 
and CAST(saledatetime as date) >= '12/1/2011'

select t.storeid, t.brandid, t.ProductId, t.supplierid
from StoreTransactions t
inner join
(select distinct storeid, brandid, ProductId, supplierid 
from StoreSetup 
where ChainID = 40393 ) s
on t.StoreID = s.StoreID
and t.ProductID = s.ProductID
and t.BrandID = s.BrandID
and t.SupplierID = s.SupplierID
where t.ChainID = 40393 
and CAST(saledatetime as date) >= '12/1/2011'
--**************Store Transactions Research***********************

--Reported Cost Issue
select *
from StoreTransactions_Working w
where WorkingStatus = 4
and ReportedCost > 1000

select distinct productid
from StoreTransactions_Working w
where WorkingStatus = 4
and ReportedCost > 1000

select *
from ProductPrices p
where ProductID in
(
select distinct productid
from StoreTransactions_Working w
where WorkingStatus = 4
and ReportedCost > 1000
)

select *
from StoreTransactions_Working w
where TransactionTypeID = 11
and SupplierID = 40562

select * into import.dbo.storesetup_20111209BeforePepperidgeFarmAdditions from storesetup

MERGE INTO [dbo].[StoreSetup] i

USING (SELECT distinct [ChainID]
	  ,[StoreID]
      ,[ProductID]
      ,0 as [BrandID]
      ,40562 as [SupplierID]
  FROM [dbo].[StoreTransactions] t
  where TransactionTypeID = 11
and SupplierID = 40562) S
	on i.ChainID = s.ChainID
	and i.StoreID = s.StoreID 
	and i.ProductID = s.ProductID
	and i.BrandID = s.BrandID
	and i.SupplierID = s.SupplierID
	
WHEN NOT MATCHED 

THEN INSERT 
           ([ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[BrandID]
           ,[LastUpdateUserID]
           ,[SupplierID]
           ,[ActiveStartDate]
           ,[ActiveLastDate]
           ,[InventoryCostMethod])
     VALUES
           (s.[ChainID]
           ,s.[StoreID]
			,s.[ProductID]
			,s.[BrandID]
			,2
			,s.[SupplierID]
			,'11/1/2011'
			,'12/31/2025'
			,'FIFO');


select *
from StoreTransactions
where SupplierID = 40562
and TransactionTypeID in (2, 6)
and CAST(SaleDateTime as date) >= '11/30/2011'
order by ReportedCost

select *
--update t set TrueCost = ReportedCost, BrandIdentifier = 'PFINV_UPDATE'
from StoreTransactions t
where SupplierID = 40562
and TransactionTypeID in (2, 6)
and CAST(SaleDateTime as date) >= '11/30/2011'
and TrueCost is null
order by ReportedCost

select *
--update t set TrueCost = ReportedCost
from StoreTransactions t
where SupplierID = 40562
and TransactionTypeID in (2, 6)
and CAST(SaleDateTime as date) >= '11/30/2011'
and ISNULL(SetupCost, 0) <> ISNULL(ReportedCost, 0)
order by ReportedCost


select *

from StoreTransactions t
where SupplierID = 40562
and TransactionTypeID in (2, 6)
and CAST(SaleDateTime as date) >= '11/30/2011'
and TransactionStatus = 811

select * from storesetup
where SupplierID = 40562
and InventoryCostMethod <> 'FIFO'

select *
from storetransactions
where SupplierID = 40562
--and InventoryCostMethod <> 'FIFO'

exec prUtil_GetInventoryCostView 40393
exec prUtil_GetInventoryPerpetualView 40393

select * from stores where CAST(storeidentifier as int) = 31744
select * from stores where CAST(custom2 as int) = 31744

select * from StoreTransactions_Working 
where 1 = 1
--and TransactionTypeID = 11
and ChainID <> 7608
and ReportedCost > 1000 
--and StoreID = 40416
order by Storeid

select *
--update c set c.dtstoreid = 40454
from import.dbo.SVINVCOUNTONE c
where 1 = 1
and [SAP Customer] = '2000103457'
--and cast(storenumber as int) = 7865

select * from import.dbo.SVINVCOUNTONE
where dtstoreid = 40416

select [sap customer], COUNT(total)
from import.dbo.SVINVCOUNTONE
where dtStoreID = 0
group by [sap customer]
order by COUNT(total) desc

select storeid, COUNT(storetransactionid)
from StoreTransactions t
where t.SupplierID = 40562
and StoreID not in
(select distinct dtstoreid from import.dbo.SVINVCOUNTONE)
group by StoreID
order by COUNT(storetransactionid) desc

select distinct s.Storeid, s.storeidentifier, a.*
from InventoryPerpetual p
inner join stores s
on p.StoreID = s.StoreID
inner join Addresses a
on s.StoreID = a.OwnerentityID
and CAST(s.storeidentifier as int) not in
(select distinct CAST(storenumber as int) from import.dbo.SVINVCOUNTONE)
where p.ChainID = 40393
order by city

select distinct [sap customer]
from import.dbo.SVINVCOUNTONE

select storeid, COUNT(storetransactionid)
from StoreTransactions t
where SupplierID = 40562
and StoreID not in (select distinct dtstoreid from import.dbo.SVINVCOUNTONE)
group by StoreID
order by COUNT(storetransactionid) desc

select custom1, COUNT(storeid)
from stores
where ChainID = 40393
group by Custom1

select Name, COUNT([total])
from import.dbo.SVINVCOUNTONE
group by Name
order by COUNT(total)

select Name, COUNT([total])
from import.dbo.SVINVCOUNTONE
where dtStoreID = 0
group by Name
order by COUNT(total)

select distinct dtstoreid
from import.dbo.SVINVCOUNTONE

select Name, [sap customer], storenumber, dtbanner, COUNT(total)
from import.dbo.SVINVCOUNTONE
where dtStoreID = 0
and loadstatus = 0
group by Name, [sap customer], storenumber, dtbanner
order by COUNT(total) desc

declare @snint int=190
select *
from stores
where CAST(storeidentifier as int) = @snint or CAST(custom2 as int) = @snint

select Custom2, *
from stores
where ChainID = 40393
order by CAST(custom2 as int)

select * from import.dbo.SVINVCOUNTONE

select * from import.dbo.SVINVCOUNTONE
where cast(storenumber as int) not in 
(select distinct CAST(storeidentifier as int) from stores)
order by storenumber

--41274 wildwood nj = 007865

--006028 2000114648

select *
from stores
where CAST(storeidentifier as int) = 168

select *
from import.dbo.SVINVCOUNTONE
where dtstoreid = 40763

select Name, [sap customer], storenumber, dtbanner, COUNT(total)
from import.dbo.SVINVCOUNTONE
where dtStoreID = 0
and loadstatus = 0
group by Name, [sap customer], storenumber, dtbanner
order by COUNT(total) desc

select i.storenumber, i.name, s.storename, s.custom1
from stores s
inner join
(select distinct storenumber, name from import.dbo.SVINVCOUNTONE where dtStoreID = 0) i
on right(ltrim(rtrim(s.custom2)), 3) = right(ltrim(rtrim(i.storenumber)), 3)
--on CAST(s.custom2 as int) = CAST(i.storenumber as int)
--on CAST(s.storeidentifier as int) = CAST(i.storenumber as int)
and s.ChainID = 40393
and s.Custom1 = 'Albertsons - IMW'

and s.Custom1 = 'Farm Fresh Markets'


select i.storenumber, i.name, s.storename, s.custom1
--update i set i.dtstoreid = s.storeid
from stores s
inner join import.dbo.SVINVCOUNTONE i
on right(ltrim(rtrim(s.custom2)), 3) = right(ltrim(rtrim(i.storenumber)), 3)
--on CAST(s.custom2 as int) = CAST(i.storenumber as int)
--on CAST(s.storeidentifier as int) = CAST(i.storenumber as int)
and s.ChainID = 40393
and s.Custom1 = 'Farm Fresh Markets'
and i.dtstoreid = 0
and CHARINDEX('Farm', i.name) > 0
and i.loadstatus = 0

/*
000168	Farm Fresh Markets
000188	Farm Fresh Markets
000190	Farm Fresh Markets
000193	Farm Fresh Markets
000196	Farm Fresh Markets
000197	Farm Fresh Markets

*/

select * from import.dbo.SVINVCOUNTONE where CAST(storenumber as int) = 7821

select *
from stores
where StoreID in
(select StoreID from InventorySettlementRequests)



INSERT INTO [DataTrue_Main].[dbo].[InventorySettlementRequests]
           ([StoreNumber]
           ,[StoreID]
           ,[PhysicalInventoryDate]
           ,[InvoiceAmount]
           ,[Settle]
           ,[UnsettledShrink]
           ,[RequestingPersonID]
           ,[RequestDate]
           ,[ApprovingPersonID]
           ,[ApprovedDate]
           ,[supplierId]
           ,[retailerId]
           ,[DenialReason])
	select distinct s.StoreIdentifier
	,s.StoreID
	,'11/30/2011'
	,0
	,'Y'
	,0
	,2
	,'11/30/2011'
	,2
	,'11/30/2011'
	,c.SupplierID
	,40393
	,''
		
	from stores s
	inner join	InventoryCost c
	on s.StoreID = c.Storeid
	where c.chainid = 40393
	
select *
--update t set SaleDateTime = '12/1/2011'
from StoreTransactions t
where TransactionTypeID = 11
and CAST(Saledatetime as date) = '12/5/2011'

select * 
--update c set c.REceivedAtThisCostDate = '12/1/2011'
from InventoryCost c
where ChainID = 40393


select top 100 * from InventorySettlementRequests

select * from import.dbo.SVINVCOUNTONE





select top 10000 * from dbo.X12_SuppliersDeliveriesAndInventories
where SupplierName not in ('GopherNews','Sara Lee')


select UPC, StoreNo, InvoiceDate, COUNT(activitycode)
from dbo.X12_SuppliersDeliveriesAndInventories
group by UPC, StoreNo, InvoiceDate
having COUNT(activitycode) > 1



exec prGetInbound846Inventory
exec prValidateStoresInStoreTransactions_Working_INV
exec prValidateProductsInStoreTransactions_Working_INV
exec prValidateSuppliersInStoreTransactions_Working_INV
exec prValidateSourceInStoreTransactions_Working_INV
exec prValidateTransactionTypeInStoreTransactions_Working_INV
exec prApplyINVStoreTransactionsToInventory
exec prApplyINVStoreTransactionsToInventoryCost --************************************************************************
--*************For Initial Count Zero Shrink Revision**************************
exec prProcessShrink_Initial
--*************For Non-Initial Count Apply Shrink Revision**************************
exec prProcessShrink
--*************For Non-Initial Count Apply Shrink Revision**************************
exec prInventory_WAVG_ProcessTransactions
exec prInventory_FIFO_ProcessTransactions

exec prCDCGetStoreTransactionsLSN
exec prCDCGetInventoryPerpetualUpdatesLSN
--*************Supplier Store Transactions Import*************************
--update DataTrue_EDI..InBoundSuppliers set RecordStatus = 0 where RecordID in (1,2,3)
--update storetransactions set InventoryCost = null where storetransactionid = 499221
--*****************Views*************************
exec prUtil_GetInventoryCostView 7608
exec prUtil_GetInventoryPerpetualView 7608
exec prUtil_GetStoreTransactionView 7608
exec prUtil_GetInvoiceDetailsView 7608
exec prUtil_GetInvoiceHeaderView 7608
--***********************************************

exec prGetInboundSUPTransactions
exec prValidateStoresInStoreTransactions_Working_SUP
exec prValidateProductsInStoreTransactions_Working_SUP
exec prValidateSuppliersInStoreTransactions_Working_SUP
exec prValidateSourceInStoreTransactions_Working_SUP
exec prValidateTransactionTypeInStoreTransactions_Working_SUP
exec prProcessSUPDeliveriesForShrinkReversal
exec prProcessSUPPickupsForShrinkReversal
exec prApplySUPStoreTransactionsToInventoryCost--************************************************************************
exec prInventory_WAVG_ProcessTransactions
exec prInventory_FIFO_ProcessTransactions
exec prApplySUPStoreTransactionsToInventory
exec prApplyShrinkReversalToInventory

exec prCDCGetStoreTransactionsLSN
exec prCDCGetInventoryPerpetualUpdatesLSN
--*************POS Transactions*******************************
--update DataTrue_EDI..Inbound852Sales set Recordstatus = 0 where chainname = 'RA'
--select * from DataTrue_EDI..Inbound852Sales where Recordstatus = 0
--*****************Views*************************
exec prUtil_GetInventoryCostView 40393
exec prUtil_GetInventoryPerpetualView 40393
exec prUtil_GetStoreTransactionView 7608
exec prUtil_GetInvoiceDetailsView 7608
exec prUtil_GetInvoiceHeaderView 7608
--***********************************************

exec prGetInboundPOSTransactions
exec prValidateStoresInStoreTransactions_Working
exec prValidateProductsInStoreTransactions_Working
exec prValidateSuppliersInStoreTransactions_Working
exec prValidateSourceInStoreTransactions_Working
exec prValidateTransactionTypeInStoreTransactions_Working
exec prProcessPOSForShrinkReversal
exec prInventory_WAVG_ProcessTransactions
exec prInventory_FIFO_ProcessTransactions
exec prApplyPOSStoreTransactionsToInventory
exec prApplyShrinkReversalToInventory

exec prCDCGetStoreTransactionsLSN
exec prCDCGetInventoryPerpetualUpdatesLSN


return
GO
