USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_Process_Type6_NEW_Debug]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_Process_Type6_NEW_Debug]
as
/*
--**************************Check for Type2********************************************
select Cost, Productid, dtstorecontexttypeid,  costzoneid, *
		  FROM [DataTrue_Main].[dbo].[MaintenanceRequests] mr
			where 1 = 1
			and RequestStatus in (0,1,2)
			and Approved = 1
			and RequestTypeID in (2)
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
declare @showquery bit=0
declare @applyupdate bit=1
declare @applyedistatusupdate bit=1
declare @additemtostoresetupeveniffound bit =1
declare @displaystoresetup bit = 0
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
			  ,ApprovalDateTime,Approved,ChainLoginID,DealNumber,DeleteDateTime
			  ,DeleteLoginId,DeleteReason,DenialReason,EmailGeneratedToSupplier 
			  ,EmailGeneratedToSupplierDateTime,RequestStatus
			  ,Skip_879_889_Conversion_ProcessCompleted,SubmitDateTime
			  --select ProductID,Cost,PromoAllowance,SkipPopulating879_889Records, dtstorecontexttypeid,  costzoneid, *
		  FROM [DataTrue_Main].[dbo].[MaintenanceRequests] mr
			where 1 = 1
			--and RequestStatus in (2)
			and Approved = 1
			--and RequestTypeID in (6)
			and Cost is not null
			and [Cost] <> 0
			and dtstorecontexttypeid is not null
			and ProductId is not null
			and MaintenanceRequestID in
			(178103,
178102,
178064,
178063,
178062,
178061,
178081,
178080,
178079,
178078,
178077,
178076,
178101,
178100,
178099,
178098,
178097,
178096,
178092,
178091,
178090,
178089,
178088,
178087,
178086,
178085,
178084,
163958,
163957,
163956,
163979,
163964)	
			order by Startdatetime, EndDateTime


open @recmr
--select top 100 *   FROM [DataTrue_Main].[dbo].[MaintenanceRequests] where requeststatus = 8 and approved = 1
fetch next from @recmr into
	@maintenancerequestid
	,@requesttypeid
	,@chainid
	,@supplierid
	,@banner
	,@allstores
	,@upc
	,@brandidentifier
	,@itemdescription
	,@currentsetupcosts
	,@requestedcost
	,@suggestedretail
	,@promotypeid
	,@promoallowance
	,@startdate
	,@enddate
	,@costzoneid
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
	

while @@FETCH_STATUS = 0
	begin


		set @bannerisvalid = 0
		set @recordvalidated = 1
		set @PendForOverlappingDates = 0
		set @onlyexactmatchfound = 0
		set @newitemalreadyhascost = 0
		set @exactmatchfound = 0
		set @foundinstoresetup = 0
		
		select @suppliername = SupplierName
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
			when @supplierid = 40567 then 'FLO'
			when @supplierid = 40562 then 'PEP'
			when @supplierid = 40578 then 'BUR'
			when @supplierid = 40558 then 'GOP'
			when @supplierid = 41746 then 'DSW'
			when @supplierid = 40560 then 'RUG'
			when @supplierid = 41440 then 'SOUR'
			when @supplierid = 40569 then 'CHO'
			when @supplierid = 42148 then 'TTT'
			when @supplierid = 41440 then 'SOUR'
		else null
		end		
		
		select @storeid=StoreID from MaintenanceRequestStores
		where MaintenanceRequestID=@maintenancerequestid
			
				if @requesttypeid in (1, 2) --and @createtype2recordfromtype1record = 1
					begin
					if @storecontexttypeid = 1 --and @applyedistatusupdate = 1 and @SkipPopulating879_889Records = 0
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
										,SupplierLoginID)
								   values(@tradingpartnervalue
								   ,'B'
								   ,@edibanner
								   ,@storedunsnumber
								   ,@banner
								   ,'002'
								   ,@allstores
								   ,@requestedcost
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
								   )
							
						end --*********
					
						if @storecontexttypeid in (2) --and @applyedistatusupdate = 1 and @SkipPopulating879_889Records = 0
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
										,SupplierLoginID)
								   values(@tradingpartnervalue
								   ,'B'
								   ,@edibanner
								   ,@storedunsnumber
								   ,@banner
								   ,'006'
								   ,@allstores
								   ,@requestedcost
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
									,@supplierloginid)
							end					
							
						if @storecontexttypeid in (3,4) --and @applyedistatusupdate = 1 and @SkipPopulating879_889Records = 0 and @recordvalidated = 1
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
										,SupplierLoginID)
								   values(@tradingpartnervalue
								   ,'B'
								   ,@edibanner
								   ,@storedunsnumber
								   ,@banner
								   ,@costzoneid --'006'
								   ,@allstores
								   ,@requestedcost
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
								   )
							end		
											
						if @storecontexttypeid in (5) --and @applyedistatusupdate = 1 and @SkipPopulating879_889Records = 0
						  begin
						  
						  --declare @recbanner cursor
						  --declare @supplierbanner nvarchar(50)
						  
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
										,SupplierLoginID)
								   values(@tradingpartnervalue
								   ,'B'
								   ,@edibanner
								   ,@storedunsnumber
								   ,@supplierbanner --@banner
								   ,'006'
								   ,@allstores
								   ,@requestedcost
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
								   )
						
								fetch next from @recbanner into @supplierbanner

							end					
						
						close @recbanner
						deallocate @recbanner							
						
						end
			end
			
			if(@markeddeleted<>null)
				Begin
					update MaintenanceRequests set RequestStatus = case when @markeddeleted = 1 then 6 else 5 end
					where MaintenanceRequestID = @maintenancerequestid
				End
			else
				Begin
					update MaintenanceRequests set RequestStatus = 10
					where MaintenanceRequestID = @maintenancerequestid
				End
		
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
	end
	
close @recmr
deallocate @recmr

return
GO
