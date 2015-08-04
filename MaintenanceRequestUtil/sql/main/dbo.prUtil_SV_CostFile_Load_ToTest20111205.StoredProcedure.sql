USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_SV_CostFile_Load_ToTest20111205]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_SV_CostFile_Load_ToTest20111205]

as


select count(*) from SV_CostFile

select top 1000 * from SV_CostFile

select distinct banner from SV_CostFile
select distinct dtbanner from SV_CostFile
  
/*
Cub Foods
update SV_CostFile set dtbanner = 'Cub Foods' where banner = 'Cub Foods'
Farm Fresh
update SV_CostFile set dtbanner = 'Farm Fresh Markets' where banner = 'Farm Fresh'
Hornbachers
update SV_CostFile set dtbanner = 'Hornbachers' where banner = 'Hornbachers'
Shoppers Food
update SV_CostFile set dtbanner = 'Shoppers Food and Pharmacy' where banner = 'Shoppers Food'
SNS ST LOUIS
update SV_CostFile set dtbanner = 'Shop N Save Warehouse Foods Inc' where banner = 'SNS ST LOUIS'
select distinct custom1 from stores
*/

select top 1000 * from SV_CostFile
select distinct suppliername from SV_CostFile


--match suppliers by name
--PURAFILTER/ARIES 40568
update SV_CostFile set dtsupplierid = 40568 where suppliername = 'ARIES MARKETING INC'
--BIMBO 40557
update SV_CostFile set dtsupplierid = 40557 where suppliername = 'BIMBO FOODS INC..'
--BURPEE 40578
update SV_CostFile set dtsupplierid = 40578 where suppliername = 'BURPEE GARDEN PRODUCTS..'
--CHOICE BOOKS 40569
update SV_CostFile set dtsupplierid = 40569 where suppliername = 'CHOICE BOOKS'
--DAILY ADVANCE 40572
update SV_CostFile set dtsupplierid = 40572 where suppliername = 'DAILY ADVANCE'
--DAILY PRESS 40571
update SV_CostFile set dtsupplierid = 40571 where suppliername = 'DAILY PRESS INC'
--FLOWERS 40567
update SV_CostFile set dtsupplierid = 40567 where suppliername = 'FLOWERS BAKING CO OF NORFOLK'
--GOPHER NEWS 40558
update SV_CostFile set dtsupplierid = 40558 where suppliername = 'GOPHER NEWS COMPANY'
--LEWIS 41464
update SV_CostFile set dtsupplierid = 41464 where suppliername = 'LEWIS VINCENNES INC'
--MARVA MAID 40563
update SV_CostFile set dtsupplierid = 40563 where suppliername = 'MARVA MAID OF NEWPORT NEWS LLC'
--NATURES FINEST LLC
update SV_CostFile set dtsupplierid = 40560 where suppliername = 'NATURES FINEST LLC'
--NESTLE DSD CO PIZZA 40559
update SV_CostFile set dtsupplierid = 40559 where suppliername = 'NESTLE DSD CO PIZZA'
--NESTLE DSD COMPANY... 40559
update SV_CostFile set dtsupplierid = 40559 where suppliername = 'NESTLE DSD COMPANY...'
--PEPPERIDGE FARM 40562
update SV_CostFile set dtsupplierid = 40562 where suppliername = 'PEPPERIDGE FARM INC'
--PEPPERIDGE FARM 40562
update SV_CostFile set dtsupplierid = 40562 where suppliername = 'PEPPERIDGE FARM INCORPORATE'
--PLANTATION PRODUCTS INC 40557
update SV_CostFile set dtsupplierid = 40557 where suppliername = 'PLANTATION PRODUCTS INC'
--RD CANDLES 40560
update SV_CostFile set dtsupplierid = 40560 where suppliername = 'RD CANDLES'
--RUG DOCTOR 40560
update SV_CostFile set dtsupplierid = 40560 where suppliername = 'RUG DOCTOR'
--SARA LEE BAKERY GROUP  X 41465
update SV_CostFile set dtsupplierid = 41465 where suppliername = 'SARA LEE BAKERY GROUP  X'
--SCHMIDT BAKING COMPANY 40561
update SV_CostFile set dtsupplierid = 40561 where suppliername = 'SCHMIDT BAKING COMPANY'
--SONY PICTURES HOME ENTERTAINMT 40570
update SV_CostFile set dtsupplierid = 40570 where suppliername = 'SONY PICTURES HOME ENTERTAINMT'
--SOURCE INTERLINK DISTRIBUTION. 41440
update SV_CostFile set dtsupplierid = 41440 where suppliername = 'SOURCE INTERLINK DISTRIBUTION.'
--TIDEWATER TRADING POST 40573
update SV_CostFile set dtsupplierid =  40573 where suppliername = 'TIDEWATER TRADING POST'
--VA PILOT & LEDGER STAR 40566
update SV_CostFile set dtsupplierid = 40566 where suppliername = 'VA PILOT & LEDGER STAR'
--VIRGINIA GAZETTE COMPANIES 40564
update SV_CostFile set dtsupplierid = 40564 where suppliername = 'VIRGINIA GAZETTE COMPANIES'
/*
DIANA'S TORTILLAS 41342
update SV_CostFile set dtsupplierid = 41342 where supplier_name = 'DIANA''S TORTILLAS'
NESTLE/EDYS 40559
update SV_CostFile set dtsupplierid = 40559 where supplier_name = 'NESTLE/EDYS'
PEPPERIDGE FARM 40562
update SV_CostFile set dtsupplierid = 40562 where supplier_name = 'PEPPERIDGE FARM'
SONY PICTURES HOME ENTERTAINMT 40570
update SV_CostFile set dtsupplierid = 40570 where supplier_name = 'SONY PICTURES HOME ENTERTAINMT'
*/
select * from SV_CostFile where dtsupplierid = 0

select top 1000 * from SV_CostFile
select distinct suppliername from SV_CostFile
select distinct dtbanner from SV_CostFile

select * --1802755
--update c set c.dtstoreid = s.storeid
from SV_CostFile c
inner join stores s
on CAST(c.bannerstorenbr as INt) = CAST(s.custom2 as INt)
--on CAST(c.bannerstorenbr as INt) = CAST(s.storeidentifier as INt)
and LTRIM(rtrim(c.dtbanner)) = LTRIM(RTRIM(s.custom1))
and s.ChainID = 40393

select top 1000 * from SV_CostFile

update w set w.dtproductid = 0
 from SV_CostFile w

    select w.POSCode, i.IdentifierValue, i.productid
    --update w set w.dtproductid = i.productid
 from SV_CostFile w
 inner join ProductIdentifiers i
 on ltrim(rtrim(w.POSCode)) = substring(ltrim(rtrim(i.IdentifierValue)), 2, 10)
 and LEN(ltrim(rtrim(i.IdentifierValue))) = 12
 
 select * from SV_CostFile
where dtstoreid <> 0
and dtProductId <> 0
and dtsupplierid <> 0
and InactiveDate <> '?'

select top 10 * from SV_CostFile

select * from ProductPricesTest20111205 where ProductPriceID = 3918497
select * from ProductPricesTest20111205 where storeid = 40535 and ProductId = 20872 and supplierid = 40557
--8	40393	40530	8722	0	40562	0.34	0.00	10/24/2011	1/3/2012
select * from ProductPricesTest20111205 where storeid = 40530 and ProductId = 8722 and supplierid = 40562

select distinct c.CostAmount, p.UnitPrice, p.*
--update c set c.alreadythere = 1
from SV_CostFile c
inner join ProductPricesTest20111205 p
on c.dtstoreid = p.StoreID
and c.dtproductid = p.ProductID
and c.dtsupplierid = p.SupplierID
where p.productpricetypeid = 8
and c.CostType = 'OIA'
and c.alreadythere = 0
--order by p.UnitPrice - c.CostAmount desc

--Merge into ProductPricesTest20111205
MERGE INTO [dbo].[ProductPricesTest20111205] t

USING (select distinct 8 as productpricetypeid
		,40393 as ChainID
	  ,[dtStoreID] as StoreID
      ,[dtProductID] as ProductID
      ,cast(0 as int) as BrandID
      ,[dtSupplierID] as SupplierID
      ,cast([CostAmount] * -1.000 as money) as Allowance
      ,cast(0 as money) as UnitRetail
      ,ActiveDate as StartDate
      ,InactiveDate as EndDate

from SV_CostFile
where dtproductid <> 0 and dtstoreid <> 0 
and dtsupplierid <> 0 and CostType = 'OIA' and alreadythere = 0) S
on t.ChainID = s.ChainID
and t.StoreID = s.StoreID 
and t.ProductID = s.ProductID
and t.BrandID = s.BrandID
and t.SupplierID = s.SupplierID
and t.ProductPriceTypeID = s.productpricetypeid

/*
WHEN MATCHED 
	Then update
			set t.ProcessingErrorDesc = ltrim(rtrim(cast(s.[StoreTransactionID] as nvarchar(50))))
*/
WHEN NOT MATCHED 

        THEN INSERT
           ([ProductPriceTypeID]
           ,[ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[BrandID]
           ,[SupplierID]
           ,[UnitPrice]
           ,[UnitRetail]
           ,[LastUpdateUserID])
     VALUES
		(s.productpricetypeid
		,S.[ChainID] 
			,S.[StoreID]
           ,S.[ProductID]
           ,s.[BrandID]
           ,S.[SupplierID]
           ,s.[Allowance]
           ,s.[UnitRetail]
           ,2);
--shop n save SS banner



select distinct c.CostAmount, p.UnitPrice, p.*
--update c set c.alreadythere = 1
from SV_CostFile c
inner join ProductPricesTest20111205 p
on c.dtstoreid = p.StoreID
and c.dtproductid = p.ProductID
and c.dtsupplierid = p.SupplierID
where p.productpricetypeid = 8
and c.CostType = 'OIA'
and c.alreadythere = 0
--order by p.UnitPrice - c.CostAmount desc

--Merge into ProductPricesTest20111205
MERGE INTO [dbo].[ProductPricesTest20111205] t

USING (select distinct 8 as productpricetypeid
		,40393 as ChainID
	  ,[dtStoreID] as StoreID
      ,[dtProductID] as ProductID
      ,cast(0 as int) as BrandID
      ,[dtSupplierID] as SupplierID
      ,[CostAmount] as Allowance
      ,cast(0 as money) as UnitRetail
      ,ActiveDate as StartDate
      ,InactiveDate as EndDate

from SV_CostFile
where dtproductid <> 0 and dtstoreid <> 0 
and dtsupplierid <> 0 and CostType = 'LIST' and alreadythere = 0) S
on t.ChainID = s.ChainID
and t.StoreID = s.StoreID 
and t.ProductID = s.ProductID
and t.BrandID = s.BrandID
and t.SupplierID = s.SupplierID
and t.ProductPriceTypeID = s.productpricetypeid

/*
WHEN MATCHED 
	Then update
			set t.ProcessingErrorDesc = ltrim(rtrim(cast(s.[StoreTransactionID] as nvarchar(50))))
*/
WHEN NOT MATCHED 

        THEN INSERT
           ([ProductPriceTypeID]
           ,[ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[BrandID]
           ,[SupplierID]
           ,[UnitPrice]
           ,[UnitRetail]
           ,[LastUpdateUserID])
     VALUES
		(s.productpricetypeid
		,S.[ChainID] 
			,S.[StoreID]
           ,S.[ProductID]
           ,s.[BrandID]
           ,S.[SupplierID]
           ,s.[Allowance]
           ,s.[UnitRetail]
           ,2);


--Merge into ProductPricesTest20111205
MERGE INTO [dbo].[ProductPricesTest20111205] t

USING (select distinct 8 as productpricetypeid
		,40393 as ChainID
	  ,[dtStoreID] as StoreID
      ,[dtProductID] as ProductID
      ,cast(0 as int) as BrandID
      ,[dtSupplierID] as SupplierID
      ,cast([CostAmount] * -1.000 as money) as Allowance
      ,cast(0 as money) as UnitRetail
      ,ActiveDate as StartDate
      ,InactiveDate as EndDate

from SV_CostFile
where dtproductid <> 0 and dtstoreid <> 0 
and dtsupplierid <> 0 and CostType = 'OIA' and alreadythere = 0) S
on t.ChainID = s.ChainID
and t.StoreID = s.StoreID 
and t.ProductID = s.ProductID
and t.BrandID = s.BrandID
and t.SupplierID = s.SupplierID
and t.ProductPriceTypeID = s.productpricetypeid

/*
WHEN MATCHED 
	Then update
			set t.ProcessingErrorDesc = ltrim(rtrim(cast(s.[StoreTransactionID] as nvarchar(50))))
*/
WHEN NOT MATCHED 

        THEN INSERT
           ([ProductPriceTypeID]
           ,[ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[BrandID]
           ,[SupplierID]
           ,[UnitPrice]
           ,[UnitRetail]
           ,[LastUpdateUserID])
     VALUES
		(s.productpricetypeid
		,S.[ChainID] 
			,S.[StoreID]
           ,S.[ProductID]
           ,s.[BrandID]
           ,S.[SupplierID]
           ,s.[Allowance]
           ,s.[UnitRetail]
           ,2);
--shop n save SS banner

update SV_CostFile set alreadythere = 0
select * from ProductPricesTest20111205 where storeid = 40467 and ProductId = 5460 and supplierid = 41440


select distinct c.CostAmount, p.UnitPrice, p.*
--update c set c.alreadythere = 1
from SV_CostFile c
inner join ProductPricesTest20111205 p
on c.dtstoreid = p.StoreID
and c.dtproductid = p.ProductID
and c.dtsupplierid = p.SupplierID
where p.productpricetypeid = 3
and c.CostType = 'LIST'
and c.alreadythere = 0
--order by p.UnitPrice - c.CostAmount desc

--Merge into ProductPricesTest20111205
MERGE INTO [dbo].[ProductPricesTest20111205] t

USING (select distinct 5 as productpricetypeid
		,40393 as ChainID
	  ,[dtStoreID] as StoreID
      ,[dtProductID] as ProductID
      ,cast(0 as int) as BrandID
      ,[dtSupplierID] as SupplierID
      ,[CostAmount] as Allowance
      ,cast(0 as money) as UnitRetail
      ,ActiveDate as StartDate
      ,InactiveDate as EndDate

from SV_CostFile
where dtproductid <> 0 and dtstoreid <> 0 
and dtsupplierid <> 0 and CostType = 'LIST' and alreadythere = 0) S
on t.ChainID = s.ChainID
and t.StoreID = s.StoreID 
and t.ProductID = s.ProductID
and t.BrandID = s.BrandID
and t.SupplierID = s.SupplierID
and t.ProductPriceTypeID = s.productpricetypeid

/*
WHEN MATCHED 
	Then update
			set t.ProcessingErrorDesc = ltrim(rtrim(cast(s.[StoreTransactionID] as nvarchar(50))))
*/
WHEN NOT MATCHED 

        THEN INSERT
           ([ProductPriceTypeID]
           ,[ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[BrandID]
           ,[SupplierID]
           ,[UnitPrice]
           ,[UnitRetail]
           ,[LastUpdateUserID])
     VALUES
		(s.productpricetypeid
		,S.[ChainID] 
			,S.[StoreID]
           ,S.[ProductID]
           ,s.[BrandID]
           ,S.[SupplierID]
           ,s.[Allowance]
           ,s.[UnitRetail]
           ,2);

  return
GO
