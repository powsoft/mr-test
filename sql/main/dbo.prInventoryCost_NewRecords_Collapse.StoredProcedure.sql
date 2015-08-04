USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInventoryCost_NewRecords_Collapse]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prInventoryCost_NewRecords_Collapse]
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

return
GO
