USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_Process_AllRecords_WithMaintenanceRequestStoresRecords_Type1and2_CheckForNoImpact]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_Process_AllRecords_WithMaintenanceRequestStoresRecords_Type1and2_CheckForNoImpact]
as
/*
--**************************Check for Type1********************************************
select Cost, Productid, dtstorecontexttypeid,  costzoneid, *
		  FROM [DataTrue_Main].[dbo].[MaintenanceRequests] mr
			where 1 = 1
			and RequestStatus in (0,1,2)
			and Approved = 1
			and RequestTypeID in (1)
			and dtstorecontexttypeid is not null
			and ProductId is not null
			and chainid = 40393
*/

declare @recmr cursor
declare @recstores cursor
declare @requesttypeid smallint
declare @chainid int
declare @recordcount int
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
declare @recbanner cursor
declare @supplierbanner nvarchar(50)
declare @requestsource nvarchar(10)

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
declare @storeidentifierfromstorestable nvarchar(50)
declare @custom1fromstorestable nvarchar(50)
declare @storedunsnumberfromstorestable nvarchar(50)
declare @storesbtnumberfromstorestable nvarchar(50)
declare @markeddeleted bit
declare @SkipPopulating879_889Records bit
declare @bannerisvalid int
declare @emailmessage nvarchar(1000)
declare @dtproductdescription nvarchar(100)
declare @recordvalidated bit
declare @PendForOverlappingDates bit
declare @supplierloginid int
declare @newitemalreadyhascost bit
declare @onlyexactmatchfound bit

declare @ApprovalDateTime datetime
declare @Approved tinyint
declare @ChainLoginID int
declare @DealNumber nvarchar(50)
declare @DeleteDateTime datetime
declare @DeleteLoginId int
declare @DeleteReason nvarchar(150)
declare @DenialReason nvarchar(150)
declare @EmailGeneratedToSupplier nvarchar(50)
declare @EmailGeneratedToSupplierDateTime DateTime
Declare @RequestStatus smallint
Declare @Skip_879_889_Conversion_ProcessCompleted int
Declare @SubmitDateTime datetime
Declare @storecountexpected int
Declare @storecountinstalled int
declare @atleastonewithnoimpact17 bit
declare @atleastonewithnoimpact18 bit
--************************************************
declare @showquery bit=0
declare @applyupdate bit=0
declare @applyedistatusupdate bit=0
declare @additemtostoresetupeveniffound bit =0
declare @displaystoresetup bit = 0
declare @additemtostoresetup bit = 0
declare @createtype2recordfromtype1record bit = 0
--*************************************************
declare @senddeletedoverlappingpromos bit=0
declare @checkforoverlappingdates bit=0
declare @removeexistingproductpricesrecordswithoverlappingdates bit=0
declare @useupcofduplicateproductids bit= 0
declare @lookforexactmatches bit = 1
declare @exactmatchfound bit


declare @foundinstoresetup int
declare @foundinproductprices int
declare @storecountincontext int
declare @thismrhasnoimpact bit
--select distinct requeststatus from maintenancerequests where requeststatus = 8
--select * from maintenancerequests where maintenancerequestid between 14131 and 14195
--update maintenancerequests set dtstorecontexttypeid = 2 where maintenancerequestid between 14131 and 14195
update  m set m.SkipPopulating879_889Records = case when SupplierID = 40558 then 1 else 0 end
--select *
from dbo.MaintenanceRequests m
where 1 = 1
and (RequestStatus = 2 or MarkDeleted = 1)
and SkipPopulating879_889Records is null
--and SupplierID = 40558

update  m set m.datatrue_edi_costs_recordid = null, m.datatrue_edi_promotions_recordid = null
--select *
from dbo.MaintenanceRequests m
where 1 = 1
and SupplierID = 40558
and (RequestStatus = 2 or MarkDeleted = 1)
and SkipPopulating879_889Records = 0

update  m set m.datatrue_edi_costs_recordid = null, m.datatrue_edi_promotions_recordid = null
--select *
from dbo.MaintenanceRequests m
where 1 = 1
and RequestStatus = 5
and (MarkDeleted = 1)
and SkipPopulating879_889Records = 0
and DeleteDateTime > '4/1/2012'

update p set p.Description = r.ItemDescription
from MaintenanceRequests r
inner join products p
on r.productid = p.productid
and upper(ltrim(rtrim(p.description))) = 'UNKNOWN'
and r.approved = 1
and r.ItemDescription is not null
and len(ltrim(rtrim(r.ItemDescription))) > 0 

set @recordcount = 0

		update mr set mr.RequestStatus = -26
		--select *
		  FROM [DataTrue_Main].[dbo].[MaintenanceRequests] mr
			where 1 = 1
			and RequestStatus in (0,1)
			and Approved = 1
			and ProductId is not null
			and RequestTypeID in (1,2)
			and ([Cost] <= 0 or [Cost] is null)
			
set @recordcount = @@ROWCOUNT

		update mr set mr.RequestStatus = -26
		--select *
		  FROM [DataTrue_Main].[dbo].[MaintenanceRequests] mr
			where 1 = 1
			and RequestStatus in (0,1)
			and Approved = 1
			and ProductId is not null
			and RequestTypeID in (3)
			and ([PromoAllowance] = 0 or [PromoAllowance] is null)
			
if @recordcount = 0
	set @recordcount = @@ROWCOUNT
			
if @recordcount > 0
	begin
		exec dbo.prSendEmailNotification_PassEmailAddresses 'Invalid MaintenanceRequest Store Context Found'
		,'MaintenanceRequest records have been found that fail validation and can not be assigned a dtstorecontexttypeid value.  Also, cost or promoallowance values must be valid depending on requesttype.  These records remain with a null dtstorecontexttypeid value and will not be processed until the invalid value is corrected.  Please review all records with -26 requeststatus and correct the values asap.'
		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;mandeep@amebasoftwares.com'	
	end
 

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
			  ,isnull([Cost], 0)
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
			  ,isnull(TradingPartnerPromotionIdentifier, 'MR-' + cast(@maintenancerequestid as nvarchar(50)))
			  ,ISNULL(MarkDeleted, 0)
			  ,SkipPopulating879_889Records
			  ,isnull(dtproductdescription, 'UNKNOWN')
			  ,SupplierLoginID
			  ,ApprovalDateTime
			  ,Approved 
			  ,ChainLoginID 
			,DealNumber
			,DeleteDateTime
			,DeleteLoginId
			,DeleteReason
			,DenialReason 
			,EmailGeneratedToSupplier 
			,EmailGeneratedToSupplierDateTime
			,RequestStatus 
			,Skip_879_889_Conversion_ProcessCompleted 
			,SubmitDateTime
			,isnull(RequestSource, '') 
			
			  --select distinct requeststatus
			  --update mr set mr.banner = 'Farm Fresh Markets', mr.dtstorecontexttypeid = 2
			  --update mr set mr.dtstorecontexttypeid = 3, costzoneid = 875, requeststatus = 0
			  --update mr set SkipPopulating879_889Records = 1
			  --update mr set mr.requeststatus = 5
			  --update mr set mr.requeststatus = 15
			  --update mr set mr.requeststatus = 16
			  --update mr set mr.requeststatus = 6
			  --update mr set mr.dtstorecontexttypeid = 3
			  --update mr set mr.dtstorecontexttypeid = 2
			  --update mr set mr.dtstorecontexttypeid = 1
			  --update mr set mr.skippopulating879_889Records = 0
			  --select distinct requeststatus
			  --update mr set mr.requeststatus = 100
			  --select ProductID,Cost,PromoAllowance,SkipPopulating879_889Records, dtstorecontexttypeid,  costzoneid, *
		  FROM [DataTrue_Main].[dbo].[MaintenanceRequests] mr
			where 1 = 1
			--and chainid = 40393
			and RequestStatus in (2)
			and Approved is null
			and RequestTypeID in (1,2)
			and isnull(MarkDeleted, 0) <> 1
			--and Cost is not null
			--and [Cost] <> 0
			and dtstorecontexttypeid is not null
			and ProductId is not null
			and DATEADD(day, -3, getdate()) < SubmitDateTime
			--and Banner = 'SHOP N SAVE WAREHOUSE FOODS INC'
			order by Startdatetime, EndDateTime

--*/

/*	
select * from datatrue_edi.dbo.edi_suppliercrossreference
*/

open @recmr
--select top 100 *   FROM [DataTrue_Main].[dbo].[MaintenanceRequests] where requeststatus = 8 and approved = 1
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
	,@markeddeleted
	,@SkipPopulating879_889Records
	,@dtproductdescription
	,@supplierloginid
	,@ApprovalDateTime
	,@Approved
	,@ChainLoginID
	,@DealNumber
	,@DeleteDateTime
	,@DeleteLoginId
	,@DeleteReason
	,@DenialReason
	,@EmailGeneratedToSupplier
	,@EmailGeneratedToSupplierDateTime
	,@RequestStatus
	,@Skip_879_889_Conversion_ProcessCompleted
	,@SubmitDateTime
	,@requestsource

set @atleastonewithnoimpact17 = 0
set @atleastonewithnoimpact18 = 0

while @@FETCH_STATUS = 0
	begin
print @maintenancerequestid
print @productid

if @useupcofduplicateproductids = 1
	begin
		print 'dupeid'
		select @productid = ProductId from ProductIdentifiers where ProductIdentifierTypeID = 2 and LTRIM(rtrim(identifiervalue)) = LTRIM(rtrim(@upc12))
		print @productid
	end
print @supplierid
print @startdate
print @enddate
print @storecontexttypeid
print @banner
print @costzoneid

		set @bannerisvalid = 0
		set @recordvalidated = 1
		set @PendForOverlappingDates = 0
		set @onlyexactmatchfound = 0
		set @newitemalreadyhascost = 0
		set @exactmatchfound = 0
		set @foundinstoresetup = 0
		
		
		
		if @storecontexttypeid not in (1,2,3,4,5) or @storecontexttypeid is null
			begin
				set @recordvalidated = 0
				set @emailmessage = 'MaintenanceRequests recordid ' + cast(@maintenancerequestid as varchar) + ' has an invalid store context value and can not be processed.  Please correct the value.'
				exec dbo.prSendEmailNotification_PassEmailAddresses 'MaintenanceRequests - Invalid Store Context'
				,@emailmessage
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'

			end
		
		if @storecontexttypeid = 2
			begin
				select @bannerisvalid = COUNT(storeid)
				from stores where LTRIM(rtrim(custom1)) = LTRIM(rtrim(@banner))
				and Custom1 is not null
				
				if @bannerisvalid is null
					set @bannerisvalid = 0
					
				if @bannerisvalid < 1 and @storecontexttypeid = 2
					begin
						set @recordvalidated = 0
						set @emailmessage = 'MaintenanceRequests recordid ' + cast(@maintenancerequestid as varchar) + ' has an invalid banner value and can not be processed.  Please correct the banner value.'
						exec dbo.prSendEmailNotification_PassEmailAddresses 'MaintenanceRequests - Invalid Store Banner'
						,@emailmessage
						,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'
					end
			end

		
		if @storecontexttypeid = 3
			begin
				select @bannerisvalid = COUNT(costzoneid)
				from costzones where LTRIM(rtrim(CostZoneID)) = LTRIM(rtrim(@costzoneid))
				and SupplierId = @supplierid
				
				if @bannerisvalid is null
					set @bannerisvalid = 0
					
				if @bannerisvalid < 1 and @storecontexttypeid = 3
					begin
						set @recordvalidated = 0
						set @emailmessage = 'MaintenanceRequests recordid ' + cast(@maintenancerequestid as varchar) + ' has an invalid costzone value and can not be processed.  Please correct the value.'
						exec dbo.prSendEmailNotification_PassEmailAddresses 'MaintenanceRequests - Invalid Cost Zone'
						,@emailmessage
						,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'
					end
			end
			
		select @suppliername = SupplierName, @tradingpartnervalue=UniqueEDIName
		from Suppliers 
		where SupplierID = @supplierid

		set @tradingpartnervalue = 						
		case when @SupplierId = 41464 then  'LWS'
			when  @SupplierId = 40557 then 'BIM'
			when @SupplierId = 41465 then 'SAR'
			when @SupplierId = 40559  then 'NST'
			when @SupplierId = 41342  then 'DIA'
			when @SupplierId = 40563 then 'MRV'
			when @SupplierId = 40570 then 'SONY'
			when @supplierid = 40567 then 'FLOW'
			when @supplierid = 40562 then 'PEP'
			when @supplierid = 40578 then 'BUR'
			when @supplierid = 40558 then 'GOP'
			when @supplierid = 41746 then 'DSW'
			when @supplierid = 40560 then 'RUG'
			when @supplierid = 41440 then 'SOUR'
			when @supplierid = 42148 then 'TTT'
			when @supplierid = 40561 then 'SHM'
		else @tradingpartnervalue
		end		
		
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
		
		set @productpricetypeid = 3
			--case when @requesttypeid IN (1, 2) then 3
			--	when  @requesttypeid IN (3, 4, 5) then 8
			--end


		set @pricevaluetopass = @requestedcost
			--case when @requesttypeid IN (1, 2) then @requestedcost
			--	when  @requesttypeid IN (3, 4, 5) then @promoallowance
			--end		
print @pricevaluetopass				
		set @enddate = '12/31/2099'
			--case when @requesttypeid IN (1, 2) then '12/31/2099'
			--	when  @requesttypeid IN (3, 4, 5) then @enddate
			--end	
			
--declare @chainid int=40393 declare @userequestproductdescription nvarchar(10) declare @clusterid int	declare @banner nvarchar(50)='Shop N Save Warehouse Foods Inc'		
declare @userequestproductdescription nvarchar(10)
declare @clusterid int
		set @clusterid = null
		
		select @clusterid = clusterid from Clusters where ChainID = @chainid and ltrim(rtrim(ClusterName)) = LTRIM(rtrim(@banner))
				
		if @@ROWCOUNT > 0
			begin
			
				set @userequestproductdescription = null
				
				select @userequestproductdescription = v.AttributeValue
				from AttributeDefinitions d
				inner join AttributeValues v
				on d.AttributeID = v.AttributeID
				and d.AttributeName = 'UseRequestProductDescription'
				and v.OwnerEntityID = @clusterid
				
				if ISNULL(@userequestproductdescription, 'NO') <> 'YES'
					begin
						set @userequestproductdescription = 'NO'
					end
			end
		else
			begin
				set @userequestproductdescription = 'NO'
			end	
			
		if @userequestproductdescription = 'YES'
			begin
				set @dtproductdescription = @itemdescription
			end		
			
		if @productpricetypeid is not null
			begin
						set @thismrhasnoimpact = 0

						--select @storecountexpected = Count(storesetupid)
						--(select storeid 
						--from dbo.MaintenanceRequestStores 
						--where MaintenanceRequestID = @maintenancerequestid)

						select @storecountinstalled = COUNT(StoreSetupID)
						from storesetup
						where ProductID = @productid
						and SupplierID = @supplierid
						and StoreID in
						(select storeid 
						from dbo.MaintenanceRequestStores 
						where MaintenanceRequestID = @maintenancerequestid)

			
						--if @showquery = 1
						--	begin 
								select *
								from ProductPrices
								where ProductPriceTypeID = @productpricetypeid
								and ProductID = @productid
								and SupplierID = @supplierid
								and StoreID in
								(select storeid 
								from dbo.MaintenanceRequestStores 
								where MaintenanceRequestID = @maintenancerequestid)
								
								if @@ROWCOUNT > 0
									set @newitemalreadyhascost = 1
									
								if @displaystoresetup = 1
									begin
										select *
										from storesetup
										where ProductID = @productid
										and SupplierID = @supplierid
										and StoreID in
										(select storeid 
										from dbo.MaintenanceRequestStores 
										where MaintenanceRequestID = @maintenancerequestid)
									end							
									
							--end
----------------------------------------------------------------------------------------------------------
						--If @additemtostoresetup = 1 --and @additemtostoresetupeveniffound = 0
						--	begin
							
								select @storecountincontext = COUNT(storeid) 
									from dbo.MaintenanceRequestStores 
									where MaintenanceRequestID = @maintenancerequestid
							
								select @foundinstoresetup = COUNT(storesetupid)
								from storesetup
								where ProductID = @productid
								and SupplierID = @supplierid
								and StoreID in
										(select storeid 
										from dbo.MaintenanceRequestStores 
										where MaintenanceRequestID = @maintenancerequestid)									
							
							--end
				if 	@storecountincontext = 	@foundinstoresetup
					begin
						if @requesttypeid = 1 and @pricevaluetopass = 0
							begin
								set @thismrhasnoimpact = 1
								set @atleastonewithnoimpact17 = 1
								update MaintenanceRequests set RequestStatus = 17
								where MaintenanceRequestID = @maintenancerequestid
								
									
						
								
							end
					
					end	
							
							
							
							
				if @thismrhasnoimpact = 0

					begin
					
						set @foundinproductprices = 0
																	
						set @recstores = CURSOR local fast_forward FOR 
							select storeid 
							from dbo.MaintenanceRequestStores 
							where MaintenanceRequestID = @maintenancerequestid

							
						open @recstores
						
						fetch next from @recstores into @storeid
						
						while @@FETCH_STATUS = 0 and @PendForOverlappingDates = 0
							begin

								set @exactmatchfound = 0
								if @lookforexactmatches = 1
									begin

										exec [dbo].[prMaintenanceRequest_ProductPrice_CostMatch_Lookup]
											@chainid
											,@storeid
											,@productid
											,@brandid
											,@supplierid
											,@productpricetypeid
											,@pricevaluetopass
											,@startdate
											,@enddate
											,@exactmatchfound output
											
										if @exactmatchfound = 1
											begin
												set @foundinproductprices = @foundinproductprices + 1
											
											end

									end

							
								fetch next from @recstores into @storeid
							end
							
							
						if 	@storecountincontext = 	@foundinproductprices
							begin
								--if @requesttypeid = 1 and @pricevaluetopass = 0
								--	begin
										set @thismrhasnoimpact = 1
										set @atleastonewithnoimpact18 = 1
										
										update MaintenanceRequests set RequestStatus = 18
										where MaintenanceRequestID = @maintenancerequestid
										
										
									--end
							
							end								
							
						
						close @recstores
						deallocate @recstores
					end
				
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
			,@markeddeleted
			,@SkipPopulating879_889Records
			,@dtproductdescription
			,@supplierloginid
			,@ApprovalDateTime
	,@Approved
	,@ChainLoginID
	,@DealNumber
	,@DeleteDateTime
	,@DeleteLoginId
	,@DeleteReason
	,@DenialReason
	,@EmailGeneratedToSupplier
	,@EmailGeneratedToSupplierDateTime
	,@RequestStatus
	,@Skip_879_889_Conversion_ProcessCompleted
	,@SubmitDateTime
	,@requestsource

	end
	
close @recmr
deallocate @recmr

if @atleastonewithnoimpact17 = 1
	begin
		set @emailmessage = 'MaintenanceRequests records have been pended as having no impact to requeststatus 17.'
		exec dbo.prSendEmailNotification_PassEmailAddresses 'MaintenanceRequests - New Item Request with No Impact'
		,@emailmessage
		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;edi@icontroldsd.com'
	end


if @atleastonewithnoimpact18 = 1
	begin
		set @emailmessage = 'MaintenanceRequests records have been pended as having no impact to requeststatus 18.'
		exec dbo.prSendEmailNotification_PassEmailAddresses 'MaintenanceRequests - Request with No Impact'
		,@emailmessage
		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;edi@icontroldsd.com'										
	end
/*

select distinct requeststatus from maintenancerequests order by requeststatus

*/
return
GO
