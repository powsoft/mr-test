USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInventory_ZeroCount_ByStore_Create_Rules_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prInventory_ZeroCount_ByStore_Create_Rules_PRESYNC_20150415]
--@supplierid int
--,@countdate date

as


declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 41714
declare @createzerocountrecords bit
declare @CreateZeroCountUsingSourceIDNotSaleDateTime bit
declare @supplierid int
declare @ChainID int
declare @SourceID int
declare @reccounts cursor
declare @countdate date
declare @sourcedate date
DECLARE @ProcessID INT



begin try

--SET PROCESS ID
	
	SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobName = 'LoadInventoryCount'
	
	select distinct StoreTransactionID
	into #tempStoreTransaction
	from [dbo].[StoreTransactions_Working] with (nolock)
	where 1 = 1
	and WorkingStatus = 4
	and charindex('INV', WorkingSource) > 0
	--and EDIName='BIM'
	--and SupplierID = 40557
	--and CAST(saledatetime as date) = '3/26/2012'
	--and SaleDateTime = @countdate

	begin transaction


	set @reccounts = CURSOr local fast_forward FOR
		select w.ChainID,w.SupplierID, w.SourceID,Min(Cast(w.DateTimeSourceReceived as date)) --CAST(saledatetime as date)
		from StoreTransactions_Working w with (nolock)
		inner join #tempStoreTransaction t
		on w.StoreTransactionID = t.StoreTransactionID
		join DataTrue_Main.dbo.InventoryRulesTimesBySupplierID r
		on w.SupplierID=r.SupplierID and w.ChainID=r.ChainID
		where 1 = 1
		and r.CreateZeroCountUsingSourceIDNotSaleDateTime=1
		and WorkingStatus = 4 
		and charindex('INV', WorkingSource) > 0
		group by w.ChainID,w.SupplierID, w.SourceID
		order by SourceID
		
	open @reccounts

	fetch next from @reccounts into @ChainID,@supplierid, @SourceID,@sourcedate

	while @@FETCH_STATUS = 0
		begin
				
			select @createzerocountrecords = CreateZeroCountRecordsForMissingProductCounts
			--select * 
			from Suppliers
			where SupplierID = @supplierid
			
			if @createzerocountrecords = 1
				begin
					
					select @CreateZeroCountUsingSourceIDNotSaleDateTime=CreateZeroCountUsingSourceIDNotSaleDateTime 
					from DataTrue_Main.dbo.InventoryRulesTimesBySupplierID
					where SupplierID=@supplierid and ChainID=@ChainID
					
						select distinct storeid
						--select * --778 records out of possible 
						into #temp4
						from StoreTransactions_Working with (nolock)
						where 1 = 1
						and WorkingStatus = 4
						and charindex('INV', WorkingSource) > 0
						--and WorkingSource = 'INV'
						and SupplierID = @supplierid
						and ChainID=@ChainID
						and SourceID = @SourceID
						and SaleDateTime > '11/30/2011'

						select distinct storeid, ProductId
						into #temp5
						from StoreTransactions with (nolock)
						where TransactionTypeID in (2, 5, 8, 11)
						and SupplierID = @supplierid
						and ChainID=@ChainID
						and StoreID in (select StoreID from #temp4)
						--and SourceID = @SourceID
						and Cast(SaleDateTime as date) < @sourcedate
						and SaleDateTime > '11/30/2011'
						--and StoreID in (select StoreID from stores where LTRIM(rtrim(custom1)) = 'Albertsons - SCAL')

			--declare @supplierid int=41464 declare @countdate date='12/10/2011'

						select two.*,w.EDIName,w.SourceID,w.SaleDateTime,w.ChainID
						into #temp6
						from #temp5 two
						left join StoreTransactions_Working w with (nolock)
						on two.StoreID = w.StoreID
						and two.ProductID = w.productid
						and charindex('INV', WorkingSource) > 0
						--and w.WorkingSource = 'INV'
						and w.SupplierID = @supplierid
						and ChainID=@ChainID
						and SourceID = @SourceID
						where w.storetransactionid is null
						order by w.StoreTransactionID
					
					update #temp6 set EDIName=(select uniqueEdiname 
					from suppliers where SupplierID=@supplierid)
					
					--select w.ChainID,w.StoreID, min(w.SaleDateTime) as "SaleDateTime" into #temp7
					--from StoreTransactions_Working w join #temp6 t
					--on w.StoreID=t.StoreID and w.ProductID=t.ProductID
					--where w.SourceID=@SourceID and w.SupplierID=@supplierid
					--and w.ChainID=@ChainID
					--group by w.ChainID,w.StoreID
					
					select w.StoreID, w.SaleDateTime,COUNT(w.ProductID) as "TotalProduct" into #temp7
					from StoreTransactions_Working w with (nolock) 
					join #temp6 t
					on w.StoreID=t.StoreID --and w.ProductID=t.ProductID
					and w.SourceID=@SourceID and w.SupplierID=@supplierid
					and w.ChainID=@ChainID
					group by  w.StoreID, w.SaleDateTime
					order by w.StoreID,w.SaleDateTime 
					
					select StoreID,MAX("TotalProduct") as "TotalProduct",Cast('' as Date) as "SaleDateTime"
					into #temp8
					from #temp7
					group by StoreID
					
					update t8 set t8.SaleDateTime =t7.SaleDateTime
					from #temp7 t7 join #temp8 t8
					on t7.StoreID=t8.StoreID
					and t7.TotalProduct=t8.TotalProduct
					
					--select w.ChainID,w.StoreID, min(w.SaleDateTime) as "SaleDateTime" into #temp7
					--from StoreTransactions_Working w with (nolock) 
					--join #temp6 t
					--on w.StoreID=t.StoreID --and w.ProductID=t.ProductID
					--and w.SourceID=@SourceID and w.SupplierID=@supplierid
					--and w.ChainID=@ChainID
					--group by w.ChainID,w.StoreID
				
				update t2 set t2.SaleDateTime=t1.SaleDateTime
				from #temp8 t1 join #temp6 t2 on t1.StoreID=t2.StoreID 
				drop table #temp7
					
					drop table #temp8

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
							   ,[Storeidentifier]
							   ,SourceIdentifier
							   ,[EdiName]
							   ,[ProcessID])
							select @ChainID
								,t.Storeid
								,t.ProductID
								,@supplierid
								,0
								,0
								,t.SaleDateTime
								,i.IdentifierValue
								,25678
								,0
								,'INV'
								,4
								,''
								,'prInventory_ZeroCount_ByStore_Create_Rules'
								,EDIName
								,@ProcessID
							from #temp6 t 
							--join #temp7 w on t.StoreID=w.StoreID
							inner join ProductIdentifiers i
							on t.ProductID = i.ProductID
							and i.ProductIdentifierTypeID = 2
							
							drop table #temp4
							drop table #temp5
							drop table #temp6
							--drop table #temp7
			end
				fetch next from @reccounts into @ChainID,@supplierid, @SourceID,@sourcedate

		end
		
	close @reccounts
deallocate @reccounts

	

	set @reccounts = CURSOr local fast_forward FOR
		select distinct w.ChainID,w.SupplierID, CAST(saledatetime as date)
		from StoreTransactions_Working w with (nolock)
		inner join #tempStoreTransaction t
		on w.StoreTransactionID = t.StoreTransactionID
		join DataTrue_Main.dbo.InventoryRulesTimesBySupplierID r
		on w.SupplierID=r.SupplierID and w.ChainID=r.ChainID
		where 1 = 1
		and r.CreateZeroCountUsingSourceIDNotSaleDateTime=0
		and WorkingStatus = 4
		and charindex('INV', WorkingSource) > 0
		order by CAST(saledatetime as date)
		
	open @reccounts

	fetch next from @reccounts into @ChainID, @supplierid, @countdate

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
			from StoreTransactions_Working with (nolock)
			where 1 = 1
			and WorkingStatus = 4
			and charindex('INV', WorkingSource) > 0
			--and WorkingSource = 'INV'
			and SupplierID = @supplierid
			and ChainID=@ChainID
			and CAST(SaleDateTime as date) = @countdate
			and SaleDateTime > '11/30/2011'

			select distinct storeid, ProductId
			into #temp2
			from StoreTransactions with (nolock)
			where TransactionTypeID in (2, 5, 8, 11) 
			and SupplierID = @supplierid and ChainID=@ChainID
			and StoreID in (select StoreID from #temp)
			and cast(SaleDateTime as date) <= @countdate
			and SaleDateTime > '11/30/2011'
			--and StoreID in (select StoreID from stores where LTRIM(rtrim(custom1)) = 'Albertsons - SCAL')

			--declare @supplierid int=41464 declare @countdate date='12/10/2011'

			select two.*,w.EDIName
			into #temp3
			from #temp2 two
			left join StoreTransactions_Working w with (nolock)
			on two.StoreID = w.StoreID
			and two.ProductID = w.productid
			and charindex('INV', WorkingSource) > 0
			--and w.WorkingSource = 'INV'
			and w.SupplierID = @supplierid and w.ChainID=@ChainID
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
					   ,[Storeidentifier]
					   ,SourceIdentifier
					   ,[EdiName]
					   ,[ProcessID])
					select @ChainID
						,Storeid
						,t.ProductID
						,@supplierid
						,0
						,0
						,@countdate
						,i.IdentifierValue
						,25678
						,0
						,'INV'
						,4
						,''
						,'prInventory_ZeroCount_ByStore_Create_Rules'
						,EDIName
						,@ProcessID
					from #temp3 t
					inner join ProductIdentifiers i
					on t.ProductID = i.ProductID
					and i.ProductIdentifierTypeID = 2
					
					drop table #temp
					drop table #temp2
					drop table #temp3
			end
				fetch next from @reccounts into @ChainID,@supplierid, @countdate

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
		
		
		UPDATE 	DataTrue_Main.dbo.JobRunning
		SET JobIsRunningNow = 0
		WHERE JobName = 'LoadInventoryCount'	
	
		exec [msdb].[dbo].[sp_stop_job] 
		@job_name = 'LoadInventoryCount'

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Load Inventory Job Stopped at zero count creation'
				,'Inventory count load has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;edi@icontroldsd.com;mandeep@amebasoftwares.com'
		
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
