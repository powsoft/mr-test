USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[zzDeleteAnyTime_prMRProcess_AllMRStoresRecords_Type2_New_NWSP_1110]    Script Date: 06/25/2015 18:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[zzDeleteAnyTime_prMRProcess_AllMRStoresRecords_Type2_New_NWSP_1110]
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


IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='zztemp_MR_NOT_IGNORE') 
                  drop table zztemp_MR_NOT_IGNORE

IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='zztemp_productprices_fix_ActiveLastDate2_NP') 
                  drop table zztemp_productprices_fix_ActiveLastDate2_NP
IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='in_MR_productprices2_NP') 
                  drop table in_MR_productprices2_NP
                  
 IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='in_MR_productprices2_NP') 
                  drop table in_MR_productprices2_NP
                  
IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='ZZtemp_MRStores_currentset_type2_NP') 
                  drop table ZZtemp_MRStores_currentset_type2_NP
                  
IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='zztemp_MRStores_prodprice_update') 
                  drop table zztemp_MRStores_prodprice_update
                  
 IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='ZZtemp_recover_Storesetup_records2 ') 
                  drop table ZZtemp_recover_Storesetup_records2 
                  
  IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='ZZtemp_storessetup_new_Type2_records_NP') 
                  drop table ZZtemp_storessetup_new_Type2_records_NP
                  
 IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='ZZtemp_Productprice_missing_Type2_NP') 
                  drop table ZZtemp_Productprice_missing_Type2_NP
                 
IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='zztemp_MR_productprice_type2_IGNORE') 
                  drop table zztemp_MR_productprice_type2_IGNORE
                                                     
IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='ZZtemp_MRStores_records_type2_NP') 
                  drop table ZZtemp_MRStores_records_type2_NP
                  
 IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='ZZtemp_MR_records_type2_NP') 
                  drop table ZZtemp_MR_records_type2_NP
                                   
IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='MR_productpricerecords_TYPE2_NP') 
                  drop table MR_productpricerecords_TYPE2_NP
                                   
IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='zztemp_MR_to5') 
                  drop table zztemp_MR_to5      
                  
 IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='ZZtemp_MR_dup_items_n2') 
                 drop table ZZtemp_MR_dup_items_n2   
                 
                 
IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='ZZtemp_ppr_delete') 
                  drop table ZZtemp_ppr_delete
 --IF EXISTS (SELECT 1 
 --                 FROM INFORMATION_SCHEMA.TABLES 
 --                 WHERE TABLE_TYPE='BASE TABLE' 
 --                 AND TABLE_NAME='temp_MR_records_type2_NP') 
 --                 drop table   temp_MR_records_type2_NP

/************** set duplicate records to requeststatus=999***************/
/************** for existing in MR***************/
--update m1 set RequestStatus=999
           select m1.*	
		    FROM [DataTrue_Main].[dbo].[MaintenanceRequests] m1
		    inner join MaintenanceRequestStores s1
		    on m1.MaintenanceRequestID=s1.MaintenanceRequestID
		    inner join MaintenanceRequests m
		    on m.productid=m1.productid
		    and m.SupplierID=m1.supplierid		  
		    and m.upc12=m1.upc12
		    and m.ChainID=m1.ChainID
		    and m.RequestTypeID=m1.RequestTypeID
		    and m.Cost=m1.cost
		    and cast(m.StartDateTime as date)=cast(m1.StartDateTime as date)
		    and cast(m.EndDateTime as date)=cast(m1.EndDateTime as date)
		    inner join MaintenanceRequestStores s
		    on m.MaintenanceRequestID=s.MaintenanceRequestID
		    and s.StoreID=s1.StoreID
		    inner join ProductPrices p
		    on m.productid=p.ProductID
		    and m.ChainID=p.chainid
		    and m.SupplierID=p.SupplierID
		    and s.StoreId=p.storeid
		    and m.Cost=p.UnitPrice
		    and cast(m.StartDateTime as date)=cast(ActiveStartDate as date)
		    and cast(m.EndDateTime as date)=cast(ActiveLastDate as date)
		    and m.RequestStatus =5
			and m1.RequestStatus =2
			and m1.RequestTypeID =2
			and m1.Cost is not null
			and isnull(m1.Cost,0) > 0			
			and m1.ProductId is not null
			and m1.bipad is not null
			and m1.datetimecreated>GETDATE()-45	
			
			/**************  fully duplicate records to requeststatus=999 in coming set ***************/
				
			select a.MaintenanceRequestID,FirstMRID  into zztemp_set_full_dupl
			--select *
			from
			(select m1.MaintenanceRequestID ,min(m1.MaintenanceRequestID) OVER (PARTITION BY StoreID,productid,chainid,upc12,supplierid,cost,startdatetime,enddatetime  ) as FirstMRID,
			StoreID,productid,chainid,upc12,supplierid,cost,startdatetime,EndDateTime
			from MaintenanceRequests m1
			inner join MaintenanceRequestStores s
			on s.MaintenanceRequestID=m1.MaintenanceRequestID
			and  m1.RequestStatus =2
			and  m1.RequestTypeID =2
			and  m1.Cost is not null
			and  isnull(m1.Cost,0) > 0			
			and  m1.ProductId is not null
			and  m1.bipad is not null
			and m1.datetimecreated>GETDATE()-45	)a	
			where  a.MaintenanceRequestID<>FirstMRID	
			
			update m set requeststatus=999
			from MaintenanceRequests m
			inner join zztemp_set_full_dupl z
			on m.MaintenanceRequestID=z.MaintenanceRequestID
			
			drop table zztemp_set_full_dupl
			
	/****************** find duplecate by upc12,SupplierID,chainid,banner,storeid**************************/		

select distinct m.MaintenanceRequestID into ZZtemp_MR_dup_items_n2
--select*
from MaintenanceRequests m,
MaintenanceRequestStores s,
(select count(*) cnt, upc12,chainid,banner,storeid,SupplierID			
			FROM [DataTrue_Main].[dbo].[MaintenanceRequests] mr
			inner join MaintenanceRequestStores s
			on mr.MaintenanceRequestID=s.MaintenanceRequestID
			where  RequestStatus in (2)
			and Approved = 1
			and RequestTypeID in (2) 
			and ProductId is not null
			and bipad is not null			
			and mr.datetimecreated>GETDATE()-45
			group by upc12,SupplierID,chainid,banner,storeid	
			having COUNT(*)>1 )a
			where m.upc12=a.upc12
			and m.banner=a.banner
			and m.chainid=a.chainid
			and m.SupplierID=a.SupplierID
			and s.storeid=a.storeid
			and m.MaintenanceRequestID=s.MaintenanceRequestID
			and m.RequestTypeID in (2) 
			and m.RequestStatus in (2)
			and m.bipad is not null
			
			if @@ROWCOUNT >0
			begin 

            insert @badrecords1 
	        select MaintenanceRequestID from  ZZtemp_MR_dup_items_n2
	
            set @errMessage1+='Conflict NWSP Records of type2 for the same item' +CHAR(13)+CHAR(10)
            end 

           if @errMessage1 <>''
		    begin
			set @Subject1 ='Conflict NWSP Records of type2 for the same item' 
			select @badrecids1 += cast(MaintenanceRequestID as varchar(13))+ ','
			from @badrecords1
			set @errMessage1+=CHAR(13)+CHAR(10)+'Record ID:'+CHAR(13)+CHAR(10)+@badrecids1
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com;charlie.clark@icucsolutions.com',
				@subject=@Subject1,@body=@errMessage1				
	
            end   
			
	update MaintenanceRequests set RequestStatus=18
	where MaintenanceRequestID in ( select MaintenanceRequestID from ZZtemp_MR_dup_items_n2)	
	
	
			      

		SELECT *
			
			into ZZtemp_MR_records_type2_NP
		--select *
			FROM MaintenanceRequests mr
			where 1 = 1
			and RequestStatus in (2)
			and RequestTypeID in (2) 
			and Cost is not null
			and [Cost] <> 0					
			and Bipad is not null
			and ProductId is not null	
			and datetimecreated>GETDATE()-45
			
			order by maintenancerequestid,Startdatetime, EndDateTime
			
			/*	find  Same MR item with the same cost exists in Productprices for different whithin Active Dates*/	
			
			
			
			select distinct m.MaintenanceRequestID
			into zztemp_MR_productprice_type2_IGNORE
			--select m.*
			from MaintenanceRequestS m
			inner join MaintenanceRequestStores s
			on m.MaintenanceRequestID=s.MaintenanceRequestID
			inner join ProductPrices p
			on p.SupplierID=m.supplierid
			and s.StoreID=p.StoreID
			and m.chainid=p.ChainID
			and m.productid=p.ProductID
			and cost=UnitPrice 
			and cast(ActiveStartDate as date)<=cast(m.startdatetime as date)
			and cast(ActiveLastDate as date)>=cast(EndDateTime as date)
			and RequestStatus in (2)
			and Approved = 1
			and RequestTypeID in (2) 
			and m.ProductId is not null
			and bipad is not null
			and m.datetimecreated>GETDATE()-45
			and ProductPriceTypeID=3
				
			--if @@ROWCOUNT >0
			--begin 

   --         insert @badrecords
	  --      select MaintenanceRequestID from zztemp_MR_productprice_type2_IGNORE
	
   --         set @errMessage+='Same item with the same cost exists in Productprices for different Active Start Date' +CHAR(13)+CHAR(10)
   --         end 

   --        if @errMessage <>''
		 --   begin
			--with c as (select ROW_NUMBER() over (partition by MaintenanceRequestID order by MaintenanceRequestID)dupe from @badrecords)
			--delete c where dupe>1
			--set @Subject ='Same item with the same cost exists in Productprices for different Active Start Date'
			--select @badrecids += cast(MaintenanceRequestID as varchar(13))+ ','
			--from @badrecords
			--set @errMessage+=CHAR(13)+CHAR(10)+'Record ID:'+CHAR(13)+CHAR(10)+@badrecids
			--exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com;charlie.clark@icucsolutions.com',
			--	@subject=@Subject,@body=@errMessage				
	
   --         end  	

    
	
	
	
    	/**************************************************** STEP2**************************************	
	        check if items from ZZtemp_MRrecords_type2 exist in STORESETUP  and insert  when are not found 	*/
			
			
		
			/*****************************************Step2 -1********************************
			 create records for each store found in MaintenanceRequestStores with maxMaintenanceRequestID
			 per storeid,productid,SupplierID,chainid to insert in STORSETUP*/
			--drop table ZZtemp_MRStores_records_type2_NP
		
			select max(m.MaintenanceRequestID) maxMRID,storeid,productid,SupplierID,chainid
			into ZZtemp_MRStores_records_type2_NP
			from ZZtemp_MR_records_type2_NP m
			inner join MaintenanceRequestStores s
			on m.MaintenanceRequestID=s.MaintenanceRequestID
			group by storeid,productid,SupplierID,chainid
			
				
			/****************************************   Step2-2  ********************************
			find storeid,chainid,SupplierID,productid which are not in Storestup and 
			create table of them ZZtemp_storesetup_missing_Type2*/
			
			/*********************************************************** STEP2**************************************	
	        *************insert missing records into SETUPSTORES from selected set of records for TYPE1*/		
			
				
			
			/*****************************update active last date to terminate supplier*********************************/
			update p set p.ActiveLastDate=m.StartDateTime-1
			from  ZZtemp_MRStores_records_type2_NP z
			inner join  ZZtemp_MR_records_type2_NP m			
			on m.MaintenanceRequestID=maxMRID
			inner join storesetup p
			on z.productid=p.productid
			and z.storeid=p.storeid
			and z.chainid=p.chainid
			and z.SupplierID<>p.SupplierID
			and p.ActiveLastDate>m.StartDateTime
			
				/***************to insert  supplier which were previously terminated*************************/
			select storeid,productid,SupplierID,chainid,StartDateTime into ZZtemp_recover_Storesetup_records2
				from
			(select z.storeid,z.productid,z.SupplierID,z.chainid,m.StartDateTime 		
			from  ZZtemp_MRStores_records_type2_NP z
			inner join  ZZtemp_MR_records_type2_NP m			
			on m.MaintenanceRequestID=maxMRID
			inner join storesetup p
			on z.productid=p.productid
			and z.storeid=p.storeid
			and z.chainid=p.chainid
			and z.SupplierID=p.SupplierID
			and p.ActiveLastDate<m.StartDateTime
			
			except
			select z.storeid,z.productid,z.SupplierID,z.chainid,m.StartDateTime 
			
			from  ZZtemp_MRStores_records_type2_NP z
			inner join  ZZtemp_MR_records_type2_NP m			
			on m.MaintenanceRequestID=maxMRID
			inner join storesetup p
			on z.productid=p.productid
			and z.storeid=p.storeid
			and z.chainid=p.chainid
			and z.SupplierID=p.SupplierID
			and p.ActiveLastDate>m.StartDateTime)a
			
			
	
			
			
			
			/* if new insert for old supplier***********/
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
					from ZZtemp_recover_Storesetup_records2 		
			
			
			
		
			/********************************************** Step2-2*******************************************************************
			*******************************find storeid,chainid,SupplierID,productid which are not in Storestup 
			********************************and create table of them ZZtemp_stores_setup_missing_Type1*********************************************/
			
			SELECT * INTO    ZZtemp_storessetup_new_Type2_records_NP 
			from   
			(select  distinct storeid,chainid,SupplierID,productid	from ZZtemp_MRStores_records_type2_NP                                    										
			EXCEPT			  
			select distinct s.storeid,s.chainid,SupplierID,s.ProductID from storesetup s with(NOLOCK)
			 ) a
			
				
			
			/*if records found then inset them in Storesetup (temp_storesetup_42490_74796)*/
				
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
					from ZZtemp_storessetup_new_Type2_records_NP  p
					inner join ZZtemp_MRStores_records_type2_NP  t
					on t.productid=p.productid
					and t.chainid=p.chainid
					and t.supplierid=p.supplierid
					and t.StoreID=p.storeid
					inner join MaintenanceRequests m
					on maxMRID=m.MaintenanceRequestid
					
						
						
			/****************************************  STEP3      **************************
			insert cost records into PRODUCTPRICES from selected set of records from ZZtemp_MRrecords_type2
			***********************Condition One*********************/		
			--update productprices for different cost but the same ActiveDates
			select m.MaintenanceRequestID,s.storeid,m.productid,m.SupplierID,m.chainid,cost,startdatetime,ProductPriceID,EndDateTime
			into zztemp_MRStores_prodprice_update
			--select m.MaintenanceRequestID,s.storeid,m.productid,m.SupplierID,m.chainid,cost,startdatetime,ProductPriceID
			from ZZtemp_MR_records_type2_NP m
			inner join MaintenanceRequestStores s
			on m.MaintenanceRequestID=s.MaintenanceRequestID
			inner join ProductPrices p
			on p.SupplierID=m.supplierid
			and s.StoreID=p.StoreID
			and m.chainid=p.ChainID
			and m.productid=p.ProductID
			and (cost<>UnitPrice or p.supplierid<>m.supplierid )
			and cast(ActiveStartDate as date)>=cast(startdatetime as date)
			and cast(ActiveLastDate as date)<=cast(EndDateTime as date)
			and ProductPriceTypeID=3
			
				INSERT INTO [DataTrue_Main].[dbo].[ProductPricesDeleted]
									   ([ProductPriceID]
									   ,[ProductPriceTypeID]
									   ,[ProductID]
									   ,[ChainID]
									   ,[StoreID]
									   ,[BrandID]
									   ,[SupplierID]
									   ,[UnitPrice]
									   ,[UnitRetail]
									   ,[PricePriority]
									   ,[ActiveStartDate]
									   ,[ActiveLastDate]
									   ,[PriceReportedToRetailerDate]
									   ,[DateTimeCreated]
									   ,[LastUpdateUserID]
									   ,[DateTimeLastUpdate]
									   ,[BaseCost]
									   ,[Allowance]
									   ,[NewActiveStartDateNeeded]
									   ,[NewActiveLastDateNeeded]
									   ,[OldStartDate]
									   ,[OldEndDate]
									   ,[TradingPartnerPromotionIdentifier])

							SELECT p.ProductPriceID
							  ,ProductPriceTypeID
								  ,p.ProductID
								  ,p.ChainID
								  ,p.StoreID
								  ,[BrandID]
								  ,p.SupplierID
								  ,[UnitPrice]
								  ,[UnitRetail]
								  ,[PricePriority]
								  ,[ActiveStartDate]
								  ,[ActiveLastDate]
								  ,[PriceReportedToRetailerDate]
								  ,[DateTimeCreated]
								  ,[LastUpdateUserID]
								  ,[DateTimeLastUpdate]
								  ,[BaseCost]
								  ,[Allowance]
								  ,[NewActiveStartDateNeeded]
								  ,[NewActiveLastDateNeeded]
								  ,[OldStartDate]
								  ,[OldEndDate]
								  ,[TradingPartnerPromotionIdentifier]
								--  select*
							  FROM ProductPrices p
							 join zztemp_MRStores_prodprice_update z
				             on  p.ProductPriceID = z.productpriceid
				           
			
			update p set UnitPrice=cost,p.SupplierID=z.supplierid,p.ActivestartDate=z.StartDateTime,p.ActiveLastDate=z.EndDateTime
			from ProductPrices p
			inner join zztemp_MRStores_prodprice_update z
			on p.ProductPriceID=z.ProductPriceID
			
			
			/******************************************    STEP3-3-1	  ***********************************
			find  MaintenanceRequestID for storeid,productid,SupplierID,chainid
			 from selected set of records for TYPE2
			and insert them in table temp_MRStores_productprice_type1*/	
						
					
			select max(m.MaintenanceRequestID) maxMRID,storeid,productid,chainid,supplierid
			into ZZtemp_MRStores_currentset_type2_NP
			--select max(m.MaintenanceRequestID) maxMRID,storeid,productid,chainid
			from ZZtemp_MR_records_type2_NP m
			inner join MaintenanceRequestStores s
			on m.MaintenanceRequestID=s.MaintenanceRequestID
			and m.MaintenanceRequestID 	not in (select MaintenanceRequestID from zztemp_MR_productprice_type2_IGNORE)
			and m.MaintenanceRequestID 	not in (select MaintenanceRequestID from zztemp_MRStores_prodprice_update) 
	 
			group by storeid,productid,chainid,supplierid
			
			/****************************************    STEP3-1	*****************************
			find storeid,productid,SupplierID,chainide from selected set of records for TYPE2
			and exist in productprices table*/	
			
			
			
			/* Step3-3
			find storeid,chainid,SupplierID,productid which are not in Productprices and 
			create table of them temp_Productprice_missing_Type1 */
			
			SELECT * INTO    ZZtemp_Productprice_missing_Type2_NP  
			from   
			(select distinct s.storeid,m.SupplierID,m.chainid,m.productid,m.cost,cast(m.startdatetime as date) startdatetime,cast(m.EndDateTime as date)EndDateTime	
			 from ZZtemp_MR_records_type2_np m
			inner join MaintenanceRequestStores s
			on m.MaintenanceRequestID=s.MaintenanceRequestID   
            and m.MaintenanceRequestID 	not in (select MaintenanceRequestID from zztemp_MR_productprice_type2_IGNORE)
			and m.MaintenanceRequestID 	not in (select MaintenanceRequestID from zztemp_MRStores_prodprice_update) 
			EXCEPT			  
			 select distinct s.storeid,SupplierID,s.chainid,s.ProductID,UnitPrice,cast(activestartdate as date)	,cast(ActiveLastDate as date)				
			 from Productprices s with(NOLOCK)	where  ProductPriceTypeID=3  ) a
				
			
		
				
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
				   ,LastUpdateUserID
				   ,DateTimeCreated)
				select 
				   3
				   ,p.chainid 
				   ,p.StoreID 
				   ,p.productid 
				   ,p.supplierid
				   ,p.cost
				   ,m.SuggestedRetail
				   ,0 
				   ,p.StartDateTime 
				   ,m.EndDateTime
				   ,0
				   , GETDATE()
				  -- select p.* --,m.StartDateTime ,minMRID
			        from ZZtemp_MR_records_type2_NP m	
			        inner join ZZtemp_MRStores_currentset_type2_NP z
			        on m.MaintenanceRequestID=z.maxMRID		       			                
	                inner join  ZZtemp_Productprice_missing_Type2_NP   p
			        on z.chainid=p.chainid			     
			        and z.supplierid=p.supplierid			        
			        and z.productid=p.productid
			        and z.StoreId=p.storeid
					and m.startdatetime	=p.startdatetime
			        and m.cost=p.cost 	
			        
			        				
				update c set c.CostPlusPercentOfRetail = UnitPrice + (UnitRetail * s1.ServiceFeeFactorValue)
				from datatrue_edi.dbo.productprices c --with (nolock)
				inner join datatrue_main.dbo.servicefees s1  with (nolock)
				on c.chainid = s1.chainid
				where 1 = 1
				and s1.ServiceFeeTypeID = 4
				and isnull(c.CostPlusPercentOfRetail, 0) <> UnitPrice + (UnitRetail * s1.ServiceFeeFactorValue)

				update c set c.CostPlusPercentOfRetail = UnitPrice + (UnitRetail * s1.ServiceFeeFactorValue)
				from productprices c --with (nolock)
				inner join servicefees s1  with (nolock)
				on c.chainid = s1.chainid
				where 1 = 1
				and s1.ServiceFeeTypeID = 4
				and isnull(c.CostPlusPercentOfRetail, 0) <> UnitPrice + (UnitRetail * s1.ServiceFeeFactorValue)		
				/* **************************STEP4*********************************
				update DATATRUE_EDI..COSTS for MR EDI records*********************
				select* from ProductPrices where cast(storeid as varchar(8))+'R'+cast(productid as varchar(8))+'R'+cast(chainid as varchar(8))
				in(				
				select distinct cast(storeid as varchar(8))+'R'+cast(productid as varchar(8))+'R'+cast(chainid as varchar(8))
				from ZZtemp_MRrecords_type1 m
			    inner join MaintenanceRequestStores s
			    on m.MaintenanceRequestID=s.MaintenanceRequestID   ) 
			    */
			   
			    
			    
			    select  MAX(mr.MaintenanceRequestID)MaintenanceRequestID, 
			    productpriceid ,p.productid,p.storeid,p.supplierid,p.chainid,p.UnitPrice,p.ActiveStartDate 
                into MR_productpricerecords_TYPE2_NP 
			    from ProductPrices p
			    inner join MaintenanceRequests mr
			    on p.supplierid=mr.supplierid
				and p.ProductID=mr.productid
				and p.chainid=mr.ChainID
				and p.ActiveStartDate=mr.StartDateTime
				and p.UnitPrice =mr.cost			
				and  productpricetypeid=3 
				inner join MaintenanceRequestStores s
			    on mr.MaintenanceRequestID=s.MaintenanceRequestID 
				and p.StoreID= s.storeid				
				inner join  ZZtemp_MRStores_records_type2_NP m
				on m.productid=p.ProductID
				and m.chainid=p.chainid
				and m.StoreID=p.storeid		
				and mr.RequestStatus  in (2,5)
	           ---- and mr.SupplierID  in (select SupplierID from SupplierS s where s.PDITradingPartner=0) 
	            and mr.RequestTypeID in (1,2)
	           	group by  p.productid,productpriceid ,p.storeid,p.supplierid,p.chainid,p.UnitPrice,p.ActiveStartDate 


				/* addiding productpriceid,activelastdate to  each row of in_MR_productprices table*/
               --if @@ROWCOUNT>0
              --drop Table in_MR_productprices

				select distinct MaintenanceRequestID,p.productpriceid, p.productid,p.storeid,p.supplierid,p.chainid,p.UnitPrice,p.ActiveStartDate ,activelastdate 
				into in_MR_productprices2_NP
				from ProductPrices p with (NOLOCK)
				inner join MR_productpricerecords_TYPE2_NP m
				on  p.productpriceid=m.productpriceid
				
				select* from in_MR_productprices2_NP
				
				
				select p2.MaintenanceRequestID newMRID,p1.MaintenanceRequestID oldMRID,p2.productpriceid newproductpriceid,p1.productpriceid oldproductpriceid,
				p1.ActiveStartDate oldActiveStartDate,p2.ActiveStartDate newActiveStartDate,p1.activelastdate practivelastdate,
				p2.activelastdate newactivelastdate,p1.supplierid oldsupplier,p2.supplierid newsupplier,p2.ChainID,p2.StoreID,p2.ProductID
				into zztemp_productprices_fix_ActiveLastDate2_NP
				from in_MR_productprices2_NP p1 with (nolock)
				inner join in_MR_productprices2_NP p2 with (nolock)
				on p1.productid = p2.productid
				and p1.chainid=p2.chainid
				and p1.storeid = p2.storeid
				and ((p2.MaintenanceRequestID>p1.MaintenanceRequestID ) and p1.ActiveLastDate >= p2.ActiveStartDate )				
				order by p2.storeid
				
				if @@ROWCOUNT>0
			/*************Condition Two**************/
				begin
				
								update p set p.activelastdate= t.newActiveStartDate-1,LastUpdateUserID=76834,--@MyID
								DateTimeLastUpdate=GETDATE()
								--select t.*
								from ProductPrices p 
								inner join zztemp_productprices_fix_ActiveLastDate2_NP t
								on  p.ProductPriceID = t.oldproductpriceid
								and p.ActiveStartDate< t.newActiveStartDate
								and p.ActiveLastDate<=t.newactivelastdate
								
			/*************Condition Tree**************/
								update p set p.ActiveStartDate= t.newactivelastdate+1,LastUpdateUserID=76834,--@MyID
								DateTimeLastUpdate=GETDATE()
								--select t.*
								from ProductPrices p 
								inner join zztemp_productprices_fix_ActiveLastDate2_NP t
								on  p.ProductPriceID = t.oldproductpriceid
								and p.activelastdate>= t.newActiveStartDate
								and p.ActiveLastDate>t.newactivelastdate
								
			/*************Condition FOUR**************/	
				
								select t.newActiveLastDate,p.* into ZZtemp_ppr_delete
								from ProductPrices p 
								inner join zztemp_productprices_fix_ActiveLastDate2_NP t
								on  p.ProductPriceID = t.oldproductpriceid
								and p.activeStartdate< t.newActiveStartDate
								and p.ActiveLastDate>t.newactivelastdate
					            
							    update p set p.activelastdate= t.newActiveStartDate-1,LastUpdateUserID=76834,--@MyID
								DateTimeLastUpdate=GETDATE()
								--select t.*
								from ProductPrices p 
								inner join zztemp_productprices_fix_ActiveLastDate2_NP t
								on  p.ProductPriceID = t.oldproductpriceid
								and p.ActiveStartDate< t.newActiveStartDate
								and p.ActiveLastDate<=t.newactivelastdate
							
				            INSERT INTO [DataTrue_Main].[dbo].[ProductPrices]
									   ([ProductPriceTypeID]
									   ,[ProductID]
									   ,[ChainID]
									   ,[StoreID]
									   ,[BrandID]
									   ,[SupplierID]
									   ,[UnitPrice]
									   ,[UnitRetail]
									   ,[PricePriority]
									   ,[ActiveStartDate]
									   ,[ActiveLastDate]
									   ,[PriceReportedToRetailerDate]
									   ,[DateTimeCreated]
									   --,[LastUpdateUserID]
									   ,[BaseCost]
									   ,[Allowance]
									   ,[NewActiveStartDateNeeded]
									   ,[NewActiveLastDateNeeded]
									   ,[OldStartDate]
									   ,[OldEndDate])
							SELECT p.ProductPriceTypeID
								  ,p.ProductID
								  ,p.ChainID
								  ,p.StoreID
								  ,p.BrandID
								  ,p.SupplierID
								  ,p.UnitPrice
								  ,p.UnitRetail
								  ,p.PricePriority
								  ,newActiveLastDate+1
								  ,p.ActiveLastDate
								  ,p.PriceReportedToRetailerDate
								  ,GETDATE()
								 -- ,@MyID
								  ,p.BaseCost
								  ,p.Allowance
								  ,p.NewActiveStartDateNeeded
								  ,p.NewActiveLastDateNeeded
								  ,p.ActiveStartDate
								  ,p.ActiveLastDate
							  FROM ProductPrices p
							  inner join ZZtemp_ppr_delete	z
							 on z.productpriceid=p.productpriceid
							  		
						
					
				       end
	
				       
				       
				                   /*********setting ActiveLastDate to '2099-12-31 00:00:00.000' for the most recent records **********/
 
				--update ProductPrices set ActiveLastDate='2099-12-31',LastUpdateUserID=76835,
				--DateTimeLastUpdate=GETDATE()
				--where productpriceid in(select productpriceid
				----select productpriceid ,LatestMRID, ActiveStartDate ,activelastdate,StoreID,productid,chainid
				--from (select p.productpriceid ,newMRID,MAX( newMRID) OVER (PARTITION BY p.StoreID,p.productid,p.chainid  ) as LatestMRID,
				--p.StoreID,p.productid,p.chainid ,p.ActiveStartDate ,p.activelastdate
				--from ProductPrices p  
				--inner join ZZtemp_productprices_fix_ActiveLastDate2_NP t
				--on  p.ProductPriceID = t.newproductpriceid and p.ProductPriceTypeID =3     
				--)a  where newMRID=LatestMRID  and   ActiveLastDate<'2099-12-31 00:00:00.000'				
				--)
				
				select  maxMR,storeid,productid,chainid,supplierid,MaintenanceRequestID,StartDateTime 
				into ZZtemp_MRS_set_no_dup2
				from 
				(select MAX(m.MaintenanceRequestId)  OVER (PARTITION BY storeid,productid,chainid) as maxMR,storeid,productid,chainid,supplierid,m.MaintenanceRequestID,StartDateTime 
				from zztemp_MR_records_type2_NP m
				inner join MaintenanceRequestStores s
				on m.MaintenanceRequestID=s.MaintenanceRequestID
				)a
				where maxMR=MaintenanceRequestID			
				
				
				
				select  p.ProductPriceID,p.storeid,p.productid,p.chainid,p.supplierid,p.activestartdate,p.ActiveLastDate ,z.startdatetime,p.ProductPriceTypeID  
into zztemp_PRODUCTPRICE_fix2
from 
			ProductPrices p
			inner join 
			(
			select  p.storeid,p.productid,p.chainid,p.supplierid,unitprice,cast(activestartdate as date) activestartdate
			from ZZtemp_MRS_set_no_dup2 z
			inner join productprices p
			on  p.storeid=z.StoreID
			and p.productid=z.productid
			and ProductPriceTypeID=3
			except
			select  distinct s.storeid,m.productid,m.chainid,m.supplierid,m.cost,cast(m.startdatetime as date)
			from MaintenanceRequests m
			inner join MaintenanceRequestStores s
			on s.MaintenanceRequestID=m.MaintenanceRequestID
			inner join ZZtemp_MRS_set_no_dup2 z
			on  s.storeid=z.StoreID
			and m.productid=z.productid
			and m.ChainID=z.chainid
			and RequestTypeID in (1,2,15))a
		
		on   a.supplierid=p.supplierid
			and a.storeid=p.StoreID
			and a.productid=p.productid
			and a.ChainID=p.chainid
			and cast(a.activestartdate as date)=cast(p.ActiveStartDate as date)
			and a.UnitPrice=p.UnitPrice
			inner join ZZtemp_MRS_set_no_dup2 z
			on z.storeid=p.StoreID
			--and z.supplierid=p.supplierid
			and z.productid=p.productid
			and z.ChainID=p.chainid
			and p.ProductPricetypeID=3
			and cast(p.ActiveLastDate as date)>cast((z.StartDateTime-1) as date)
			order by p.storeid,p.productid  
			
			
			update p set p.ActiveLastDate=z.StartDateTime-1		
			--select p.ActiveStartDate,p.ActiveLastDate,z.StartDateTime,p.ProductPricetypeID,*			
			from productprices p
			inner join zztemp_PRODUCTPRICE_fix2 z
			on z.productpriceid=p.productpriceid
			
			drop table ZZtemp_MRS_set_no_dup2
            drop table zztemp_PRODUCTPRICE_fix2
				/**********find m.MaintenanceRequestID for NSWPR upc records which were not sent before**/
				select  m.MaintenanceRequestID into zztemp_MR_to5
				from MaintenanceRequests m,			
				MaintenanceRequestStores s,
				(select upc12,cost,chainid,ProductId,SupplierID,StoreId,StartDateTime,EndDateTime 
				from MaintenanceRequests m
				inner join MaintenanceRequestStores s
				on m.MaintenanceRequestID=s.MaintenanceRequestID
				where m.MaintenanceRequestID in (select MaintenanceRequestID 
				from zztemp_MR_productprice_type2_IGNORE)
				except
				select upc12,cost,chainid,ProductId,SupplierID,StoreId,StartDateTime,EndDateTime  
				from MaintenanceRequests m
				inner join MaintenanceRequestStores s
				on m.MaintenanceRequestID=s.MaintenanceRequestID
				where Bipad is not null and RequestStatus=5
				and RequestTypeID in (1,2))a
				where a.upc12=m.upc12
				and a.chainid=m.chainid
				and a.SupplierID=m.supplierid
				and a.StoreID=s.storeid
				and a.Cost=m.cost
				and m.MaintenanceRequestID=s.MaintenanceRequestID

           if @@ROWCOUNT >0
			
			delete from zztemp_MR_productprice_type2_IGNORE  where MaintenanceRequestID in
			 (select MaintenanceRequestID from  zztemp_MR_to5)
					
					   update c
					   set c.PartnerName=s.suppliername						
					   from  datatrue_edi.dbo.Costs c
					   inner join ZZtemp_MR_records_type2_NP m
					   on c.RecordID = m.datatrue_edi_costs_recordid
					   inner join Suppliers  s 
					   on s.SupplierID = m.supplierid
			           and  c.PartnerName is null
			           
			           update c
					   set c.StoreIdentifier=s.CorporateIdentifier		
					   from  datatrue_edi.dbo.Costs c
					   inner join ZZtemp_MR_records_type2_NP m
					   on c.RecordID = m.datatrue_edi_costs_recordid
					   inner join [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp] s
					   on Custom1 = LTRIM(rtrim(m.banner)) 
					   and suppliername =c.PartnerName 
					   and Custom1 is not null
			           and c.StoreIdentifier is null 
							
				    	update c
						set c.RecordStatus = case when  isnull(m.SkipPopulating879_889Records,0) =1 and  m.pdiparticipant=0 then 20 
						                          when  isnull(m.SkipPopulating879_889Records,0) <>1 and m.pdiparticipant=0 then 10
						                          when   isnull(m.SkipPopulating879_889Records,0) =1 and m.pdiparticipant=1 then 35
						                          when  isnull(m.SkipPopulating879_889Records,0) <>1 and m.pdiparticipant=1 then 25
						                          end 
						,c.dtmaintenancerequestid = m.maintenancerequestid 
						,c.ProductName = Case when upper(m.dtproductdescription) = 'UNKNOWN' then ProductName else m.dtproductdescription end
						,c.ProductNameReceived = ProductName
						,c.deleted = case when isnull(m.MarkDeleted, 0) = 1 then 1 else null end
						,c.SentToRetailer = case when isnull(m.MarkDeleted, 0) = 1 then 0 else SentToRetailer end
						,c.StoreName=ltrim(rtrim(m.Banner))
						,c.PricingMarket= case when c.dtstorecontexttypeid=1 then '002'
						                       when c.dtstorecontexttypeid=2 then '006'
						                       when c.dtstorecontexttypeid=3 then m.costzoneid end
						,c.dtproductid=m.productid
						,c.dtbrandid=m.brandid
						,c.Recordsource='EDI'
						,c.ProductIdentifier = m.upc12
						,SubmitDateTime = m.SubmitDateTime
						from  datatrue_edi.dbo.Costs c
						inner join ZZtemp_MR_records_type2_NP m
						on c.RecordID = m.datatrue_edi_costs_recordid
						and  m.MaintenanceRequestID not in 
						(select MaintenanceRequestID from zztemp_MR_productprice_type2_IGNORE)
						
				update m set RequestStatus=18	
				--select recordstatus,*
				from MaintenanceRequests m
				inner join 	ZZtemp_MR_records_type2_NP z
				on m.MaintenanceRequestID=z.MaintenanceRequestID				
				and  m.MaintenanceRequestID  in (select MaintenanceRequestID from zztemp_MR_productprice_type2_IGNORE)		
						
			
				update m set RequestStatus=5	
				--select recordstatus,*
				from MaintenanceRequests m
				inner join 	ZZtemp_MR_records_type2_NP z
				on m.MaintenanceRequestID=z.MaintenanceRequestID
				inner join DataTrue_EDI..costs	c 
				on m.datatrue_edi_costs_recordid=c.RecordID
				and recordstatus>1	
				and  m.MaintenanceRequestID not in (select MaintenanceRequestID from zztemp_MR_productprice_type2_IGNORE)
			
										
				/* **************************STEP4*********************************
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
										   'B'
										   --,edibanner
										   ,t.StoreIdentifier
										   ,banner
										   ,'002'
										   ,allstores
										   ,cost
										   ,suggestedretail
										   ,upc
										   ,upc12
										   ,case when upper(dtproductdescription) = 'UNKNOWN' then itemdescription else dtproductdescription end
										   ,startdatetime
										   ,enddatetime
										   , case when  t.pdiparticipant=0 then 10
						                          when t.pdiparticipant=1 then 25
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
										from ZZtemp_MR_records_type2_NP t
										inner join MaintenanceRequestStores m
										on t.MaintenanceRequestID=m.MaintenanceRequestID
										inner join stores s
										on m.Storeid = s.storeid
										where datatrue_edi_costs_recordid is null
										and  t.MaintenanceRequestID not in (select MaintenanceRequestID from zztemp_MR_productprice_type2_IGNORE)
								
								
								  update c
											   
									set PartnerIdentifier = UniqueEDIName
									from datatrue_edi.dbo.Costs c
									join Suppliers s on SupplierID=ltrim(rtrim(dtsupplierid))
									and PartnerIdentifier is null and recordstatus = 1

									
									
									update c
									set c.PartnerName=s.suppliername	,c.SupplierIdentifier=s.SupplierIdentifier
									--select,*					
									from  datatrue_edi.dbo.Costs c
									inner join ZZtemp_MR_records_type2_NP m
									on c.dtmaintenancerequestid = m.MaintenanceRequestID
									inner join Suppliers  s 
									on s.SupplierID = m.supplierid
									and  c.PartnerName is null

									update c
									set c.StoreIdentifier=s.CorporateIdentifier,c.banner = s.banner
									--select c.*			
									from  datatrue_edi.dbo.Costs c
									inner join ZZtemp_MR_records_type2_NP m
									on c.dtmaintenancerequestid = m.MaintenanceRequestID
									inner join [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp] s
									on Custom1 = LTRIM(rtrim(m.banner)) 
									and suppliername =c.PartnerName 
									and Custom1 is not null
									and (c.StoreIdentifier is null or c.banner is null)
									
									
									
									update m set RequestStatus=5	
									--select*
									from MaintenanceRequests m
									inner join 	ZZtemp_MR_records_type2_NP z
									on m.MaintenanceRequestID=z.MaintenanceRequestID
									inner join DataTrue_EDI..costs	c 
									on c.dtmaintenancerequestid = m.MaintenanceRequestID
									and  m.MaintenanceRequestID not in (select MaintenanceRequestID from zztemp_MR_productprice_type2_IGNORE)
									and recordstatus>1	
									and m.RequestStatus=2	
									
									
									update c set c.Cost = c.Cost + (SuggRetail * s2.ServiceFeeFactorValue)
									from datatrue_edi.dbo.costs c with (nolock)
									inner join ZZtemp_MR_records_type2_NP z
									on c.dtmaintenancerequestid = z.MaintenanceRequestID
									inner join datatrue_main.dbo.servicefees s1
									on c.dtchainid = s1.chainid
									inner join datatrue_main.dbo.servicefees s2
									on s1.chainid = s2.chainid
									inner join productidentifiers p
									on dtproductid =p.productid
									where productidentifiertypeid = 8
									and s1.ServiceFeeTypeID = 9
									and s2.ServiceFeeTypeID = 4
									and isnull(c.Cost, 0) <> c.Cost + (SuggRetail * s2.ServiceFeeFactorValue)
									
					
	
			
				
		
			drop table zztemp_productprices_fix_ActiveLastDate2_NP
			drop table zztemp_MR_to5
			drop table in_MR_productprices2_NP	
			drop table ZZtemp_MRStores_records_type2_NP
            drop table ZZtemp_MR_records_type2_NP	
            drop table MR_productpricerecords_TYPE2_NP          		
			drop table ZZtemp_MRStores_currentset_type2_NP  
		    --drop table zztemp_MRStores_prodprice_update	
		    drop table ZZtemp_recover_Storesetup_records2 		    
			drop table ZZtemp_storessetup_new_Type2_records_NP			
            drop table ZZtemp_Productprice_missing_Type2_NP
            drop table ZZtemp_MR_dup_items_n2
            drop table zztemp_MR_productprice_type2_IGNORE
            drop table zztemp_MRStores_prodprice_update
           
            
             IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='ZZtemp_ppr_delete') 
                  drop table ZZtemp_ppr_delete
           
         
update p set ProductName = LTRIM(rtrim(Description))
--select *
from Products p
where isnumeric(ProductName) >0
and Description <> 'UNKNOWN'
return
GO
