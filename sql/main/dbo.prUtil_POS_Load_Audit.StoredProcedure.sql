USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_POS_Load_Audit]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_POS_Load_Audit]

as

select *
from datatrue_EDI..temp_Inbound852Sales s
--where RecordStatus = 0

select *
from datatrue_EDI..temp_Inbound852Sales s
inner join datatrue_EDI.dbo.SV_ItemFile_1 t
on t.ProductCode = s.ProductIdentifier

select ProductID, Identifiervalue into ztmpProductIdentTenWide
--update p set p.Identifiervalue = '00' + p.Identifiervalue
from ProductIdentifiers p
where LEN(identifiervalue) = 10

select ProductID, Identifiervalue into ztmpProductIdentElevenWide
--update p set p.Identifiervalue = '0' + p.Identifiervalue
from ProductIdentifiers p
where LEN(identifiervalue) = 11

select *
--update p set p.Identifiervalue = '00' + p.Identifiervalue
from ProductIdentifiers
where LEN(identifiervalue) = 10
and productid > 7090



select *
from datatrue_EDI..Inbound852Sales s
inner join ProductIdentifiers p
on Right(LTRIM(rtrim(s.productidentifier)), 11) = LTRIM(rtrim(p.IdentifierValue))
where RecordStatus = -5

select *
from datatrue_EDI..Inbound852Sales s
inner join ProductIdentifiers p
on LTRIM(rtrim(s.productidentifier)) = LTRIM(rtrim(p.IdentifierValue))
where RecordStatus = 0
and ChainIdentifier = 'SV'

select identifiervalue, COUNT(productid) as count, MAX(ProductID) as maxproductid
into #tmpstepone
from ProductIdentifiers
group by identifiervalue
having COUNT(productid) > 1
order by COUNT(productid) desc

select * from #tmpstepone order by maxproductid

update ProductIdentifiers set IdentifierValue = IdentifierValue + 'X' where ProductID in
(select maxproductid from #tmpstepone)

select identifiervalue, COUNT(productid) as count, MAX(ProductID) as maxproductid
into #tmpsteptwo
from ProductIdentifiers
group by identifiervalue
having COUNT(productid) > 1
order by COUNT(productid) desc

update ProductIdentifiers set IdentifierValue = IdentifierValue + 'X' where ProductID in
(select maxproductid from #tmpsteptwo)

select * from productidentifiers where right(IdentifierValue, 1) = 'X'order by productid

select * from datatrue_edi.dbo.Inbound852Sales where Saledate = '11/7/2011'

select distinct recordstatus from datatrue_edi.dbo.Inbound852Sales where Saledate = '11/7/2011'

select * from datatrue_EDI..Inbound852Sales where RecordStatus = -5
select * from datatrue_EDI..Inbound852Sales where RecordStatus = 0

update datatrue_EDI..Inbound852Sales set RecordStatus = 0 where RecordStatus = -5
update datatrue_EDI..Inbound852Sales set RecordStatus = 0 where Saledate = '11/7/2011'



select *
from datatrue_EDI..Inbound852Sales s
inner join ProductIdentifiers i
on LTRIM(rtrim(s.productidentifier)) = LTRIM(rtrim(IdentifierValue))
where 1 = 1
and productidentifiertypeid = 2
and RecordStatus = 0
and ChainIdentifier = 'SV'

select LTRIM(rtrim(identifiervalue)), count(productid)
from productidentifiers
group by LTRIM(rtrim(identifiervalue))
order by count(productid) desc

select LTRIM(rtrim(identifiervalue)) as ident, count(productid) as count, MAX(productid) as maxproductid
into #tempnow1
from productidentifiers
group by LTRIM(rtrim(identifiervalue))
having count(productid) > 1
order by count(productid) desc

select *
from #tempnow1 t
inner join ProductIdentifiers i
on LTRIM(rtrim(t.ident)) = LTRIM(rtrim(i.IdentifierValue))

update ProductIdentifiers set IdentifierValue = LTRIM(rtrim(IdentifierValue)) + 'W'
where ProductID in
(select distinct maxproductid from #tempnow1)

select LTRIM(rtrim(identifiervalue)) as ident, count(productid) as count, MAX(productid) as maxproductid
from productidentifiers
group by LTRIM(rtrim(identifiervalue))
having count(productid) > 1
order by count(productid) desc







select s.*

from datatrue_EDI..Inbound852Sales s
where LTRIM(rtrim(s.productidentifier)) not in
(select LTRIM(rtrim(IdentifierValue)) from ProductIdentifiers)
and RecordStatus = 0

select s.*
--update s set s.recordstatus = -5
from datatrue_EDI..Inbound852Sales s
where LTRIM(rtrim(s.productidentifier)) not in
(select LTRIM(rtrim(IdentifierValue)) from ProductIdentifiers)
and RecordStatus = 0

select *
--
from ProductIdentifiers i
inner join datatrue_EDI..Inbound852Sales s
on LTRIM(rtrim(i.IdentifierValue)) = LTRIM(rtrim(s.ProductIdentifier))
and RecordStatus = 0
--27252

select * from datatrue_EDI..Inbound852Sales where RecordStatus = 0

select *
--
from ProductIdentifiers i
inner join datatrue_EDI..Inbound852Sales s
on right(LTRIM(rtrim(i.IdentifierValue)), 12) = LTRIM(rtrim(s.ProductIdentifier))
and RecordStatus = 0
and i.ProductID > 7000

select distinct ProductIdentifier
--update s set s.recordstatus = -5
from datatrue_EDI..Inbound852Sales s
where LTRIM(rtrim(s.productidentifier)) not in
(select LTRIM(rtrim(IdentifierValue)) from ProductIdentifiers)
and RecordStatus = 0
and ChainIdentifier = 'SV'

select * from ProductIdentifiers
where CHARINDEX('74570146', Identifiervalue) > 0
--007457014600

select * from ProductIdentifiers
where len(Identifiervalue) > 12
and CHARINDEX('X', Identifiervalue) = 0

select distinct CAST(saledate as date) from datatrue_EDI..Inbound852Sales where RecordStatus = 0

select * from ProductIdentifiers where DateTimeCreated > '11/7/2011' order by productid

select * from ProductIdentifiers
where 1 = 1
--and len(Identifiervalue) > 12
and CHARINDEX('007098910477', Identifiervalue) > 0
--007098910477


select * into tmpProductIdentifiers_201111091339PM from ProductIdentifiers

update ProductIdentifiers set identifiervalue = LTRIM(rtrim(identifiervalue)) + 'Z' where ProductId < 7094

select * from ProductIdentifiers
where 1 = 1
and CHARINDEX('X', Identifiervalue) > 0
and ProductID > 7090

select LEFT(IdentifierValue, LEN(IdentifierValue) - 1)
--update i set i.IdentifierValue = LEFT(i.IdentifierValue, LEN(i.IdentifierValue) - 1)
from ProductIdentifiers i
where 1 = 1
and CHARINDEX('X', Identifiervalue) > 0
and ProductID > 7090

update i set i.IdentifierValue = LTRIM(rtrim(i.IdentifierValue))
from ProductIdentifiers i
where 1 = 1
--and CHARINDEX('X', Identifiervalue) > 0
and ProductID > 7090



select distinct chainid from StoreTransactions


select storeid, COUNT(storetransactionid)
from StoreTransactions
group by StoreID
order by COUNT(storetransactionid)  desc


select supplierid, COUNT(storetransactionid)
from StoreTransactions
group by supplierid
order by COUNT(storetransactionid)  desc


select * 
FROM brands
--RA = 35541

select distinct InventoryCostMethod
FROM StoreSetup
where ChainID = 35541

select * 
FROM StoreSetup
where ChainID = 35541
and brandid <> 0

select * 
FROM productprices
where ChainID = 35541
and UnitPrice <=0
and brandid <> 0


select AVG(unitprice/unitretail) 
FROM productprices
where ChainID = 35541
and UnitPrice <=0
and brandid <> 0

select distinct productid
from StoreTransactions
where ProductID not in 
(select productid 
FROM productprices
where ChainID = 35541)
and brandid <> 0

SELECT COUNT(*)
FROM  StoreTransactions_Working
WHERE (StoreID IS NULL)

SELECT distinct storeid
FROM  StoreTransactions_Working

--product and brand

SELECT COUNT(*)
FROM  StoreTransactions_Working
WHERE (ProductID IS NULL)

SELECT distinct productid
FROM  StoreTransactions_Working

SELECT COUNT(*)
FROM  StoreTransactions_Working
WHERE (brandID IS NULL)

SELECT distinct brandid
FROM  StoreTransactions_Working

--supplier

SELECT COUNT(*)
FROM  StoreTransactions_Working
WHERE (supplierID IS NULL)

SELECT COUNT(*)
FROM  StoreTransactions_Working
WHERE supplierID = 0

select * from Suppliers where SupplierIdentifier = 'wr723'--=26645

SELECT distinct supplierID
FROM  StoreTransactions_Working

--Source

SELECT COUNT(*)
FROM  StoreTransactions_Working
WHERE (sourceID IS NULL)


SELECT distinct sourceID
FROM  StoreTransactions_Working

--transaction types

select distinct transactiontypeid
from StoreTransactions

--qty's

select *
from StoreTransactions
where qty <= 0


--update costs
update StoreTransactions
set RuleCost = SetupCost
,TrueCost = SetupCost
,CostMisMatch = 0
,RetailMisMatch = 0
,RuleRetail = SetupRetail
,TrueRetail = SetupRetail
where SetupCost is not null


--initialize inventory

select CurrentOnHandQty, -1 * CurrentOnHandQty + 5, OriginalQty
--update i set CurrentOnHandQty = -1 * CurrentOnHandQty + 5, OriginalQty = -1 * CurrentOnHandQty + 5 + SBTSales
from dbo.InventoryPerpetual i
where CurrentOnHandQty < 0

select top 1000 * from dbo.InventoryPerpetual

select top 1000 * from Datatrue_Report.dbo.InventoryPerpetual where storeid = 35813
select top 1000 * from Datatrue_Report.dbo.StoreTransactions where storeid = 35813

select top 1000 * from Datatrue_Report.dbo.StoreTransactions where supplierid = 24209

select top 1000 * from Datatrue_Report.dbo.StoreSalesBySaleDate



select * from StoreTransactions 
where 1 = 1
and TrueCost <> null
and reportedcost <> 0
and upc = '091925980270'

--zero out brands

select *
from StoreSetup
where ChainID = 35541

select * into zStoreSetup_20110930 from storesetup
select distinct BrandId
--update s set brandid = 0
from StoreSetup s
where ChainID = 35541

select * into zProductPrices_20110930 from ProductPrices
select distinct BrandId s
--update s set brandid = 0
from ProductPrices s
where ChainID = 35541

select *
from ProductBrandAssignments
where BrandID in 
(select distinct BrandId
from StoreSetup
where ChainID = 35541)


update ProductIdentifiers set IdentifierValue = LTRIM(rtrim(IdentifierValue)) + 'ABC'

select * from datatrue_EDI..Inbound852Sales where RecordStatus = 0

select * 
from datatrue_EDI..Inbound852Sales s
inner join Suppliers u
on ltrim(rtrim(s.SupplierIdentifier)) = ltrim(rtrim(u.supplieridentifier))
where RecordStatus = 0

select * 
from datatrue_EDI..Inbound852Sales s
inner join Stores u
on cast(s.SupplierIdentifier as int) = cast(u.storeidentifier AS int)
where RecordStatus = 0

select * 
from datatrue_EDI..Inbound852Sales s
where RecordStatus = 0
and ISNUMERIC(storeidentifier) < 1

select distinct workingstatus
from storetransactions_working
where saledatetime = '11/7/2011'

select * from Products where ProductName = '000912845775'

select * from Products order by DateTimeCreated desc 

update Products set ProductName = LTRIM(rtrim(ProductName)) + '_'

select * into ztmpProducts_201111091621 from Products

select left(productname, len(productname) - 1), * 
--update p set productname = left(productname, len(productname) - 1)
from Products p where right(ProductName, 1) = '_'

select *
--update p set p.ProductName = LTRIM(rtrim(ProductName)) + '-TMP'
from Products p
where productid >= 17912

update ProductIdentifiers set IdentifierValue = LTRIM(rtrim(IdentifierValue)) + '-TMP'
where productid >= 17912


select * from suppliers

select * from StoreTransactions where SaleDateTime = '11/7/2011'

select * 
from StoreTransactions 
where SaleDateTime = '11/7/2011'
and SupplierID = 0

select w.supplierid, s.supplierid, LTRIM(rtrim(w.supplieridentifier)), LTRIM(rtrim(s.supplieridentifier))
--update w set w.SupplierID = s.SupplierID
from storetransactions_working w
inner join Suppliers s
on LTRIM(rtrim(w.supplieridentifier)) = LTRIM(rtrim(s.supplieridentifier))
where saledatetime = '11/7/2011'

select st.SupplierID, w.supplierid
--update st set st.SupplierID = w.supplierid
from StoreTransactions st
inner join StoreTransactions_Working w
on st.WorkingTransactionID = w.StoreTransactionID
where w.SaleDateTime = '11/7/2011'

select *
--update st set st.ChainID = 0
from StoreTransactions st

where st.SaleDateTime = '11/7/2011'

select *
--update st set st.ChainID = 0
from StoreTransactions_working st

where st.SaleDateTime = '11/7/2011'

select top 100 * from systementities
where entitytypeid = 2

insert into systementities
(EntityTypeID, LastUpdateUserID)
Values(2, 2)

--select * from chains
--41353

select t.IdentifierValue, i.IdentifierValue, *
--update i set i.IdentifierValue = t.IdentifierValue
from TempCompare.dbo.ProductIdentifiers t
inner join ProductIdentifiers i
on t.ProductID = i.ProductID
where t.IdentifierValue <> i.IdentifierValue

select t.IdentifierValue, i.IdentifierValue, t.ProductID, i.productid
--update i set i.IdentifierValue = i.IdentifierValue + '-TMP'
from TempCompare.dbo.ProductIdentifiers t
inner join ProductIdentifiers i
on ltrim(rtrim(t.IdentifierValue)) = ltrim(rtrim(i.IdentifierValue))
and  t.ProductID <> i.ProductID

select t.ProductName, i.ProductName
--update i set i.IdentifierValue = t.IdentifierValue
from TempCompare.dbo.Products t
inner join Products i
on t.ProductID = i.ProductID
where t.ProductName <> i.ProductName

select *
from ProductIdentifiers
where LEN(IdentifierValue) = 10

select *
from ProductIdentifiers
where LEN(IdentifierValue) = 11

truncate table cdc.dbo_StoreTransactions_CT

select COUNT(storetransactionid) from StoreTransactions_Working where SaleDateTime = '11/7/2011'
select distinct chainid from StoreTransactions_Working where SaleDateTime = '11/7/2011'

select *
into ProductIdentifiersWrong_20111110
from datatrue_main.dbo.ProductIdentifiers

select *
into ProductIdentifiersBeforeWrong_20111110
from tempcompare.dbo.ProductIdentifiers

select *
from ProductIdentifiersWrong_20111110

select *
from ProductIdentifiersBeforeWrong_20111110
where LEN(identifiervalue) = 11
order by datetimecreated

select ProductID, IdentifierValue
into #elevenwide
from ProductIdentifiersBeforeWrong_20111110
where LEN(identifiervalue) = 11

select ProductID, IdentifierValue
into #twelvewide
from ProductIdentifiersBeforeWrong_20111110
where LEN(identifiervalue) = 12

select ProductID, IdentifierValue
into #tenwide
from ProductIdentifiersBeforeWrong_20111110
where LEN(identifiervalue) = 10

select MIN(productid) from #elevenwide
select MIN(productid) from #tenwide

select e.ProductID, i.ProductID, e.IdentifierValue, i.IdentifierValue, i.DateTimeCreated
--update i set i.identifiervalue = ltrim(rtrim(i.IdentifierValue)) + '-11DUP'
from DataTrue_Main.dbo.ProductIdentifiers i
inner join #elevenwide e
on ltrim(rtrim(i.IdentifierValue)) = '0' + ltrim(rtrim(e.IdentifierValue))
where i.ProductID < 7094
order by i.ProductID desc

select * from DataTrue_Main.dbo.ProductIdentifiers
--update DataTrue_Main.dbo.ProductIdentifiers set identifiervalue = ltrim(rtrim(IdentifierValue)) + '-11DUP'
where productid in 
(
select e.ProductID
--update i set i.identifiervalue = ltrim(rtrim(i.IdentifierValue)) + '-11DUP'
from DataTrue_Main.dbo.ProductIdentifiers i
inner join #elevenwide e
on ltrim(rtrim(i.IdentifierValue)) = '0' + ltrim(rtrim(e.IdentifierValue))
where i.ProductID < 7094
)

select *
into ztmpproductidentifiers_201111101310PM
from productidentifiers


select e.ProductID, i.ProductID, e.IdentifierValue, i.IdentifierValue, i.DateTimeCreated
--update i set i.identifiervalue = ltrim(rtrim(i.IdentifierValue)) + '-11DUP'
from DataTrue_Main.dbo.ProductIdentifiers i
inner join #elevenwide e
on ltrim(rtrim(i.IdentifierValue)) = '0' + ltrim(rtrim(e.IdentifierValue))
where i.ProductID < 7094
order by i.ProductID desc

select ltrim(rtrim(IdentifierValue)), COUNT(productid)
from DataTrue_Main.dbo.ProductIdentifiers
group by ltrim(rtrim(IdentifierValue))
order by COUNT(productid) desc

select *
from #elevenwide
where '0' + ltrim(rtrim(IdentifierValue)) not in 
(select ltrim(rtrim(IdentifierValue)) from Datatrue_Main.dbo.ProductIdentifiers)

select *
from Datatrue_Main.dbo.ProductIdentifiers i
inner join datatrue_edi.dbo.Inbound852Sales s
on ltrim(rtrim(i.IdentifierValue)) = ltrim(rtrim(s.ProductIdentifier))
where Saledate = '11/7/2011'
and i.ProductID < 7094
order by i.ProductID desc


select * from ProductPrices order by ProductID desc
/*
select * from productprices where productid = 18829
18829
18829
18821
18821
18821
18821
18821
18821
18820
18819
18818
18818
18818
18818
18818
18818
18817
18817
18817
18817
18817
18817
18817
18817
18817
18817
18817
18817
18817
18817
18817
18817
18817
18816
18815
18814
18809
18809
18808
18805
18805
18804
18803
18803
18803
18802
18802
18802
18802
*/

select distinct workingstatus
from StoreTransactions_Working
where ChainID = 0

select * into Import..StoreTransactions_20111111 from StoreTransactions

delete from StoreTransactions where chainid = 0

delete from StoreTransactions_working where chainid = 0

update datatrue_edi.dbo.Inbound852Sales set recordstatus = 1

select *
--update s set s.RecordStatus = -7
from datatrue_edi.dbo.Inbound852Sales s
where 1 = 1
and s.RecordStatus = -7
and Saledate = '11/7/2011'

select *
--update s set recordstatus = 0
from Datatrue_Main.dbo.ProductIdentifiers i
inner join datatrue_edi.dbo.Inbound852Sales s
on ltrim(rtrim(i.IdentifierValue)) = ltrim(rtrim(s.ProductIdentifier))
where Saledate = '11/7/2011'
and s.RecordStatus = -7
and i.ProductID < 7094
order by i.ProductID desc



return
GO
