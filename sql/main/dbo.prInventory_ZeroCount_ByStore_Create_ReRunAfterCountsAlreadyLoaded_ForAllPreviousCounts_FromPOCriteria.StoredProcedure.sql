USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInventory_ZeroCount_ByStore_Create_ReRunAfterCountsAlreadyLoaded_ForAllPreviousCounts_FromPOCriteria]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prInventory_ZeroCount_ByStore_Create_ReRunAfterCountsAlreadyLoaded_ForAllPreviousCounts_FromPOCriteria]
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
declare @supplierid int=44246
declare @countdate date
declare @reccounts cursor
declare @rec cursor


	set @rec = CURSOr local fast_forward FOR
		select distinct CAST(SaleDateTime as date)
		from StoreTransactions
		where SupplierID=44246
		and TransactionTypeID=11
		and CAST(SaleDateTime as date)>'2013-04-01'
		order by CAST(SaleDateTime as date)
		--and WorkingStatus = 4
		--and charindex('INV', WorkingSource) > 0
		
	open @rec

	fetch next from @rec into  @countdate

	while @@FETCH_STATUS = 0
		begin
	print @countdate;

begin try

	select distinct StoreTransactionID
	into #tempStoreTransaction
	--select *
	from [StoreTransactions]
	where 1 = 1
	--and WorkingStatus = 4
	and TransactionTypeID = 11
	--and charindex('INV', WorkingSource) > 0
	and SaleDateTime = @countdate
	and SupplierID = @supplierid

	begin transaction


	set @reccounts = CURSOr local fast_forward FOR
		select distinct SupplierID, CAST(saledatetime as date)
		from StoreTransactions w
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
			from StoreTransactions
			where 1 = 1
			--and WorkingStatus = 4
			and TransactionTypeID = 11
			--and charindex('INV', WorkingSource) > 0
			--and WorkingSource = 'INV'
			and SupplierID = @supplierid
			and CAST(SaleDateTime as date) = @countdate
			and SaleDateTime > '11/30/2011'

			select distinct ss.storeid, ss.ProductId
			into #temp2
			from storesetup ss
			inner join PO_Criteria c
			on ss.StoreSetupID = c.StoreSetupID
			and SupplierID = @supplierid
			and StoreID in (select StoreID from #temp)
			--and cast(SaleDateTime as date) <= @countdate
			--and SaleDateTime > '11/30/2011'
			--and StoreID in (select StoreID from stores where LTRIM(rtrim(custom1)) = 'Albertsons - SCAL')

			--declare @supplierid int=41464 declare @countdate date='12/10/2011'

			select two.* 
			into #temp3
			from #temp2 two
			left join storetransactions w
			on two.StoreID = w.StoreID
			and two.ProductID = w.productid
			and w.TransactionTypeID = 11
			--and charindex('INV', WorkingSource) > 0
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
					select 44199
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
		print @errormessage;
		--exec dbo.prLogExceptionAndNotifySupport
		--1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		--,@errorlocation
		--,@errormessage
		--,@errorsenderstring
		--,@MyID
		

		--update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID
		--from #tempStoreTransaction tmp
		--inner join [dbo].[StoreTransactions_Working] t
		--on tmp.StoreTransactionID = t.StoreTransactionID		
		
end catch


		
		
		
		drop table #tempStoreTransaction
		drop table #temp3
		drop table #temp2
		drop table #temp
		fetch next from @rec into  @countdate

end
close @rec
deallocate @rec	

return
GO
