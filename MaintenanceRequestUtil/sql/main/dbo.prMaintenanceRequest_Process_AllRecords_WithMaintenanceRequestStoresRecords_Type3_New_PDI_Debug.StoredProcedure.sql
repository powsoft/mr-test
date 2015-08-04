USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_Process_AllRecords_WithMaintenanceRequestStoresRecords_Type3_New_PDI_Debug]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_Process_AllRecords_WithMaintenanceRequestStoresRecords_Type3_New_PDI_Debug]
as


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


--************************************************
declare @showquery bit=1
declare @applyupdate bit=1
declare @applyedistatusupdate bit=1
declare @additemtostoresetupeveniffound bit =1
declare @displaystoresetup bit =1
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
declare @includeinadjustments tinyint
declare @supplierpackageid int


--select distinct requeststatus from maintenancerequests where requeststatus = 8
--select * from maintenancerequests where maintenancerequestid between 14131 and 14195
--update maintenancerequests set dtstorecontexttypeid = 2 where maintenancerequestid between 14131 and 14195
update  m set m.SkipPopulating879_889Records = case when ISNULL(PDIParticipant, 0) = 1 then 1 else 0 end
--select *
from dbo.MaintenanceRequests m
where 1 = 1
and RequestTypeID = 3
--and (RequestStatus = 3 or MarkDeleted = 1)
and ISNULL(PDIParticipant, 0) = 1
and (SkipPopulating879_889Records is null or SkipPopulating879_889Records = 0)

update  m set m.datatrue_edi_costs_recordid = null, m.datatrue_edi_promotions_recordid = null
--select *
from dbo.MaintenanceRequests m
where 1 = 1
and SupplierID = 40558
and (RequestStatus = 3 or MarkDeleted = 1)
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
 
 if @senddeletedoverlappingpromos = 1
	begin
		 set @recmr = CURSOR local fast_forward FOr

		SELECT distinct r.[MaintenanceRequestID]
				,r.RequestTypeID
			  ,r.[ChainID]
			  ,r.[SupplierID]
			  ,ltrim(rtrim(r.[Banner]))
			  ,r.[AllStores]
			  ,ltrim(rtrim(r.[UPC12]))
			  ,r.[BrandIdentifier]
			  ,r.[ItemDescription]
			  ,r.[CurrentSetupCost]
			  ,r.[Cost]
			  ,isnull(r.[SuggestedRetail], 0.00)
			  ,r.[PromoTypeID]
			  ,case when d.[UnitPrice] <  0 then d.[UnitPrice] * -1 else d.[UnitPrice] end
			  ,d.[ActiveStartDate]
			  ,d.[ActiveLastDate]
			  ,r.[CostZoneID]
			  ,r.[ProductID]
			  ,r.[upc12]
			  ,null --r.[datatrue_edi_costs_recordid]
			  ,null --r.[datatrue_edi_promotions_recordid]
			  ,r.[dtstorecontexttypeid]
			  ,isnull(r.[BrandID], 0)
			  ,isnull(r.TradingPartnerPromotionIdentifier, 'MR-' + cast(r.maintenancerequestid as nvarchar(50)))
			  ,1 --MarkDeleted
			  ,0 --r.SkipPopulating879_889Records
			  ,isnull(r.dtproductdescription, 'UNKNOWN')
			  ,r.SupplierLoginID   
			  ,r.ApprovalDateTime 
			,r.Approved 
			,r.ChainLoginID 
			,r.DealNumber
			,r.DeleteDateTime
			,r.DeleteLoginId
			,r.DeleteReason
			,r.DenialReason 
			,r.EmailGeneratedToSupplier 
			,r.EmailGeneratedToSupplierDateTime
			,r.RequestStatus 
			,r.Skip_879_889_Conversion_ProcessCompleted 
			,r.SubmitDateTime 
			,isnull(RequestSource, '')		
			--select * 
			--select distinct recordstatus 
			--update d set recordstatus = 10
		  FROM [DataTrue_Main].[dbo].[OverlappingProductPricesRecordsDeleted] d
		  inner join MaintenanceRequests r
		  on d.maintenancerequestid = r.MaintenanceRequestID
		  where d.recordstatus = 0
		  and r.RequestTypeID = 3
		  and ISNULL(Pdiparticipant, 0) = 1
		  



	end
else
	begin
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
			--select pdiparticipant, *		  
		  FROM [DataTrue_Main].[dbo].[MaintenanceRequests] mr
			where 1 = 1
			and MaintenanceRequestID in
(2803734,
2803713,
2803712,
2803711,
2803710,
2803709,
2803708,
2803707,
2803706,
2803704,
2803694)
			--and RequestStatus in (3)
			and Approved = 1
			and RequestTypeID in (3)
			and PromoAllowance is not null
			and PromoAllowance <> 0
			and dtstorecontexttypeid is not null
			and ProductId is not null
			and isnull(MarkDeleted, 0) = 0
			and ISNULL(Pdiparticipant, 0) = 1
			and datetimecreated>GETDATE()-60
			order by Startdatetime, EndDateTime

--*/

		end
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

		
		if @storecontexttypeid = 3 and @costzoneid <> 0
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
			
		select @suppliername = SupplierName,@tradingpartnervalue=UniqueEDIName
		from Suppliers 
		where SupplierID = @supplierid
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
								and SupplierID = @supplierid
								and StoreID in
								(select storeid 
								from dbo.MaintenanceRequestStores 
								where MaintenanceRequestID = @maintenancerequestid)
									order by ActiveStartDate
								
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
									
							end

						If @additemtostoresetup = 1 --and @additemtostoresetupeveniffound = 0
							begin
							
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
							
							end
													
							
							
							
				if @SkipPopulating879_889Records = 0
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
									--If @markeddeleted = 1 and @PendForOverlappingDates = 0
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
--									exec prMaintenanceRequest_OverlappingDates_Report_Send
--											@maintenancerequestid,
--											@supplierloginid,
--											@requesttypeid
								
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
--*/
								
							--set @PendForOverlappingDates = 0 --*****************************************************************************
							
							
							if @applyupdate = 1 and @recordvalidated = 1 and @PendForOverlappingDates = 0 
							--and (@requesttypeid in (2,3) or @newitemalreadyhascost = 0)
								begin
									--if @markeddeleted = 1 and @onlyexactmatchfound = 1
										--begin
											exec [dbo].[prProductPrice_Manage_PDI_20140618]
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
											,@markeddeleted
											,@tradingpartnerpromotionidentifier
											,@includeinadjustments
											,@supplierpackageid
										--end
								end			
							
							if @additemtostoresetup = 1 and @foundinstoresetup <> @storecountincontext
								begin
								
									exec [dbo].[prStoreSetup_Manage]
										@chainid
										,@storeid
										,@productid
										,@brandid
										,@supplierid
								
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
								and SupplierID = @supplierid
								and StoreID in
								(select storeid 
								from dbo.MaintenanceRequestStores 
								where MaintenanceRequestID = @maintenancerequestid)
									order by ActiveStartDate
							end							
				
				
				
					If  @displaystoresetup = 1
					begin
						select *
						from storesetup
						where 1 = 1
						and ProductID = @productid
						and SupplierID = @supplierid
						and StoreID in
					(select storeid 
								from dbo.MaintenanceRequestStores 
								where MaintenanceRequestID = @maintenancerequestid)
						
					end	
						
						
			--
			end

		delete from tmpMaintenanceRequestStoreIDList where ID = @uniqueid
		
		if @requesttypeid in (3, 4, 5) and @applyedistatusupdate = 1 and @recordvalidated = 1 and @PendForOverlappingDates = 0
			begin
				if @supplierid = 41465 and @requestsource = 'TMP'
					begin
						update datatrue_edi.dbo.Promotions
						set Loadstatus = 20
						where RecordID = @edipromorecordid
						
						set @edipromorecordid = null
					
					end
				if @edipromorecordid is not null
					begin
						select @storeidentifierfromstorestable = ltrim(RTRIM(storeidentifier))
							,@custom1fromstorestable = LTRIM(rtrim(custom1))
							,@storedunsnumberfromstorestable = LTRIM(rtrim(DunsNumber))
							,@edibanner = LTRIM(rtrim(custom3))
							,@storesbtnumberfromstorestable = LTRIM(rtrim(custom2))
							from stores where storeid = @storeid
							
						update datatrue_edi.dbo.Promotions
						set Loadstatus = 35,
						PromotionStatus = case when isnull(@markeddeleted, 0) = 1 then '03' else ISNull(PromotionStatus,'01') end,
						dtmaintenancerequestid = @maintenancerequestid,
						SentToRetailer = CASe when cast(dateendpromotion as date) < dateadd(day, 2, getdate()) then 1 else 0 end,
						ProductName = Case when upper(@dtproductdescription) = 'UNKNOWN' then ProductName else @dtproductdescription end,
						ProductNameReceived = ProductName,
						[MarketAreaCodeIdentifier]='002',
						[CorporateName]=@banner
						,[CorpIdentifier]=@storedunsnumber
						,[productid]=@productid
						,[brandid]=@brandid
						,[SupplierName]=@suppliername
						,[storeid]=@storeid
						,[storename]=@custom1fromstorestable
						,[storenumber]=@storeidentifierfromstorestable
						,[storeduns]=@storedunsnumberfromstorestable 
						,[storeidentifier]=@storeidentifierfromstorestable
						,[StoreSBTNumber]=@storesbtnumberfromstorestable
						,[ProductIdentifier] = @upc12

								   
						where RecordID = @edipromorecordid
					end
				else
					begin
					
						if @applyedistatusupdate = 1 and @SkipPopulating879_889Records = 0
						  begin
						  
						  if @supplierid = 41465
							begin
--/*						  


--*/

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
								   ,[dtbanner]
								   ,[storeid]
								   ,[storename]
								   ,[storenumber]
								   ,[storeduns]
								   ,[storeidentifier]
								   ,[StoreSBTNumber]
								   ,[dtcostzoneid]
								   ,[SentToRetailer]
								   ,[PromotionStatus]
								   ,Approved 
								   ,ApprovalDateTime 
								   ,AllStores 
								   ,BrandIdentifier
								   ,ChainLoginID
								   ,Cost
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
								   ,SuggestedRetail
								   ,SupplierLoginID)
								   select '002'
								   ,@tradingpartnervalue
								   ,@startdate
								   ,@enddate
								   ,left(isnull(@tradingpartnerpromotionidentifier, 'MR-' + LTRIM(rtrim(@tradingpartnervalue)) + '-' + @upc12 + LEFT(replace(replace(cast(@startdate as nvarchar), ' ', ''), ':',''), 11)), 30)
								   ,@banner
								   ,DunsNumber
								   	,case when upper(@dtproductdescription) = 'UNKNOWN' then @itemdescription else @dtproductdescription end
								   ,ltrim(rtrim(cast(@pricevaluetopass as nvarchar)))
								   ,@upc
								   ,@upc12
								   ,35 --loadstatus
								   ,@chainid
								   ,@productid
								   ,@brandid
								   ,@supplierid
								   ,s.custom3
								   ,@suppliername
								   ,1 --storecontexttypeid
								   ,@maintenancerequestid
								   ,'MR'
								   ,@banner
								   ,s.storeid
								   ,s.Custom1
								   ,s.StoreIdentifier
								   ,s.DunsNumber
								   ,s.StoreIdentifier
								   ,s.Custom2
								   ,@costzoneid
								   ,CASe when cast(@enddate as date) < dateadd(day, 2, getdate()) then 1 else 0 end
								   ,case when isnull(@markeddeleted, 0) = 1 then '03' else '01' end	
								   ,@Approved 
								,@ApprovalDateTime 
								,@allstores
								,@brandidentifier
								,@ChainLoginID
								,@requestedcost
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
								,@suggestedretail
								,@supplierloginid 
								   from MaintenanceRequestStores rs
								   inner join stores s
								   on rs.Storeid = s.storeid
								   and rs.MaintenanceRequestID = @maintenancerequestid

							end
						  else
							begin
							select @storeidentifierfromstorestable = ltrim(RTRIM(storeidentifier))
							,@custom1fromstorestable = LTRIM(rtrim(custom1))
							,@storedunsnumberfromstorestable = LTRIM(rtrim(DunsNumber))
							,@edibanner = LTRIM(rtrim(custom3))
							,@storesbtnumberfromstorestable = LTRIM(rtrim(custom2))
							from stores where storeid = @storeid
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
								   ,[dtbanner]
								   ,[storeid]
								   ,[storename]
								   ,[storenumber]
								   ,[storeduns]
								   ,[storeidentifier]
								   ,[StoreSBTNumber]
								   ,[dtcostzoneid]
								   ,[SentToRetailer]
								   ,[PromotionStatus]
								   ,Approved 
								   ,ApprovalDateTime 
								   ,AllStores 
								   ,BrandIdentifier
								   ,ChainLoginID
								   ,Cost
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
								   ,SuggestedRetail
								   ,SupplierLoginID)
								   values('002'
								   ,@tradingpartnervalue
								   ,@startdate
								   ,@enddate
								   ,left(isnull(@tradingpartnerpromotionidentifier, 'MR-' + LTRIM(rtrim(@tradingpartnervalue)) + '-' + @upc12 + LEFT(replace(replace(cast(@startdate as nvarchar), ' ', ''), ':',''), 11)), 30)
								   ,@banner
								   ,@storedunsnumber
								   ,case when upper(@dtproductdescription) = 'UNKNOWN' then @itemdescription else @dtproductdescription end
								   ,ltrim(rtrim(cast(@pricevaluetopass as nvarchar)))
								   ,@upc
								   ,@upc12
								   ,35--loadstatus
								   ,@chainid
								   ,@productid
								   ,@brandid
								   ,@supplierid
								   ,@edibanner
								   ,@suppliername
								   ,1 --storecontexttypeid
								   ,@maintenancerequestid
								   ,'MR'
								   ,@banner
								   ,@storeid
								   ,@custom1fromstorestable
								   ,@storeidentifierfromstorestable
								   ,@storedunsnumberfromstorestable --@storedunsnumber
								   ,@storeidentifierfromstorestable
								   ,@storesbtnumberfromstorestable
								   ,@costzoneid
								   ,CASe when cast(@enddate as date) < dateadd(day, 2, getdate()) then 1 else 0 end
								   ,case when isnull(@markeddeleted, 0) = 1 then '03' else '01' end
								   ,@Approved 
								,@ApprovalDateTime 
								,@allstores
								,@brandidentifier
								,@ChainLoginID
								,@requestedcost
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
								,@suggestedretail
								,@supplierloginid)
								end
							end

					
					
							end
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
	end
	
close @recmr
deallocate @recmr


update p set p.Description = r.ItemDescription, p.ProductName = r.ItemDescription
from MaintenanceRequests r
inner join products p
on r.productid = p.productid
and (upper(ltrim(rtrim(p.description))) = 'UNKNOWN' or len(ltrim(rtrim(p.description)))=0)
and r.approved = 1
and r.ItemDescription is not null
and len(r.ItemDescription) > 0



return
GO
