USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMRProcess_AllMRStoresRecords_Type1_new_PDI_01072015_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prMRProcess_AllMRStoresRecords_Type1_new_PDI_01072015_PRESYNC_20150329]
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

declare @costtablerecordid int
declare @RecordID int
declare @mridreturned int

declare @rec cursor
DECLARE @badrecids varchar(max)=''
DECLARE @Subject VARCHAR(MAX)=''
DECLARE @errMessage varchar(max)=''
DECLARE @badrecords table(MaintenanceRequestID int)


declare @foundinstoresetup int
declare @storecountincontext int
declare @includeinadjustments tinyint
declare @rowcount int

DECLARE @badrecids1 varchar(max)=''
DECLARE @Subject1 VARCHAR(MAX)=''
DECLARE @errMessage1 varchar(max)=''
DECLARE @badrecords1 table(MaintenanceRequestID int)

/************** set duplicate records tp requeststatus=999***************/

			
			/**************  fully duplicate records to requeststatus=999 in coming set ***************/
				
			select a.MaintenanceRequestID,FirstMRID  into zztemp_set_full_dupl
			from
			(select m1.MaintenanceRequestID ,min(m1.MaintenanceRequestID) OVER (PARTITION BY StoreID,vin,productid,chainid,supplierid,cost,startdatetime  ) as FirstMRID,
			StoreID,productid,vin,chainid,supplierid,cost,startdatetime
			from MaintenanceRequests m1
			inner join MaintenanceRequestStores s
			on s.MaintenanceRequestID=m1.MaintenanceRequestID
			and  m1.RequestStatus =2
			and  m1.RequestTypeID =1
			and  m1.Cost is not null
			and  isnull(m1.Cost,0) > 0			
			and  m1.ProductId is not null
			and  m1.bipad is null
			and m1.datetimecreated>GETDATE()-45	)a	
			where  a.MaintenanceRequestID<>FirstMRID	
			
			update m set requeststatus=999
			from MaintenanceRequests m
			inner join zztemp_set_full_dupl z
			on m.MaintenanceRequestID=z.MaintenanceRequestID	
			
			drop table zztemp_set_full_dupl


select distinct m.MaintenanceRequestID into ZZtemp_MR_dup_items1
from 
MaintenanceRequests m,
MaintenanceRequestStores s,
(select count(*) cnt, productid,vin,chainid,banner,storeid
			
			FROM [DataTrue_Main].[dbo].[MaintenanceRequests] mr
			inner join MaintenanceRequestStores s
			on mr.MaintenanceRequestID=s.MaintenanceRequestID
			where  RequestStatus in (2)
			and RequestTypeID in (1) 
			and Cost is not null
			and [Cost] <> 0			
			and ProductId is not null
			and PDIParticipant =0
			and bipad is  null
			and mr.datetimecreated>GETDATE()-45
			group by productid,vin,chainid,banner,storeid
			having COUNT(*)>1 )a
			where m.productid=a.productid
			and m.banner=a.banner
			and m.chainid=a.chainid
			and s.storeid=a.storeid
			and m.VIN=a.vin
			and m.RequestTypeID in (1) 
			and m.RequestStatus in (2)
			and m.PDIParticipant =0
			and m.bipad is  null
			
			if @@ROWCOUNT >0
			begin 

            insert @badrecords1 
	        select MaintenanceRequestID from  ZZtemp_MR_dup_items1
	
            set @errMessage1+='Conflict Records of type1 for the same item' +CHAR(13)+CHAR(10)
            end 

           if @errMessage1 <>''
		    begin
			set @Subject1 ='Conflict not PDI Records of type1 for the same item' 
			select @badrecids1 += cast(MaintenanceRequestID as varchar(13))+ ','
			from @badrecords1
			set @errMessage1+=CHAR(13)+CHAR(10)+'Record ID:'+CHAR(13)+CHAR(10)+@badrecids1
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com;charlie.clark@icucsolutions.com',
				@subject=@Subject1,@body=@errMessage1				
	
            end   
			
	update MaintenanceRequests set RequestStatus=18
	where MaintenanceRequestID in ( select MaintenanceRequestID from ZZtemp_MR_dup_items1)		

/* insert matching  Type 1 set of records into  temp table temp_MR_type1*/
	        select*	into ZZtemp_MR_records_type1
			--select bipad,*
		    FROM [DataTrue_Main].[dbo].[MaintenanceRequests] mr
			where  1=1
			and RequestStatus in (2)
			and Approved = 1
			and RequestTypeID in (1) 
			and Cost is not null
			and [Cost] > 0			
			and ProductId is not null
			and PDIParticipant=1
			and bipad is  null
			and datetimecreated>GETDATE()-45
			
			order by maintenancerequestid,Startdatetime, EndDateTime
	
	
	
/*********************************************************** STEP2**************************************	
	***********************insert missing records into SETUPSTORES from selected set of records for TYPE1*/		
			
			/*Step2 -1
			 create records for each store found in MaintenanceRequestStores with maxMaintenanceRequestID
			 per storeid,productid,SupplierID,chainid to insert in STORSETUP*/
			
			select max(m.MaintenanceRequestID) maxMRID,storeid,sP.productid,sp.SupplierPackageID,m.vin,m.SupplierID,chainid
			into ZZtemp_MRStores_records_type1 
			from ZZtemp_MR_records_type1 m
			inner join MaintenanceRequestStores s
			on m.MaintenanceRequestID=s.MaintenanceRequestID
			inner join SupplierPackages sP
			on m.VIN=sP.vin
			and m.chainid=sP.OwnerEntityID
			and m.SupplierID=sP.SupplierID
			group by storeid,SP.productid,sp.vin,sp.SupplierPackageID,m.SupplierID,chainid
			
			/*****************************Update active last date for terminated supplier ;
			*******************Update for each productid for vin. *********************************/
			update p set p.ActiveLastDate=m.StartDateTime-1
			from  ZZtemp_MRStores_records_type1 z
			inner join  ZZtemp_MR_records_type1 m			
			on m.MaintenanceRequestID=maxMRID
			inner join storesetup p
			on  z.storeid=p.storeid
			and z.chainid=p.chainid
			inner join SupplierPackages s
			on m.VIN=s.vin
			and  s.productid=p.productid
			and z.chainid=s.OwnerEntityID
			and z.SupplierID=s.SupplierID
			and z.SupplierID<>p.SupplierID
			and p.ActiveLastDate>m.StartDateTime
			
				/***************to insert  supplier which were previously terminated and not recovered*************************/
			select storeid,productid,SupplierID,chainid,StartDateTime into ZZtemp_new_Storesetup_records
				from
			(
			/***************find  supplier which were previously terminated*************************/
			select z.storeid,z.productid,z.SupplierID,z.chainid,m.StartDateTime 		
			from  ZZtemp_MRStores_records_type1 z
			inner join  ZZtemp_MR_records_type1 m			
			on m.MaintenanceRequestID=maxMRID
			inner join storesetup p
			on z.storeid=p.storeid 
			--andz.productid=p.productid			
			and z.chainid=p.chainid
			and z.SupplierID=p.SupplierID
			inner join SupplierPackages s
			on z.VIN=s.vin
			and  s.productid=p.productid
			and z.chainid=s.OwnerEntityID
			and z.SupplierID=s.SupplierID
			and p.ActiveLastDate<m.StartDateTime
			
			except
			
			/***************find  supplier which are recovered*************************/
			select z.storeid,z.productid,z.SupplierID,z.chainid,m.StartDateTime 			
			from  ZZtemp_MRStores_records_type1 z
			inner join  ZZtemp_MR_records_type1 m			
			on m.MaintenanceRequestID=maxMRID
			inner join storesetup p
			on z.storeid=p.storeid
			--and z.productid=p.productid
			and z.chainid=p.chainid
			and z.SupplierID=p.SupplierID
			inner join SupplierPackages s
			on z.VIN=s.vin
			and  s.productid=p.productid
			and z.chainid=s.OwnerEntityID
			and z.SupplierID=s.SupplierID
			and p.ActiveLastDate>m.StartDateTime)a
			
			
			
			
			/*/.r***********/
			insert into storesetup--ZZtemp_storesetup_40393_65590
									   
					   (ChainID
					   ,StoreID
					   ,ProductID
					   ,SupplierID
					   ,BrandID
					   ,ActiveStartDate
					   ,ActiveLastDate
					   ,LastUpdateUserID
					   ,DateTimeCreated)
				select 
				    chainid 
				   ,StoreID 
				   ,productid 
				   ,supplierid
				   ,0 
				   ,StartDateTime 
				   ,'2099-12-31'
				   ,0
				   , GETDATE()
				  -- select p.* ,m.StartDateTime ,minMRID
					from ZZtemp_new_Storesetup_records 		
			
			
			
		
			/********************************************** Step2-2*******************************************************************
			*******************************find storeid,chainid,SupplierID,productid which are not in Storestup 
			********************************and create table of them ZZtemp_stores_setup_missing_Type1*********************************************/
			
			SELECT * INTO    ZZtemp_storessetup_new_Type1_records 
			from   
			(select  distinct z.storeid,z.chainid,z.SupplierID,s.productid	
			from ZZtemp_MRStores_records_type1  z
			inner join SupplierPackages s
			on z.VIN=s.vin
			and z.chainid=s.OwnerEntityID
			and z.SupplierID=s.SupplierID                                  										
			EXCEPT			  
			select distinct s.storeid,s.chainid,SupplierID,s.ProductID from storesetup s with(NOLOCK)
			 ) a
			
				
			
			/*if records found then inset them in Storesetup (temp_storesetup_42490_74796)*/
			
			--select max(m.MaintenanceRequestID) maxMRID,storeid,sP.productid,m.vin,m.SupplierID,chainid
			--into ZZtemp_MRStores_records_type1 
			--from ZZtemp_MR_records_type1 m
			--inner join MaintenanceRequestStores s
			--on m.MaintenanceRequestID=s.MaintenanceRequestID
			--inner join SupplierPackages sP
			--on m.VIN=sP.vin
			--and m.chainid=sP.OwnerEntityID
			--and m.SupplierID=sP.SupplierID
			--group by storeid,SP.productid,sp.vin,m.SupplierID,chainid
				
			if @@ROWCOUNT>0
			insert into storesetup--ZZtemp_storesetup_40393_65590
									   
					   (ChainID
					   ,StoreID
					   ,ProductID
					   ,SupplierID
					   ,BrandID
					   ,ActiveStartDate
					   ,ActiveLastDate
					   ,LastUpdateUserID
					   ,DateTimeCreated)
				select 
				    p.chainid 
				   ,p.StoreID 
				   ,p.productid 
				   ,p.supplierid
				   ,0 
				   ,m.StartDateTime 
				   ,'2099-12-31'
				   ,0
				   , GETDATE()
				  -- select p.* ,m.StartDateTime ,minMRID
					from ZZtemp_storessetup_new_Type1_records  p
					inner join ZZtemp_MRStores_records_type1  t
					on  t.chainid=p.chainid
					and t.supplierid=p.supplierid
					and t.StoreID=p.storeid 
					inner join SupplierPackages s
			        on t.VIN=s.vin
					and s.productid=p.productid
			        and p.chainid=s.OwnerEntityID
			        and p.SupplierID=s.SupplierID  
					inner join MaintenanceRequests m
					on maxMRID=m.MaintenanceRequestid
					
					
	
					
			/*********************************************STEP3********************************************************
			insert records into PRODUCTPRICES from selected set of records for TYPE1 existing in ZZtemp_MR_records_type1*/		
			
			/******************************************STEP3-1*********************************************************
			find combination of storeid,productid,SupplierPackageID,SupplierID,chainid from ZZtemp_MR_records_type1
			which exists in productprices table but not for total match of UnitPrice or ActiveStartDate
			In other words chack for conflict. Type 1 should not have instance in ProdactPrices*/	
						
			select m.MaintenanceRequestID,s.storeid,sp.productid,m.vin,sp.SupplierPackageID,m.SupplierID,m.chainid,cost,startdatetime,datatrue_edi_costs_recordid
			into zztemp_MRStores_type2_type1
			from ZZtemp_MR_records_type1 m
			inner join MaintenanceRequestStores s
			on m.MaintenanceRequestID=s.MaintenanceRequestID
			inner join ProductPrices p
			on p.SupplierID=m.supplierid
			and s.StoreID=p.StoreID
			and m.chainid=p.ChainID
			and m.productid=p.ProductID
			inner join SupplierPackages sp
			on sp.VIN=m.vin
			and m.chainid=sp.OwnerEntityID
			and m.SupplierID=sp.SupplierID     
			and (cost<>UnitPrice or ActiveStartDate<>m.startdatetime or p.SupplierID<>m.supplierid)
			and ProductPriceTypeID=11
			
			
			update m set requesttypeid=2
			from MaintenanceRequests m
			inner join zztemp_MRStores_type2_type1 z
			on m.MaintenanceRequestID=z.MaintenanceRequestID
			
			
			update c set requesttypeid=2,PriceChangeCode='B'
			from DataTrue_EDI..costs c
			inner join zztemp_MRStores_type2_type1 z
			on datatrue_edi_costs_recordid=recordid
			
			delete from ZZtemp_MR_records_type1  where MaintenanceRequestID in (select MaintenanceRequestID from zztemp_MRStores_type2_type1)
						
			drop table zztemp_MRStores_type2_type1	
			
					
			/****************************************************STEP3-3-2*****************************************************
			 find MAX MaintenanceRequestID for storeid,productid,chainid (SupplierID might be swiched)
			 from selected set of records for TYPE1(the most recent request)
			 and insert them in table temp_MRStores_productprice_type1.
			 In case if more then 1 record send for 1 new item*/	
						
					
			select max(m.MaintenanceRequestID) maxMRID,storeid,sp.productid,m.vin,sp.SupplierPackageID,chainid,m.supplierid	
			into ZZtemp_MRStores_productprice_type1
			from ZZtemp_MR_records_type1 m
			inner join MaintenanceRequestStores s
			on m.MaintenanceRequestID=s.MaintenanceRequestID
			inner join SupplierPackages sp
			on sp.VIN=m.vin
			and sp.SupplierID=m.SupplierID
			and m.ChainID=sp.OwnerEntityID
			group by storeid,sp.productid,m.vin,sp.SupplierPackageID,chainid,m.supplierid	
			
			 
				
			/***************************************************** Step3-3************************************************
			find storeid,chainid,SupplierID,productid which are not in Productprices and 
			create temp table of them temp_Productprice_new_Type1 */
			
			SELECT * INTO    ZZtemp_Productprice_new_Type1  
			--select*
			from   
			(select  distinct t.storeid,m.chainid,s.productid,m.supplierid,m.SupplierPackageID
			from    zztemp_MRStores_productprice_type1  t  
			inner join  ZZtemp_MR_records_type1 m
			on m.MaintenanceRequestID=t.maxMRID    
			inner join SupplierPackages s
			on t.VIN=s.vin
			and t.chainid=s.OwnerEntityID
			and t.SupplierID=s.SupplierID                              										
			EXCEPT			  
			select distinct s.storeid,s.chainid,s.ProductID	,s.supplierid	,s.SupplierPackageID	
			from Productprices s with(NOLOCK)	where  ProductPriceTypeID=11  ) a
				
				
			--select * from temp_Productprices_42490_74796
				
			if @@ROWCOUNT>0
			insert into Productprices		--ZZtemp_Productprices								   
				   (ProductPriceTypeID
				   ,ChainID
				   ,StoreID
				   ,ProductID
				   ,SupplierID
				   ,UnitPrice
				   ,UnitRetail
				   ,BrandID
				   ,ActiveStartDate
				   ,ActiveLastDate
				   ,SupplierPackageID
				   ,LastUpdateUserID
				   ,DateTimeCreated)
				select 
				    11 
				   ,p.chainid 
				   ,p.StoreID 
				   ,p.productid 
				   ,m.supplierid
				   ,m.cost
				   ,m.SuggestedRetail
				   ,0 
				   ,m.StartDateTime 
				   ,'2099-12-31'
				   ,p.SupplierPackageID
				   ,0
				   , GETDATE()
				  -- select p.* --,m.StartDateTime ,minMRID
			        from ZZtemp_Productprice_new_Type1    p
			        inner join  zztemp_MRStores_productprice_type1  t 
			        on p.productid= t.productid
			        and p.StoreID=t.storeid
			        and p.chainid=t.chainid
			        and p.SupplierID=t.SupplierID
			        and p.SupplierPackageID=t.SupplierPackageID		        
	                inner join  ZZtemp_MR_records_type1 m
			        on m.MaintenanceRequestID=t.maxMRID  
			         /*** only for max mrid if duplicates exist!!!!!!!!!!!!!!!!!!!!!!!! do not remove****/
										
					
							
						select  maxMR,storeid,productid,chainid,supplierid,MaintenanceRequestID,StartDateTime into ZZtemp_MRS_set_no_dup1
				from 
				(select MAX(m.MaintenanceRequestId)  OVER (PARTITION BY storeid,productid,chainid,supplierid ) as maxMR,storeid,productid,chainid,supplierid,m.MaintenanceRequestID,StartDateTime 
				from ZZtemp_MR_records_type1 m
				inner join MaintenanceRequestStores s
				on m.MaintenanceRequestID=s.MaintenanceRequestID
				)a
				where maxMR=MaintenanceRequestID			
				
	/*************** fix PB last date***********************/			
				
				select  p.ProductPriceID,p.storeid,p.productid,p.chainid,p.supplierid,p.activestartdate,p.ActiveLastDate ,z.startdatetime,p.ProductPriceTypeID  
into zztemp_PRODUCTPRICE_fix1
from 
			ProductPrices p
			inner join 
			(
			select  p.storeid,p.productid,p.chainid,p.supplierid,unitprice,cast(activestartdate as date) activestartdate
			from ZZtemp_MRS_set_no_dup1 z
			inner join productprices p
			on p.supplierid=z.supplierid
			and p.storeid=z.StoreID
			and p.productid=z.productid
			and ProductPriceTypeID=3
			except
			select  distinct s.storeid,m.productid,m.chainid,m.supplierid,m.cost,cast(m.startdatetime as date)
			from MaintenanceRequests m
			inner join MaintenanceRequestStores s
			on s.MaintenanceRequestID=m.MaintenanceRequestID
			inner join ZZtemp_MRS_set_no_dup1 z
			on m.supplierid=z.supplierid
			and s.storeid=z.StoreID
			and m.productid=z.productid
			and m.ChainID=z.chainid
			and RequestTypeID in (1,2,15))a
		
		on   a.supplierid=p.supplierid
			and a.storeid=p.StoreID
			and a.productid=p.productid
			and a.ChainID=p.chainid
			and cast(a.activestartdate as date)=cast(p.ActiveStartDate as date)
			and a.UnitPrice=p.UnitPrice
			inner join ZZtemp_MRS_set_no_dup1 z
			on z.supplierid=p.supplierid
			and z.storeid=p.StoreID
			and z.productid=p.productid
			and z.ChainID=p.chainid
			and p.ProductPricetypeID=3
			and cast(p.ActiveLastDate as date)>cast((z.StartDateTime-1) as date)
			order by p.storeid,p.productid  
			
			
			update p set p.ActiveLastDate=z.StartDateTime-1		
			--select p.ActiveStartDate,p.ActiveLastDate,z.StartDateTime,p.ProductPricetypeID,*			
			from productprices p
			inner join zztemp_PRODUCTPRICE_fix1 z
			on z.productpriceid=p.productpriceid
			
			drop table ZZtemp_MRS_set_no_dup1
            drop table zztemp_PRODUCTPRICE_fix1
								
				/* **************************STEP4*********************************
				update DATATRUE_EDI..COSTS for MR EDI records**********************/
						
					   update c
					   
					   set c.PartnerName=s.suppliername	
					   --select,*					
					   from  datatrue_edi.dbo.Costs c
					   inner join ZZtemp_MR_records_type1 m
					   on c.RecordID = m.datatrue_edi_costs_recordid
					   inner join Suppliers  s 
					   on s.SupplierID = m.supplierid
			           and  c.PartnerName is null
			           
			           update c
					   set c.StoreIdentifier=s.CorporateIdentifier
					   --select c.*			
					   from  datatrue_edi.dbo.Costs c
					   inner join ZZtemp_MR_records_type1 m
					   on c.RecordID = m.datatrue_edi_costs_recordid
					   inner join [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp] s
					   on Custom1 = LTRIM(rtrim(m.banner)) 
					   and suppliername =c.PartnerName 
					   and Custom1 is not null
			           and c.StoreIdentifier is null 
					
							
				    	update c
						set c.RecordStatus = case when c.SkipPopulating879_889Records = 1 and c.pdiparticipant=1 then 35
						                          when isnull(c.SkipPopulating879_889Records,0) <>1 and c.pdiparticipant=1 then 25
						                          
						                          end 
						,c.dtmaintenancerequestid = m.maintenancerequestid 
						,c.ProductName = Case when upper(m.dtproductdescription) = 'UNKNOWN' then ProductName else m.dtproductdescription end
						,c.ProductNameReceived = ProductName
						,c.deleted = case when isnull(m.MarkDeleted, 0) = 1 then 1 else null end
						,c.SentToRetailer = case when isnull(m.MarkDeleted, 0) = 1 then 0 else SentToRetailer end
						,c.StoreName=ltrim(rtrim(m.Banner))
						,c.PricingMarket= case when m.dtstorecontexttypeid =1 then '002'
						                       when m.dtstorecontexttypeid=2 then '006'
						                       when m.dtstorecontexttypeid=3 then m.costzoneid
						                       end
						
						,c.dtproductid=m.productid
						,c.dtbrandid=m.brandid
						,c.Recordsource='EDI'
						,c.ProductIdentifier = m.upc12
						,SubmitDateTime = m.SubmitDateTime
						from  datatrue_edi.dbo.Costs c
						inner join ZZtemp_MR_records_type1 m
						on c.RecordID = m.datatrue_edi_costs_recordid
							
						
				update m set RequestStatus=5	
				--select*
				from MaintenanceRequests m
				inner join 	ZZtemp_MR_records_type1 z
				on m.MaintenanceRequestID=z.MaintenanceRequestID
				inner join DataTrue_EDI..costs	c 
				on m.datatrue_edi_costs_recordid=c.RecordID
				inner join MaintenanceRequestStores s
				on m.MaintenanceRequestID=s.MaintenanceRequestID
				and recordstatus in (25,35)	
						 
				/****************create costs records with PriceChangeCode=B  forrecords with PriceChangeCode=A  **************/
				
				----for  chains in (60620,64074,64298, 50964) and supplierid <> 41465
				
				   			
				/* **************************STEP5*********************************
				INSERT into DATATRUE_EDI..COSTS for MR WEB records**********************/
				
				INSERT INTO [DataTrue_EDI].[dbo].[Costs]
											   (
											   [PriceChangeCode]
											   --,[Banner]
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
											 --  ,[PartnerName]
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
												,dtstoreid
												)
										   select 
										   'A'
										   --,edibanner
										   ,t.StoreIdentifier
										   ,banner
										   ,case when t.dtstorecontexttypeid=1 then '002'
						                       when t.dtstorecontexttypeid=2 then '006'
						                       when t.dtstorecontexttypeid=3 then t.costzoneid end
										   ,allstores
										   ,cost
										   ,suggestedretail
										   ,upc
										   ,upc12
										   ,case when upper(dtproductdescription) = 'UNKNOWN' then itemdescription else dtproductdescription end
										   ,startdatetime
										   ,enddatetime
										   , case 
						                          when t.SkipPopulating879_889Records = 1 and t.pdiparticipant=1 then 35 
						                          when isnull(t.SkipPopulating879_889Records,0) <>1 and t.pdiparticipant=1 then 25
						                          end 
						                         
										   ,t.chainid
										   ,productid
										   ,brandid
										   ,supplierid
										   ,banner
									     --,suppliername
										   ,dtstorecontexttypeid
										   ,t.maintenancerequestid
										   ,'MR'
										   ,costzoneid
										   ,case when isnull(MarkDeleted, 0) = 1 then 1 else null end
										   ,ApprovalDateTime 
										   ,Approved 
											,brandidentifier 
											,ChainLoginID 
											,Currentsetupcost
											,DealNumber
											,DeleteDateTime
											,DeleteLoginId
											,DeleteReason
											,DenialReason 
											,EmailGeneratedToSupplier 
											,EmailGeneratedToSupplierDateTime
											,RequestStatus 
											,1
											,Skip_879_889_Conversion_ProcessCompleted 
											,SkipPopulating879_889Records  
											,SubmitDateTime
											,supplierloginid 
											,s.StoreIdentifier
	       									,s.storeid
										from ZZtemp_MR_records_type1 t
										inner join MaintenanceRequestStores m
										on t.MaintenanceRequestID=m.MaintenanceRequestID
										inner join stores s
										on m.Storeid = s.storeid
										where datatrue_edi_costs_recordid is null
										
								  update c
											   
									set PartnerIdentifier = UniqueEDIName
									from datatrue_edi.dbo.Costs c
									inner join ZZtemp_MR_records_type1 m
									on c.dtmaintenancerequestid = m.MaintenanceRequestID
									inner join Suppliers s on s.SupplierID=ltrim(rtrim(dtsupplierid))
									and PartnerIdentifier is null 

									
									
									update c
									set c.PartnerName=s.suppliername	,c.SupplierIdentifier=s.SupplierIdentifier
									--select,*					
									from  datatrue_edi.dbo.Costs c
									inner join ZZtemp_MR_records_type1 m
									on c.dtmaintenancerequestid = m.MaintenanceRequestID
									inner join Suppliers  s 
									on s.SupplierID = m.supplierid
									and  c.PartnerName is null

									update c
									set c.StoreIdentifier=s.CorporateIdentifier,c.banner = s.banner
									--select c.*			
									from  datatrue_edi.dbo.Costs c
									inner join ZZtemp_MR_records_type1 m
									on c.dtmaintenancerequestid = m.MaintenanceRequestID
									inner join [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp] s
									on Custom1 = LTRIM(rtrim(m.banner)) 
									and suppliername =c.PartnerName 
									and Custom1 is not null
									and (c.StoreIdentifier is null or c.banner is null)
									
									
									
									update m set RequestStatus=5	
									--select*
									from MaintenanceRequests m
									inner join 	ZZtemp_MR_records_type1 z
									on m.MaintenanceRequestID=z.MaintenanceRequestID
									inner join DataTrue_EDI..costs	c 
									on c.dtmaintenancerequestid = m.MaintenanceRequestID
									and recordstatus in (25,35)
									and m.RequestStatus=2	
									
										
				 
		
			drop table ZZtemp_MR_records_type1			
			drop table ZZtemp_MRStores_records_type1
			drop table ZZtemp_storessetup_new_Type1_records 	
			drop table ZZtemp_new_Storesetup_records			
			drop table ZZtemp_MRStores_productprice_type1		   
            drop table zztemp_Productprice_new_Type1  
            drop table ZZtemp_MR_dup_items1
            
         

update p set ProductName = LTRIM(rtrim(Description))
--select *
from Products p
where isnumeric(ProductName) >0
and Description <> 'UNKNOWN'
return
GO
