USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[ZNU_prMaintenanceRequest_Process_AllRecords_20111219]    Script Date: 06/25/2015 18:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[ZNU_prMaintenanceRequest_Process_AllRecords_20111219]
as

/*
select * from datatrue_edi.dbo.Costs order by RecordID desc
*/

declare @recmr cursor
declare @recstores cursor
declare @requesttypeid smallint
declare @chainid int
declare @supplierid int
declare @banner nvarchar(50)
declare @allstores smallint
declare @upc nvarchar(50)
declare @brandidentifier nvarchar(50)
declare @itemdescription nvarchar(255)
declare @currentsetupcosts money
declare @requestedcost money
declare @suggestedretail money
declare @promotypeid smallint
declare @promoallowance money
declare @startdate datetime
declare @enddate datetime
declare @costzoneid int
declare @productid int
declare @applyupdate bit=1
declare @maintenancerequestid int
declare @upc12  nvarchar(50)
declare @edicostrecordid int
declare @edipromorecordid int
declare @storecontexttypeid smallint
declare @productpricetypeid smallint
declare @cusrosql nvarchar(2000)
declare @uniqueid uniqueidentifier
declare @storeid int
declare @pricevaluetopass money
declare @brandid int


 set @recmr = CURSOR local fast_forward FOr
 
 SELECT maintenancerequestid
		,[RequestTypeID]
      ,[ChainID]
      ,[SupplierID]
      ,ltrim(rtrim([Banner]))
      ,[AllStores]
      ,ltrim(rtrim([UPC]))
      ,[BrandIdentifier]
      ,[ItemDescription]
      ,[CurrentSetupCost]
      ,[Cost]
      ,isnull([SuggestedRetail], 0.00)
      ,[PromoTypeID]
      ,case when [PromoAllowance] <  0 then [PromoAllowance] * -1 else [PromoAllowance] end
      ,[StartDateTime]
      ,[EndDateTime]
      ,[CostZoneID]
      ,[ProductID]
      ,[upc12]
      ,[datatrue_edi_costs_recordid]
      ,[datatrue_edi_promotions_recordid]
      ,[dtstorecontexttypeid]
      ,isnull([BrandID], 0)
  FROM [DataTrue_Main].[dbo].[MaintenanceRequests]
	where RequestStatus = 0
	--and RequestTypeID in (3)
	--and [Cost] <> 0 
	and RequestTypeID in (1,2,3,4,5) 
	and ProductId is not null
	and Approved = 1
	and dtstorecontexttypeid is not null
	and (CAST(StartDateTime AS date) <= '12/25/2011')
	order by MaintenanceRequestID

open @recmr
--select top 100 *   FROM [DataTrue_Main].[dbo].[MaintenanceRequests] where requeststatus = 0 and approved = 1
fetch next from @recmr into
	@maintenancerequestid
	,@requesttypeid
	, @chainid
	, @supplierid
	, @banner
	, @allstores
	, @upc
	, @brandidentifier
	, @itemdescription
	, @currentsetupcosts
	, @requestedcost
	, @suggestedretail
	, @promotypeid
	, @promoallowance
	, @startdate
	, @enddate
	, @costzoneid
	,@productid
	,@upc12
	,@edicostrecordid
	,@edipromorecordid
	,@storecontexttypeid
	,@brandid

while @@FETCH_STATUS = 0
	begin
print @productid
print @supplierid
print @startdate
print @enddate
print @storecontexttypeid
print @banner
		set @productpricetypeid =
			case when @requesttypeid IN (1, 2) then 3
				when  @requesttypeid IN (3, 4, 5) then 8
			end


		set @pricevaluetopass =
			case when @requesttypeid IN (1, 2) then @requestedcost
				when  @requesttypeid IN (3, 4, 5) then @promoallowance
			end			
			
			
		if @productpricetypeid is not null
			begin
			
				set @uniqueid = NEWID()
				
				If @storecontexttypeid = 1 --Store Specific
					begin
						insert into tmpMaintenanceRequestStoreIDList
						select @uniqueid, storeid 
						from dbo.MaintenanceRequestStores 
						where MaintenanceRequestID = @maintenancerequestid
					end
				If @storecontexttypeid = 2 --Banner (custom1 in stores table)
					begin
						insert into tmpMaintenanceRequestStoreIDList
						select @uniqueid, storeid 
						from stores
						where LTRIM(rtrim(custom1)) = @banner
						
						select *
						from ProductPrices
						where ProductPriceTypeID = @productpricetypeid
						and ProductID = @productid
						and SupplierID = @supplierid
						and StoreID in
						(select storeid 
						from stores
						where LTRIM(rtrim(custom1)) = @banner)
					end				
				If @storecontexttypeid = 3 --CostZoneID
					begin
						insert into tmpMaintenanceRequestStoreIDList
						select @uniqueid, storeid 
						from CostZoneRelations r
						inner join CostZones z
						on r.CostZoneID = z.CostZoneID
						where z.CostZoneID = @costzoneid
					end		
				If @storecontexttypeid = 4 --CostZoneName
					begin
						insert into tmpMaintenanceRequestStoreIDList
						select @uniqueid, storeid 
						from CostZoneRelations r
						inner join CostZones z
						on r.CostZoneID = z.CostZoneID
						where ltrim(rtrim(z.CostZoneName)) = cast(@costzoneid as nvarchar)
					end												
				set @recstores = CURSOR local fast_forward FOR 
					select storeid from tmpMaintenanceRequestStoreIDList
					where ID = @uniqueid

					
				open @recstores
				
				fetch next from @recstores into @storeid
				
				while @@FETCH_STATUS = 0
					begin
					
					
						exec [dbo].[prProductPrice_Manage]
						@chainid
						,@storeid
						,@productid
						,@brandid
						,@supplierid
						,@productpricetypeid
						,@pricevaluetopass
						,@startdate
						,@enddate
						,@suggestedretail
						,0				
					
					
					
						fetch next from @recstores into @storeid
					end
					
				
				close @recstores
				deallocate @recstores
				
				
			
			
			end

		delete from tmpMaintenanceRequestStoreIDList where ID = @uniqueid
		
		if @requesttypeid in (1, 2)
			begin
				update datatrue_edi.dbo.Costs
				set RecordStatus = 10, dtmaintenancerequestid = @maintenancerequestid
				where RecordID = @edicostrecordid
			end
		if @requesttypeid in (3, 4, 5)
			begin
				update datatrue_edi.dbo.Promotions
				set Loadstatus = 10, dtmaintenancerequestid = @maintenancerequestid
				where RecordID = @edipromorecordid
			end			
			
		update MaintenanceRequests set RequestStatus = 5
		where MaintenanceRequestID = @maintenancerequestid
		
		fetch next from @recmr into
			@maintenancerequestid
			,@requesttypeid
			, @chainid
			, @supplierid
			, @banner
			, @allstores
			, @upc
			, @brandidentifier
			, @itemdescription
			, @currentsetupcosts
			, @requestedcost
			, @suggestedretail
			, @promotypeid
			, @promoallowance
			, @startdate
			, @enddate
			, @costzoneid
			,@productid
			,@upc12
			,@edicostrecordid
			,@edipromorecordid
			,@storecontexttypeid
			,@brandid
	end
	
close @recmr
deallocate @recmr




return
GO
