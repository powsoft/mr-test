USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Promotions_Load_Nestle_20111208]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Promotions_Load_Nestle_20111208]
as

select * from import.dbo.NestlePromos20111208

drop table #distinctupc 
select distinct ltrim(rtrim(upc11)) as UPC into #distinctupc from import.dbo.NestlePromos20111208

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
	 
	 update import.dbo.NestlePromos20111208 set upc12 = @upc11 + @CheckDigit
	 where upc11 = @upc
	
		fetch next from @rec into @upc
--fetch next from @rec into @recordid, @upc
	end
	
close @rec
deallocate @rec

select *
--update c set c.dtproductid = i.productid
from import.dbo.NestlePromos20111208 c
inner join ProductIdentifiers i
on LTRIM(rtrim(upc12)) = LTRIM(rtrim(identifiervalue))

select *
--update c set c.dtbanner = i.costzonedescription
from import.dbo.NestlePromos20111208 c
inner join CostZones i
on LTRIM(rtrim(Groupcode)) = LTRIM(rtrim(CostZoneName))

select * from import.dbo.NestlePromos20111208 order by groupcode, dtproductid

select * from Suppliers where SupplierID = 40559
select * from datatrue_edi.dbo.EDI_SupplierCrossReference

select * from ProductPrices 
where SupplierID = 40559
and ProductPriceTypeID = 8
and ProductID in (select dtproductid from import.dbo.NestlePromos20111208)
--and cast(activestartdate as date) = '12/6/2011'
order by activestartdate

select * from import.dbo.NestlePromos20111208 order by groupcode, dtproductid
select *
from ProductPrices 
where 1 = 1
--ProductID = 5641
and ProductPriceTypeID = 8
--and storeid in (select storeid from stores where custom1 = 'Albertsons - SCAL')
order by activestartdate

declare @rec2 cursor
declare @productid int
declare @supplierid int=40559
declare @banner nvarchar(50)
declare @allowance money
declare @startdate date
declare @enddate date

set @rec2 = CURSOR local fast_forward FOR
select dtproductid, dtbanner, PromoAllowance, cast(PromoStartDate as date), cast(PromoEndDate as date)
from import.dbo.NestlePromos20111208 order by groupcode, dtproductid

open @rec2

fetch next from @rec2 into @productid, @banner, @allowance, @startDate, @enddate

while @@FETCH_STATUS = 0
	begin

/*	
		select *
		from ProductPrices p
		where 1 = 1
		and ProductID = @productid
		and ProductPriceTypeID = 8
		and storeid in (select storeid from stores where custom1 = @banner)
		and ActiveLastDate > '12/5/2011'
	
		if @@ROWCOUNT > 0
			begin	
				--select *
				update p set p.OldStartDate = p.ActiveStartDate, p.OldEndDate = p.ActiveLastDate
				,p.ActiveStartDate = Case when cast(p.ActiveStartDate AS date) <= @enddate and cast(p.ActiveLastDate AS date) > @enddate then DATEADD(day, 1,@enddate) else p.ActiveStartDate end
				,p.ActiveLastDate = Case when cast(p.ActiveLastDate AS date) >= @startdate and cast(p.ActiveLastDate AS date) <= @enddate then DATEADD(day, -1, @startdate) else p.ActiveLastDate end
				,p.NewActiveStartDateNeeded = Case when cast(p.ActiveStartDate AS date) < @startdate then p.ActiveStartDate else null end
				,p.NewActiveLastDateNeeded = Case when cast(p.ActiveStartDate AS date) < @startdate then DATEADD(day, -1, @startdate) else p.ActiveStartDate end
				from ProductPrices p
				where 1 = 1
				and ProductID = @productid
				and ProductPriceTypeID = 8
				and storeid in (select storeid from stores where custom1 = @banner)
				and ActiveLastDate > '12/5/2011'
				and p.NewActiveStartDateNeeded is null
				and p.NewActiveLastDateNeeded is null
			end

		
		if @@ROWCOUNT > 0
			begin
print @productid
print @banner			
			end
*/

MERGE INTO [dbo].[productprices] t
--		fetch next from @rec2 into @productid, @banner, @allowance, @startDate, @enddate
USING (select distinct 8 as productpricetypeid
		,40393 as ChainID
	  ,StoreID
      ,@productid as ProductID
      ,cast(0 as int) as BrandID
      ,40559 as SupplieriD
      ,@allowance as Allowance
      ,cast(0 as money) as UnitRetail
      ,@startDate as StartDate
      ,@enddate as EndDate
      from stores
	where ltrim(rtrim(custom1)) = ltrim(rtrim(@banner))) S
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




		fetch next from @rec2 into @productid, @banner, @allowance, @startDate, @enddate

	end
	
close @rec2
deallocate @rec2


select *
from ProductPrices
where SupplierID = 40559
and ProductPriceTypeID = 8
and ActiveStartDate = '12/6/2011'
--where Oldstartdate is not null
/*
(43 row(s) affected)
5017
Farm Fresh Markets

(43 row(s) affected)
5018
Farm Fresh Markets

(43 row(s) affected)
5605
Farm Fresh Markets

(43 row(s) affected)
5978
Farm Fresh Markets

(43 row(s) affected)
6006
Farm Fresh Markets

(43 row(s) affected)
6007
Farm Fresh Markets

(43 row(s) affected)
6020
Farm Fresh Markets

(43 row(s) affected)
6021
Farm Fresh Markets

(43 row(s) affected)
6022
Farm Fresh Markets

(43 row(s) affected)
6023
Farm Fresh Markets

(43 row(s) affected)
6024
Farm Fresh Markets
*/


return
GO
