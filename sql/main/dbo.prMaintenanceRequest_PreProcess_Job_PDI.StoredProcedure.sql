USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_PreProcess_Job_PDI]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_PreProcess_Job_PDI]
as

declare @rec cursor
declare @bannercheck nvarchar(255)
declare @costzoneidcheck int
declare @mridcheck int
declare @invalidrecordsexist bit
declare @recordcountcheck int
declare @thisrecordisinvalid bit
declare @requeststatuscheck smallint
declare @supplierid int
declare @storeproductcontextmethod nvarchar(50)

--select distinct custom1 from stores where chainid = 44285
--update stores set Custom1 = 'CT Markets LLC' where chainid = 44285
----update mr set RequestStatus = -90, Approved = 1
------select *
----from maintenancerequests mr
----where supplierid = 41440 --Source InterLink
----and banner not in ('Albertsons - SCAL','Albertsons - ACME','Farm Fresh Markets','Shoppers Food and Pharmacy')
----and RequestStatus not in (5, -90)

update R set r.markdeleted = 1, r.deletedatetime = GETDATE()
--select *
from MaintenanceRequestS r
where RequestTypeID = 4
and SubmitDateTime > '11/10/2012'
and MarkDeleted is null



set @invalidrecordsexist = 0

set @rec = CURSOR local fast_forward FOR
	select ltrim(rtrim(banner)), isnull(costzoneid, -1), maintenancerequestid, RequestStatus, ISNULL(supplierid, 0)
	--select *
	from MaintenanceRequests
	where RequestStatus in (0, 17, -25)
	and RequestTypeID <> 8
	and isnull(Approved, -1) <> 0
	and PDIParticipant= 1
	and isnull(filetype,'ND')<>'888'
	and dtstorecontexttypeid<>1
	and productid is not null
	and datetimecreated>GETDATE()-60
open @rec

fetch next from @rec into
	@bannercheck
	,@costzoneidcheck
	, @mridcheck
	,@requeststatuscheck
	,@supplierid
	
while @@FETCH_STATUS = 0
	begin
--select * from suppliers where supplierid = 44431 update suppliers set StoreProductContextMethod = 'COSTZONE' where supplierid = 44431
		set @thisrecordisinvalid = 0
		select @storeproductcontextmethod = storeproductcontextmethod
		--select *
		from Suppliers
		where SupplierID = @supplierid
		
		If upper(@storeproductcontextmethod) = 'COSTZONE'
			begin
				set @recordcountcheck = 0
				if @costzoneidcheck <> 0
					begin
						select @recordcountcheck = costzoneid from CostZones where CostZoneID = @costzoneidcheck
						if @recordcountcheck is null
							set @recordcountcheck = 0
					
						if @recordcountcheck < 1
							begin
								set @thisrecordisinvalid = 1
								set @invalidrecordsexist = 1
							end					
					
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
		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'
		--,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;nik.baskin@icontroldsd.com;gilad.keren@icontroldsd.com;mandeep@amebasoftwares.com'
	end


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

set @atleastonefailedstorecontext = 0

set @recmrprep = CURSOR local fast_forward FOR
	select maintenancerequestid, RequestTypeId, ChainID, SupplierID, ltrim(rtrim(isnull(Banner, ''))), 
	AllStores, Cost, PromoAllowance, [StartDateTime]
      ,[EndDateTime]
      ,isnull([CostZoneID], -1)
      ,[ProductID]
      --,requeststatus
	FROM [DataTrue_Main].[dbo].[MaintenanceRequests] mr
	where 1 = 1
	and isnull(Approved, 1) <> 0
	and RequestStatus in (0, -26)
	and RequestTypeID <> 8
	and ProductId is not null
	and SupplierID is not null
	and dtstorecontexttypeid is null
	and ISNULL(PDIParticipant, 0) = 1
	and RequestTypeID in (1,2)
	and dtstorecontexttypeid<>1	
	and isnull(filetype,'ND')<>'888'
	and datetimecreated>GETDATE()-60
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
		select @storeproductcontextmethod = storeproductcontextmethod
		from Suppliers
		where SupplierID = @supplierid
		
		set @recordcount = 0
		select @recordcount = supplierid from suppliers where SupplierID = @supplierid
		if @recordcount is null
			set @recordcount = 0
			
		if @recordcount < 1
			set @recordisvalid = 0
		
		--RequestType
		
		if @requesttypeid in (1,2)
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


		select distinct custom1
		from stores where StoreID in
		(select storeid from MaintenanceRequestStores where MaintenanceRequestID = @maintenancerequestid)
		
		if @@ROWCOUNT > 1
			begin
				exec dbo.prSendEmailNotification_PassEmailAddresses 'Invalid MaintenanceRequest Stores Found in MaintenanceRequestStores Table'
				,'MaintenanceRequest records have been found that fail validation: One of the records at -26 has more than one banner of stores in that table'
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'	
				--,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;nik.baskin@icontroldsd.com;gilad.keren@icontroldsd.com;mandeep@amebasoftwares.com'
				
				set @recordisvalid = 0
			end
			
		if @recordisvalid = 1
			begin
						
				--store context
				set @recordcount = 0
				
				select @recordcount = COUNT(s.MaintenanceRequestID)
				from MaintenanceRequests m
				inner join MaintenanceRequestStores s
				on m.MaintenanceRequestID = s.MaintenanceRequestID
				and m.MaintenanceRequestID = @maintenancerequestid
				
				if @recordcount > 0
					set @storecontexttypeid = 1
				
				
				if @allstores = 1 and @storecontexttypeid = 0
					begin
						if upper(@storeproductcontextmethod) = 'BANNER'  and upper(@banner) = 'ALL'
							begin
								set @storecontexttypeid = 5
							end
					
						if upper(@storeproductcontextmethod) = 'COSTZONE'  and @storecontexttypeid = 0
							begin
								set @recordcount = 0
								select @recordcount = costzoneid from CostZones where CostZoneID = @costzoneid and SupplierId = @supplierid
								if @recordcount is null
									set @recordcount = 0
									
								if @recordcount > 0
									begin
										set @storecontexttypeid = 3
									end
				
						end
														
						if upper(@storeproductcontextmethod) = 'BANNER'  and upper(@banner) <> 'ALL' and @storecontexttypeid = 0
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
					end --------------


			end
			
			
		if @storecontexttypeid <> 0
			begin
				update MaintenanceRequests 
				set dtstorecontexttypeid = @storecontexttypeid
				,RequestStatus = 1 
				where MaintenanceRequestID = @maintenancerequestid	
			end	
		else
			begin
				update MaintenanceRequests set RequestStatus = -26 where MaintenanceRequestID = @maintenancerequestid	
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
		exec dbo.prSendEmailNotification_PassEmailAddresses 'Invalid MaintenanceRequest Store Context Found'
		,'MaintenanceRequest records have been found that fail validation and can not be assigned a dtstorecontexttypeid value.  Also, cost or promoallowance values must be valid depending on requesttype.  These records remain with a null dtstorecontexttypeid value and will not be processed until the invalid value is corrected.  Please review all records with -26 requeststatus and correct the values asap.'
		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'	
		--,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;nik.baskin@icontroldsd.com;gilad.keren@icontroldsd.com;mandeep@amebasoftwares.com'	
	
	end

return
GO
