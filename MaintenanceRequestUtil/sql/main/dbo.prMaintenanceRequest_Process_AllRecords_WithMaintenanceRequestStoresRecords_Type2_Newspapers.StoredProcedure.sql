USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_Process_AllRecords_WithMaintenanceRequestStoresRecords_Type2_Newspapers]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_Process_AllRecords_WithMaintenanceRequestStoresRecords_Type2_Newspapers]
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
declare @displaystoresetup bit = 1
declare @additemtostoresetup bit = 1
declare @createtype2recordfromtype1record bit = 0
--*************************************************
declare @senddeletedoverlappingpromos bit=0
declare @checkforoverlappingdates bit=0
declare @removeexistingproductpricesrecordswithoverlappingdates bit=0
declare @useupcofduplicateproductids bit= 0
declare @lookforexactmatches bit = 0
declare @exactmatchfound bit
declare @PDIParticipant bit

declare @foundinstoresetup int
declare @storecountincontext int
--Irina add this to production copy
declare @includeinadjustments bit

  update m set RequestStatus=-27
            --select datetimecreated,OwnerMarketID,*	
		    FROM [DataTrue_Main].[dbo].[MaintenanceRequests] m		   
			where   RequestStatus in (2)	
			and MaintenanceRequestID not in 
			(select distinct MaintenanceRequestID From MaintenanceRequestStores 
			where datetimecreated>GETDATE()-90)	and datetimecreated>GETDATE()-90
			and Approved = 1
			and RequestTypeID =2
			and Cost is not null
			and [Cost] <> 0			
			and ProductId is not null			
			and bipad is not null 

update  m set m.SkipPopulating879_889Records = case when SupplierID = 40558 then 1 else 0 end
--select *
from dbo.MaintenanceRequests m
where 1 = 1
and (RequestStatus in (2,11) or MarkDeleted = 1)
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
			and RequestTypeID in (2)
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
			,PDIParticipant
			,isnull(RequestSource, '')
			  
			  --select ProductID,Cost,PromoAllowance,SkipPopulating879_889Records, dtstorecontexttypeid,  costzoneid, *
		  FROM [DataTrue_Main].[dbo].[MaintenanceRequests] mr
			where  RequestStatus in (2)
			--and Approved = 1
			and RequestTypeID in (2)
			and Cost is not null
			and [Cost] <> 0
			and ProductId is not null
			and SubmitDateTime > '2/1/2013'	
			and Bipad is not null
			and supplierid = 82607
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
	,@PDIParticipant
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
														
							
							
							
				if @SkipPopulating879_889Records = 0 and @supplierid = 40558
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
											exec [dbo].[prProductPrice_Manage_20140602]
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
											--Irina add this parameter in production copies
											,@includeinadjustments
										--end
								end			
							
							--if @additemtostoresetup = 1 and @foundinstoresetup <> @storecountincontext
							--	begin
								
									exec [dbo].[prStoreSetup_Manage_Assignment]
										@chainid
										,@storeid
										,@productid
										,@brandid
										,@supplierid
										,@startdate
										,@enddate
--ALTER procedure [dbo].[prStoreSetup_Manage_Assignment]
--@chainid int=0
--,@storeid int=0
--,@productid int=0
--,@brandid int=0
--,@supplierid int=0
--,@startdate date
--,@enddate date								
								--end
							
							
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
		
		if @requesttypeid in (1, 2) and @applyedistatusupdate = 1 and @recordvalidated = 1 and @PendForOverlappingDates = 0
			begin
				if @supplierid = 41465 and @requestsource = 'TMP'
					begin
						update datatrue_edi.dbo.costs
						set recordstatus = 20
						where RecordID = @edicostrecordid
						
						set @edicostrecordid = null
					
					end			
				if @edicostrecordid is not null
					begin
					
					
							select @storeidentifierfromstorestable = ltrim(RTRIM(storeidentifier))
							,@custom1fromstorestable = LTRIM(rtrim(custom1))
							,@storedunsnumberfromstorestable = LTRIM(rtrim(DunsNumber))
							,@edibanner = LTRIM(rtrim(custom3))
							,@storesbtnumberfromstorestable = LTRIM(rtrim(custom2))
							from stores where storeid = @storeid
							
						update datatrue_edi.dbo.Costs
						set RecordStatus = case when  @PDIParticipant =1 then 25 
						                        when @PDIParticipant =0 then 10						                         
						                        end, 
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
						,[PartnerName]=left(@suppliername,30)
						,[Recordsource]='EDI'
						,[ProductIdentifier] = @upc12
						where RecordID = @edicostrecordid
					end
				else
					begin--************************************************
					
					if @supplierid = 41465
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
											,@supplierloginid )
									
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
												,SupplierLoginID)
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
											,@supplierloginid )
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
												,SupplierLoginID)
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
											,@supplierloginid )
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
												,SupplierLoginID)
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
											,@supplierloginid )
								
										fetch next from @recbanner into @supplierbanner

									end					
								
								close @recbanner
								deallocate @recbanner							
								
								end
								
						end	
							
							
										
					end--**************************************************		
					
				if @requesttypeid = 1 and @createtype2recordfromtype1record = 1
					begin
					if @storecontexttypeid = 1 and @applyedistatusupdate = 1 and @SkipPopulating879_889Records = 0
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
									,@supplierloginid )
							
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
										,SupplierLoginID)
								   values(@tradingpartnervalue
								   ,'B'
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
									,@supplierloginid )
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
										,SupplierLoginID)
								   values(@tradingpartnervalue
								   ,'B'
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
									,@supplierloginid )
							end		
											
						if @storecontexttypeid in (5) and @applyedistatusupdate = 1 and @SkipPopulating879_889Records = 0
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
									,@supplierloginid )
						
								fetch next from @recbanner into @supplierbanner

							end					
						
						close @recbanner
						deallocate @recbanner							
						
						end
						
							
												
					
					end																			
			end
		if @requesttypeid in (3, 4, 5) and @applyedistatusupdate = 1 and @recordvalidated = 1 and @PendForOverlappingDates = 0
			begin
				if @edipromorecordid is not null
					begin
						update datatrue_edi.dbo.Promotions
						set Loadstatus = case when @SkipPopulating879_889Records = 1 then 20 else 10 end,
						PromotionStatus = case when isnull(@markeddeleted, 0) = 1 then '03' else IsNull(PromotionStatus,'01') end,
						dtmaintenancerequestid = @maintenancerequestid,
						SentToRetailer = CASe when cast(dateendpromotion as date) < dateadd(day, 2, getdate()) then 1 else 0 end,
						ProductName = Case when upper(@dtproductdescription) = 'UNKNOWN' then ProductName else @dtproductdescription end,
						ProductNameReceived = ProductName

						where RecordID = @edipromorecordid
					end
				else
					begin
					
					
					
							if @storecontexttypeid = 1 and @applyedistatusupdate = 1 and @SkipPopulating879_889Records = 0
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
								   ,isnull(@tradingpartnerpromotionidentifier, 'MR-' + LTRIM(rtrim(@tradingpartnervalue)) + '-' + @upc12 + LEFT(replace(replace(cast(@startdate as nvarchar), ' ', ''), ':',''), 11))
								   ,@banner
								   ,DunsNumber
								   	,case when upper(@dtproductdescription) = 'UNKNOWN' then @itemdescription else @dtproductdescription end
								   ,@pricevaluetopass
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
--select top 100 * from stores								   





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
								   ,isnull(@tradingpartnerpromotionidentifier, 'MR-' + LTRIM(rtrim(@tradingpartnervalue)) + '-' + @upc12 + LEFT(replace(replace(cast(@startdate as nvarchar), ' ', ''), ':',''), 11))
								   ,@banner
								   ,@storedunsnumber
								   ,case when upper(@dtproductdescription) = 'UNKNOWN' then @itemdescription else @dtproductdescription end
								   ,@pricevaluetopass
								   ,@upc
								   ,@upc12
								   ,10 --loadstatus
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
								,@supplierloginid
								   )
								end
							end

				
					
					
					
					
						if @storecontexttypeid = 2 and @applyedistatusupdate = 1 and @SkipPopulating879_889Records = 0
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
								   values('006'
								   ,@tradingpartnervalue
								   ,@startdate
								   ,@enddate
								   ,isnull(@tradingpartnerpromotionidentifier, 'MR-' + LTRIM(rtrim(@tradingpartnervalue)) + '-' + @upc12 + LEFT(replace(replace(cast(@startdate as nvarchar), ' ', ''), ':',''), 11))
								   ,@banner
								   ,@storedunsnumber
								   ,case when upper(@dtproductdescription) = 'UNKNOWN' then @itemdescription else @dtproductdescription end
								   ,@pricevaluetopass
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
									)
							end


						if @storecontexttypeid in (3,4) and @applyedistatusupdate = 1 and @SkipPopulating879_889Records = 0
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
								   ,@pricevaluetopass
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
	,@PDIParticipant
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


/*
select c.dtproductid, *
--update r set r.productid = c.dtproductid
from maintenancerequests r 
inner join datatrue_edi.dbo.costs c
on r.datatrue_edi_costs_recordid = c.recordid
where r.requeststatus = 11

truncate table dbo.tmpMaintenanceRequestStoreIDList

select * from MaintenanceRequestS where requeststatus = 8

select * from MaintenanceRequestS where approved = 1 and requesttypeid = 1 and requeststatus in (0,1) and (cost is null or cost = 0)

--morning checks

select *
from DataTrue_EDI..Inbound846Inventory
WHERE RecordStatus = 0
and EdiName in ('SHM', 'PEP', 'GOP','BIM')
and PurposeCode in ('CNT')

select *
from DataTrue_EDI..Inbound846Inventory
WHERE RecordStatus = 0
and EdiName in ('SHM', 'PEP', 'GOP','BIM')
and PurposeCode in ('DB', 'CR')

select p.Description, r.ItemDescription, *
--update p set p.Description = r.ItemDescription
from MaintenanceRequests r
inner join products p
on r.productid = p.productid
and upper(ltrim(rtrim(p.description))) = 'UNKNOWN'
and r.approved = 1
and r.ItemDescription is not null
and len(r.ItemDescription) > 0

select * from datatrue_edi.dbo.promotions where loadstatus = 0 order by recordid desc
select * from datatrue_edi.dbo.costs where recordstatus = 0 order by recordid desc

select * from datatrue_edi.dbo.promotions where Promotionstatus = '03' order by recordid desc


select *
  FROM [DataTrue_Main].[dbo].[MaintenanceRequests] mr
	where 1 = 1
	--and Banner is null
	and LEN(banner) < 1
	--and Approved = 1
	and RequestStatus = 0
	--and ProductId is not null
	--and SupplierID in (40558)
	order by ApprovalDateTime

select * from datatrue_edi.dbo.promotions where loadstatus = 0 order by recordid desc
select * from datatrue_edi.dbo.costs where recordstatus = 0
select top 890 * from datatrue_edi.dbo.costs order by recordid desc
select *  from update datatrue_edi.dbo.costs set PartnerIdentifier = 'GOP' where Partnername = 'GOPHER NEWS COMPANY' and PartnerIdentifier is null

select * from datatrue_edi.dbo.promotions where recordid = 840

select * from datatrue_edi.dbo.edi_suppliercrossreference

select *  from maintenancerequests where requeststatus = -26

select distinct requeststatus from maintenancerequests
select * from maintenancerequeststores where storeid = 40945
select distinct custom1 from stores

--*************************Cost Zones******************************8
select * from costzones
select * from costzonerelations where costzoneid = 1772

select * from costzonerelations where storeid = 40945

select * from stores where custom1 = 'Shop N Save Warehouse Foods Inc'
--*************************Billing***********************************
select saledatetime, count(storetransactionid)
from storetransactions_working
where workingsource = 'POS'
and saledatetime > '11/30/2011'
and workingstatus < 5
group by saledatetime
order by saledatetime

 select banner, filename, saledate, COUNT(recordid)
from datatrue_edi.dbo.Inbound852Sales [No Lock]
where 1 = 1
and RecordStatus = 0
--and saledate = '2/24/2012'
and Qty <> 0
group by banner, filename, saledate
order by saledate desc

 select count(*)
from datatrue_edi.dbo.Inbound852Sales [No Lock]
where 1 = 1
and RecordStatus = 0
and recordtype = 0
and cast(saledate as date) >= '11/30/2011'
and Qty <> 0


select *
from datatrue_edi.dbo.Inbound852Sales
order by datetimereceived desc, saledate

select *
from invoicedetails
where cast(datetimecreated as date) = '2/8/2012'
and invoicedetailtypeid = 1
and banner = 'ABS'
order by saledate

 select storeidentifier, ProductIdentifier, cast(SaleDate as date), ltrim(rtrim(PONO)), COUNT(recordid)
from datatrue_edi.dbo.Inbound852Sales [No Lock]
where 1 = 1
and RecordStatus = 0
--and banner = 'SS'
--and CAST(saledate as date) = '1/29/2012'
group by storeidentifier, ProductIdentifier, cast(SaleDate as date), ltrim(rtrim(PONO))
having COUNT(recordid) > 1

0006017	072945761452	2012-02-07	NULL	3

where storeidentifier = '6017'
and upc = '072945761452'
and saledatetime = '2/4/2012'

 select *
--update s set recordstatus = -5
from datatrue_edi.dbo.Inbound852Sales s
where RecordStatus = 0
and Banner = 'SYNC'

select count(*)
from storetransactions_working [no lock]
where cast(saledatetime as date) = '1/18/2012'

select count(*)
from storetransactions_working [no lock]
where cast(datetimecreated as date) = '1/20/12'
and transactiontypeid in (2, 6)

select distinct workingstatus
from storetransactions_working [no lock]
where cast(datetimecreated as date) = '1/20/12'
and transactiontypeid in (2, 6)

select *
from storetransactions_working [no lock]
where cast(datetimecreated as date) = '1/20/12'
and transactiontypeid in (2, 6)
and workingstatus = -6

select count(*)
from storetransactions [no lock]
where cast(datetimecreated as date) = '1/20/12'
and transactiontypeid in (2, 6)


select count(*)
from invoicedetails [no lock]
where cast(saledate as date) = '1/18/2012'

select count(*)
from invoicedetails [no lock]
where cast(datetimecreated as date) = '1/20/2012'
and invoicedetailtypeid = 1

select count(*)
from datatrue_edi.dbo.invoicedetails [no lock]
where cast(saledate as date) = '1/18/2012'
--*******************************************************************
710
(/order by startdatetime

select * from productidentifiers where identifiervalue = '043396362796'
select * from products where productid = 9836

select * into import.dbo.productprices_20120406BeforeOverlapDeletes from productprices
select * into import.dbo.maintenancerequests_20120406 from maintenancerequests
select * into import.dbo.storesetup_20120406 from storesetup

select * from datatrue_edi.dbo.Costs order by RecordID desc
select *  FROM [DataTrue_Main].[dbo].[MaintenanceRequests] where ltrim(rtrim(upc)) = '0'

select *  FROM [DataTrue_Main].[dbo].[MaintenanceRequests] 
where maintenancerequestid = 4956
where supplierid = 40567
order by submitdatetime


select * from costzonerelations
where costzoneid = 874
where storeid =  40945


select distinct recordsource from datatrue_edi.dbo.Costs 

select *
--update r set r.dtstorecontexttypeid = 2
from maintenancerequests r
where r.dtstorecontexttypeid is null
and r.supplierid = 40559
and r.requeststatus = 0
and r.approved = 1
and r.allstores = 1

select c.dtbanner, r.banner, *
--update r set r.banner = c.dtbanner
from datatrue_edi.dbo.Costs c
inner join maintenancerequests r
on c.recordid = r.datatrue_edi_costs_recordid
where r.requeststatus = 0
and r.dtstorecontexttypeid = 2
and r.banner is null


select c.dtbanner, r.banner, *
--update r set r.banner = c.dtbanner
from datatrue_edi.dbo.promotions c
inner join maintenancerequests r
on c.recordid = r.datatrue_edi_promotions_recordid
where r.requeststatus = 0
and r.dtstorecontexttypeid = 2
and r.banner is null

select * from datatrue_edi.dbo.promotions
where 1 = 1
and loadstatus = 1
and dtstorecontexttypeid = 2
and dtbanner is null

select * from datatrue_edi.dbo.Costs 
where 1 = 1
and recordstatus = 1
and dtstorecontexttypeid = 2
and dtbanner is null
and recordsource in ('WEB','MANUALSET')

select *
--update c set Effectivedate = '11/30/2011'
from datatrue_edi.dbo.Costs c
where 1 = 1
and recordsource in ('MANUALSET')
and Effectivedate is null

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
--update r set r.banner = 'Albertsons - IMW', dtstorecontexttypeid = 2  
FROM [DataTrue_Main].[dbo].[MaintenanceRequests] r
where requeststatus = 0
and approved = 1
and allstores = 1
and supplierid = 40559
and banner = 'ALBERTSONS IMW'

select *
--update r set r.banner = 'Albertsons - IMW', dtstorecontexttypeid = 3 
FROM [DataTrue_Main].[dbo].[MaintenanceRequests] r
where requeststatus = 0
and approved = 1
order by Startdatetime
--and allstores = 0
and supplierid = 41465

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

select * into import.dbo.productprices_20120117BeforeUpdates from productprices

select * from productprices where activestartdate = '12/30/2011' and activelastdate = '12/31/2011'

select top 100 * from datatrue_edi.dbo.promotions order by recordid desc
select distinct datetimecreated from datatrue_edi.dbo.promotions
update datatrue_edi.dbo.promotions set datetimecreated = '11/29/2011' where datetimecreated is null

select *
--update r set r.SkipPopulating879_889Records = 0, Skip_879_889_Conversion_ProcessCompleted = 1, approved = 1, dtstorecontexttypeid = 2
FROM [DataTrue_Main].[dbo].[MaintenanceRequests] r
where supplierid = 40558
and len(itemdescription) = 0
and datetimecreated > '12/11/2012'
order by maintenancerequestid desc

select *
FROM [DataTrue_Main].[dbo].[MaintenanceRequests]
where supplierid = 40570

truncate table dbo.tmpMaintenanceRequestStoreIDList



ALBERTSONS - SCAL	1	073410115374
ALBERTSONS - SCAL	1	073410115374
ALBERTSONS - SCAL	1	073130012397



select * from maintenancerequests 
where 1 = 1
and (requeststatus in (0,1,100) or markdeleted is not null)
and productid in 
(select productid from productidentifiers where charindex('(D)', identifiervalue) > 0)



*/

return
GO
