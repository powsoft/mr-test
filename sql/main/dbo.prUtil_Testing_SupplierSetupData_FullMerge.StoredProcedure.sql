USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Testing_SupplierSetupData_FullMerge]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Testing_SupplierSetupData_FullMerge]
as

	select distinct storeid, datatrueSupplierid, Productid, DataTrueBanner, 
	Cost, Retail, Allowance, StartDate, Enddate
	from SuppliersSetupData
	where recordstatus = 0
	and isnumeric(storenumber) > 0
	and storeid <> 0	
	
select * into Import.dbo.storesetup_20111203b_BeforeSupplierSetupDataFullMerge from storesetup


--Merge into storesetup
MERGE INTO [dbo].[StoreSetup] t

USING (select distinct 40393 as ChainID
	  ,StoreID
      ,ProductID
      ,cast(0 as int) as BrandID
      ,datatrueSupplierid as SupplieriD
      from SuppliersSetupData
      where storeid <> 0 and productid <> 0 and datatruesupplierid <> 0) S
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

select top 281686 * from storesetup order by DateTimeCreated  desc, StoreID, ProductID, supplierid

select * from storesetup where StoreID = 0 order by storesetupid

select * 
--delete
from storesetup 
where StoreID = 0 
and storesetupid not in (50834,50838, 50839, 50840)
and CAST(datetimecreated as date) = '12/3/2011'


select * 
--delete
from storesetup 
where productID = 0 
and storesetupid not in (50834,50838, 50839, 50840)
and CAST(datetimecreated as date) = '12/3/2011'

select * 
--delete
from storesetup 
where supplierID = 0 
and storesetupid not in (50834,50838, 50839, 50840)
and CAST(datetimecreated as date) = '12/3/2011'

--product price
select * from stores 
where chainid = 40393
and cast(LTRIM(rtrim(storeidentifier)) as int) in
(
select distinct cast(LTRIM(rtrim(storenumber)) as int)
      from SuppliersSetupData
      where storeid = 0
)
select * from stores 
where chainid = 40393
and cast(LTRIM(rtrim(custom2)) as int) in
(
select distinct cast(LTRIM(rtrim(storenumber)) as int)
      from SuppliersSetupData
      where storeid = 0
)
/*
198 205 321 674 
*/
select distinct storenumber
      from SuppliersSetupData
      where storeid = 0 or productid = 0 or datatruesupplierid = 0
      and Allowance is null
--/*
select * into Import.dbo.productprices_20111203BeforeSupplierSetupDataAndSNSData from productprices
select top 1000 * from SuppliersSetupData
--Merge into productprices type 3
MERGE INTO [dbo].[productprices] t

USING (select distinct 3 as productpricetypeid
		,40393 as ChainID
	  ,StoreID
      ,ProductID
      ,cast(0 as int) as BrandID
      ,datatrueSupplierid as SupplieriD
      ,Cost as UnitPrice
      ,Allowance as Allowance
      ,isnull(Retail, 0) as UnitRetail
      ,StartDate
      ,EndDate
      from SuppliersSetupData
      where storeid <> 0 and productid <> 0 and datatruesupplierid <> 0) S
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

USING (select distinct 5 as productpricetypeid
		,40393 as ChainID
	  ,StoreID
      ,ProductID
      ,cast(0 as int) as BrandID
      ,datatrueSupplierid as SupplieriD
      ,Cost as UnitPrice
      ,Allowance as Allowance
      ,isnull(Retail, 0) as UnitRetail
      ,StartDate
      ,EndDate
      from SuppliersSetupData
      where storeid <> 0 and productid <> 0 and datatruesupplierid <> 0) S
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

          

MERGE INTO [dbo].[productprices] t

USING (select distinct 8 as productpricetypeid
		,40393 as ChainID
	  ,StoreID
      ,ProductID
      ,cast(0 as int) as BrandID
      ,datatrueSupplierid as SupplieriD
      ,Cost as UnitPrice
      ,Allowance as Allowance
      ,isnull(Retail, 0) as UnitRetail
      ,StartDate
      ,EndDate
      from SuppliersSetupData
      where storeid <> 0 and productid <> 0 and datatruesupplierid <> 0
      and StartDate is not null and enddate is not null and allowance is not null) S
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
		

--*/

return
GO
