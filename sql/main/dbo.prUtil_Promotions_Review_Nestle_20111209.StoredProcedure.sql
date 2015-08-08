USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Promotions_Review_Nestle_20111209]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Promotions_Review_Nestle_20111209]
as

/*
40559 is Nestle SupplierID
select * from import.dbo.NestlePromos20111208
select distinct custom1 from stores where custom1 is not null and len(custom1) > 0
select distinct dtbanner, groupcode from import.dbo.NestlePromos20111208
*/

declare @rec2 cursor
declare @productid int
declare @supplierid int=40559
declare @costzonecode nvarchar(50)
declare @allowance money
declare @startdate date
declare @enddate date
declare @banner nvarchar(50)

set @rec2 = CURSOR local fast_forward FOR
select ltrim(rtrim(dtbanner)), dtproductid, ltrim(rtrim(groupcode)), 
PromoAllowance, cast(PromoStartDate as date), cast(PromoEndDate as date)
from import.dbo.NestlePromos20111208 
where LTRIM(rtrim(GroupCode)) = '575'
order by ltrim(rtrim(groupcode)), dtproductid

open @rec2

fetch next from @rec2 into @banner, @productid, @costzonecode, @allowance, @startDate, @enddate

while @@FETCH_STATUS = 0
	begin

	
		select *
		from ProductPrices p
		where 1 = 1
		and ProductID = @productid
		and ProductPriceTypeID = 8
		and storeid in 
		/*
		(select distinct StoreID from stores where LTRIM(rtrim(custom1)) = @banner)
		*/
		--/*
		(select r.storeid from costzones z
		inner join costzonerelations r
		on z.CostZoneID = r.CostZoneID
		where ltrim(rtrim(costzonename)) = @costzonecode
		and z.SupplierId = @supplierid)
		--*/
		and ActiveStartDate = '12/6/2011'
		--and ActiveLastDate > '12/4/2011'
		order by ActivestartDate
		
		if @@ROWCOUNT < 1
			begin
				print @banner
				print @productid
				print @allowance
				print @startDate
				print @costzonecode
			end
/*	
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

*/


		fetch next from @rec2 into @banner, @productid, @costzonecode, @allowance, @startDate, @enddate

	end
	
close @rec2
deallocate @rec2


return
GO
