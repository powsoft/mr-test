USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prApplyINVStoreTransactionsToInventory_PassDateAndSupplier_NOCURSOR]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prApplyINVStoreTransactionsToInventory_PassDateAndSupplier_NOCURSOR]
@tempdate date,
@supplierid int
as
declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @transactionstatus smallint
declare @id as uniqueidentifier
declare @newshrinkrevision int
declare @newcurrentonhandqty int
declare @MyID int
set @MyID = 7599

begin try
--drop table #tempStoreTransaction
select distinct StoreTransactionID
into #tempStoreTransaction
from [dbo].[StoreTransactions]
where TransactionStatus = 0
and TransactionTypeID in (10,11)
and RuleCost is not null
and SupplierID = @supplierid
and CAST(Saledatetime as date) = @tempdate


set @id = NEWID()
set @transactionstatus = 2

begin transaction



--**************************************************************
MERGE INTO [dbo].[InventoryPerpetual] i

USING (SELECT [ChainID], [StoreID]
      ,[ProductID]
      ,[BrandID]
      ,sum([Qty]) as Qty
      ,@id as TempID
      ,tmp.StoreTransactionID
      ,[SaleDateTime]
      ,isnull(max([TrueCost]), isnull(max([RuleCost]), isnull(max([SetupCost]), 0.0))) - isnull(max([PromoAllowance]), 0.00) as Cost
      ,isnull(max([TrueRetail]), isnull(max([RuleRetail]), isnull(max([SetupRetail]), 0.0))) as Retail
  FROM [dbo].[StoreTransactions] t
  inner join #tempStoreTransaction tmp
	on t.StoreTransactionID = tmp.StoreTransactionID
	group by t.chainid, t.storeid, t.productid, t.brandid, tmp.StoreTransactionID, SaleDateTime) S
	--group by t.chainid, t.storeid, t.productid, t.brandid) S
	on i.ChainID = s.ChainID
	and i.StoreID = s.StoreID 
	and i.ProductID = s.ProductID
	and i.BrandID = s.BrandID
/*
WHEN MATCHED THEN

update set  Deliveries = Deliveries + S.Qty
	,CurrentOnHandQty = CurrentOnHandQty + s.Qty 
	,LastUpdateUserID = @MyID
	,DateTimeLastUpdate = getdate()
*/	
WHEN NOT MATCHED 

THEN INSERT 
           ([ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[BrandID]
           ,[OriginalQty]
           ,[Deliveries]
           ,[SBTSales]
           ,[ShrinkRevision]
           ,[CurrentOnHandQty]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[TempID]
           ,[OriginatingStoreTransactionID]
           ,[EffectiveDateTime]
           ,[Cost]
           ,[Retail])
     VALUES
           (s.[ChainID], s.[StoreID]
			,s.[ProductID]
			,s.[BrandID]
			,s.[Qty]
			,0
			,0
			,0
			,s.[Qty]
			,@MyID
			,getdate()
			,s.TempID
			,s.StoreTransactionID
			,s.SaleDateTime
            ,s.[Cost]
            ,s.[Retail]);

  
select distinct tmp.StoreTransactionID
into #tempStoreTransaction2
from [dbo].[StoreTransactions] t
inner join #tempStoreTransaction tmp
on t.StoreTransactionID = tmp.StoreTransactionID
where t.TransactionStatus = 0
and t.TransactionTypeID in (10,11)
and t.StoreTransactionID not in (Select OriginatingStoreTransactionID  from InventoryPerpetual where OriginatingStoreTransactionID is not null)
--and StoreID = 40509
--and ProductID = 5511
and CAST(Saledatetime as date) = @tempdate

declare @rec cursor
declare @storeid int
declare @productid int
declare @brandid int
declare @transactiontypeid int
declare @saledatetime datetime
declare @countqty int
declare @storetransactionid bigint
declare @onhandqty int
declare @salesqtysincecount int
declare @deliveriesqtysincecount int
declare @pickupsqtysincecount int
declare @startdate date
declare @cost money
declare @retail money
declare @countbeforesales bit
declare @countbeforedeliveries bit
declare @countsupplierid int
--declare @storetransactionid int
----------------------------------------------------------------
/*			Start -> New Changes - Use of temp table		  */
----------------------------------------------------------------
	select StoreID, ProductID, BrandID, TransactionTypeID, 
	SaleDateTime, Qty, t.StoreTransactionID, SupplierID,
	CAST(0 as int) as CountBeforeDeliveries,
	CAST(0 as int) as CountBeforeSales,
	CAST(0 as int) as SalesQtySinceCount,
	CAST(0 as int) as DeliveriesQtySinceCount,
	CAST(0 as int) as PickupsQtySinceCount,
	CAST(0 as int) as NewCurrentOnHandQty
	into #tempStoreTransactions
	from [dbo].[StoreTransactions] t
	inner join #tempStoreTransaction2 tmp
	on t.StoreTransactionID = tmp.StoreTransactionID
	
	
--fetch next from @rec into @storeid,@productid,@brandid,@transactiontypeid,@saledatetime,
--@countqty, @storetransactionid, @countsupplierid

	
	update  t set t.CountBeforeDeliveries =  r.InventoryTakenBeforeDeliveries 
	,t.CountBeforeSales = r.InventoryTakenBeginOfDay
	from dbo.InventoryRulesTimesBySupplierID r join #tempStoreTransactions t
	on r.SupplierID = t.SupplierID
	
	update t set t.SalesQtySinceCount = (select ISNULL(SUM(Qty),0)
		from [dbo].[StoreTransactions] s
		where s.StoreID=t.StoreId
		and s.ProductID=t.ProductID
		and s.BrandID = t.BrandID
		and TransactionTypeID in (2,6,7,16) --2 is POS sales
		and SaleDateTime >= case when t.CountBeforeSales = 1 then cast(t.saledatetime as DATE)
							 else cast(DATEADD(day,1,t.saledatetime) as DATE) end
		and TransactionStatus in (2, 810)
		and RuleCost is not null
		and TransactionStatus not in (Select StatusIntValue from Statuses where StatusTypeID = 9) 
		)
	from #tempStoreTransactions t 
	
	
	update t set t.DeliveriesQtySinceCount = (select ISNULL(SUM(Qty),0)
		from [dbo].[StoreTransactions] s
		where s.StoreID=t.StoreId
		and s.ProductID=t.ProductID
		and s.BrandID = t.BrandID
		and TransactionTypeID in (5,4,9,20)
		and SaleDateTime >= case when t.CountBeforeSales = 1 then cast(t.saledatetime as DATE)
							 else cast(DATEADD(day,1,t.saledatetime) as DATE) end
		and TransactionStatus in (2, 810)
		and RuleCost is not null
		and TransactionStatus not in (Select StatusIntValue from Statuses where StatusTypeID = 9) 
		)
	from #tempStoreTransactions t 
	
	
	update t set t.PickupsQtySinceCount = (select ISNULL(SUM(Qty),0)
		from [dbo].[StoreTransactions] s
		where s.StoreID=t.StoreId
		and s.ProductID=t.ProductID
		and s.BrandID = t.BrandID
		and TransactionTypeID in (8,13,14,21) --8 is SUP pickups
		and SaleDateTime >= case when t.CountBeforeSales = 1 then cast(t.saledatetime as DATE)
							 else cast(DATEADD(day,1,t.saledatetime) as DATE) end
		and TransactionStatus in (2, 810)
		and RuleCost is not null
		and TransactionStatus not in (Select StatusIntValue from Statuses where StatusTypeID = 9) 
		)
	from #tempStoreTransactions t 
	
	update t set t.NewCurrentOnHandQty=t.Qty - t.SalesQtySinceCount + t.DeliveriesQtySinceCount-t.PickupsQtySinceCount
	from #tempStoreTransactions t
	
	update i set
		i.CurrentOnHandQty=t.NewCurrentOnHandQty,
		i.ShrinkPerpetual=i.ShrinkPerpetual + case when i.CurrentOnHandQty <> t.NewCurrentOnHandQty 
				then ShrinkRevision + CurrentOnHandQty - t.NewCurrentOnHandQty  else ShrinkRevision end, 
		i.LastUpdateUserID=@MyID,DateTimeLastUpdate=GETDATE(),
		i.EffectiveDateTime = case when t.SaleDateTime > i.[EffectiveDateTime] then t.SaleDateTime 
			 else [EffectiveDateTime] end
		from InventoryPerpetual i join #tempStoreTransactions t
		on i.StoreID=t.StoreID
		and i.ProductID=t.ProductID
		and i.BrandID=t.BrandID
	
	update t
	set TransactionStatus = 2
	from [dbo].[StoreTransactions] t join #tempStoreTransactions s
	on t.StoreTransactionID = s.StoreTransactionID
	
		
		
		
		
----------------------------------------------------------------
/*			End -> New Changes - Use of temp table		      */
----------------------------------------------------------------
/*
set @rec = CURSOR local fast_forward FOR
	select StoreID, ProductID, BrandID, TransactionTypeID, 
	SaleDateTime, Qty, t.StoreTransactionID, SupplierID
	from [dbo].[StoreTransactions] t
	inner join #tempStoreTransaction2 tmp
	on t.StoreTransactionID = tmp.StoreTransactionID
	
open @rec

fetch next from @rec into @storeid,@productid,@brandid,
@transactiontypeid,@saledatetime,@countqty, @storetransactionid, @countsupplierid

while @@FETCH_STATUS = 0
	begin
	
		select @countbeforedeliveries =  InventoryTakenBeforeDeliveries 
		,@countbeforesales = InventoryTakenBeginOfDay
		from dbo.InventoryRulesTimesBySupplierID
		where SupplierID = @countsupplierid
		
		set @salesqtysincecount = 0

		select @salesqtysincecount = SUM(Qty)
		from [dbo].[StoreTransactions]
		where StoreID = @storeid
		and ProductID = @productid
		and BrandID = @brandid
		and TransactionTypeID in (2,6,7,16) --2 is POS sales
		and SaleDateTime >= case when @countbeforesales = 1 then cast(@saledatetime as DATE)
							 else cast(DATEADD(day,1,@saledatetime) as DATE) end
		--and SaleDateTime >= @startdate
		and TransactionStatus in (2, 810)
		--and TransactionStatus > 0
		and RuleCost is not null
		and TransactionStatus not in (Select StatusIntValue from Statuses where StatusTypeID = 9) --KilledStoreTransactionStatus is type 9
		
		if @salesqtysincecount is null
			set @salesqtysincecount = 0
		
		set @deliveriesqtysincecount = 0
		
		select @deliveriesqtysincecount = SUM(Qty)
		from [dbo].[StoreTransactions]
		where StoreID = @storeid
		and ProductID = @productid
		and BrandID = @brandid
		and TransactionTypeID in (5,4,9,20) --5 is SUP deliveries
		and SaleDateTime >= case when @countbeforedeliveries = 1 then cast(@saledatetime as DATE) else cast(DATEADD(day,1,@saledatetime) as DATE) end
		--and SaleDateTime >= @startdate
		and TransactionStatus in (2, 810)
		--		and TransactionStatus > 0
		and RuleCost is not null
		and TransactionStatus not in (Select StatusIntValue from Statuses where StatusTypeID = 9) --KilledStoreTransactionStatus is type 9
	
		if @deliveriesqtysincecount is null
			set @deliveriesqtysincecount = 0

		set @pickupsqtysincecount = 0
		
		select @pickupsqtysincecount = SUM(Qty)
		from [dbo].[StoreTransactions]
		where StoreID = @storeid
		and ProductID = @productid
		and BrandID = @brandid
		and TransactionTypeID in (8,13,14,21) --8 is SUP pickups
		and SaleDateTime >= case when @countbeforedeliveries = 1 then cast(@saledatetime as DATE) else cast(DATEADD(day,1,@saledatetime) as DATE) end
		--and SaleDateTime >= @startdate
		and TransactionStatus in (2, 810)
		--		and TransactionStatus > 0
		and RuleCost is not null
		and TransactionStatus not in (Select StatusIntValue from Statuses where StatusTypeID = 9) --KilledStoreTransactionStatus is type 9
		
		if @pickupsqtysincecount is null
			set @pickupsqtysincecount = 0			
--print str(@pickupsqtysincecount)		
			
		set @newcurrentonhandqty = @countqty - @salesqtysincecount + @deliveriesqtysincecount - @pickupsqtysincecount

		update i
		set CurrentOnHandQty = @newcurrentonhandqty,
		 ShrinkPerpetual = ShrinkPerpetual + case when CurrentOnHandQty <> @newcurrentonhandqty then ShrinkRevision + CurrentOnHandQty - @newcurrentonhandqty  else ShrinkRevision end, 
		--ShrinkRevision = case when CurrentOnHandQty <> @newcurrentonhandqty then ShrinkRevision + @newcurrentonhandqty - CurrentOnHandQty else ShrinkRevision end, 
		LastUpdateUserID = @MyID, DateTimeLastUpdate = GETDATE()
		--,Cost = @cost, Retail= @retail, 
		,EffectiveDateTime = case when @saledatetime > [EffectiveDateTime] then @saledatetime  else [EffectiveDateTime] end
		--EffectiveDateTime = @saledatetime
		from [dbo].[InventoryPerpetual] i
		where StoreID = @storeid
		and ProductID = @productid
		and BrandID = @brandid
		--and TempID <> @id

		
		update t
		set TransactionStatus = 2
		from [dbo].[StoreTransactions] t
		where t.StoreTransactionID = @storetransactionid
			
		fetch next from @rec into @storeid,@productid,
		@brandid,@transactiontypeid,@saledatetime,@countqty, @storetransactionid, @countsupplierid
	end
	
close @rec
deallocate @rec
*/
/*
declare @rec2 cursor
declare @recordid int
declare @shrink int

set @rec2 = CURSOR local fast_forward FOR
	select recordid, shrinkrevision
	from InventoryPerpetual
	where shrinkrevision <> 0
	
open @rec2

fetch next from @rec2 into @recordid, @shrink
*/

--select recordid, ShrinkRevision from InventoryPerpetual
--**************************************************************
commit transaction

/*
select recordid from InventoryPerpetual where ShrinkRevision <> 0
if @@ROWCOUNT > 0
	begin
		waitfor delay '0:0:5'
		repeatdelete:
		delete from cdc.dbo_InventoryPerpetual_CT where RecordID in
		(select recordid from InventoryPerpetual where ShrinkRevision <> 0)
		if @@rowcount < 1
			begin
				waitfor delay '0:0:5'
				--goto repeatdelete
			end
	end
*/	
end try
	
begin catch

		rollback transaction
		
		set @transactionstatus = -9997

		--declare @errormessage varchar(4500)
		--declare @errorlocation varchar(255)

		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
		
		exec [msdb].[dbo].[sp_stop_job] 
		@job_name = 'LoadInventoryCount - [prApplyINVStoreTransactionsToInventory_PassDateAndSupplier_NOCURSOR]'

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Load Inventory Job Stopped'
				,'Inventory count load has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;edi@icontroldsd.com;mandeep@amebasoftwares.com'	
				
end catch

update t set TransactionStatus = @transactionstatus
,LastUpdateUserID = @MyID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions] t
on tmp.StoreTransactionID = t.StoreTransactionID
where TransactionStatus = 0

--waitfor delay '0:0:5'

--exec DataTrue_Report..prCDCGetINVStoreTransactions
	
return
GO
