USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_Process_AllRecords_WithMaintenanceRequestStoresRecords_Type14_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_Process_AllRecords_WithMaintenanceRequestStoresRecords_Type14_PRESYNC_20150415]
as
/*
--**************************Check for Type2********************************************
select Cost, Productid, dtstorecontexttypeid,  costzoneid, *
		  FROM [DataTrue_Main].[dbo].[MaintenanceRequests] mr
			where 1 = 1
			and RequestStatus in (0,1,2)
			and RequestTypeID in (14)
			and dtstorecontexttypeid is not null
			and ProductId is not null
			and Approved = 1	
			
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
declare @pdiparticipant bit

--************************************************
declare @showquery bit=1
declare @applyupdate bit=1
declare @applyedistatusupdate bit=1
declare @additemtostoresetupeveniffound bit =1
declare @displaystoresetup bit = 1
declare @additemtostoresetup bit = 1
declare @createtype2recordfromtype1record bit = 1
--*************************************************
declare @senddeletedoverlappingpromos bit=0
declare @checkforoverlappingdates bit=0
declare @removeexistingproductpricesrecordswithoverlappingdates bit=0
declare @useupcofduplicateproductids bit= 0
declare @lookforexactmatches bit = 0
declare @exactmatchfound bit

declare @foundinstoresetup int
declare @storecountincontext int

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
			,isnull(RequestSource, ''),PDIParticipant
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
			and RequestStatus in (1, 2)
			and RequestTypeID in (14)
			and ISNULL(Pdiparticipant, 0) = 1
			and dtstorecontexttypeid is not null
			and ProductId is not null
			and Approved = 1	
			and datetimecreated>GETDATE()-60
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
	,@pdiparticipant

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
			
				if @costzoneid <> 0
					begin
						select @bannerisvalid = COUNT(costzoneid)
						from costzones where LTRIM(rtrim(CostZoneID)) = LTRIM(rtrim(@costzoneid))
						and SupplierId = @supplierid
					end
				else
					begin
						set @bannerisvalid = 1
					end
				
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
				

		if @applyedistatusupdate = 1 and @recordvalidated = 1
			begin		
				if @edicostrecordid is not null
					begin
					
							
						update datatrue_edi.dbo.Costs
						set RecordStatus = case when @SkipPopulating879_889Records = 1 then 35 else 25 end, 
						dtmaintenancerequestid = @maintenancerequestid, 
						ProductName = Case when upper(@dtproductdescription) = 'UNKNOWN' then ProductName else @dtproductdescription end,
						ProductNameReceived = ProductName,
						deleted = case when isnull(@markeddeleted, 0) = 1 then 1 else null end,
						SentToRetailer = case when isnull(@markeddeleted, 0) = 1 then 0 else SentToRetailer end,
						[StoreIdentifier]=@storedunsnumber
						,[StoreName]=@banner
						,[PricingMarket]='002'
						,[dtproductid]=@productid
						,[dtbrandid]=@brandid
						,[PartnerName]=@suppliername
						,[Recordsource]='EDI'
						,[ProductIdentifier] = @upc12
						,[RequestTypeID] = @requesttypeid
						,[PDIParticipant] = @pdiparticipant
						where RecordID = @edicostrecordid
					end
				else
					begin--************************************************
					
	
								if @applyedistatusupdate = 1 and @SkipPopulating879_889Records = 0 and @recordvalidated = 1
								  begin

						--select top 100 * from [DataTrue_EDI].[dbo].[Costs]
									INSERT INTO [DataTrue_EDI].[dbo].[Costs]
											   ([PartnerIdentifier]
											   ,[PriceChangeCode]
											   ,[Banner]
											   ,[StoreIdentifier]
											   ,[StoreName]
											   ,[PricingMarket]
											   ,[AllStores]
											   ,[Cost]
											   ,[SuggRetail]
											   ,[RawProductIdentifier]
											   ,[ProductIdentifier]
											   ,[ProductName]
											   ,[EffectiveDate]
											   ,[EndDate]
											   ,[RecordStatus]
											   ,[dtchainid]
											   ,[dtproductid]
											   ,[dtbrandid]
											   ,[dtsupplierid]
											   ,[dtbanner]
											   ,[PartnerName]
											   ,[dtstorecontexttypeid]
											   ,[dtmaintenancerequestid]
											   ,[Recordsource]
											   ,[dtcostzoneid]
											   ,[Deleted]
											   ,ApprovalDateTime 
												,Approved 
												,BrandIdentifier 
												,ChainLoginID 
												,CurrentSetupCost
												,DealNumber
												,DeleteDateTime
												,DeleteLoginId
												,DeleteReason
												,DenialReason 
												,EmailGeneratedToSupplier 
												,EmailGeneratedToSupplierDateTime
												,RequestStatus 
												,RequestTypeID 
												,Skip_879_889_Conversion_ProcessCompleted 
												,SkipPopulating879_889Records  
												,SubmitDateTime
												,SupplierLoginID
												,PDIParticipant)
										   values(@tradingpartnervalue
										   ,case when @requesttypeid = 1 then 'A' else 'B' end
										   ,@edibanner
										   ,@storedunsnumber
										   ,@banner
										   ,@costzoneid --'006'
										   ,@allstores
										   ,@pricevaluetopass
										   ,@suggestedretail
										   ,@upc
										   ,@upc12
										   ,case when upper(@dtproductdescription) = 'UNKNOWN' then @itemdescription else @dtproductdescription end
										   ,@startdate
										   ,'12/31/2099' --@enddate
										   ,10 --loadstatus
										   ,@chainid
										   ,@productid
										   ,@brandid
										   ,@supplierid
										   ,@banner
										   ,@suppliername
										   ,3 --storecontexttypeid
										   ,@maintenancerequestid
										   ,'MR'
										   ,@costzoneid
										   ,case when isnull(@markeddeleted, 0) = 1 then 1 else null end
										   ,@ApprovalDateTime 
											,@Approved 
											,@brandidentifier 
											,@ChainLoginID 
											,@currentsetupcosts
											,@DealNumber
											,@DeleteDateTime
											,@DeleteLoginId
											,@DeleteReason
											,@DenialReason 
											,@EmailGeneratedToSupplier 
											,@EmailGeneratedToSupplierDateTime
											,@RequestStatus 
											,@requesttypeid 
											,@Skip_879_889_Conversion_ProcessCompleted 
											,@SkipPopulating879_889Records  
											,@SubmitDateTime
											,@supplierloginid
											,@pdiparticipant)
									end		
																
					end--**************************************************		
					
			end
		if  @applyupdate = 1 and @recordvalidated = 1
			begin
				update MaintenanceRequests set RequestStatus = case when @markeddeleted = 1 then 6 else 5 end
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
	,@pdiparticipant

	end
	
close @recmr
deallocate @recmr



return
GO
