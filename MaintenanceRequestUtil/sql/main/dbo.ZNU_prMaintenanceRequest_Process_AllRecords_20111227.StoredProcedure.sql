USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[ZNU_prMaintenanceRequest_Process_AllRecords_20111227]    Script Date: 06/25/2015 18:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[ZNU_prMaintenanceRequest_Process_AllRecords_20111227]
as

/*
select * into import.dbo.productprices_20111227BeforeLoadAllFuturePromotions from productprices
select * from datatrue_edi.dbo.Costs order by RecordID desc
select *  FROM [DataTrue_Main].[dbo].[MaintenanceRequests] where ltrim(rtrim(upc)) = '0'

select distinct custom1 from stores


Albertsons - ACME
Albertsons - IMW
Albertsons - SCAL
Cub Foods
Farm Fresh Markets
Hornbachers
Shop N Save Warehouse Foods Inc
Shoppers Food and Pharmacy

select *
--update r set r.banner = 'Albertsons - SCAL', dtstorecontexttypeid = 2  
FROM [DataTrue_Main].[dbo].[MaintenanceRequests] r
where requeststatus = 0
and approved = 1
and allstores = 1
and banner = 'ALBERTSON''S -SCAL'

select *  
FROM [DataTrue_Main].[dbo].[MaintenanceRequests] r
where requeststatus = 0
and approved = 1
and allstores = 1
and banner <> 'all'
and ltrim(rtrim(banner)) not in
(select distinct custom1 from stores)


and supplierid = 41342

select *  
FROM [DataTrue_Main].[dbo].[MaintenanceRequests] r
inner join (select distinct custom1 from stores) s
on ltrim(rtrim(banner)) = ltrim(rtrim(s.custom1))
where requeststatus = 0
and approved = 1
and allstores = 1
and supplierid = 41342

select *  FROM [DataTrue_Main].[dbo].[MaintenanceRequests] where supplierid = 41342

select * from datatrue_edi.dbo.Costs
where dtmaintenancerequestid = 385

select *
--delete  
FROM [DataTrue_Main].[dbo].[MaintenanceRequests] 
--inner join datatrue_edi.dbo.Costs c
--on r.datatrue_edi_costs_recordid = c.recordid
where ltrim(rtrim(upc)) = '0'

select * into import.dbo.productprices_20111222Before257NestleRetroCostUpdatesAnd879Updates from productprices

select * from productprices where activestartdate = '12/30/2011' and activelastdate = '12/31/2011'

select * from datatrue_edi.dbo.promotions order by recordid desc
select distinct datetimecreated from datatrue_edi.dbo.promotions
update datatrue_edi.dbo.promotions set datetimecreated = '11/29/2011' where datetimecreated is null

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
declare @edibanner nvarchar(50)
declare @storedunsnumber nvarchar(50)
declare @tradingpartnervalue nvarchar(50)
declare @tradingpartnerpromotionidentifier nvarchar(50)
declare @suppliername nvarchar(50)
declare @showquery bit=0
declare @applyupdate bit=1
declare @applyedistatusupdate bit=1

 set @recmr = CURSOR local fast_forward FOr
 
 SELECT top 50 maintenancerequestid
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
      ,TradingPartnerPromotionIdentifier
      --select *
  FROM [DataTrue_Main].[dbo].[MaintenanceRequests]
	where 1 = 1
	--and RequestStatus = -200
	and RequestStatus = 0
	and RequestTypeID in (3)
	--and [Cost] <> 0 
	--and RequestTypeID in (1,2,3,4,5) 
	and ProductId is not null
	and Approved = 1
	--and dtstorecontexttypeid = 2
	and dtstorecontexttypeid is not null
	--and (CAST(StartDateTime AS date) <= '1/8/2012')
	--and SupplierID = 41342
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
	,@tradingpartnerpromotionidentifier

while @@FETCH_STATUS = 0
	begin
print @productid
print @supplierid
print @startdate
print @enddate
print @storecontexttypeid
print @banner

		select @suppliername = SupplierName
		from Suppliers 
		where SupplierID = @supplierid

		set @tradingpartnervalue = 						
		case when @SupplierId = 41464 then  'LWS'
			when  @SupplierId = 40557 then 'BIM'
			when @SupplierId = 41465 then 'SAR'
			when @SupplierId = 40559  then 'NST'
			when @SupplierId = 41342  then 'DIA'
		else null
		end		

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
				if @edipromorecordid is not null
					begin
						update datatrue_edi.dbo.Promotions
						set Loadstatus = 10, dtmaintenancerequestid = @maintenancerequestid
						where RecordID = @edipromorecordid
					end
				else
					begin
						if @storecontexttypeid = 2 and @applyedistatusupdate = 1
						  begin
							set @storedunsnumber =					
							case 
								when LTRIM(rtrim(@banner)) = 'Farm Fresh Markets' then '1939636180000'
								when LTRIM(rtrim(@banner)) = 'Albertsons - SCAL' then '0069271863600'
								when LTRIM(rtrim(@banner)) = 'Albertsons - IMW'  then '0069271833301'
								when LTRIM(rtrim(@banner)) = 'Albertsons - ACME' then '0069271877700'
								when LTRIM(rtrim(@banner)) = 'Cub Foods' then '0032326880002'
								when LTRIM(rtrim(@banner)) = 'Shop N Save Warehouse Foods Inc' then '8008812780000'
								when LTRIM(rtrim(@banner)) = 'Hornbachers' then '0299516910000'
								when LTRIM(rtrim(@banner)) = 'Shoppers Food and Pharmacy' then '4233100000000'
							else null
							end	

							set @edibanner =					
							case 
								when LTRIM(rtrim(@banner)) = 'Farm Fresh Markets' then 'SV'
								when LTRIM(rtrim(@banner)) = 'Albertsons - SCAL' then 'ABS'
								when LTRIM(rtrim(@banner)) = 'Albertsons - IMW'  then 'ABS'
								when LTRIM(rtrim(@banner)) = 'Albertsons - ACME' then 'ABS'
								when LTRIM(rtrim(@banner)) = 'Cub Foods' then 'SV'
								when LTRIM(rtrim(@banner)) = 'Shop N Save Warehouse Foods Inc' then 'SS'
								when LTRIM(rtrim(@banner)) = 'Hornbachers' then 'SV'
								when LTRIM(rtrim(@banner)) = 'Shoppers Food and Pharmacy' then 'SV'
								
							else null
							end	
				--corporatename = custom1, corporateidentifier = dunsnumber, banner = custom3, suppliername
				--006 for banner 002 for store
						INSERT INTO [DataTrue_EDI].[dbo].[Promotions]
								   ([MarketAreaCodeIdentifier]
								   ,[SupplierIdentifier]
								   ,[DateStartPromotion]
								   ,[DateEndPromotion]
								   ,[PromotionNumber]
								   ,[CorporateName]
								   ,[CorpIdentifier]
								   ,[ProductName]
								   ,[Allowance_ChargeRate]
								   ,[RawProductIdentifier]
								   ,[ProductIdentifier]
								   ,[Loadstatus]
								   ,[chainid]
								   ,[productid]
								   ,[brandid]
								   ,[supplierid]
								   ,[banner]
								   ,[SupplierName]
								   ,[dtstorecontexttypeid]
								   ,[dtmaintenancerequestid]
								   ,[Recordsource]
								   ,[dtbanner])
								   values('006'
								   ,@tradingpartnervalue
								   ,@startdate
								   ,@enddate
								   ,isnull(@tradingpartnerpromotionidentifier, 'MR-' + LTRIM(rtrim(@tradingpartnervalue)) + '-' + @upc12 + LEFT(replace(replace(cast(@startdate as nvarchar), ' ', ''), ':',''), 11))
								   ,@banner
								   ,@storedunsnumber
								   ,@itemdescription
								   ,ltrim(rtrim(cast(@pricevaluetopass as nvarchar)))
								   ,@upc
								   ,@upc12
								   ,10 --loadstatus
								   ,@chainid
								   ,@productid
								   ,@brandid
								   ,@supplierid
								   ,@edibanner
								   ,@suppliername
								   ,2 --storecontexttypeid
								   ,@maintenancerequestid
								   ,'MR'
								   ,@banner)
							end
				
						end
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
			,@tradingpartnerpromotionidentifier
	end
	
close @recmr
deallocate @recmr




return
GO
