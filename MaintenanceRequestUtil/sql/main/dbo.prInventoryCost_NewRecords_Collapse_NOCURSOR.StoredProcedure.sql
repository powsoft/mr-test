USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInventoryCost_NewRecords_Collapse_NOCURSOR]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prInventoryCost_NewRecords_Collapse_NOCURSOR]
as


declare @rec cursor
declare @inventorycostid bigint
declare @chainid int
declare @storeid int
declare @productid int
declare @brandid int
declare @cost money
declare @qtyatcost int
declare @datetimereceived datetime
declare @olderinventorycostid bigint
declare @oldercost money
--*****************************************
--drop table #tempInventoryCost
SELECT [InventoryCostID]
      ,[ChainID]
      ,[StoreID]
      ,[ProductID]
      ,[BrandID]
      ,[Cost]
      ,[QtyAvailableAtThisCost]
      ,[ReceivedAtThisCostDate]
      ,null as "DateAfterThisID"
      ,null as "DateBeforeThisID"
      ,Cast(null as money) as "CostOnDateAfterThis"
      ,Cast(null as money) as "CostOnDateBeforeThis"
      ,Cast(null as date) as "DateAfterThis"
      ,Cast(null as date) as "DateBeforeThis"
      into #tempInventoryCost
  FROM [DataTrue_Main].[dbo].[InventoryCost]
  where recordstatus = 0
  order by [ReceivedAtThisCostDate]
  
  
    update main set DateAfterThisID=
       (select top 1 InventoryCostID from InventoryCost i1 where [ReceivedAtThisCostDate]>main.[ReceivedAtThisCostDate] and ChainID=main.chainid
		and StoreID= main.storeid and ProductID = main.productid and RecordStatus =1 and BrandID = main.brandid order by [ReceivedAtThisCostDate])
      ,DateBeforeThisID =(select top 1 InventoryCostID from InventoryCost i1 where [ReceivedAtThisCostDate]<=main.[ReceivedAtThisCostDate] and ChainID=main.chainid
      and StoreID= main.storeid and ProductID = main.productid and RecordStatus =1 and BrandID = main.brandid order by [ReceivedAtThisCostDate]) 
  FROM #tempInventoryCost main--[DataTrue_Main].[dbo].[InventoryCost]
  
  
  update t set t.CostOnDateAfterThis= i.Cost, t.DateAfterThis=t.ReceivedAtThisCostDate
  from #tempInventoryCost t join InventoryCost i
  on t.DateAfterThisID=i.InventoryCostID
  and t.DateAfterThisID is not null
  
  
  update t set t.CostOnDateBeforeThis= i.Cost, t.DateBeforeThis=t.ReceivedAtThisCostDate
  from #tempInventoryCost t join InventoryCost i
  on t.DateBeforeThisID=i.InventoryCostID
  and t.DateBeforeThisID is not null
  

		update i set i.QtyAvailableAtThisCost = i.QtyAvailableAtThisCost + t.QtyAvailableAtThisCost
		,i.MaxQtyAvailableAtThisCost = i.MaxQtyAvailableAtThisCost + t.QtyAvailableAtThisCost
		--select *
		from #tempInventoryCost t join InventoryCost i
		on t.DateAfterThisID=i.InventoryCostID
		where t.Cost=t.CostOnDateAfterThis
		and DateAfterThisID is not null
		and DateBeforeThisID is null
	  
		delete
		from InventoryCost where InventoryCostID in
		(select [InventoryCostID] from #tempInventoryCost t
		where t.Cost=t.CostOnDateAfterThis
		and DateAfterThisID is not null
		and DateBeforeThisID is null)
	  
		update i set i.QtyAvailableAtThisCost = i.QtyAvailableAtThisCost + t.QtyAvailableAtThisCost
				,i.MaxQtyAvailableAtThisCost = i.MaxQtyAvailableAtThisCost + t.QtyAvailableAtThisCost
				,i.ReceivedAtThisCostDate = t.DateBeforeThisID
		--select *
		from #tempInventoryCost t join InventoryCost i
		on t.DateBeforeThisID=i.InventoryCostID
		where t.Cost=t.CostOnDateBeforeThis 
		and DateBeforeThisID is not null
		and DateAfterThisID is null
		
		update i set i.recordstatus=1
		from #tempInventoryCost t join InventoryCost i
		on t.InventoryCostID=i.InventoryCostID
		where DateBeforeThisID is null
		and DateAfterThisID is null
  
		
		
--*****************************************
/*
set @rec = cursor local fast_forward for
	SELECT [InventoryCostID]
      ,[ChainID]
      ,[StoreID]
      ,[ProductID]
      ,[BrandID]
      ,[Cost]
      ,[QtyAvailableAtThisCost]
      ,[ReceivedAtThisCostDate]
  FROM [DataTrue_Main].[dbo].[InventoryCost]
  where recordstatus = 0
  order by [ReceivedAtThisCostDate]

open @rec

fetch next from @rec into
@inventorycostid
,@chainid
,@storeid
,@productid
,@brandid
,@cost
,@qtyatcost
,@datetimereceived

while @@fetch_status = 0
	begin
		select @olderinventorycostid = inventorycostid 
		,@oldercost = cost
		from InventoryCost
		where chainid = @chainid
		and storeid = @storeid
		and productid = @productid
		and brandid = @brandid
		and recordstatus = 1
		order by ReceivedAtThisCostDate
		
--print @olderinventorycostid

		if @@rowcount > 0
			begin
				if @cost = @oldercost
					begin
						update InventoryCost set QtyAvailableAtThisCost = QtyAvailableAtThisCost + @qtyatcost
						,MaxQtyAvailableAtThisCost = MaxQtyAvailableAtThisCost + @qtyatcost
						,ReceivedAtThisCostDate = case when ReceivedAtThisCostDate < @datetimereceived then @datetimereceived else ReceivedAtThisCostDate end
						where inventorycostid = @olderinventorycostid
						
						delete InventoryCost where inventorycostid = @inventorycostid
					end
				else
					begin
						update InventoryCost set recordstatus = 1  where inventorycostid = @inventorycostid
					end
			end
		else
			begin
				update InventoryCost set recordstatus = 1  where inventorycostid = @inventorycostid
			end
	
		fetch next from @rec into
		@inventorycostid
		,@chainid
		,@storeid
		,@productid
		,@brandid
		,@cost
		,@qtyatcost
		,@datetimereceived	
	end
	
close @rec
deallocate @rec
*/
return
GO
