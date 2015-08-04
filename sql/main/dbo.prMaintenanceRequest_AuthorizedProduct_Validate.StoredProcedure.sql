USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_AuthorizedProduct_Validate]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_AuthorizedProduct_Validate]

as

declare @rec cursor
declare @upc nvarchar(50)
declare @productid int
declare @supplierid int
declare @banner nvarchar(50)
declare @maintenancerequestid int
declare @productdescription nvarchar(100)
declare @costzoneid int
declare @dtstorecontexttypeid int
declare @isproductfound tinyint
declare @isproductauthorized tinyint
declare @productpricetypeid tinyint
declare @loadstatus int =-30
declare @productidonnewitemrequest int
declare @atleastonesettoNeg30 bit
declare @chainid int
declare @rowcount int

set @rec = CURSOR local fast_forward FOR
	select   maintenancerequestid, LTRIM(rtrim(upc12)), SupplierID,Banner,dtstorecontexttypeid,CostZoneID, ProductID, chainid
	--select approved ,*
	from dbo.MaintenanceRequests
	where 1 = 1
	--and RequestStatus in (-30)
	and (RequestStatus in (0, 1, -30) or (SupplierID = 40559 and RequestStatus in (17)))
	and ProductId is not null
	and ((requesttypeid in (2,3,4)and ISNULL(Approved, -1) <> 0) )
	--and Approved = 1
	--and Approved is null
	and LEN(LTRIM(rtrim(upc12))) >= 12
	and ISNULL(filetype,'N')<>'888'
	and SubmitDateTime >= DATEADD(day, -60, getdate())
	--order by requeststatus
	
open @rec

fetch next from @rec into @maintenancerequestid, @upc, @supplierID,@banner,@dtstorecontexttypeid,@costzoneid, @productID, @chainid 

set @atleastonesettoNeg30 = 0

while @@FETCH_STATUS = 0
	begin
	
		set @isproductauthorized=0
		--set @productid = null
		set @productdescription = null
			if @productid is null
				begin
				
					select @productid = productid from ProductIdentifiers 
					where LTRIM(rtrim(identifiervalue)) = @upc
					and ProductIdentifierTypeID =2				
				
				end


			
			if @productid is not null
				begin
					
					if @dtstorecontexttypeid=1
						Begin	
						
							set @rowcount = 0
							
							select @rowcount = COUNT(*)				
							--select *
							from StoreSetup
							where 1=1
							and ProductID = @productid
							and SupplierID = @supplierid
							and StoreID in
							(select storeid 
							from MaintenanceRequestStores
							where MaintenanceRequestID = @maintenancerequestid)
					
							if @rowcount > 0
							--if @@ROWCOUNT > 0
								set @isproductauthorized=1
						end
					if @dtstorecontexttypeid=2
						Begin	
						
							set @rowcount = 0
											
							select @rowcount = COUNT(*)				
							--select *
							from StoreSetup
							where 1=1
							and ProductID = @productid
							and SupplierID = @supplierid
							and StoreID in
							(select storeid 
							from stores
							where LTRIM(rtrim(custom1)) = @banner)
					
							if @rowcount > 0
							--if @@ROWCOUNT > 0
								set @isproductauthorized=1
						end
							/***********added by Irina on 03022015
					         to chech regulated record	
					         **********************/
						if @dtstorecontexttypeid=4
						Begin						
							select top 1 *
							from StoreSetup
							where 1=1
							and ProductID = @productid
							and SupplierID = @supplierid
							and StoreID in
							(select storeid 
							from stores
							where LTRIM(rtrim(custom1)) = @banner)
					
							if @@ROWCOUNT > 0
								set @isproductauthorized=1
						end
						
						
					if @dtstorecontexttypeid=3
						Begin
						
						set @rowcount = 0						
						
						if @costzoneid = 0
							begin
							select @rowcount = COUNT(*)				
							--select *
								from StoreSetup
								where 1=1
								and ProductID = @productid
								and SupplierID = @supplierid
								and StoreID in
								(select storeid from stores where ChainID = @chainid)
							end
						else
							begin
							select @rowcount = COUNT(*)				
							--select *
								from StoreSetup
								where 1=1
								and ProductID = @productid
								and SupplierID = @supplierid
								and StoreID in
								(select storeid 
								from CostZoneRelations r
								inner join CostZones z
								on r.CostZoneID = z.CostZoneID
								where z.CostZoneID = @costzoneid)
							end
							if @rowcount > 0
							--if @@ROWCOUNT > 0
								set @isproductauthorized=1
						end

						
					if @isproductauthorized = 1
						Begin
							select @productdescription = description from Products where ProductID = @productid
							
							update MaintenanceRequests set requeststatus = case when Supplierid = 40559 and RequestTypeID IN (1,2) then 17 else 1 end, Productid = @productid, upc12 =@upc, dtproductdescription = @productdescription
							where MaintenanceRequestID = @maintenancerequestid
							
						end
						
				end
			else --@@Rowcount > 0
				begin
				
							set @productidonnewitemrequest = null
							
							select @productidonnewitemrequest = productid from MaintenanceRequests
							where RequestTypeID in (1,2)--RequestTypeID=1
							and Approved=1
							and upc12=@upc
							and Banner=@banner
							
							if @@ROWCOUNT > 0
								begin
									set @isproductauthorized = 1
									if @productidonnewitemrequest is not null
										begin
											select @productdescription = description from Products where ProductID = @productidonnewitemrequest
											update MaintenanceRequests set requeststatus = case when Supplierid = 40559 and RequestTypeID IN (1,2) then 17 else 1 end, Productid = @productidonnewitemrequest, upc12 =@upc, dtproductdescription = @productdescription
											where MaintenanceRequestID = @maintenancerequestid								
										end

								end				
				
				end
				
				if @isproductauthorized = 0
					begin
						update MaintenanceRequests set RequestStatus=-30
						where MaintenanceRequestID = @maintenancerequestid
						
						set @atleastonesettoNeg30 = 1
						
						
						
					end
				
			
		fetch next from @rec into @maintenancerequestid, @upc, @supplierID,@banner,@dtstorecontexttypeid,@costzoneid, @productID, @chainid 
	end
	
close @rec
deallocate @rec

		if @atleastonesettoNeg30 = 1
			begin
				exec dbo.prSendEmailNotification_PassEmailAddresses 'Requests for Unauthorized Items Found in MaintenanceRequests Table'
				,'MaintenanceRequest records have been found for cost changes or promotions that are for items not authorized in StoreSetup. These records have been pended to a -30 RequestStatus.'
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;irina.trush@icucsolutions.com'	
				--,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;edi@icontroldsd.com'	
			end



update r2 set r2.requeststatus = 0
--select r2.requeststatus, *
from maintenancerequests r1
inner join maintenancerequests r2
on ltrim(rtrim(r1.UPC)) = ltrim(rtrim(r2.UPC))
and ltrim(rtrim(r1.Banner)) = ltrim(rtrim(r2.Banner))
and r1.supplierid = r2.supplierid
and r1.requeststatus in (2)
--and r2.requeststatus = -30
and r2.requeststatus in (-30, -25, -26)
and r1.requesttypeid = 1
and r2.requesttypeid = 2
and r1.cost = 0
and r1.supplierid = 40559
and isnull(r1.approved, 0) =1
and isnull(r2.approved, 1) <> 0

update r2 set r2.requeststatus = 0
--select r2.requeststatus, *
from maintenancerequests r1
inner join maintenancerequests r2
on ltrim(rtrim(r1.UPC)) = ltrim(rtrim(r2.UPC))
and ltrim(rtrim(r1.Banner)) = ltrim(rtrim(r2.Banner))
and r1.supplierid = r2.supplierid
and r1.requeststatus in (2)
--and r2.requeststatus = -30
and r2.requeststatus in (-30, -25, -26)
and r1.requesttypeid in (1,2)
and r2.requesttypeid = 2
and r2.cost > 0
and r1.approved=1
and isnull(r2.approved, 1) <> 0
GO
