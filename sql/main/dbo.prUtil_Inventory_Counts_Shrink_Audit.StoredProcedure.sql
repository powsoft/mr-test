USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Inventory_Counts_Shrink_Audit]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Inventory_Counts_Shrink_Audit]
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
		,qty as lastqty, cast(0 as money) as salessincelastqty
		,cast(0 as money) as deliveriessincelastqty
		,cast(0 as money) as pickupssincelastqty
		,cast(0 as int) as nextqty
		,cast(0 as int) as expectednextqty
		,cast(0 as int) as shrinkqty
		into #tempshrinkaudit
		from storetransactions
		where transactiontypeid = 11
		and CAST(saledatetime as date) = @lastcountdate
		and SupplierID = @cntsupplierid
		
		update t1 set t1.nextqty = t2.qty
		from #tempshrinkaudit t1
		inner join StoreTransactions t2
		on t1.storeid = t2.StoreID
		and t1.productid = t2.ProductID
		and t1.brandid = t2.BrandID
		and t2.TransactionTypeID = 11
		and CAST(t2.saledatetime as date) = @thiscountdate
		
update #tempshrinkaudit
set salessincelastqty = 
	(		
		select SUM(isnull(st.qty, 0))
		from StoreTransactions st
		where TransactionTypeID in (2,6,7,16)
		and TransactionStatus in (2, 810)
		and CAST(saledatetime as date) between @lastcountdate and DATEADD(day, -1, @thiscountdate)
		and #tempshrinkaudit.storeid = st.StoreID
		and #tempshrinkaudit.productid = st.ProductID
		and #tempshrinkaudit.brandid = st.BrandID
		
	)
		
update #tempshrinkaudit
set deliveriessincelastqty = 
	(		
		select SUM(isnull(st.qty, 0))
		from StoreTransactions st
		where TransactionTypeID in (5)
		and TransactionStatus in (2, 810)
		and CAST(saledatetime as date) between @lastcountdate and DATEADD(day, -1, @thiscountdate)
		and #tempshrinkaudit.storeid = st.StoreID
		and #tempshrinkaudit.productid = st.ProductID
		and #tempshrinkaudit.brandid = st.BrandID
		
	)
	
		
update #tempshrinkaudit
set pickupssincelastqty = 
	(		
		select SUM(isnull(st.qty, 0))
		from StoreTransactions st
		where TransactionTypeID in (8)
		and TransactionStatus in (2, 810)
		and CAST(saledatetime as date) between @lastcountdate and DATEADD(day, -1, @thiscountdate)
		and #tempshrinkaudit.storeid = st.StoreID
		and #tempshrinkaudit.productid = st.ProductID
		and #tempshrinkaudit.brandid = st.BrandID
		
	)	

update #tempshrinkaudit
set salessincelastqty = 0 where salessincelastqty is null

update #tempshrinkaudit
set deliveriessincelastqty = 0 where deliveriessincelastqty is null

update #tempshrinkaudit
set pickupssincelastqty = 0 where pickupssincelastqty is null

	
update #tempshrinkaudit
set expectednextqty = lastqty + deliveriessincelastqty - pickupssincelastqty - salessincelastqty

update #tempshrinkaudit
set shrinkqty = expectednextqty - nextqty

select sum(qty)
from StoreTransactions
where TransactionTypeID = 17
and SupplierID = @cntsupplierid
and CAST(saledatetime as date) = @thiscountdate

select SUM(ShrinkQty) from #tempshrinkaudit

select * from #tempshrinkaudit order by 	shrinkqty desc

update i set i.shrinkrevision = t.shrinkqty
from #tempshrinkaudit t
inner join InventoryPerpetual i
on t.StoreID = i.StoreID
and t.ProductID = i.ProductID
and t.BrandID = i.brandid
and t.shrinkqty <> 0

select * from inventoryperpetual where shrinkrevision <> 0

select * from StoreTransactions where SupplierID = @cntsupplierid and CAST(saledatetime as date) = @thiscountdate and TransactionTypeID = 17

exec prProcessShrink_PassDateAndSupplierId @thiscountdate, @cntsupplierid

select * from inventoryperpetual where shrinkrevision <> 0

select * from StoreTransactions where SupplierID = @cntsupplierid and CAST(saledatetime as date) = @thiscountdate and TransactionTypeID = 17

drop table #tempshrinkaudit

set @lastcountdate = @thiscountdate
		
		fetch next from @reccount into  @cntsupplierid, @thiscountdate	
		
		
	end
	
close @reccount
deallocate @reccount


--/**************************Sync OnHand After Last Count**********************

select max(saledatetime) from storetransactions where supplierid = 41464 and transactiontypeid = 11

declare @rec cursor
declare @recordid int
declare @storeid int
declare @productid int
declare @brandid int=0
declare @originalqty int
declare @loadqty int
declare @sbtsalestable int
declare @sbtsalesnew int
declare @deliveriesnew int
declare @pickupsnew int
declare @synclastcountdate date
declare @syncsupplierid int=41464

select @synclastcountdate = cast(max(saledatetime) as date) from storetransactions where supplierid = 41464 and transactiontypeid = 11
print @synclastcountdate

set @rec = CURSOR local fast_forward FOR
	select i.StoreID, i.ProductID, i.BrandID, i.Qty, 0
	--select *
	from storetransactions i
	where supplierid = @syncsupplierid
	and cast(saledatetime as date) = @synclastcountdate
	and transactiontypeid = 11
	
open @rec

fetch next from @rec into 
	@storeid
	,@productid
	,@brandid
	,@originalqty
	,@sbtsalestable
	--,@loadqty
	
while @@FETCH_STATUS = 0
	begin

		set @sbtsalesnew = 0
		
		select @sbtsalesnew = SUM(qty)
		from StoreTransactions
		where StoreID = @storeid
		and ProductID = @productid
		and BrandID = @brandid
		and TransactionTypeID in (2,6,7,16)
		and cast(SaleDateTime as date) >= @synclastcountdate
		and TransactionStatus in (2, 810)
		and RuleCost is not null
		
		if @sbtsalesnew is null
			set @sbtsalesnew = 0
			
		set @deliveriesnew = 0
		
		select @deliveriesnew = SUM(qty)
		from StoreTransactions
		where StoreID = @storeid
		and ProductID = @productid
		and BrandID = @brandid
		and TransactionTypeID in (5,4)		
		and cast(SaleDateTime as date) >= @synclastcountdate
		and TransactionStatus in (2, 810)
		and RuleCost is not null
				
		if @deliveriesnew is null
			set @deliveriesnew = 0
			
			
		set @pickupsnew = 0
		
		select @pickupsnew = SUM(qty)
		from StoreTransactions
		where StoreID = @storeid
		and ProductID = @productid
		and BrandID = @brandid
		and TransactionTypeID in (8)		
		and cast(SaleDateTime as date) >= @synclastcountdate
		and TransactionStatus in (2, 810)
		and RuleCost is not null
				
		if @pickupsnew	is null
			set @pickupsnew = 0	

print @originalqty
--print @loadqty
print @sbtsalestable
print @sbtsalesnew	
print  @deliveriesnew
print @pickupsnew

		update i set i.currentonhandqty = @originalqty - @sbtsalesnew + @deliveriesnew - @pickupsnew
		from InventoryPerpetual i
		where i.storeid = @storeid
		and i.productid = @productid
		and i.brandid = @brandid
		
	
		fetch next from @rec into 
	@storeid
	,@productid
	,@brandid
	,@originalqty
	,@sbtsalestable
	end
	
close @rec
deallocate @rec

--*/

/**************Shrink Qty Review************************
declare @recreview cursor
declare @countdate date
declare @rvwsupplierid int=41464

set @recreview = cursor local fast_forward for
	select distinct cast(saledatetime as date)
	from storetransactions
	where supplierid = @rvwsupplierid
	and transactiontypeid = 11
	order by cast(saledatetime as date)
	
open @recreview

fetch next from @recreview into @countdate

while @@fetch_status = 0
	begin
	
		select @countdate, sum(qty) from storetransactions 
		where supplierid = @rvwsupplierid 
		and cast(saledatetime as date) = @countdate
		and transactiontypeid = 17
	
		fetch next from @recreview into @countdate
	
	end
	
close @recreview
deallocate @recreview

*/
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
