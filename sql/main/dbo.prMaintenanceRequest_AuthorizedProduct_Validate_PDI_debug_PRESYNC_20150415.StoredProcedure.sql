USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_AuthorizedProduct_Validate_PDI_debug_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Batch submitted through debugger: SQLQuery295.sql|7|0|C:\Users\irina.trush\AppData\Local\Temp\7\~vs6297.sql
CREATE procedure [dbo].[prMaintenanceRequest_AuthorizedProduct_Validate_PDI_debug_PRESYNC_20150415]

as

declare @rec cursor
declare @upc nvarchar(50)
declare @productid int
declare @supplierid int
declare @banner nvarchar(50)
declare @maintenancerequestid int
declare @productdescription nvarchar(100)
declare @costzoneid int
declare @OwnerMarketID nvarchar(15)
declare @dtstorecontexttypeid int
declare @isproductfound tinyint
declare @isproductauthorized tinyint
declare @productpricetypeid tinyint
declare @loadstatus int =-30
declare @productidonnewitemrequest int
declare @atleastonesettoNeg30 bit
declare @chainid int
declare @vin nvarchar(50)

set @rec = CURSOR local fast_forward FOR
	select maintenancerequestid, LTRIM(rtrim(upc)), SupplierID,Banner,dtstorecontexttypeid,CostZoneID,OwnerMarketID, ProductID, Chainid, VIN
	--select *
	from dbo.MaintenanceRequests
	where 1 = 1
	and RequestStatus in (0, 1, -30)
	--and ProductId is not null
	and requesttypeid in (3,4)
	and ISNULL(Approved, 1) <> 0
	and dtstorecontexttypeid is not null
	and LEN(LTRIM(rtrim(upc))) = 12
	and ISNULL(PDIParticipant, 0) = 1
	--and ChainID = 65726
	and CAST(datetimecreated as date) >GETDATE()-120
	and SupplierID=80248 and RequestTypeID=3 and datetimecreated>='3/2/15'
	
open @rec

fetch next from @rec into @maintenancerequestid, @upc, @supplierID,@banner,@dtstorecontexttypeid,@costzoneid, @OwnerMarketID,@productID, @chainid, @vin

set @atleastonesettoNeg30 = 0

while @@FETCH_STATUS = 0
	begin
	
		set @isproductauthorized=0
		--set @productid = null
		set @productdescription = null
			if @productid is null
				begin
				
					select @productid = productid from SupplierPackages --select @productid = productid from ProductIdentifiers 
					where LTRIM(rtrim(VIN)) = @vin --where LTRIM(rtrim(identifiervalue)) = @upc
					and SupplierID = @supplierid --and ProductIdentifierTypeID = 2		
					and OwnerEntityID = @chainid			
				
				end


			
			if @productid is not null
				begin
					
					if @dtstorecontexttypeid=1
						Begin						
							select top 1 *
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
							if @costzoneid <> 0
								begin
									select top 1 *
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
							else
								begin
									--select *
									--from StoreSetup
									--where 1=1
									--and ProductID = @productid
									--and SupplierID = @supplierid
									--and StoreID in
									--(select storeid 
									--from CostZoneRelations r
									--inner join CostZones z
									--on r.CostZoneID = z.CostZoneID
									--where z.CostZoneID = @costzoneid)
									
								select top 1 *
								from stores
								where StoreID in
										(select storeid 
										from CostZoneRelations r
										inner join CostZones z
										on r.CostZoneID = z.CostZoneID
										where z.OwnerMarketID = @OwnerMarketID
										and z.OwnerEntityID = @chainid
										and z.SupplierId = @supplierid)	
										
									if @@ROWCOUNT > 0
									set @isproductauthorized=1
									
																			
									--if @@ROWCOUNT > 0
									--set @isproductauthorized=1
								end
						end
						
					if @isproductauthorized = 1
						Begin
							--select @productdescription = description from Products where ProductID = @productid
							
							update MaintenanceRequests set requeststatus = 1--, Productid = @productid, upc12 =@upc, dtproductdescription = @productdescription
							where MaintenanceRequestID = @maintenancerequestid
							
						end
						
				end
			else --@@Rowcount > 0
				begin
				
							set @productidonnewitemrequest = null
							
							select top 1 @productidonnewitemrequest = productid from MaintenanceRequests
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
											update MaintenanceRequests set requeststatus = 1, Productid = @productidonnewitemrequest, upc12 =@upc, dtproductdescription = @productdescription
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
				
			
		fetch next from @rec into @maintenancerequestid, @upc, @supplierID,@banner,@dtstorecontexttypeid,@costzoneid,@OwnerMarketID, @productID,@chainid,@vin
	end
	
close @rec
deallocate @rec

		if @atleastonesettoNeg30 = 1
			begin
				exec dbo.prSendEmailNotification_PassEmailAddresses 'Requests for Unauthorized Items Found in MaintenanceRequests Table'
				,'MaintenanceRequest records have been found for cost changes or promotions that are for items not authorized in StoreSetup. These records have been pended to a -30 RequestStatus.'
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'	
				--,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;edi@icontroldsd.com'	
			end
GO
