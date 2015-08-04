USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_RetailOnly_Update_Type8]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_RetailOnly_Update_Type8]
as


 declare @rec cursor
 declare @productid as int
 declare @banner nvarchar(100)
 declare @retail money
 declare @supplierid int
 declare @mrid int
 declare @updaterowcount int
 declare @startdate datetime
 
 set @rec = CURSOR local fast_forward FOR
 select Productid, Supplierid, Banner, SuggestedRetail, MaintenanceRequestID, StartDateTime
 --select *
 --update mr set mr.RequestStatus = 5
 from MaintenanceRequests mr
 where RequestTypeID = 8
 and RequestStatus in (0, -90)
 and productid is not null
 and SupplierID is not null
 and Banner is not null
 and isnull(Approved, 0) = 1
 order by datetimecreated
 
 open @rec
 
 fetch next from @rec into @productid, @supplierid, @banner, @retail, @mrid, @startdate
 
 while @@FETCH_STATUS = 0
	begin
	--print @retail

		select @retail, p.UnitRetail, * 
		from ProductPrices p
		where ProductID = @productid 
		and SupplierID = @supplierid 
		and StoreID in (select StoreID from stores where Custom1 = @banner)
		--and @startdate <= cast(p.ActiveLastDate as date)
		--and p.ProductPriceTypeID = 3
		order by p.ActiveLastDate
		
		set @updaterowcount = 0
		
		update P set p.UnitRetail = @retail
		--select @retail, p.UnitRetail, * 
		from ProductPrices p
		where ProductID = @productid 
		and SupplierID = @supplierid 
		and StoreID in (select StoreID from stores where Custom1 = @banner)
		and @startdate <= cast(p.ActiveLastDate as date)
		--and p.UnitRetail = 0
		
		set @updaterowcount = @@ROWCOUNT

		select @retail, p.UnitRetail, * 
		from ProductPrices p
		where ProductID = @productid 
		and SupplierID = @supplierid 
		and StoreID in (select StoreID from stores where Custom1 = @banner)
		--and @startdate <= cast(p.ActiveLastDate as date)
		--and p.ProductPriceTypeID = 3
		order by p.ActiveLastDate
				
		if @updaterowcount > 0
			begin		
				update R set r.requeststatus = 5
				from MaintenanceRequests r
				where MaintenanceRequestID = @mrid
			end
	
		fetch next from @rec into @productid, @supplierid, @banner, @retail, @mrid, @startdate
	end
	
close @rec
deallocate @rec
 
 
 return
GO
