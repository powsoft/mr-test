USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_Newspapers_Shrink_Create_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prBilling_Newspapers_Shrink_Create_PRESYNC_20150329]
@saledate as date

/*

[dbo].[prBilling_Newspapers_Shrink_Create] '11/19/2013'



*/
as
--declare @saledate as date='11/18/2013'
declare @MyID int = 7417

--update f set f.Qty = t.TotalQty
----select *
--from storetransactions_forward f
--inner join
--(select storeid, ProductId, brandid, supplierid, CAST(saledatetime as date) as Saledate, SUM(Qty) as TotalQty
--from StoreTransactions 
--where transactiontypeid in (5)
--and CAST(saledatetime as date) >= DATEADD(day, -90, getdate())
--group by storeid, ProductId, brandid, supplierid, CAST(saledatetime as date)
--) t
--on f.storeid = t.StoreID
--and f.productid = t.ProductID
--and f.brandid = t.BrandID
--and f.supplierid = t.SupplierID
--and CAST(f.saledatetime as date) = CAST(t.saledate as date)
--and f.Qty <> t.TotalQty

/*
select * from ShrinkSupportingStoreTransactions

*/

	begin transaction
		
	update t set t.shrinklocked = 1
	--select *
	from [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts] f
	inner join ShrinkSupportingStoreTransactions s
	on f.storetransactionid = s.shrinktransactionid
	and CAST(f.Saledatetime as date) = @saledate
	inner join storetransactions t
	on s.SupportingTransactionID = t.Storetransactionid
	where f.Status in (1)
--	where f.Status in (1, 2)
	and isnull(t.ShrinkLocked, 0) <> 1

--Need to remove any store transactions and shrink facts that remain at zero status for this saledate
	delete t
	--select *
	from storetransactions t
	inner join [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts] f
	on t.StoreTransactionID = f.StoreTransactionID
	where f.Status in (0, 2)
	and t.ChainID = 64010
	--where f.Status = 0
	and CAST(f.saledatetime as date) = @saledate
	
	
	delete t
	--select *
	from ShrinkSupportingStoreTransactions t
	inner join [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts] f
	on t.ShrinkTransactionID = f.StoreTransactionID
	where f.Status in (0, 2)
	and f.ChainID = 64010
	--where f.Status = 0
	and CAST(f.saledatetime as date) = @saledate
		
	delete
	from [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts]
	where 1 = 1
	and ChainID = 64010
	--***************************
	--and ChainID = 42515
	--and SupplierID = 24202
	--***************************
	and status in (0, 2)
	--and Status = 0
	and CAST(saledatetime as date) = @saledate
	
/*
62368	38709
62368	38710
62372	39546
*/	

select distinct productid
into #tempNewspaperProducts 
from StoreTransactions_Forward
order by productid

select * from #tempNewspaperProducts order by ProductID

--select ProductId
--into #tempNewspaperProducts 
----select *
--from ProductCategoryAssignments a
--inner join ProductCategories c
--on a.ProductCategoryID = c.ProductCategoryID
--and LEFT(cast(HierarchyID as nvarchar),4)  IN (select LEFT(cast(HierarchyID as nvarchar),4) from ProductCategories where ProductCategoryName = 'NEWSPAPERS')
/*
select *
--update t set rulecost = reportedcost
from storetransactions t
where TransactionTypeID in (2, 6)
and ChainID = 42501 
*/
select StoretransactionID, chainid, storeid, t.ProductId, brandid, supplierid, CAST(saledatetime as date) as Saledate,
QTY, rulecost, ruleretail, CAST(null as bigint) as ShrinkTransactionID, TransactionTypeID, UPC
into #tempShrinkTransactions
from storetransactions t
--inner join #tempNewspaperProducts n
--on t.ProductID = n.ProductID
where 1 = 1
and isnull(t.ShrinkLocked, 0) = 0
and TransactionTypeID in (5, 8)
--and TransactionTypeID in (2, 6, 5, 8, 7, 16)
and ChainID = 64010
--and t.ProductID in (38722, 38723)
--and StoreID in (64884,64894)
--and supplierid = 27131
--and SupplierID = 24202 ---------------------------------------------Temp HardCode------------------------------------------------------------
and CAST(saledatetime as date) = @saledate

select * from #tempShrinkTransactions

select chainid, storeid, t.ProductId, brandid, supplierid, CAST(saledate as date) as Saledate,
CAST(0 as money) as POSQTY, CAST(0 as int) as DLQty, CAST(0 as int) as PKQty,
CAST(0 as int) as ShrinkQty, max(rulecost) as rulecost, max(ruleretail) as ruleretail, CAST(0 as int) as ApprovedDrawQty
,CAST(null as bigint) as ShrinkTransactionID, LTRIM(rtrim(UPC)) as UPC
into #tempShrinkCalc
from #tempShrinkTransactions t
where 1 = 1
and TransactionTypeID in (5, 8)
--and TransactionTypeID in (2, 6, 5, 8, 7, 16)
and ChainID = 64010
--and ProductID in (38722, 38723)
--and StoreID in (64884,64894)
--and supplierid = 27131
--and SupplierID = 24202 ---------------------------------------------Temp HardCode------------------------------------------------------------
and CAST(saledate as date) = @saledate
group by chainid, storeid, t.ProductId, brandid, supplierid, CAST(saledate as date), LTRIM(rtrim(UPC))--,
--rulecost, ruleretail


update s set s.POSQTY = t.Qty
from #tempShrinkCalc s
inner join
(
select storeid, productid, brandid, supplierid, CAST(t.saledatetime as date) as Date, SUM(qty) as Qty 
from storetransactions t
where t.TransactionTypeID in (2,6,7,16)
and isnull(t.ShrinkLocked, 0) = 0
group by storeid, productid, brandid, supplierid, CAST(t.saledatetime as date)
) t
on t.storeid = s.storeid
and t.productid = s.productid
and t.brandid = s.brandid
and t.supplierid = s.supplierid
and CAST(t.[Date] as date) = cast(s.SaleDate as date)

--delete from #tempShrinkCalc 
--where SupplierID in
--(select SupplierID from dbo.BillingExclusions where 

select * from #tempShrinkCalc
--select top 1000 * from storesetup select DATEPART(weekday, getdate())

update t 
set ApprovedDrawQty = 
	case when DATEPART(weekday, Saledate) = 1 then SunLimitQty
			when DATEPART(weekday, Saledate) = 2 then MonLimitQty
			when DATEPART(weekday, Saledate) = 3 then TueLimitQty
			when DATEPART(weekday, Saledate) = 4 then WedLimitQty
			when DATEPART(weekday, Saledate) = 5 then ThuLimitQty
			when DATEPART(weekday, Saledate) = 6 then FriLimitQty
			when DATEPART(weekday, Saledate) = 7 then SatLimitQty
		else 0
	end
from #tempShrinkCalc t
inner join storesetup s
on t.StoreID = s.StoreID
and t.ProductID = s.ProductID
and t.BrandID = s.BrandID
and t.SupplierID = s.SupplierID

--select * from #tempShrinkCalc

--delete from #tempShrinkCalc where approveddrawqty = 0

select * from #tempShrinkCalc

--update s set s.DLQty =
--(
--select SUM(qty) 
--from storetransactions t
--where t.TransactionTypeID in (5)
--and t.storeid = s.storeid
--and t.productid = s.productid
--and t.brandid = s.brandid
--and t.supplierid = s.supplierid
--and CAST(t.saledatetime as date) = cast(s.SaleDate as date)
--)
--from #tempShrinkCalc s
update s set s.DLQty = t.Qty
from #tempShrinkCalc s
inner join
(
select storeid, productid, brandid, supplierid, CAST(t.saledate as date) as Date, SUM(qty) as Qty 
from #tempShrinkTransactions t
where t.TransactionTypeID in (5)
group by storeid, productid, brandid, supplierid, CAST(t.saledate as date)
) t
on t.storeid = s.storeid
and t.productid = s.productid
and t.brandid = s.brandid
and t.supplierid = s.supplierid
and CAST(t.[date] as date) = cast(s.SaleDate as date)

----***********************Temp Code Until Deliveries Loaded*******************************************
--update t 
--set DLQty = 
--	case when DATEPART(weekday, Saledate) = 1 then SunLimitQty
--			when DATEPART(weekday, Saledate) = 2 then MonLimitQty
--			when DATEPART(weekday, Saledate) = 3 then TueLimitQty
--			when DATEPART(weekday, Saledate) = 4 then WedLimitQty
--			when DATEPART(weekday, Saledate) = 5 then ThuLimitQty
--			when DATEPART(weekday, Saledate) = 6 then FriLimitQty
--			when DATEPART(weekday, Saledate) = 7 then SatLimitQty
--		else 0
--	end
--from #tempShrinkCalc t
--inner join storesetup s
--on t.StoreID = s.StoreID
--and t.ProductID = s.ProductID
--and t.BrandID = s.BrandID
--and t.SupplierID = s.SupplierID
----***************************************************************************************************

select * from #tempShrinkCalc order by DLQty desc

update s set s.PKQty = t.Qty
from #tempShrinkCalc s
inner join
(
select storeid, productid, brandid, supplierid, CAST(t.saledate as date) as Date, SUM(qty) as Qty 
from #tempShrinkTransactions t
where t.TransactionTypeID in (8)
group by storeid, productid, brandid, supplierid, CAST(t.saledate as date)
) t
on t.storeid = s.storeid
and t.productid = s.productid
and t.brandid = s.brandid
and t.supplierid = s.supplierid
and CAST(t.[date] as date) = cast(s.SaleDate as date)

select * from #tempShrinkCalc order by DLQty desc

--update s set ApprovedDrawQty = cast(CAST(POSQty as money) * 1.10 as int)
--from #tempShrinkCalc s
--where ApprovedDrawQty = 0

update s set ShrinkQty = DLQty - POSQty - PKQty
--case when DLQty <= ApprovedDrawQty then DLQty - POSQty - PKQty
--	 when DLQty > ApprovedDrawQty and POSQTY > ApprovedDrawQty then 0
--	 when DLQty > ApprovedDrawQty and POSQTY < DLQty then ApprovedDrawQty - POSQty - PKQty
--else 0
--end
from #tempShrinkCalc s

select * from #tempShrinkCalc order by DLQty desc

--delete from #tempShrinkCalc where ShrinkQty <= 0


--select *
--from storetransactions
--where TransactionTypeID = 17


declare @rec cursor
declare @chainid  int
declare @storeid  int
declare @ProductId  int
declare @brandid  int
declare @supplierid int
declare @ShrinkQty int
declare @RuleCost money
declare @RuleRetail money
declare @recsaledate as date
declare @shrinktransactionid bigint
declare @upc nvarchar(50)

set @rec= CURSOR local fast_forward FOR
	select chainid, storeid, ProductId, brandid, supplierid, ShrinkQty, RuleCost, RuleRetail, CAST(saledate as date), UPC
		from #tempShrinkCalc
		--where ShrinkQty <> 0
		
open @rec

fetch next from @rec into @chainid, @storeid, @productid, @brandid, @supplierid, @shrinkqty, @rulecost, @ruleretail, @recsaledate, @upc

while @@FETCH_STATUS = 0
	begin
			
		INSERT INTO [DataTrue_Main].[dbo].[StoreTransactions]
				   ([ChainID]
				   ,[StoreID]
				   ,[ProductID]
				   ,[SupplierID]
				   ,[TransactionTypeID]
				   ,[ProductPriceTypeID]
				   ,[BrandID]
				   ,[Qty]
				   ,[SetupCost]
				   ,[SetupRetail]
				   ,[SaleDateTime]
				   ,[RuleCost]
				   ,[RuleRetail]
				   ,[TrueCost]
				   ,[TrueRetail]
				   ,[LastUpdateUserID]
				   ,[SourceID]
				   ,[WorkingTransactionID]
				   ,[UPC])
			values (@ChainID
				   ,@StoreID
				   ,@ProductID
				   ,@SupplierID
				   ,17 --[TransactionTypeID]
				   ,3 --[ProductPriceTypeID]
				   ,@BrandID
				   ,@ShrinkQty
				   ,@RuleCost
				   ,@RuleRetail
				   ,@SaleDate
				   ,@RuleCost
				   ,@RuleRetail
				   ,@RuleCost
				   ,@RuleRetail
				   ,@MyID --[LastUpdateUserID]
				   ,135
				   ,0
				   ,@upc)
			
			set @shrinktransactionid = SCOPE_IDENTITY()
			
			update c set ShrinkTransactionid = @shrinktransactionid
			from #tempShrinkCalc c
			where c.ChainID = @chainid
			and c.storeid = @storeid
			and c.ProductID = @ProductId
			and c.BrandID = @brandid
			and c.SupplierID = @supplierid
			and c.Saledate = @recsaledate
			
			fetch next from @rec into @chainid, @storeid, @productid, @brandid, @supplierid, @shrinkqty, @rulecost, @ruleretail, @recsaledate, @upc

	end
	
	
	update c set ShrinkTransactionid = @shrinktransactionid
	from #tempShrinkTransactions c
	inner join #tempShrinkCalc a
	on c.ChainID = a.chainid
	and c.storeid = a.storeid
	and c.ProductID = a.ProductId
	and c.BrandID = a.brandid
	and c.SupplierID = a.supplierid
	and c.Saledate = a.saledate
/*
select * from [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts]
select * from #tempShrinkCalc
*/

INSERT INTO [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts]
           ([TransactionTypeID]
           ,[ChainID]
        ,[StoreID]
           ,[ProductID]
           ,[BrandID]
           ,[Supplierid]
           ,[SaleDateTime]
           ,[UnitCost]
           ,[ShrinkUnits]
           ,[Shrink$]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[Status]
           ,[storetransactionid]
           ,[OriginalPOS]
           ,[OriginalDeliveries]
           ,[OriginalPickups])
    select [TransactionTypeID]
           ,t.[ChainID]
           ,t.[StoreID]
           ,t.[ProductID]
           ,t.[BrandID]
           ,t.[Supplierid]
           ,[SaleDateTime]
           ,t.[RuleCost]
           ,[Qty]
           ,cast([Qty] as money) * t.[RuleCost] 
           ,getdate()
           ,0
           ,2 --0
           ,storetransactionid
           ,POSQTY
           ,DLQty
           ,PKQty
    from storetransactions t
    inner join #tempShrinkCalc c
    on t.StoreID = c.StoreID
    and t.ProductID = c.ProductID
    and t.BrandID = c.BrandID
    and t.SupplierID = c.SupplierID
    and CAST(t.saledatetime as date) = CAST(c.saledate as date)
where 1 = 1
and t.ChainID = 64010
--and t.supplierid = 27131
--and t.SupplierID = 24202
    and t.TransactionTypeID in (17, 23)
    and StoreTransactionID not in
    (select StoreTransactionID from [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts])

	--select * 
	----update f set transactiontypeid = 23
	--from [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts] f
	--where shrinkfactsid > 1350
	
	update t set t.transactionstatus = 800
	--select *
	from [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts] f
	inner join storetransactions t
	on f.storetransactionid = t.StoreTransactionID
	and t.TransactionStatus in (0, -800)
	and f.status = 1

	update t set t.transactionstatus = -800
	from [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts] f
	inner join storetransactions t
	on f.storetransactionid = t.StoreTransactionID
	and t.TransactionStatus in (0)
	and f.status = 2
	
	commit transaction
/*
select * from suppliers where supplieridentifier = 'WR483'

select *
from storetransactions
where chainid = 64010
and storeid = 64620 --64894
and productid = 37748
and cast(saledatetime as date) = '11/18/2013'

64620	37748	0	27155

select transactionstatus as stat, *
--select * into import.dbo.storetransactions_Type17_DELETED_20131218
--delete
from storetransactions
where chainid = 64010
and transactiontypeid = 17
order by transactionstatus

select * from [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts] order by status

select * into import.dbo.InventoryReport_Newspaper_Shrink_Facts_DELETED_20131218 from [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts] where chainid in (64010)
delete from [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts] where chainid in (64010)

select * from [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts] where chainid in (64010) order by status
select * from [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts] where chainid in (64010) order by saledatetime
select * from [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts] order by OriginalDeliveries desc
select * from [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts] order by ShrinkUnits desc
select * from storetransactions where chainid = 64010 and transactiontypeid = 17

select sum(OriginalDeliveries), sum(OriginalPickups), sum(OriginalPOS), sum(ShrinkUnits) from [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts] where chainid in (64010) and cast(SaleDateTime as date) between '11/25/2013' and '12/1/2013' and supplierid = 27155

select sum(case when transactiontypeid = 5 then qty else qty * -1 end) from storetransactions where chainid in (64010) and cast(SaleDateTime as date) between '11/25/2013' and '12/1/2013' and transactiontypeid in (5,8)

select sum(qty) from storetransactions where chainid in (64010) and cast(SaleDateTime as date) between '11/25/2013' and '12/1/2013' and transactiontypeid in (8)
select sum(qty) from storetransactions where chainid in (64010) and cast(SaleDateTime as date) between '12/2/2013' and '12/8/2013' and transactiontypeid in (8)


select * from datatrue_edi.dbo.inbound846inventory_newspapers where chainname = 'LG' and cast(EffectiveDate as date) between '11/25/2013' and '12/1/2013' and recordtype = 0 and purposecode = 'DB'
select sum(qty) from datatrue_edi.dbo.inbound846inventory_newspapers where chainname = 'LG' and cast(EffectiveDate as date) between '11/25/2013' and '12/1/2013' and recordtype = 0 and purposecode = 'CR'

select * from storesetup
where (storeid = 62368	and productid = 38709)
or (storeid = 62368	and productid = 38710)
or (storeid = 62372	and productid = 39546)
	

prBilling_Newspapers_Shrink_Create '10/10/2012'

select *
from storetransactions
where chainid = 42501
and transactiontypeid = 17

select distinct saledatetime
from storetransactions
where chainid = 42501
and transactiontypeid = 5
and transactionstatus = 0

select distinct saledatetime
from storetransactions
where chainid = 42501
and transactiontypeid = 2
and transactionstatus = 0

select * from productcategoryassignments where productid in 
(select distinct productid from productidentifiers where productidentifiertypeid = 8)

insert productcategoryassignments
select distinct 1371, productid, 0, getdate(), 0, getdate(), '' from productidentifiers where productidentifiertypeid = 8

select ss.* into import.dbo.storesetup_before41440Update_20121024
--update ss set ss.supplierid = 41440
from storesetup ss
inner join
(select distinct storeid, productid from storetransactions where chainid = 42501) st
on ss.StoreID = st.StoreID
and ss.ProductID = st.ProductID

select * from storetransactions where storeid = 57196 and productid = 38647
select * from storetransactions where transactiontypeid = 5 and chainid = 42501 and cast(saledatetime as date) = '10/9/2012'

select * from storetransactions where transactiontypeid = 17 and chainid = 42501

select * into import.dbo.InventoryReport_Newspaper_Shrink_Facts_20121105 from [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts]

select * from [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts] order by Originaldeliveries desc

update t set t.shrink$ = ShrinkUnits * Unitcost from InventoryReport_Newspaper_Shrink_Facts t

truncate table [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts]

select * from import.dbo.storesetup_before41440Update_20121024 where chainid = 42501

select s.supplierid, b.supplierid, *
--select s.* into import.dbo.storesetupwith41440_20121105 
--update s set s.supplierid = b.supplierid
from storesetup s
inner join import.dbo.storesetup_before41440Update_20121024 b
on s.storesetupid = b.storesetupid
where s.supplierid <> b.supplierid

select *
--update t set t.supplierid = s.supplierid
from storetransactions t
inner join storesetup s
on t.storeid = s.storeid
and t.productid = s.productid
and t.brandid = s.brandid
and t.saledatetime between s.activestartdate and s.activelastdate
and t.supplierid <> s.supplierid
and t.supplierid = 41440
and t.transactionstatus = 0

select * from [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts]

declare @startdate date = '9/2/2013'
declare @enddate date = '9/8/2013'
declare @currentdate date

set @currentdate = @startdate

while @currentdate <= @enddate
	begin
	
		exec [dbo].[prBilling_Newspapers_Shrink_Create] @currentdate

		set @currentdate = dateadd(day, 1, @currentdate)

	end

*/	
return
GO
