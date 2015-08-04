USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMRProcess_AllMRStoresRecords_Type2_new_DCS]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMRProcess_AllMRStoresRecords_Type2_new_DCS]
as



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
                  AND TABLE_NAME='zztemp_productprices_fix_ActiveLastDate2_DCS') 
                  drop table zztemp_productprices_fix_ActiveLastDate2_DCS
                  
 IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='in_MR_productprices2_DCS') 
                  drop table in_MR_productprices2_DCS
                  
IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='MR_productpricerecords_DCS ') 
                  drop table MR_productpricerecords_DCS 
                  
IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='ZZtemp_MRStores_records_max') 
                  drop table ZZtemp_MRStores_records_max
                  
 IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='ZZtemp_MRStores_records_DCS') 
                  drop table ZZtemp_MRStores_records_DCS
                  
  IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='ZZtemp_MR_missing_records_DCS ') 
                  drop table ZZtemp_MR_missing_records_DCS 
                  
 
                  


--drop ZZtemp_MR_missing_records_DCS 

/* find missing productprice  records which are in MR with requeststatus=5 */
	        select *	into ZZtemp_MR_missing_records_DCS   
	        from 
			(select distinct  chainid,supplierid ,cost,productid,storeid ,cast(StartDateTime as date) StartDateTime
			 from 
			 MaintenanceRequests m 
			 inner join MaintenanceRequestStores s
			 on s.MaintenanceRequestID=m.MaintenanceRequestID
			 where chainid=42490 
			 and RequestStatus in (5)
			 and RequestTypeID<>3
			 and PDIParticipant=0
			 and cast(StartDateTime as date)>'2014-01-01' 
			 and productid= 3493721--3489327
			 except
			 select distinct   chainid,supplierid ,UnitPrice,productid,storeid ,cast(activeStartDate as date)
			 from  productprices
			 where chainid=42490  and supplierid=74796
			 and ProductPriceTypeID=3
			 and SupplierPackageID is null) a
			 
			 
			 select distinct  chainid,supplierid ,cost,productid,storeid --,cast(StartDateTime as date) StartDateTime
			 from 
			 MaintenanceRequests m 
			 inner join MaintenanceRequestStores s
			 on s.MaintenanceRequestID=m.MaintenanceRequestID
			 where chainid=42490 
			 and RequestStatus in (5)
			 and RequestTypeID<>3
			 and PDIParticipant=0
			 and cast(StartDateTime as date)>'01-01-2014' 
			 --and productid=3489327
			 except
			 select distinct   chainid,supplierid ,UnitPrice,productid,storeid --,cast(activeStartDate as date)
			 from  productprices
			 where chainid=42490  and supplierid=74796
			 and ProductPriceTypeID=3
			 and SupplierPackageID is null
 
 
		    select m.MaintenanceRequestID,m.StartDateTime, m.chainid,m.supplierid ,m.cost,m.productid,s.storeid ,m.SuggestedRetail
			into ZZtemp_MRStores_records_DCS
			from MaintenanceRequests m
			inner join MaintenanceRequestStores s
			on m.MaintenanceRequestID=s.MaintenanceRequestID
			inner join ZZtemp_MR_missing_records_DCS   z
			on z.productid=m.productid
			and m.SupplierID=z.SupplierID
			and m.ChainID=z.ChainID
			and m.Cost=z.Cost
			and cast(m.StartDateTime as date)=cast(z.StartDateTime as date)
			and z.storeid=s.StoreID
			
			--select* from ZZtemp_MRStores_records_DCS
			--select* from MaintenanceRequests where MaintenanceRequestID=  381417
	        select* from productprices where 	chainid=42490  and supplierid=74796	 
	        and ProductPriceTypeID=3 and SupplierPackageID is null and productid=3489327 --and StoreID in (44337,44408,44426)
	        --and  CAST(ActiveLastDate as date)='2099-12-31' 
	       -- and ActivestartDate <>'2014-04-01 00:00:00.000'
	         order by storeid, ActiveLastDate
	         
	         
	           select COUNT(*),StoreID
	            from productprices where 	chainid=42490  and supplierid=74796	 
	        and ProductPriceTypeID=3 and SupplierPackageID is null and productid=3489327
	        group by StoreID having count(*)<2
			 
	
	
/*********************************************************** STEP2**************************************	
	***********************insert missing records into SETUPSTORES from selected set of records for TYPE1*/		
			
			/*Step2 -1
			 create records for each store found in MaintenanceRequestStores with maxMaintenanceRequestID
			 per storeid,productid,SupplierID,chainid to insert in STORSETUP*/
			
			select max(MaintenanceRequestID) maxMRID,storeid,productid,SupplierID,chainid
			into ZZtemp_MRStores_records_max
			from ZZtemp_MRStores_records_DCS
			group by storeid,productid,SupplierID,chainid
			
			select* from ZZtemp_MRStores_records_max
			select* from MaintenanceRequests where MaintenanceRequestID=417723
			
			/*****************************update active last date for terminated supplier*********************************/
			update p set p.ActiveLastDate=m.StartDateTime-1
			--select p.*
			from  ZZtemp_MRStores_records_max z
			inner join  MaintenanceRequests m			
			on m.MaintenanceRequestID=maxMRID
			inner join storesetup p
			on z.productid=p.productid
			and z.storeid=p.storeid
			and z.chainid=p.chainid
			and z.SupplierID<>p.SupplierID
			and p.ActiveLastDate>m.StartDateTime
			
				/***************to insert  supplier which were previously terminated and not recovered*************************/
			select storeid,productid,SupplierID,chainid,StartDateTime into ZZtemp_new_Storesetup_records
				from
			(
			/***************find  supplier which were previously terminated*************************/
			select z.storeid,z.productid,z.SupplierID,z.chainid,m.StartDateTime 		
			from  ZZtemp_MRStores_records_max z
			inner join  MaintenanceRequests m			
			on m.MaintenanceRequestID=maxMRID
			inner join storesetup p
			on z.productid=p.productid
			and z.storeid=p.storeid
			and z.chainid=p.chainid
			and z.SupplierID=p.SupplierID
			and p.ActiveLastDate<m.StartDateTime
			
			except
			
			/***************find  supplier which are recovered*************************/
			select z.storeid,z.productid,z.SupplierID,z.chainid,m.StartDateTime 			
			from  ZZtemp_MRStores_records_max z
			inner join  MaintenanceRequests m			
			on m.MaintenanceRequestID=maxMRID
			inner join storesetup p
			on z.productid=p.productid
			and z.storeid=p.storeid
			and z.chainid=p.chainid
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
			(select  distinct storeid,chainid,SupplierID,productid	from ZZtemp_MRStores_records_max                                  										
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
					from ZZtemp_MRStores_records_max  p
					inner join MaintenanceRequests  m
					on maxMRID=m.MaintenanceRequestid							
					inner join MaintenanceRequeststores s
					on m.MaintenanceRequestID=s.MaintenanceRequestID					
					and s.StoreID=p.storeid
	
	
	


/******************************************    STEP3-3-1	  ***********************************/

/* 
find storeid,chainid,SupplierID,productid which are not in Productprices and 
create table of 
  select *	into ZZtemp_MR_missing_records_DCS   
	        from 
			(select distinct cast(StartDateTime as date) StartDateTime, chainid,supplierid ,cost,productid,storeid 
			 from 
			 MaintenanceRequests m 
			 inner join MaintenanceRequestStores s
			 on s.MaintenanceRequestID=m.MaintenanceRequestID
			 where chainid=42490 
			 and RequestStatus in (5)
			 and RequestTypeID<>3
			 and PDIParticipant=0
			 and cast(StartDateTime as date)>'01-01-2014' 
			 except
			 select distinct cast(activeStartDate as date) , chainid,supplierid ,UnitPrice,productid,storeid 
			 from  productprices
			 where chainid=42490  and supplierid=74796
			 and ProductPriceTypeID=3
			 and SupplierPackageID is null) a
			 
			select  m.MaintenanceRequestID,m.StartDateTime, m.chainid,m.supplierid ,m.cost,m.productid,s.storeid ,m.SuggestedRetail
			--into ZZtemp_MRStores_records_DCS
			from MaintenanceRequests m
			inner join MaintenanceRequestStores s
			on m.MaintenanceRequestID=s.MaintenanceRequestID
			inner join ZZtemp_MR_missing_records_DCS   z
			on z.productid=m.productid
			and m.SupplierID=z.SupplierID
			and m.ChainID=z.ChainID
			and m.Cost=z.Cost
			and cast(m.StartDateTime as date)=cast(z.StartDateTime as date)
			and z.storeid=s.StoreID

			
			select max(MaintenanceRequestID) maxMRID,storeid,productid,SupplierID,chainid
			--into ZZtemp_MRStores_records_max
			from ZZtemp_MRStores_records_DCS
			group by storeid,productid,SupplierID,chainid
		

 */




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
,'2099-12-31'
,0
, GETDATE()
-- select  p.* --,maxMRID
from ZZtemp_MR_missing_records_DCS   p			        
inner join  ZZtemp_MRStores_records_DCS m
on m.chainid=p.chainid
and p.supplierid=m.supplierid
and m.startdatetime	=p.startdatetime
and m.cost=p.cost 
and m.productid=p.productid
and p.storeid=m.storeid
and m.MaintenanceRequestID in (select distinct maxMRID from ZZtemp_MRStores_records_max )


		
/* **************************STEP4*********************************
update DATATRUE_EDI..COSTS for MR EDI records*********************

*/

--drop table MR_productpricerecords_DCS 


select  MAX(mr.MaintenanceRequestID)MaintenanceRequestID, 
productpriceid ,p.productid,p.storeid,p.supplierid,p.chainid,p.UnitPrice,p.ActiveStartDate 
into MR_productpricerecords_DCS 
from ProductPrices p
inner join ZZtemp_MRStores_records_DCS mr
on p.supplierid=mr.supplierid
and p.ProductID=mr.productid
and p.chainid=mr.ChainID
and p.ActiveStartDate=mr.StartDateTime
and p.UnitPrice =mr.cost	
and p.StoreID= mr.storeid		
and  productpricetypeid=3 
group by  p.productid,productpriceid ,p.storeid,p.supplierid,p.chainid,p.UnitPrice,p.ActiveStartDate 


/* addiding productpriceid,activelastdate to  each row of in_MR_productprices table*/
--if @@ROWCOUNT>0
--drop Table in_MR_productprices2_DCS

select distinct MaintenanceRequestID,p.productpriceid, p.productid,p.storeid,p.supplierid,p.chainid,p.UnitPrice,p.ActiveStartDate ,activelastdate 
into in_MR_productprices2_DCS
from ProductPrices p with (NOLOCK)
inner join MR_productpricerecords_DCS m
on  p.productpriceid=m.productpriceid

select* from in_MR_productprices2_NP
--drop table zztemp_productprices_fix_ActiveLastDate2_DCS

select p2.MaintenanceRequestID newMRID,p1.MaintenanceRequestID oldMRID,p2.productpriceid newproductpriceid,p1.productpriceid oldproductpriceid,
p1.ActiveStartDate oldActiveStartDate,p2.ActiveStartDate newActiveStartDate,p1.activelastdate practivelastdate,
p2.activelastdate newactivelastdate,p1.supplierid oldsupplier,p2.supplierid newsupplier,p2.ChainID,p2.StoreID,p2.ProductID
into zztemp_productprices_fix_ActiveLastDate2_DCS
from in_MR_productprices2_DCS p1 with (nolock)
inner join in_MR_productprices2_DCS p2 with (nolock)
on p1.productid = p2.productid
and p1.chainid=p2.chainid
and p1.storeid = p2.storeid
and ((p2.MaintenanceRequestID>p1.MaintenanceRequestID ) and p1.ActiveLastDate >= p2.ActiveStartDate )				
order by p2.storeid

if @@ROWCOUNT>0

update p set p.activelastdate= t.newActiveStartDate-1,LastUpdateUserID=76834,--@MyID
DateTimeLastUpdate=GETDATE()
--select t.*
from ProductPrices p 
inner join zztemp_productprices_fix_ActiveLastDate2_DCS t
on  p.ProductPriceID = t.oldproductpriceid

/*********setting ActiveLastDate to '2099-12-31 00:00:00.000' for the most recent records **********/

update ProductPrices set ActiveLastDate='2099-12-31',LastUpdateUserID=76835,
DateTimeLastUpdate=GETDATE()
where productpriceid in(select productpriceid
--select productpriceid ,LatestMRID, ActiveStartDate ,activelastdate,StoreID,productid,chainid
from (select p.productpriceid ,newMRID,MAX( newMRID) OVER (PARTITION BY p.StoreID,p.productid,p.chainid  ) as LatestMRID,
p.StoreID,p.productid,p.chainid ,p.ActiveStartDate ,p.activelastdate
from ProductPrices p  
inner join ZZtemp_productprices_fix_ActiveLastDate2_DCS t
on  p.ProductPriceID = t.newproductpriceid and p.ProductPriceTypeID =3     
)a  where newMRID=LatestMRID  and   ActiveLastDate<'2099-12-31 00:00:00.000'
)



				select  maxMR,storeid,productid,chainid,supplierid,MaintenanceRequestID,StartDateTime 
				into ZZtemp_MRS_set_no_dup_DCS
				from 
				(select MAX(m.MaintenanceRequestId)  OVER (PARTITION BY storeid,productid,chainid,supplierid ) as maxMR,storeid,productid,chainid,supplierid,m.MaintenanceRequestID,StartDateTime 
				from ZZtemp_MRStores_records_DCS m
					)a
				where maxMR=MaintenanceRequestID			
				
				

		select  p.ProductPriceID,p.storeid,p.productid,p.chainid,p.supplierid,p.activestartdate,p.ActiveLastDate ,z.startdatetime,p.ProductPriceTypeID  
		into zztemp_PRODUCTPRICE_fix_DCS
		from 
		ProductPrices p
			inner join 
			(
			select  p.storeid,p.productid,p.chainid,p.supplierid,unitprice,cast(activestartdate as date) activestartdate
			from ZZtemp_MRS_set_no_dup_DCS z
			inner join productprices p
			on p.ChainID=z.supplierid
			and p.storeid=z.StoreID
			and p.productid=z.productid
			and ProductPriceTypeID=3
			except
			select  distinct s.storeid,m.productid,m.chainid,m.supplierid,m.cost,cast(m.startdatetime as date)
			from MaintenanceRequests m
			inner join MaintenanceRequestStores s
			on s.MaintenanceRequestID=m.MaintenanceRequestID
			inner join ZZtemp_MRS_set_no_dup_DCS z
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
			inner join ZZtemp_MRS_set_no_dup_DCS z
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
			inner join zztemp_PRODUCTPRICE_fix_DCS z
			on z.productpriceid=p.productpriceid
			
			drop table ZZtemp_MRS_set_no_dup_DCS
            drop table zztemp_PRODUCTPRICE_fix_DCS


   

drop table zztemp_productprices_fix_ActiveLastDate2_NP

            IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='zztemp_MR_NOT_IGNORE') 
                  drop table zztemp_MR_NOT_IGNORE
                  
                  
	  
drop table in_MR_productprices2_NP	          		
drop table ZZtemp_MRStores_currentset_type2_NP  
--drop table zztemp_MRStores_prodprice_update	
drop table ZZtemp_recover_Storesetup_records2 		    
drop table ZZtemp_storessetup_new_Type2_records_NP			
drop table ZZtemp_Productprice_missing_Type2_NP
drop table ZZtemp_MR_dup_items_n2
drop table zztemp_MR_productprice_type2_IGNORE
drop table ZZtemp_MRStores_records_type2_NP
drop table ZZtemp_MR_records_type2_NP	
drop table MR_productpricerecords_TYPE2_NP
--drop table zztemp_MR_to5

update p set ProductName = LTRIM(rtrim(Description))
--select *
from Products p
where isnumeric(ProductName) >0
and Description <> 'UNKNOWN'
return
GO
