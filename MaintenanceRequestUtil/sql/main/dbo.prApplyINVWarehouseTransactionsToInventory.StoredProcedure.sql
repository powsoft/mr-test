USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prApplyINVWarehouseTransactionsToInventory]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prApplyINVWarehouseTransactionsToInventory]
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

declare @tempdate as date='2012-03-03 00:00:00.000' -------2011-12-12 00:00:00.000**************TO CATCH UP*****************

begin try
--drop table #tempWarehouseTransaction
select distinct WarehouseTransactionID
into #tempWarehouseTransaction
--declare @tempdate date='12/17/2011' select *
from [dbo].[WarehouseTransactions]
where 1 = 1
and TransactionStatus = 0
and TransactionTypeID in (10,11)
--and CostMisMatch = 0
--and RetailMisMatch = 0
and RuleCost is not null
--and TrueCost is not null
and SupplierID in (41465) --GOP --40562--PEP 40561--SHM 40557--BIMBO
--and SupplierID in (40558, 40561, 40562, 40557, 41464, 41465) --GOP --40562--PEP 40561--SHM 40557--BIMBO
and CAST(Effectivedatetime as date) = @tempdate
--and WarehouseID in (select WarehouseID from Warehouses where LTRIM(rtrim(custom1)) = 'Farm Fresh Markets')
--and CAST(datetimecreated as date) = '3/7/2012'
--and WarehouseID = 40509
--and ProductID = 5511

set @id = NEWID()
set @transactionstatus = 2

begin transaction



--**************************************************************
MERGE INTO [dbo].[InventoryPerpetual_WHS] i

USING (SELECT [ChainID], [WarehouseID]
      ,[ProductID]
      ,[BrandID]
      ,sum([Qty]) as Qty
      ,@id as TempID
      ,tmp.WarehouseTransactionID
      ,[Effectivedatetime]
      ,isnull(max([TrueCost]), isnull(max([RuleCost]), isnull(max([SetupCost]), 0.0))) - isnull(max([PromoAllowance]), 0.00) as Cost
      ,isnull(max([TrueRetail]), isnull(max([RuleRetail]), isnull(max([SetupRetail]), 0.0))) as Retail
  FROM [dbo].[WarehouseTransactions] t
  inner join #tempWarehouseTransaction tmp
	on t.WarehouseTransactionID = tmp.WarehouseTransactionID
	group by t.chainid, t.Warehouseid, t.productid, t.brandid, tmp.WarehouseTransactionID, Effectivedatetime) S
	--group by t.chainid, t.Warehouseid, t.productid, t.brandid) S
	on i.ChainID = s.ChainID
	and i.WarehouseID = s.WarehouseID 
	and i.ProductID = s.ProductID
	and i.BrandID = s.BrandID

WHEN NOT MATCHED 

THEN INSERT 
           ([ChainID]
           ,[WarehouseID]
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
           ,[OriginatingWarehouseTransactionID]
           ,[EffectiveDateTime]
           ,[Cost]
           ,[Retail])
     VALUES
           (s.[ChainID], s.[WarehouseID]
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
			,s.WarehouseTransactionID
			,s.Effectivedatetime
            ,s.[Cost]
            ,s.[Retail]);

select distinct tmp.WarehouseTransactionID
into #tempWarehouseTransaction2
from [dbo].[WarehouseTransactions] t
inner join #tempWarehouseTransaction tmp
on t.WarehouseTransactionID = tmp.WarehouseTransactionID
where 1 = 1
and t.TransactionStatus = 0
and t.TransactionTypeID in (10,11)
and t.WarehouseTransactionID not in (Select OriginatingWarehouseTransactionID  from InventoryPerpetual_WHS where OriginatingWarehouseTransactionID is not null)
--and WarehouseID = 40509
--and ProductID = 5511
and CAST(Effectivedatetime as date) = @tempdate

declare @rec cursor
declare @Warehouseid int
declare @productid int
declare @brandid int
declare @transactiontypeid int
declare @Effectivedatetime datetime
declare @countqty int
declare @Warehousetransactionid bigint
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
--declare @Warehousetransactionid int

set @rec = CURSOR local fast_forward FOR
 select WarehouseID, ProductID, BrandID, TransactionTypeID, 
 Effectivedatetime, Qty, t.WarehouseTransactionID, SupplierID
 from [dbo].[WarehouseTransactions] t
inner join #tempWarehouseTransaction2 tmp
on t.WarehouseTransactionID = tmp.WarehouseTransactionID



open @rec

fetch next from @rec into @Warehouseid,@productid,@brandid,
@transactiontypeid,@Effectivedatetime,@countqty, @Warehousetransactionid, @countsupplierid

while @@FETCH_STATUS = 0
	begin
	
		select @countbeforedeliveries =  InventoryTakenBeforeDeliveries 
		,@countbeforesales = InventoryTakenBeginOfDay
		from dbo.InventoryRulesTimesBySupplierID
		where SupplierID = @countsupplierid
		
		set @salesqtysincecount = 0
		select @salesqtysincecount = SUM(Qty)
		from [dbo].[WarehouseTransactions]
		where WarehouseID = @Warehouseid
		and ProductID = @productid
		and BrandID = @brandid
		and TransactionTypeID in (2,6,7,16) --2 is POS sales
		and Effectivedatetime >= case when @countbeforesales = 1 then cast(@Effectivedatetime as DATE) else cast(DATEADD(day,1,@Effectivedatetime) as DATE) end
		--and Effectivedatetime >= @startdate
		and TransactionStatus in (2, 810)
		--and TransactionStatus > 0
		and RuleCost is not null
		and TransactionStatus not in (Select StatusIntValue from Statuses where StatusTypeID = 9) --KilledWarehouseTransactionStatus is type 9
		if @salesqtysincecount is null
			set @salesqtysincecount = 0
--print str(@salesqtysincecount)		
		set @deliveriesqtysincecount = 0
		select @deliveriesqtysincecount = SUM(Qty)
		from [dbo].[WarehouseTransactions]
		where WarehouseID = @Warehouseid
		and ProductID = @productid
		and BrandID = @brandid
		and TransactionTypeID in (5,4,9,20) --5 is SUP deliveries
		and Effectivedatetime >= case when @countbeforedeliveries = 1 then cast(@Effectivedatetime as DATE) else cast(DATEADD(day,1,@Effectivedatetime) as DATE) end
		--and Effectivedatetime >= @startdate
		and TransactionStatus in (2, 810)
		--		and TransactionStatus > 0
		and RuleCost is not null
		and TransactionStatus not in (Select StatusIntValue from Statuses where StatusTypeID = 9) --KilledWarehouseTransactionStatus is type 9
		if @deliveriesqtysincecount is null
			set @deliveriesqtysincecount = 0
--print str(@deliveriesqtysincecount)		
		--@pickupsqtysincecount			
		set @pickupsqtysincecount = 0
		select @pickupsqtysincecount = SUM(Qty)
		from [dbo].[WarehouseTransactions]
		where WarehouseID = @Warehouseid
		and ProductID = @productid
		and BrandID = @brandid
		and TransactionTypeID in (8,13,14,21) --8 is SUP pickups
		and Effectivedatetime >= case when @countbeforedeliveries = 1 then cast(@Effectivedatetime as DATE) else cast(DATEADD(day,1,@Effectivedatetime) as DATE) end
		--and Effectivedatetime >= @startdate
		and TransactionStatus in (2, 810)
		--		and TransactionStatus > 0
		and RuleCost is not null
		and TransactionStatus not in (Select StatusIntValue from Statuses where StatusTypeID = 9) --KilledWarehouseTransactionStatus is type 9
		if @pickupsqtysincecount is null
			set @pickupsqtysincecount = 0			
--print str(@pickupsqtysincecount)		
			
		set @newcurrentonhandqty = @countqty - @salesqtysincecount + @deliveriesqtysincecount - @pickupsqtysincecount

		update i
		set CurrentOnHandQty = @newcurrentonhandqty,
		ShrinkRevision = case when CurrentOnHandQty <> @newcurrentonhandqty then ShrinkRevision + CurrentOnHandQty - @newcurrentonhandqty  else ShrinkRevision end, 
		--ShrinkRevision = case when CurrentOnHandQty <> @newcurrentonhandqty then ShrinkRevision + @newcurrentonhandqty - CurrentOnHandQty else ShrinkRevision end, 
		LastUpdateUserID = @MyID, DateTimeLastUpdate = GETDATE()
		--,Cost = @cost, Retail= @retail, 
		,EffectiveDateTime = case when @Effectivedatetime > [EffectiveDateTime] then @Effectivedatetime  else [EffectiveDateTime] end
		--EffectiveDateTime = @Effectivedatetime
		from [dbo].[InventoryPerpetual_WHS] i
		where WarehouseID = @Warehouseid
		and ProductID = @productid
		and BrandID = @brandid
		--and TempID <> @id
		
		
		update t
		set TransactionStatus = 2
		from [dbo].[WarehouseTransactions] t
		where t.WarehouseTransactionID = @Warehousetransactionid
			
		fetch next from @rec into @Warehouseid,@productid,
		@brandid,@transactiontypeid,@Effectivedatetime,@countqty, @Warehousetransactionid, @countsupplierid
	end
	
close @rec
deallocate @rec
--**************************************************************
commit transaction

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
from #tempWarehouseTransaction tmp
inner join [dbo].[WarehouseTransactions] t
on tmp.WarehouseTransactionID = t.WarehouseTransactionID
where TransactionStatus = 0

	
return
GO
