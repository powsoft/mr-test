USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Testing_SBTCostAllowanceBook]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Testing_SBTCostAllowanceBook]
as


--productid

SELECT *
  FROM [Import].[dbo].[SBTCostAllowanceBook]

SELECT top 100 *
  FROM [Import].[dbo].[SBTCostAllowanceBook]
  order by dateenda
  
SELECT *
  FROM [Import].[dbo].[SBTCostAllowanceBook] where dtProductId <> 0
 
SELECT distinct UPC, CAST('' as nvarchar(50)) as upc12, CAST(0 as int) as ProductId, originallength
into #productmatch
  FROM [Import].[dbo].[SBTCostAllowanceBook]
  
SELECT *
  FROM #productmatch c
  inner join ProductIdentifiers i
  on ltrim(rtrim(c.upc12)) = ltrim(rtrim(i.IdentifierValue))  
  
    select w.[upc], i.IdentifierValue, i.productid, w.description
    --update w set w.dtproductid  = i.productid
 from [Import].[dbo].[SBTCostAllowanceBook] w
 inner join ProductIdentifiers i
  on ltrim(rtrim(w.[upc12])) = ltrim(rtrim(i.IdentifierValue))
--on ltrim(rtrim(w.[12upc])) = substring(ltrim(rtrim(i.IdentifierValue)), 2, 10)
 --on substring(ltrim(rtrim(w.[upc])), 2, 10) = substring(ltrim(rtrim(i.IdentifierValue)), 2, 10)

 /*
  where ltrim(rtrim(w.[upc]))
  not in 
(select ltrim(rtrim(identifiervalue)) from ProductIdentifiers)
and LEN(ltrim(rtrim(i.identifiervalue))) = 11  
  */  
  
 select *
  from [Import].[dbo].[SBTCostAllowanceBook]
  where ltrim(rtrim([upc12])) not in
  (select ltrim(rtrim(IdentifierValue)) from ProductIdentifiers)
  
  select distinct upc12, description
  from [Import].[dbo].[SBTCostAllowanceBook]
  where ltrim(rtrim([upc12])) not in
  (select ltrim(rtrim(IdentifierValue)) from ProductIdentifiers) 
 
 
 INSERT INTO [DataTrue_EDI].[dbo].[Load_Products]
           ([ProductIdentifier]
           ,[ProductDescription]
           ,[ProductPrice]
           ,[ProductCost]
           ,[ActiveStartDate]
           ,[ActiveLastDate]
           ,[LoadStatus]
           ,[LoadType]
           ,[ProductRetailPrice])
     select
           upc12
           ,Max(Description)
           ,max(Cost)
           ,max(Cost)
           ,'1/1/2000'
           ,'12/31/2025'
           ,0
           ,'ADD'
           ,0.0
  from [Import].[dbo].[SBTCostAllowanceBook]
  where ltrim(rtrim([upc12])) not in
  (select ltrim(rtrim(IdentifierValue)) from ProductIdentifiers)
  Group by upc12 

 
    select * --distinct upc12, description
  from [Import].[dbo].[SBTCostAllowanceBook]
  where ltrim(rtrim([upc12])) not in
  (select ltrim(rtrim(IdentifierValue)) from ProductIdentifiers) 
  
  select * from datatrue_edi.dbo.Load_Products where LoadStatus = 0
  
--storeid

  select *
  --update b set b.dtstoreid = s.storeid
  from [Import].[dbo].[SBTCostAllowanceBook] b
  inner join stores s
  on cast(b.store as int) = cast(s.StoreIdentifier as int)
  where s.Custom3 = 'SS'
  
  select distinct vendorname from [Import].[dbo].[SBTCostAllowanceBook]
  
--Nestle Pizza 40559
update [Import].[dbo].[SBTCostAllowanceBook] set dtsupplierid = 40559 where ltrim(rtrim(vendorname)) = 'Nestle Pizza'
--Burpee Garden Prod Co
update [Import].[dbo].[SBTCostAllowanceBook] set dtsupplierid = 40578 where ltrim(rtrim(vendorname)) = 'Burpee Garden Prod Co'
--Lewis
update [Import].[dbo].[SBTCostAllowanceBook] set dtsupplierid = 41464 where ltrim(rtrim(vendorname)) = 'Lewis'
--Dreyers
update [Import].[dbo].[SBTCostAllowanceBook] set dtsupplierid = 40559 where ltrim(rtrim(vendorname)) = 'Dreyers'
--Pepperidge Farm - Breads
update [Import].[dbo].[SBTCostAllowanceBook] set dtsupplierid = 40562 where ltrim(rtrim(vendorname)) = 'Pepperidge Farm - Breads'
--Rug Doctor
update [Import].[dbo].[SBTCostAllowanceBook] set dtsupplierid = 40560 where ltrim(rtrim(vendorname)) = 'Rug Doctor'
--Sony Home Entertainment
update [Import].[dbo].[SBTCostAllowanceBook] set dtsupplierid = 40570 where ltrim(rtrim(vendorname)) = 'Sony Home Entertainment'
--Sara Lee 
 update [Import].[dbo].[SBTCostAllowanceBook] set dtsupplierid = 41465 where ltrim(rtrim(vendorname)) = 'Sara Lee'

select distinct dtsupplierid from [Import].[dbo].[SBTCostAllowanceBook]

--productid update

select distinct LEN(UPC) from [Import].[dbo].[SBTCostAllowanceBook]
select * from [Import].[dbo].[SBTCostAllowanceBook] where LEN(UPC) = 10
select * from [Import].[dbo].[SBTCostAllowanceBook] where LEN(UPC) = 11
select distinct upc from [Import].[dbo].[SBTCostAllowanceBook] where LEN(UPC) = 11

update [Import].[dbo].[SBTCostAllowanceBook] set upc12 = null where LEN(UPC) = 10

update [Import].[dbo].[SBTCostAllowanceBook] set originallength = 10 where LEN(UPC) = 10
update [Import].[dbo].[SBTCostAllowanceBook] set originallength = 11 where LEN(UPC) = 11

select distinct UPC, CAST('' as nvarchar(50))  as upc12
into #distinctupc 
from [Import].[dbo].[SBTCostAllowanceBook] where LEN(UPC) = 10 

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
	set @upc11 = '0' + @UPC
	
	exec [dbo].[prUtil_UPC_GetCheckDigit]
	 @upc11,
	 @CheckDigit OUT
	 
	 update [Import].[dbo].[SBTCostAllowanceBook] set upc12 = @upc11 + @CheckDigit
	 where upc = @upc
	
		fetch next from @rec into @upc
--fetch next from @rec into @recordid, @upc
	end
	
close @rec
deallocate @rec


/*
declare @rec cursor
declare @upc nvarchar(50)
declare @upc12 nvarchar(50)
declare @recordid int
declare @checkdigit char(1)
*/

set @rec = CURSOR local fast_forward FOR
	select recordid, UPC from [Import].[dbo].[SBTCostAllowanceBook] where LEN(UPC) = 11 and upc12 is null
	
open @rec

fetch next from @rec into @recordid, @upc

while @@FETCH_STATUS = 0
	begin

	set @checkdigit = ''

	exec [dbo].[prUtil_UPC_GetCheckDigit]
	 @UPC,
	 @CheckDigit OUT
	 
	 update [Import].[dbo].[SBTCostAllowanceBook] set upc12 = UPC + @CheckDigit
	 where recordid = @recordid
	
		fetch next from @rec into @recordid, @upc
	end
	
close @rec
deallocate @rec

	select *
      from [Import].[dbo].[SBTCostAllowanceBook]
      where dtstoreid = 0 or dtproductid = 0 or dtsupplierid = 0


--Merge into storesetup
MERGE INTO [dbo].[StoreSetup] t

USING (select distinct 40393 as ChainID
	  ,dtStoreID as StoreID
      ,dtProductID as ProductiD
      ,cast(0 as int) as BrandID
      ,dtSupplierid as SupplieriD
      from [Import].[dbo].[SBTCostAllowanceBook]
      where dtstoreid <> 0 and dtproductid <> 0 and dtsupplierid <> 0) S
on t.ChainID = s.ChainID
and t.StoreID = s.StoreID 
and t.ProductID = s.ProductID
and t.BrandID = s.BrandID
and t.SupplierID = s.SupplierID

WHEN NOT MATCHED 

        THEN INSERT
           ([ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[BrandID]
           ,[SupplierID]
           ,[LastUpdateUserID])
     VALUES
		(S.[ChainID] 
			,S.[StoreID]
           ,S.[ProductID]
           ,s.[BrandID]
           ,S.[SupplierID]
           ,2);

--Merge into productprices type 3
--select top 1000 * from [Import].[dbo].[SBTCostAllowanceBook]
MERGE INTO [dbo].[productprices] t

USING (select 3 as productpricetypeid
		,40393 as ChainID
	  ,dtStoreID as StoreID
      ,dtProductID as ProductID
      ,cast(0 as int) as BrandID
      ,dtSupplierid as SupplieriD
      ,max(Cost) as UnitPrice
      ,max(Allowance) as Allowance
      ,cast(0 as money) as UnitRetail
      ,max(DateEffA) as StartDate
      ,max(DateEndA) as EndDate
      from [Import].[dbo].[SBTCostAllowanceBook]
      where dtstoreid <> 0 and dtproductid <> 0 and dtsupplierid <> 0
      group by dtstoreid, dtproductid, dtsupplierid) S
on t.ChainID = s.ChainID
and t.StoreID = s.StoreID 
and t.ProductID = s.ProductID
and t.BrandID = s.BrandID
and t.SupplierID = s.SupplierID
and t.ProductPriceTypeID = s.productpricetypeid

--/*
WHEN MATCHED 
	Then update
			set t.UnitPrice = s.[UnitPrice]
			,t.UnitRetail = s.[UnitRetail]
--*/
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
           ,s.[UnitPrice]
           ,s.[UnitRetail]
           ,2);


--Merge into productprices type 5
MERGE INTO [dbo].[productprices] t

USING (select 5 as productpricetypeid
		,40393 as ChainID
	  ,dtStoreID as StoreID
      ,dtProductID as ProductID
      ,cast(0 as int) as BrandID
      ,dtSupplierid as SupplieriD
      ,max(Cost) as UnitPrice
      ,max(Allowance) as Allowance
      ,cast(0 as money) as UnitRetail
      ,max(DateEffA) as StartDate
      ,max(DateEndA) as EndDate
      from [Import].[dbo].[SBTCostAllowanceBook]
      where dtstoreid <> 0 and dtproductid <> 0 and dtsupplierid <> 0
      group by dtstoreid, dtproductid, dtsupplierid) S
on t.ChainID = s.ChainID
and t.StoreID = s.StoreID 
and t.ProductID = s.ProductID
and t.BrandID = s.BrandID
and t.SupplierID = s.SupplierID
and t.ProductPriceTypeID = s.productpricetypeid

--/*
WHEN MATCHED 
	Then update
			set t.UnitPrice = s.[UnitPrice]
			,t.UnitRetail = s.[UnitRetail]
--*/
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
           ,s.[UnitPrice]
           ,s.[UnitRetail]
           ,2);
         
/*
      select * from [Import].[dbo].[SBTCostAllowanceBook]
      where dtstoreid <> 0 and dtproductid <> 0 and dtsupplierid <> 0
      and isdate(DateEffA) > 0 and isdate(DateEndA) > 0 and allowance is not null

      select * from [Import].[dbo].[SBTCostAllowanceBook]
      where isdate(DateEffA) > 0 and DateEndA is not null and allowance is not null
*/
MERGE INTO [dbo].[productprices] t

USING (select distinct 8 as productpricetypeid
		,40393 as ChainID
	  ,dtStoreID as StoreID
      ,dtProductID as ProductID
      ,cast(0 as int) as BrandID
      ,dtSupplierid as SupplieriD
      ,Cost as UnitPrice
      ,Allowance as Allowance
      ,cast(0 as int) as UnitRetail
      ,DateEffA as StartDate
      ,dateadd(day, -1, DateEndA) as EndDate
      from [Import].[dbo].[SBTCostAllowanceBook]
      where dtstoreid <> 0 and dtproductid <> 0 and dtsupplierid <> 0
      and isdate(DateEffA) > 0 and isdate(DateEndA) > 0 and allowance is not null) S
on t.ChainID = s.ChainID
and t.StoreID = s.StoreID 
and t.ProductID = s.ProductID
and t.BrandID = s.BrandID
and t.SupplierID = s.SupplierID
and t.ProductPriceTypeID = s.productpricetypeid
and cast(t.ActiveStartDate as date) = cast(s.startdate as date)
and cast(t.ActiveLastDate as date) = cast(s.enddate as date)

--/*
WHEN MATCHED 
	Then update
			set t.UnitPrice = s.[Allowance]
--*/
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
           ,[LastUpdateUserID]
           ,[ActiveStartDate]
           ,[ActiveLastDate])
     VALUES
		(s.productpricetypeid
		,S.[ChainID] 
			,S.[StoreID]
           ,S.[ProductID]
           ,s.[BrandID]
           ,S.[SupplierID]
           ,s.[Allowance]
           ,s.[UnitRetail]
           ,2
           ,s.[StartDate]
           ,s.[EndDate]);
		



  return
GO
