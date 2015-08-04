USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Inventory_Counts_Shrink_Audit_20120409]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Inventory_Counts_Shrink_Audit_20120409]
as

--**************************LOAD ALL COUNTS**************************
declare @reccount cursor
declare @lastcountdate date
declare @thiscountdate date
declare @cntsupplierid int=41464
declare @initialcountdate as date='12/10/2011'

set @reccount = CURSOR local fast_forward FOR
	select distinct Supplierid, CAST(saledatetime as date)
	--select *
	from StoreTransactions t
	where 1 = 1
	and SupplierID = @cntsupplierid
	and t.TransactionTypeID = 11
	and CAST(t.saledatetime as date) > @initialcountdate
	and t.RuleCost is not null
	order by Supplierid, CAST(saledatetime as date)
	
open @reccount

fetch next from @reccount into  @cntsupplierid, @thiscountdate

set @lastcountdate =  @initialcountdate

while @@FETCH_STATUS = 0
	begin
	
	print @lastcountdate
	print @thiscountdate
	
		select storeid, productid, brandid
		,qty as nextqty, cast(0 as money) as salessincelastqty
		,cast(0 as money) as deliveriessincelastqty
		,cast(0 as money) as pickupssincelastqty
		,cast(0 as int) as lastqty
		,cast(0 as int) as expectednextqty
		,cast(0 as int) as shrinkqty
		,CAST(null as date) as LastCountDate
		,CAST(saledatetime as date) as ThisCountDate
		into #tempshrink
		from storetransactions
		where transactiontypeid = 11
		and CAST(saledatetime as date) = @thiscountdate
		and SupplierID = @cntsupplierid
		
		update t1 set t1.LastCountDate = t2.maxdate
		from #tempshrink t1
		inner join 
		(select storeid, productid, brandid, max(saledatetime) as maxdate
		from StoreTransactions 
		where TransactionTypeID = 11
		and CAST(saledatetime as date) < @thiscountdate
		and CAST(saledatetime as date) >= @initialcountdate
		group by storeid, productid, brandid
		) t2
		on t1.storeid = t2.StoreID
		and t1.productid = t2.ProductID
		and t1.brandid = t2.BrandID
		
		update t1 set t1.Lastqty = t2.qty
		from #tempshrink t1
		inner join 	StoreTransactions t2
		on t1.StoreID = t2.StoreID
		and t1.ProductID = t2.ProductID
		and t1.BrandID = t2.BrandID
		and cast(t1.LastCountDate as date) = CAST(t2.saledatetime as date)

select * from #tempshrink 
		
update #tempshrink
set salessincelastqty = 
	(		
		select SUM(isnull(st.qty, 0))
		from StoreTransactions st
		where TransactionTypeID in (2,6)
		and TransactionStatus in (2, 810)
		and CAST(saledatetime as date) between #tempshrink.lastcountdate and DATEADD(day, -1, @thiscountdate)
		and #tempshrink.storeid = st.StoreID
		and #tempshrink.productid = st.ProductID
		and #tempshrink.brandid = st.BrandID
		
	)
		
update #tempshrink
set deliveriessincelastqty = 
	(		
		select SUM(isnull(st.qty, 0))
		from StoreTransactions st
		where TransactionTypeID in (5)
		and TransactionStatus in (2, 810)
		and CAST(saledatetime as date) between #tempshrink.lastcountdate and DATEADD(day, -1, @thiscountdate)
		and #tempshrink.storeid = st.StoreID
		and #tempshrink.productid = st.ProductID
		and #tempshrink.brandid = st.BrandID
		
	)
	
		
update #tempshrink
set pickupssincelastqty = 
	(		
		select SUM(isnull(st.qty, 0))
		from StoreTransactions st
		where TransactionTypeID in (8)
		and TransactionStatus in (2, 810)
		and CAST(saledatetime as date) between #tempshrink.lastcountdate and DATEADD(day, -1, @thiscountdate)
		and #tempshrink.storeid = st.StoreID
		and #tempshrink.productid = st.ProductID
		and #tempshrink.brandid = st.BrandID
		
	)	

select * from #tempshrink

update #tempshrink
set salessincelastqty = 0 where salessincelastqty is null

update #tempshrink
set deliveriessincelastqty = 0 where deliveriessincelastqty is null

update #tempshrink
set pickupssincelastqty = 0 where pickupssincelastqty is null

	
update #tempshrink
set expectednextqty = lastqty + deliveriessincelastqty - pickupssincelastqty - salessincelastqty

update #tempshrink
set shrinkqty = expectednextqty - nextqty

select sum(qty)
from StoreTransactions
where TransactionTypeID = 17
and SupplierID = @cntsupplierid
and CAST(saledatetime as date) = @thiscountdate

select SUM(ShrinkQty) from #tempshrink

select * from #tempshrink order by 	shrinkqty desc

drop table #tempshrink

set @lastcountdate = @thiscountdate
		
		fetch next from @reccount into  @cntsupplierid, @thiscountdate	
		
		
	end
	
close @reccount
deallocate @reccount

return


/*
select * from inventoryperpetual
where shrinkrevision <> 0

select *
from storetransactions
where supplierid = 40562
and transactiontypeid in (5,8)
order by saledatetime desc

select *
from invoicedetails
where supplierid = 40562
and invoicedetailtypeid in (3)
order by saledate desc

*/
GO
