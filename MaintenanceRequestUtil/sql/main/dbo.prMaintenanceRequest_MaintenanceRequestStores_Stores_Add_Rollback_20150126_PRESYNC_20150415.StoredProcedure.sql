USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_MaintenanceRequestStores_Stores_Add_Rollback_20150126_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prMaintenanceRequest_MaintenanceRequestStores_Stores_Add_Rollback_20150126_PRESYNC_20150415]
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
--************************************************
declare @showquery bit=0
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
declare @storecountincontext int
declare @storecountinmrstable int
declare @storecountinmrstablecorrect bit
declare @atleastonerecordnotvalid bit
declare @foundinstoresetup int


set @atleastonerecordnotvalid = 0

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
			  --select requeststatus, approved, ProductID,Cost,PromoAllowance,SkipPopulating879_889Records, dtstorecontexttypeid,  costzoneid, *
			  --select *
			  --update mr set mr.requeststatus = 15
		  FROM [DataTrue_Main].[dbo].[MaintenanceRequests] mr
			where 1 = 1
			and RequestStatus in (0,1,17,-27)
			and isnull(Approved, -1) <> 0
			and ProductId is not null
			and SupplierID is not null
			and dtstorecontexttypeid is not null
			and RequestTypeID in (1,2,3,4,6,7,8,9,10,20)
			and  DATEADD(day, -100, getdate()) < SubmitDateTime -- or MaintenanceRequestID = 33036)
			and PDIParticipant=0
			
			order by MaintenanceRequestID 


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

while @@FETCH_STATUS = 0
	begin
print @maintenancerequestid
print @productid
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
		set @storecountinmrstablecorrect = 0
		
set @uniqueid = NEWID()		
		
If @allstores = 0
	begin
						select @storecountinmrstable = COUNT(storeid) 
						from MaintenanceRequestStores 
						where MaintenanceRequestID = @maintenancerequestid
						
						if @storecountinmrstable > 0
							begin
								set @storecountinmrstablecorrect = 1
							end
							
					If @storecontexttypeid =4 --All Stores Supplier Serves
					begin
					
					
						select distinct storeid
						into zztemp_storesforbanners
						from StoreTransactions
						where SupplierID = @supplierid
						and SaleDateTime > '11/30/2011'
						
						select @storecountincontext = COUNT(storeid)
						from zztemp_storesforbanners					
						
						select @storecountinmrstable = COUNT(storeid) 
						from MaintenanceRequestStores 
						where MaintenanceRequestID = @maintenancerequestid
						
						if @storecountincontext <> @storecountinmrstable
							begin
							
								insert into MaintenanceRequestStores 
								(MaintenanceRequestID,StoreID,Included)
								select @maintenancerequestid, storeid, 1
								from zztemp_storesforbanners
								where StoreID not in
								(select StoreID from MaintenanceRequestStores
								where MaintenanceRequestID = @maintenancerequestid)
								set @storecountinmrstablecorrect = 1
	                      	
							end	
						else
							begin
								set @storecountinmrstablecorrect = 1
							end	
										
						drop table zztemp_storesforbanners												
					    end	
						
						
	end
else
	begin
				If @storecontexttypeid = 1 --Store Specific
					begin
						--declare @storecountincontext int
						select @storecountinmrstable = COUNT(storeid) 
						from MaintenanceRequestStores 
						where MaintenanceRequestID = @maintenancerequestid
						
						if @storecountinmrstable > 0
							begin
								set @storecountinmrstablecorrect = 1
							end
							
							
					end
					
				If @storecontexttypeid = 2 --Banner (custom1 in stores table)
					begin

						select @storecountincontext = COUNT(storeid)
						from stores
						where StoreID in
						(select storeid 
						from stores
						where LTRIM(rtrim(custom1)) = @banner
						and StoreID not in(select StoreID from SupplierStoreExclud
						where Supplierid=@supplierid and ChainID=@chainid
						and banner= @banner)	
						)					
											
						select @storecountinmrstable = COUNT(storeid) 
						from MaintenanceRequestStores 
						where MaintenanceRequestID = @maintenancerequestid
						
						if @storecountincontext <> @storecountinmrstable
							begin
								insert into MaintenanceRequestStores 
								(MaintenanceRequestID,StoreID,Included)
								select @maintenancerequestid, storeid, 1
								from stores
								where StoreID in
								(select storeid 
								from stores
								where LTRIM(rtrim(custom1)) = @banner
								and StoreID not in(select StoreID from SupplierStoreExclud
						        where Supplierid=@supplierid and ChainID=@chainid
						        and banner= @banner)	
								)
								and StoreID not in
								(select StoreID from MaintenanceRequestStores
								where MaintenanceRequestID = @maintenancerequestid)
								
								set @storecountinmrstablecorrect = 1
							end
						else
							begin
								set @storecountinmrstablecorrect = 1
							end																
					end				
				If @storecontexttypeid = 3 --CostZoneID
					begin
					
					
						select @storecountincontext = COUNT(storeid)
						from stores
						where StoreID in
								(select storeid 
								from CostZoneRelations r
								inner join CostZones z
								on r.CostZoneID = z.CostZoneID
								where z.CostZoneID = @costzoneid)				
											
						select @storecountinmrstable = COUNT(storeid) 
						from MaintenanceRequestStores 
						where MaintenanceRequestID = @maintenancerequestid
						
						if @storecountincontext <> @storecountinmrstable
							begin
							
								insert into MaintenanceRequestStores 
								(MaintenanceRequestID,StoreID,Included)
								select @maintenancerequestid, storeid, 1
								from stores
								where StoreID in
								(select storeid 
								from CostZoneRelations r
								inner join CostZones z
								on r.CostZoneID = z.CostZoneID
								where z.CostZoneID = @costzoneid)
								and StoreID not in
								(select StoreID from MaintenanceRequestStores
								where MaintenanceRequestID = @maintenancerequestid)
								set @storecountinmrstablecorrect = 1

							end	
						else
							begin
								set @storecountinmrstablecorrect = 1
							end									
					

					end		
				If @storecontexttypeid =4 --All Stores Supplier Serves
					begin
					
					
						select distinct storeid
						into zztemp_storesforbanners
						from StoreTransactions
						where SupplierID = @supplierid
						and SaleDateTime > '11/30/2011'
						
						select @storecountincontext = COUNT(storeid)
						from zztemp_storesforbanners					
						
						select @storecountinmrstable = COUNT(storeid) 
						from MaintenanceRequestStores 
						where MaintenanceRequestID = @maintenancerequestid
						
						if @storecountincontext <> @storecountinmrstable
							begin
							
								insert into MaintenanceRequestStores 
								(MaintenanceRequestID,StoreID,Included)
								select @maintenancerequestid, storeid, 1
								from zztemp_storesforbanners
								where StoreID not in
								(select StoreID from MaintenanceRequestStores
								where MaintenanceRequestID = @maintenancerequestid)
								set @storecountinmrstablecorrect = 1
	                      	
							end	
						else
							begin
								set @storecountinmrstablecorrect = 1
							end	
										
						drop table zztemp_storesforbanners												
					    end	

				If @storecontexttypeid = 5 --All Stores Supplier Serves
					begin
					
					
						select distinct storeid, cast('' as nvarchar(50)) as Banner 
						into #tempstoresforbanners
						from StoreTransactions
						where SupplierID = @supplierid
						and SaleDateTime > '11/30/2011'
						
						update t set t.Banner = s.custom1
						from #tempstoresforbanners t
						inner join stores s
						on t.StoreID = s.StoreID
						
						select storeid into #allstores
						from stores
						where Custom1 in
						(select distinct Banner from #tempstoresforbanners)
						
						insert into tmpMaintenanceRequestStoreIDList
						select distinct @uniqueid, storeid 
						from #allstores
						
						select @storecountincontext = COUNT(storeid)
						from #allstores							
						
						drop table #tempstoresforbanners
						drop table #allstores					
					
					
			
											
						select @storecountinmrstable = COUNT(storeid) 
						from MaintenanceRequestStores 
						where MaintenanceRequestID = @maintenancerequestid
						
						if @storecountincontext <> @storecountinmrstable
							begin
							
								insert into MaintenanceRequestStores 
								(MaintenanceRequestID,StoreID,Included)
								select @maintenancerequestid, storeid, 1
								from #allstores
								where StoreID not in
								(select StoreID from MaintenanceRequestStores
								where MaintenanceRequestID = @maintenancerequestid)
								set @storecountinmrstablecorrect = 1

							end	
						else
							begin
								set @storecountinmrstablecorrect = 1
							end															
					end						
										
end

		select @foundinstoresetup = COUNT(StoreSetupID)
		from storesetup
		where productid = @productid
		and SupplierID = @supplierid
		and StoreID in
		(select storeid 
		from MaintenanceRequestStores 
		where MaintenanceRequestID = @maintenancerequestid)
--select distinct requeststatus from MaintenanceRequests order by requeststatus	
	
if @foundinstoresetup = 0 and @requesttypeid = 3
	begin
	
		update MaintenanceRequests set RequestStatus = -333
		where MaintenanceRequestID = @maintenancerequestid
							
		exec dbo.prSendEmailNotification_PassEmailAddresses 'Possible UnAuthorized MaintenanceRequestStores Records'
		,'MaintenanceRequest records have been found that fail validation due to possible UnAuthorized products.  These records not be processed until this is corrected.  Please review all records with -333 requeststatus and correct asap.'
		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;mandeep@amebasoftwares.com'	
	
	end	
else		
	begin	

		if @storecountinmrstablecorrect = 1
			begin
						update MaintenanceRequests set RequestStatus = case when requesttypeid = 20 OR (SupplierID = 40559 and RequestTypeID IN (1,2)) then 17 else 2 end
						where MaintenanceRequestID = @maintenancerequestid
			end
		else
			begin
						update MaintenanceRequests set RequestStatus = -27
						where MaintenanceRequestID = @maintenancerequestid	
						set @atleastonerecordnotvalid = 1		
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
	end
	
close @recmr
deallocate @recmr

if @atleastonerecordnotvalid = 1
	begin
		exec dbo.prSendEmailNotification_PassEmailAddresses 'Possible Missing MaintenanceRequestStores Records'
		,'MaintenanceRequest records have been found that fail validation due to possible missing MaintenanceRequestStores records.  These records not be processed until this is corrected.  Please review all records with -27 requeststatus and correct asap.'
		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;irina.trush@icucsolutions.com'	
	
	end
	
	
	update m set RequestStatus=-27
            --select datetimecreated,OwnerMarketID,*	
		    FROM [DataTrue_Main].[dbo].[MaintenanceRequests] m		   
			where   RequestStatus in (2)	
			and MaintenanceRequestID not in 
			(select distinct MaintenanceRequestID From MaintenanceRequestStores 
			where datetimecreated>GETDATE()-90)	and datetimecreated>GETDATE()-90
			and Cost is not null
			and [Cost] <> 0			
			and ProductId is not null			
			and PDIParticipant=0
				and isnull(filetype,'ND')<>'888'

/*

select *
from maintenancerequests
where productid in
(28069,
28067,
28092)
*/
return
GO
