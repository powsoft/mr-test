USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Entity_Conversion_Import]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Entity_Conversion_Import]
as

/*
update  datatrue_edi..Load_Suppliers set loadstatus = 0 where loadstatus = -3
update suppliers set Supplieridentifier = suppliername
update manufacturers set manufactureridentifier = manufacturername
update brands set brandidentifier = brandname
update suppliers set Suppliername = supplierdescription + '-' + SupplierName where len(supplierdescription) > 1

select *
--update m set manufacturername = branddescription + '-' + Manufacturername
from manufacturers m
inner join brands b
on m.manufacturerid = b.manufacturerid
where len(branddescription) > 1

update brands set brandname = branddescription + '-' + brandname
where len(branddescription) > 1
delete [DataTrue_EDI].[dbo].[Load_Suppliers] where recordid > 2

select top 100 * from [Import]..rastorelist

*/


select * from ChainProductFactors where ChainID = 35541

select distinct ProductID from StoreSetup where ChainID = 35541

  
MERGE INTO [dbo].[chainproductfactors] i

USING (SELECT [ChainID]
      ,[ProductID]
      ,[BrandID]
      from StoreSetup
      where ChainID = 35541
      group by [ChainID]
      ,[ProductID]
      ,[BrandID]) S
	on i.ChainID = s.ChainID
	and i.ProductID = s.ProductID
	and i.BrandID = s.BrandID

WHEN NOT MATCHED 

THEN INSERT 
           ([ChainID]
           ,[ProductID]
           ,[BrandID]
           ,[BaseUnitsCalculationPerNoOfweeks]
           ,[CostFromRetailPercent]
           ,[BillingRuleID]
           ,[IncludeDollarDiffDetails]
           ,[LastUpdateUserID]
           ,[ActiveStartDate]
           ,[ActiveEndDate])
     VALUES
           (s.[ChainID]
			,s.[ProductID]
			,s.[BrandID]
			,17
			,75
			,1
			,1
			,2
			,dateadd(month, -1, getdate())
			,dateadd(month, 12, getdate()));






INSERT INTO [DataTrue_EDI].[dbo].[Load_Stores]
           ([ChainsStoreIdentifier]
           ,[ChainIdentifier]
           ,[StoreIdentifier]
           ,[StoreName]
           ,[StoreManager]
           ,[Address]
           ,[City]
           ,[State]
           ,[Zip]
           ,[Tel]
           ,[Fax]
           ,[Email]
           ,[ActiveStartDate]
           ,[ActiveEndDate])
           
  SELECT [StoreID]
      ,[ChainID]
      ,[StoreNumber] --right([StoreID], LEN([StoreID]) - 3)
      ,[StoreName]
      ,[StoreMgr]
      ,[Address]
      ,[City]
      ,[State]
      ,[ZipCode]
      ,[Tel]
      ,[Fax]
      ,[email]
      ,[ActiveDate]
      ,case when [DateClosed] = 'NULL' then '12/31/2025' else isnull([DateClosed], '12/31/2025') end

  FROM [Import].[dbo].[RAStoreList]

update [DataTrue_EDI].[dbo].[Load_Stores] set Storemanager = null where Storemanager = 'NULL' 
update [DataTrue_EDI].[dbo].[Load_Stores] set fax = null where fax = 'NULL' 
update [DataTrue_EDI].[dbo].[Load_Stores] set email = null where email = 'NULL' 
update [DataTrue_EDI].[dbo].[Load_Stores] set LoadStatus = 0 where chainidentifier = 'RA'
           
select count(*) from [DataTrue_EDI].[dbo].[Load_Stores] where loadstatus < 0    


INSERT INTO [DataTrue_EDI].[dbo].[Load_Suppliers]
           ([SupplierIdentifier]
           ,[SupplierName]
           ,[Contact]
           ,[Address]
			,[Address2]
           ,[City]
           ,[State]
           ,[Zip]
           ,[Tel]
           ,[Fax]
           ,[Email]
           ,[ActiveStartDate]
           ,[ActiveLastDate]
           ,[LoadStatus])
 SELECT distinct [WholesalerID]
      ,[WholesalerName]
      ,[Contact]
      ,[Address]
      ,[Address2]
      ,[City]
      ,[State]
      ,[ZipCode]
      ,[Tel]
      ,[Fax]
      ,[Email]
      ,'1/1/2011'
      ,case when [active] = 1 then '12/31/2025' else '12/13/2010' end
      ,0
  FROM [Import].[dbo].[WholesalersList]          

--select * from [DataTrue_EDI].[dbo].[Load_Manufacturers]  
--delete [DataTrue_EDI].[dbo].[Load_Manufacturers]  where Contact <> 'Jack Snack' 
--select * FROM [Import].[dbo].[PublishersList]        
INSERT INTO [DataTrue_EDI].[dbo].[Load_Manufacturers]
           ([ManufacturerName]
           ,[ManufacturerIdentifier]
           ,[Contact]
           ,[Address]
           ,[City]
           ,[State]
           ,[Zip]
           ,[Tel]
           ,[Fax]
           ,[Email]
           ,[ActiveStartDate]
           ,[ActiveEndDate]
           ,[LoadStatus])
SELECT Distinct [PublisherName]
	  ,[PublisherID]
      ,[Contact]
      ,[Address]
      ,[City]
      ,[State]
      ,[ZipCode]
      ,[Tel]
      ,[Fax]
      ,[EmailAddress]
      ,'1/1/2011'
      ,'12/31/2025'
      ,0
  FROM [Import].[dbo].[PublishersList]

INSERT INTO [DataTrue_EDI].[dbo].[Load_Brands]
           ([BrandName]
           ,[BrandIdentifier]
           ,[BrandDescription]
           ,[ManufacturerIdentifier]
           ,[LoadStatus])
SELECT [PublisherName]
		,[PublisherID]
		,[PublisherName]
		,[PublisherID]
      ,0
  FROM [Import].[dbo].[PublishersList]



select top 1 * from [Import].[dbo].[Products]
select top 1 * from [Import].[dbo].[BaseOrder]

select 
i.productid
,CAST(0 as int) as brandid
,CAST(0 as int) as chainid
,CAST(0 as int) as storeid
,CAST(0 as int) as supplierid
,b.chainid as chainidentifier
,b.storeid as storeidentifier 
,b.wholesalerid as supplieridentifier
,p.titlename
,p.upc
,p.publisherid as manufactureridentifier
into datatrue_archive..tmpstoresetuplegacysource2
from productidentifiers i
inner join [Import].[dbo].[Products] p
on i.IdentifierValue = p.upc
inner join [Import].[dbo].[BaseOrder] b
on p.bipad = b.bipad
where b.chainid = 'RA'

--ICVNDPTL01\[Import]

select COUNT(*) from datatrue_archive..tmpstoresetuplegacysource2
select COUNT(*) from datatrue_archive..tmpstoresetuplegacysource2 
where LEFT(chainidentifier,2) = 'ra'

select COUNT(*)
--select ltrim(rtrim(t.chainidentifier)), ltrim(rtrim(s.chainidentifier)), *
--update t set t.chainid = s.chainid
from datatrue_archive..tmpstoresetuplegacysource2 t
inner join Chains s
on ltrim(rtrim(t.chainidentifier)) = ltrim(rtrim(s.chainidentifier))

select top 1000 * from datatrue_archive..tmpstoresetuplegacysource
select count(*) from datatrue_archive..tmpstoresetuplegacysource

update datatrue_archive..tmpstoresetuplegacysource2 
set storeidentifier = right(ltrim(rtrim(storeidentifier)),len(storeidentifier) - 2)
where LEFT(UPPER(storeidentifier),2) = 'RA'

select COUNT(*)
--update t set t.storeid = s.storeid
from datatrue_archive..tmpstoresetuplegacysource2 t
inner join Stores s
on cast(ltrim(rtrim(t.storeidentifier)) as int) = cast(ltrim(rtrim(s.storeidentifier)) as int)
and t.chainid = s.chainid

select COUNT(*)
--update t set t.supplierid = s.supplierid
from datatrue_archive..tmpstoresetuplegacysource2 t
inner join Suppliers s
on ltrim(rtrim(t.supplieridentifier)) = ltrim(rtrim(s.supplieridentifier))

select top 1000 * from datatrue_archive..tmpstoresetuplegacysource2
where supplierid = 0

update datatrue_archive..tmpstoresetuplegacysource2
set brandidentifier = manufactureridentifier

--/*
select *
--update t set brandid = 0 --b.brandid
from datatrue_archive..tmpstoresetuplegacysource2 t
inner join brands b
on t.brandidentifier = b.brandidentifier
--*/

select storeid from datatrue_archive..tmpstoresetuplegacysource2
where storeid not in (select storeid from stores)

select * from Stores where ChainID = 35541
select * from StoreSetupdelete where ChainID = 35541
select distinct storeid from StoreSetup where ChainID = 35541

INSERT INTO [DataTrue_Main].[dbo].[StoreSetup]
           ([ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[BrandID]
           ,[SupplierID]
           ,[InventoryRuleID]
           ,[LastUpdateUserID]
           ,[ActiveStartDate]
           ,[ActiveLastDate])
SELECT distinct [chainid]
      ,[storeid]
      ,[productid]
      ,[brandid]
      ,[supplierid]
      ,0 --inventoryruleid 0=perpetual
      ,2
      ,dateadd(month, -1, getdate())
      ,dateadd(month, 12, getdate())
      
  FROM [DataTrue_Archive].[dbo].[tmpstoresetuplegacysource2] tmp2
  where tmp2.storeid not in
  (select storeid from StoreSetup where chainid = 35541)
  
  select * into storesetupdelete from StoreSetup where ChainID = 35541
  select * from StoreSetup where ChainID = 35541
  
  --(35810, 4589, 27923, 0
  select *
  from [DataTrue_Archive].[dbo].[tmpstoresetuplegacysource2]
  where storeid = 35810
  and ProductID = 4589
  
MERGE INTO [dbo].[StoreSetup] i

USING (SELECT [ChainID], [StoreID]
      ,[ProductID]
      ,[BrandID]
      ,[SupplierID]
      from [DataTrue_Archive].[dbo].[tmpstoresetuplegacysource2]
      group by [ChainID], [StoreID]
      ,[ProductID]
      ,[BrandID]
      ,[SupplierID]) S
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
           ,[SupplierID]
           ,[InventoryRuleID]
           ,[LastUpdateUserID]
           ,[ActiveStartDate]
           ,[ActiveLastDate])
     VALUES
           (s.[ChainID], s.[StoreID]
			,s.[ProductID]
			,s.[BrandID]
			,s.[SupplierID]
			,0 --inventoryruleid 0=perpetual
			,2
			,dateadd(month, -1, getdate())
			,dateadd(month, 12, getdate()));


INSERT INTO [DataTrue_Main].[dbo].[ProductPrices]
           ([ProductPriceTypeID]
           ,[ProductID]
           ,[ChainID]
           ,[StoreID]
           ,[BrandID]
           ,[SupplierID]
           ,[UnitPrice]
           ,[UnitRetail]
           ,[PricePriority]
           ,[ActiveStartDate]
           ,[ActiveLastDate]
           ,[LastUpdateUserID])
SELECT 3
	  ,[productid]
      ,[chainid]
      ,[storeid]
      ,[brandid]
      ,[supplierid]
      ,[cost]
      ,[retail]
      ,0
      ,dateadd(month, -1, getdate())
      ,dateadd(month, 12, getdate())
      ,2
      FROM [DataTrue_Archive].[dbo].[tmpstoresetuplegacysource2]

merge into [DataTrue_Main].[dbo].[ProductPrices] i

USING (SELECT [ChainID], [StoreID]
      ,[ProductID]
      ,[BrandID]
      ,[SupplierID]
      ,isnull(max([Cost]), 0.00) as cost
      ,isnull(max([Retail]), 0.00) as retail
      from [DataTrue_Archive].[dbo].[tmpstoresetuplegacysource2]
      group by [ChainID], [StoreID]
      ,[ProductID]
      ,[BrandID]
      ,[SupplierID]) S
	on i.ChainID = s.ChainID
	and i.StoreID = s.StoreID 
	and i.ProductID = s.ProductID
	and i.BrandID = s.BrandID
	and i.SupplierID = s.SupplierID
	--and i.ProductPriceTypeID = 4

WHEN NOT MATCHED 

THEN INSERT 

([ProductPriceTypeID]
           ,[ProductID]
           ,[ChainID]
           ,[StoreID]
           ,[BrandID]
           ,[SupplierID]
           ,[UnitPrice]
           ,[UnitRetail]
           ,[PricePriority]
           ,[ActiveStartDate]
           ,[ActiveLastDate]
           ,[LastUpdateUserID])
values (3 --4
	  ,s.[productid]
      ,s.[chainid]
      ,s.[storeid]
      ,s.[brandid]
      ,s.[supplierid]
      ,s.[cost]
      ,s.[retail]
      ,0
      ,dateadd(month, -1, getdate())
      ,dateadd(month, 12, getdate())
      ,2);







SELECT     TOP (10) StoreID, Bipad, WholesalerID, ChainID, CostToStore, CostToStore4Wholesaler, CostToWholesaler, SuggRetail, DateChanged, DefaultCost, 
                      DefaultRetail
FROM         [Import]..[ProductsPrices Expanded]
WHERE     (ChainID = 'RA')

select top 10 * from [Import]..Products

select * FROM [DataTrue_Archive].[dbo].[tmpstoresetuplegacysource]

update t set t.cost = e.costtostore, t.retail = e.SuggRetail
from [DataTrue_Archive].[dbo].[tmpstoresetuplegacysource2] t
inner join [Import]..Products p
on t.upc = p.upc
inner join [Import]..[ProductsPrices Expanded] e
on p.bipad = e.bipad
           
select count(*) from datatrue_edi..Inbound852Sales where recordstatus = 0
update datatrue_edi..Inbound852Sales set recordstatus = 0 where ChainIdentifier = 'RA'   
           
--update t StoreTransactions_Working set t.brandidentifier = s

update storesetup set activestartdate = dateadd(month, -1, getdate())
      , activelastdate = dateadd(month, 12, getdate())
      where activestartdate is null

select *
--update s set supplierid = t.supplierid
from StoreSetup s
inner join datatrue_archive..tmpstoresetuplegacysource t
on s.ProductID = t.ProductID
and s.SupplierID = t.supplierid
and s.StoreID = t.storeid

select *
--update s set brandid = t.brandid
from StoreSetup s
inner join datatrue_archive..tmpstoresetuplegacysource t
on s.ProductID = t.ProductID
and s.SupplierID = t.supplierid
and s.StoreID = t.storeid

update w set supplierid = s.supplierid
,BrandID = s.brandid
from StoreTransactions_Working w
inner join StoreSetup s
on w.ChainID = s.ChainID
and w.StoreID = s.StoreID
and w.ProductID = s.productid

select *
--update t set supplierid = w.supplierid
,BrandID = w.brandid
from StoreTransactions_Working w
inner join StoreTransactions t
on w.StoreTransactionID = t.WorkingTransactionID

select *
--update p set brandid = s.brandid
from inventoryperpetual p
inner join StoreSetup s
on p.ChainID = s.ChainID
and p.StoreID = s.StoreID
and p.ProductID = s.productid

drop table datatrue_report..storetransactions
drop table datatrue_report..inventoryperpetual

select * into datatrue_report..storetransactions
from storetransactions

select * into datatrue_report..inventoryperpetual
from inventoryperpetual

select * from Suppliers where SupplierID = 7584

select SupplierID, COUNT(SupplierID) 
from datatrue_main..storetransactions_working
group by SupplierID
order by COUNT(SupplierID) desc

select SupplierID, COUNT(SupplierID) 
from datatrue_main..StoreSetup
group by SupplierID
order by COUNT(SupplierID) desc

select SupplierID, COUNT(SupplierID) 
from datatrue_main..storetransactions_working
group by SupplierID
order by COUNT(SupplierID) desc

select SupplierID, COUNT(SupplierID) 
from datatrue_main..storetransactions
group by SupplierID
order by COUNT(SupplierID) desc

select SupplierID, COUNT(SupplierID) 
from datatrue_report..storetransactions
group by SupplierID
order by COUNT(SupplierID) desc

select brandID, COUNT(SupplierID) 
from datatrue_report..storetransactions
group by brandID
order by COUNT(brandID) desc

select * from Brands where BrandID = 328

select * from Manufacturers where ManufacturerID = 35929
select * from Suppliers where SupplierID = 7584


select *
from StoreSetup
where SupplierID = 7584
/*	           
declare @rec cursor
declare @supplieridentifier nvarchar(50)
declare @supplierid int

set @rec = CURSOR local fast_forward FOR
	select distinct wholesalerid from [Import].[dbo].[WholesalersList]

open @rec

fetch next from @rec into @supplieridentifier

while @@FETCH_STATUS = 0
	begin

		INSERT INTO [DataTrue_Main].[dbo].[SystemEntities]
				   ([EntityTypeID]
				   ,[LastUpdateUserID])
			 VALUES
				   (5
				   ,2)
				   
		select @supplierid = SCOPE_IDENTITY()


		fetch next from @rec into @supplieridentifier	
	end
	
close @rec
deallocate @rec
*/
/*
select top 1 * 
from [Import].[dbo].[Products]

select top 1000 * 
from [Import].[dbo].[BaseOrder]
where chainid = 'cvs'
*/


return
GO
