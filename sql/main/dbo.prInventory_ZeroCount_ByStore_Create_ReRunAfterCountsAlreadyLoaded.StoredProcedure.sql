USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInventory_ZeroCount_ByStore_Create_ReRunAfterCountsAlreadyLoaded]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prInventory_ZeroCount_ByStore_Create_ReRunAfterCountsAlreadyLoaded]
--@supplierid int
--,@countdate date

as



/*







drop table #temp
drop table #temp2
drop table #temp3

select distinct saledatetime
from storetransactions_working
where transactiontypeid = 11
and supplierid = 40562
order by saledatetime

select distinct saledatetime
from storetransactions_working
where workingsource = 'INV'
and workingstatus = 4
and supplierid = 41464
order by saledatetime

select *
from storetransactions_working
where workingsource = 'INV'
and workingstatus = 4
and supplierid = 41464
and cast(datetimecreated as date) = '3/12/2012'

select saledatetime, count(storetransactionid)
from storetransactions_working
where workingsource = 'INV'
and workingstatus = 4
and supplierid = 40557
group by saledatetime
order by saledatetime


prInventory_ZeroCount_ByStore_Create 40557, '2012-01-23 00:00:00.000'



	select *
	from [dbo].[StoreTransactions_Working]
	where WorkingStatus = 4
	and charindex('INV', WorkingSource) > 0
	and saledatetime = '2012-02-28 00:00:00.000'
	order by storeidentifier
*/


--declare @supplierid int=41464 declare @countdate date='2012-01-21 00:00:00.000'
declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 41714
declare @createzerocountrecords bit
declare @supplierid int
declare @countdate date
declare @reccounts cursor

begin try

	select distinct StoreTransactionID
	into #tempStoreTransaction
	--select *
	from [dbo].[StoreTransactions_Working]
	where 1 = 1
	--and WorkingStatus = 4
	and charindex('INV', WorkingSource) > 0
	and SaleDateTime = @countdate
	and SupplierID = @supplierid

	begin transaction


	set @reccounts = CURSOr local fast_forward FOR
		select distinct SupplierID, CAST(saledatetime as date)
		from StoreTransactions_Working w
		inner join #tempStoreTransaction t
		on w.StoreTransactionID = t.StoreTransactionID
		where 1 = 1
		--and WorkingStatus = 4
		--and charindex('INV', WorkingSource) > 0
		
	open @reccounts

	fetch next from @reccounts into @supplierid, @countdate

	while @@FETCH_STATUS = 0
		begin
				
			select @createzerocountrecords = CreateZeroCountRecordsForMissingProductCounts
			--select * 
			from Suppliers
			where SupplierID = @supplierid

			if @createzerocountrecords = 1
				begin

			select distinct storeid
			--select * --778 records out of possible 
			into #temp
			from StoreTransactions_Working
			where 1 = 1
			--and WorkingStatus = 4
			and charindex('INV', WorkingSource) > 0
			--and WorkingSource = 'INV'
			and SupplierID = @supplierid
			and CAST(SaleDateTime as date) = @countdate
			and SaleDateTime > '11/30/2011'

			select distinct storeid, ProductId
			into #temp2
			from StoreTransactions
			where TransactionTypeID in (2, 5, 8, 11)
			and SupplierID = @supplierid
			and StoreID in (select StoreID from #temp)
			and cast(SaleDateTime as date) <= @countdate
			and SaleDateTime > '11/30/2011'
			--and StoreID in (select StoreID from stores where LTRIM(rtrim(custom1)) = 'Albertsons - SCAL')

			--declare @supplierid int=41464 declare @countdate date='12/10/2011'

			select two.* 
			into #temp3
			from #temp2 two
			left join StoreTransactions_Working w
			on two.StoreID = w.StoreID
			and two.ProductID = w.productid
			and charindex('INV', WorkingSource) > 0
			--and w.WorkingSource = 'INV'
			and w.SupplierID = @supplierid
			and CAST(w.SaleDateTime as date) = @countdate
			where w.storetransactionid is null
			order by w.StoreTransactionID

			--select * from #temp3

			--declare @supplierid int=40562 declare @countdate date='12/6/2011'

			INSERT INTO [DataTrue_Main].[dbo].[StoreTransactions_Working]
					   ([ChainID]
					   ,[StoreID]
					   ,[ProductID]
					   ,[SupplierID]
					   ,[BrandID]
					   ,[Qty]
					   ,[SaleDateTime]
					   ,[UPC]
					   ,[SourceID]
					   ,[LastUpdateUserID]
					   ,[WorkingSource]
					   ,[WorkingStatus]
					   ,[Storeidentifier])
					select 40393
						,Storeid
						,t.ProductID
						,@supplierid
						,0
						,0
						,@countdate
						,i.IdentifierValue
						,0
						,0
						,'INV'
						,4
						,''
					from #temp3 t
					inner join ProductIdentifiers i
					on t.ProductID = i.ProductID
					and i.ProductIdentifierTypeID = 2
			end
				fetch next from @reccounts into @supplierid, @countdate

		end
		
	close @reccounts
deallocate @reccounts

		commit transaction

	
end try
	
begin catch
		rollback transaction
		
		set @loadstatus = -9997
		
		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		

		update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID
		from #tempStoreTransaction tmp
		inner join [dbo].[StoreTransactions_Working] t
		on tmp.StoreTransactionID = t.StoreTransactionID		
		
end catch

	
/*
--declare @supplierid int=40562 declare @countdate date='12/6/2011'

select top 500 *
from StoreTransactions_Working
order by storetransactionid desc

select top 500 *
from StoreTransactions
order by storetransactionid desc

select top 1 *
from StoreTransactions_Working w
where w.WorkingSource = 'INV-BOD'
and w.SupplierID = @supplierid
and CAST(w.SaleDateTime as date) = @countdate

drop table #temp
drop table #temp2

select * from #temp a inner join #temp2 b on a.storeid = b.storeid

select distinct saledatetime
from storetransactions_working
where transactiontypeid = 11
and supplierid = 40562
order by saledatetime

select distinct saledatetime
from storetransactions
where transactiontypeid = 11
and supplierid = 40562
and saledatetime >= '1/20/2012'
and transactionstatus = 0
order by saledatetime

select saledatetime, count(storetransactionid)
from storetransactions_working
where transactiontypeid = 11
and supplierid = 40562
group by saledatetime
order by saledatetime
*/

return
GO
