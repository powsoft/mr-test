USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[ZNU_prApplySUPStoreTransactionsToInventoryCost_TEST20111005]    Script Date: 06/25/2015 18:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[ZNU_prApplySUPStoreTransactionsToInventoryCost_TEST20111005]

as

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @MyID int
set @MyID = 0

declare @storeid int
declare @productid int
declare @brandid int
declare @inventorycostid int
declare @receivedatthiscostdate datetime
declare @nextinventorycostid int
declare @lastinventorycostid int
declare @nextcost money
declare @nextqtyavailable int
declare @nextMaxQtyAvailableAtThisCost int
declare @MaxQtyAvailableAtThisCostAtZeroQty int
declare @updatenextinventoryrecordasactive tinyint
declare @transactionidtoupdate bigint
declare @rec cursor
declare @rec1qty int

begin try

exec prInventoryCost_NewRecords_Collapse
exec prInventoryCost_ActiveCost_Sync

begin transaction

--delivery records
select distinct StoreTransactionID
into #tempStoreTransaction
from [dbo].[StoreTransactions]
where TransactionStatus in (0, 811)
and TransactionTypeID in (4,5,9,20,23)
and CostMisMatch = 0
and RetailMisMatch = 0

--**************************************************************
MERGE INTO [dbo].[InventoryCost] i

USING (SELECT [ChainID]
	  ,[StoreID]
      ,[ProductID]
      ,[BrandID]
      ,cast([SaleDateTime] as date) as EffectiveDate
      ,sum([Qty]) as Qty
      ,[TrueCost] as Cost
      ,max([TrueRetail]) as Retail
      ,max([SaleDateTime]) as EffectiveDateTime
      --,transactiontypeid
  FROM [dbo].[StoreTransactions] t
  inner join #tempStoreTransaction tmp
	on t.StoreTransactionID = tmp.StoreTransactionID
	group by t.chainid, t.storeid, t.productid, t.brandid, t.truecost, t.saledatetime) S
	on i.ChainID = s.ChainID
	and i.StoreID = s.StoreID 
	and i.ProductID = s.ProductID
	and i.BrandID = s.BrandID
	and i.Cost = s.Cost
	and cast(i.ReceivedAtThisCostDate as date) = cast(s.EffectiveDateTime as date)

WHEN MATCHED THEN

update set  QtyAvailableAtThisCost =  QtyAvailableAtThisCost + s.Qty
	,MaxQtyAvailableAtThisCost =  MaxQtyAvailableAtThisCost + s.Qty
	,LastUpdateUserID = @MyID
	,DateTimeLastUpdate = getdate()
--	,EffectiveDateTime = case when s.EffectiveDateTime > i.EffectiveDateTime then s.EffectiveDateTime else i.EffectiveDateTime end

	
WHEN NOT MATCHED 

THEN INSERT 
           ([ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[BrandID]
           ,[QtyAvailableAtThisCost]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[ReceivedAtThisCostDate]
           ,[Cost]
           ,[Retail]
           ,[MaxQtyAvailableAtThisCost])
     VALUES
           (s.[ChainID]
           ,s.[StoreID]
			,s.[ProductID]
			,s.[BrandID]
			,s.Qty
			,@MyID
			,s.[EffectiveDateTime] --getdate()
			,s.EffectiveDateTime
			,s.Cost
			,s.Retail
			,s.Qty);
--**************************************************************

--pickup records
select distinct StoreTransactionID
into #tempStoreTransaction2
from [dbo].[StoreTransactions]
where TransactionStatus in (0, 811)
and TransactionTypeID in (8,13,14,19,21)
and CostMisMatch = 0
and RetailMisMatch = 0

--***********************************************************************************************
--FIFO Pickup Approach Start


--Update all records that stay on the current ActiveCost record
--drop table #tempcostdata
	select t.storeid, t.productid, t.brandid, t.Qty, ic.inventorycostid, ic.cost
	into #tempcostdata
	from InventoryCost ic
	inner join
	(select storeid, productid, brandid, sum(Qty) as Qty
	from Storetransactions st
	inner join #tempStoreTransaction2 tmp
	on st.StoreTransactionID = tmp.StoreTransactionID
	group by storeid, productid, brandid) t
	on ic.storeid = t.storeid
	and ic.productid = t.productid
	and ic.brandid = t.brandid
	where ic.ActiveCost = 1
	and t.Qty < QtyAvailableAtThisCost
	and t.Qty > 0
--select * from #tempcostdata
	--and case when t.Qty > 0 then t.Qty < QtyAvailableAtThisCost else MaxQtyAvailableAtThisCost - QtyAvailableAtThisCost > abs(t.Qty) end
	insert into #tempcostdata
	select t.storeid, t.productid, t.brandid, t.Qty, ic.inventorycostid, ic.cost
	from InventoryCost ic
	inner join
	(select storeid, productid, brandid, sum(Qty) as Qty
	from Storetransactions st
	inner join #tempStoreTransaction2 tmp
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
set InventoryCost = cost, 
transactionstatus = case when TransactionStatus = 811 then 11 else 1 end
from #tempStoreTransaction2 tmp
inner join StoreTransactions t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join #tempcostdata tcd
on t.storeid = tcd.storeid
and t.productid = tcd.productid
and t.brandid = tcd.brandid

update ic
set QtyAvailableAtThisCost = QtyAvailableAtThisCost - Qty
,MaxQtyAvailableAtThisCost = MaxQtyAvailableAtThisCost - Qty
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
	inner join #tempStoreTransaction2 tmp
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
	inner join #tempStoreTransaction2 tmp
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
			inner join #tempStoreTransaction2 tmp
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
						select inventorycostid, cost, QtyAvailableAtThisCost, MaxQtyAvailableAtThisCost
						from InventoryCost
						where 1 = 1
						--and ReceivedAtThisCostDate > @receivedatthiscostdate
						and (QtyAvailableAtThisCost > 0 or ActiveCost = 1)
						and storeid = @storeid
						and productid = @productid
						and brandid = @brandid
						order by ReceivedAtThisCostDate
						
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
																	  ,case when TransactionStatus = 811 then 11 
																		else 1 end
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
														update InventoryCost set QtyAvailableAtThisCost = QtyAvailableAtThisCost - @remainingqtytocost
														,MaxQtyAvailableAtThisCost = MaxQtyAvailableAtThisCost - @remainingqtytocost
														where InventoryCostID = @nextinventorycostid
														/*20111005
														update InventoryCost set QtyAvailableAtThisCost = 0
														, ActiveCost = 0, MaxQtyAvailableAtThisCost = 0
														where InventoryCostID = @nextinventorycostid
														
														20111005*/
														set @updatenextinventoryrecordasactive = 1
													end
												else
													begin
														update InventoryCost set QtyAvailableAtThisCost = QtyAvailableAtThisCost - @remainingqtytocost
														,MaxQtyAvailableAtThisCost = MaxQtyAvailableAtThisCost - @remainingqtytocost
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
																	  ,case when TransactionStatus = 811 then 11 
																		else 1 end
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
												--set @MaxQtyAvailableAtThisCostAtZeroQty = @nextMaxQtyAvailableAtThisCost - @nextqtyavailable
												
												--update current cost record as zero qty and not active
												update InventoryCost set QtyAvailableAtThisCost = 0, ActiveCost = 0
												,MaxQtyAvailableAtThisCost = MaxQtyAvailableAtThisCost - @nextqtyavailable
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
										update InventoryCost set QtyAvailableAtThisCost = QtyAvailableAtThisCost - @remainingqtytocost
										,ActiveCost = 1
										,MaxQtyAvailableAtThisCost = MaxQtyAvailableAtThisCost - @remainingqtytocost
										where InventoryCostID = @lastinventorycostid
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
			inner join #tempStoreTransaction2 tmp
			on st.StoreTransactionID = tmp.StoreTransactionID
			where storeid = @storeid
			and productid = @productid
			and brandid = @brandid
			and qty < 0
			order by saledatetime
			
		open @rec2
		
		fetch next from @rec2 into @rec2transactionid, @rec2qty
--print '2'
print @@fetch_status		
		while @@fetch_status = 0
			begin
--print '3'
				--if @rec2qty >= @rec1availableqty
				--	begin

						
						set @rec3 = cursor local fast_forward for
						select inventorycostid, cost, QtyAvailableAtThisCost, MaxQtyAvailableAtThisCost
						from InventoryCost
						where (ActiveCost = 1 or QtyAvailableAtThisCost = 0)
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
																	  ,case when TransactionStatus = 811 then 11 
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
														,MaxQtyAvailableAtThisCost = MaxQtyAvailableAtThisCost - @remainingqtytocost
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
																	  ,case when TransactionStatus = 811 then 11 
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
										update InventoryCost set MaxQtyAvailableAtThisCost = MaxQtyAvailableAtThisCost - @remainingqtytocost 
										,ActiveCost = 1, QtyAvailableAtThisCost = QtyAvailableAtThisCost - @remainingqtytocost 
										where InventoryCostID = @lastinventorycostid
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
		
		fetch next from @rec into @storeid, @productid, @brandid, @rec1qty
	end

close @rec
deallocate @rec




--FIFO Pickup Approach End
--************************************************************************************************


/* LIFO Pickup Approach Code Start
--**************************************************************
MERGE INTO [dbo].[InventoryCost] i

USING (SELECT [ChainID]
	  ,[StoreID]
      ,[ProductID]
      ,[BrandID]
      ,cast([SaleDateTime] as date) as EffectiveDate
      ,sum([Qty]) as Qty
      ,[TrueCost] as Cost
      ,max([TrueRetail]) as Retail
      ,max([SaleDateTime]) as EffectiveDateTime
      --,transactiontypeid
  FROM [dbo].[StoreTransactions] t
  inner join #tempStoreTransaction2 tmp
	on t.StoreTransactionID = tmp.StoreTransactionID
	group by t.chainid, t.storeid, t.productid, t.brandid, t.truecost, t.saledatetime) S
	on i.ChainID = s.ChainID
	and i.StoreID = s.StoreID 
	and i.ProductID = s.ProductID
	and i.BrandID = s.BrandID
	and i.Cost = s.Cost
	and cast(i.ReceivedAtThisCostDate as date) = cast(s.EffectiveDateTime as date)

WHEN MATCHED THEN

update set  QtyAvailableAtThisCost =  QtyAvailableAtThisCost - s.Qty
	--,MaxQtyAvailableAtThisCost =  MaxQtyAvailableAtThisCost - s.Qty
	,LastUpdateUserID = @MyID
	,DateTimeLastUpdate = getdate()
--	,EffectiveDateTime = case when s.EffectiveDateTime > i.EffectiveDateTime then s.EffectiveDateTime else i.EffectiveDateTime end

	
WHEN NOT MATCHED 

THEN INSERT 
           ([ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[BrandID]
           ,[QtyAvailableAtThisCost]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[ReceivedAtThisCostDate]
           ,[Cost]
           ,[Retail]
           ,[MaxQtyAvailableAtThisCost])
     VALUES
           (s.[ChainID]
           ,s.[StoreID]
			,s.[ProductID]
			,s.[BrandID]
			,-1 * s.Qty
			,@MyID
			,getdate()
			,s.EffectiveDateTime
			,s.Cost
			,s.Retail
			,-1 * s.Qty);
LIFO Pickup Approach Code End*/
--***************************************************************

exec prInventoryCost_NewRecords_Collapse
exec prInventoryCost_ActiveCost_Sync

update t set TransactionStatus = case when transactionstatus = 0 then 1 else 11 end
	,LastUpdateUserID = @MyID
	,DateTimeLastUpdate = GETDATE()
	,Inventorycost = case when costmismatch = 0 and InventoryCost IS null then truecost else InventoryCost end
	from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions] t
on tmp.StoreTransactionID = t.StoreTransactionID
where TransactionStatus not in (1, 11)

update t set TransactionStatus = case when transactionstatus = 0 then 1 else 11 end
	,LastUpdateUserID = @MyID
	,DateTimeLastUpdate = GETDATE()
	,Inventorycost = case when costmismatch = 0 and InventoryCost IS null then truecost else InventoryCost end
	from #tempStoreTransaction2 tmp
inner join [dbo].[StoreTransactions] t
on tmp.StoreTransactionID = t.StoreTransactionID
where TransactionStatus not in (1, 11)

/*
--pickup records
select distinct StoreTransactionID
into #tempStoreTransaction2
from [dbo].[StoreTransactions]
where TransactionStatus = 0
and TransactionTypeID in (8,9,13,21)
and CostMisMatch = 0
and RetailMisMatch = 0
--**************************************************************
MERGE INTO [dbo].[InventoryCost] i

USING (SELECT [ChainID]
	  ,[StoreID]
      ,[ProductID]
      ,[BrandID]
      ,cast([SaleDateTime] as date) as EffectiveDate
      ,sum([Qty]) as Qty
      ,[TrueCost] as Cost
      ,max([TrueRetail]) as Retail
      ,max([SaleDateTime]) as EffectiveDateTime
  FROM [dbo].[StoreTransactions] t
  inner join #tempStoreTransaction tmp
	on t.StoreTransactionID = tmp.StoreTransactionID
	group by t.chainid, t.storeid, t.productid, t.brandid, t.truecost) S
	on i.ChainID = s.ChainID
	and i.StoreID = s.StoreID 
	and i.ProductID = s.ProductID
	and i.BrandID = s.BrandID
	and i.ReceivedAtThisCostDate = s.EffectiveDateTime

WHEN MATCHED THEN

update set  QtyAvailableAtThisCost = QtyAvailableAtThisCost - s.Qty 
	,LastUpdateUserID = @MyID
	,DateTimeLastUpdate = getdate()
--	,EffectiveDateTime = case when s.EffectiveDateTime > i.EffectiveDateTime then s.EffectiveDateTime else i.EffectiveDateTime end

	
WHEN NOT MATCHED 

THEN INSERT 
           ([ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[BrandID]
           ,[QtyAvailableAtThisCost]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[ReceivedAtThisCostDate]
           ,[Cost]
           ,[Retail])
     VALUES
           (s.[ChainID]
           ,s.[StoreID]
			,s.[ProductID]
			,s.[BrandID]
			,s.[Qty]
			,@MyID
			,getdate()
			,s.EffectiveDateTime
			,s.Cost
			,s.Retail);
--**************************************************************
update t set TransactionStatus = 1
	,LastUpdateUserID = @MyID
	,DateTimeLastUpdate = GETDATE()
	from #tempStoreTransaction2 tmp
inner join [dbo].[StoreTransactions] t
on tmp.StoreTransactionID = t.StoreTransactionID

--waitfor delay '0:0:5'

--exec DataTrue_Report..prCDCGetINVStoreTransactions
*/

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
