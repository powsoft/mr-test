USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prForward_VirtualPickups_Append]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prForward_VirtualPickups_Append]
as

declare @maxdate date
declare @appenddate date
declare @weekdaynumber tinyint --1 = Sunday 7 = Saturday
declare @myid int=-1

/*
 select * from #tempNewspaperProducts t inner join products p on t.productid = p.productid 
 select * from #tempNewspaperProducts t inner join storesetup p on t.productid = p.productid 
 drop table #tempNewspaperProducts)
 
 select * from Storetransactions_Forward
*/


--select ProductId
--into #tempNewspaperProducts 
--from ProductCategoryAssignments a
--inner join ProductCategories c
--on a.ProductCategoryID = c.ProductCategoryID
--and LEFT(cast(HierarchyID as nvarchar),4)  IN (select LEFT(cast(HierarchyID as nvarchar),4) from ProductCategories where ProductCategoryName = 'NEWSPAPERS')
--and ProductID = 37

-------------------------REMOVE THIS NEXT TEMP TABLE--------------------------------------------
select StoreSetupID
into #tempstoresetup
from storesetup
where ChainID = 62362
and IncludeInForwardTransactions = 1
--and ProductID in
--(select distinct ProductID from ProductCategoryAssignments where ProductCategoryID in (5, 79, 1371))
--and (SunLimitQty <> 0 or MonLimitQty <> 0 or TueLimitQty <> 0)
--and SupplierID <> 41440


select @maxdate = MAX(cast(saledatetime as DATE))
--select MAX(cast(saledatetime as DATE))
from Storetransactions_Forward
where Transactiontypeid = 29 --expected deliveries

set @appenddate = DATEADD(day, 1, isnull(@maxdate,'8/11/2013'))

set @weekdaynumber = Datepart(weekday, @appenddate)

--declare @appenddate date='10/7/2012' declare @myid int= 0
INSERT INTO [DataTrue_Main].[dbo].[StoreTransactions_Forward]
           ([ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[SupplierID]
           ,[BrandID]
           ,[TransactionTypeID]
           ,[Qty]
           ,[SetupCost]
           ,[SetupRetail]
           ,[SaleDateTime]
           ,[UPC]
           ,[LastUpdateUserID]
           ,[SourceID]
           ,[DateTimeCreated]
           ,[DateTimeLastUpdate]
           ,[TransactionStatus])
           --declare @appenddate date='10/7/2012' declare @myid int= 0
SELECT s.[ChainID]
      ,s.[StoreID]
      ,s.[ProductID]
      ,s.[SupplierID]
      ,s.[BrandID]
      ,29 --ExpectedDeliviers
      ,case when @weekdaynumber = 1 then isnull([SunLimitQty], 0)
			when @weekdaynumber = 2 then isnull([MonLimitQty], 0)
			when @weekdaynumber = 3 then isnull([TueLimitQty], 0)
			when @weekdaynumber = 4 then isnull([WedLimitQty], 0)
			when @weekdaynumber = 5 then isnull([ThuLimitQty], 0)
			when @weekdaynumber = 6 then isnull([FriLimitQty], 0)
			when @weekdaynumber = 7 then isnull([SatLimitQty], 0)
		end
	  ,null --[UnitPrice]
	  ,null --[UnitRetail]
	  ,@appenddate
	  ,'' --i.IdentifierValue
	  ,@myid
	  ,0 --sourceid
	  ,GETDATE()
	  ,GETDATE()
	  ,0 --status
  FROM  #tempstoresetup t
  inner join [DataTrue_Main].[dbo].[StoreSetup] s
  on t.StoreSetupID = s.StoreSetupID
  --inner join [DataTrue_Main].[dbo].[ProductPrices] p 
  --on s.storeid = p.storeid
  --and s.ProductID = p.ProductID
  --and s.BrandID = p.BrandID
  --and @appenddate between p.ActiveStartDate and p.ActiveLastDate
  and s.IncludeInForwardTransactions = 1
  --and p.ProductPriceTypeID = 3
  ----inner join [DataTrue_Main].[dbo].[ProductIdentifiers] i
  ----on s.ProductID = i.ProductID
  ----and i.ProductIdentifierTypeID = 8 --UPC
  ----inner join  #tempNewspaperProducts t 
  ----on i.productid = t.productid 


--INSERT INTO [DataTrue_Main].[dbo].[StoreTransactions_Forward]
--           ([ChainID]
--           ,[StoreID]
--           ,[ProductID]
--           ,[SupplierID]
--           ,[BrandID]
--           ,[TransactionTypeID]
--           ,[Qty]
--           ,[SetupCost]
--           ,[SetupRetail]
--           ,[SaleDateTime]
--           ,[UPC]
--           ,[LastUpdateUserID])
--           --declare @appenddate date='10/7/2012' declare @myid int= 0
--SELECT s.[ChainID]
--      ,s.[StoreID]
--      ,s.[ProductID]
--      ,s.[SupplierID]
--      ,s.[BrandID]
--      ,30 --Virtual Pickups
--      ,0 --Qty
--	  ,[UnitPrice]
--	  ,[UnitRetail]
--	  ,@appenddate
--	  ,i.IdentifierValue
--	  ,@myid
--  FROM  #tempstoresetup t
--  inner join [DataTrue_Main].[dbo].[StoreSetup] s
--  on t.StoreSetupID = s.StoreSetupID
--  inner join [DataTrue_Main].[dbo].[ProductPrices] p 
--  on s.storeid = p.storeid
--  and s.ProductID = p.ProductID
--  and s.BrandID = p.BrandID
--  and @appenddate between p.ActiveStartDate and p.ActiveLastDate
--  and s.IncludeInForwardTransactions = 1
--  and p.ProductPriceTypeID = 3
--  inner join [DataTrue_Main].[dbo].[ProductIdentifiers] i
--  on s.ProductID = i.ProductID
--  and i.ProductIdentifierTypeID = 8 


select storeid, ProductId, BrandID, 
@weekdaynumber as WeekdayNumber, cast(null as int) as EstimatedPOSQty
,Qty as PlannedDelivery
into #tempEstimatedPOS
from [DataTrue_Main].[dbo].[StoreTransactions_Forward] 
where TransactionTypeID = 29
and cast(SaleDateTime as date) = @appenddate

--select * from #tempEstimatedPOS

update t 
set EstimatedPOSQty = 0
from #tempEstimatedPOS t

--update t 
--set EstimatedPOSQty = 
--(
--select cast(AVG(Qty) as int)
--from storetransactions s
--where s.StoreID = t.StoreID
--and s.ProductID = t.ProductID
--and s.BrandID = t.BrandID
--and DATEPART(weekday, s.Saledatetime) = @weekdaynumber
--and s.SaleDateTime > DATEADD(day, -90, getdate())
--)
--from #tempEstimatedPOS t


--update t 
--set EstimatedPOSQty = cast(t.PlannedDelivery * .1 as int)
--from #tempEstimatedPOS t
--where t.EstimatedPOSQty is null

/*
	update t set t.DeliveriesQtySinceCount = (select ISNULL(SUM(Qty),0)
		from [dbo].[StoreTransactions] s
		where s.StoreID=t.StoreId
		and s.ProductID=t.ProductID
		and s.BrandID = t.BrandID
		and TransactionTypeID in (5,4,9,20)
		and SaleDateTime >= case when t.CountBeforeSales = 1 then cast(t.saledatetime as DATE)
							 else cast(DATEADD(day,1,t.saledatetime) as DATE) end
		and TransactionStatus in (2, 810)
		and RuleCost is not null
		and TransactionStatus not in (Select StatusIntValue from Statuses where StatusTypeID = 9) 
		)
	from #tempStoreTransactions t

*/

--update tf set tf.Qty = t.PlannedDelivery - t.EstimatedPOSQty
--from [DataTrue_Main].[dbo].[StoreTransactions_Forward] tf
--inner join #tempEstimatedPOS t
--on tf.StoreID = t.StoreID
--and tf.ProductID = t.ProductID
--and tf.BrandID = t.brandid
--and tf.TransactionTypeID = 30

 select *
from [DataTrue_Main].[dbo].[StoreTransactions_Forward] 
  

/*

truncate table [StoreTransactions_Forward] 


select AVG(Qty)
from storetransactions
where StoreID = 6327
and ProductID = 37
and BrandID = 0
and DATEPART(weekday, Saledatetime) = 1
and SaleDateTime > DATEADD(day, -90, getdate())

select *
from storetransactions
where 1 = 1
and chainid = 3
and storeid = 6327
and productid = 37

update storetransactions
set chainid = 3
,storeid = 6327
,productid = 37
where storetransactionid in
(1377387,
1377388,
1377389,
1377390,
1377391,
1377392,
1377393,
1377394,
1377395,
1377396,
1377397,
1377398,
1377399,
1377400)

select *
from storesetup where productid in
(select productid from #tempNewspaperProducts)

select *
from productprices where productid in
(select productid from #tempNewspaperProducts)


select cast(HierarchyID as nvarchar),*
from ProductCategories where LEFT(cast(HierarchyID as nvarchar),4) = '/16/'


ProductCategoryName = 'NEWSPAPERS'

select *
from [DataTrue_Main].[dbo].[StoreTransactions_Forward]


*/
GO
