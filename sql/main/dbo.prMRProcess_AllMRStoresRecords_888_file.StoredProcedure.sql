USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMRProcess_AllMRStoresRecords_888_file]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create  procedure [dbo].[prMRProcess_AllMRStoresRecords_888_file]
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




--SELECT *

--into ZZtemp_MR_find_879
--
select m1.productid,m2.productid,m1.SupplierID,m2.supplierid,m1.ChainID,m2.chainid
,m1.banner,m2.banner,m1.StartDateTime,m2.StartDateTime
FROM MaintenanceRequests m1
inner join MaintenanceRequests m2
on m1.productid=m2.productid
and m1.SupplierID=m2.supplierid
and m1.ChainID=m2.chainid
--and m1.banner=m2.banner
--and cast(m1.StartDateTime as date)=CAST(m2.StartDateTime as date)
where isnull(m1.Filetype,1)=888
and isnull(m2.Filetype,1)=879

--and m1.Bipad is  null
and m1.ProductId is not null
and m2.RequestStatus=5
and m1.requeststatus<>5	
and m1.PDIParticipant=0


select m1.productid,m2.productid,m1.SupplierID,m2.supplierid,m1.ChainID,m2.chainid
,m1.banner,m2.banner,m1.StartDateTime,m2.StartDateTime,m1.RequestStatus,m1.RequestTypeID,m2.RequestTypeID,m1.RequestSource
FROM MaintenanceRequests m1
inner join MaintenanceRequests m2
on m1.VIN=m2.vin
and m1.SupplierID=m2.supplierid
and m1.ChainID=m2.chainid

--and m1.banner=m2.banner
--and cast(m1.StartDateTime as date)=CAST(m2.StartDateTime as date)
where isnull(m1.Filetype,1)=888
and isnull(m2.Filetype,1)=879

and m1.Bipad is  null
and m1.ProductId is not null
and m2.RequestStatus=5
and m1.requeststatus<>5	
and m1.PDIParticipant=1



select distinct c.filename,c.filetype ,cast(c.datetimecreated as date),c.Recordsource,cast(m1.StartDateTime as date),CAST(m2.StartDateTime as date), c1.filename,c1.filetype ,cast(c1.datetimecreated as date),c1.Recordsource
FROM MaintenanceRequests m1
inner join MaintenanceRequests m2
on m1.VIN=m2.vin
and m1.SupplierID=m2.supplierid
and m1.ChainID=m2.chainid
inner join DataTrue_EDI..costs c
on m1.datatrue_edi_costs_recordid=c.RecordID
inner join DataTrue_EDI..costs c1
on m2.datatrue_edi_costs_recordid=c1.recordid
--and cast(m1.StartDateTime as date)=CAST(m2.StartDateTime as date)
where isnull(m1.Filetype,1)=888
and isnull(m2.Filetype,1)=879
and m1.Bipad is  null
and m1.ProductId is not null
and m2.RequestStatus=5
and m1.requeststatus<>5	
and m1.PDIParticipant=1







--   update c
--   set c.PartnerName=s.suppliername						
--   from  datatrue_edi.dbo.Costs c
--   inner join ZZtemp_MR_records_type2_NP m
--   on c.RecordID = m.datatrue_edi_costs_recordid
--   inner join Suppliers  s 
--   on s.SupplierID = m.supplierid
--   and  c.PartnerName is null
   
--   update c
--   set c.StoreIdentifier=s.CorporateIdentifier		
--   from  datatrue_edi.dbo.Costs c
--   inner join ZZtemp_MR_records_type2_NP m
--   on c.RecordID = m.datatrue_edi_costs_recordid
--   inner join [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp] s
--   on Custom1 = LTRIM(rtrim(m.banner)) 
--   and suppliername =c.PartnerName 
--   and Custom1 is not null
--   and c.StoreIdentifier is null 
   
--   update c
--	set c.RecordStatus = case when  isnull(m.SkipPopulating879_889Records,0) =1 and  m.pdiparticipant=0 then 20 
--	                          end 
--	,c.dtmaintenancerequestid = m.maintenancerequestid 
--	,c.ProductName = Case when upper(m.dtproductdescription) = 'UNKNOWN' then ProductName else m.dtproductdescription end
--	,c.ProductNameReceived = ProductName
--	,c.deleted = case when isnull(m.MarkDeleted, 0) = 1 then 1 else null end
--	,c.SentToRetailer = case when isnull(m.MarkDeleted, 0) = 1 then 0 else SentToRetailer end
--	,c.StoreName=ltrim(rtrim(m.Banner))
--	,c.PricingMarket= case when c.dtstorecontexttypeid=1 then '002'
--	                       when c.dtstorecontexttypeid=2 then '006'
--	                       when c.dtstorecontexttypeid=3 then m.costzoneid end
--	,c.dtproductid=m.productid
--	,c.dtbrandid=m.brandid
--	,c.Recordsource='EDI'
--	,c.ProductIdentifier = m.upc12
--	,SubmitDateTime = m.SubmitDateTime
--	from  datatrue_edi.dbo.Costs c
--	inner join ZZtemp_MR_records_type2_NP m
--	on c.RecordID = m.datatrue_edi_costs_recordid
--	and (dtBanner='Shop N Save Warehouse Foods Inc' and dtsupplierid = 41465 )
--	and (dtstoreid is  null or dtstoreid='')
--	and  m.MaintenanceRequestID not in 
--	(select MaintenanceRequestID from zztemp_MR_productprice_type2_IGNORE)

		
--	update c
--	set c.RecordStatus = case when  isnull(m.SkipPopulating879_889Records,0) =1 and  m.pdiparticipant=0 then 20 
--	                          when  isnull(m.SkipPopulating879_889Records,0) <>1 and m.pdiparticipant=0 then 10
--	                          when   isnull(m.SkipPopulating879_889Records,0) =1 and m.pdiparticipant=1 then 35
--	                          when  isnull(m.SkipPopulating879_889Records,0) <>1 and m.pdiparticipant=1 then 25
--	                          end 
--	,c.dtmaintenancerequestid = m.maintenancerequestid 
--	,c.ProductName = Case when upper(m.dtproductdescription) = 'UNKNOWN' then ProductName else m.dtproductdescription end
--	,c.ProductNameReceived = ProductName
--	,c.deleted = case when isnull(m.MarkDeleted, 0) = 1 then 1 else null end
--	,c.SentToRetailer = case when isnull(m.MarkDeleted, 0) = 1 then 0 else SentToRetailer end
--	,c.StoreName=ltrim(rtrim(m.Banner))
--	,c.PricingMarket= case when c.dtstorecontexttypeid=1 then '002'
--	                       when c.dtstorecontexttypeid=2 then '006'
--	                       when c.dtstorecontexttypeid=3 then m.costzoneid end
--	,c.dtproductid=m.productid
--	,c.dtbrandid=m.brandid
--	,c.Recordsource='EDI'
--	,c.ProductIdentifier = m.upc12
--	,SubmitDateTime = m.SubmitDateTime
--	from  datatrue_edi.dbo.Costs c
--	inner join ZZtemp_MR_records_type2_NP m
--	on c.RecordID = m.datatrue_edi_costs_recordid
--	and  m.MaintenanceRequestID not in 
--	(select MaintenanceRequestID from zztemp_MR_productprice_type2_IGNORE)
--	and RecordStatus=1

--update m set RequestStatus=5	
----select recordstatus,*
--from MaintenanceRequests m
--inner join 	ZZtemp_MR_records_type2_NP z
--on m.MaintenanceRequestID=z.MaintenanceRequestID
--inner join DataTrue_EDI..costs	c 
--on m.datatrue_edi_costs_recordid=c.RecordID
--and recordstatus>1	
--and  m.MaintenanceRequestID not in (select MaintenanceRequestID from zztemp_MR_productprice_type2_IGNORE)

--update m set RequestStatus=18	
----select recordstatus,*
--from MaintenanceRequests m
--inner join 	ZZtemp_MR_records_type2_NP z
--on m.MaintenanceRequestID=z.MaintenanceRequestID
--and  m.MaintenanceRequestID  in (select MaintenanceRequestID from zztemp_MR_productprice_type2_IGNORE)

--/*******create records for SARA LEE*********/

	  
--drop table in_MR_productprices2_NP	          		
--drop table ZZtemp_MRStores_currentset_type2_NP  
----drop table zztemp_MRStores_prodprice_update	
--drop table ZZtemp_recover_Storesetup_records2 		    
--drop table ZZtemp_storessetup_new_Type2_records_NP			
--drop table ZZtemp_Productprice_missing_Type2_NP
--drop table ZZtemp_MR_dup_items_n2
--drop table zztemp_MR_productprice_type2_IGNORE
--drop table ZZtemp_MRStores_records_type2_NP
--drop table ZZtemp_MR_records_type2_NP	
--drop table MR_productpricerecords_TYPE2_NP
----drop table zztemp_MR_to5

--update p set ProductName = LTRIM(rtrim(Description))
----select *
--from Products p
--where isnumeric(ProductName) >0
--and Description <> 'UNKNOWN'
return
GO
