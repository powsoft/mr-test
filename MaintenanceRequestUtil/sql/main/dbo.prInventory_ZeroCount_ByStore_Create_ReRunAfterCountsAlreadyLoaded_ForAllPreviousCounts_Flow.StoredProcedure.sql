USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInventory_ZeroCount_ByStore_Create_ReRunAfterCountsAlreadyLoaded_ForAllPreviousCounts_Flow]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prInventory_ZeroCount_ByStore_Create_ReRunAfterCountsAlreadyLoaded_ForAllPreviousCounts_Flow]
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
declare @supplierid int=40562
declare @ChainID int=40393
declare @countdate date
declare @EdiName nvarchar(10)
declare @reccounts cursor
declare @rec cursor

select @EdiName=EDIName from Suppliers where SupplierID=@supplierid



	set @rec = CURSOr local fast_forward FOR
	--declare @supplierid int=40567;declare @ChainID int=60620
		select distinct CAST(SaleDateTime as date)
		from StoreTransactions with (nolock)
		where SupplierID=@supplierid and ChainID=@ChainID
		and TransactionTypeID=11
		and CAST(SaleDateTime as date)>='3/15/2015'
		--and CAST(SaleDateTime as date)<='12/31/2013'
		--and StoreID in (select StoreID from Stores where Custom1='A.J.s')
		order by CAST(SaleDateTime as date)
		--and WorkingStatus = 4
		--and charindex('INV', WorkingSource) > 0
		
	open @rec

	fetch next from @rec into  @countdate

	while @@FETCH_STATUS = 0
		begin
	print @countdate;
--drop table #tempStoreTransaction
begin try
	--declare @supplierid int=40567;declare @ChainID int=60620;declare @CountDate datetime='12/27/2013'
	select distinct StoreTransactionID
	into #tempStoreTransaction
	--select *
	from [StoreTransactions] with (nolock)
	where 1 = 1
	--and WorkingStatus = 4
	and TransactionTypeID = 11
	--and charindex('INV', WorkingSource) > 0
	and SaleDateTime = @countdate
	and SupplierID = @supplierid and ChainID=@ChainID
	--and StoreID in (select StoreID from Stores where Custom1='A.J.s')
		
	begin transaction


	set @reccounts = CURSOr local fast_forward FOR
	--declare @supplierid int=40567;declare @ChainID int=60620;declare @CountDate datetime='12/27/2013'
		select distinct ChainID, SupplierID, CAST(saledatetime as date)
		from StoreTransactions w with (nolock)
		inner join #tempStoreTransaction t
		on w.StoreTransactionID = t.StoreTransactionID
		where 1 = 1
		--and WorkingStatus = 4
		--and charindex('INV', WorkingSource) > 0
		
	open @reccounts

	fetch next from @reccounts into @ChainID,@supplierid, @countdate

	while @@FETCH_STATUS = 0
		begin
				
			select @createzerocountrecords = CreateZeroCountRecordsForMissingProductCounts
			--select * 
			from Suppliers
			where SupplierID = @supplierid
			--drop table #temp
set @createzerocountrecords=1
			if @createzerocountrecords = 1
				begin
--declare @supplierid int=40567;declare @ChainID int=60620;declare @CountDate datetime='12/27/2013'
			select distinct storeid
			--select * --778 records out of possible 
			into #temp
			from StoreTransactions with (nolock)
			where 1 = 1
			--and WorkingStatus = 4
			and TransactionTypeID = 11
			--and charindex('INV', WorkingSource) > 0
			--and WorkingSource = 'INV'
			and SupplierID = @supplierid and ChainID=@ChainID
			and CAST(SaleDateTime as date) = @countdate
			and SaleDateTime > '11/30/2011'
			--and StoreID in (select StoreID from Stores where Custom1='Farm Fresh Markets')
		
--declare @supplierid int=40567;declare @ChainID int=60620;declare @CountDate datetime='12/27/2013'
			select distinct storeid, ProductId
			into #temp2
			from StoreTransactions with (nolock)
			where TransactionTypeID in (2, 5, 8, 11)
			and SupplierID = @supplierid
			and ChainID=@ChainID
			and StoreID in (select StoreID from #temp )
			and cast(SaleDateTime as date) <= @countdate
			and SaleDateTime > '11/30/2011'
			--and StoreID in (select StoreID from stores where LTRIM(rtrim(custom1)) = 'Albertsons - SCAL')

			--declare @supplierid int=41464 declare @countdate date='12/10/2011'
--declare @supplierid int=40567;declare @ChainID int=60620;declare @CountDate datetime='12/27/2013'
			select two.* 
			into #temp3
			from #temp2 two
			left join storetransactions w with (nolock)
			on two.StoreID = w.StoreID
			and two.ProductID = w.productid
			and w.TransactionTypeID = 11
			--and charindex('INV', WorkingSource) > 0
			--and w.WorkingSource = 'INV'
			and w.SupplierID = @supplierid and ChainID=@ChainID
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
					   ,[EdiName])
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
						,@EdiName
					from #temp3 t
					inner join ProductIdentifiers i
					on t.ProductID = i.ProductID
					and i.ProductIdentifierTypeID = 2
					
					
		
		
		drop table #temp3
		drop table #temp2
		drop table #temp
		
			end
				fetch next from @reccounts into @ChainID, @supplierid, @countdate

		end
		
	close @reccounts
deallocate @reccounts

		commit transaction
		
		drop table #tempStoreTransaction
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


		
		
		fetch next from @rec into  @countdate

end
close @rec
deallocate @rec	

return
GO
