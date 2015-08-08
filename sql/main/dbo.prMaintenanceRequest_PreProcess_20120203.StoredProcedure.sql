USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_PreProcess_20120203]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_PreProcess_20120203]
as


/*
select distinct custom1 from stores
select * from MaintenanceRequests where requeststatus = -25
*/



--review markdeleted records

select *
  FROM [DataTrue_Main].[dbo].[MaintenanceRequests] mr
	where 1 = 1
	and MarkDeleted is not null
	and RequestStatus <> 6
	and Banner = 'Shop N Save Warehouse Foods Inc'
	and ProductId is not null
	and SkipPopulating879_889Records is not null
	and dtstorecontexttypeid is not null
	and RequestTypeID in (3)
	and SupplierID in (40559)
	order by ApprovalDateTime



declare @rec cursor
declare @bannercheck nvarchar(255)
declare @costzoneidcheck int
declare @mridcheck int
declare @invalidrecordsexist bit
declare @recordcountcheck int
declare @thisrecordisinvalid bit
declare @requeststatuscheck smallint
declare @supplierid int

set @invalidrecordsexist = 0

set @rec = CURSOR local fast_forward FOR
	select ltrim(rtrim(banner)), isnull(costzoneid, -1), maintenancerequestid, RequestStatus, ISNULL(supplierid, 0)
	--select *
	from MaintenanceRequests
	where RequestStatus in (0, -25)
	--and AllStores = 1
	--and Approved = 1
	--and MarkDeleted is null
	--and requesttypeid in (2,3)
	
open @rec

fetch next from @rec into
	@bannercheck
	,@costzoneidcheck
	, @mridcheck
	,@requeststatuscheck
	,@supplierid
	
while @@FETCH_STATUS = 0
	begin
	
		set @thisrecordisinvalid = 0
		
		--if @costzoneidcheck <> -1
		if @supplierid in (41464, 40567, 40558)
			begin
				set @recordcountcheck = 0
				select @recordcountcheck = costzoneid from CostZones where CostZoneID = @costzoneidcheck
				if @recordcountcheck is null
					set @recordcountcheck = 0
			
				if @recordcountcheck < 1
					begin
						set @thisrecordisinvalid = 1
						set @invalidrecordsexist = 1
					end
					
			end
			
		--if @costzoneidcheck = -1 and upper(@bannercheck) <> 'ALL'
		--if @supplierid not in (41464, 40567, 40558) and upper(@bannercheck) <> 'ALL'
		if upper(isnull(@bannercheck, '')) <> 'ALL'
			begin
				set @recordcountcheck = 0
				select @recordcountcheck = COUNT(storeid) from stores where LTRIM(rtrim(custom1)) = @bannercheck
				if @recordcountcheck is null
					set @recordcountcheck = 0
			
				if @recordcountcheck < 1
					begin
						set @thisrecordisinvalid = 1
						set @invalidrecordsexist = 1
					end			
			
			end
			
		if @thisrecordisinvalid = 1
			begin
				update MaintenanceRequests set RequestStatus = -25 where MaintenanceRequestID = @mridcheck
			end
		else
			begin
				if @thisrecordisinvalid = 0 and @requeststatuscheck = -25
					begin
						update MaintenanceRequests set RequestStatus = 0 where MaintenanceRequestID = @mridcheck
					end
			
			end
				
		fetch next from @rec into
			@bannercheck
			,@costzoneidcheck
			, @mridcheck	
			,@requeststatuscheck
			,@supplierid
	end

close @rec
deallocate @rec

if @invalidrecordsexist = 1
	begin
		exec dbo.prSendEmailNotification_PassEmailAddresses 'Invalid MaintenanceRequest Records Found'
		,'MaintenanceRequest records have been found that either have an invalid banner value or invalid costzoneid value on the record.  Gopher News, Lewis Bakery, and Flowers bakery require valid costzoneid and the remainder of the suppliers require a valid banner value.  These records have been set to a requeststatus value of -25 and will not be processed until the invalid value is corrected.  Please review all records with -25 requeststatus and correct the values asap.'
		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;nik.baskin@icontroldsd.com;gilad.keren@icontroldsd.com'
	end

/*	
select * from MaintenanceRequests where requeststatus = -25
*/

declare @recmrprep cursor
declare @maintenancerequestid int
declare @requesttypeid smallint
declare @chainid int
--declare @supplierid int
declare @banner nvarchar(50)
declare @allstores smallint
declare @requestedcost money
declare @promoallowance money
declare @startdate datetime
declare @enddate datetime
declare @costzoneid int
declare @productid int
declare @storecontexttypeid smallint
declare @recordcount int
declare @recordisvalid bit
declare @atleastonefailedstorecontext bit

set @recmrprep = CURSOR local fast_forward FOR
	select maintenancerequestid, RequestTypeId, ChainID, SupplierID, ltrim(rtrim(Banner)), 
	AllStores, Cost, PromoAllowance, [StartDateTime]
      ,[EndDateTime]
      ,isnull([CostZoneID], -1)
      ,[ProductID]
	FROM [DataTrue_Main].[dbo].[MaintenanceRequests] mr
	where 1 = 1
	and Approved = 1
	and RequestStatus = 0
	and ProductId is not null
	and SupplierID is not null
	and dtstorecontexttypeid is null
	--and SupplierID = 40558
	order by MaintenanceRequestID
	
open @recmrprep

fetch next from @recmrprep into 
	 @maintenancerequestid
	,@requesttypeid
	,@chainid
	,@supplierid
	,@banner
	,@allstores
	,@requestedcost
	,@promoallowance
	,@startdate
	,@enddate
	,@costzoneid
	,@productid
	
while @@FETCH_STATUS = 0
	begin
	
		set @storecontexttypeid = 0
		set @recordisvalid = 1
		set @atleastonefailedstorecontext = 0
		
		set @recordcount = 0
		select @recordcount = supplierid from suppliers where SupplierID = @supplierid
		if @recordcount is null
			set @recordcount = 0
			
		if @recordcount < 1
			set @recordisvalid = 0
		
		--RequestType
		
		if @requesttypeid in (1, 2)
			begin
				--check cost
				if @requestedcost is null or @requestedcost = 0
					set @recordisvalid = 0
			end
			
		if @requesttypeid = 3
			begin
				--check promo
				if @promoallowance is null or @promoallowance = 0
					set @recordisvalid = 0
				if isdate(@startdate) < 1 or isdate(@enddate) < 1
					set @recordisvalid = 0		
				if @startdate > @enddate
					set @recordisvalid = 0								
			end
			
		if @recordisvalid = 1
			begin
						
				--store context
				
				if @allstores = 1
					begin
						if @supplierid not in (41464, 41465, 40567, 40558) and upper(@banner) = 'ALL'
						--if @costzoneid = -1 and upper(@banner) = 'ALL'
							begin
								set @storecontexttypeid = 5
							end
					
						--if @storecontexttypeid = 0
						if @supplierid in (41464, 41465, 40567, 40558) and @storecontexttypeid = 0
							begin
								set @recordcount = 0
								select @recordcount = costzoneid from CostZones where CostZoneID = @costzoneid and SupplierId = @supplierid
								if @recordcount is null
									set @recordcount = 0
									
								if @recordcount > 0
									begin
										set @storecontexttypeid = 3
									end
								
								if @supplierid not in (41464, 41465, 40567, 40558) and @storecontexttypeid = 0
								--if @storecontexttypeid = 0
									begin
										set @recordcount = 0
										select @recordcount = COUNT(storeid) from Stores where LTRIM(rtrim(custom1)) = @banner
										if @recordcount is null
											set @recordcount = 0
											
										if @recordcount > 0
											begin
												set @storecontexttypeid = 2
											end								
									end					
						end
					end
				else
					begin
						set @recordcount = 0
						select @recordcount = storeid from MaintenanceRequestStores where MaintenanceRequestID = @maintenancerequestid and Included = 1
						if @recordcount is null
							set @recordcount = 0
							
						if @recordcount > 0
							begin
								set @storecontexttypeid = 1
							end							
					
					end


			end
			
		if @storecontexttypeid <> 0
			begin
				update MaintenanceRequests set dtstorecontexttypeid = @storecontexttypeid where MaintenanceRequestID = @maintenancerequestid	
			end	
		else
			begin
				set @storecontexttypeid = 0
				set @atleastonefailedstorecontext = 1
			end
			
		fetch next from @recmrprep into 
			 @maintenancerequestid
			,@requesttypeid
			,@chainid
			,@supplierid
			,@banner
			,@allstores
			,@requestedcost
			,@promoallowance
			,@startdate
			,@enddate
			,@costzoneid
			,@productid	
	end
	
close @recmrprep
deallocate @recmrprep

if @atleastonefailedstorecontext = 1
	begin
		exec dbo.prSendEmailNotification_PassEmailAddresses 'Invalid MaintenanceRequest Records Found'
		,'MaintenanceRequest records have been found that fail validation and can not be assigned a dtstorecontexttypeid value.  Gopher News, Lewis Bakery, and Flowers bakery require valid costzoneid and the remainder of the suppliers require a valid banner value.  Also, cost and promoallowance values must be valid depending on requesttype.  These records remain with a null dtstorecontexttypeid value and will not be processed until the invalid value is corrected.  Please review all records with -25 requeststatus and correct the values asap.'
		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'	
	
	end


/*

select * from suppliers where supplierid = 40570

select *
--update mr set costzoneid = 1775
from MaintenanceRequests mr
 where requeststatus in (0, -25) 
 and supplierid = 40567 
 --and costzoneid = -1
 and banner = 'Shoppers Food and pharmacy'
 and costzoneid <> 1775
 
 select *
 from costzonerelations
 where costzoneid = 1777
 
 select *
 from MaintenanceRequests
 where left(banner, 5) = 'shope'
*/
return
GO
