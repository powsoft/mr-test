USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_MaintenanceRequest_Promo_Load_ByStore_20111216]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_MaintenanceRequest_Promo_Load_ByStore_20111216]
as
/*
--26604 @productidentifier = 824325771595
select top 10 * from MaintenanceRequests where maintenancerequestid = 13
select StoreID from stores where LTRIM(rtrim(custom1)) = 'Albertsons - ACME'
select * into import.dbo.productprices_20111211_Before_MoreMaintenanceRequestPromoAdds from productprices
select * from stores where custom2 = '55576'

40543 select * from costzonerelations where costzoneid = 1774
*/


declare @rec cursor
declare @requesttypeid smallint
declare @chainid int
declare @supplierid int
declare @banner nvarchar(50)
declare @allstores smallint
declare @upc nvarchar(50)
declare @brandidentifier nvarchar(50)
declare @itemdescription nvarchar(255)
declare @currentsetupcosts money
declare @requestedcost money
declare @suggestedretail money
declare @promotypeid smallint
declare @promoallowance money
declare @startdate datetime
declare @enddate datetime
declare @approved smallint
declare @denialreason nvarchar(500)
declare @costzoneid int
declare @productid int
declare @productidfound bit=1
declare @applyupdate bit=1
declare @addcheckdigit bit=1
declare @maintenancerequestid int
declare @checkdigit char(1)
declare @storeid int

 set @rec = CURSOR local fast_forward FOr
 
 SELECT r.maintenancerequestid
		,[RequestTypeID]
      ,[ChainID]
      ,[SupplierID]
      ,ltrim(rtrim([Banner]))
      ,[AllStores]
      ,ltrim(rtrim([UPC]))
      ,[BrandIdentifier]
      ,[ItemDescription]
      ,[CurrentSetupCost]
      ,[Cost]
      ,isnull([SuggestedRetail], 0.00)
      ,[PromoTypeID]
      ,case when [PromoAllowance] <  0 then [PromoAllowance] * -1 else [PromoAllowance] end
      ,[StartDateTime]
      ,[EndDateTime]
      ,[CostZoneID]
      ,[ProductID]
      ,[StoreID]
  FROM [DataTrue_Main].[dbo].[MaintenanceRequests] r
  inner join dbo.MaintenanceRequestStores s
  on r.MaintenanceRequestID = s.MaintenanceRequestID
	where RequestStatus = 0 --not in (5, -17)
	and RequestTypeID = 3 and AllStores = 0
	and ProductId is not null
	and SupplierID = 41465
	order by MaintenanceRequestID

open @rec

fetch next from @rec into
	@maintenancerequestid
	,@requesttypeid
	, @chainid
	, @supplierid
	, @banner
	, @allstores
	, @upc
	, @brandidentifier
	, @itemdescription
	, @currentsetupcosts
	, @requestedcost
	, @suggestedretail
	, @promotypeid
	, @promoallowance
	, @startdate
	, @enddate
	, @costzoneid
	,@productid
	,@storeid

while @@FETCH_STATUS = 0
	begin
/*
		set @checkdigit = ''
		
		exec [dbo].[prUtil_UPC_GetCheckDigit]
		@UPC,
		@CheckDigit OUT
		
		set @upc = @upc + @checkdigit

		set @productidfound = 0
		set @productid = 0				   
			
		select @productid = productid
		from ProductIdentifiers
		where LTRIM(rtrim(identifiervalue)) = @upc
		
		if @@ROWCOUNT > 0
			begin
				set @productidfound = 1
			end
*/
print 'ID:' + cast(@maintenancerequestid as nvarchar)	
		if @productid <> 0
			begin	
				SELECT  * from ProductPrices 
				where SupplierID = @supplierid
				and ProductID = @productid
				and StoreID = @storeid
				and ProductPriceTypeID = 8
				and ActiveLastDate >= @startdate
				--and StoreID in 
				--(select storeid from costzones z inner join costzonerelations r on z.costzoneid = r.costzoneid where z.costzoneid = @costzoneid)
			end
		--else
		--	begin
		--		update MaintenanceRequests set RequestStatus = -17 where MaintenanceRequestID = @maintenancerequestid
				-- -17 means product not found
		--	end
		/*
		(
		select StoreID from stores where LTRIM(rtrim(custom1)) = @banner
		)
		*/
--*********************************************************************************************************		
--select top 5 * from costzones select * from costzonerelations
--select storeid from costzones z inner join costzonerelations r on z.costzoneid = r.costzoneid where costzoneid = @costzoneid
--*********************************************************************************************************	
	if @productidfound = 1 and @applyupdate = 1
		begin
			--Merge into storesetup
			MERGE INTO [dbo].[StoreSetup] t

			USING (select distinct 40393 as ChainID
				  ,@storeid as StoreID
				  ,@productid as ProductID
				  ,cast(0 as int) as BrandID
				  ,@supplierid as SupplieriD) S
				  --from stores
				  --where storeid  in 
				--	((select storeid from costzones z inner join costzonerelations r on z.costzoneid = r.costzoneid where z.costzoneid = @costzoneid))) S
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
/*
		update p set  OldEndDate = ActiveLastDate, ActiveLastDate = CAST(dateadd(day, -1, @startdate) as date)
		from ProductPrices p
		where SupplierID = @supplierid
		and ProductID = @productid
		and ProductPriceTypeID = 8
		and StoreID in 
		(select storeid from costzones z inner join costzonerelations r on z.costzoneid = r.costzoneid where z.costzonename = cast(@costzoneid as nvarchar))
*/

			MERGE INTO [dbo].[productprices] t

			USING (select distinct 8 as ProductPriceTypeID
				  ,40393 as ChainID
				  ,@storeid as StoreID
				  ,@productid as ProductID
				  ,cast(0 as int) as BrandID
				  ,@supplierid as SupplieriD) S
				  --from stores
				  --where storeid  in 
					--(select storeid from costzones z inner join costzonerelations r on z.costzoneid = r.costzoneid where z.costzoneid = @costzoneid)) S
			on t.ChainID = s.ChainID
			and t.StoreID = s.StoreID 
			and t.ProductID = s.ProductID
			and t.BrandID = s.BrandID
			and t.SupplierID = s.SupplierID
			and t.ProductPriceTypeID = s.productpricetypeid
			and t.ActiveStartDate = @startdate

			/*
			WHEN MATCHED 
				Then update
						set t.UnitPrice = @promoallowance
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
					   ,@promoallowance
					   ,@suggestedretail
					   ,2
					   ,@startdate
					   ,@enddate);
					   
					   
		if @productid <> 0
			begin			   
				SELECT  * from ProductPrices 
				where SupplierID = @supplierid
				and ProductID = @productid
				and StoreID = @storeid
				and ProductPriceTypeID = 8
				and ActiveLastDate >= @startdate
				--and StoreID in 
				--(select storeid from costzones z inner join costzonerelations r on z.costzoneid = r.costzoneid where z.costzoneid = @costzoneid)
			end	   
					   
				update MaintenanceRequests set RequestStatus = 5 where MaintenanceRequestID = @maintenancerequestid
		end
--*********************************************************************************************************	
--*********************************************************************************************************	
		fetch next from @rec into
			@maintenancerequestid
			,@requesttypeid
			, @chainid
			, @supplierid
			, @banner
			, @allstores
			, @upc
			, @brandidentifier
			, @itemdescription
			, @currentsetupcosts
			, @requestedcost
			, @suggestedretail
			, @promotypeid
			, @promoallowance
			, @startdate
			, @enddate
			, @costzoneid	
			,@productid
			,@storeid
	end
	
close @rec
deallocate @rec
 
 

/*

declare @upc11 nvarchar(50)= '02560000740'
declare @checkdigit char(1)
declare @productid int
exec [dbo].[prUtil_UPC_GetCheckDigit]
	 @UPC11,
	 @CheckDigit OUT
print @CheckDigit
select @productid = productid
from productidentifiers
where identifiervalue = @upc11 + @CheckDigit
print @productid


027100004776 = upc 15347 = productid
Cub Foods = banner
1.95 = newcost 2.06 = oldcost 2.79 = retail
2011-12-08 00:00:00.000 = startdate
40558 = supplierid

select * from productidentifiers where identifiervalue = '824325771595' --027100004776'

select * from storesetup where productid = 26605
select * from productprices where productid = 26605

cost 3.22 retail 5.50

select * 
--UPdate p set ActiveLastDate = '12/7/2011'
from productprices p
where productid = 15347
and supplierid = 40558
and productpricetypeid = 3
and storeid in
(
select storeid
from stores
where ltrim(rtrim(custom1)) = 'Cub Foods'
)

INSERT INTO [DataTrue_Main].[dbo].[ProductPrices]
           ([ProductPriceTypeID]
           ,[ProductID]
           ,[ChainID]
           ,[StoreID]
           ,[BrandID]
           ,[SupplierID]
           ,[UnitPrice]
           ,[UnitRetail]
           ,[ActiveStartDate]
           ,[ActiveLastDate]
           ,[LastUpdateUserID])
       select 3
       ,26605
       ,40393
       ,[StoreID]
       ,0
       ,40558
       ,3.22
       ,5.50
       ,'12/8/2011'
       ,'12/31/2025'
       ,2    
from stores
where ltrim(rtrim(custom1)) = 'Cub Foods'

select * from storesetup where productid = 26605
INSERT INTO [DataTrue_Main].[dbo].[StoreSetup]
           ([ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[SupplierID]
           ,[BrandID]
           ,[InventoryCostMethod]
           ,[ActiveStartDate]
           ,[ActiveLastDate]
           ,[LastUpdateUserID])
       select 40393
       ,[StoreID]
       ,26605
       ,40558
       ,0
       ,'FIFO'
       ,'12/8/2011'
       ,'12/31/2025'
       ,2    
from stores
where ltrim(rtrim(custom1)) = 'Cub Foods'



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
*/

return
GO
