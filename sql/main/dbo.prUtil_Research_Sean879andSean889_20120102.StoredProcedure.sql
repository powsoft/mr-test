USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Research_Sean879andSean889_20120102]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Research_Sean879andSean889_20120102]
as


--*****************************work on 20120101 and 20120102 start************************************************
--First Do Costs

select distinct Start,[End]
--select *
  FROM [DataTrue_Main].[dbo].[Sean-879-UpdateOurSystem]


select distinct StoreID, cast(0 as int) as productid, cast(0 as int) as supplierid, UPC12, Start, [End], [iC Setup Cost] as PerceivedCost, [Confirmed Base] as ConfirmedCost
--select *
into Import.dbo.tmpCostDiff20120102 
  FROM [DataTrue_Main].[dbo].[Sean-879-UpdateOurSystem]
  
  select *
  --update c set c.productid = i.productid
  from Import.dbo.tmpCostDiff20120102 c
  inner join productidentifiers i
  on ltrim(rtrim(c.upc12)) = ltrim(rtrim(i.identifiervalue))
  
  select *
  --update c set c.supplierid = t.supplierid
  from Import.dbo.tmpCostDiff20120102 c
  inner join
  (select distinct storeid, ProductId, supplierid
  from StoreTransactions where SaleDateTime > '11/29/2011') t
  on c.storeid = t.StoreID
  and c.productid = t.ProductID
  
  
  select *   from Import.dbo.tmpCostDiff20120102 c
  
  select *
  from ProductPrices pp

  where pp.ProductPriceTypeID = 3
and  productid = 5142
 and supplierid =	40562
  
  
SELECT [PerceivedCost], [Confirmedcost], pp.UnitPrice, pp.ActiveStartDate, pp.ActiveLastDate, s.*
  FROM Import.dbo.tmpCostDiff20120102 s
  inner join ProductPrices pp
  on s.StoreID = pp.StoreID
  and s.ProductID = pp.productid
  and s.supplierid = pp.supplierid
  where pp.ProductPriceTypeID = 3
  --and GETDATE() between pp.ActiveStartDate and pp.ActiveLastDate
  and [Confirmedcost] <> pp.UnitPrice  
  
 
 declare @reccostfix cursor
 declare @chainidcostfix int=40393
 declare @storeidcostfix int
 declare @productidcostfix int
 declare @brandidcostfix int=0
 declare @supplieridcostfix int
 declare @perceivedcost money
 declare @confirmedcostfix money
 declare @startdatecostfix date
 declare @enddatecostfix date
 declare @upc12costfix nvarchar(50)
 declare @bannercostfix nvarchar(50)
 declare @productdesc nvarchar(100)
 
 declare @mrrecordid int
 
 set @reccostfix = CURSOR local fast_forward FOR
 
 select s.StoreID, s.productid, s.supplierid, UPC12, Start, [end], ConfirmedCost, PerceivedCost
  FROM Import.dbo.tmpCostDiff20120102 s
  inner join ProductPrices pp
  on s.StoreID = pp.StoreID
  and s.ProductID = pp.productid
  and s.supplierid = pp.supplierid
  where pp.ProductPriceTypeID = 3
  and [Confirmedcost] <> pp.UnitPrice   
  
  open @reccostfix
  
  fetch next from @reccostfix into
		@storeidcostfix
		,@productidcostfix
		,@supplieridcostfix
		,@upc12costfix
		,@startdatecostfix
		,@enddatecostfix
		,@confirmedcostfix
		,@perceivedcost
		
while @@FETCH_STATUS = 0
	begin
	
		 select @bannercostfix = custom1
		 from stores where StoreID = @storeidcostfix
		 
		 select @productdesc = ltrim(rtrim(Description))
		 from Products where ProductID = @productidcostfix
		   
		 INSERT INTO [DataTrue_Main].[dbo].[MaintenanceRequests]
				   ([SubmitDateTime]
				   ,[RequestTypeID]
				   ,[ChainID]
				   ,[SupplierID]
				   ,[Banner]
				   ,[AllStores]
				   ,[UPC]
				   ,[ItemDescription]
				   ,[CurrentSetupCost]
				   ,[Cost]
				   ,[SuggestedRetail]
				   ,[StartDateTime]
				   ,[EndDateTime]
				   ,[SupplierLoginID]
				   ,[ChainLoginID]
				   ,[Approved]
				   ,[RequestStatus]
				   ,[productid]
				   ,[brandid]
				   ,[upc12]
				   ,[dtstorecontexttypeid])
				   values(GETDATE()
						,2
						,@chainidcostfix
						,@supplieridcostfix
						,@bannercostfix
						,0 --all stores
						,@upc12costfix
						,@productdesc
						,@perceivedcost
						,@confirmedcostfix
						,0.00 --suggretail
						,@startdatecostfix
						,@enddatecostfix
						,0
						,0
						,1
						,0 --[RequestStatus]
						,@productidcostfix
						,@brandidcostfix
						,@upc12costfix
						,1)
					
					
				set @mrrecordid = SCOPE_IDENTITY()
				
				--select top 10 * from maintenancerequeststores		
				
				insert into maintenancerequeststores
					(MaintenanceRequestID, StoreID, Included)
					values(@mrrecordid, @storeidcostfix, 1)
						

  
	
		  fetch next from @reccostfix into
				@storeidcostfix
				,@productidcostfix
				,@supplieridcostfix
				,@upc12costfix
				,@startdatecostfix
				,@enddatecostfix
				,@confirmedcostfix	
				,@perceivedcost
	end
	
close @reccostfix
deallocate @reccostfix
	
  
 
 --Next do promos
 
 --First Do Costs

select distinct [Confirmed start], [Confirmed End]
--select *
  FROM [DataTrue_Main].[dbo].[Sean-889UpdateOurRecords]


select distinct StoreID, cast(0 as int) as productid, cast(0 as int) as supplierid, UPC12, [Confirmed start] as start, [Confirmed End] as [end], [iC Setup _Promo] as PerceivedPromo, [Confirmed allow] as ConfirmedPromo
--select *
into Import.dbo.tmpPromoDiff20120102 
  FROM [DataTrue_Main].[dbo].[Sean-889UpdateOurRecords]
  
  select *
  --update c set c.productid = i.productid
  from Import.dbo.tmpPromoDiff20120102 c
  inner join productidentifiers i
  on ltrim(rtrim(c.upc12)) = ltrim(rtrim(i.identifiervalue))
  
  select *
  --update c set c.supplierid = t.supplierid
  from Import.dbo.tmpPromoDiff20120102 c
  inner join
  (select distinct storeid, ProductId, supplierid
  from StoreTransactions where SaleDateTime > '11/29/2011') t
  on c.storeid = t.StoreID
  and c.productid = t.ProductID
  
  
  select *   from Import.dbo.tmpPromoDiff20120102 c
  
  select *
  from ProductPrices pp

  where pp.ProductPriceTypeID = 3
and  productid = 5142
 and supplierid =	40562
  
  
SELECT [PerceivedPromo], [ConfirmedPromo], pp.UnitPrice, pp.ActiveStartDate, pp.ActiveLastDate, pp.DateTimeCreated, s.*
  FROM Import.dbo.tmpPromoDiff20120102 s
  inner join ProductPrices pp
  on s.StoreID = pp.StoreID
  and s.ProductID = pp.productid
  and s.supplierid = pp.supplierid
  where pp.ProductPriceTypeID = 8
  and pp.ActiveStartDate < '1/2/2012'
  order by pp.StoreID, pp.ProductID, pp.ActiveStartDate
  --and GETDATE() between pp.ActiveStartDate and pp.ActiveLastDate
  --and [ConfirmedPromo] <> pp.UnitPrice  
  
 --update correct records
 SELECT [PerceivedPromo], [ConfirmedPromo], pp.UnitPrice, pp.ActiveStartDate, pp.ActiveLastDate, s.*
 --select *
 --update s set s.recordstatus = 2
  FROM Import.dbo.tmpPromoDiff20120102 s
  inner join ProductPrices pp
  on s.StoreID = pp.StoreID
  and s.ProductID = pp.productid
  and s.supplierid = pp.supplierid
  where pp.ProductPriceTypeID = 8
    and pp.ActiveStartDate < '1/2/2012'
  and s.[ConfirmedPromo] = pp.UnitPrice
and cast(s.start as date) = cast(pp.ActiveStartDate as date)
and cast(s.[end] as date) = cast(pp.ActivelastDate as date)

 
 declare @recpromofix cursor
 declare @chainidpromofix int=40393
 declare @storeidpromofix int
 declare @productidpromofix int
 declare @brandidpromofix int=0
 declare @supplieridpromofix int
 declare @perceivedpromo money
 declare @confirmedpromofix money
 declare @startdatepromofix date
 declare @enddatepromofix date
 declare @upc12promofix nvarchar(50)
 declare @bannerpromofix nvarchar(50)
 declare @productdescpromofix nvarchar(100)
 declare @diffrecordid int
 declare @mrrecordidpromofix int
 
 set @recpromofix = CURSOR local fast_forward FOR
 
 select s.StoreID, s.productid, s.supplierid, UPC12, Start, [end], ConfirmedPromo, PerceivedPromo, s.recordid
  FROM Import.dbo.tmpPromoDiff20120102 s
  where recordstatus = 0
  /*
  inner join ProductPrices pp
  on s.StoreID = pp.StoreID
  and s.ProductID = pp.productid
  and s.supplierid = pp.supplierid
  where pp.ProductPriceTypeID = 8
  and [ConfirmedPromo] <> pp.UnitPrice 
  */  
  
  open @recpromofix
  
  fetch next from @recpromofix into
		@storeidpromofix
		,@productidpromofix
		,@supplieridpromofix
		,@upc12promofix
		,@startdatepromofix
		,@enddatepromofix
		,@confirmedpromofix
		,@perceivedpromo
		,@diffrecordid
		
while @@FETCH_STATUS = 0
	begin
	
		 select @bannerpromofix = custom1
		 from stores where StoreID = @storeidpromofix
		 
		 select @productdescpromofix = ltrim(rtrim(Description))
		 from Products where ProductID = @productidpromofix
		   
		 INSERT INTO [DataTrue_Main].[dbo].[MaintenanceRequests]
				   ([SubmitDateTime]
				   ,[RequestTypeID]
				   ,[ChainID]
				   ,[SupplierID]
				   ,[Banner]
				   ,[AllStores]
				   ,[UPC]
				   ,[ItemDescription]
				   ,[CurrentSetupCost]
				   ,[Cost]
				   ,[SuggestedRetail]
				   ,[StartDateTime]
				   ,[EndDateTime]
				   ,[SupplierLoginID]
				   ,[ChainLoginID]
				   ,[Approved]
				   ,[RequestStatus]
				   ,[productid]
				   ,[brandid]
				   ,[upc12]
				   ,[dtstorecontexttypeid])
				   values(GETDATE()
						,3
						,@chainidpromofix
						,@supplieridpromofix
						,@bannerpromofix
						,0 --all stores
						,@upc12promofix
						,@productdescpromofix
						,@perceivedpromo
						,@confirmedpromofix
						,0.00 --suggretail
						,@startdatepromofix
						,@enddatepromofix
						,0
						,0
						,1
						,0 --[RequestStatus]
						,@productidpromofix
						,@brandidpromofix
						,@upc12promofix
						,1)
					
					
				set @mrrecordidpromofix = SCOPE_IDENTITY()
				
				--select top 10 * from maintenancerequeststores		
				
				insert into maintenancerequeststores
					(MaintenanceRequestID, StoreID, Included)
					values(@mrrecordidpromofix, @storeidpromofix, 1)
						
			update Import.dbo.tmpPromoDiff20120102 set recordstatus = 1 where recordid = @diffrecordid
  
	
		  fetch next from @recpromofix into
				@storeidpromofix
				,@productidpromofix
				,@supplieridpromofix
				,@upc12promofix
				,@startdatepromofix
				,@enddatepromofix
				,@confirmedpromofix
				,@perceivedpromo
				,@diffrecordid
	end
	
close @recpromofix
deallocate @recpromofix
	
  
--*****************************work on 20120101 and 20120102 end************************************************


select * from dbo.[Sean-879-First Update]

/*
Promotions
Put custom1 in CorpIdentifier
Put custom3 in banner
*/

select p.SupplierID, * 
--update s set s.supplierid = p.supplierid
from dbo.[Sean-879-First Update] s
inner join
(select distinct storeid, supplierid, ProductId
from ProductPrices) p
on s.StoreID = p.StoreID
and s.productid = p.ProductID




select top 10 * from [DataTrue_EDI].[dbo].[Costs]
select top 10 * from dbo.[Sean-879-First Update]

INSERT INTO [DataTrue_EDI].[dbo].[Costs]
           ([PriceChangeCode]
           ,[AllStores]
           ,[Cost]
           ,[ProductIdentifier]
           ,[ProcessDate]
           ,[RecordStatus]
           ,[dtchainid]
           ,[dtstoreid]
           ,[dtproductid]
           ,[dtbrandid]
           ,[dtsupplierid]
           ,[dtbanner]
           ,[dtstorecontexttypeid]
           ,[Recordsource])
SELECT 'B'
		,0
      ,[Cost]
      ,[UPC12]
      ,GETDATE()
      ,9
      ,40393
      ,Storeid
      ,[productid]
      ,0 --brandid
      ,[supplierid]
      ,[Banner]
      ,1
      ,'MANUALSET'
      --select *
  FROM [DataTrue_Main].[dbo].[Sean-879-First Update]
  where Instructions = '879'
  
  

select top 10 * from [DataTrue_EDI].[dbo].[Costs]
select top 10 * from dbo.[Sean-879-First Update]

INSERT INTO [DataTrue_EDI].[dbo].[Promotions]
           ([DateStartPromotion]
           ,[DateEndPromotion]
           ,[Allowance_ChargeRate]
           ,[ProductIdentifier]
           ,[LoadStatus]
           ,[chainid]
           ,[storeid]
           ,[productid]
           ,[brandid]
           ,[supplierid]
           ,[banner]
           ,[dtstorecontexttypeid]
           ,[Recordsource])
SELECT [EffectiveDate]
		,[End Date]
      ,[Cost]
      ,[UPC12]
      ,9
      ,40393
      ,Storeid
      ,[productid]
      ,0 --brandid
      ,[supplierid]
      ,[Banner]
      ,1
      ,'MANUALSET'
      --select *
  FROM [DataTrue_Main].[dbo].[Sean-879-First Update]
  where Instructions = '889'
  
  






select *
--update s set s.productid = pi.productid
from dbo.[Sean-879-First Update] s
inner join ProductIdentifiers pi
on ltrim(rtrim(s.UPC12)) = ltrim(rtrim(pi.IdentifierValue))

select pp.UnitPrice, s.Cost, pp.ActiveStartDate, pp.ActiveLastDate, *
from dbo.[Sean-879-First Update] s
inner join ProductPrices pp
on s.StoreID = pp.StoreID
and s.productid = pp.ProductID
and GETDATE() between pp.ActiveStartDate and pp.ActiveLastDate
and pp.ProductPriceTypeID = 3
and s.Instructions = '879'
where s.Cost <> pp.UnitPrice
 

/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [iC Setup Cost], [Confirmed Base], pp.UnitPrice, pp.ActiveStartDate, pp.ActiveLastDate, s.*
  FROM [DataTrue_Main].[dbo].[Sean-879-UpdateOurSystem] s
  inner join productidentifiers i
  on ltrim(rtrim(s.UPC12)) = ltrim(rtrim(i.identifiervalue))
  inner join ProductPrices pp
  on s.StoreID = pp.StoreID
  and i.ProductID = pp.productid
  where pp.ProductPriceTypeID = 3
  --and GETDATE() between pp.ActiveStartDate and pp.ActiveLastDate
  and [Confirmed Base] <> pp.UnitPrice
  
  
  select * FROM [DataTrue_Main].[dbo].[Sean-879-UpdateOurSystem]
  
  drop table Import.dbo.tmpCostDiff20111222
  
  select StoreID, UPC12, cast(0 as int) as ProductId, 
  cast(0 as int) as supplierid, [iC Setup Cost] as PerceivedSetupCost,
  [Confirmed base], cast(0 as money) as ActualSetupCostNow,
  CAST('1/1/2000' as date) as ActiveStartDate,   CAST('1/1/2000' as date) as ActiveEndDate 
  into Import.dbo.tmpCostDiff20111222 
    FROM [DataTrue_Main].[dbo].[Sean-879-UpdateOurSystem]
    
    
select * from Import.dbo.tmpCostDiff20111222    
    
select *
--update d set d.productid = i.productid
from Import.dbo.tmpCostDiff20111222 d
inner join ProductIdentifiers i
on LTRIM(rtrim(upc12)) = LTRIM(rtrim(i.IdentifierValue))   

select *
from Import.dbo.tmpCostDiff20111222
where ProductId = 0    
   
select *
FROM [DataTrue_Main].[dbo].[Sean-879-UpdateOurSystem]
where upc12 = '#REF!'  

select * into import.dbo.productprices_20111223BeforeSeanCostUpdate from productprices

select UnitPrice, d.[Confirmed base], *
--update d set d.ActualsetupCostNow = p.UnitPrice, d.ActiveStartDate = p.ActiveStartDate, d.ActiveEndDate = p.ActiveLastDate
--update p set UnitPrice = cast(d.[Confirmed base] as decimal(12,2))
from Import.dbo.tmpCostDiff20111222 d
left outer join ProductPrices p
on d.StoreID = p.StoreID
and d.ProductId = p.productid
and p.ProductPriceTypeID = 3
and GETDATE() between p.ActiveStartDate and p.ActiveLastDate
where d.ProductId <> 0
and cast(p.UnitPrice as decimal(12,2)) <> cast([Confirmed base] as decimal(12,2))


  
select *
from ProductPrices p
inner join StoreTransactions t
on p.StoreID = t.StoreID
and p.ProductID = t.ProductID
and p.SupplierID = t.SupplierID
--where 
  
select *
from StoreTransactions t
where ReportedCost <> cast(SetupCost as decimal(12,2)) - PromoAllowance
and CAST(saledatetime as date) = '12/22/2011'


select * from dbo.[Sean-889UpdateOurRecords]
/*
  select StoreID, UPC12, cast(0 as int) as ProductId, 
  cast(0 as int) as supplierid, [iC Setup Cost] as PerceivedSetupCost,
  [Confirmed Allow], cast(0 as money) as ActualSetupCostNow,
  CAST('1/1/2000' as date) as ActiveStartDate,   CAST('1/1/2000' as date) as ActiveEndDate 
  into Import.dbo.tmpPromoDiff20111223 
    from dbo.[Sean-889UpdateOurRecords]
 */  
 select *
   into Import.dbo.tmpPromoDiff20111223 
    from dbo.[Sean-889UpdateOurRecords]
    
  select *
   from Import.dbo.tmpPromoDiff20111223    
 
   alter table Import.dbo.tmpPromoDiff20111223
   add productid int
   
select *
--update d set d.productid = i.productid
from Import.dbo.tmpPromoDiff20111223 d
inner join ProductIdentifiers i
on LTRIM(rtrim(upc12)) = LTRIM(rtrim(i.IdentifierValue))  

select * from Import.dbo.tmpPromoDiff20111223

declare @rec cursor
declare @productid int
declare @storeid int
declare @startdate date
declare @enddate date
declare @confirmedallow money
--declare @perceivedpromo money

set @rec = CURSOr local fast_forward FOR
select ProductId, storeid, [Confirmed start], [Confirmed end], [Confirmed allow], [iC Setup _Promo]
from Import.dbo.tmpPromoDiff20111223
where [Confirmed allow] = 0

open @rec

fetch next from @rec into 
	@productid
	,@storeid
	,@startdate
	,@enddate
	,@confirmedallow
	,@perceivedpromo

while @@FETCH_STATUS = 0
	begin
print 	@productid
print 	@storeid
print 	@startdate
print 	@enddate
print @confirmedallow
print @perceivedpromo

select @productid, @storeid, @startdate as startdate, @enddate as enddate, @confirmedallow as confirmed, @perceivedpromo as perceived

		select *
		from ProductPrices
		where StoreID = @storeid
		and ProductID = @productid
		and ProductPriceTypeID = 8
		order by ActiveLastDate	
	
		fetch next from @rec into 
			@productid
			,@storeid
			,@startdate
			,@enddate
			,@confirmedallow	
			,@perceivedpromo
	end

close @rec
deallocate @rec

update ProductPricesDeleted set datetimedeleted = '1/1/1900'

select *
from ProductPrices
where ProductPriceTypeID = 8
and ActiveLastDate > '2/1/2012'
order by ActiveLastDate

select distinct ActiveLastDate
from ProductPrices
where ProductPriceTypeID = 8
and ActiveLastDate > '2/1/2012'


						
						
							INSERT INTO [DataTrue_Main].[dbo].[ProductPricesDeleted]
									   ([ProductPriceID]
									   ,[ProductPriceTypeID]
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
									   ,[PriceReportedToRetailerDate]
									   ,[DateTimeCreated]
									   ,[LastUpdateUserID]
									   ,[DateTimeLastUpdate]
									   ,[BaseCost]
									   ,[Allowance]
									   ,[NewActiveStartDateNeeded]
									   ,[NewActiveLastDateNeeded]
									   ,[OldStartDate]
									   ,[OldEndDate]
									   ,[TradingPartnerPromotionIdentifier])

							SELECT [ProductPriceID]
								  ,[ProductPriceTypeID]
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
								  ,[PriceReportedToRetailerDate]
								  ,[DateTimeCreated]
								  ,[LastUpdateUserID]
								  ,[DateTimeLastUpdate]
								  ,[BaseCost]
								  ,[Allowance]
								  ,[NewActiveStartDateNeeded]
								  ,[NewActiveLastDateNeeded]
								  ,[OldStartDate]
								  ,[OldEndDate]
								  ,[TradingPartnerPromotionIdentifier]
							  FROM [DataTrue_Main].[dbo].[ProductPrices]
							  where cast(ActiveLastDate as date) in ('12/2/2012', '11/30/2012')
							  and ProductPriceTypeID = 8
							  
--delete FROM [DataTrue_Main].[dbo].[ProductPrices]  where cast(ActiveLastDate as date) in ('12/2/2012', '11/30/2012') and ProductPriceTypeID = 8

update [DataTrue_Main].[dbo].[ProductPricesDeleted] set ActualActionOnRecord = 'DELETED'



/*

declare @rec cursor
declare @productid int
declare @storeid int
declare @startdate date
declare @enddate date
declare @confirmedallow money
declare @perceivedpromo money
declare @recordid int
declare @productpriceid int
declare @supplierid int
declare @currentallowanceintable money
declare @rowcountnow int

set @rec = CURSOr local fast_forward FOR
select recordid, ProductId, storeid, cast([Confirmed start] as date), cast([Confirmed end] as date), [Confirmed allow], [iC Setup _Promo]
from Import.dbo.tmpPromoDiff20111223
where [Confirmed allow] <> 0

open @rec

fetch next from @rec into 
	@recordid
	,@productid
	,@storeid
	,@startdate
	,@enddate
	,@confirmedallow
	,@perceivedpromo

while @@FETCH_STATUS = 0
	begin
print 	@productid
print 	@storeid
print 	@startdate
print 	@enddate
print @confirmedallow
print @perceivedpromo

		if @confirmedallow = .33
			begin
			
				select @productid, @storeid, @startdate as startdate, @enddate as enddate, @confirmedallow as confirmed, @perceivedpromo as perceived
			
				select *
				from ProductPrices
				where StoreID = @storeid
				and ProductID = @productid
				--and cast(ActiveStartDate as date) = @startdate
				--and cast(ActiveStartDate as date) <= '11/30/2011'
				--and cast(ActiveLastDate as date) = @enddate
				and ProductPriceTypeID = 8
				order by ActiveLastDate	
				
				set @rowcountnow = @@rowcount

/*		
		if @rowcountnow = 1
			begin
				select @productpriceid = productpriceid, @currentallowanceintable = UnitPrice
				from ProductPrices
				where StoreID = @storeid
				and ProductID = @productid
				and ActiveStartDate = @startdate
				--and ActiveLastDate = @enddate
				and ProductPriceTypeID = 8	
				
				if 	@@rowcount > 0 and @currentallowanceintable <> @confirmedallow
					begin
					
							INSERT INTO [DataTrue_Main].[dbo].[ProductPricesDeleted]
									   ([ProductPriceID]
									   ,[ProductPriceTypeID]
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
									   ,[PriceReportedToRetailerDate]
									   ,[DateTimeCreated]
									   ,[LastUpdateUserID]
									   ,[DateTimeLastUpdate]
									   ,[BaseCost]
									   ,[Allowance]
									   ,[NewActiveStartDateNeeded]
									   ,[NewActiveLastDateNeeded]
									   ,[OldStartDate]
									   ,[OldEndDate]
									   ,[TradingPartnerPromotionIdentifier]
									   ,ActualActionOnRecord)

							SELECT [ProductPriceID]
								  ,[ProductPriceTypeID]
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
								  ,[PriceReportedToRetailerDate]
								  ,[DateTimeCreated]
								  ,[LastUpdateUserID]
								  ,[DateTimeLastUpdate]
								  ,[BaseCost]
								  ,[Allowance]
								  ,[NewActiveStartDateNeeded]
								  ,[NewActiveLastDateNeeded]
								  ,[OldStartDate]
								  ,[OldEndDate]
								  ,[TradingPartnerPromotionIdentifier]
								  ,'UPDATED'
							  FROM [DataTrue_Main].[dbo].[ProductPrices]
							  where productpriceid = @productpriceid
							  and ProductPriceTypeID = 8					
					
								update p set p.UnitPrice = @confirmedallow, p.ActiveStartDate = @startdate, p.ActiveLastDate = @enddate
								FROM [DataTrue_Main].[dbo].[ProductPrices] p
							  where p.productpriceid = @productpriceid
							  
							  update Import.dbo.tmpPromoDiff20111223 set recordstatus = 1 where recordid = @recordid   
				
					
					end	
			
			end
*/
/*			
		if @rowcountnow = 0
			begin
			
			select @supplierid = max(supplierid) from storetransactions
			where storeid = @storeid and productid = @productid and saledatetime > '11/30/2011'
			
			if @@rowcount > 0
				begin
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
				   values(8
				   ,@productid
				   ,40393
				   ,@storeid
				   ,0
				   ,@supplierid
				   ,@confirmedallow
				   ,0.00
				   ,@startdate
				   ,@enddate
				   ,0)
				   
					update Import.dbo.tmpPromoDiff20111223 set recordstatus = 1 where recordid = @recordid   
				 
				end

			end
*/	
end

		fetch next from @rec into 
			@recordid
			,@productid
			,@storeid
			,@startdate
			,@enddate
			,@confirmedallow	
			,@perceivedpromo
	end

close @rec
deallocate @rec


*/
GO
