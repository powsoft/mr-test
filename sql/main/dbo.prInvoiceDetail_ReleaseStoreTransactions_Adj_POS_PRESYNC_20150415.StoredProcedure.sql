USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoiceDetail_ReleaseStoreTransactions_Adj_POS_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prInvoiceDetail_ReleaseStoreTransactions_Adj_POS_PRESYNC_20150415]

As
/*
select distinct sourceid from storetransactions order by sourceid desc
*/
declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @MyID int

set @MyID = 24134

begin try 

begin transaction

select StoreTransactionID 
into #tempStoreTransactions 
--select * 
from StoreTransactions
where 1 = 1
--and SourceID in (1466) --1379, 1380, 1383)
and CAST(saledatetime as date) >= '12/1/2011'
--and CAST(saledatetime as date) in ('12/13/2011','12/14/2011','12/15/2011')
--and CAST(saledatetime as date) in ('12/13/2011')
--and cast(DateTimeCreated as date) >= '7/14/2014'
and isnull(RuleCost,0) <> 0 
and Qty <> 0
--and TransactionTypeID in (select TransactionTypeID from TransactionTypes where BillableTransactionType = 1)
and TransactionStatus in (0, 2)
--and TransactionTypeID in (2,6)
and TransactionTypeID in (7,16)
--and TransactionTypeID in (17)
and InvoiceBatchID is null
and cast(datetimecreated as date) >= '03/5/2015'
--and StoreID in 
--(select StoreID from stores where Custom1 = 'Shop N Save Warehouse Foods Inc')


/*
(
(TransactionStatus = 2 and TransactionTypeID not in (10,11))
or
(TransactionStatus = 0 and TransactionTypeID in (2,4,5,6,7,8,9,14,16,17,18,19,20,21,22,23))
)
--select top 22000 * from storetransactions order by storetransactionid desc
--*/
--***************************Look for Multiple Instances***************************************
declare @recremovedupes cursor
declare @reconeassignmentsaledate cursor
declare @remtransactionid bigint
declare @remstoreid int
declare @remproductid int
declare @rembrandid int
declare @remsaledate date
declare @curstoreid int
declare @curproductid int
declare @curbrandid int
declare @cursaledate date
declare @firstrowpassed bit
declare @transactiontypeid int
declare @storetransactionid bigint
declare @reportedcostcompare money
declare @setupcostcompare money
declare @rulecostcompare money
declare @rulecosthold money
declare @setupcosthold money
declare @reportedcosthold money
declare @truecostcompare money
declare @rulecostdiffers bit
declare @reportedcostdiffers bit
declare @costdifferenceresolved bit
/*			
set @recremovedupes = CURSOR local fast_forward FOR
	select distinct w.storeid
		,w.productid
		,w.brandid
		,cast(w.saledatetime as date)
		,transactiontypeid
	from storetransactions w
	inner join #tempStoreTransactions tmp
	on w.storetransactionid = tmp.storetransactionid
	where tmp.StoreTransactionID in
	(
	select storetransactionid
	from storetransactions w
	inner join
		(select storeid, productid, brandid, cast(saledatetime as date) as [date]
		from storetransactions
		where transactiontypeid in (2,4,5,6,7,8,9,14,16,17,18,19,20,21,22,23)
		and InvoiceBatchID is null
		group by storeid, productid, brandid, cast(saledatetime as date), transactiontypeid
		having count(storetransactionid) > 1) s
	on w.storeid = s.storeid and w.productid = s.productid and w.brandid = s.brandid and cast(w.saledatetime as date) = cast(s.date as date)
	)
	order by w.storeid
		,w.productid
		,w.brandid
		,cast(w.saledatetime as date)
	
	open @recremovedupes
	
	fetch next from @recremovedupes into --@remtransactionid
										@remstoreid
										,@remproductid
										,@rembrandid
										,@remsaledate
										,@transactiontypeid
										
	while @@FETCH_STATUS = 0
		begin
		
			set @costdifferenceresolved = 0
			
			set @reconeassignmentsaledate = CURSOR local fast_forward FOR
				select t.StoreTransactionID, ReportedCost, SetupCost, RuleCost, TrueCost
				from #tempStoreTransactions tmp
				inner join StoreTransactions t
				on tmp.StoreTransactionID = t.StoreTransactionID
				where t.StoreID = @remstoreid
				and t.ProductID = @remproductid
				and t.BrandID = @rembrandid
				and cast(t.SaleDateTime as Date) = @remsaledate
				and t.TransactionTypeID = @transactiontypeid
				
			open @reconeassignmentsaledate
			
			fetch next from @reconeassignmentsaledate into
				@storetransactionid
				,@reportedcostcompare
				,@setupcostcompare
				,@rulecostcompare
				,@truecostcompare
				
				set @rulecosthold = @rulecostcompare
				set @setupcosthold = @setupcostcompare
				set @reportedcosthold = @reportedcostcompare
				set @rulecostdiffers = 0
				set @reportedcostdiffers = 0
					
				
			while @@FETCH_STATUS = 0
				begin
					
					if @rulecostcompare is null
						begin
							set @rulecostdiffers = 1
						end

					if @reportedcostcompare is null
						begin
							set @reportedcostdiffers = 1
						end

					fetch next from @reconeassignmentsaledate into
						@storetransactionid
						,@reportedcostcompare
						,@setupcostcompare
						,@rulecostcompare
						,@truecostcompare	
						
					if @setupcostcompare is not null
						begin
							set @setupcosthold = @setupcostcompare	
						end
						
					if @rulecostcompare <> 	@rulecosthold
						begin
							set @rulecostdiffers = 1
						end
								
					if @reportedcostcompare <> 	@reportedcosthold
						begin
							set @reportedcostdiffers = 1
						end
										end
				
				if @rulecostdiffers = 1
					begin
						if @setupcostcompare is not null
							begin
								update t set t.RuleCost = @setupcostcompare
								from #tempStoreTransactions tmp
								inner join StoreTransactions t
								on tmp.StoreTransactionID = t.StoreTransactionID
								where t.StoreID = @remstoreid
								and t.ProductID = @remproductid
								and t.BrandID = @rembrandid
								and cast(t.SaleDateTime as Date) = @remsaledate
								and t.TransactionTypeID = @transactiontypeid
								
								set @costdifferenceresolved = 1							
							end
						else
							begin
								--look at reported and if all equal use it
								if @reportedcostdiffers = 0
									begin
										update t set t.RuleCost = @reportedcostcompare
										from #tempStoreTransactions tmp
										inner join StoreTransactions t
										on tmp.StoreTransactionID = t.StoreTransactionID
										where t.StoreID = @remstoreid
										and t.ProductID = @remproductid
										and t.BrandID = @rembrandid
										and cast(t.SaleDateTime as Date) = @remsaledate
										and t.TransactionTypeID = @transactiontypeid
										
										set @costdifferenceresolved = 1										
									end							
							end
						if @costdifferenceresolved = 0
							begin
								set @errormessage = 'Multiple cost values found for single saledate assignment.  Multiple records for the same saledate assignment are being loaded at the same time and a cost difference could not be resolved.  Records in the StoreTransactions have been pended to a status of -801.'
								set @errorlocation = 'Invalid cost data found during execution of prInvoiceDetail_ReleaseStoreTransactions'
								set @errorsenderstring = 'prInvoiceDetail_ReleaseStoreTransactions'
								
								exec dbo.prLogExceptionAndNotifySupport
								3 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
								,@errorlocation
								,@errormessage
								,@errorsenderstring
								,@MyID	
								
										update t set t.TransactionStatus = -801
										from #tempStoreTransactions tmp
										inner join StoreTransactions t
										on tmp.StoreTransactionID = t.StoreTransactionID
										where t.StoreID = @remstoreid
										and t.ProductID = @remproductid
										and t.BrandID = @rembrandid
										and cast(t.SaleDateTime as Date) = @remsaledate
										and t.TransactionTypeID = @transactiontypeid								
													
							end
					end

			
			close @reconeassignmentsaledate
			deallocate @reconeassignmentsaledate
			
			delete from #tempStoreTransactions
			where StoreTransactionID in
			(
				select StoreTransactionID from StoreTransactions
				where StoreID = @remstoreid
				and ProductID = @remproductid
				and BrandID = @rembrandid
				and CAST(saledatetime as DATE) =  @remsaledate
				and transactiontypeid = @transactiontypeid --in (2,6,7,16,5,8,17,18)
				and InvoiceBatchID is null
			 )
			and StoreTransactionID not in
			(
				select top 1 StoreTransactionID from StoreTransactions
				where StoreID = @remstoreid
				and ProductID = @remproductid
				and BrandID = @rembrandid
				and CAST(saledatetime as DATE) =  @remsaledate
				and transactiontypeid = @transactiontypeid --in (2,6,7,16,5,8,17,18)
				and InvoiceBatchID is null
				order by StoreTransactionID
			 )
			 							
			fetch next from @recremovedupes into --@remtransactionid
										@remstoreid
										,@remproductid
										,@rembrandid
										,@remsaledate	
										,@transactiontypeid
		end
		
	close @recremovedupes
	deallocate @recremovedupes
	*/
--******************Multiple Instances End**********************************





--begin transaction

update t
set transactionstatus = case when transactionstatus = 2 then 800 else 801 end
from  StoreTransactions t
inner join #tempStoreTransactions tmp
on t.StoreTransactionID = tmp.StoreTransactionID
where TransactionStatus <> -801
and 
(
(TransactionStatus = 2 and TransactionTypeID not in (10,11))
or
(TransactionStatus = 0 and TransactionTypeID in (2,4,5,6,7,8,9,14,16,17,18,19,20,21,22,23))
)     
     
commit transaction
	
end try
	
begin catch
		rollback transaction
		
		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
end catch
GO
