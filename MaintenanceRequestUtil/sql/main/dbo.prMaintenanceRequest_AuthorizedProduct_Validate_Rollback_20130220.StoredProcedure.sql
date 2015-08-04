USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_AuthorizedProduct_Validate_Rollback_20130220]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prMaintenanceRequest_AuthorizedProduct_Validate_Rollback_20130220]

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

set @rec = CURSOR local fast_forward FOR
	select maintenancerequestid, LTRIM(rtrim(upc)), SupplierID,Banner,dtstorecontexttypeid,CostZoneID
	--select *
	from dbo.MaintenanceRequests
	where 1 = 1
	and RequestStatus in (0, -30)
	--and ProductId is null
	and requesttypeid in (2,3)
	and Approved is null
	and LEN(LTRIM(rtrim(upc))) = 12
	
open @rec

fetch next from @rec into @maintenancerequestid, @upc, @supplierID,@banner,@dtstorecontexttypeid,@costzoneid

while @@FETCH_STATUS = 0
	begin
	
		set @isproductauthorized=0
		set @productid = null
		set @productdescription = null
			
			select @productid = productid from ProductIdentifiers 
			where LTRIM(rtrim(identifiervalue)) = @upc
			and ProductIdentifierTypeID = 2
			
			if @@ROWCOUNT > 0
				begin
					
					if @dtstorecontexttypeid=1
						Begin						
							select *
							from StoreSetup
							where 1=1
							and ProductID = @productid
							and SupplierID = @supplierid
							and StoreID in
							(select storeid 
							from MaintenanceRequestStores
							where MaintenanceRequestID = @maintenancerequestid)
					
							if @@ROWCOUNT > 0
								set @isproductauthorized=1
						end
					if @dtstorecontexttypeid=2
						Begin						
							select *
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
							select *
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
								
								if @@ROWCOUNT > 0
								set @isproductauthorized=1
						end
						
					if @isproductauthorized = 1
						Begin
							select @productdescription = description from Products where ProductID = @productid
							
							update MaintenanceRequests set requeststatus = 0, Productid = @productid, upc12 =@upc, dtproductdescription = @productdescription
							where MaintenanceRequestID = @maintenancerequestid
							
						end
						
				end
			else --@@Rowcount > 0
				begin
				
							set @productidonnewitemrequest = null
							
							select @productidonnewitemrequest = productid from MaintenanceRequests
							where RequestTypeID=1
							and Approved=1
							and upc12=@upc
							and Banner=@banner
							
							if @@ROWCOUNT > 0
								begin
									set @isproductauthorized = 1
									if @productidonnewitemrequest is not null
										begin
											select @productdescription = description from Products where ProductID = @productidonnewitemrequest
											update MaintenanceRequests set requeststatus = 0, Productid = @productidonnewitemrequest, upc12 =@upc, dtproductdescription = @productdescription
											where MaintenanceRequestID = @maintenancerequestid								
										end

								end				
				
				end
				
				if @isproductauthorized = 0
					begin
						update MaintenanceRequests set RequestStatus=-30
						where MaintenanceRequestID = @maintenancerequestid
					end
				
			
		fetch next from @rec into @maintenancerequestid, @upc, @supplierID,@banner,@dtstorecontexttypeid,@costzoneid
	end
	
close @rec
deallocate @rec
GO
