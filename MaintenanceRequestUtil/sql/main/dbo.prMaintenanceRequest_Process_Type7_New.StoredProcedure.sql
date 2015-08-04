USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_Process_Type7_New]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_Process_Type7_New]
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
declare @displaystoresetup bit =0
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
			  ,Approved,ApprovalDateTime,ChainLoginID,DealNumber
			  ,DeleteDateTime,DeleteLoginId,DeleteReason,DenialReason
			  ,EmailGeneratedToSupplier,EmailGeneratedToSupplierDateTime
			  ,RequestStatus,Skip_879_889_Conversion_ProcessCompleted
			  ,SubmitDateTime
			  --select ProductID,Cost,PromoAllowance,SkipPopulating879_889Records, dtstorecontexttypeid,  costzoneid, *
		  FROM [DataTrue_Main].[dbo].[MaintenanceRequests] mr
			where 1 = 1
			and RequestTypeID in (7)
			and RequestStatus in (2)
			and Approved = 1
			and PromoAllowance is not null
			and PromoAllowance <> 0
			and dtstorecontexttypeid is not null
			and ProductId is not null
			order by Startdatetime, EndDateTime

open @recmr

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
	,@Approved 
	,@ApprovalDateTime 
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

		select @suppliername = SupplierName, @tradingpartnervalue = UniqueEDIName
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
			when @supplierid = 40569 then 'CHO'
			when @supplierid = 42148 then 'TTT'
			when @supplierid = 41440 then 'SOUR'
		else @tradingpartnervalue
		end		


		set @productpricetypeid = 8
			


		set @pricevaluetopass = @promoallowance
			
		select @storeid=StoreID from MaintenanceRequestStores
		where MaintenanceRequestID=@maintenancerequestid
		

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
			
						
		if @requesttypeid in (7) -- and @applyedistatusupdate = 1 and @recordvalidated = 1 and @PendForOverlappingDates = 0
			begin
			if @edipromorecordid is not null
					begin
						select @storeidentifierfromstorestable = case when @storecontexttypeid =1 then ltrim(RTRIM(storeidentifier)) else null end
							,@custom1fromstorestable = LTRIM(rtrim(custom1))
							,@storedunsnumberfromstorestable = LTRIM(rtrim(DunsNumber))
							,@edibanner = LTRIM(rtrim(custom3))
							,@storesbtnumberfromstorestable = LTRIM(rtrim(custom2))
							from stores where storeid = @storeid
							
						update datatrue_edi.dbo.Promotions
						set Loadstatus = case when @SkipPopulating879_889Records = 1 then 20 else 10 end,
						PromotionStatus = case when isnull(@markeddeleted, 0) = 1 then '09' else '08' end,
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

								   
						where RecordID = @edipromorecordid
					end
			else
			begin
				if @storecontexttypeid = 1 and @applyedistatusupdate = 1 and @SkipPopulating879_889Records = 0
					begin
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
								   ,isnull(@tradingpartnerpromotionidentifier, 'MR-' + LTRIM(rtrim(@tradingpartnervalue)) + '-' + @upc12 + LEFT(replace(replace(cast(@startdate as nvarchar), ' ', ''), ':',''), 11))
								   ,@banner
								   ,DunsNumber
								   	,case when upper(@dtproductdescription) = 'UNKNOWN' then @itemdescription else @dtproductdescription end
								   ,ltrim(rtrim(cast(@pricevaluetopass as nvarchar)))
								   ,@upc
								   ,@upc12
								   ,10 --loadstatus
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
								   ,case when isnull(@markeddeleted, 0) = 1 then '09' else '08' end	
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
							
					
						if @storecontexttypeid = 2 --and @applyedistatusupdate = 1 and @SkipPopulating879_889Records = 0
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
								   values('006'
								   ,@tradingpartnervalue
								   ,@startdate
								   ,@enddate
								   ,isnull(@tradingpartnerpromotionidentifier, 'MR-' + LTRIM(rtrim(@tradingpartnervalue)) + '-' + @upc12 + LEFT(replace(replace(cast(@startdate as nvarchar), ' ', ''), ':',''), 11))
								   ,@banner
								   ,@storedunsnumber
								   ,case when upper(@dtproductdescription) = 'UNKNOWN' then @itemdescription else @dtproductdescription end
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
								   ,@banner
								   ,@costzoneid
								   ,CASe when cast(@enddate as date) < dateadd(day, 2, getdate()) then 1 else 0 end
									,case when isnull(@markeddeleted, 0) = 1 then '09' else '08' end
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
									)
							end


						if @storecontexttypeid in (3,4) --and @applyedistatusupdate = 1 and @SkipPopulating879_889Records = 0
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
								   ,[dtbanner]
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
								   values(@costzoneid
								   ,@tradingpartnervalue
								   ,@startdate
								   ,@enddate
								   ,isnull(@tradingpartnerpromotionidentifier, 'MR-' + LTRIM(rtrim(@tradingpartnervalue)) + '-' + @upc12 + LEFT(replace(replace(cast(@startdate as nvarchar), ' ', ''), ':',''), 11))
								   ,@banner
								   ,@storedunsnumber
								   ,case when upper(@dtproductdescription) = 'UNKNOWN' then @itemdescription else @dtproductdescription end
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
								   ,@storecontexttypeid --2 --storecontexttypeid
								   ,@maintenancerequestid
								   ,'MR'
								   ,@banner
								   ,@costzoneid
								   ,CASe when cast(@enddate as date) < dateadd(day, 2, getdate()) then 1 else 0 end
									,case when isnull(@markeddeleted, 0) = 1 then '09' else '08' end
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
									)
							end
				


				
						end
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
			,@Approved 
			,@ApprovalDateTime 
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



/*

select top 100 *
from datatrue_edi.dbo.promotions
order by recordid desc

*/
return
GO
