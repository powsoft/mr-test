USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Research_Sean879andSean889_20111222]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Research_Sean879andSean889_20111222]
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
GO
