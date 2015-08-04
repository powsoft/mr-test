USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Testing_SupplierSetupData_FullMerge_PepperidgeFarmReLoad]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Testing_SupplierSetupData_FullMerge_PepperidgeFarmReLoad]
as
--40562 Pepperidge Farm

select * into import.dbo.ProductPrices_20111206_Before_PepperidgeFarmReloadb from ProductPrices
select * into import.dbo.StoreSetup_20111206_Before_PepperidgeFarmReload from StoreSetup


select * from ProductPrices where SupplierID = 40562

	select *
	from SuppliersSetupData
	where datatruesupplierid = 40562

	select distinct storeid, datatrueSupplierid, Productid, DataTrueBanner, 
	Cost, Retail, Allowance, StartDate, Enddate
	from SuppliersSetupData
	where recordstatus = 0
	and isnumeric(storenumber) > 0
	and storeid <> 0	
	
select COUNT(*) from storesetup --3052963 before run

--Merge into storesetup
MERGE INTO [dbo].[StoreSetup] t

USING (select distinct 40393 as ChainID
	  ,StoreID
      ,ProductID
      ,cast(0 as int) as BrandID
      ,datatrueSupplierid as SupplieriD
      from SuppliersSetupData
      where storeid <> 0 and productid <> 0 and datatruesupplierid = 40562) S
      --where storeid <> 0 and productid <> 0 and datatruesupplierid <> 0) S
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

--***************DELETE Pepperidge Farm Only 40562******************************
select *
--delete
from ProductPrices where SupplierID = 40562
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
	where storeid <> 0 and productid <> 0 and datatruesupplierid = 40562) S
on t.ChainID = s.ChainID
and t.StoreID = s.StoreID 
and t.ProductID = s.ProductID
and t.BrandID = s.BrandID
and t.SupplierID = s.SupplierID
and t.ProductPriceTypeID = s.productpricetypeid

/*
WHEN MATCHED 
	Then update
			set t.UnitPrice = s.[UnitPrice]
			,t.UnitRetail = s.[UnitRetail]
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
		where storeid <> 0 and productid <> 0 and datatruesupplierid = 40562) S
on t.ChainID = s.ChainID
and t.StoreID = s.StoreID 
and t.ProductID = s.ProductID
and t.BrandID = s.BrandID
and t.SupplierID = s.SupplierID
and t.ProductPriceTypeID = s.productpricetypeid

/*
WHEN MATCHED 
	Then update
			set t.UnitPrice = s.[UnitPrice]
			,t.UnitRetail = s.[UnitRetail]
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
	where storeid <> 0 and productid <> 0 and datatruesupplierid = 40562
      and StartDate is not null and enddate is not null and allowance is not null) S
on t.ChainID = s.ChainID
and t.StoreID = s.StoreID 
and t.ProductID = s.ProductID
and t.BrandID = s.BrandID
and t.SupplierID = s.SupplierID
and t.ProductPriceTypeID = s.productpricetypeid
and cast(t.ActiveStartDate as date) = cast(s.startdate as date)
and cast(t.ActiveLastDate as date) = cast(s.enddate as date)

/*
WHEN MATCHED 
	Then update
			set t.UnitPrice = s.[Allowance]
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


--verify a sample
/*
store 6255 = 40528
upc 014100085973 = 5115

select * from stores where storeidentifier = '6255'
select * from productidentifiers where identifiervalue = '014100085973'

select * from productprices where storeid = 40528 and productid = 5115 and productpricetypeid = 8

*/
return
GO
