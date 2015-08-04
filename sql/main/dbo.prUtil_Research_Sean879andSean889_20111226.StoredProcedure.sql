USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Research_Sean879andSean889_20111226]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Research_Sean879andSean889_20111226]
as



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
  and GETDATE() between pp.ActiveStartDate and pp.ActiveLastDate
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
declare @perceivedpromo money

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
