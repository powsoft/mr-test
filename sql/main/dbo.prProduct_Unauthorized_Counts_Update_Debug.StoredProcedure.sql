USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prProduct_Unauthorized_Counts_Update_Debug]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prProduct_Unauthorized_Counts_Update_Debug]
as


--get outlyers drop table #tempproductsdelivered select transactionstatus, count(storetransactionid) from storetransactions where transactiontypeid = 11 group by transactionstatus
select storetransactionid, storeid, productid, brandid, 
supplierid, saledatetime, cast(null as int) as storesetupid,
cast(null as int) as mrid, CAST(null as nvarchar(50)) as UPC
into #tempproductsdelivered
--select count(storetransactionid)
--select *
from storetransactions
--from import.dbo.storetranstest
where 
(
1 = 1
--and cast(datetimecreated as date)  > '11/30/2011' --cast(getdate() as date)
and cast(datetimecreated as date)  >= cast(dateadd(day,-5,getdate()) as date)
and transactiontypeid in (11)
and transactionstatus in (1,2)
)
or transactiontypeid = 26
order by TransactionTypeID desc

--select cast(dateadd(day,-5,getdate())
update t set t.upc = i.identifiervalue
from #tempproductsdelivered t
inner join ProductIdentifiers i
on t.productid = i.ProductID
and i.ProductIdentifierTypeID = 2

--update records with valid setup

update t set t.storesetupid = s.storesetupid
from #tempproductsdelivered t
inner join storesetup s
on t.storeid = s.storeid
and t.productid = s.productid
and t.brandid = s.brandid
and t.supplierid = s.supplierid
and t.saledatetime between s.activestartdate and s.activelastdate



update st set st.transactiontypeid =
case when st.transactiontypeid = 26 then 11
	 else st.transactiontypeid
end
from storetransactions st
inner join #tempproductsdelivered t
on st.StoreTransactionID = t.StoreTransactionID
and st.TransactionTypeID in (26)
and t.storesetupid is not null


delete
--select *
from #tempproductsdelivered 
where storesetupid is not null

--look for authorization update  #tempproductsdelivered set mrid = null
--select * from #tempproductsdelivered

update t set t.mrid = mr.maintenancerequestid
from #tempproductsdelivered t
inner join maintenancerequests mr
on t.productid = mr.productid
and t.supplierid = mr.supplierid
and mr.approved = 1
and mr.markdeleted is null
and t.mrid is null
inner join maintenancerequeststores ms
on mr.maintenancerequestid = ms.maintenancerequestid
and t.storeid = ms.storeid
--and t.storeid in (select storeid from stores where custom1 = mr.banner)

update t set t.mrid = mr.maintenancerequestid
from #tempproductsdelivered t
inner join maintenancerequests mr
on t.productid = mr.productid
and t.supplierid = mr.supplierid
and t.mrid is null
and mr.approved = 1
and mr.markdeleted is null
and t.storeid in (select storeid from stores where custom1 = mr.banner)

update t set t.mrid = mr.maintenancerequestid
from #tempproductsdelivered t
inner join maintenancerequests mr
on t.upc = mr.upc
and t.supplierid = mr.supplierid
and t.mrid is null
and mr.approved = 1
and mr.markdeleted is null
and t.storeid in (select storeid from stores where custom1 = mr.banner)




/*
select * from stores where storeid = 40451
40451	19071	0	40559	2012-05-29 00:00:00.000	NULL	47551
40451	19072	0	40559	2012-05-29 00:00:00.000	NULL	49441
select *
from maintenancerequests
where maintenancerequestid in (47551,49441)

select * from #tempproductsdelivered where storesetupid is null
select * from #tempproductsdelivered where mrid is null
*/

delete from #tempproductsdelivered where mrid is not null

declare @recauth cursor
declare @authtransid bigint
declare @authstoreid int
declare @authproductid int
declare @authsupplierid int
declare @authsaledatetime date

set @recauth = cursor local fast_forward for
	select storetransactionid, storeid, productid, supplierid, cast(saledatetime as date)
	from #tempproductsdelivered
	
open @recauth

fetch next from @recauth into @authtransid,@authstoreid,@authproductid,@authsupplierid,@authsaledatetime

while @@fetch_status = 0
	begin
		
		select storeid from stores where storeid = @authstoreid
		and custom1 in
		(
			select distinct custom1
			from stores
			where 1 = 1
			and storeid in
			(
				select distinct storeid from storetransactions
				where transactiontypeid = 2 and productid = @authproductid	
				and supplierid = @authsupplierid and cast(saledatetime as date) <= cast(@authsaledatetime as date)
				and saledatetime > '11/30/2011'
			)
		)
	
		if @@rowcount > 0
			begin
				--select * from #tempproductsdelivered where storetransactionid = @authtransid
				delete from #tempproductsdelivered where storetransactionid = @authtransid
			end
		else
			begin
				update storetransactions 
				set transactiontypeid = 26
				where storetransactionid = @authtransid
				and ProductPriceTypeID is null
			end
	
		fetch next from @recauth into @authtransid,@authstoreid,@authproductid,@authsupplierid,@authsaledatetime	
	end

close @recauth
deallocate @recauth

/*
select * from storetransactions where transactiontypeid in (24, 25) order by cast(datetimecreated as date) desc

drop table import.dbo.storetranstest 

select * into import.dbo.storetranstest from storetransactions where cast(datetimecreated as date) = '5/30/2012'

select * from import.dbo.storetranstest where transactiontypeid in (24, 25) order by productpricetypeid desc

update import.dbo.storetranstest set transactiontypeid = case when transactiontypeid = 24 then 5 else 8 end

select * 
--update st set st.transactiontypeid = t.transactiontypeid
from import.dbo.storetranstest t
inner join datatrue_main.dbo.storetransactions st
on t.storetransactionid = st.storetransactionid
where t.transactiontypeid in (24, 25)
and t.ProductPriceTypeID is null


below had cost setup
72077680	40393	40411	5688	40559	24	3	0	12	5.03	0.00	2012-04-11 00:00:00.000
24080784	40393	40945	22459	41464	25	3	0	1	1.84	2.72	2012-01-30 00:00:00.000
24533483	40393	40945	22459	41464	25	3	0	1	1.84	2.72	2012-03-16 00:00:00.000
72936248	40393	40404	5688	40559	25	3	0	12	5.03	0.00	2011-12-06 00:00:00.000
73088996	40393	40434	5688	40559	24	3	0	12	5.03	0.00	2012-03-16 00:00:00.000
24060570	40393	40945	22459	41464	25	3	0	1	1.84	2.72	2011-12-24 00:00:00.000
24124904	40393	40945	22459	41464	25	3	0	2	1.84	2.72	2012-01-28 00:00:00.000
24049429	40393	40989	22459	41464	25	3	0	1	1.84	2.72	2011-12-17 00:00:00.000
*/

return
GO
