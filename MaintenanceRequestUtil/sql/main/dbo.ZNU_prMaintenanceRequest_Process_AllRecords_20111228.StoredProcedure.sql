USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[ZNU_prMaintenanceRequest_Process_AllRecords_20111228]    Script Date: 06/25/2015 18:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[ZNU_prMaintenanceRequest_Process_AllRecords_20111228]
as

/*
select * into import.dbo.productprices_20111227BeforeLoadAllFuturePromotions from productprices
select * from datatrue_edi.dbo.Costs order by RecordID desc
select *  FROM [DataTrue_Main].[dbo].[MaintenanceRequests] where ltrim(rtrim(upc)) = '0'

select *  FROM [DataTrue_Main].[dbo].[MaintenanceRequests] where requeststatus = 0
order by submitdatetime desc

select *
--update 
FROM [DataTrue_Main].[dbo].[MaintenanceRequests] r
inner join Maintenancerequeststores s
on r.Maintenancerequestid = s.Maintenancerequestid
inner join datatrue_edi.dbo.promotions c
on s.storeid = c.storeid
and r.upc = c.productidentifier
and r.startdatetime = c.DateStartPromotion
and r.enddatetime = c.DateEndPromotion
and c.dtbanner = ''


select *
--delete  
FROM [DataTrue_Main].[dbo].[MaintenanceRequests] 
--inner join datatrue_edi.dbo.Costs c
--on r.datatrue_edi_costs_recordid = c.recordid
where ltrim(rtrim(upc)) = '0'

select * into import.dbo.productprices_20111222Before257NestleRetroCostUpdatesAnd879Updates from productprices

select * from productprices where activestartdate = '12/30/2011' and activelastdate = '12/31/2011'
truncate table dbo.tmpMaintenanceRequestStoreIDList
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
declare @applyedistatusupdate bit=1
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
declare @showquery bit=0


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
      --select *
  FROM [DataTrue_Main].[dbo].[MaintenanceRequests]
	where 1 = 1
	--and RequestStatus = -200
	and RequestStatus = 0
	and RequestTypeID in (3)
	--and [Cost] <> 0 
	and RequestTypeID in (1,2,3,4,5) 
	and ProductId is not null
	--and Approved = 1
	--and dtstorecontexttypeid = 2
	and dtstorecontexttypeid is not null
	--and (CAST(StartDateTime AS date) <= '1/8/2012')
	order by Startdatetime
	--order by MaintenanceRequestID

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
print @pricevaluetopass				
		set @enddate =
			case when @requesttypeid IN (1, 2) then '12/31/2099'
				when  @requesttypeid IN (3, 4, 5) then @enddate
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
						if @showquery = 1
							begin 
								select *
								from ProductPrices
								where ProductPriceTypeID = @productpricetypeid
								and ProductID = @productid
								and SupplierID = @supplierid
								and StoreID in
								(select storeid 
								from dbo.MaintenanceRequestStores 
								where MaintenanceRequestID = @maintenancerequestid)
							end							
					end
				If @storecontexttypeid = 2 --Banner (custom1 in stores table)
					begin
						insert into tmpMaintenanceRequestStoreIDList
						select @uniqueid, storeid 
						from stores
						where LTRIM(rtrim(custom1)) = @banner
						
						if @showquery = 1
							begin 
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
					end				
				If @storecontexttypeid = 3 --CostZoneID
					begin
						insert into tmpMaintenanceRequestStoreIDList
						select @uniqueid, storeid 
						from CostZoneRelations r
						inner join CostZones z
						on r.CostZoneID = z.CostZoneID
						where z.CostZoneID = @costzoneid
						
						if @showquery = 1
							begin 						
								select *
								from ProductPrices
								where ProductPriceTypeID = @productpricetypeid
								and ProductID = @productid
								and SupplierID = @supplierid
								and StoreID in
								(select storeid 
								from CostZoneRelations r
								inner join CostZones z
								on r.CostZoneID = z.CostZoneID
								where z.CostZoneID = @costzoneid)
							end
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
				If @storecontexttypeid = 5 --All Stores Supplier Serves
					begin
						insert into tmpMaintenanceRequestStoreIDList
						select distinct @uniqueid, storeid 
						from StoreTransactions
						where SupplierID = @supplierid
						
						select *
						from ProductPrices
						where ProductPriceTypeID = @productpricetypeid
						and ProductID = @productid
						and SupplierID = @supplierid
						and StoreID in
						(select distinct storeid 
						from StoreTransactions
						where SupplierID = @supplierid)
					end						
																
				set @recstores = CURSOR local fast_forward FOR 
					select storeid from tmpMaintenanceRequestStoreIDList
					where ID = @uniqueid

					
				open @recstores
				
				fetch next from @recstores into @storeid
				
				while @@FETCH_STATUS = 0
					begin
					
					if @applyupdate = 1
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
						end			
					
					
					
						fetch next from @recstores into @storeid
					end
					
				
				close @recstores
				deallocate @recstores
				
					If @storecontexttypeid = 2 and @applyupdate = 1  and @showquery = 1 --Banner (custom1 in stores table)
					begin
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
			
					If @storecontexttypeid = 3 and @applyupdate = 1 and @showquery = 1 
					  begin
						select *
						from ProductPrices
						where ProductPriceTypeID = @productpricetypeid
						and ProductID = @productid
						and SupplierID = @supplierid
						and StoreID in
						(select storeid 
						from CostZoneRelations r
						inner join CostZones z
						on r.CostZoneID = z.CostZoneID
						where z.CostZoneID = @costzoneid)
					  end			
				If @storecontexttypeid = 5  and @showquery = 1 --All Stores Supplier Serves
					begin
						select *
						from ProductPrices
						where ProductPriceTypeID = @productpricetypeid
						and ProductID = @productid
						and SupplierID = @supplierid
						and StoreID in
						(select distinct storeid 
						from StoreTransactions
						where SupplierID = @supplierid)
					end				
			
			end

		delete from tmpMaintenanceRequestStoreIDList where ID = @uniqueid
		
		if @requesttypeid in (1, 2) and @applyedistatusupdate = 1
			begin
				update datatrue_edi.dbo.Costs
				set RecordStatus = 10, dtmaintenancerequestid = @maintenancerequestid
				where RecordID = @edicostrecordid
			end
		if @requesttypeid in (3, 4, 5) and @applyedistatusupdate = 1
			begin
				update datatrue_edi.dbo.Promotions
				set Loadstatus = 10, dtmaintenancerequestid = @maintenancerequestid
				where RecordID = @edipromorecordid
			end			
		if  @applyupdate = 1 or @applyedistatusupdate = 1
			begin
				update MaintenanceRequests set RequestStatus = 5
				where MaintenanceRequestID = @maintenancerequestid
			end
		
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
