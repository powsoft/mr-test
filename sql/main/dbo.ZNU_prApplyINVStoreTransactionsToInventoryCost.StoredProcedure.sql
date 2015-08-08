USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[ZNU_prApplyINVStoreTransactionsToInventoryCost]    Script Date: 06/25/2015 18:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[ZNU_prApplyINVStoreTransactionsToInventoryCost]

as

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @transactionstatus smallint
declare @id as uniqueidentifier
declare @newshrinkrevision int
declare @newcurrentonhandqty int
declare @MyID int
set @MyID = 0

begin try

select distinct StoreTransactionID
into #tempStoreTransaction
from [dbo].[StoreTransactions]
where TransactionStatus = 0
and TransactionTypeID in (10,11)
and CostMisMatch = 0
and RetailMisMatch = 0

begin transaction

set @id = NEWID()
set @transactionstatus = 1

--**************************************************************
MERGE INTO [dbo].[InventoryPerpetual] i

USING (SELECT [ChainID], [StoreID]
      ,[ProductID]
      ,[BrandID]
      ,sum([Qty]) as Qty
      ,@id as TempID
      ,tmp.StoreTransactionID
      ,[SaleDateTime]
      ,isnull(max([TrueCost]), isnull(max([RuleCost]), isnull(max([SetupCost]), 0.0))) as Cost
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
/*
update t set TransactionStatus = @transactionstatus
  FROM [dbo].[StoreTransactions] t
  inner join #tempStoreTransaction tmp
  on t.StoreTransactionID = tmp.StoreTransactionID
  inner join [dbo].[InventoryPerpetual] i
  on tmp.StoreTransactionID = i.StoreTransactionID
 */
  
select distinct tmp.StoreTransactionID
into #tempStoreTransaction2
from [dbo].[StoreTransactions] t
inner join #tempStoreTransaction tmp
on t.StoreTransactionID = tmp.StoreTransactionID
where t.TransactionStatus = 0
and t.TransactionTypeID in (10,11)
and t.StoreTransactionID not in (Select OriginatingStoreTransactionID  from InventoryPerpetual where OriginatingStoreTransactionID is not null)

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
--declare @storetransactionid int

set @rec = CURSOR local fast_forward FOR
 select StoreID, ProductID, BrandID, TransactionTypeID, 
 SaleDateTime, Qty, t.StoreTransactionID
 from [dbo].[StoreTransactions] t
inner join #tempStoreTransaction2 tmp
on t.StoreTransactionID = tmp.StoreTransactionID

open @rec

fetch next from @rec into @storeid,@productid,@brandid,
@transactiontypeid,@saledatetime,@countqty, @storetransactionid

while @@FETCH_STATUS = 0
	begin
--print str(@countqty)
		if @transactiontypeid = 10
			begin
				set @startdate = cast(DATEADD(day,1,@saledatetime) as DATE)
			end
		if @transactiontypeid = 11
			begin
				set @startdate = cast(@saledatetime as DATE)
			end
			
		set @salesqtysincecount = 0
		select @salesqtysincecount = SUM(Qty)
		from [dbo].[StoreTransactions]
		where StoreID = @storeid
		and ProductID = @productid
		and BrandID = @brandid
		and TransactionTypeID in (2,6,7,16) --2 is POS sales
		and SaleDateTime >= @startdate
		and TransactionStatus > 0
		and TransactionStatus not in (Select StatusIntValue from Statuses where StatusTypeID = 9) --KilledStoreTransactionStatus is type 9
		if @salesqtysincecount is null
			set @salesqtysincecount = 0
--print str(@salesqtysincecount)		
		set @deliveriesqtysincecount = 0
		select @deliveriesqtysincecount = SUM(Qty)
		from [dbo].[StoreTransactions]
		where StoreID = @storeid
		and ProductID = @productid
		and BrandID = @brandid
		and TransactionTypeID in (5,4,9,20) --5 is SUP deliveries
		and SaleDateTime >= @startdate
		and TransactionStatus > 0
		and TransactionStatus not in (Select StatusIntValue from Statuses where StatusTypeID = 9) --KilledStoreTransactionStatus is type 9
		if @deliveriesqtysincecount is null
			set @deliveriesqtysincecount = 0
--print str(@deliveriesqtysincecount)		
		--@pickupsqtysincecount			
		set @pickupsqtysincecount = 0
		select @pickupsqtysincecount = SUM(Qty)
		from [dbo].[StoreTransactions]
		where StoreID = @storeid
		and ProductID = @productid
		and BrandID = @brandid
		and TransactionTypeID in (8,13,14,21) --8 is SUP pickups
		and SaleDateTime >= @startdate
		and TransactionStatus > 0
		and TransactionStatus not in (Select StatusIntValue from Statuses where StatusTypeID = 9) --KilledStoreTransactionStatus is type 9
		if @pickupsqtysincecount is null
			set @pickupsqtysincecount = 0			
--print str(@pickupsqtysincecount)		
			
		set @newcurrentonhandqty = @countqty - @salesqtysincecount + @deliveriesqtysincecount - @pickupsqtysincecount
		--set @newshrinkrevision = 
--print str(@newcurrentonhandqty)		
/*			
		set @cost = 0
		set @retail = 0
			
		select @cost = TrueCost, @retail = TrueRetail
		from StoreTransactions
		where StoreID = @storeid
		and ProductID = @productid
		and BrandID = @brandid
		and TransactionTypeID = 2
		and TrueCost is not null
		and TrueRetail is not null
		order by DATEDIFF(day,SaleDateTime, @saledatetime) desc
		
		if @cost is null
			set @cost = 0
		if @retail is null
			set @retail = 0
*/			
			
		update i
		set CurrentOnHandQty = @newcurrentonhandqty,
		ShrinkRevision = case when CurrentOnHandQty <> @newcurrentonhandqty then ShrinkRevision + CurrentOnHandQty - @newcurrentonhandqty  else ShrinkRevision end, 
		--ShrinkRevision = case when CurrentOnHandQty <> @newcurrentonhandqty then ShrinkRevision + @newcurrentonhandqty - CurrentOnHandQty else ShrinkRevision end, 
		LastUpdateUserID = @MyID, DateTimeLastUpdate = GETDATE()
		--,Cost = @cost, Retail= @retail, 
		,EffectiveDateTime = case when @saledatetime > [EffectiveDateTime] then @saledatetime  else [EffectiveDateTime] end
		--EffectiveDateTime = @saledatetime
		from [dbo].[InventoryPerpetual] i
		where StoreID = @storeid
		and ProductID = @productid
		and BrandID = @brandid
		and TempID <> @id
		
		update t
		set TransactionStatus = 1
		from [dbo].[StoreTransactions] t
		where t.StoreTransactionID = @storetransactionid
			
		fetch next from @rec into @storeid,@productid,
		@brandid,@transactiontypeid,@saledatetime,@countqty, @storetransactionid
	end
	
close @rec
deallocate @rec
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
