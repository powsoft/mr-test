USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Testing_SNS_Reload]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Testing_SNS_Reload]
as

--20 6211
--21 5742
--22 5912
--23 6215
--24 225
--25 4446
--26 5152
--0006017	072945761452	2011-11-26	2
select distinct saledate, filename from datatrue_edi.dbo.Inbound852Sales

select *
--update d set UnitCost = UnitCost + isnull(promoallowance, 0.00)
from InvoiceDetailS d
where 1 = 1
and PromoAllowance is not null
and Banner = 'SS'
order by PromoAllowance desc
--4826030	40393	41447	16921	41465	2	3	0	1	2.32	3.18	2011-11-26 00:00:00.000	072945761452		2.27	0.00	0.00	NULL	2.32	3.18	1	1	NULL	NULL	NULL	0	0	NULL	1657	NULL	NULL	2011-12-02 14:03:26.610	7420	2011-12-02 14:03:26.610	4395222	NULL	NULL	NULL	0006017	Shop N Save	NULL	UD	007294576145	SARA LEE COMPANY	0073223400000	NULL		EA        	0.00			Shop N Save	8008812780000                                     	SS        	NULL	NULL	6017
select * from StoreTransactions 
where 1 = 1
and StoreIdentifier = '0006017'
--and StoreID in (41000, 41001, 41002)
and Banner = 'SS'
and rawproductidentifier = '007294576145'
and SaleDateTime = 11/26/2011
order by PromoAllowance desc


select * from StoreTransactions_working
where 1 = 1
and saledatetime = '11/23/2011'
and Banner = 'SS'

select *
--update t set t.PromoAllowance = p.UnitPrice, t.PromoTypeID = P.ProductPriceTypeID
from [dbo].[StoreTransactions_Working] t
inner join [dbo].[ProductPrices] p
on t.ProductID = p.ProductID 
and t.BrandID = p.BrandID
and t.ChainID = p.ChainID 
and t.StoreID = p.StoreID 
and t.SupplierID = p.SupplierID 
where p.ProductPriceTypeID in 
(8, 9, 10) --2 is Chain Entity
and t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate
and t.WorkingStatus = 4

select *
from [dbo].[StoreTransactions_Working] t
inner join [dbo].[ProductPrices] p
on t.ProductID = p.ProductID 
and t.BrandID = p.BrandID
and t.ChainID = p.ChainID 
and t.StoreID = p.StoreID 
and t.SupplierID = p.SupplierID 
where p.ProductPriceTypeID in 
(3) --2 is Chain Entity
and t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate
and t.WorkingStatus = 4

select storeidentifier, upc, cast(SaleDateTime as date), COUNT(storetransactionid)
from StoreTransactions_Working
where banner = 'SS'
--and CAST(saledatetime as date) = '11/21/2011'
group by storeidentifier, upc, cast(SaleDateTime as date)
having COUNT(storetransactionid) > 1

select distinct workingstatus from StoreTransactions_Working

select *
--update w set workingstatus = -77
from StoreTransactions_Working w
where WorkingStatus = 4

select * into import.dbo.StoreTransactions_Working_20111202 from StoreTransactions_Working
delete from StoreTransactions_Working where Banner = 'SS'
select * into import.dbo.StoreTransactions_20111202 from StoreTransactions
delete from StoreTransactions where Banner = 'SS'
select * into import.dbo.invoicedetails_20111202 from InvoiceDetailS
select * into import.dbo.invoicesretailer_20111202 from invoicesretailer
select * into import.dbo.invoicessupplier_20111202 from invoicessupplier
delete from InvoiceDetailS
delete from InvoicesRetailer
delete from InvoicesSupplier

select * into import.dbo.invoicedetailsEDI_20111202 from datatrue_edi.dbo.InvoiceDetailS
select * into import.dbo.invoicesretailerEDI_20111202 from datatrue_edi.dbo.invoicesretailer
select * into import.dbo.invoicessupplierEDI_20111202 from datatrue_edi.dbo.invoicessupplier
delete from datatrue_edi.dbo.InvoiceDetailS
delete from datatrue_edi.dbo.InvoicesRetailer
delete from datatrue_edi.dbo.InvoicesSupplier

INSERT INTO [DataTrue_EDI].[dbo].[Inbound852Sales]
           ([ChainIdentifier]
           ,[StoreIdentifier]
           ,[StoreName]
           ,[ProductQualifier]
           ,[RawProductIdentifier]
           ,[ProductIdentifier]
           ,[BrandIdentifier]
           ,[ProductCategoryIdentifier]
           ,[SupplierIdentifier]
           ,[SupplierName]
           ,[DivisionIdentifier]
           ,[Saledate]
           ,[Qty]
           ,[UnitMeasure]
           ,[Cost]
           ,[SalePrice]
           ,[Retail]
           ,[PromotionPrice]
           ,[Allowance]
           ,[InvoiceNo]
           ,[PONo]
           ,[CorporateName]
           ,[CorporateIdentifier]
           ,[Banner]
           ,[FileName]
           ,[DateTimeReceived]
           ,[RecordStatus])
SELECT [ChainIdentifier]
      ,[StoreIdentifier]
      ,[StoreName]
      ,[ProductQualifier]
      ,[RawProductIdentifier]
      ,[ProductIdentifier]
      ,[BrandIdentifier]
      ,[ProductCategoryIdentifier]
      ,[SupplierIdentifier]
      ,[SupplierName]
      ,[DivisionIdentifier]
      ,[Saledate]
      ,[Qty]
      ,[UnitMeasure]
      ,[Cost]
      ,[SalePrice]
      ,[Retail]
      ,[PromotionPrice]
      ,[Allowance]
      ,[InvoiceNo]
      ,[PONo]
      ,[CorporateName]
      ,[CorporateIdentifier]
      ,[Banner]
      ,[FileName]
      ,[DateTimeReceived]
      ,0
  FROM [Import].[dbo].[Inbound852Sales_20111202_AtSVGoLive]
  where Banner = 'SS'
  and Saledate between '11/20/2011' and '11/26/2011'






return
GO
