USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Pricing_MissingPricing_Report]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Pricing_MissingPricing_Report]
as

--drop table #currentpricinginstalled

select distinct
	chainid
	,storeid
	,productid
	,brandid
	,supplierid
	,cast('ProductPrices' as nvarchar(50)) as ContextSource
into #currentpricinginstalled
from ProductPrices
where ProductPriceTypeID = 3
and ChainID = 40393
order by ChainID, StoreID, ProductID, BrandID, supplierid

MERGE INTO [dbo].[#currentpricinginstalled] t

USING (select distinct [ChainID]
	  ,[StoreID]
      ,[ProductID]
      ,[BrandID]
      ,[SupplierID]
from [dbo].[StoreTransactions] w
where transactiontypeid in (2,6,16)
and cast(w.SaleDateTime as date) >= '12/1/2011') S
on t.chainid = s.chainid
and t.StoreID = s.StoreID 
and t.ProductID = s.ProductID
and t.BrandID = s.BrandID
and t.supplierid = s.supplierid



WHEN NOT MATCHED 

        THEN INSERT
           ([ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[BrandID]
           ,[SupplierID]
           ,ContextSource)
     VALUES
     (S.[ChainID], S.[StoreID]
           ,S.[ProductID]
           ,S.[BrandID]
           ,S.[SupplierID]
           ,'StoreTransOnly');

select s.StoreName, s.storeidentifier as StoreNumber, 
s.Custom2 as SBTNumber,  sp.SupplierName, p.*, pr.Description as ProductDescription, pi.Identifiervalue as UPC
from #currentpricinginstalled p
inner join Products pr
on p.ProductID = pr.ProductID
inner join ProductIdentifiers pi
on pr.ProductID = pi.ProductID
inner join stores s
on p.StoreID = s.StoreID
inner join Suppliers sp
on p.SupplierID = sp.SupplierID
where ContextSource = 'StoreTransOnly'
order by ProductID, StoreID, supplierid

/*
select distinct [ChainID]
	  ,[StoreID]
      ,[ProductID]
      ,[BrandID]
      ,[SupplierID]
from [dbo].[StoreTransactions]
where SetupCost is null
and TransactionTypeID in (2,6,16)
and ChainID = 40393
and cast(SaleDateTime as date) >= '12/1/2011'
*/

return
GO
