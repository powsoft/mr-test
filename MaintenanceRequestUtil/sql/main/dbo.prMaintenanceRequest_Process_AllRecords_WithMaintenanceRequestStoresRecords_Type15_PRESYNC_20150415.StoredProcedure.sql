USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_Process_AllRecords_WithMaintenanceRequestStoresRecords_Type15_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_Process_AllRecords_WithMaintenanceRequestStoresRecords_Type15_PRESYNC_20150415]
as
/*
--**************************Check for Type15********************************************
select Cost, Productid, dtstorecontexttypeid,  costzoneid, *
		  FROM [DataTrue_Main].[dbo].[MaintenanceRequests] mr
			where 1 = 1
			and RequestStatus in (0,1,2)
			and Approved = 1
			and RequestTypeID in (15)
			and dtstorecontexttypeid is not null
			and ProductId is not null
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
Declare @oldupc nvarchar(50)
declare @oldupcdescription nvarchar(255)
declare @oldvin nvarchar(50)
declare @oldvindescription nvarchar(255)
declare @pdiparticipant bit
declare @vin nvarchar(50)
declare @vindescription nvarchar(255)
declare @replaceupc bit
declare @supplierpackageid int
declare @oldsupplierpackageid int
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
			,isnull(RequestSource, '') 
			,OldUPC
			,PDIParticipant
			,OldUPCDescription
			,OldVIN
			,OldVINDescription
			,VIN
			,VINDescription
			,[ReplaceUPC]
			,[SupplierPackageID]
			
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
			--and MaintenanceRequestID = 2807741
			--and chainid = 40393
			and RequestStatus in (2)
			and Approved = 1
			and RequestTypeID in (15)
			and Cost is not null
			and [Cost] <> 0
			and dtstorecontexttypeid is not null
			and ProductId is not null
			and PDIParticipant = 1
			and datetimecreated> GETDATE()-60
			and dtstorecontexttypeid in (1,3,4)
			order by Startdatetime, EndDateTime


open @recmr

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
	,@oldupc
	,@pdiparticipant
	,@oldupcdescription
	,@oldvin
	,@oldvindescription
	,@vin
	,@vindescription
	,@replaceupc
	,@supplierpackageid

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
					set @bannerisvalid = -1
					
				if @bannerisvalid < 0 and @storecontexttypeid = 3
					begin
						set @recordvalidated = 0
						set @emailmessage = 'MaintenanceRequests recordid ' + cast(@maintenancerequestid as varchar) + ' has an invalid costzone value and can not be processed.  Please correct the value.'
						exec dbo.prSendEmailNotification_PassEmailAddresses 'MaintenanceRequests - Invalid Cost Zone'
						,@emailmessage
						,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'
					end
			end

		--select @supplierpackageid = supplierpackageid 
		--from SupplierPackages
		--where ProductID = @productid
		--and OwnerEntityID = @chainid
		--and SupplierID = @supplierid
		--and VIN = @vin
			
		select @suppliername = SupplierName, @tradingpartnervalue=UniqueEDIName
		from Suppliers 
		where SupplierID = @supplierid


		
		set @productpricetypeid =
			case when @requesttypeid IN (1, 2, 15) then 11
				when  @requesttypeid IN (3, 4, 5) then 8
			end


		set @pricevaluetopass =
			case when @requesttypeid IN (1, 2, 15) then @requestedcost
				when  @requesttypeid IN (3, 4, 5) then @promoallowance
			end		
print @pricevaluetopass				
		set @enddate =
			case when @requesttypeid IN (1, 2, 15) then '12/31/2099'
				when  @requesttypeid IN (3, 4, 5) then @enddate
			end	
			
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
			
						if @showquery = 1
							begin 
								select *
								from ProductPrices
								where ProductPriceTypeID = @productpricetypeid
								and ProductID = @productid
								--and SupplierID = @supplierid
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
										--and SupplierID = @supplierid
										and StoreID in
										(select storeid 
										from dbo.MaintenanceRequestStores 
										where MaintenanceRequestID = @maintenancerequestid)
									end							
									
							end

						If @additemtostoresetup = 1 
							begin
							
								select @storecountincontext = COUNT(storeid) 
									from dbo.MaintenanceRequestStores 
									where MaintenanceRequestID = @maintenancerequestid
							
								select @foundinstoresetup = COUNT(storesetupid)
								from storesetup
								where ProductID = @productid
								--and SupplierID = @supplierid
								and StoreID in
										(select storeid 
										from dbo.MaintenanceRequestStores 
										where MaintenanceRequestID = @maintenancerequestid)	
								and ActiveLastDate >= @enddate								
							
							end
							
				if @supplierid = 40558 and @SkipPopulating879_889Records = 0
					begin
						set @SkipPopulating879_889Records = 0
					end
				else
					begin												
						set @recstores = CURSOR local fast_forward FOR 
							select storeid 
							from dbo.MaintenanceRequestStores 
							where MaintenanceRequestID = @maintenancerequestid

							
						open @recstores
						
						fetch next from @recstores into @storeid
						
						while @@FETCH_STATUS = 0 and @PendForOverlappingDates = 0
							begin
--/*							
							If @checkforoverlappingdates = 1
								begin
									If @PendForOverlappingDates = 0 and @onlyexactmatchfound = 0
										begin
											exec prMaintenanceRequests_ProductPrice_Overlap_Lookup
												@maintenancerequestid
												,@storeid
												,@productid
												,@brandid
												,@supplierid
												,@productpricetypeid
												,@startdate
												,@enddate
												,@storecontexttypeid
												,@costzoneid
												,@banner
												,@PendForOverlappingDates output
												,@onlyexactmatchfound output
										end
								end
--*/
--/*								
							If @PendForOverlappingDates = 1
								begin
									set @PendForOverlappingDates = 1
--								
								end
								
							If @removeexistingproductpricesrecordswithoverlappingdates = 1
								begin								

									exec [dbo].[prMaintenanceRequests_ProductPrice_Overlap_Existing_Remove]
									@maintenancerequestid
									,@storeid
									,@productid
									,@brandid
									,@supplierid
									,@productpricetypeid
									,@startdate
									,@enddate
									,@storecontexttypeid
									,@banner
									,@costzoneid	
									,@allstores
									,@upc12					
								
								end

						if @lookforexactmatches = 1 and @exactmatchfound = 0
							begin

								exec [dbo].[prMaintenanceRequest_ProductPrice_ExactMatch_Lookup]
									@chainid
									,@storeid
									,@productid
									,@brandid
									,@supplierid
									,@productpricetypeid
									,@productpricetypeid
									,@startdate
									,@enddate
									,@exactmatchfound output

							end
							
							if @applyupdate = 1 and @replaceupc = 1 and @recordvalidated = 1 and @PendForOverlappingDates = 0 
							
								begin
								
											exec [dbo].[prProductPrice_Manage_Assignment]
											@chainid
											,@storeid
											,@productid
											,0 --@brandid
											,@supplierid
											,@productpricetypeid
											,@pricevaluetopass
											,@startdate
											,@enddate
											,@suggestedretail
											,0
											,@markeddeleted
											,@tradingpartnerpromotionidentifier
											,@supplierpackageid
							
								end			
							
							
								if @replaceupc = 1
									begin
										exec [dbo].[prStoreSetup_Manage_Assignment]
											@chainid
											,@storeid
											,@productid
											,@brandid
											,@supplierid
											,@startdate
											,@enddate	
									end							
										
								fetch next from @recstores into @storeid
							end
							
						
						close @recstores
						deallocate @recstores
					end
				
				
				
						if @showquery = 1
							begin 
								select *
								from ProductPrices
								where ProductPriceTypeID = @productpricetypeid
								and ProductID = @productid
								--and SupplierID = @supplierid
								and StoreID in
								(select storeid 
								from dbo.MaintenanceRequestStores 
								where MaintenanceRequestID = @maintenancerequestid)
							end							
				
				
				
					If  @displaystoresetup = 1
					begin
						select *
						from storesetup
						where 1 = 1
						and ProductID = @productid
						--and SupplierID = @supplierid
						and StoreID in
					(select storeid 
								from dbo.MaintenanceRequestStores 
								where MaintenanceRequestID = @maintenancerequestid)
						
					end					
						
			--
			end

		delete from tmpMaintenanceRequestStoreIDList where ID = @uniqueid
		
		if @requesttypeid in (15) and @applyedistatusupdate = 1 and @recordvalidated = 1 and @PendForOverlappingDates = 0
			begin	
				
				declare @discontinuedproductid int
				
				set @discontinuedproductid = null
				
				select @oldsupplierpackageid = SupplierPackageid
				from supplierpackages
				where ltrim(rtrim(VIN)) = @oldvin
				and supplierid = @supplierid
				and OwnerEntityID = @chainid
				
				select @discontinuedproductid = productid
				from productidentifiers
				where identifiervalue = @oldupc
				and ProductIdentifierTypeID = 2		
				
				
				
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
												,OldUPC
												,PDIParticipant
												,OldVIN
												,OldVINDescription
												,VIN
												,VINDescription
												,replaceupc
												,SupplierPackageID)
										   values(@tradingpartnervalue
										   ,case when @requesttypeid = 1 then 'A' else 'B' end
										   ,@edibanner
										   ,@storedunsnumber
										   ,@banner
										   ,@costzoneid --'006'
										   ,@allstores
										   ,@pricevaluetopass
										   ,@suggestedretail
										   ,@oldupc
										   ,@oldupc
										   ,case when upper(@dtproductdescription) = 'UNKNOWN' then @itemdescription else @dtproductdescription end
										   ,@startdate
										   ,@enddate
										   ,25 --loadstatus
										   ,@chainid
										   ,@discontinuedproductid --@productid
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
											,14 --@requesttypeid 
											,@Skip_879_889_Conversion_ProcessCompleted 
											,@SkipPopulating879_889Records  
											,@SubmitDateTime
											,@supplierloginid
											,@upc
											,@pdiparticipant
											,@vin 
											,@vindescription
											,@oldvin
											,@oldvindescription
											,@replaceupc
											,@oldsupplierpackageid)			
			
				if @edicostrecordid is not null
					begin
					select @storeidentifierfromstorestable = ltrim(RTRIM(storeidentifier))
							,@custom1fromstorestable = LTRIM(rtrim(custom1))
							,@storedunsnumberfromstorestable = LTRIM(rtrim(DunsNumber))
							,@edibanner = LTRIM(rtrim(custom3))
							,@storesbtnumberfromstorestable = LTRIM(rtrim(custom2))
							from stores where storeid = @storeid
							
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
						,OldUPC = @oldupc
						,PDIParticipant = @pdiparticipant
						,SupplierPackageID = @supplierpackageid
						where RecordID = @edicostrecordid
					end
				else
					begin--************************************************
					if @storecontexttypeid = 1
						begin
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
												,StoreNumber
												,[dtstoreid]
												,OldUPC
												,PDIParticipant)
										   select @tradingpartnervalue
										   ,case when @requesttypeid = 1 then 'A' else 'B' end
										   ,@edibanner
										   ,s.StoreIdentifier
										   ,@banner
										   ,'002'
										   ,@allstores
										   ,@pricevaluetopass
										   ,@suggestedretail
										   ,@upc
										   ,@upc12
										   ,case when upper(@dtproductdescription) = 'UNKNOWN' then @itemdescription else @dtproductdescription end
										   ,@startdate
										   ,@enddate
										   ,25 --loadstatus
										   ,@chainid
										   ,@productid
										   ,@brandid
										   ,@supplierid
										   ,@banner
										   ,@suppliername
										   ,1 --storecontexttypeid
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
											,s.StoreIdentifier
											,s.storeid
											,@oldupc
											,@pdiparticipant
									from MaintenanceRequestStores rs
								   inner join stores s
								   on rs.Storeid = s.storeid
								   and rs.MaintenanceRequestID = @maintenancerequestid
						end
					else
						begin
					
							if @storecontexttypeid = 10 and @applyedistatusupdate = 1 and @SkipPopulating879_889Records = 0
								  begin
								  
									select @storeidentifierfromstorestable = ltrim(RTRIM(storeidentifier))
									,@custom1fromstorestable = LTRIM(rtrim(custom1))
									,@storedunsnumberfromstorestable = LTRIM(rtrim(DunsNumber))
									,@edibanner = LTRIM(rtrim(custom3))
									,@storesbtnumberfromstorestable = LTRIM(rtrim(custom2))
									from stores where storeid = @storeid
									
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
												,OldUPC
												,PDIParticipant)
										   values(@tradingpartnervalue
										   ,case when @requesttypeid = 1 then 'A' else 'B' end
										   ,@edibanner
										   ,@storedunsnumber
										   ,@banner
										   ,'002'
										   ,@allstores
										   ,@pricevaluetopass
										   ,@suggestedretail
										   ,@upc
										   ,@upc12
										   ,case when upper(@dtproductdescription) = 'UNKNOWN' then @itemdescription else @dtproductdescription end
										   ,@startdate
										   ,@enddate
										   ,25 --loadstatus
										   ,@chainid
										   ,@productid
										   ,@brandid
										   ,@supplierid
										   ,@banner
										   ,@suppliername
										   ,2 --storecontexttypeid
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
											,@oldupc
											,@pdiparticipant)
									
								end --*********
							
								if @storecontexttypeid in (2) and @applyedistatusupdate = 1 and @SkipPopulating879_889Records = 0
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
												,OldUPC
												,PDIParticipant)
										   values(@tradingpartnervalue
										   ,case when @requesttypeid = 1 then 'A' else 'B' end
										   ,@edibanner
										   ,@storedunsnumber
										   ,@banner
										   ,'006'
										   ,@allstores
										   ,@pricevaluetopass
										   ,@suggestedretail
										   ,@upc
										   ,@upc12
										   ,case when upper(@dtproductdescription) = 'UNKNOWN' then @itemdescription else @dtproductdescription end
										   ,@startdate
										   ,@enddate
										   ,25 --loadstatus
										   ,@chainid
										   ,@productid
										   ,@brandid
										   ,@supplierid
										   ,@banner
										   ,@suppliername
										   ,2 --storecontexttypeid
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
											,@oldupc
											,@pdiparticipant )
									end					
									
								if @storecontexttypeid in (3,4) and @applyedistatusupdate = 1 and @SkipPopulating879_889Records = 0 and @recordvalidated = 1
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
												,OldUPC
												,PDIParticipant
											,vin 
											,vindescription
											,oldvin
											,oldvindescription
											,replaceupc												
												)
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
										   ,@enddate
										   ,25 --loadstatus
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
											,@oldupc
											,@pdiparticipant 
											,@vin 
											,@vindescription
											,@oldvin
											,@oldvindescription
											,@replaceupc											
											)
									end		
													
								if @storecontexttypeid in (5) and @applyedistatusupdate = 1 and @SkipPopulating879_889Records = 0
								  begin
								  

								  
								  set @recbanner = CURSOR local fast_forward FOR
								  
								  
										select distinct custom1
										from stores
										where StoreID in
										(SELECT distinct storeid
										from storetransactions
										where supplierid = @supplierid)	
										
									open @recbanner
								  
									fetch next from @recbanner into @supplierbanner
									
									while @@FETCH_STATUS = 0
										begin
								  
									set @storedunsnumber =					
									case 
										when LTRIM(rtrim(@supplierbanner)) = 'Farm Fresh Markets' then '1939636180000'
										when LTRIM(rtrim(@supplierbanner)) = 'Albertsons - SCAL' then '0069271863600'
										when LTRIM(rtrim(@supplierbanner)) = 'Albertsons - IMW'  then '0069271833301'
										when LTRIM(rtrim(@supplierbanner)) = 'Albertsons - ACME' then '0069271877700'
										when LTRIM(rtrim(@supplierbanner)) = 'Cub Foods' then '0032326880002'
										when LTRIM(rtrim(@supplierbanner)) = 'Shop N Save Warehouse Foods Inc' then '8008812780000'
										when LTRIM(rtrim(@supplierbanner)) = 'Hornbachers' then '0299516910000'
										when LTRIM(rtrim(@supplierbanner)) = 'Shoppers Food and Pharmacy' then '4233100000000'
									else null
									end	

									set @edibanner =					
									case 
										when LTRIM(rtrim(@supplierbanner)) = 'Farm Fresh Markets' then 'SV'
										when LTRIM(rtrim(@supplierbanner)) = 'Albertsons - SCAL' then 'ABS'
										when LTRIM(rtrim(@supplierbanner)) = 'Albertsons - IMW'  then 'ABS'
										when LTRIM(rtrim(@supplierbanner)) = 'Albertsons - ACME' then 'ABS'
										when LTRIM(rtrim(@supplierbanner)) = 'Cub Foods' then 'SV'
										when LTRIM(rtrim(@supplierbanner)) = 'Shop N Save Warehouse Foods Inc' then 'SS'
										when LTRIM(rtrim(@supplierbanner)) = 'Hornbachers' then 'SV'
										when LTRIM(rtrim(@supplierbanner)) = 'Shoppers Food and Pharmacy' then 'SV'
										
									else null
									end	
						--corporatename = custom1, corporateidentifier = dunsnumber, banner = custom3, suppliername
						--006 for banner 002 for store
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
												,OldUPC
												,PDIParticipant)
										   values(@tradingpartnervalue
										   ,case when @requesttypeid = 1 then 'A' else 'B' end
										   ,@edibanner
										   ,@storedunsnumber
										   ,@supplierbanner --@banner
										   ,'006'
										   ,@allstores
										   ,@pricevaluetopass
										   ,@suggestedretail
										   ,@upc
										   ,@upc12
										   ,case when upper(@dtproductdescription) = 'UNKNOWN' then @itemdescription else @dtproductdescription end
										   ,@startdate
										   ,@enddate
										   ,25 --loadstatus
										   ,@chainid
										   ,@productid
										   ,@brandid
										   ,@supplierid
										   ,@banner
										   ,@suppliername
										   ,2 --storecontexttypeid
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
											,@oldupc
											,@pdiparticipant )
								
										fetch next from @recbanner into @supplierbanner

									end					
								
								close @recbanner
								deallocate @recbanner							
								
								end
								
						end	
						
										
					end--**************************************************select distinct custom1 from stores		
					
			end
		
		if  @senddeletedoverlappingpromos = 0 and (@applyupdate = 1 or @applyedistatusupdate = 1 and @recordvalidated = 1)
			begin
				if @PendForOverlappingDates = 0
					begin
						update MaintenanceRequests set RequestStatus = case when @markeddeleted = 1 then 6 else 5 end
						where MaintenanceRequestID = @maintenancerequestid
					end
				else
					begin
						update MaintenanceRequests set RequestStatus = case when @markeddeleted = 1 then 7 else 8 end
						where MaintenanceRequestID = @maintenancerequestid					
					end
			end
			
		if  @senddeletedoverlappingpromos = 0 and @applyupdate = 0 and @applyedistatusupdate = 0 and @PendForOverlappingDates = 1
			begin
						update MaintenanceRequests set RequestStatus = case when @markeddeleted = 1 then 7 else 8 end
						where MaintenanceRequestID = @maintenancerequestid	
			end
		if @senddeletedoverlappingpromos = 0 and @removeexistingproductpricesrecordswithoverlappingdates = 1
			begin
						update MaintenanceRequests set RequestStatus = -8
						where MaintenanceRequestID = @maintenancerequestid	
			end
			--select distinct requeststatus from MaintenanceRequests
		if @senddeletedoverlappingpromos = 1
			begin
				UPDATE [DataTrue_Main].[dbo].[OverlappingProductPricesRecordsDeleted]
				   SET [RecordStatus] = 1
				 WHERE MaintenanceRequestID = @maintenancerequestid
					and [ActiveStartDate] = @startdate
					and [ActiveLastDate] = @enddate
					and Unitprice = @pricevaluetopass
			end
		if @useupcofduplicateproductids = 1 --select  distinct requeststatus from MaintenanceRequests
			begin
						update MaintenanceRequests set RequestStatus = 20
						where MaintenanceRequestID = @maintenancerequestid				
			end
		if @requesttypeid = 1 and @additemtostoresetup = 1
			begin
						update MaintenanceRequests set RequestStatus = 5
						where MaintenanceRequestID = @maintenancerequestid
			end
		if @exactmatchfound = 1
			begin
						update MaintenanceRequests set RequestStatus = 101
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
	,@oldupc
	,@pdiparticipant
	,@oldupcdescription
	,@oldvin
	,@oldvindescription
	,@vin
	,@vindescription
	,@replaceupc
	,@supplierpackageid

	end
	
close @recmr
deallocate @recmr



return
GO
