USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMRProcess_productprices_fix_ActiveLastDate_all_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMRProcess_productprices_fix_ActiveLastDate_all_PRESYNC_20150329]
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
                  
 
                  


--drop table ZZtemp_MR_missing_records_DCS 


select distinct p1.chainid,p1.activestartdate, p2.activestartdate, p1.UnitPrice, p2.UnitPrice, p1.supplierid, p2.supplierid, p1.datetimecreated, p2.datetimecreated, *
--select p1.* --into zztemp_ProductPrices_74813_BeforeActiveLastDateUpdate_20150112
--update p1 set p1.activelastdate = dateadd(day, -1, p2.activestartdate), OldEndDate = p1.activelastdate
from productprices p1 with (nolock)
inner join productprices p2 with (nolock)
on p1.storeid = p2.storeid
and p1.productid = p2.productid
--and p1.supplierid = 78662 --74813
and p1.productpricetypeid = p2.productpricetypeid
and p1.productpricetypeid = 3
and p1.productpriceid <> p2.productpriceid
and cast(p1.activelastdate as date) = cast(p2.activelastdate as date)
and cast(p1.activelastdate as date) = '12/31/2099'
and cast(p2.activestartdate as date) >= cast(p1.activestartdate as date)
and cast(p2.datetimecreated as date) > cast(p1.datetimecreated as date)
where (p1.UnitPrice <> p2.UnitPrice or p1.supplierid <> p2.supplierid)
--and p1.productid in (select productid from productidentifiers where productidentifiertypeid = 8)
--and p1.StoreID=40515
--and p1.ChainID<>44285
order by p1.storeid, p1.productid


drop table zztemp_ProductPrices_dupenddate_20150203

select  distinct p1.supplierid, p1.productid, p1.storeid, p2.chainid 
into zztemp_ProductPrices_dupenddate_20150203
--update p1 set p1.activelastdate = dateadd(day, -1, p2.activestartdate), OldEndDate = p1.activelastdate
from productprices p1 with (nolock)
inner join productprices p2 with (nolock)
on p1.storeid = p2.storeid
and p1.productid = p2.productid
and p1.productpricetypeid = p2.productpricetypeid
and p1.productpricetypeid = 3
and p1.productpriceid <> p2.productpriceid
and cast(p1.activelastdate as date) = cast(p2.activelastdate as date)
and cast(p1.activelastdate as date) = '12/31/2099'
--and cast(p2.activestartdate as date) >= cast(p1.activestartdate as date)
--and cast(p2.datetimecreated as date) > cast(p1.datetimecreated as date)
where (p1.UnitPrice <> p2.UnitPrice or p1.supplierid <> p2.supplierid or cast(p1.activestartdate as date)<> cast(p2.activestartdate as date))
--and p1.productid in (select productid from productidentifiers where productidentifiertypeid = 2)
order by p1.storeid, p1.productid


/****************************in MR*****************************************/
   drop table zztemp_MR_productprices_NP_02032015 
   


			    select  MAX(mr.MaintenanceRequestID)MaintenanceRequestID, 
			    productpriceid ,p.productid,p.storeid,p.supplierid,p.chainid,p.UnitPrice,p.ActiveStartDate 
                into zztemp_MR_productprices_NP_02032015 
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
				inner join  zztemp_ProductPrices_dupenddate_20150203 m
				on m.productid=p.ProductID
				and m.chainid=p.chainid
				and m.StoreID=p.storeid		
				and mr.RequestStatus =5
	            and (mr.SupplierID  in (select SupplierID from SupplierS s where s.PDITradingPartner=0) or isnull(Bipad ,'N')<>'N')
	        
				group by  p.productid,productpriceid ,p.storeid,p.supplierid,p.chainid,p.UnitPrice,p.ActiveStartDate 
				

	          drop Table zztemp_in_MR_productprices2_NP_0203

				select distinct MaintenanceRequestID,p.productpriceid, p.productid,p.storeid,p.supplierid,p.chainid,p.UnitPrice,p.ActiveStartDate ,activelastdate 
				into zztemp_in_MR_productprices2_NP_0203
				from ProductPrices p with (NOLOCK)
				inner join zztemp_MR_productprices_NP_02032015   m
				on  p.productpriceid=m.productpriceid
				
					
                
 select ProductId,chainid,SupplierID,storeid,cost,StartDateTime,m.MaintenanceRequestID,RequestTypeID,requeststatus,SubmitDateTime,approved,m.MaintenanceRequestID,Bipad
--update m set requeststatus=2
from MaintenanceRequests m
inner join MaintenanceRequestStores s
on m.MaintenanceRequestID=s.MaintenanceRequestID
--and SupplierID=60170
and StoreID=40808
and productid=31018
and m.MaintenanceRequestID=2307797


select* 
from productprices where 1=1 and StoreID=40808
and productid=31018

select* 
from storesetup where 1=1and StoreID=40797
and productid=3499464
                
				drop table zztemp_productprices_fix_ActiveLastDate_NP_2015
				
				 select p2.MaintenanceRequestID newMRID,p1.MaintenanceRequestID oldMRID,p2.productpriceid newproductpriceid,p1.productpriceid oldproductpriceid,
				p1.ActiveStartDate oldActiveStartDate,p2.ActiveStartDate newActiveStartDate,p1.activelastdate practivelastdate,
				p2.activelastdate newactivelastdate,p1.supplierid oldsupplier,p2.supplierid newsupplier,p2.ChainID,p2.StoreID,p2.ProductID
				into zztemp_productprices_fix_ActiveLastDate_NP_2015
				from zztemp_in_MR_productprices2_NP_0203 p1 with (nolock)
				inner join zztemp_in_MR_productprices2_NP_0203 p2 with (nolock)
				on p1.productid = p2.productid
				and p1.chainid=p2.chainid
				and p1.storeid = p2.storeid
				and ((p2.MaintenanceRequestID>p1.MaintenanceRequestID ) and p1.ActiveLastDate >= p2.ActiveStartDate )
			
				order by p2.storeid
				
				
				select* from zztemp_in_MR_productprices2_NP_0203 where ProductID=3492131 and chainid=40393--where ProductID=7867 and StoreID in (41015,41018,41021,41044,41047,41050,41053,41073,41076,41079)
				order by storeid,productid,activelastdate
				select*from productprices   where ProductID=3492131 and chainid=40393--StoreID in (40400,40401,40402,41044,41047,41050,41053,41073,41076,41079)
				order by storeid,productid,activelastdate
				
				if @@ROWCOUNT>0
				
				update p set p.activelastdate= t.newActiveStartDate-1,LastUpdateUserID=76834,--@MyID
				DateTimeLastUpdate=GETDATE()
				--select newMRID,oldMRID,newproductpriceid,oldproductpriceid, p.*
				from ProductPrices p 
				inner join zztemp_productprices_fix_ActiveLastDate_NP_2015 t
				on  p.ProductPriceID = t.oldproductpriceid
				and p.activestartdate<t.newActiveStartDate
				--and p.ProductID=3492131 and p.chainid=40393
				--order by p.storeid,p.productid,productpriceid,newMRID
		
				
		select* from zztemp_productprices_fix_ActiveLastDate_NP_2015
		
		select* from productprices where ProductID=7571 and StoreID in (76222,76223,76224,76225,76226)
		order by storeid,productid,activelastdate
		
				begin
				
								update p set p.activelastdate= t.newActiveStartDate-1,LastUpdateUserID=76834,--@MyID
								DateTimeLastUpdate=GETDATE()
								--select t.*
								from ProductPrices p 
								inner join zztemp_productprices_fix_ActiveLastDate_NP_2015 t
								on  p.ProductPriceID = t.oldproductpriceid
								and p.ActiveStartDate< t.newActiveStartDate
								and p.ActiveLastDate<=t.newactivelastdate
								
			/*************Condition Tree**************/
								update p set p.ActiveStartDate= t.newactivelastdate+1,LastUpdateUserID=76834,--@MyID
								DateTimeLastUpdate=GETDATE()
								--select t.*
								from ProductPrices p 
								inner join zztemp_productprices_fix_ActiveLastDate_NP_2015 t
								on  p.ProductPriceID = t.oldproductpriceid
								and p.activelastdate>= t.newActiveStartDate
								and p.ActiveLastDate>t.newactivelastdate
								
			/*************Condition FOUR**************/	
				
								select t.newActiveLastDate,p.* into ZZtemp_ppr_delete
								--select*
								from ProductPrices p 
								inner join zztemp_productprices_fix_ActiveLastDate_NP_2015 t
								on  p.ProductPriceID = t.oldproductpriceid
								and p.activeStartdate< t.newActiveStartDate
								and p.ActiveLastDate>t.newactivelastdate
					            
							    update p set p.activelastdate= t.newActiveStartDate-1,LastUpdateUserID=76834,--@MyID
								DateTimeLastUpdate=GETDATE()
								--select t.*
								from ProductPrices p 
								inner join zztemp_productprices_fix_ActiveLastDate_NP_2015 t
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
	
				       
				
				
				

select distinct EndDateTime from MaintenanceRequests where RequestTypeID=2and datetimecreated>GETDATE()-70

select* from ProductPricesDeleted

/*****************not in pMR*********************************/
drop table ZZtemp_MRS_set_no_dup_0203
select  maxMR,storeid,productid,chainid,supplierid,MaintenanceRequestID,StartDateTime 
				into ZZtemp_MRS_set_no_dup_0203
				from 
				(select MAX(m.MaintenanceRequestId)  OVER (PARTITION BY s.storeid,m.productid,m.chainid ) as maxMR,s.storeid,m.productid,m.chainid,m.supplierid,m.MaintenanceRequestID,StartDateTime 
				from MaintenanceRequests m
				inner join MaintenanceRequestStores s
				on m.MaintenanceRequestID=s.MaintenanceRequestID
				inner join zztemp_ProductPrices_dupenddate_20150203 z
				
				on  z.storeid=s.StoreID
		  	    and z.productid=m.productid
			    and z.ChainID=m.chainid
			    and RequestStatus=5
		   		)a
				where maxMR=MaintenanceRequestID	
drop table  zztemp_PRODUCTPRICE_fix_0203

select  p.ProductPriceID,p.storeid,p.productid,p.chainid,p.supplierid,p.activestartdate,p.ActiveLastDate,p.ProductPriceTypeID ,z.StartDateTime 
into zztemp_PRODUCTPRICE_fix_0203
from 
			ProductPrices p
			inner join 
			(
			select  p.storeid,p.productid,p.chainid,p.supplierid,unitprice,cast(activestartdate as date) activestartdate
			from zztemp_ProductPrices_dupenddate_20150203 z
			inner join productprices p
			on  p.storeid=z.StoreID
			and p.productid=z.productid
			and ProductPriceTypeID=3
			
			except
			select  distinct s.storeid,m.productid,m.chainid,m.supplierid,m.cost,cast(m.startdatetime as date)
			from MaintenanceRequests m
			inner join MaintenanceRequestStores s
			on s.MaintenanceRequestID=m.MaintenanceRequestID
			inner join ZZtemp_MRS_set_no_dup_0203 z
			on  s.storeid=z.StoreID
			and m.productid=z.productid
			and m.ChainID=z.chainid
			and RequestTypeID in (1,2,15)
			and RequestStatus=5
			
			
			)a
		
		on   a.supplierid=p.supplierid
			and a.storeid=p.StoreID
			and a.productid=p.productid
			and a.ChainID=p.chainid
			and cast(a.activestartdate as date)=cast(p.ActiveStartDate as date)
			and a.UnitPrice=p.UnitPrice
			inner join ZZtemp_MRS_set_no_dup_0203 z
			on  z.storeid=p.StoreID
			and z.productid=p.productid
			and z.ChainID=p.chainid
			and p.ProductPricetypeID=3
			and cast(p.ActiveLastDate as date)>cast((z.StartDateTime)-1 as date)
			order by p.storeid,p.productid  
			
			
			update p set p.ActiveLastDate=z.StartDateTime-1	,LastUpdateUserID=203	
			--select p.ActiveStartDate,p.ActiveLastDate,z.StartDateTime,p.ProductPricetypeID,p.productid,p.storeid
			--select*			
			from productprices p
			inner join zztemp_PRODUCTPRICE_fix_0203 z
			on z.productpriceid=p.productpriceid
			and p.ActiveStartDate<z.StartDateTime
			and p.ActiveLastDate>=z.StartDateTime
			--order by storeid,productid,activelastdate
			 and p.StoreID in (41033,41139,41050,41091)
                 and p.productid=5674
                 
                 select* from zztemp_PRODUCTPRICE_fix_0203 	where 1=1 and StoreID in (41033,41139,41050,41091)
                 and productid=5674	order by storeid,productid,activelastdate
                 
                 select* from productprices where 	ProductID=5674 and StoreID in (41033,41139,41050,41091) and ProductPriceTypeID=3
		order by storeid,productid,activelastdate
             
       select* from ZZtemp_MRS_set_no_dup_0203	where 1=1 and StoreID in (41033,41139,41050,41091)
                 and productid=5674	order by storeid,productid
			drop table ZZtemp_MRS_set_no_dup_NSP
            drop table zztemp_PRODUCTPRICE_fix_NSP






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

return
GO
