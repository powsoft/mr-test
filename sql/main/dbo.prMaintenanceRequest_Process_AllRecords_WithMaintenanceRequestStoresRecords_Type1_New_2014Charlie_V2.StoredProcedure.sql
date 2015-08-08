USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_Process_AllRecords_WithMaintenanceRequestStoresRecords_Type1_New_2014Charlie_V2]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_Process_AllRecords_WithMaintenanceRequestStoresRecords_Type1_New_2014Charlie_V2]
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
--***********************************
declare @PricingMarket nvarchar(50)

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
declare @includeinadjustments tinyint


update  m set m.SkipPopulating879_889Records = case when SupplierID = 40558 then 1 else 0 end
from dbo.MaintenanceRequests m
where (RequestStatus = 2 or MarkDeleted = 1)
and SkipPopulating879_889Records is null

update  m set m.datatrue_edi_costs_recordid = null, m.datatrue_edi_promotions_recordid = null
from dbo.MaintenanceRequests m
where  SupplierID = 40558
and (RequestStatus = 2 or MarkDeleted = 1)
and SkipPopulating879_889Records = 0

update  m set m.datatrue_edi_costs_recordid = null, m.datatrue_edi_promotions_recordid = null
from dbo.MaintenanceRequests m
where  RequestStatus = 5
and (MarkDeleted = 1)
and SkipPopulating879_889Records = 0
and DeleteDateTime > '4/1/2012'

update p set p.Description = r.ItemDescription                /* statment commented out*/
from MaintenanceRequests r
inner join products p
on r.productid = p.productid
and upper(ltrim(rtrim(p.description))) = 'UNKNOWN'
and r.approved = 1
and r.ItemDescription is not null
and len(ltrim(rtrim(r.ItemDescription))) > 0 

set @recordcount = 0

		update mr set mr.RequestStatus = -26         /* statment commented out*/
	   FROM [DataTrue_Main].[dbo].[MaintenanceRequests] mr
			where RequestStatus in (0,1)
			and Approved = 1
			and ProductId is not null
			and RequestTypeID in (1,2)
			and ([Cost] <= 0 or [Cost] is null)
			
			
set @recordcount = @@ROWCOUNT  /* statment commented out*/
print(@recordcount)

		update mr set mr.RequestStatus = -26
		FROM [DataTrue_Main].[dbo].[MaintenanceRequests] mr  /* statment commented out*/
			where RequestStatus in (0,1)
			and Approved = 1
			and ProductId is not null
			and RequestTypeID in (3)
			and ([PromoAllowance] = 0 or [PromoAllowance] is null)
			
if @recordcount = 0       /* statment commented out*/
	set @recordcount = @@ROWCOUNT  /* statment commented out*/
			
if @recordcount > 0 /* block if commented out*/
	begin 
		exec dbo.prSendEmailNotification_PassEmailAddresses 'Invalid MaintenanceRequest Store Context Found'
		,'MaintenanceRequest records have been found that fail validation and can not be assigned a dtstorecontexttypeid value.  Also, cost or promoallowance values must be valid depending on requesttype.  These records remain with a null dtstorecontexttypeid value and will not be processed until the invalid value is corrected.  Please review all records with -26 requeststatus and correct the values asap.'
		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;mandeep@amebasoftwares.com'	
	end
 
	
	  set @recmr = CURSOR local fast_forward FOr /*MaintenanceRequests cursor*/

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
			 FROM [DataTrue_Main].[dbo].[MaintenanceRequests] mr
			where  RequestStatus in (2)
			and Approved = 1
			and RequestTypeID in (1)
			and Cost is not null
			and [Cost] <> 0
			and ISNULL(Pdiparticipant, 0) <> 1
			and dtstorecontexttypeid is not null
			and ProductId is not null
			order by Startdatetime, EndDateTime
		
/*	
select * from datatrue_edi.dbo.edi_suppliercrossreference
*/
open @recmr           /* Open MaintenanceRequests cursor*/
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
/* **************************************
Q1 @useupcofduplicateproductids = 0 in declaration
*********************************** */
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
		
set @includeinadjustments = case when @SkipPopulating879_889Records = 0 then 1 else 0 end			
					
		select @suppliername = left(SupplierName, 30),		 @tradingpartnervalue=UniqueEDIName 
		from Suppliers where SupplierID = @supplierid
		
		select @storedunsnumber = CorporateIdentifier,@edibanner = banner
		from[DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp]
		where Custom1 = LTRIM(rtrim(@banner)) and suppliername =@suppliername and Custom1 is not null; 
				
		set @productpricetypeid = 3
		set @pricevaluetopass = @requestedcost
		set @enddate = '12/31/2099'	
		
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
				select *from ProductPrices
				where ProductPriceTypeID = @productpricetypeid
				and ProductID = @productid  and SupplierID = @supplierid
				and StoreID in(select storeid from dbo.MaintenanceRequestStores 
								where MaintenanceRequestID = @maintenancerequestid)
								
						if @@ROWCOUNT > 0
						set @newitemalreadyhascost = 1
						if @displaystoresetup = 1
						begin
							select *from storesetup
							where ProductID = @productid and SupplierID = @supplierid
							and StoreID in(select storeid from dbo.MaintenanceRequestStores 
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
				where ProductID = @productid and SupplierID = @supplierid
				and StoreID in(select storeid from dbo.MaintenanceRequestStores 
								where MaintenanceRequestID = @maintenancerequestid)	
				and ActiveLastDate >= @enddate					
				end
							
				if @supplierid = 40558 and @SkipPopulating879_889Records = 0
				begin
					set @SkipPopulating879_889Records = 0
				end
				else
	            /*begin1 after else*/
	
	             begin												
					set @recstores = CURSOR local fast_forward FOR 
					select storeid from dbo.MaintenanceRequestStores 
					where MaintenanceRequestID = @maintenancerequestid
		
					open @recstores						
					fetch next from @recstores into @storeid						
					while @@FETCH_STATUS = 0 and @PendForOverlappingDates = 0
		         /*begin2*/	
		             begin
							--set @PendForOverlappingDates = 0 --*****************************************************************************
					
						if @applyupdate = 1 
						      begin
											exec [dbo].[prProductPrice_Manage_20131213]
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
								end			
							
							if @additemtostoresetup = 1 and @foundinstoresetup <> @storecountincontext
								begin								
									exec [dbo].[prStoreSetup_Manage]@chainid,@storeid,@productid,@brandid,@supplierid								
								end		
								fetch next from @recstores into @storeid
							    end	
						close @recstores
						deallocate @recstores
					end
				
						if @showquery = 1
							begin 
								select *from ProductPrices
								where ProductPriceTypeID = @productpricetypeid
								and ProductID = @productid and SupplierID = @supplierid
								 and StoreID in(select storeid 	from dbo.MaintenanceRequestStores 
								where MaintenanceRequestID = @maintenancerequestid)
							end		
				
					   If  @displaystoresetup = 1
					   begin
						select *from storesetup
						where  ProductID = @productid and SupplierID = @supplierid
						and StoreID in(select storeid from dbo.MaintenanceRequestStores 
								where MaintenanceRequestID = @maintenancerequestid)
					  end	
			end
		if @applyedistatusupdate = 1
			begin
			if @supplierid = 41465 and @requestsource = 'TMP'
			   begin
					update datatrue_edi.dbo.costs set recordstatus = 20 where RecordID = @edicostrecordid
					set @edicostrecordid = null
		       end				
			
			if @edicostrecordid is not null
				begin
				/* result of the fallowing query does not used in this if*/
					--We need to fix this next query to be handled another way
					select @storeidentifierfromstorestable = ltrim(RTRIM(storeidentifier))
							,@custom1fromstorestable = LTRIM(rtrim(custom1))
							,@storedunsnumberfromstorestable = LTRIM(rtrim(DunsNumber))
							,@edibanner = LTRIM(rtrim(custom3))
							,@storesbtnumberfromstorestable = LTRIM(rtrim(custom2))
							from stores where storeid = @storeid
						
							
						update datatrue_edi.dbo.Costs
						set RecordStatus = case when @SkipPopulating879_889Records = 1 then 20 else 10 end, 
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
						,[SubmitDateTime] = @SubmitDateTime
						where RecordID = @edicostrecordid
					end
				else
				begin
					if @supplierid = 41465
						begin --select*from [DataTrue_EDI].[dbo].[Costs]where StoreName is not null
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
												,[dtstoreid])
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
										   ,10 --loadstatus
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
											,s.StoreIdentifier
											,s.storeid
									from MaintenanceRequestStores rs
								   inner join stores s
								   on rs.Storeid = s.storeid
								   and rs.MaintenanceRequestID = @maintenancerequestid
						end
					else
						begin
					
							    if @storecontexttypeid = 1 and @applyedistatusupdate = 1 and @SkipPopulating879_889Records = 0
								  begin
								  set @PricingMarket='002'
								  set @storecontexttypeid=2
								  
								  end
								  if @storecontexttypeid = 2 and @applyedistatusupdate = 1 and @SkipPopulating879_889Records = 0
								  begin
								  set @PricingMarket='006'
								  set @storecontexttypeid=2
								  end
								  
								  if @storecontexttypeid in (3,4) and @applyedistatusupdate = 1 and @SkipPopulating879_889Records = 0 and @recordvalidated = 1
								  begin
								  set @PricingMarket=@costzoneid
								  set @storecontexttypeid=2
								  end
								  
									--select @storeidentifierfromstorestable = ltrim(RTRIM(storeidentifier))
									--,@custom1fromstorestable = LTRIM(rtrim(custom1))
									--,@storedunsnumberfromstorestable = LTRIM(rtrim(DunsNumber))
									--,@edibanner = LTRIM(rtrim(custom3))
									--,@storesbtnumberfromstorestable = LTRIM(rtrim(custom2))
									--from stores where storeid = @storeid
							
		                            select @storedunsnumber = CorporateIdentifier,@edibanner = banner
		                            from[DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp] r
		                            inner join Suppliers s on  LTRIM(rtrim(r.suppliername)) = LTRIM(rtrim(s.suppliername)) and Custom1 is not null
		                           	and Custom1 = LTRIM(rtrim(@banner))  and Custom1 is not null
		                            

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
												,SupplierLoginID)
										   values(@tradingpartnervalue
										   ,case when @requesttypeid = 1 then 'A' else 'B' end
										   ,@edibanner
										   ,@storedunsnumber
										   ,@banner
										   ,@PricingMarket --if stcont 2 then '006',-- if 3,4 then @costzoneid
										   ,@allstores
										   ,@pricevaluetopass
										   ,@suggestedretail
										   ,@upc
										   ,@upc12
										   ,case when upper(@dtproductdescription) = 'UNKNOWN' then @itemdescription else @dtproductdescription end
										   ,@startdate
										   ,@enddate
										   ,10 --loadstatus
										   ,@chainid
										   ,@productid
										   ,@brandid
										   ,@supplierid
										   ,@banner
										   ,@suppliername
										   ,@storecontexttypeid-- for3,4,storecontexttypeid=3 --storecontexttypeid
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
											,@supplierloginid )
								
							end						
					end--**************************************************select distinct custom1 from stores		
				if @requesttypeid = 1 and @createtype2recordfromtype1record = 1 
						and (@banner = 'Shop N Save Warehouse Foods Inc' or @chainid in (60620,64074,64298, 50964))
					begin
					If @supplierid = 41465
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
												,[dtstoreid])
										   select @tradingpartnervalue
										   ,'B' --case when @requesttypeid = 1 then 'A' else 'B' end
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
										   ,10 --loadstatus
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
											,s.StoreIdentifier
											,s.storeid
									from MaintenanceRequestStores rs
								   inner join stores s
								   on rs.Storeid = s.storeid
								   and rs.MaintenanceRequestID = @maintenancerequestid						
						end
					else
						begin
							     if @storecontexttypeid = 1 and @applyedistatusupdate = 1 and @SkipPopulating879_889Records = 0
								  begin
								  set @PricingMarket='002'
								  set @storecontexttypeid=2
								  
								  end
								  if @storecontexttypeid = 2 and @applyedistatusupdate = 1 and @SkipPopulating879_889Records = 0
								  begin
								  set @PricingMarket='006'
								  set @storecontexttypeid=2
								  end
								  
								  if @storecontexttypeid in (3,4) and @applyedistatusupdate = 1 and @SkipPopulating879_889Records = 0 and @recordvalidated = 1
								  begin
								  set @PricingMarket=@costzoneid
								  set @storecontexttypeid=3
								  end
								  
						         select @suppliername = left(SupplierName, 30),		 @tradingpartnervalue=UniqueEDIName 
		                         from Suppliers where SupplierID = @supplierid
		
		                         select @storedunsnumber = CorporateIdentifier,@edibanner = banner
		                         from[DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp]
		                         where Custom1 = LTRIM(rtrim(@banner)) and suppliername =@suppliername and Custom1 is not null; 

						  
							--select @storeidentifierfromstorestable = ltrim(RTRIM(storeidentifier))
							--,@custom1fromstorestable = LTRIM(rtrim(custom1))
							--,@storedunsnumberfromstorestable = LTRIM(rtrim(DunsNumber))
							--,@edibanner = LTRIM(rtrim(custom3))
							--,@storesbtnumberfromstorestable = LTRIM(rtrim(custom2))
							--from stores where storeid = @storeid
							
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
										,SupplierLoginID )
								   values(@tradingpartnervalue
								   ,'B'
								   ,@edibanner
								   ,@storedunsnumber
								   ,@banner
								   ,@PricingMarket
								   ,@allstores
								   ,@pricevaluetopass
								   ,@suggestedretail
								   ,@upc
								   ,@upc12
								   ,case when upper(@dtproductdescription) = 'UNKNOWN' then @itemdescription else @dtproductdescription end
								   ,@startdate
								   ,@enddate
								   ,10 --loadstatus
								   ,@chainid
								   ,@productid
								   ,@brandid
								   ,@supplierid
								   ,@banner
								   ,@suppliername
								   ,@storecontexttypeid
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
									,@supplierloginid )
									
						
						if @storecontexttypeid = 1 and @applyedistatusupdate = 1 and @SkipPopulating879_889Records = 0
							BEGIN			
							update two set two.storenumber = one.storenumber
							from datatrue_edi.dbo.costs one
							inner join datatrue_edi.dbo.costs two
							on one.dtmaintenancerequestid = two.dtmaintenancerequestid
							and one.PartnerIdentifier = 'SAR'
							and one.PriceChangeCode in ('A', 'w')
							and two.PriceChangeCode = 'B'
							and one.StoreNumber <> ISNULL(two.storenumber, '')		
							
						end
					END
						--	if @storecontexttypeid in (5) and @applyedistatusupdate = 1 and @SkipPopulating879_889Records = 0
						--	  begin
							 			  
						--	  set @recbanner = CURSOR local fast_forward FOR
							  
							  
						--			select distinct custom1
						--			from stores
						--			where StoreID in
						--			(SELECT distinct storeid
						--			from storetransactions
						--			where supplierid = @supplierid)	
									
						--		open @recbanner
							  
						--		fetch next from @recbanner into @supplierbanner
								
						--		while @@FETCH_STATUS = 0
						--			begin
							  
						--		 select @suppliername = left(SupplierName, 30),		 @tradingpartnervalue=UniqueEDIName 
		    --                     from Suppliers where SupplierID = @supplierid
		
		    --                     select @storedunsnumber = CorporateIdentifier,@edibanner = banner
		    --                     from[DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp]
		    --                     where Custom1 = LTRIM(rtrim(@banner)) and suppliername =@suppliername and Custom1 is not null; 

						--		INSERT INTO [DataTrue_EDI].[dbo].[Costs]
						--				   ([PartnerIdentifier]
						--				   ,[PriceChangeCode]
						--				   ,[Banner]
						--				   ,[StoreIdentifier]
						--				   ,[StoreName]
						--				   ,[PricingMarket]
						--				   ,[AllStores]
						--				   ,[Cost]
						--				   ,[SuggRetail]
						--				   ,[RawProductIdentifier]
						--				   ,[ProductIdentifier]
						--				   ,[ProductName]
						--				   ,[EffectiveDate]
						--				   ,[EndDate]
						--				   ,[RecordStatus]
						--				   ,[dtchainid]
						--				   ,[dtproductid]
						--				   ,[dtbrandid]
						--				   ,[dtsupplierid]
						--				   ,[dtbanner]
						--				   ,[PartnerName]
						--				   ,[dtstorecontexttypeid]
						--				   ,[dtmaintenancerequestid]
						--				   ,[Recordsource]
						--				   ,[dtcostzoneid]
						--				   ,[Deleted]
						--				   ,ApprovalDateTime 
						--					,Approved 
						--					,BrandIdentifier 
						--					,ChainLoginID 
						--					,CurrentSetupCost
						--					,DealNumber
						--					,DeleteDateTime
						--					,DeleteLoginId
						--					,DeleteReason
						--					,DenialReason 
						--					,EmailGeneratedToSupplier 
						--					,EmailGeneratedToSupplierDateTime
						--					,RequestStatus 
						--					,RequestTypeID 
						--					,Skip_879_889_Conversion_ProcessCompleted 
						--					,SkipPopulating879_889Records  
						--					,SubmitDateTime
						--					,SupplierLoginID )
						--			   values(@tradingpartnervalue
						--			   ,'B'
						--			   ,@edibanner
						--			   ,@storedunsnumber
						--			   ,@supplierbanner --@banner
						--			   ,'006'
						--			   ,@allstores
						--			   ,@pricevaluetopass
						--			   ,@suggestedretail
						--			   ,@upc
						--			   ,@upc12
						--			   ,case when upper(@dtproductdescription) = 'UNKNOWN' then @itemdescription else @dtproductdescription end
						--			   ,@startdate
						--			   ,@enddate
						--			   ,10 --loadstatus
						--			   ,@chainid
						--			   ,@productid
						--			   ,@brandid
						--			   ,@supplierid
						--			   ,@banner
						--			   ,@suppliername
						--			   ,2 --storecontexttypeid
						--			   ,@maintenancerequestid
						--			   ,'MR'
						--			   ,@costzoneid
						--			   ,case when isnull(@markeddeleted, 0) = 1 then 1 else null end
						--			   ,@ApprovalDateTime 
						--				,@Approved 
						--				,@brandidentifier 
						--				,@ChainLoginID 
						--				,@currentsetupcosts
						--				,@DealNumber
						--				,@DeleteDateTime
						--				,@DeleteLoginId
						--				,@DeleteReason
						--				,@DenialReason 
						--				,@EmailGeneratedToSupplier 
						--				,@EmailGeneratedToSupplierDateTime
						--				,@RequestStatus 
						--				,@requesttypeid 
						--				,@Skip_879_889_Conversion_ProcessCompleted 
						--				,@SkipPopulating879_889Records  
						--				,@SubmitDateTime
						--				,@supplierloginid )
							
						--			fetch next from @recbanner into @supplierbanner
						--		end								
						--	close @recbanner
						--	deallocate @recbanner														end
						
						--end					
					
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
			
		if @useupcofduplicateproductids = 1 --select  distinct requeststatus from MaintenanceRequests
			begin
						update MaintenanceRequests set RequestStatus = 20
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

return
GO
