USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[ZNU_Rollback_20111006_prInventory_FIFO_ProcessTransactions]    Script Date: 06/25/2015 18:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[ZNU_Rollback_20111006_prInventory_FIFO_ProcessTransactions]

as

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @MyID int
set @MyID = 0

declare @rec cursor
declare @transactionid bigint
declare @storeid int
declare @productid int
declare @brandid int
declare @rec1qty int
declare @rec1cost money
declare @rec1availableqty int
declare @saledate date
declare @inventorycostid int
declare @receivedatthiscostdate datetime
declare @nextinventorycostid int
declare @lastinventorycostid int
declare @nextcost money
declare @nextqtyavailable int
declare @nextMaxQtyAvailableAtThisCost int
declare @updatenextinventoryrecordasactive tinyint
declare @transactionidtoupdate bigint

begin try

begin transaction

exec prInventoryCost_ActiveCost_Sync

--drop table #tempStoreTransaction
--delivery records
select distinct StoreTransactionID
into #tempStoreTransaction
from [dbo].[StoreTransactions] t
inner join StoreSetup ss
on t.storeid = ss.storeid
and t.productid = ss.productid
and t.brandid = ss.brandid
where TransactionStatus in (0, 811)
and TransactionTypeID in (2,6,7,16,17,18,19,22)
and CostMisMatch = 0
and RetailMisMatch = 0
and Qty <> 0
and t.saledatetime between ss.ActiveStartDate and ss.ActiveLastDate
and ss.InventoryCostMethod = 'FIFO'

--Update all records that stay on the current ActiveCost record
--drop table #tempcostdata
	select t.storeid, t.productid, t.brandid, t.Qty, ic.inventorycostid, ic.cost
	into #tempcostdata
	from InventoryCost ic
	inner join
	(select storeid, productid, brandid, sum(Qty) as Qty
	from Storetransactions st
	inner join #tempStoreTransaction tmp
	on st.StoreTransactionID = tmp.StoreTransactionID
	group by storeid, productid, brandid) t
	on ic.storeid = t.storeid
	and ic.productid = t.productid
	and ic.brandid = t.brandid
	where ic.ActiveCost = 1
	and t.Qty < QtyAvailableAtThisCost
	and t.Qty > 0

	--and case when t.Qty > 0 then t.Qty < QtyAvailableAtThisCost else MaxQtyAvailableAtThisCost - QtyAvailableAtThisCost > abs(t.Qty) end
	insert into #tempcostdata
	select t.storeid, t.productid, t.brandid, t.Qty, ic.inventorycostid, ic.cost
	from InventoryCost ic
	inner join
	(select storeid, productid, brandid, sum(Qty) as Qty
	from Storetransactions st
	inner join #tempStoreTransaction tmp
	on st.StoreTransactionID = tmp.StoreTransactionID
	group by storeid, productid, brandid) t
	on ic.storeid = t.storeid
	and ic.productid = t.productid
	and ic.brandid = t.brandid
	where ic.ActiveCost = 1
	and abs(t.Qty) < MaxQtyAvailableAtThisCost - QtyAvailableAtThisCost
	and t.Qty < 0
	
--select * from #tempcostdata

update t
set InventoryCost = cost, transactionstatus = case when transactiontypeid = 17 then 2 
													when transactiontypeid <> 17 and TransactionStatus = 811 then 11 else 1 end
from #tempStoreTransaction tmp
inner join StoreTransactions t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join #tempcostdata tcd
on t.storeid = tcd.storeid
and t.productid = tcd.productid
and t.brandid = tcd.brandid

update ic
set QtyAvailableAtThisCost = QtyAvailableAtThisCost - Qty
from #tempcostdata tcd
inner join InventoryCost ic
on tcd.inventorycostid = ic.inventorycostid

--Get records that do not stay on the current ActiveCost record
set @rec = cursor local fast_forward for
	select t.storeid, t.productid, t.brandid, t.Qty--, ic.QtyAvailableAtThisCost, 
	--ic.inventorycostid, ic.ReceivedAtThisCostDate, ic.cost
	from InventoryCost ic
	inner join
	(select storeid, productid, brandid, sum(Qty) as Qty
	from Storetransactions st
	inner join #tempStoreTransaction tmp
	on st.StoreTransactionID = tmp.StoreTransactionID
	where 	transactionstatus in (0, 811)
	group by storeid, productid, brandid) t
	on ic.storeid = t.storeid
	and ic.productid = t.productid
	and ic.brandid = t.brandid
	where ic.ActiveCost = 1
	and t.Qty >= QtyAvailableAtThisCost
	union
	select t.storeid, t.productid, t.brandid, t.Qty--, ic.QtyAvailableAtThisCost, 
	--ic.inventorycostid, ic.ReceivedAtThisCostDate, ic.cost
	from Storetransactions t
	inner join #tempStoreTransaction tmp
	on t.StoreTransactionID = tmp.StoreTransactionID
	where t.Qty < 0	
	and InventoryCost is null
	
open @rec

fetch next from @rec into @storeid, @productid, @brandid, @rec1qty--, @rec1availableqty, 
			--@inventorycostid, @receivedatthiscostdate, @rec1cost
--print '1'
--print @@fetch_status
while @@fetch_Status = 0
	begin
		--First take care of the positive qty's
		declare @rec2 cursor
		declare @rec2transactionid bigint
		declare @rec2qty int
						declare @rec3 cursor
						declare @needmorecostrecords tinyint
						declare @remainingqtytocost int
						declare @neednewtransaction tinyint
--*******************************Positive qty's Begin**********************************************
		set @rec2 = cursor local fast_forward for
			select st.storetransactionid, qty
			from Storetransactions st
			inner join #tempStoreTransaction tmp
			on st.StoreTransactionID = tmp.StoreTransactionID
			where storeid = @storeid
			and productid = @productid
			and brandid = @brandid
			and qty > 0
			order by saledatetime
			
		open @rec2
		
		fetch next from @rec2 into @rec2transactionid, @rec2qty
--print '2'
--print @@fetch_status		
		while @@fetch_status = 0
			begin
--print '3'
				--if @rec2qty >= @rec1availableqty
				--	begin
						
						set @rec3 = cursor local fast_forward for
						select inventorycostid, cost, QtyAvailableAtThisCost
						from InventoryCost
						where 1 = 1
						--and ReceivedAtThisCostDate > @receivedatthiscostdate
						and (ActiveCost = 1 or QtyAvailableAtThisCost > 0)
						and storeid = @storeid
						and productid = @productid
						and brandid = @brandid
						order by ReceivedAtThisCostDate
						
						set @needmorecostrecords = 1
						set @updatenextinventoryrecordasactive = 0
						set @remainingqtytocost = @rec2qty
						set @neednewtransaction = 0
						
						open @rec3
						
						fetch next from @rec3 into @nextinventorycostid, @nextcost, @nextqtyavailable
						
						/*
						if @@fetch_status <> 0 --no cost records use last cost and exit
							begin
								select 'Temporary Dummy Code'
							end
						*/
						
						while @@fetch_status = 0 or @needmorecostrecords = 1
							begin
								--if @rec2qty = @rec1availableqty --just zero out and move activecost to next record
								--	begin
								/*
										update InventoryCost set QtyAvailableAtThisCost = 0, ActiveCost = 0
										where InventoryCostID = @inventorycostid
										
										update InventoryCost set ActiveCost = 1
										where InventoryCostID = @nextinventorycostid
										
										update storetransactions set inventorycost = @rec1cost
										where storetransactionid = @rec2transactionid
										
										set @needmorecostrecords = 0
								*/
								--	end
								--else
								--	begin
									if @@fetch_status <> 0
										begin
											update storetransactions set qty = qty + @remainingqtytocost
											where storetransactionid = @transactionidtoupdate
											set @needmorecostrecords = 0
										end
									else
										begin
										--deactivate cost record
										if @remainingqtytocost <= @nextqtyavailable
											begin
											
												if @neednewtransaction = 1
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
																   ,[UPC]
																   ,[SupplierInvoiceNumber]
																   ,[ReportedCost]
																   ,[ReportedRetail]
																   ,[RuleCost]
																   ,[RuleRetail]
																   ,[CostMisMatch]
																   ,[RetailMisMatch]
																   ,[TrueCost]
																   ,[TrueRetail]
																   ,[ActualCostNetFee]
																   ,[TransactionStatus]
																   ,[Reversed]
																   ,[ProcessingErrorDesc]
																   ,[SourceID]
																   ,[Comments]
																   ,[InvoiceID]
																   ,[DateTimeCreated]
																   ,[LastUpdateUserID]
																   ,[DateTimeLastUpdate]
																   ,[WorkingTransactionID]
																   ,[InvoiceBatchID]
																   ,[InventoryCost])
																SELECT [ChainID]
																	  ,[StoreID]
																	  ,[ProductID]
																	  ,[SupplierID]
																	  ,[TransactionTypeID]
																	  ,[ProductPriceTypeID]
																	  ,[BrandID]
																	  ,@remainingqtytocost
																	  ,[SetupCost]
																	  ,[SetupRetail]
																	  ,[SaleDateTime]
																	  ,[UPC]
																	  ,[SupplierInvoiceNumber]
																	  ,[ReportedCost]
																	  ,[ReportedRetail]
																	  ,[RuleCost]
																	  ,[RuleRetail]
																	  ,[CostMisMatch]
																	  ,[RetailMisMatch]
																	  ,[TrueCost]
																	  ,[TrueRetail]
																	  ,[ActualCostNetFee]
																	  ,case when transactiontypeid = 17 then 2 
																		when transactiontypeid <> 17 and TransactionStatus = 811 then 11 
																		else 1 end--case when transactiontypeid = 17 then 2 else 1 end --1 --[TransactionStatus]
																	  ,[Reversed]
																	  ,[ProcessingErrorDesc]
																	  ,[SourceID]
																	  ,isnull([Comments], '') + ' Inventory Spawn From StoreTransactionID: ' + cast(@rec2transactionid as nvarchar)
																	  ,[InvoiceID]
																	  ,[DateTimeCreated]
																	  ,[LastUpdateUserID]
																	  ,[DateTimeLastUpdate]
																	  ,[WorkingTransactionID]
																	  ,[InvoiceBatchID]
																	  ,@nextcost
																  FROM [DataTrue_Main].[dbo].[StoreTransactions]
																  where storetransactionid = @rec2transactionid

														set @transactionidtoupdate = Scope_Identity()
													end
												else
													begin
														--update existing store transaction with cost
														update storetransactions set inventorycost = @nextcost
														where storetransactionid = @rec2transactionid
														set @transactionidtoupdate = @rec2transactionid
													end

																										
												if @remainingqtytocost = @nextqtyavailable
													begin
														--update current cost record as zero qty and not active
														update InventoryCost set QtyAvailableAtThisCost = 0, ActiveCost = 0
														where InventoryCostID = @nextinventorycostid
														set @updatenextinventoryrecordasactive = 1
													end
												else
													begin
														update InventoryCost set QtyAvailableAtThisCost = QtyAvailableAtThisCost - @remainingqtytocost
														where InventoryCostID = @nextinventorycostid
														set @updatenextinventoryrecordasactive = 0
													end
													
												set @remainingqtytocost = 0	
																						

											end
										else --so @rec2qty is > @nextqtyavailable
											begin
											
											
												if @neednewtransaction = 1
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
																   ,[UPC]
																   ,[SupplierInvoiceNumber]
																   ,[ReportedCost]
																   ,[ReportedRetail]
																   ,[RuleCost]
																   ,[RuleRetail]
																   ,[CostMisMatch]
																   ,[RetailMisMatch]
																   ,[TrueCost]
																   ,[TrueRetail]
																   ,[ActualCostNetFee]
																   ,[TransactionStatus]
																   ,[Reversed]
																   ,[ProcessingErrorDesc]
																   ,[SourceID]
																   ,[Comments]
																   ,[InvoiceID]
																   ,[DateTimeCreated]
																   ,[LastUpdateUserID]
																   ,[DateTimeLastUpdate]
																   ,[WorkingTransactionID]
																   ,[InvoiceBatchID]
																   ,[InventoryCost])
																SELECT [ChainID]
																	  ,[StoreID]
																	  ,[ProductID]
																	  ,[SupplierID]
																	  ,[TransactionTypeID]
																	  ,[ProductPriceTypeID]
																	  ,[BrandID]
																	  ,@nextqtyavailable
																	  ,[SetupCost]
																	  ,[SetupRetail]
																	  ,[SaleDateTime]
																	  ,[UPC]
																	  ,[SupplierInvoiceNumber]
																	  ,[ReportedCost]
																	  ,[ReportedRetail]
																	  ,[RuleCost]
																	  ,[RuleRetail]
																	  ,[CostMisMatch]
																	  ,[RetailMisMatch]
																	  ,[TrueCost]
																	  ,[TrueRetail]
																	  ,[ActualCostNetFee]
																	  ,case when transactiontypeid = 17 then 2 
																		when transactiontypeid <> 17 and TransactionStatus = 811 then 11 
																		else 1 end--case when transactiontypeid = 17 then 2 else 1 end --1 --[TransactionStatus]
																	  ,[Reversed]
																	  ,[ProcessingErrorDesc]
																	  ,[SourceID]
																	  ,isnull([Comments], '') + ' Inventory Spawn From StoreTransactionID: ' + cast(@rec2transactionid as nvarchar)
																	  ,[InvoiceID]
																	  ,[DateTimeCreated]
																	  ,[LastUpdateUserID]
																	  ,[DateTimeLastUpdate]
																	  ,[WorkingTransactionID]
																	  ,[InvoiceBatchID]
																	  ,@nextcost
																  FROM [DataTrue_Main].[dbo].[StoreTransactions]
																  where storetransactionid = @rec2transactionid

														set @transactionidtoupdate = Scope_Identity()
													end	
												else
													begin
														--update existing store transaction with cost and qty
														update storetransactions set inventorycost = @nextcost, qty = @nextqtyavailable
														where storetransactionid = @rec2transactionid	
														set @transactionidtoupdate = @rec2transactionid												
													end										
											
												
												set @neednewtransaction = 1
																										
												set @remainingqtytocost = @remainingqtytocost - @nextqtyavailable	
												
												--update current cost record as zero qty and not active
												update InventoryCost set QtyAvailableAtThisCost = 0, ActiveCost = 0
												where InventoryCostID = @nextinventorycostid
												set @updatenextinventoryrecordasactive = 1


											
											end
/*										
										set @remainingqtytocost = @rec1qty - @rec2qty
										
										--update existing store transaction with cost and qty
										update storetransactions set qty = @rec1availableqty, inventorycost = @rec1cost
										where storetransactionid = @rec2transactionid
										
										--insert new store transaction for next cost record up to maximum on record
										if @remainingqtytocost > 
										
										
										update InventoryCost set ActiveCost = 1
										where InventoryCostID = @nextinventorycostid
*/										
										
								--	end
								set @lastinventorycostid = @nextinventorycostid
								fetch next from @rec3 into @nextinventorycostid, @nextcost, @nextqtyavailable
								if @@fetch_status = 0
								  begin
										if @updatenextinventoryrecordasactive = 1
										update InventoryCost set ActiveCost = 1 where InventoryCostID = @nextinventorycostid
										set @updatenextinventoryrecordasactive = 0
									end
								else
									begin
										update InventoryCost set ActiveCost = 1 where InventoryCostID = @lastinventorycostid
										set @updatenextinventoryrecordasactive = 0
									end	
								end --if @@fetch_status <> 0						
							end --while @@fetch_status = 0 or @needmorecostrecords = 1
							
						close @rec3
						deallocate @rec3
						
						set @needmorecostrecords = 1
/*
					end
				else
					begin
					
						update InventoryCost set QtyAvailableAtThisCost = QtyAvailableAtThisCost - @rec2qty
						where InventoryCostID = @inventorycostid
								
						update storetransactions set inventorycost = @rec1cost
						where storetransactionid = @rec2transactionid					
								
					end
*/
				fetch next from @rec2 into @rec2transactionid, @rec2qty
			end
			
		close @rec2
		deallocate @rec2
--*******************************Positive qty's End**********************************************

--*****************************Negative qty's Begin***********************************************
--Now take care of negative values

		set @rec2 = cursor local fast_forward for
			select st.storetransactionid, qty
			from Storetransactions st
			inner join #tempStoreTransaction tmp
			on st.StoreTransactionID = tmp.StoreTransactionID
			where storeid = @storeid
			and productid = @productid
			and brandid = @brandid
			and qty < 0
			order by saledatetime
			
		open @rec2
		
		fetch next from @rec2 into @rec2transactionid, @rec2qty
print '2'
print @@fetch_status		
		while @@fetch_status = 0
			begin
print '3'
				--if @rec2qty >= @rec1availableqty
				--	begin

						
						set @rec3 = cursor local fast_forward for
						select inventorycostid, cost, QtyAvailableAtThisCost, MaxQtyAvailableAtThisCost
						from InventoryCost
						where (ActiveCost = 1 or QtyAvailableAtThisCost > 0)
						--and ReceivedAtThisCostDate > @receivedatthiscostdate
						--and QtyAvailableAtThisCost > 0
						and storeid = @storeid
						and productid = @productid
						and brandid = @brandid
						order by ReceivedAtThisCostDate Desc
						
						set @needmorecostrecords = 1
						set @updatenextinventoryrecordasactive = 0
						set @remainingqtytocost = @rec2qty
						set @neednewtransaction = 0
						
						open @rec3
						
						fetch next from @rec3 into @nextinventorycostid, @nextcost, @nextqtyavailable, @nextMaxQtyAvailableAtThisCost
						/*
						if @@fetch_status <> 0 --no cost records use last cost and exit
							begin
								select 'Temporary Dummy Code'
							end
						*/
						
						while @@fetch_status = 0 or @needmorecostrecords = 1
							begin
								--if @rec2qty = @rec1availableqty --just zero out and move activecost to next record
								--	begin
								/*
										update InventoryCost set QtyAvailableAtThisCost = 0, ActiveCost = 0
										where InventoryCostID = @inventorycostid
										
										update InventoryCost set ActiveCost = 1
										where InventoryCostID = @nextinventorycostid
										
										update storetransactions set inventorycost = @rec1cost
										where storetransactionid = @rec2transactionid
										
										set @needmorecostrecords = 0
								*/
								--	end
								--else
								--	begin
									if @@fetch_status <> 0
										begin
											update storetransactions set qty = qty + @remainingqtytocost
											where storetransactionid = @transactionidtoupdate
											set @needmorecostrecords = 0
										end
									else
										begin
										--deactivate cost record
										if abs(@remainingqtytocost) <= @nextMaxQtyAvailableAtThisCost - @nextqtyavailable
											begin
											
												if @neednewtransaction = 1
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
																   ,[UPC]
																   ,[SupplierInvoiceNumber]
																   ,[ReportedCost]
																   ,[ReportedRetail]
																   ,[RuleCost]
																   ,[RuleRetail]
																   ,[CostMisMatch]
																   ,[RetailMisMatch]
																   ,[TrueCost]
																   ,[TrueRetail]
																   ,[ActualCostNetFee]
																   ,[TransactionStatus]
																   ,[Reversed]
																   ,[ProcessingErrorDesc]
																   ,[SourceID]
																   ,[Comments]
																   ,[InvoiceID]
																   ,[DateTimeCreated]
																   ,[LastUpdateUserID]
																   ,[DateTimeLastUpdate]
																   ,[WorkingTransactionID]
																   ,[InvoiceBatchID]
																   ,[InventoryCost])
																SELECT [ChainID]
																	  ,[StoreID]
																	  ,[ProductID]
																	  ,[SupplierID]
																	  ,[TransactionTypeID]
																	  ,[ProductPriceTypeID]
																	  ,[BrandID]
																	  ,@remainingqtytocost
																	  ,[SetupCost]
																	  ,[SetupRetail]
																	  ,[SaleDateTime]
																	  ,[UPC]
																	  ,[SupplierInvoiceNumber]
																	  ,[ReportedCost]
																	  ,[ReportedRetail]
																	  ,[RuleCost]
																	  ,[RuleRetail]
																	  ,[CostMisMatch]
																	  ,[RetailMisMatch]
																	  ,[TrueCost]
																	  ,[TrueRetail]
																	  ,[ActualCostNetFee]
																	  ,case when transactiontypeid = 17 then 2 
																		when transactiontypeid <> 17 and TransactionStatus = 811 then 11 
																		else 1 end--case when transactiontypeid = 17 then 2 else 1 end --1 --[TransactionStatus]
																	  ,[Reversed]
																	  ,[ProcessingErrorDesc]
																	  ,[SourceID]
																	  ,isnull([Comments], '') + ' Inventory Spawn From StoreTransactionID: ' + cast(@rec2transactionid as nvarchar)
																	  ,[InvoiceID]
																	  ,[DateTimeCreated]
																	  ,[LastUpdateUserID]
																	  ,[DateTimeLastUpdate]
																	  ,[WorkingTransactionID]
																	  ,[InvoiceBatchID]
																	  ,@nextcost
																  FROM [DataTrue_Main].[dbo].[StoreTransactions]
																  where storetransactionid = @rec2transactionid

														set @transactionidtoupdate = Scope_Identity()
													end
												else
													begin
														--update existing store transaction with cost
														update storetransactions set inventorycost = @nextcost
														where storetransactionid = @rec2transactionid
														set @transactionidtoupdate = @rec2transactionid
													end

																										
												if abs(@remainingqtytocost) = @nextMaxQtyAvailableAtThisCost - @nextqtyavailable
													begin
														--update current cost record as zero qty and not active
														update InventoryCost set QtyAvailableAtThisCost = @nextMaxQtyAvailableAtThisCost
														,ActiveCost = 0
														where InventoryCostID = @nextinventorycostid
														set @updatenextinventoryrecordasactive = 1
													end
												else
													begin
														update InventoryCost set QtyAvailableAtThisCost = QtyAvailableAtThisCost - @remainingqtytocost
														where InventoryCostID = @nextinventorycostid
														set @updatenextinventoryrecordasactive = 0
													end
													
												set @remainingqtytocost = 0	
																						

											end
										else --so @rec2qty is > @nextqtyavailable
											begin
											
											
												if @neednewtransaction = 1
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
																   ,[UPC]
																   ,[SupplierInvoiceNumber]
																   ,[ReportedCost]
																   ,[ReportedRetail]
																   ,[RuleCost]
																   ,[RuleRetail]
																   ,[CostMisMatch]
																   ,[RetailMisMatch]
																   ,[TrueCost]
																   ,[TrueRetail]
																   ,[ActualCostNetFee]
																   ,[TransactionStatus]
																   ,[Reversed]
																   ,[ProcessingErrorDesc]
																   ,[SourceID]
																   ,[Comments]
																   ,[InvoiceID]
																   ,[DateTimeCreated]
																   ,[LastUpdateUserID]
																   ,[DateTimeLastUpdate]
																   ,[WorkingTransactionID]
																   ,[InvoiceBatchID]
																   ,[InventoryCost])
																SELECT [ChainID]
																	  ,[StoreID]
																	  ,[ProductID]
																	  ,[SupplierID]
																	  ,[TransactionTypeID]
																	  ,[ProductPriceTypeID]
																	  ,[BrandID]
																	  ,-1 * (@nextMaxQtyAvailableAtThisCost - @nextqtyavailable)
																	  ,[SetupCost]
																	  ,[SetupRetail]
																	  ,[SaleDateTime]
																	  ,[UPC]
																	  ,[SupplierInvoiceNumber]
																	  ,[ReportedCost]
																	  ,[ReportedRetail]
																	  ,[RuleCost]
																	  ,[RuleRetail]
																	  ,[CostMisMatch]
																	  ,[RetailMisMatch]
																	  ,[TrueCost]
																	  ,[TrueRetail]
																	  ,[ActualCostNetFee]
																	  ,case when transactiontypeid = 17 then 2 
																		when transactiontypeid <> 17 and TransactionStatus = 811 then 11 
																		else 1 end--case when transactiontypeid = 17 then 2 else 1 end --1 --[TransactionStatus]
																	  ,[Reversed]
																	  ,[ProcessingErrorDesc]
																	  ,[SourceID]
																	  ,isnull([Comments], '') + ' Inventory Spawn From StoreTransactionID: ' + cast(@rec2transactionid as nvarchar)
																	  ,[InvoiceID]
																	  ,[DateTimeCreated]
																	  ,[LastUpdateUserID]
																	  ,[DateTimeLastUpdate]
																	  ,[WorkingTransactionID]
																	  ,[InvoiceBatchID]
																	  ,@nextcost
																  FROM [DataTrue_Main].[dbo].[StoreTransactions]
																  where storetransactionid = @rec2transactionid

														set @transactionidtoupdate = Scope_Identity()
													end	
												else
													begin
														--update existing store transaction with cost and qty
														update storetransactions set inventorycost = @nextcost, qty = -1 * (@nextMaxQtyAvailableAtThisCost - @nextqtyavailable)
														where storetransactionid = @rec2transactionid
														set @transactionidtoupdate = @rec2transactionid													
													end										
											
												
												set @neednewtransaction = 1
																										
												set @remainingqtytocost = @remainingqtytocost + @nextMaxQtyAvailableAtThisCost - @nextqtyavailable
												
												--update current cost record as zero qty and not active
												update InventoryCost set QtyAvailableAtThisCost = @nextMaxQtyAvailableAtThisCost, ActiveCost = 0
												where InventoryCostID = @nextinventorycostid
												set @updatenextinventoryrecordasactive = 1


											
											end
/*										
										set @remainingqtytocost = @rec1qty - @rec2qty
										
										--update existing store transaction with cost and qty
										update storetransactions set qty = @rec1availableqty, inventorycost = @rec1cost
										where storetransactionid = @rec2transactionid
										
										--insert new store transaction for next cost record up to maximum on record
										if @remainingqtytocost > 
										
										
										update InventoryCost set ActiveCost = 1
										where InventoryCostID = @nextinventorycostid
*/										
										
								--	end
								set @lastinventorycostid = @nextinventorycostid
								fetch next from @rec3 into @nextinventorycostid, @nextcost, @nextqtyavailable, @nextMaxQtyAvailableAtThisCost
								if @@fetch_status = 0
								  begin
										if @updatenextinventoryrecordasactive = 1
										update InventoryCost set ActiveCost = 1 where InventoryCostID = @nextinventorycostid
										set @updatenextinventoryrecordasactive = 0
									end
								else
									begin
										update InventoryCost set ActiveCost = 1 where InventoryCostID = @lastinventorycostid
										set @updatenextinventoryrecordasactive = 0
									end							
								end --if @@fetch_status <> 0						
							end --while @@fetch_status = 0 or @needmorecostrecords = 1
							
						close @rec3
						deallocate @rec3
						
						set @needmorecostrecords = 1
/*
					end
				else
					begin
					
						update InventoryCost set QtyAvailableAtThisCost = QtyAvailableAtThisCost - @rec2qty
						where InventoryCostID = @inventorycostid
								
						update storetransactions set inventorycost = @rec1cost
						where storetransactionid = @rec2transactionid					
								
					end
*/
				fetch next from @rec2 into @rec2transactionid, @rec2qty
			end
			
		close @rec2
		deallocate @rec2
--*****************************Negative qty's End***********************************************




		
		fetch next from @rec into @storeid, @productid, @brandid, @rec1qty--, @rec1availableqty, 
				--@inventorycostid, @receivedatthiscostdate, @rec1cost
	end
	
close @rec
deallocate @rec

update t set TransactionStatus = case when transactionstatus = 811 then 11 else 1 end
	,LastUpdateUserID = @MyID
	,DateTimeLastUpdate = GETDATE()
	from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions] t
on tmp.StoreTransactionID = t.StoreTransactionID
where transactionstatus not in (2, 11)

exec prInventoryCost_ActiveCost_Sync


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
