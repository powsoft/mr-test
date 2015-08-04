USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_SuperValue_Entities_Load]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_SuperValue_Entities_Load]

as

return


/*
drop table DataTrue_EDI..Stores
drop table DataTrue_EDI..Suppliers
drop table DataTrue_EDI..Products
drop table DataTrue_EDI..ProductIdentifiers
drop table DataTrue_EDI..Addresses
select *
into DataTrue_EDI..Stores From Stores
select *
into DataTrue_EDI..Suppliers From Suppliers
select *
into DataTrue_EDI..Products From Products
select *
into DataTrue_EDI..ProductIdentifiers from ProductIdentifiers
select *
into DataTrue_EDI..Addresses From Addresses
*/

--Stores

INSERT INTO [DataTrue_EDI].[dbo].[Load_Stores]
           ([ChainsStoreIdentifier]
           ,[ChainIdentifier]
           ,[StoreIdentifier]
           ,[StoreName]
           ,[ActiveStartDate]
           ,[ActiveEndDate]
           ,[LoadStatus])
           
           
 SELECT distinct ltrim(rtrim([ChainIdentifier])) + ltrim(rtrim([StoreIdentifier]))
		,ltrim(rtrim([ChainIdentifier]))
      ,ltrim(rtrim([StoreIdentifier]))
      ,ltrim(rtrim([StoreName])) + ' ' + ltrim(rtrim([StoreIdentifier]))
      ,'1/1/2011'
      ,'12/31/2025'
      ,1
  FROM [DataTrue_EDI].[dbo].[EDI_StoreCrossReference]
  where [ChainIdentifier] = 'SV'


update DataTrue_EDI.dbo.Load_Stores set LoadStatus = 0 where ChainIdentifier = 'SV' 

--Suppliers

update [DataTrue_EDI].[dbo].[Load_Suppliers] set LoadStatus = 1

INSERT INTO [DataTrue_EDI].[dbo].[Load_Suppliers]
           ([ChainIdentifier]
           ,[SupplierName]
           ,[SupplierIdentifier]
           ,[ActiveStartDate]
           ,[ActiveLastDate]
           ,[LoadStatus])
           
           
 SELECT LTRIM(rtrim([ChainIdentifier]))
      ,LTRIM(rtrim([SupplierName]))
      ,LTRIM(rtrim([SupplierIdentifier]))
      ,'1/1/2011'
      ,'12/31/2025'
      ,0
  FROM [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference]
  where LTRIM(rtrim([ChainIdentifier])) = 'SV'


 select * from [DataTrue_EDI].[dbo].[Load_Suppliers] where LTRIM(rtrim([ChainIdentifier])) = 'SV'

update [DataTrue_EDI].[dbo].[Load_Suppliers] 
set SupplierDescription = SupplierName
where LTRIM(rtrim([ChainIdentifier])) = 'SV'

select ls.*, s.*
from [DataTrue_EDI].[dbo].[Load_Suppliers] ls
inner join Suppliers s
on ls.SupplierIdentifier = s.SupplierIdentifier
where ls.ChainIdentifier = 'SV'


select distinct ProductCategoryIdentifier 
from datatrue_edi.dbo.Inbound852Sales
where ChainIdentifier = 'sv'
order by ProductCategoryIdentifier 

update datatrue_edi.dbo.Inbound852Sales
set DivisionIdentifier = ProductCategoryIdentifier
,ProductCategoryIdentifier = ''
WHERE     (ChainIdentifier = 'sv')


--update recordstatus

select * 
--update s set s.recordstatus = 1
from datatrue_edi.dbo.Inbound852Sales s
where RecordStatus = -2
and chainidentifier = 'sv'

select * 
from datatrue_edi.dbo.Inbound852Sales s
where RecordStatus = 0
and chainidentifier = 'sv'

select * from datatrue_edi.dbo.Inbound852Sales
--update datatrue_edi.dbo.Inbound852Sales set RecordStatus = 0
where RecordID not in (1515158, 1515159)
and chainidentifier = 'sv'

select * from datatrue_edi.dbo.Inbound852Sales
where RecordStatus = 1
and chainidentifier = 'sv'

select * from datatrue_edi.dbo.Inbound852Sales
--update Inbound852Sales set RecordStatus = 1
where RecordID = 1515158

--update chainid


select *
from StoreTransactions_working
where ChainID is null
and ChainIdentifier = 'sv'

select *
--update w set w.chainid = 40393
from StoreTransactions_working w
where ChainID is null
and ChainIdentifier = 'sv'

select *
from StoreTransactions
where ChainID = 40393


select *
from StoreTransactions_working
where ChainID = 40393
and SupplierID is null


select *
--update stw set SupplierID = 40559
from StoreTransactions_working stw
where ChainID = 40393
and SupplierIdentifier = '5336706'
and SupplierID is null

select *
--update stw set workingstatus = 4
from StoreTransactions_working stw
where ChainID = 40393
and WorkingStatus = -9999

--audit load quantities

select SUM(Qty)
from StoreTransactions
where ChainID = 40393
and SaleDateTime in ('11/12/2011', '11/13/2011')

select SUM(Qty)
from datatrue_edi.dbo.Inbound852Sales
where ChainIdentifier = 'SV'
and RecordStatus = 1
and SaleDate in ('11/12/2011', '11/13/2011')

--select top 100 * from invoicedetails

select SUM(TotalQty)
from invoicedetails
where chainid = 40393
and saledate in ('11/12/2011', '11/13/2011')

select SUM(TotalQty)
from datatrue_edi.dbo.invoicedetails
where chainid = 40393
and saledate in ('11/12/2011', '11/13/2011')
and retailerinvoiceid is null
--*****************Quantities By SaleDate******************

select SUM(Qty)
from StoreTransactions
where ChainID = 40393
and CAST(saledatetime as DATE) = '10/24/2011'

select SUM(Qty)
from datatrue_edi.dbo.Inbound852Sales
where ChainIdentifier = 'SV'
and RecordStatus <> 0
and CAST(saledate as DATE) = '10/24/2011'

--audit load cost

select SUM(Qty * Cost)
from datatrue_edi.dbo.Inbound852Sales
where ChainIdentifier = 'SV'
and RecordStatus <> 0

select SUM(Qty * ReportedCost)
from StoreTransactions
where ChainID = 40393


select distinct StoreIdentifier, ProductIdentifier, SupplierIdentifier, saledate, recordstatus
from datatrue_edi.dbo.Inbound852Sales
where 1 = 1
and CAST(saledate as DATE) = '10/21/2011'

--select StoreIdentifier, ProductIdentifier, SupplierIdentifier, saledate
select *
--delete
from datatrue_edi.dbo.Inbound852Sales
where 1 = 1
and CAST(saledate as DATE) = '10/21/2011'
and RecordID >= 1762841
order by recordid
--***********************************************************
select *
from StoreTransactions_working
where ChainID = 40393
and cast(SaleDateTime as DATE) = '10/27/2011'

select *
from StoreTransactions
where ChainID = 40393
and cast(SaleDateTime as DATE) = '10/27/2011' 

select distinct TransactionTypeID
from StoreTransactions
where ChainID = 40393


select SUM(Qty * SalePrice)
from datatrue_edi.dbo.Inbound852Sales
where ChainIdentifier = 'SV'
and RecordStatus <> 0
-- 146374.512 + 96729.611
select SUM(Qty * Cost)
from datatrue_edi.dbo.Inbound852Sales
where ChainIdentifier = 'SV'
and RecordStatus <> 0

select 146374.512 + 692779.399



select SUM(Qty * RuleCost)
from StoreTransactions
where ChainID = 40393

--truncate
truncate table datatrue_report.dbo.StoreTransactions
truncate table cdc.dbo_StoreTransactions_CT
truncate table cdc.dbo_InventoryPerpetual_CT


--before allowance applied = 146374.512
--after allowance applied = 134670.332 but 136753.362 allowance applied < rulecost

select SUM(Qty * (RuleCost-ReportedAllowance))
from StoreTransactions
where ChainID = 40393

select *
--Update t set RuleCost = ReportedCost -- - ReportedAllowance
from StoreTransactions t
where 1 = 1
and ReportedCost > ReportedAllowance
and ChainID = 40393
and DateTimeCreated > '10/21/2011'


select *
from StoreTransactions
where RuleCost <= ReportedAllowance
and ChainID = 40393

select distinct TransactionTypeID
from StoreTransactions
where ChainID = 40393

select *
from datatrue_edi.dbo.Inbound852Sales
where ProductIdentifier = '000912846157'



select distinct storeidentifier, DivisionIdentifier
from datatrue_edi.dbo.Inbound852Sales
where ChainIdentifier = 'sv'
order by StoreIdentifier, divisionidentifier

select w.ReportedAllowance, s.reportedAllowance
--update s set s.ReportedAllowance = w.ReportedAllowance
from storetransactions_working w
inner join StoreTransactions s
on w.storetransactionid = s.WorkingTransactionID
where s.ChainID = 40393
and w.ReportedAllowance is null


select *
--update w set chainid = 40393 --workingstatus = 0
from StoreTransactions_Working w
where ChainIdentifier = 'sv'
and workingStatus = 0
order by datetimecreated


--update stores

select *
from StoreTransactions_Working
where WorkingStatus = 1
and StoreID is null

select *
from StoreTransactions_Working
where WorkingStatus = 1
and StoreID = 0

select distinct ltrim(rtrim(storeidentifier))
from StoreTransactions_Working
where WorkingStatus = 0
and StoreIdentifier not in
(select storeidentifier from stores where ChainID = 40393)

select *
from datatrue_EDI.dbo.EDI_StoreCrossReference
where storeidentifier in
(
select distinct ltrim(rtrim(storeidentifier))
from StoreTransactions_Working
where WorkingStatus = 0
and cast(StoreIdentifier as int) not in
(select cast(StoreIdentifier as int) from stores where ChainID = 40393)
)

select *
from datatrue_EDI.dbo.EDI_StoreCrossReference
wHere storeidentifier in
('0005054','0055360')

select *
from stores
where storeidentifier = '0005054'


--update products

select COUNT(ProductId)
from products

--16536 before 11/7/2011 SV reload

--4745 to 4775 = 30 added from 10/27 data
--4698 to 4745 = 47 added from 10/26 data
--4665 to 4698 = 33 added from 10/25 data
--4632 to 4665 = 33 added from 10/24 data


select *
from StoreTransactions_Working
where WorkingStatus = 1
and ProductID is null

--supplier audit
--supplier update 

select distinct w.SupplierIdentifier
from StoreTransactions_Working w
where w.ChainID = 40393
and ltrim(rtrim(w.SupplierIdentifier)) not in
(select ltrim(rtrim(w.SupplierIdentifier)) from Suppliers)

select *
from StoreTransactions_working w
where w.ChainID = 40393
and supplierid is null

select *
from StoreTransactions_working w
where w.ChainID = 40393
and supplierid = 0

select distinct supplierid
from StoreTransactions_working w
where w.ChainID = 40393

select s.SupplierID, s.SupplierIdentifier, 
w.SupplierIdentifier, w.SupplierID, w.workingstatus,
w.datetimecreated
--update w set w.SupplierID = s.SupplierID
from StoreTransactions_Working w
inner join Suppliers s
on ltrim(rtrim(w.SupplierIdentifier)) = ltrim(rtrim(s.SupplierIdentifier))
where 1 = 1
and w.ChainID = 40393
and (w.SupplierID = 0 or w.SupplierID is null) 
and w.WorkingStatus < 5
--and w.DateTimeCreated >= '11/18/2011'
and w.SupplierID is null
and w.WorkingStatus <> -9999

select *
from StoreTransactions_Working
where WorkingStatus = 4

select distinct saledatetime
from StoreTransactions_Working
where WorkingStatus = 4

select top 5000 *
from StoreTransactions_Working

order by DateTimeCreated desc

select *
from storesetup
where ChainID = 40393
and SupplierID = 0

drop table #DistinctStoreTransactions_Working

select distinct
chainid, storeid, ProductId, brandid, supplierid
into #DistinctStoreTransactions_Working
from StoreTransactions_Working
where ChainID = 40393
and SupplierID <> 0

select ss.SupplierID, w.supplierid
--update ss set ss.SupplierID = w.SupplierID
from storesetup ss
inner join #DistinctStoreTransactions_Working w
on ss.ChainID = w.ChainID
and ss.StoreID = w.StoreID
and ss.ProductID = w.ProductID
and ss.BrandID = w.brandid 
where ss.ChainID = 40393
and ss.SupplierID = 0
and ss.storeid <> 0

select * from 
StoreTransactions_Working
where workingstatus = 4

select distinct SupplierIdentifier from StoreTransactions_Working
where StoreTransactionID in
	(
	select WorkingTransactionID
	from StoreTransactions w
	where w.ChainID = 40393
	and supplierid = 0 or supplierid is null
	)
	
select w.supplierid, t.supplierid
--update t set t.supplierid = w.supplierid
from StoreTransactions t
inner join StoreTransactions_Working w
on t.WorkingTransactionID = w.StoreTransactionID
where w.StoreTransactionID in
	(
	select WorkingTransactionID
	from StoreTransactions w
	where w.ChainID = 40393
	and supplierid = 0 or supplierid is null
	)
	
		
select * from Suppliers
where SupplierIdentifier in
('0767392','5178583') --40557 40578

select * from StoreTransactions where SupplierID = 40557 --40578
select SUM(qty) from StoreTransactions where SupplierID = 40557 --40578
	
select workingstatus, COUNT(StoreTransactionID)
from StoreTransactions_Working
group by workingstatus

select distinct transactiontypeid from StoreTransactions
where ChainID = 40393

select distinct WorkingStatus 
from StoreTransactions_working
where ChainID = 40393 or ChainIdentifier = 'SV'

select * --distinct WorkingStatus 
--delete
from StoreTransactions_working
where ChainID = 40393
and DateTimeCreated between '2011-10-24 21:50:00.000' and '2011-10-24 22:15:51.297'
and WorkingStatus = -9999

select * from StoreTransactions
where WorkingTransactionID in 
(
select StoreTransactionID from StoreTransactions_working
where ChainID = 40393
and DateTimeCreated between '2011-10-24 21:50:00.000' and '2011-10-24 22:15:51.297'
)

select *
--update s set recordstatus = -3
from datatrue_EDI.dbo.Inbound852Sales s
where 1 = 1
and ChainIdentifier = 'sv'
and RecordStatus = -2

select top 30000 * from StoreTransactions_working
where RecordID_EDI_852 in
(
select recordid
from datatrue_EDI.dbo.Inbound852Sales s
where 1 = 1
and ChainIdentifier = 'sv'
and RecordStatus = -1
)

select * from StoreTransactions
where WorkingTransactionID in
(
select StoreTransactionID from StoreTransactions_working
where RecordID_EDI_852 in
	(
	select recordid
	from datatrue_EDI.dbo.Inbound852Sales s
	where 1 = 1
	and ChainIdentifier = 'sv'
	and RecordStatus = -1
	)
)


--audit load categories
---update categories

select distinct DivisionIdentifier
from datatrue_EDI.dbo.Inbound852Sales
where ChainIdentifier = 'sv'
order by DivisionIdentifier

--drop table #prodcatassign

select distinct ProductID, ProductIdentifier, DivisionIdentifier, c.ProductCategoryID
into #prodcatassign
from datatrue_EDI.dbo.Inbound852Sales s
inner join ProductIdentifiers p
on s.ProductIdentifier = p.IdentifierValue
inner join ProductCategories c
on s.DivisionIdentifier = c.ProductCategoryName
where ChainIdentifier = 'sv'
and c.ChainID = 40393
and p.ProductIdentifierTypeID = 2
order by DivisionIdentifier


select distinct a.ProductCategoryID, c.ProductCategoryID, *
--update c set c.ProductCategoryID = a.ProductCategoryID
from #prodcatassign a
inner join ProductCategoryAssignments c
on a.ProductID = c.ProductID
where c.ProductCategoryID = 0
and a.ProductCategoryID <> 0

select * from ProductCategoryAssignments
where ProductID in 
(
select ProductID
from #prodcatassign
)

select distinct a.ProductCategoryID
--update a set a.ProductCategoryID = t.ProductCategoryID
from #prodcatassign t
inner join ProductCategoryAssignments a
on t.ProductID = a.ProductID
where a.ProductCategoryID = 0


insert into ProductCategoryAssignments
(ProductCategoryID, ProductID, CustomOwnerEntityID, LastUpdateUserID)
select ProductCategoryID, ProductID, 0, 2
from #prodcatassign
where ProductID not in
(select ProductID from ProductCategoryAssignments)



select distinct a.ProductCategoryID, c.ProductCategoryID, *
--update c set c.ProductCategoryID = a.ProductCategoryID
from #prodcatassign a
inner join ProductCategoryAssignments c
on a.ProductID = c.ProductID
where c.ProductCategoryID = 0
and a.ProductCategoryID <> 0


select *
from StoreTransactions_Working
where ChainIdentifier = 'SV'
and StoreID is null

select *
from StoreTransactions_Working
where ChainIdentifier = 'SV'
and ProductID is null

select *
from StoreTransactions_Working
where ChainIdentifier = 'SV'
and WorkingStatus = 4

select * 
--delete
from StoreTransactions_Working
where ChainIdentifier = 'SV'
and ChainID is null
and WorkingStatus = 0

select * 
from StoreTransactions_Working
where 1 = 1
and WorkingStatus = 4
and ChainIdentifier = 'SV'
and ChainID is null



select distinct ProductId
from StoreTransactions t
where ChainID in (40393)
and ProductID not in 
(select ProductID from ProductCategoryAssignments)

select IdentifierValue
from ProductIdentifiers
where ProductID = 5017

select distinct DivisionIdentifier
from datatrue_edi.dbo.Inbound852Sales
where ProductIdentifier = '007457008202'

select StoreIdentifier as storeident, divisionidentifier as divisionident, *
from datatrue_edi.dbo.Inbound852Sales
where ProductIdentifier = '007457008202'
order by StoreIdentifier, divisionidentifier

select ProductIdentifier, divisionidentifier, COUNT(recordid)
from datatrue_edi.dbo.Inbound852Sales
where ChainIdentifier = 'SV'
group by ProductIdentifier, divisionidentifier
order by ProductIdentifier, divisionidentifier
--having COUNT(recordid) > 1

select distinct ProductIdentifier
from datatrue_edi.dbo.Inbound852Sales
where ChainIdentifier = 'SV'

select distinct UPC
from StoreTransactions
where ChainID = 40393

select COUNT(storetransactionid)
from StoreTransactions

select COUNT(storetransactionid)
from StoreTransactions_working


--billing

select * 
--update d set RetailerInvoiceID = null
from InvoiceDetails  d
where ChainID = 40393 

update d set SupplierInvoiceID = null
from InvoiceDetails  d
where ChainID = 40393 

select *
--update f set f.billingruleid = 1
from ChainProductFactors f
where ChainID = 40393

select distinct billingruleid
from ChainProductFactors f
where ChainID = 40393

update Datatrue_EDI.dbo.InvoiceDetails set recordstatus = 0 where ChainID = 40393

select * from InvoiceDetails where ChainID = 40393 order by totalcost

select * from InvoiceDetails where ChainID = 40393 
and Invoicedetailtypeid = 1
order by totalcost

select * from InvoicesRetailer  where ChainID = 40393
select * from InvoicesSupplier --where ChainID = 40393

select * from Datatrue_EDI.dbo.InvoiceDetails where ChainID = 40393
select * from Datatrue_EDI.dbo.InvoicesRetailer  where ChainID = 40393

delete from InvoiceDetails where ChainID = 40393
delete from InvoicesRetailer  where ChainID = 40393
delete from Datatrue_EDI.dbo.InvoiceDetails where ChainID = 40393
delete from Datatrue_EDI.dbo.InvoicesRetailer  where ChainID = 40393

update InvoiceDetails 
set REtailerInvoiceID = null
where ChainID = 40393

select distinct transactionstatus
--update st set transactionstatus = 811
from StoreTransactions st
where ChainID = 40393

select *
--update st set transactionstatus = 0
from StoreTransactions st
where ChainID = 40393
and CAST(saledatetime as DATE) = '10/16/2011'

select transactionstatus, COUNT(StoreTransactionID)
from StoreTransactions st
where ChainID = 40393
group by TransactionStatus

select SUM(qty)
from StoreTransactions st
where ChainID = 40393
and TransactionStatus = 0

select *
from StoreTransactions st
where ChainID = 40393
and transactionstatus = 0

--billing audit

select * from InvoiceDetails where ChainID = 40393 order by totalcost
select * from InvoicesRetailer  where ChainID = 40393
select * from InvoicesSupplier --where ChainID = 40393

select * from Datatrue_EDI.dbo.Inbound852Sales
where Saledate = '10/16/2011'
order by saleprice

select SUM(Qty * Cost)
from datatrue_edi.dbo.Inbound852Sales
where ChainIdentifier = 'SV'
and Saledate = '10/24/2011'

select SUM(Qty)
from datatrue_edi.dbo.Inbound852Sales
where ChainIdentifier = 'SV'
and Saledate = '10/16/2011'
and Cost <> 0


select SUM(Qty * Cost)
from datatrue_edi.dbo.Inbound852Sales
where ChainIdentifier = 'SV'
and RecordStatus <> 0

select SUM(totalCost) from InvoiceDetails 
where ChainID = 40393
and SaleDate = '10/24/2011'
and InvoiceDetailTypeID = 1

select SUM(totalCost) from InvoiceDetails 
where ChainID = 40393
and InvoiceDetailTypeID = 1

select SUM(totalCost) from datatrue_EDI.dbo.InvoiceDetails 
where ChainID = 40393
and InvoiceDetailTypeID = 1

delete from datatrue_EDI.dbo.InvoiceDetails where RetailerInvoiceID is null

select SUM(totalqty) from InvoiceDetails 
where ChainID = 40393
and InvoiceDetailTypeID = 1

select SUM(totalqty) from datatrue_EDI.dbo.InvoiceDetails 
where ChainID = 40393
and InvoiceDetailTypeID = 1

select *
from datatrue_EDI.dbo.InvoiceDetails 
where ChainID = 40393
and InvoiceDetailTypeID = 1
and TotalCost = 0

select * from InvoicesRetailer  where ChainID = 40393
select * from InvoicesSupplier --where ChainID = 40393

select * from datatrue_EDI.dbo.InvoicesRetailer  where ChainID = 40393
select SUM(originalamount) from datatrue_EDI.dbo.InvoicesRetailer  where ChainID = 40393

select * from datatrue_EDI.dbo.InvoicesSupplier --where ChainID = 40393

select SUM(OriginalAmount) from datatrue_EDI.dbo.InvoicesRetailer  where ChainID = 40393


select *
from StoreTransactions
where ChainID = 40393
and CAST(saledatetime as DATE) = '10/16/2011'
order by transactionstatus

select SUM(qty)
from StoreTransactions
where ChainID = 40393
and CAST(saledatetime as DATE) = '10/16/2011'


--*****************Item File**************************

select productcode, COUNT(basecost)
from datatrue_edi.dbo.SV_ItemFile
group by ProductCode
having COUNT(basecost) < 2
order by COUNT(basecost) desc

select Banner as bnr, [CostEffectiveDate(TEMPORARYCOSTS)] as effdate, BaseCost as bc, NetCost as nc, *
from datatrue_edi.dbo.SV_ItemFile
where ProductCode = '0080487918525' --0007192100006' 
order by  Banner, CAST([CostEffectiveDate(TEMPORARYCOSTS)] as DATE)  

select * from datatrue_edi.dbo.copy_Chains_WorkingTable
             

update [DataTrue_EDI].[dbo].[Load_Products]
set ProductPrice = productcost

select distinct ProductCode
from datatrue_edi.dbo.SV_ItemFile
where LTRIM(rtrim(ProductCode))
not in
(select LTRIM(rtrim(identifiervalue)) from productidentifiers)

select *
from datatrue_edi.dbo.SV_ItemFile
where LTRIM(rtrim(ProductCode))
not in
(select LTRIM(rtrim(identifiervalue)) from productidentifiers)

select distinct ProductCode
from datatrue_edi.dbo.SV_ItemFile

select *

FROM productidentifiers p
inner join [DataTrue_EDI].[dbo].[SV_ItemFile] i
on LTRIM(rtrim(p.identifiervalue)) = LTRIM(rtrim(i.ProductCode))

update [DataTrue_EDI].[dbo].[Load_Products] set LoadStatus = 0

select * from [DataTrue_EDI].[dbo].[Load_Products] where ProductIdentifier not in
(select IdentifierValue from ProductIdentifiers)

select * from [DataTrue_EDI].[dbo].[Load_Products]
where RecordID >= 21520


INSERT INTO [DataTrue_EDI].[dbo].[Load_Products]
           ([ProductIdentifier]
           ,[ProductDescription]
           ,[ProductPrice]
           ,[ProductCost]
           ,[ActiveStartDate]
           ,[ActiveLastDate]
           ,[LoadStatus]
           ,[LoadType])
SELECT distinct [ProductCode]
      ,[Description]
      ,[BaseCost]
      ,[BaseCost]
      ,'1/1/2000' --cast([CostEffectiveDate(TEMPORARYCOSTS)] as DATE)
      ,'12/31/2025'
      ,0
      ,'ADD'
  FROM [DataTrue_EDI].[dbo].[SV_ItemFile]
where LTRIM(rtrim(ProductCode))
not in
(select LTRIM(rtrim(identifiervalue)) from productidentifiers)
  
  --loading recordid 9860 and 9861

declare @productid int
select @productid = 7094 --MAX(productid) from Products

select * from Products where ProductID >= @productid
select * from ProductIdentifiers where ProductID >= @productid
select * from ProductBrandAssignments where ProductID >= @productid
select * from ProductCategoryAssignments where ProductID >= @productid
select * from ProductPrices where ProductID >= @productid


select * from ChainProductFactors where ChainID = 40393

--chainproductfactor update

INSERT INTO [DataTrue_Main].[dbo].[ChainProductFactors]
           ([ChainID]
           ,[ProductID]
           ,[BrandID]
           ,[BaseUnitsCalculationPerNoOfweeks]
           ,[CostFromRetailPercent]
           ,[BillingRuleID]
           ,[IncludeDollarDiffDetails]
           ,[ActiveStartDate]
           ,[ActiveEndDate]
           ,[LastUpdateUserID])
select 40393
		,ProductId
		,0
		,17
		,75
		,1
		,1
		,'2000-01-01 00:00:00'
		,'12/31/2025'
		,2
from Products
where ProductID not in (select productid from ChainProductFactors)
--where ProductID >= 7094


select *
from ProductIdentifiers i
inner join DataTrue_EDI.dbo.SV_ItemFile p
on left(ltrim(rtrim(i.IdentifierValue)), 11) = ltrim(rtrim(p.ProductCode))

--Base cost
select pr.*
from ProductPrices pr
inner join ProductIdentifiers i
on pr.productid = i.productid
inner join DataTrue_EDI.dbo.SV_ItemFile p
on ltrim(rtrim(i.IdentifierValue)) = ltrim(rtrim(p.ProductCode))
order by pr.productid


select ltrim(rtrim(productcode)), COUNT(basecost)
from datatrue_edi.dbo.SV_ItemFile
where ProductCode is not null
group by ltrim(rtrim(productcode))
having COUNT(basecost) < 2
order by COUNT(basecost) desc

select productcode, BaseCost--, NetCost, Allowance, UnitMeasure, qty, Pack
--into #costproductssingle
from datatrue_edi.dbo.SV_ItemFile
group by productcode, BaseCost--, NetCost, Allowance, UnitMeasure, qty, Pack
having COUNT(basecost) < 2
order by COUNT(basecost) desc

select *
from datatrue_edi.dbo.SV_ItemFile
where ISNUMERIC(qty) < 1

declare @rec cursor
declare @productcode nvarchar(50)
--declare @productid int
declare @basecost money
declare @netcost money
declare @allowance money
declare @uom nvarchar(50)
declare @qty dec(12,2)
declare @pack int

set @rec = CURSOR local fast_forward for
	select top 10 ltrim(rtrim(productcode))
	from datatrue_edi.dbo.SV_ItemFile
	where ProductCode is not null
	group by ltrim(rtrim(productcode))
	having COUNT(basecost) < 2
	order by COUNT(basecost)
	
open @rec

fetch next from @rec into @productcode

while @@FETCH_STATUS = 0
	begin
print @productcode	

		select @basecost = basecost
			,@netcost = netcost
			,@allowance = allowance
			,@uom = unitmeasure
			,@qty = qty
			,@pack = pack
			from datatrue_edi.dbo.SV_ItemFile
			where ProductCode = @productcode

	select @productid = productid from ProductIdentifiers where IdentifierValue = @productcode
print str(@productid)
		fetch next from @rec into @productcode	
	end
	
close @rec
deallocate @rec


--stores

select * from storesetup where ChainID = 40393
select distinct storeid from storesetup where ChainID = 40393

select *
--update s set loadstatus = 5
from [DataTrue_EDI].[dbo].[Load_Stores] s
where LoadStatus = 0

select distinct storenumber from datatrue_edi.dbo.copy_Chains_WorkingTable

select * from datatrue_edi.dbo.copy_Chains_WorkingTable
where storenumber = 101

select * from stores where ChainID = 40393

select * into Import..Stores_20111109 from stores

select * from #storenumber

select distinct storenumber into #storenumber
from datatrue_edi.dbo.copy_Chains_WorkingTable

select 'SuperValu - ' + cast(cast(w.storenumber as int) as nvarchar), s.* 
--update s set storename = 'SuperValu - ' + cast(cast(w.storenumber as int) as nvarchar)
from #storenumber w
inner join stores s
on CAST(storenumber as int) = CAST(storeidentifier as int)
and s.ChainID = 40393


select * from datatrue_edi.dbo.copy_Chains_WorkingTable
where CAST(storenumber as int) not in
(select CAST(storeidentifier as int) from stores)

INSERT INTO [DataTrue_EDI].[dbo].[Load_Stores]
           ([ChainsStoreIdentifier]
           ,[ChainIdentifier]
           ,[StoreIdentifier]
           ,[StoreName]
           ,[City]
           ,[State]
           ,[ActiveStartDate]
           ,[ActiveEndDate])
SELECT Distinct 'SV' + LTRIM(rtrim([storenumber]))
	  ,'SV'
      ,LTRIM(rtrim([storenumber]))
      ,'SuperValu - ' + cast(storenumber as nvarchar) --+ ' (' + isnull(LTRIM(rtrim([storename])), '') + ')'
      ,'' --[storecity]
      ,'' --[storestate]
      ,'1/1/2000'
      ,'12/31/2025'

  FROM [DataTrue_EDI].[dbo].[copy_Chains_WorkingTable]
where CAST(storenumber as int) not in
(select CAST(storeidentifier as int) from stores where ChainID = 40393)
order by LTRIM(rtrim([storenumber]))

select *
--delete
from [DataTrue_EDI].[dbo].[Load_Stores]
where 1 = 1
--and ChainIdentifier = 'SV'
and LoadStatus = 0


select MAX(storeid) from stores

declare @storeid int
set @storeid = 40742

select * from stores where StoreID >= @storeid
select * from ContactInfo where OwnerEntityID >= @storeid
select * from Addresses where OwnerEntityID >= @storeid 

select * from stores where chainID = 40393


select REPLACE(s.StoreName, ' ()', ''), *
--select *
--update s set StoreName = REPLACE(s.StoreName, ' ()', '')
from stores s
where ChainID = 40393

--update banner

select *
  FROM [DataTrue_EDI].[dbo].[copy_Chains_WorkingTable]
  
  select *
  FROM [DataTrue_EDI].[dbo].[copy_Chains_WorkingTable]
  where 1 = 1
  and storenumber is null
  
  select distinct storenumber, filename
  into #storeno_filename
  from [DataTrue_EDI].[dbo].[copy_Chains_WorkingTable]
  
delete from #storeno_filename where storenumber is null
  
select * from #storeno_filename

select
case 
	when charindex('SV_ACME', filename) > 0 then 'ACME'
	when charindex('SV_IMW', filename) > 0 then 'IMW'
	when charindex('SV_CUB', filename) > 0 then 'CUB'
	when charindex('SV_FF', filename) > 0 then 'FF'
	when charindex('SV_SHPS', filename) > 0 then 'SHPS'
	when charindex('SV_SS', filename) > 0 then 'SS'
	when charindex('SV_SCAL', filename) > 0 then 'SCAL'
	when charindex('SV_HB', filename) > 0 then 'HB'
end,
 w.filename, s.*,
--update s set custom1 =
case 
	when charindex('SV_ACME', filename) > 0 then 'ACME'
	when charindex('SV_IMW', filename) > 0 then 'IMW'
	when charindex('SV_CUB', filename) > 0 then 'CUB'
	when charindex('SV_FF', filename) > 0 then 'FF'
	when charindex('SV_SHPS', filename) > 0 then 'SHPS'
	when charindex('SV_SS', filename) > 0 then 'SS'
	when charindex('SV_SCAL', filename) > 0 then 'SCAL'
	when charindex('SV_HB', filename) > 0 then 'HB'
end
from #storeno_filename w
inner join stores s
on CAST(storenumber as int) = CAST(storeidentifier as int)
and s.ChainID = 40393
order by filename


select * from stores where CAST(storeidentifier as int) = 6019

--vendors

select *
  from [DataTrue_EDI].[dbo].[copy_Chains_WorkingTable]
  
  

select distinct vendornumber
  from [DataTrue_EDI].[dbo].[copy_Chains_WorkingTable]  
 
 select * from Suppliers
 where SupplierID in
(select distinct supplierid from storetransactions where ChainID = 40393)
order by SupplierName
  
select distinct vendor, Vendorapnumber
  from [DataTrue_EDI].[dbo].[copy_Chains_WorkingTable] 
  order by vendor
  
 select distinct recordstatus 
 from datatrue_edi.dbo.Inbound852Sales s
  
 --Repair Products
   select *
 --update s set RecordStatus = 0  
 from datatrue_edi.dbo.Inbound852Sales s
 where RecordStatus = 0
 --and banner = 'SS'
 
 
   select *
   --update s set recordstatus = 0
 from datatrue_edi.dbo.Inbound852Sales s
 inner join ProductIdentifiers i
 on ltrim(rtrim(s.ProductIdentifier)) = ltrim(rtrim(i.identifiervalue))
 where RecordStatus = -8
 --group by ProductIdentifier
 --order by COUNT(recordid) desc
 
  --UPC audit 
   select *
 from datatrue_edi.dbo.Inbound852Sales
  where RecordStatus = 0
  and ltrim(rtrim(ProductIdentifier))
  not in 
(select ltrim(rtrim(identifiervalue)) from ProductIdentifiers)

 select distinct UPC from StoreTransactions_Working where WorkingStatus = 1
 select distinct workingstatus from StoreTransactions_Working
 select * from StoreTransactions_Working where WorkingStatus = 2
 
    select *
    --update w set w.workingstatus = -99 --SS UPCs that didn't match ommited from load
 from StoreTransactions_Working w
  where workingStatus = 1
  and ltrim(rtrim(UPC))
  not in 
(select ltrim(rtrim(identifiervalue)) from ProductIdentifiers)


    select *
 from StoreTransactions_Working
  where workingStatus = 1
  and substring(ltrim(rtrim(UPC)), 2, 10)
  not in 
(select substring(ltrim(rtrim(identifiervalue)), 2, 10) from ProductIdentifiers)
--and SUBSTRING(g.productid, 2, 10) = substring(t.ProductIdentifier, 2, 10)


    select distinct UPC
 from StoreTransactions_Working
  where workingStatus = 1
  and ltrim(rtrim(UPC))
  not in 
(select ltrim(rtrim(identifiervalue)) from ProductIdentifiers)
 
   select distinct ProductIdentifier
   into Import..ztmpDistinctUPCsNotLoaded20111114
 from datatrue_edi.dbo.Inbound852Sales
  where RecordStatus = 0
  and ltrim(rtrim(ProductIdentifier))
  not in 
(select ltrim(rtrim(identifiervalue)) from ProductIdentifiers)

select * from Import..ztmpDistinctUPCsNotLoaded20111114 order by ProductIdentifier

select *
--update s set s.recordstatus = -8
 from datatrue_edi.dbo.Inbound852Sales s
inner join Import..ztmpDistinctUPCsNotLoaded20111114 i
on LTRIM(rtrim(s.ProductIdentifier)) =  LTRIM(rtrim(i.ProductIdentifier))
where s.RecordStatus = 0

--****************stores*******************
   select *
 from datatrue_edi.dbo.Inbound852Sales s
 where RecordStatus = 0

select *
--update s set s.recordstatus = -8
 from datatrue_edi.dbo.Inbound852Sales s
inner join stores i
on cast(LTRIM(rtrim(s.storeIdentifier)) as int) =  cast(LTRIM(rtrim(i.storeIdentifier)) as int)
where s.RecordStatus = 0
and i.ChainID = 40393
--****************stores*******************

--****************suppliers****************
select *
--update s set s.recordstatus = -8
 from datatrue_edi.dbo.Inbound852Sales s
inner join suppliers i
on LTRIM(rtrim(s.supplierIdentifier)) =  LTRIM(rtrim(i.supplierIdentifier))
--on cast(LTRIM(rtrim(s.supplierIdentifier)) as int) =  cast(LTRIM(rtrim(i.supplierIdentifier)) as int)
where s.RecordStatus = 0
--and i.ChainID = 40393

select distinct LTRIM(rtrim(supplierIdentifier))
 from datatrue_edi.dbo.Inbound852Sales s
 where LTRIM(rtrim(supplierIdentifier))
 not in 
(select LTRIM(rtrim(supplierIdentifier)) from suppliers)
and RecordStatus = 0

--*****************************************

select distinct workingstatus from StoreTransactions_Working

update StoreTransactions_Working set WorkingStatus = -4 where WorkingStatus = 4
update StoreTransactions_Working set WorkingStatus = -5 where WorkingStatus = 0

select * from StoreTransactions_Working where WorkingStatus = 2 and ProductID is null
 
 select identifiervalue, COUNT(productid)
 from ProductIdentifiers
 group by identifiervalue
 order by COUNT(productid) desc
 
  select *
 from datatrue_edi.dbo.Inbound852Sales s
 inner join ProductIdentifiers i
 on s.ProductIdentifier = i.identifiervalue
 where RecordStatus = -7
 --group by ProductIdentifier
 --order by COUNT(recordid) desc
 
update datatrue_edi.dbo.Inbound852Sales
set RecordStatus = 0 
 where RecordStatus = -7
 
 drop table #pendingproducts
 --10 and 11 match
 select cast(0 as int) as recordstatus, ProductIdentifier, COUNT(recordid) as cnt
 into #pendingproducts
 from datatrue_edi.dbo.Inbound852Sales s
 where RecordStatus = -8
 group by ProductIdentifier
 order by COUNT(recordid) desc
 
 declare @recx cursor
 declare @productidentifier nvarchar(50)
 declare @productid10 int
 declare @productid11 int
 declare @productid12 int
 declare @productid13 int
 declare @productsfoundcount smallint
 declare @dummy smallint

 set @recx = CURSOR local fast_forward FOr
  select distinct ProductIdentifier 
  from #pendingproducts
  where recordstatus = 0
  /*
  where ProductIdentifier not in
  ('000928102218'
  ,'000928102878'
  )
  */
 
 open @recx
 
 fetch next from @recx into @productidentifier
 
 while @@FETCH_STATUS = 0
	begin
	
	set @productsfoundcount = 0
	
		select @productid10 = ProductId from ProductIdentifiers where RIGHT(@productidentifier, 10) = identifiervalue
		if @@ROWCOUNT > 0
			set @productsfoundcount = @productsfoundcount + 1
print @productidentifier

		select @productid11 = ProductId from ProductIdentifiers where RIGHT(@productidentifier, 11) = identifiervalue
		if @@ROWCOUNT > 0
			set @productsfoundcount = @productsfoundcount + 1
print '10'
print @productid10			
print '11'
print @productid11
		if @productsfoundcount = 2
			begin
				if @productid10 > @productid11
					begin
						set @dummy = 0
						--update ProductIdentifiers set IdentifierValue = IdentifierValue + 'XXX' where ProductID = @productid10
						--update ProductIdentifiers set IdentifierValue = '0' + IdentifierValue where ProductID = @productid11
						--update #pendingproducts set recordstatus = 1 where ProductIdentifier =  @productidentifier
					end

			end
		if @productsfoundcount = 1
			begin
				if @productid11 is not null
					begin
						set @dummy = 0
						--update ProductIdentifiers set IdentifierValue = IdentifierValue + 'XXX' where ProductID = @productid10
						update ProductIdentifiers set IdentifierValue = '0' + IdentifierValue where ProductID = @productid11
						update #pendingproducts set recordstatus = 1 where ProductIdentifier =  @productidentifier
					end

			end				
		
		fetch next from @recx into @productidentifier	
	end
	
close @recx
deallocate @recx
 
 
 /*
 drop table #pendingproducts
 --13 match
 select cast(0 as int) as recordstatus, ProductIdentifier, COUNT(recordid) as cnt
 into #pendingproducts
 from datatrue_edi.dbo.Inbound852Sales s
 where RecordStatus = -8
 group by ProductIdentifier
 order by COUNT(recordid) desc
 
 declare @recx cursor
 declare @productidentifier nvarchar(50)
 declare @productid10 int
 declare @productid11 int
 declare @productid12 int
 declare @productid13 int
 declare @productsfoundcount smallint
 declare @dummy smallint

 set @recx = CURSOR local fast_forward FOr
  select distinct ProductIdentifier 
  from #pendingproducts
  where recordstatus = 0
  /*
  where ProductIdentifier not in
  ('000928102218'
  ,'000928102878'
  )
  */
 
 open @recx
 
 fetch next from @recx into @productidentifier
 
 while @@FETCH_STATUS = 0
	begin
	
	set @productsfoundcount = 0
	
		select @productid13 = ProductId from ProductIdentifiers where @productidentifier = right(identifiervalue, 12)
		if @@ROWCOUNT > 0
			set @productsfoundcount = @productsfoundcount + 1
print @productidentifier

print '13'
print @productid13			

		if @productsfoundcount = 1
			begin
				if @productid11 is not null
					begin
						set @dummy = 0
						--update ProductIdentifiers set IdentifierValue = IdentifierValue + 'XXX' where ProductID = @productid10
						--update ProductIdentifiers set IdentifierValue = '0' + IdentifierValue where ProductID = @productid11
						--update #pendingproducts set recordstatus = 1 where ProductIdentifier =  @productidentifier
					end

			end				
		
		fetch next from @recx into @productidentifier	
	end
	
close @recx
deallocate @recx
 */
 
 /*
 update ProductIdentifiers set IdentifierValue = ltrim(rtrim(IdentifierValue))
 007313000132
007313000732
007313000125
007313002855
007313000073
 */
 
 select *
 from ProductIdentifiers
 where 1=1
 and CHARINDEX('7313000132', Identifiervalue) > 0 
 
 select *
 from ProductPrices
 where ProductID = 14255
 
 
 
 --where CAST(ltrim(rtrim(IdentifierValue)) as bigint) = cast('007313000132'  as bigint)
 --and 

 
select * from StoreTransactions
where ChainID = 40393
and TransactionStatus = 0 
and SaleDateTime = '11/7/2011'
order by TransactionTypeID desc
 
 select *
 from InvoiceDetails
 where SaleDate = '11/7/2011'
 and RetailerInvoiceID is null
 
 --storelist load queries
 select * into Stores_201111111237PM from DataTrue_Main.dbo.stores
select * from Stores_201111111237PM

select * from Import.dbo.sVStores where cast(storenumber as int) = 52012 --'0052012'

select distinct CAST(storenumber as int) from Import.dbo.sVStores

select *
from DataTrue_Main.dbo.stores ds
where ds.ChainID = 40393
order by Custom2

select *
from Import.dbo.sVStores s
order by cast(StoreNumber as int)

select CAST(StoreNumber as int), COUNT(*)
from Import.dbo.sVStores s
group by cast(StoreNumber as int)
order by COUNT(*) desc



select *
from Import.dbo.sVStores
where cast(StoreNumber as int) IN
(
6062,
6006,
6009,
6011,
6012,
6013,
6016,
6017,
6018,
6019,
6024,
6029,
6043,
6039,
6059
)
order by cast(StoreNumber as int)

select *
--update ds set ds.Custom1 = s.Banner, ds.StoreName = s.StoreName, ds.Custom2 = s.[SBT Number]
from Import.dbo.sVStores s
inner join DataTrue_Main.dbo.stores ds
on cast(s.storenumber as int) = cast(ds.StoreIdentifier as int)
and ds.ChainID = 40393
and custom2 <> [SBT number]

select SupplierID, SupplierName from datatrue_main.dbo.suppliers where supplierid in
(
select distinct supplierid from datatrue_main.dbo.storetransactions where chainid = 40393
)
order by SupplierName

select distinct banner from Import.dbo.sVStores

select distinct custom1 from stores

update Import.dbo.sVStores set dtbanner = 'Albertsons - ACME' where Banner = 'ACME'
update Import.dbo.sVStores set dtbanner = 'Albertsons - SCAL' where Banner = 'Albertsons'
update Import.dbo.sVStores set dtbanner = 'Cub Foods' where Banner = 'Cub'
update Import.dbo.sVStores set dtbanner = 'Cub Foods' where Banner = 'Cub (Diamond Lake LLC)'
update Import.dbo.sVStores set dtbanner = 'Farm Fresh Markets' where Banner = 'Farm Fresh'
update Import.dbo.sVStores set dtbanner = 'Hornbachers' where Banner = 'Hornbachers'
update Import.dbo.sVStores set dtbanner = 'Albertsons - IMW' where Banner = 'IMW'
update Import.dbo.sVStores set dtbanner = 'Shop N Save Warehouse Foods Inc' where Banner = 'Shop N Save'
update Import.dbo.sVStores set dtbanner = 'Shoppers Food and Pharmacy' where Banner = 'Shoppers'
update Import.dbo.sVStores set dtbanner = 'Farm Fresh Markets' where Banner = 'GW Marketplace'



select a.*, ds.*, s.*
--update a set a.addressdescription = s.StoreName, a.Address1 = s.Address, a.city = s.city, a.state = s.state, a.postalcode = s.zipcode
from Import.dbo.sVStores s
inner join DataTrue_Main.dbo.stores ds
on cast(s.storenumber as int) = cast(ds.StoreIdentifier as int)
and LTRIM(rtrim(s.dtBanner)) = LTRIM(rtrim(ds.custom1))
left join DataTrue_Main.dbo.Addresses a
on ds.StoreID = a.OwnerEntityID
where ds.ChainID = 40393
and a.AddressID is null
order by a.OwnerEntityID

--add addresses add

declare @recaddress cursor
declare @addressstoreid int
declare @storename nvarchar(50)
declare @address1 nvarchar(255)
declare @city nvarchar(100)
declare @state nvarchar(5)
declare @zip nvarchar(50)


set @recaddress = CURSOR local fast_forward FOR

select ds.storeid, ds.StoreName, s.Address, s.City, s.State, s.ZipCode
from Import.dbo.sVStores s
inner join DataTrue_Main.dbo.stores ds
on cast(s.storenumber as int) = cast(ds.StoreIdentifier as int)
and LTRIM(rtrim(s.Banner)) = LTRIM(rtrim(ds.custom1))
left join DataTrue_Main.dbo.Addresses a
on ds.StoreID = a.OwnerEntityID
where ds.ChainID = 40393
and a.AddressID is null
order by a.OwnerEntityID

open @recaddress

fetch next from @recaddress into 
	@addressstoreid
	,@storename
	,@address1
	,@city
	,@state
	,@zip

while @@FETCH_STATUS = 0
	begin
	
INSERT INTO [DataTrue_Main].[dbo].[Addresses]
           ([OwnerEntityID]
           ,[AddressDescription]
           ,[Address1]
           ,[City]
           ,[State]
           ,[PostalCode]
           ,[LastUpdateUserID])
     VALUES
           (@addressstoreid
			,@storename
			,@address1
			,@city
			,@state
			,@zip
			,2)
					
		fetch next from @recaddress into 
			@addressstoreid
			,@storename
			,@address1
			,@city
			,@state
			,@zip	
	end
	
close @recaddress
deallocate @recaddress

select distinct workingstatus from StoreTransactions_Working
 
 select * 
 --Update w set workingstatus = -6
 from StoreTransactions_Working w 
 where RecordID_EDI_852 in
 (select recordid
 from DataTrue_EDI.dbo.Inbound852Sales where FileName = 'sb1113sv.txt')
 
 select * 
 --Update w set workingstatus = -7
 from StoreTransactions_Working w 
 where RecordID_EDI_852 in
 (select recordid
 from DataTrue_EDI.dbo.Inbound852Sales where FileName = 'sl1113sa.txt')
 
 select distinct transactionstatus from StoreTransactions
 
 select *
 --update st set transactionstatus = 44
 from StoreTransactions st
 inner join StoreTransactions_Working w
 on st.WorkingTransactionID = w.StoreTransactionID
 where w.WorkingStatus in (-6, -7)
 
 Select distinct invoicebatchid
 from StoreTransactions st
 where TransactionStatus = 44
 
 select * into Import.dbo.InvoiceDetails_20111115Main from InvoiceDetails
 select * into Import.dbo.InvoiceDetails_20111115EDI from datatrue_edi.dbo.InvoiceDetails
 
 select * into Import.dbo.InvoicesRetailer_20111115Main from InvoicesRetailer
 select * into Import.dbo.InvoicesRetailer_20111115EDI from datatrue_edi.dbo.InvoicesRetailer 
 
 /*
 select * delete from InvoicesRetailer where RetailerInvoiceID in
 (select RetailerInvoiceID from InvoiceDetails where BatchID = '1443')
  
 select * delete from datatrue_edi.dbo.InvoicesRetailer where RetailerInvoiceID in
 (select RetailerInvoiceID from InvoiceDetails where BatchID = '1443')

 select RetailerInvoiceID delete from InvoiceDetails where BatchID = '1443'
  select RetailerInvoiceID delete from datatrue_edi.dbo.InvoiceDetails where BatchID = '1443'
  */
  
 select *
 from InvoiceDetails
 where BatchID = '1443'
 
  Select *
  --delete
 from StoreTransactions 
 where TransactionStatus = 44
 
  select *
 --update w set transactionstatus = 44
 --delete 
 from StoreTransactions_Working
 where WorkingStatus in (-6, -7)
 
  select * 
 from DataTrue_EDI.dbo.Inbound852Sales 
 where recordstatus = 0
 
 select * 
 --Update s set s.recordstatus = 0
 from DataTrue_EDI.dbo.Inbound852Sales s 
 where FileName in ('sb1113sv.txt', 'sl1113sa.txt')

select * from stores
where ChainID = 40393

select distinct custom1 from stores
where ChainID = 40393
 order by Custom1
 
 
 
 select * 
 --Update w set workingstatus = -7
 from StoreTransactions_Working w 
 where RecordID_EDI_852 in
 (select recordid
 from DataTrue_EDI.dbo.Inbound852Sales where FileName = 'sl1113sa.txt')
  
  select *
  --update w set w.Banner = s.Custom1
 from StoreTransactions_Working w  --where WorkingStatus = 0
 inner join stores s
 on LTRIM(rtrim(w.storeidentifier)) = LTRIM(rtrim(s.storeidentifier))
 where WorkingStatus = 0
and ltrim(rtrim(s.custom1)) <> 'Albertsons'


   select *
 from datatrue_edi.dbo.Inbound852Sales s
 where RecordStatus = 0
 
    select distinct banner
 from datatrue_edi.dbo.Inbound852Sales s
 where RecordStatus = 0
 
     select * -- distinct banner
    --update s set Banner =  'Albertsons'
 from datatrue_edi.dbo.Inbound852Sales s
 where RecordStatus = 0
 and banner = 'ABS'
 
      select distinct saledate
 from datatrue_edi.dbo.Inbound852Sales s
 where RecordStatus = 0
 
 select *
 from StoreTransactions_Working
 where WorkingStatus = 0
 
  select storeidentifier
 from StoreTransactions_Working
 where WorkingStatus = 0
 and CAST(storeidentifier as int) not in
 (select CAST(storeidentifier as int) from Stores where ChainID = 40393)
 
 select s.storeid, s.Custom1, w.Banner, *
from StoreTransactions_Working w
 inner join stores s
 on CAST(w.storeidentifier as int) = CAST(s.storeidentifier as int)
 where WorkingStatus = 0
 and s.ChainID = 40393
 and s.Custom1 <> 'Shop N Save'
 order by s.StoreID
 
  select s.storeid, s.Custom3, w.Banner, *
  --update w set w.storeid = s.storeid
from StoreTransactions_Working w
 inner join stores s
 on CAST(w.storeidentifier as int) = CAST(s.storeidentifier as int)
 where WorkingStatus = 0
 and s.ChainID = 40393
 and s.Custom1 <> 'Shop N Save'
 order by s.StoreID
 
 
select MAX(retailerinvoiceid) from datatrue_edi.dbo.invoicedetails
--11132

 /*
 
 select distinct custom1 from stores
 
SV - Legacy SV 

FF 
Shop N Save  
Cub
Hornbachers
SHPS
Cub (Diamond Lake LLC)

select distinct custom3 from stores

select s.*
--update s set s.custom3 = 'SV' 
from stores s
where custom1 in
('FF', 
'Shop N Save',
'Cub',
'Hornbachers',
'SHPS', 
'Cub (Diamond Lake LLC)')
order by custom1

 

ABS – Albertsons 

Albertsons         
IMW
ACME
SCAL

 select custom3 as c3, s.*
--update s set s.custom3 = 'ABS' 
from stores s
where custom1 in
('Albertsons'
,'IMW'
,'ACME'
,'SCAL')
order by custom3
 
 */
 
select * from datatrue_edi.dbo.Inbound852Sales
where RecordStatus = 0

select distinct banner 
from datatrue_edi.dbo.Inbound852Sales
where RecordStatus = 0

select distinct saledate 
from datatrue_edi.dbo.Inbound852Sales
where RecordStatus = 0

 select distinct transactionstatus from StoreTransactions where ChainID = 40393
 
 select distinct sourceid
 from StoreTransactions
 order by SourceID desc
 
  select distinct saledatetime
 from StoreTransactions
where SourceID = 945

select COUNT(storetransactionid)
from StoreTransactions
where SourceID = 1004


select *
from InvoiceDetails
order by DateTimeCreated desc

--supplier invoice details

select distinct saledate from InvoiceDetails where SupplierID = 40559

select * from InvoiceDetails where SupplierID = 40559 and SaleDate = '11/15/2011'
select * into Import.dbo.stores_20111117BeforeBannerAndDunsUpdate from stores

select distinct custom1 from stores

/*
Albertsons - IMW                     0069271833300
Shoppers Food and Pharmacy                          4233100000000
Cub Foods                                                       0032326880002
Farm Fresh Markets                                        1939636180000
Albertsons – ACME                                          0069271877700
Shop N Save Warehouse Foods Inc                8008812780000   - do not know why they are different. Gilad needs to ask them.
Shop N Save Warehouse Foods Inc                800881278000P

Albertsons - Southern California                      0069271863600
*/

select *
--update s set custom1 = 'Albertsons - SCAL', DunsNumber = '0069271863600'
from stores s
where Custom1 in ('SCAL')

select *
--update s set custom1 = 'Shop N Save Warehouse Foods Inc', DunsNumber = '8008812780000'
from stores s
where Custom1 in ('Shop N Save')

select *
--update s set custom1 = 'Albertsons - ACME', DunsNumber = '0069271877700'
from stores s
where Custom1 in ('ACME')

select *
--update s set custom1 = 'Farm Fresh Markets', DunsNumber = '1939636180000'
from stores s
where Custom1 in ('FF')

select *
--update s set custom1 = 'Cub Foods', DunsNumber = '0032326880002'
from stores s
where Custom1 in ('Cub', 'Cub (Diamond Lake LLC)')

select *
--update s set custom1 = 'Shoppers Food and Pharmacy', DunsNumber = '4233100000000'
from stores s
where Custom1 = 'SHPS'

select *
--update s set custom1 = 'Albertsons - IMW', DunsNumber = '0069271833300'
from stores s
where Custom1 = 'IMW'

select *
--select distinct banner
--update s set s.banner = 'ABS'
from datatrue_edi.dbo.Inbound852Sales
where RecordStatus = 0


select * 
--update s set recordstatus = -7
from datatrue_edi.dbo.Inbound852Sales s
where RecordStatus = -7

select * from Source where SourceID = 1022

select distinct recordstatus from InvoiceDetails

update InvoiceDetails set RecordStatus = -5 where RecordStatus = 0

update InvoiceDetails set RecordStatus = 0 where BatchID = '1451'



select productid 
from StoreTransactions [NoLock] 
where SourceID = 1061
and ProductID not in
(select ProductID from ChainProductFactors where ChainID = 40393)


INSERT INTO [DataTrue_Main].[dbo].[ChainProductFactors]
           ([ChainID]
           ,[ProductID]
           ,[BrandID]
           ,[BaseUnitsCalculationPerNoOfweeks]
           ,[CostFromRetailPercent]
           ,[BillingRuleID]
           ,[IncludeDollarDiffDetails]
           ,[ActiveStartDate]
           ,[ActiveEndDate]
           ,[LastUpdateUserID])

select distinct 40393, productid, 0, 17, 100, 1, 1, '1/1/2000', '12/31/2025', 2 
from StoreTransactions [NoLock] 
where chainid = 40393 --SourceID = 1447
and ProductID not in
(select ProductID from ChainProductFactors where ChainID = 40393)

 
 
 select *
 --update w set chainidentifier = 'SV'
 from StoreTransactions_Working w
 where WorkingStatus = 0
 and chainidentifier = 'SS'
 
  select *
 --update w set Banner = 'SV'
 from StoreTransactions_Working w
 where WorkingStatus = 0
 and Banner = 'SS'
 
 select * 
 --update w set workingstatus = 2
 from StoreTransactions_Working w
 where WorkingStatus = 3
 
 select * from InvoiceDetails --where RecordStatus = 0
 order by DateTimeCreated desc
 update InvoiceDetails set RecordStatus = 0
 
  select * from InvoiceDetails
 where batchid = '1453'
 
 select distinct saledate from DataTrue_EDI.dbo.Inbound852Sales
 where ChainIdentifier = 'SV'
 and RecordStatus <> 0
 
  select * from DataTrue_EDI.dbo.Inbound852Sales
 where ChainIdentifier = 'SV'
 and RecordStatus = 0
 
 
  select distinct filename from DataTrue_EDI.dbo.Inbound852Sales
 where ChainIdentifier = 'SV'
 and RecordStatus = 0
 
 
 
 
 alter table storetransactions_working
 add StoreName nvarchar(50)
,ProductQualifier nvarchar(50)
,RawProductIdentifier nvarchar(50)
,SupplierName nvarchar(50)
,DivisionIdentifier nvarchar(50)
,UOM nvarchar(50)
,SalePrice money
,InvoiceNo nvarchar(50)
,PONo nvarchar(50) 
,CorporateName nvarchar(50)  
,CorporateIdentifier nvarchar(50)
,PromoTypeID int
,PromoAllowance money 
 
 
 alter table storetransactions
 add
 ChainIdentifier nvarchar(50)
,StoreIdentifier  nvarchar(50)
,StoreName nvarchar(50)
,ProductIdentifier  nvarchar(50)
,ProductQualifier nvarchar(50)
,RawProductIdentifier nvarchar(50)
,SupplierName nvarchar(50)
,SupplierIdentifier nvarchar(50)
,BrandIdentifier nvarchar(50)
,DivisionIdentifier nvarchar(50)
,UOM nvarchar(50)
,SalePrice money
,InvoiceNo nvarchar(50)
,PONo nvarchar(50) 
,CorporateName nvarchar(50)  
,CorporateIdentifier nvarchar(50)
,Banner nvarchar(50)
,PromoTypeID int
,PromoAllowance money 
 
  alter table invoicedetails
 add
 ChainIdentifier nvarchar(50)
,StoreIdentifier  nvarchar(50)
,StoreName nvarchar(50)
,ProductIdentifier  nvarchar(50)
,ProductQualifier nvarchar(50)
,RawProductIdentifier nvarchar(50)
,SupplierName nvarchar(50)
,SupplierIdentifier nvarchar(50)
,BrandIdentifier nvarchar(50)
,DivisionIdentifier nvarchar(50)
,UOM nvarchar(50)
,SalePrice money
,Allowance money
,InvoiceNo nvarchar(50)
,PONo nvarchar(50) 
,CorporateName nvarchar(50)  
,CorporateIdentifier nvarchar(50)
,Banner nvarchar(50)
,PromoTypeID int
,PromoAllowance money

  alter table datatrue_edi.dbo.invoicedetails
 add
 ChainIdentifier nvarchar(50)
,StoreIdentifier  nvarchar(50)
,StoreName nvarchar(50)
,ProductIdentifier  nvarchar(50)
,ProductQualifier nvarchar(50)
,RawProductIdentifier nvarchar(50)
,SupplierName nvarchar(50)
,SupplierIdentifier nvarchar(50)
,BrandIdentifier nvarchar(50)
,DivisionIdentifier nvarchar(50)
,UOM nvarchar(50)
,SalePrice money
,Allowance money
,InvoiceNo nvarchar(50)
,PONo nvarchar(50) 
,CorporateName nvarchar(50)  
,CorporateIdentifier nvarchar(50)
,Banner nvarchar(50)
,PromoTypeID int
,PromoAllowance money
/* 
chainidentifier,
StoreIdentifier,
storename,
Productqualifier,
Rawproductidentifier,
ProductIdentifier,
supplierIdentifier,
suppliername,
divisionIdentifier,
saledate,
qty,
unitmeasure,
cost,
saleprice,
retail,
allowance,
invoiceno,
PONO,
corporatename,
CorporateIdendifier
Banner
*/

 select * from storetransactions_working where SourceIdentifier = 'ABS.20111118070539_SPLIT5'
 
 select distinct  saledatetime from StoreTransactions where SourceID = 1080
 
 
 select MAX(batchid) from batch
 
 select * from InvoiceDetails where BatchID = '1456'
 
 select * 
 --delete
 from InvoicesRetailer
 where RetailerInvoiceID in
 ( select RetailerInvoiceID from InvoiceDetails where BatchID = '1456')
 
update InvoiceDetails set RetailerInvoiceID = null where BatchID = '1456'
 
  select * from datatrue_edi.dbo.InvoiceDetails where BatchID = '1456'
 
 update datatrue_edi.dbo.InvoiceDetails set RecordStatus = 1
 
 select * from StoreTransactions where InvoiceBatchID = 1456 and ReportedCost <> RuleCost
 
 
select sum(qty * (SetupCost - ReportedCost)) from StoreTransactions where InvoiceBatchID = 1456 and ReportedCost <> RuleCost

select * from InvoiceDetails where pono in ('105340','105341') order by pono desc

select distinct recordstatus from datatrue_edi.dbo.Inbound852Sales
--update datatrue_edi.dbo.Inbound852Sales set recordstatus = 1 where RecordStatus = 0 ---8 Three SS files that got reloaded or reset to zero
select distinct filename, banner from datatrue_edi.dbo.Inbound852Sales where RecordStatus = 0
select distinct filename, saledate from datatrue_edi.dbo.Inbound852Sales where RecordStatus = 0
select * from datatrue_edi.dbo.Inbound852Sales where RecordStatus = 0

select * from Source order by SourceID desc

delete from datatrue_edi.dbo.Inbound852Sales where filename = 'ABS.20111117065235_SPLIT4' and recordstatus = 0

select * from datatrue_edi.dbo.Inbound852Sales where recordstatus = 0


select * from InvoiceDetails where BatchID = '1451'
select * from StoreTransactions where SourceID = 1451

select * from Source order by SourceID desc
select distinct SourceName from Source order by SourceName desc
select * from Source where sourcename = 'SVEC.20111123121147_SPLIT8'

select distinct invoicebatchid from StoreTransactions where SourceID = 1335 --1316 --1269 --/1463
select distinct SaleDateTime from StoreTransactions where SourceID = 1466
--1379 1380 1383

select * from StoreTransactions [NoLock] where SourceID = 1265

select distinct WorkingStatus from StoreTransactions_working
select distinct Banner from StoreTransactions_working where WorkingStatus = 0

select distinct Saledatetime from StoreTransactions [NoLock] where SourceID = 1447
select distinct TransactionStatus from StoreTransactions [NoLock] where SourceID = 1061
select distinct Invoicebatchid from StoreTransactions [NoLock] where SourceID = 1061
select distinct transactiontypeid from StoreTransactions [NoLock] where SourceID = 1061

select * from InvoiceDetails where BatchID = '1078'
select distinct SaleDate from InvoiceDetails where BatchID = '1461'
select * from InvoiceDetails  where BatchID = '1462'

select distinct invoicedetailtypeid from InvoiceDetails where BatchID = '1452'

--40559 = Nestle 40557 = Bimbo 41349 = burpee gopher = 40558 schmit = 40561 sony = 40570 lewis = 41464
select * from InvoiceDetails where supplierid = 41464 and SupplierInvoiceID is null and SaleDate = '11/17/2011' and RetailerInvoiceID is not null
select distinct saledate from InvoiceDetails where supplierid = 41464 and SupplierInvoiceID is null

select * from InvoicesSupplier order by SupplierInvoiceID desc

select * from InvoiceDetails where SupplierInvoiceID >= 1603

select * from datatrue_EDI.dbo.InvoicesSupplier where SupplierInvoiceID >= 1603

select * from datatrue_EDI.dbo.InvoiceDetails 
where 1 = 1
and SupplierInvoiceID >= 1603 
and RetailerInvoiceId is null

select * from datatrue_EDI.dbo.Inbound852Sales where RecordStatus = 0

--Before Loading new files

select distinct saledate from datatrue_EDI.dbo.Inbound852Sales where RecordStatus = 0
select distinct filename, banner, saledate from datatrue_EDI.dbo.Inbound852Sales where RecordStatus = 0
select * from datatrue_EDI.dbo.Inbound852Sales where RecordStatus = 0 and Banner = 'SS'
update datatrue_EDI.dbo.Inbound852Sales set recordstatus = 1 where RecordStatus = 0 and Banner = 'SS'

delete from datatrue_EDI.dbo.Inbound852Sales where recordstatus = 0 and filename = 'SVEC.20111123121147_SPLIT8'
/*
ABS.20111125064511_SPLIT4
SVEC.20111125133250_SPLIT8
*/
select distinct supplieridentifier from datatrue_EDI.dbo.Inbound852Sales where RecordStatus = 0

select * from Suppliers where SupplierIdentifier in
(select distinct supplieridentifier from datatrue_EDI.dbo.Inbound852Sales where RecordStatus = 0)

select * from datatrue_edi.dbo.InvoiceDetails where supplierid = 40559

select s.*, t.*
--update t set t.StoreID = s.StoreID
from [dbo].[StoreTransactions_Working] t
left join [dbo].[Stores] s
on cast(t.StoreIdentifier as int) = cast(s.StoreIdentifier as int)
--and ltrim(rtrim(t.Banner)) = ltrim(rtrim(s.Custom3))
where t.WorkingStatus = 0
and Custom3 = 'SV'


select * 
--update w set banner = 'SV'
from StoreTransactions_Working  w
where WorkingStatus = 0
and Banner = 'SS'

select s.custom3 as edib, s.*, w.*
--select distinct s.custom3
--update s set s.custom3 = 'SS'
from StoreTransactions_Working  w
inner join stores s
on w.StoreID = s.StoreID
where WorkingStatus = 1

select * 
--update w set banner = 'SS'
from StoreTransactions_Working  w
where WorkingStatus = 1
and Banner = 'SV'


select * 
from StoreTransactions_Working  w
where WorkingStatus = 1

--product audit

    select distinct ltrim(rtrim(UPC))
    --update w set w.workingstatus = -99 --SS UPCs that didn't match ommited from load
 from StoreTransactions_Working w
  where workingStatus = 1
  and ltrim(rtrim(UPC))
  not in 
(select ltrim(rtrim(identifiervalue)) from ProductIdentifiers)


    select *
 from StoreTransactions_Working
  where workingStatus = 1
  and substring(ltrim(rtrim(UPC)), 2, 10)
  not in 
(select substring(ltrim(rtrim(identifiervalue)), 2, 10) from ProductIdentifiers)
--and SUBSTRING(g.productid, 2, 10) = substring(t.ProductIdentifier, 2, 10)

    select w.UPC, i.IdentifierValue, i.productid
    --update i set i.identifiervalue = ltrim(rtrim(w.UPC))
 from StoreTransactions_Working w
 inner join ProductIdentifiers i
 on substring(ltrim(rtrim(w.UPC)), 2, 10) = substring(ltrim(rtrim(i.IdentifierValue)), 2, 10)
  where workingStatus = 1
  and ltrim(rtrim(UPC))
  not in 
(select ltrim(rtrim(identifiervalue)) from ProductIdentifiers)

select * into Import.dbo.Productidentifiers_20111121BeforeUpdatefrom852Source from productidentifiers

    select w.UPC, i.IdentifierValue, i.productid
    --update i set i.identifiervalue = ltrim(rtrim(w.UPC))
 from StoreTransactions_Working w
 inner join ProductIdentifiers i
 on substring(ltrim(rtrim(w.UPC)), 2, 10) = substring(ltrim(rtrim(i.IdentifierValue)), 1, 11)
  where workingStatus = 1
  and ltrim(rtrim(UPC))
  not in 
(select ltrim(rtrim(identifiervalue)) from ProductIdentifiers)

select distinct p.ProductName
--select left(p.ProductName, len(p.ProductName) - 4)
--update p set p.productname = left(p.ProductName, len(p.ProductName) - 4)
from Products p
inner join ProductIdentifiers i
on p.ProductID = i.ProductID
inner join StoreTransactions_Working w
on i.identifiervalue = w.UPC
  where workingStatus = 1
  and CHARINDEX('-TMP', p.ProductName) > 0
order by p.productname

--supplier audit

select *
from StoreTransactions_Working w
where 1 = 1
and w.ChainID = 40393
and (w.SupplierID = 0 or w.SupplierID is null)

select s.SupplierID, s.SupplierIdentifier, 
w.SupplierIdentifier, w.SupplierID, w.workingstatus,
w.datetimecreated
--update w set w.SupplierID = s.SupplierID
from StoreTransactions_Working w
inner join Suppliers s
on ltrim(rtrim(w.SupplierIdentifier)) = ltrim(rtrim(s.SupplierIdentifier))
where 1 = 1
and w.ChainID = 40393
and (w.SupplierID = 0 or w.SupplierID is null) 
and w.WorkingStatus < 5
--and w.DateTimeCreated >= '11/18/2011'
and w.SupplierID is null
and w.WorkingStatus <> -9999


select top 39070 *
from StoreTransactions
order by StoreTransactionID desc

select *
from StoreTransactions
where ChainID = 40393
and TransactionStatus = 0
and cast(SaleDateTime as date) = '11/24/2011'

select *
from StoreTransactions
where SupplierID in (41462)

select distinct saledate
from InvoiceDetailS

where SupplierID in (41462)

select *
from InvoiceDetailS
where DateTimeCreated > '11/27/2011'

select distinct supplierid
from InvoiceDetailS
where DateTimeCreated > '11/27/2011'


select *
from InvoiceDetailS
where SupplierID in (41462)
and SaleDate = '11/17/2011'

select distinct Banner from StoreTransactions_working where WorkingStatus = 0
select distinct Banner from StoreTransactions_working where WorkingStatus = 1

select s.suppliername, s.supplierid, count(storetransactionid)
from Suppliers s
inner join StoreTransactions t
on s.SupplierID = t.SupplierID
where t.ChainID = 40393
group by s.suppliername, s.supplierid
order by s.suppliername, s.supplierid

select distinct supplier_name
--select top 1000 *
from ChainSetupBase

select distinct suppliername
from SuppliersSetupData
order by suppliername

select distinct supplierid, suppliername
from SuppliersSetupData
order by suppliername

select *
from InvoiceDetails
where SaleDate = '11/25/2011'
and SupplierInvoiceID is null

select distinct datatruesupplierid 
from datatrue_edi.dbo.EDI_SupplierCrossReference
where datatruesupplierid not in
(select entityidtoinvoice from BillingControl)

select * into Import.dbo.Suppliers_20111128 from suppliers

select s.suppliername, ss.SupplierID, cr.DataTrueSupplierID
--update ss set ss.supplierid = cr.datatruesupplierid
from storesetup ss
inner join suppliers s
on ss.SupplierID = s.SupplierID
inner join datatrue_edi.dbo.EDI_SupplierCrossReference cr
on LTRIM(rtrim(s.supplieridentifier)) = LTRIM(rtrim(cr.supplieridentifier))
where ss.SupplierID <> cr.DataTrueSupplierID


--remove leading zeros from stores table storeidentifier column
select * into Import.dbo.stores_20111129 from stores

select storeidentifier, cast(CAST(storeidentifier as int) as nvarchar)
--update s set storeidentifier = cast(CAST(storeidentifier as int) as nvarchar)
from stores s
where LEFT(storeidentifier, 1) = '0'


--pos source 
drop table Import.dbo.SetupFromPOS

select distinct chainid, storeid, ProductId, cast(0 as int) as BrandID, supplieridentifier
into Import.dbo.SetupFromPOS
from StoreTransactions_working t
where ChainID = 40393
and StoreID is not null
and ProductID is not null

select top 10 * from Import.dbo.SetupFromPOS
--234658
select top 10 * from Import.dbo.tmpChainSetupBasePlus
--here now thinking of creating program for matching/setup
select p.*, c.cost
from Import.dbo.SetupFromPOS p
inner join Import.dbo.tmpChainSetupBasePlus c
on p.storeid = c.storeid
and p.ProductID = c.productid

--chainsetupbase
drop table Import.dbo.DupeStoreSBTNumbersAccrossBanners

select CAST(custom2 as int) as SBTNumber
into Import.dbo.DupeStoreSBTNumbersAccrossBanners
from stores
where Custom2 is not null
group by CAST(custom2 as int)
having  COUNT(storeid) > 1
order by COUNT(storeid) desc

select *
from Import.dbo.tmpChainSetupBasePlus

select distinct CAST(c.storeidentifier as int)
from Import.dbo.tmpChainSetupBasePlus c
where 1 = 1
--and s.ChainID = 40393
and CAST(c.storeidentifier as int) not in
(select SBTNumber from Import.dbo.DupeStoreSBTNumbersAccrossBanners)

--1800363 before dropping 15 dupe sbtNumbers

select COUNT(*)
--update c set c.StoreID = s.storeid
from Import.dbo.tmpChainSetupBasePlus c
inner join stores s
on CAST(c.storeidentifier as int) = CAST(s.custom2 as int)
--and LTRIM(rtrim(c.matchbanner)) = LTRIM(rtrim(s.custom1))
where 1 = 1
and s.ChainID = 40393
and CAST(c.storeidentifier as int) not in
(select SBTNumber from Import.dbo.DupeStoreSBTNumbersAccrossBanners)


select top 1000 *
from chainsetupbase


select distinct banner
from chainsetupbase

select *
from chainsetupbase
where UPC12Digit is null

select distinct upc12digit
from chainsetupbase
where LTRIM(rtrim(upc12digit)) not in 
(select LTRIM(rtrim(identifiervalue)) from ProductIdentifiers)


select cast(0 as int) as productid
,cast(0 as int) as storeid
,cast(0 as int) as brandid
,cast(0 as int) as supplierid
,StoreNumber as storeidentifier
,supplierID as supplieridentifier
,banner
,product_desc
,supplier_name
,upc12digit
,CAST(cost as money) as cost
into Import.dbo.tmpChainSetupBasePlus
from chainsetupbase

--2167116

select *
from Import.dbo.tmpChainSetupBasePlus
where productid <> 0

select c.*
--update c set c.productid = i.productid
from Import.dbo.tmpChainSetupBasePlus c
inner join ProductIdentifiers i
on ltrim(rtrim(c.UPC12Digit)) = ltrim(rtrim(i.IdentifierValue))

select distinct supplieridentifier
from Import.dbo.tmpChainSetupBasePlus


select distinct supplier_name
from Import.dbo.tmpChainSetupBasePlus
where supplierid = 0

select *
from Import.dbo.tmpChainSetupBasePlus
where supplierid = 0

update Import.dbo.tmpChainSetupBasePlus set SupplierId = 40557 where supplier_name = 'PLANTATION' and supplierid = 0

select COUNT(c.upc12digit)
--update c set c.productid = i.productid
from Import.dbo.tmpChainSetupBasePlus c
inner join datatrue_edi.dbo.EDI_SupplierCrossReference i
on ltrim(rtrim(c.supplieridentifier)) = ltrim(rtrim(i.SupplierIdentifier))

select distinct ltrim(rtrim(c.supplieridentifier))
from Import.dbo.tmpChainSetupBasePlus c
where ltrim(rtrim(c.supplieridentifier)) not in
(select ltrim(rtrim(SupplierIdentifier)) from datatrue_edi.dbo.EDI_SupplierCrossReference)

select distinct ltrim(rtrim(c.supplieridentifier)), supplier_name
from Import.dbo.tmpChainSetupBasePlus c
where ltrim(rtrim(c.supplieridentifier)) not in
(select ltrim(rtrim(SupplierIdentifier)) from Suppliers)

select COUNT(c.upc12digit)
--update c set c.supplierid = i.datatruesupplierid
from Import.dbo.tmpChainSetupBasePlus c
inner join datatrue_edi.dbo.EDI_SupplierCrossReference i
on ltrim(rtrim(c.supplieridentifier)) = ltrim(rtrim(i.SupplierIdentifier))
/*
5536706	NESTLE/EDYS 41345
update c set c.supplierid = 41345 from Import.dbo.tmpChainSetupBasePlus c where ltrim(rtrim(c.SupplierIdentifier)) = '5536706'
747807	RUG DOCTOR 40560
update c set c.supplierid = 40560 from Import.dbo.tmpChainSetupBasePlus c where ltrim(rtrim(c.SupplierIdentifier)) = '747807'
2917	NESTLE/EDYS 41345
update c set c.supplierid = 41345 from Import.dbo.tmpChainSetupBasePlus c where ltrim(rtrim(c.SupplierIdentifier)) = '2917'
4871	BIMBO 40557
update c set c.supplierid = 40557 from Import.dbo.tmpChainSetupBasePlus c where ltrim(rtrim(c.SupplierIdentifier)) = '4871'
767392	BIMBO 40557
update c set c.supplierid = 40557 from Import.dbo.tmpChainSetupBasePlus c where ltrim(rtrim(c.SupplierIdentifier)) = '767392'
7541001	iControl SV legacy
606228	PLANTATION
30150	DIANA'S TORTILLAS 41342
update c set c.supplierid = 41342 from Import.dbo.tmpChainSetupBasePlus c where ltrim(rtrim(c.SupplierIdentifier)) = '30150'
43739	BURPEE 40578
update c set c.supplierid = 40578 from Import.dbo.tmpChainSetupBasePlus c where ltrim(rtrim(c.SupplierIdentifier)) = '43739'
7730438	PEPPERIDGE FARM 40562
update c set c.supplierid = 40562 from Import.dbo.tmpChainSetupBasePlus c where ltrim(rtrim(c.SupplierIdentifier)) = '7730438'
9105562	NESTLE/EDYS 41345
update c set c.supplierid = 41345 from Import.dbo.tmpChainSetupBasePlus c where ltrim(rtrim(c.SupplierIdentifier)) = '9105562'
7721738	RUG DOCTOR 40560
update c set c.supplierid = 40560 from Import.dbo.tmpChainSetupBasePlus c where ltrim(rtrim(c.SupplierIdentifier)) = '7721738'
7744784	NESTLE/EDYS 41345
update c set c.supplierid = 41345 from Import.dbo.tmpChainSetupBasePlus c where ltrim(rtrim(c.SupplierIdentifier)) = '7744784'
5439838	iControl ABS legacy
*/

select distinct banner from Import.dbo.tmpChainSetupBasePlus
select distinct custom1 from stores
/*
ACME
Cub
Farm Fresh
Hornbachers
IMW
SCAL
Shoppers
*/

select distinct matchbanner from Import.dbo.tmpChainSetupBasePlus

select distinct custom1 from stores
/*
Albertsons - ACME
update Import.dbo.tmpChainSetupBasePlus set matchbanner = 'Albertsons - ACME' where banner = 'ACME'
Cub Foods
update Import.dbo.tmpChainSetupBasePlus set matchbanner = 'Cub Foods' where banner = 'Cub'
Farm Fresh Markets
update Import.dbo.tmpChainSetupBasePlus set matchbanner = 'Farm Fresh Markets' where banner = 'Farm Fresh'
Hornbachers
update Import.dbo.tmpChainSetupBasePlus set matchbanner = 'Hornbachers' where banner = 'Hornbachers'
Albertsons - IMW
update Import.dbo.tmpChainSetupBasePlus set matchbanner = 'Albertsons - IMW' where banner = 'IMW'
Albertsons - SCAL
update Import.dbo.tmpChainSetupBasePlus set matchbanner = 'Albertsons - SCAL' where banner = 'SCAL'
Shoppers Food and Pharmacy
update Import.dbo.tmpChainSetupBasePlus set matchbanner = 'Shoppers Food and Pharmacy' where banner = 'Shoppers'
Shop N Save Warehouse Foods Inc
Albertsons

*/
select COUNT(*) from SuppliersSetupData

select top 1000 * from SuppliersSetupData

select CAST(0 as int) as dtproductid
,CAST(0 as int) as dtstoreid
,CAST(0 as int) as dtbrandid
,CAST(0 as int) as dtsupplierid
,'                    ' as matchbanner
,*
into Import.dbo.SuppliersSetupDataPlus
from SuppliersSetupData

select distinct banner
from Import.dbo.SuppliersSetupDataPlus

select banner, COUNT(dtproductid)
from Import.dbo.SuppliersSetupDataPlus
group by banner

/*
NULL	5143
CubFoods	353648
Shoppers	4144

Cub Foods
update Import.dbo.SuppliersSetupDataPlus set matchbanner = 'Cub Foods' where ltrim(rtrim(banner)) = 'CubFoods'
Shoppers Food and Pharmacy
update Import.dbo.SuppliersSetupDataPlus set matchbanner = 'Shoppers Food and Pharmacy' where banner = 'Shoppers'
*/



select top 1000 * from Import.dbo.SuppliersSetupDataPlus
select top 1000 * from SuppliersSetupData

select * from Import.dbo.SuppliersSetupDataPlus where charindex('Lewis', suppliername) > 0

select distinct dtproductid, [12digitupc], '               ' as matchedupc
into #supplierdata12digit
from Import.dbo.SuppliersSetupDataPlus 




    select w.[12digitupc], i.IdentifierValue, i.productid
    --update i set i.identifiervalue = ltrim(rtrim(w.UPC12digit))
 from #supplierdata12digit w
 inner join ProductIdentifiers i
 on substring(ltrim(rtrim(w.[12digitupc])), 2, 10) = substring(ltrim(rtrim(i.IdentifierValue)), 2, 10)
  where ltrim(rtrim(w.[12digitupc]))
  not in 
(select ltrim(rtrim(identifiervalue)) from ProductIdentifiers)
and LEN(ltrim(rtrim(i.identifiervalue))) = 11

    select w.[12digitupc], i.IdentifierValue, i.productid
    --update i set i.identifiervalue = ltrim(rtrim(w.UPC12digit))
 from #supplierdata12digit w
 inner join ProductIdentifiers i
 on substring(ltrim(rtrim(w.[12digitupc])), 2, 10) = substring(ltrim(rtrim(i.IdentifierValue)), 1, 11)
  where ltrim(rtrim(w.[12digitupc]))
  not in 
(select ltrim(rtrim(identifiervalue)) from ProductIdentifiers)


update Import.dbo.SuppliersSetupDataPlus set SupplieriD = 41464 where charindex('Lewis', suppliername) > 0 

select SupplierName, [12digitupc], COUNT(banner)
from SuppliersSetupData
where LTRIM(rtrim([12digitupc])) not in 
(select LTRIM(rtrim(identifiervalue)) from ProductIdentifiers)
group by SupplierName, [12digitupc]
order by SupplierName,[12digitupc]

select *
from SuppliersSetupData
where [12digitupc] = '020735092121'

select *
from stores
where ChainID = 40393
and Custom1 = 'Albertsons'

 
select SupplierName, count([12digitupc])
from SuppliersSetupData
where LTRIM(rtrim([12digitupc])) not in 
(select LTRIM(rtrim(identifiervalue)) from ProductIdentifiers)
group by SupplierName
order by SupplierName



--clean up product names and descriptions

select * from Import.dbo.tmpChainSetupBasePlus
where productid = 0

select LEN(Product_desc)
from Import.dbo.tmpChainSetupBasePlus
where productid <> 0
order by LEN(Product_desc) desc

select distinct ProductId, product_desc
into #productnaming
from Import.dbo.tmpChainSetupBasePlus
where productid <> 0

select * into Import.dbo.Products_20111128 from products

select n.product_desc, p.*
--update p set p.description = n.product_desc
from #productnaming n
inner join Products p
on n.productid = p.ProductID
where p.Description = 'UNKNOWN'

select n.product_desc, p.*
--update p set p.productname = n.product_desc
from #productnaming n
inner join Products p
on n.productid = p.ProductID


select * from stores where Custom1 = 'Farm Fresh Markets'
order by StoreIdentifier

select distinct custom1 from stores where ChainID = 40393

select * from stores where ChainID = 40393

select * from productidentifiers where productid = 6189

select * from StoreTransactions where ProductID = 6189 order by saledatetime desc

select *
from Import.dbo.tmpChainSetupBasePlus



select * from #tempchainsetup

select distinct upc12digit
from #tempchainsetup
where LTRIM(rtrim(upc12digit)) not in 
(select LTRIM(rtrim(identifiervalue)) from ProductIdentifiers)



select *
into #tempchainsetup1732
from #tempchainsetup2206
where LTRIM(rtrim(upc12digit)) not in 
(select LTRIM(rtrim(identifiervalue)) from ProductIdentifiers)

select * 
--update i set i.identifiervalue = LTRIM(rtrim(t.upc12digit))
from #tempchainsetup2206 t
inner join ProductIdentifiers i
on CAST(i.IdentifierValue as bigint) = CAST(left(t.upc12digit,11) as bigint)
where isnumeric(i.IdentifierValue) > 0
and LTRIM(rtrim(upc12digit)) not in 
(select LTRIM(rtrim(identifiervalue)) from ProductIdentifiers)


select *
from #tempchainsetup1732 t
inner join ProductIdentifiers i
on RIGHT(left(t.upc12digit, 11), 5) = RIGHT(i.identifiervalue, 5)
and LTRIM(rtrim(t.upc12digit)) not in 
(select LTRIM(rtrim(identifiervalue)) from ProductIdentifiers)

select * into Import.dbo.productidentifiers_20111127 from ProductIdentifiers

    select w.UPC12digit, i.IdentifierValue, i.productid
    --update i set i.identifiervalue = ltrim(rtrim(w.UPC12digit))
 from #tempchainsetup w
 inner join ProductIdentifiers i
 on substring(ltrim(rtrim(w.UPC12digit)), 2, 10) = substring(ltrim(rtrim(i.IdentifierValue)), 2, 10)
  where ltrim(rtrim(w.UPC12digit))
  not in 
(select ltrim(rtrim(identifiervalue)) from ProductIdentifiers)
and LEN(ltrim(rtrim(i.identifiervalue))) = 11


    select w.UPC12digit, i.IdentifierValue, i.productid
    --update i set i.identifiervalue = ltrim(rtrim(w.UPC12digit))
 from #tempchainsetup w
 inner join ProductIdentifiers i
 on substring(ltrim(rtrim(w.UPC12digit)), 2, 10) = substring(ltrim(rtrim(i.IdentifierValue)), 1, 11)
  where ltrim(rtrim(w.UPC12digit))
  not in 
(select ltrim(rtrim(identifiervalue)) from ProductIdentifiers)


select *
from stores
where custom3 = 'SS'

select *
--update s set recordstatus = 1
from datatrue_edi.dbo.Inbound852Sales s
where recordstatus = 0
and Qty = 0

select *
from datatrue_edi.dbo.Load_Stores
where LoadStatus = 0

select distinct custom1 from stores



select *
from stores
where custom2 is not null
and Custom1 in ('Farm Fresh Markets', 'Shoppers Food and Pharmacy')


select *
from stores
where Custom1 in ('Shoppers Food and Pharmacy')

select *
from datatrue_edi.dbo.InvoiceDetails
where RecordStatus = 2


--chainsetupdata store match

select COUNT(*)
--update c set c.storeid = s.storeid
from Import.dbo.tmpChainSetupBasePlus c
inner join stores s
on CAST(c.storeidentifier as int) = CAST(s.storeidentifier as int)
and LTRIM(rtrim(c.matchbanner)) = LTRIM(rtrim(s.custom1))
where s.ChainID = 40393

select c.*, s.*
from Import.dbo.tmpChainSetupBasePlus c
left join stores s
on CAST(c.storeidentifier as int) = CAST(s.storeidentifier as int)
and LTRIM(rtrim(c.matchbanner)) = LTRIM(rtrim(s.custom1))
where s.ChainID = 40393
order by s.storeid

select distinct storeidentifier, banner, matchbanner as Custom1
from Import.dbo.tmpChainSetupBasePlus
where CAST(storeidentifier as int) not in
(select CAST(storeidentifier as int) from stores where ChainID = 40393)
order by banner

select * from StoresConversionTbl

select COUNT(*)
from datatrue_edi.dbo.Inbound852Sales
where ChainIdentifier = 'SV'
--1251181

select *
from datatrue_edi.dbo.Inbound852Sales s
inner join StoresConversionTbl c
on CAST(s.StoreIdentifier as int) = CAST(c.SBTStoreNumber as int)
where s.ChainIdentifier = 'SV'
--1185665

select *
from datatrue_edi.dbo.Inbound852Sales s
where s.ChainIdentifier = 'SV'
and CAST(s.StoreIdentifier as int) not in
(select CAST(SBTStoreNumber as int) from StoresConversionTbl where chainid = 40393)

--1185665
--65516


select distinct s.StoreIdentifier
from datatrue_edi.dbo.Inbound852Sales s
where s.ChainIdentifier = 'SV'
and CAST(s.StoreIdentifier as int) not in
(select CAST(SBTStoreNumber as int) from StoresConversionTbl where chainid = 40393)
order by s.storeIdentifier


select * from stores 
where chainid = 40393
and cast(StoreIdentifier as int) in
(
select distinct cast(s.StoreIdentifier as int)
from datatrue_edi.dbo.Inbound852Sales s
where s.ChainIdentifier = 'SV'
and CAST(s.StoreIdentifier as int) not in
(select CAST(SBTStoreNumber as int) from StoresConversionTbl where chainid = 40393)
--order by s.storeIdentifier
)

select *
from StoresConversionTbl
where CAST(storenumber as int) in
(
30354,
30394,
30914,
55212,
6001,
6003,
6007,
6008,
6010,
6015,
6020,
6022,
6023,
6025,
6026,
6030,
6033,
6037,
6038,
6044,
6048,
6049,
6050,
6051,
6053,
6054,
6055,
6056,
6057,
6058,
6063,
6064,
6066)

select * from datatrue_edi.dbo.Inbound852Sales
where CAST(storeidentifier as int) in
(
select CAST(storeidentifier as int)
from stores
where Custom1 = 'Shop N Save Warehouse Foods Inc'
)
and ChainIdentifier = 'SV'
and RecordID not in
(
select recordid
from datatrue_edi.dbo.Inbound852Sales s
where s.ChainIdentifier = 'SV'
and CAST(s.StoreIdentifier as int) in
(select CAST(SBTStoreNumber as int) from StoresConversionTbl where chainid = 40393)
)


select distinct storeidentifier from datatrue_edi.dbo.Inbound852Sales
where CAST(storeidentifier as int) in
(
select CAST(storeidentifier as int)
from stores
where Custom1 = 'Shop N Save Warehouse Foods Inc'
)
and ChainIdentifier = 'SV'
and RecordID not in
(
select recordid
from datatrue_edi.dbo.Inbound852Sales s
where s.ChainIdentifier = 'SV'
and CAST(s.StoreIdentifier as int) in
(select CAST(SBTStoreNumber as int) from StoresConversionTbl where chainid = 40393)
)
order by StoreIdentifier

--Albertsons update to SCAL
select distinct custom1
from stores

select * into Import.dbo.stores_20111129BeforeAlbertsonsUPdateToSCAL from stores


select *
from stores
where Custom1 = 'albertsons'

select *
--update s set custom1 = 'Albertsons - SCAL'
from stores s
where Custom1 = 'albertsons'

select *
from datatrue_edi.dbo.Inbound852Sales s
where s.ChainIdentifier = 'SV'
and CAST(s.StoreIdentifier as int) in
(30354,
30394,
30914,
55212)

select * from stores s

where s.ChainId = 40393
and CAST(s.StoreIdentifier as int) in
(30354,
30394,
30914,
55212)

select *
from stores
where Custom1 = 'Shop N Save Warehouse Foods Inc'


select s.*, c.SBTStoreNumber
from stores s
inner join StoresConversionTbl c
on CAST(s.StoreIdentifier as int) = CAST(c.StoreNumber as int)
and s.ChainID = 40393
where CAST(s.Custom2 as int) <> CAST(c.SBTStoreNumber as int) 

select * from StoresConversionTbl

select * from StoresConversionTbl
where storenumber = sbtstorenumber

select * from StoresConversionTbl
where storenumber <> sbtstorenumber

select *
from datatrue_edi.dbo.Inbound852Sales s
where s.ChainIdentifier = 'SV'
and CAST(s.StoreIdentifier as int) in
(
select CAST(SBTStoreNumber as int) 
from StoresConversionTbl
--where banner = 'Shop N Save'
where storenumber <> sbtstorenumber
)

select distinct StoreIdentifier
from datatrue_edi.dbo.Inbound852Sales s
where s.ChainIdentifier = 'SV'
and Banner = 'SS'

select *
from datatrue_edi.dbo.Inbound852Sales s
where s.ChainIdentifier = 'SV'
--and Banner = 'SS'
and CAST(s.StoreIdentifier as int) in
(
select CAST(SBTStoreNumber as int) 
from StoresConversionTbl
where banner = 'Shop N Save'
--where storenumber <> sbtstorenumber
)


select *
from datatrue_edi.dbo.Inbound852Sales s
where s.ChainIdentifier = 'SV'

select CAST(SBTStoreNumber as int) 
from StoresConversionTbl
where CAST(StoreNumber as int) in
(30354,
30394,
30914,
55212)


alter table storetransactions_working
add SBTNumber nvarchar(50)

alter table storetransactions
add SBTNumber nvarchar(50)

alter table invoicedetails
add SBTNumber nvarchar(50)

alter table datatrue_edi.dbo.invoicedetails
add SBTNumber nvarchar(50)


select * 
--update s set custom2 = ltrim(rtrim(storeidentifier))
from stores s
where StoreIdentifier <> Custom2
and ChainID = 40393


select * 
--update s set custom2 = ltrim(rtrim(storeidentifier))
from stores s
where Custom2 is null
and ChainID = 40393


select *
--update s set Custom2 = ltrim(rtrim(c.SBTStoreNumber)) 
from stores s
inner join StoresConversionTbl c
on CAST(s.Storeidentifier as int) = CAST(c.SBTStoreNumber as int)
where s.ChainID = 40393
and s.Custom2 is null
and CAST(s.Custom2 as int) <> CAST(c.SBTStoreNumber as int)

--update real store number using SBTNumber
select * into IMport.dbo.stores_20111129BeforeStoreIdentifierUpdate from stores

select CAST(s.storeidentifier as int), cast(c.StoreNumber as int), *
--update s set s.storeidentifier = ltrim(rtrim(c.StoreNumber)) 
from stores s
inner join StoresConversionTbl c
on CAST(s.Custom2 as int) = CAST(c.SBTStoreNumber as int)
where s.ChainID = 40393
and CAST(s.storeidentifier as int) <> cast(c.StoreNumber as int)




select distinct custom1
from stores



select *
from stores
where Custom1 in ('Farm Fresh Markets', 'Shoppers Food and Pharmacy')
order by Custom1, StoreIdentifier

select *
from datatrue_edi.dbo.Inbound852Sales
where chainidentifier = 'SV'
and cast(StoreIdentifier as int) in
(select cast(StoreIdentifier as int)
from stores
where Custom1 in ('Farm Fresh Markets', 'Shoppers Food and Pharmacy'))
--order by Custom1, StoreIdentifier

select top 1000 * from InvoiceDetailS
order by DateTimeCreated desc

select *
--update d set d.SBTNumber = s.Custom2
from datatrue_edi.dbo.InvoiceDetails d
inner join stores s
on d.storeid = s.storeid
where Banner = 'SS'


return
GO
