USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[ZNU_prApplyINVStoreTransactionsToInventoryCost_NoBeginTransaction]    Script Date: 06/25/2015 18:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[ZNU_prApplyINVStoreTransactionsToInventoryCost_NoBeginTransaction]

as

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @MyID int
set @MyID = 0

begin try

--begin transaction

--/*
declare @rec cursor
declare @invcostid bigint
declare @currentonhand int
declare @totalavailable int
declare @availdifference int
declare @invchainid int
declare @invstoreid int
declare @invproductid int
declare @invbrandid int
declare @invReceivedAtThisCostDate datetime
declare @invtruecost money
declare @invtrueretail money
declare @invqty int

set @rec = CURSOR local fast_forward FOR
	select distinct t.chainid, t.storeid, t.productid, t.brandid, t.saledatetime, t.TrueCost, t.qty, t.TrueRetail
	--into #tempStoreTransaction2
	from StoreTransactions t
	inner join InventoryCost c
	on t.storeid = c.storeid 
	and t.productid = c.productid
	and t.brandid = c.brandid
	where t.TransactionStatus = 1
	and t.TransactionTypeID in (10,11)
	and t.CostMisMatch = 0
	and t.RetailMisMatch = 0
	
open @rec

fetch next from @rec into @invchainid, @invstoreid, @invproductid, @invbrandid, 
	@invReceivedAtThisCostDate, @invtruecost, @invqty, @invtrueretail

while @@FETCH_STATUS = 0
	begin
		select @currentonhand = CurrentOnHandQty from InventoryPerpetual
		where StoreID = @invstoreid
		and ProductID = @invproductid
		and BrandID = @invbrandid
		
		select @totalavailable = sum(QtyAvailableAtThisCost)
		from InventoryCost
		where StoreID = @invstoreid
		and ProductID = @invproductid
		and BrandID = @invbrandid
		
		set @availdifference = 	@currentonhand - @totalavailable
		
		if @availdifference <> 0
		  begin
				INSERT InventoryCost
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
			   ,MaxQtyAvailableAtThisCost)
				VALUES
			   (@invchainid
			   ,@invstoreid
				,@invproductid
				,@invbrandid
				,@availdifference
				,@MyID
				,getdate()
				,@invReceivedAtThisCostDate
				,@invtruecost
				,@invtrueretail
				,@availdifference)
			end
/*		
		update InventoryCost set QtyAvailableAtThisCost = @availdifference
		,MaxQtyAvailableAtThisCost = @availdifference
		,LastUpdateUserID = @MyID
		where InventoryCostID = @invcostid	
*/		
		fetch next from @rec into @invchainid, @invstoreid, @invproductid, @invbrandid, 
			@invReceivedAtThisCostDate, @invtruecost, @invqty, @invtrueretail
	end
	
	close @rec
	deallocate @rec
--*/

--delivery records
select distinct StoreTransactionID
into #tempStoreTransaction
from [dbo].[StoreTransactions]
where TransactionStatus = 1
and TransactionTypeID in (10,11)
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
      ,transactiontypeid
  FROM [dbo].[StoreTransactions] t
  inner join #tempStoreTransaction tmp
	on t.StoreTransactionID = tmp.StoreTransactionID
	group by t.chainid, t.storeid, t.productid, t.brandid, t.truecost, t.saledatetime, transactiontypeid) S
	on i.ChainID = s.ChainID
	and i.StoreID = s.StoreID 
	and i.ProductID = s.ProductID
	and i.BrandID = s.BrandID
	--and cast(i.ReceivedAtThisCostDate as date) = cast(s.EffectiveDateTime as date)

/*
WHEN MATCHED THEN
	INSERT 
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
           ,MaxQtyAvailableAtThisCost)
     VALUES
           (s.[ChainID]
           ,s.[StoreID]
			,s.[ProductID]
			,s.[BrandID]
			,0
			,-9999
			,getdate()
			,s.EffectiveDateTime
			,s.Cost
			,s.Retail
			,0)
*/
	
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
           ,MaxQtyAvailableAtThisCost)
     VALUES
           (s.[ChainID]
           ,s.[StoreID]
			,s.[ProductID]
			,s.[BrandID]
			,s.Qty
			,@MyID
			,getdate()
			,s.EffectiveDateTime
			,s.Cost
			,s.Retail
			,s.Qty);
--**************************************************************
/*

*/

exec prInventoryCost_NewRecords_Collapse
exec prInventoryCost_ActiveCost_Sync

update t set TransactionStatus = 2
	,LastUpdateUserID = @MyID
	,DateTimeLastUpdate = GETDATE()
	,Inventorycost = case when costmismatch = 0 then truecost else null end
	from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions] t
on tmp.StoreTransactionID = t.StoreTransactionID



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

		--commit transaction
	
end try
	
begin catch
		--rollback transaction
		
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
