USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_PromotionsGiladNestle]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_PromotionsGiladNestle]
as

--drop table #PromotionsGiladNestle
select * into #PromotionsGiladNestle from PromotionsGiladNestle

alter table #PromotionsGiladNestle
add datatrueproductid int,
datatruebanner nvarchar(50)

select * from #PromotionsGiladNestle

update #PromotionsGiladNestle set datatruebanner = banner

select distinct banner from #PromotionsGiladNestle
select distinct datatruebanner from #PromotionsGiladNestle


select * from #PromotionsGiladNestle


select distinct ltrim(rtrim(c.[12DigitUPC]))
from #PromotionsGiladNestle c
where ltrim(rtrim(c.[12DigitUPC])) not in
(select ltrim(rtrim(IdentifierValue)) from ProductIdentifiers)



select c.*
--update c set c.datatrueproductid = i.productid
from #PromotionsGiladNestle c
inner join ProductIdentifiers i
on ltrim(rtrim(c.[12DigitUPC])) = ltrim(rtrim(i.IdentifierValue))

select * from #PromotionsGiladNestle


declare @rec cursor
declare @supplierid int
declare @productid int
declare @banner nvarchar(255)
declare @cost money
declare @retail money
declare @allowance money
declare @startdate date
declare @enddate date

set @rec = CURSOR local fast_forward FOR
	select distinct 40559, DataTrueProductid, DataTrueBanner, 
	Cost, RetailPrice, Allowance, BeginDate, Enddate
	from #PromotionsGiladNestle
	where Cost is not null
	
open @rec

fetch next from @rec into 
	@supplierid
	,@productid
	,@banner
	,@cost
	,@retail
	,@allowance
	,@startdate
	,@enddate
	
while @@FETCH_STATUS = 0
	begin
	

--Merge into storesetup
MERGE INTO [dbo].[StoreSetup] t

USING (select distinct ChainID
	  ,[StoreID] as StoreID
      ,@productid as ProductID
      ,cast(0 as int) as BrandID
      ,@supplierid as SupplierID

from Stores
where ltrim(rtrim(Custom1)) = ltrim(rtrim(@banner))) S
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

--product price

--Merge into productprices type 3
MERGE INTO [dbo].[productprices] t

USING (select distinct 3 as productpricetypeid
		,ChainID
	  ,[StoreID] as StoreID
      ,@productid as ProductID
      ,cast(0 as int) as BrandID
      ,@supplierid as SupplierID
      ,@cost as UnitPrice
      ,@retail as UnitRetail

from Stores
where ltrim(rtrim(Custom1)) = ltrim(rtrim(@banner))) S
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
		,ChainID
	  ,[StoreID] as StoreID
      ,@productid as ProductID
      ,cast(0 as int) as BrandID
      ,@supplierid as SupplierID
      ,@cost as UnitPrice
      ,@retail as UnitRetail

from Stores
where ltrim(rtrim(Custom1)) = ltrim(rtrim(@banner))) S
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
	
     if @startdate is not null and @enddate is not null and @allowance > 0
		begin
		 --Add Promotion Price
		 --select top 1000 * from productprices where productpricetypeid = 8 order by datetimecreated desc
			--Merge into productprices type 8
			MERGE INTO [dbo].[productprices] t

			USING (select distinct 5 as productpricetypeid
		,ChainID
	  ,[StoreID] as StoreID
      ,@productid as ProductID
      ,cast(0 as int) as BrandID
      ,@supplierid as SupplierID
      ,@cost as UnitPrice
      ,@allowance as Allowance
      ,@retail as UnitRetail
      ,@startdate as StartDate
      ,@enddate as EndDate

from Stores
where ltrim(rtrim(Custom1)) = ltrim(rtrim(@banner))) S
on t.ChainID = s.ChainID
and t.StoreID = s.StoreID 
and t.ProductID = s.ProductID
and t.BrandID = s.BrandID
and t.SupplierID = s.SupplierID
and t.ProductPriceTypeID = s.productpricetypeid
			and cast(t.ActiveStartDate as date) = cast(s.StartDate as date)
			and cast(t.ActiveLastDate as date) = cast(s.EndDate as date)

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
					   ,[ActiveStartDate]
					   ,[ActiveLastDate]
					   ,[LastUpdateUserID])
				 VALUES
					(s.productpricetypeid
					,S.[ChainID] 
						,S.[StoreID]
					   ,S.[ProductID]
					   ,s.[BrandID]
					   ,S.[SupplierID]
					   ,s.[Allowance]
					   ,0
					   ,s.StartDate
					   ,s.EndDate
					   ,2);
		
		end
		
	
	
	
		fetch next from @rec into 
			@supplierid
			,@productid
			,@banner
			,@cost
			,@retail
			,@allowance
			,@startdate
			,@enddate
	end
	
close @rec
deallocate @rec

return
GO
