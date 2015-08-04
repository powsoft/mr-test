USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_PromotionsGilad]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_PromotionsGilad]
as

select * into #PromotionsGilad from PromotionsGilad

alter table #PromotionsGilad
add datatrueproductid int,
datatruebanner nvarchar(50)

select * from #PromotionsGilad

select distinct banner from #PromotionsGilad
select distinct datatruebanner from #PromotionsGilad

/*
Farm Fresh Markets
update #PromotionsGilad set datatruebanner = 'Farm Fresh Markets' where banner = 'Farm Fresh'
Albertsons - SCAL
update #PromotionsGilad set datatruebanner = 'Albertsons - SCAL' where banner = 'SCAL'
Shop N Save
update #PromotionsGilad set datatruebanner = 'Shop N Save Warehouse Foods Inc' where banner = 'Shop N Save'
select distinct custom1 from stores

*/
select * from #PromotionsGilad


select distinct ltrim(rtrim(c.UPC12Digit))
from #PromotionsGilad c
where ltrim(rtrim(c.UPC12Digit)) not in
(select ltrim(rtrim(IdentifierValue)) from ProductIdentifiers)



select c.*
--update c set c.datatrueproductid = i.productid
from #PromotionsGilad c
inner join ProductIdentifiers i
on ltrim(rtrim(c.UPC12Digit)) = ltrim(rtrim(i.IdentifierValue))

select * from #PromotionsGilad


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
	select distinct Supplierid, DataTrueProductid, DataTrueBanner, 
	Cost, Retail, Allowance, BeginDate, Enddate
	from #PromotionsGilad
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
