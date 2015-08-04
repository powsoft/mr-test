USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMRProcess_storesetup_fix_ActiveLastDate_all_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMRProcess_storesetup_fix_ActiveLastDate_all_PRESYNC_20150415]
as


declare @costtablerecordid int
declare @RecordID int
declare @mridreturned int
declare @RecordCount1 int
declare @RecordCount2 int
declare @rec cursor
DECLARE @badrecids varchar(max)=''
DECLARE @requeststatus varchar(4)=''
DECLARE @requestTypeid varchar(2)=''
DECLARE @PDIParticipant varchar(1)=''
DECLARE @SubmitDateTime DATETIME
DECLARE @StartDateTime DATETIME
--DECLARE @chainid varchar(8)=''
--DECLARE @chainname varchar(60)=''
--DECLARE @SupplierID varchar(8)=''
DECLARE @suppliername varchar(60)=''
DECLARE @Storenumber varchar(8)=''
declare @rec1 cursor
declare @storeid int
DECLARE @ActiveStartDate DATETIME
DECLARE @ActiveLastDate DATETIME
declare @productid int
declare @supplierid int
declare @chainid int
			


			

/*************************************/

IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='zztemp_dup_STST_records_02102015') 
                  drop table zztemp_dup_STST_records_02102015
IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='zztemp_STORESETUP2_dupenddate_20150203') 
                  drop table zztemp_STORESETUP2_dupenddate_20150203
                  
 IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='zztemp_STORESETUP3_dupenddate_20150203') 
                  drop table zztemp_STORESETUP3_dupenddate_20150203
                  
  IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='ZZtemp_MRS_set_dupSTST_02112015') 
                  drop table ZZtemp_MRS_set_dupSTST_02112015                  
 
                  
                 IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='zztemp_in_MR_productprices2_NP_0203') 
                  drop table zztemp_in_MR_productprices2_NP_0203    
                 
                  IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='zztemp_productprices_fix_ActiveLastDate_NP_2015') 
                  drop table zztemp_productprices_fix_ActiveLastDate_NP_2015
                  
                  IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='zztemp_PP_delete_extra_0310') 
                  drop table  zztemp_PP_delete_extra_0310  
                  
                  IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='ZZtemp_MRS_set_dupPP_0203')                   
                  drop table ZZtemp_MRS_set_dupPP_0203
                      
                  IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='zztemp_PRODUCTPRICE_fix_0203') 
                  drop table zztemp_PRODUCTPRICE_fix_0203  
                  
                  IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='zztemp_DELETE_PB_02112015') 
                  drop table zztemp_DELETE_PB_02112015                    
 

/***********************delete full PP duplicates**************************/

select * into zztemp_dup_STST_records_02102015
from(
select max(storesetupid) OVER (PARTITION BY p.StoreID,p.productid,p.chainid,supplierid,cast(activestartdate as date),cast(activelastdate as date)   ) as maxstoresetupid,p.storesetupid,p.StoreID,p.productid,p.chainid,p.supplierid,cast(activestartdate as date) startdt,cast(activelastdate as date) lastdt
from storesetup p )a
where storesetupid<>maxstoresetupid

if @@ROWCOUNT>0
begin
							 
							 delete p 
							  FROM storesetup p							
							  inner join zztemp_dup_STST_records_02102015 z
							 on z.storesetupid=p.storesetupid
end




select  COUNT(*) CNT,  p1.productid, p1.storeid, p1.chainid 
into zztemp_STORESETUP2_dupenddate_20150203
from storesetup p1 with (nolock)
where  cast(p1.activelastdate as date) = '12/31/2099'
group by  p1.productid, p1.storeid, p1.chainid 
having COUNT(*)=2
order by p1.storeid, p1.productid

select  COUNT(*)cnt,  p1.productid, p1.storeid, p1.chainid 
into zztemp_STORESETUP3_dupenddate_20150203
from storesetup p1 with (nolock)
where  cast(p1.activelastdate as date) = '12/31/2099'
group by  p1.productid, p1.storeid, p1.chainid 
having COUNT(*)>2
order by p1.storeid, p1.productid


select  min(StartDateTime) StartDateTime ,a.storeid,a.productid,a.chainid,a.supplierid
				into ZZtemp_MRS_set_dupSTST_02112015
				from 
				(select MAX(m.MaintenanceRequestId)  OVER (PARTITION BY s.storeid,m.productid,m.chainid ) as maxMR,s.storeid,m.productid,m.chainid,m.supplierid,m.MaintenanceRequestID
				from MaintenanceRequests m
				inner join MaintenanceRequestStores s
				on m.MaintenanceRequestID=s.MaintenanceRequestID
				inner join  zztemp_STORESETUP2_dupenddate_20150203 z				
				on  z.storeid=s.StoreID
		  	    and z.productid=m.productid
			    and z.ChainID=m.chainid
			    and RequestStatus=5
			    and RequestTypeID in (1,2,15))a
			    inner join MaintenanceRequests m
			    on m.productid=a.productid
			    and m.ChainID=a.ChainID
			    and m.supplierid=a.supplierid
			    inner join MaintenanceRequestStores s
				on m.MaintenanceRequestID=s.MaintenanceRequestID
			    and s.StoreID=a.storeid		   		
				where maxMR=a.MaintenanceRequestID	
				
				
				select* 				
				--update s set s.ActiveLastDate=z.StartDateTime
				from storesetup s
				inner join ZZtemp_MRS_set_dupSTST_02112015 z
				on s.storeid=z.storeid
				and s.productid=z.productid
				and s.SupplierID<>z.supplierid
				and cast(s.activelastdate as date) = '12/31/2099'
				
				
				select* 				
				--update s set s.ActivestartDate=z.StartDateTime
				from storesetup s
				inner join ZZtemp_MRS_set_dupSTST_02112015 z
				on s.storeid=z.storeid
				and s.productid=z.productid
				and s.SupplierID=z.supplierid
				and cast(s.activelastdate as date) = '12/31/2099'
				


set @rec1 = CURSOR local fast_forward FOR

	select  s.storeid,s.productid,s.chainid,s.supplierid,s.ActiveStartDate,s.ActiveLastDate
	from storesetup s
	inner join zztemp_STORESETUP3_dupenddate_20150203 z
	on s.ChainID=z.chainid
	and s.StoreID=z.storeid
    and s.ProductID=z.productid
    and cast(s.activelastdate as date) = '12/31/2099'
	order by s.storeid,s.productid,s.chainid,s.supplierid,s.ActiveStartDate

  fetch next from @rec1 into @storeid,@productid,@chainid,@supplierid,@ActiveStartDate,@ActiveLastDate

    while @@FETCH_STATUS = 0
	begin
	 			
	fetch next from @rec1 into @storeid,@productid,@chainid,@supplierid,@ActiveStartDate,@ActiveLastDate
	end
	
close @rec1
deallocate @rec1

/*************************************************************************************************
*****************************************************************************************************
*************************************************************************************************/
--select * into zztemp_dup_PRPR_records_02102015
--from(
--select min(productpriceid) OVER (PARTITION BY p.StoreID,p.productid,p.chainid,supplierid,unitprice,cast(activestartdate as date),cast(activelastdate as date)   ) as minproductpriceid,p.productpriceid,p.StoreID,p.productid,p.chainid,supplierid,unitprice,cast(activestartdate as date) startdt,cast(activelastdate as date) lastdt
--from productprices p where ProductPriceTypeID=3 and SupplierPackageID is null)a
--where productpriceid<>minproductpriceid

--if @@ROWCOUNT>0
--begin
--		            INSERT INTO [DataTrue_Main].[dbo].[ProductPricesDeleted]
--									   ([ProductPriceID]
--									   ,[ProductPriceTypeID]
--									   ,[ProductID]
--									   ,[ChainID]
--									   ,[StoreID]
--									   ,[BrandID]
--									   ,[SupplierID]
--									   ,[UnitPrice]
--									   ,[UnitRetail]
--									   ,[PricePriority]
--									   ,[ActiveStartDate]
--									   ,[ActiveLastDate]
--									   ,[PriceReportedToRetailerDate]
--									   ,[DateTimeCreated]
--									   ,[LastUpdateUserID]
--									   ,[BaseCost]
--									   ,[Allowance]
--									   ,[NewActiveStartDateNeeded]
--									   ,[NewActiveLastDateNeeded]
--									   ,[OldStartDate]
--									   ,[OldEndDate])
--							SELECT p.productpriceid
--							      ,p.ProductPriceTypeID
--								  ,p.ProductID
--								  ,p.ChainID
--								  ,p.StoreID
--								  ,p.BrandID
--								  ,p.SupplierID
--								  ,p.UnitPrice
--								  ,p.UnitRetail
--								  ,p.PricePriority
--								  ,p.ActiveLastDate
--								  ,p.ActiveLastDate
--								  ,p.PriceReportedToRetailerDate
--								  ,GETDATE()
--								 ,02102015
--								  ,p.BaseCost
--								  ,p.Allowance
--								  ,p.NewActiveStartDateNeeded
--								  ,p.NewActiveLastDateNeeded
--								  ,p.ActiveStartDate
--								  ,p.ActiveLastDate
								  
--								  --select p.*								
--							  FROM ProductPrices p							
--							  inner join zztemp_dup_PRPR_records_02102015 z
--							 on z.productpriceid=p.productpriceid
							 
--							 delete p 
--							  FROM ProductPrices p							
--							  inner join zztemp_dup_PRPR_records_02102015 z
--							 on z.productpriceid=p.productpriceid
--end

--select distinct p1.chainid,p1.activestartdate,p2.activestartdate, p1.ActiveLastDate,  p2.ActiveStartDate, p1.UnitPrice, p2.UnitPrice, p1.supplierid, p2.supplierid, p1.datetimecreated, p2.datetimecreated, *
--from productprices p1 with (nolock)
--inner join productprices p2 with (nolock)
--on p1.storeid = p2.storeid
--and p1.productid = p2.productid

--and p1.productpricetypeid = p2.productpricetypeid
--and p1.productpricetypeid = 3
--and p1.productpriceid <> p2.productpriceid
--and cast(p1.activelastdate as date) = cast(p2.activelastdate as date)
--and cast(p1.activelastdate as date) <> '12/31/2099'
----and cast(p2.activestartdate as date) >= cast(p1.activestartdate as date)
----and cast(p2.datetimecreated as date) > cast(p1.datetimecreated as date)
--and p1.SupplierPackageID is null
--and p2.SupplierPackageID is null
--where (p1.UnitPrice <> p2.UnitPrice or p1.supplierid <> p2.supplierid)
--order by p1.storeid, p1.productid


--select  COUNT(*),  p1.productid, p1.storeid, p1.chainid ,p1.activelastdate
----into zztemp_ProductPrices_dupenddate_20150203
--from productprices p1 with (nolock)
--where p1.productpricetypeid = 3
--and cast(p1.activelastdate as date) = '12/31/2099'
--and p1.SupplierPackageID is null
--group by  p1.productid, p1.storeid, p1.chainid ,p1.activelastdate
--having COUNT(*)>1

--order by p1.storeid, p1.productid


--/**********************find duplicates ActiveLast date*************************/


--select  distinct p1.supplierid, p1.productid, p1.storeid, p2.chainid 
--into zztemp_ProductPrices_dupenddate_20150203
----update p1 set p1.activelastdate = dateadd(day, -1, p2.activestartdate), OldEndDate = p1.activelastdate
--from productprices p1 with (nolock)
--inner join productprices p2 with (nolock)
--on p1.storeid = p2.storeid
--and p1.productid = p2.productid
--and p1.productpricetypeid = p2.productpricetypeid
--and p1.productpricetypeid = 3
--and p1.productpriceid <> p2.productpriceid
--and cast(p1.activelastdate as date) = cast(p2.activelastdate as date)
--and cast(p1.activelastdate as date) <> '12/31/2099'
--and p1.SupplierPackageID is null
--and p2.SupplierPackageID is null
--where (p1.UnitPrice <> p2.UnitPrice or p1.supplierid <> p2.supplierid or cast(p1.activestartdate as date)<> cast(p2.activestartdate as date))
----and p1.productid in (select productid from productidentifiers where productidentifiertypeid = 2)
--order by p1.storeid, p1.productid

--select distinct StoreID,productid into zztemp_store_product_set02112015 from  zztemp_ProductPrices_dupenddate_20150203 
--where  ProductID in (5081,5674,6994,38913,3487411,3494063) and SupplierID<>0
--order by StoreID,productid

--select* from productprices where ProductID in (5081,5674,3487411)and ProductPriceTypeID=3 and StoreID=40400
--order by StoreID,productid,ActiveLastDate 

--select  distinct m.productid,s.storeid,m.chainid,m.supplierid,m.cost,cast(m.startdatetime as date)
--			from MaintenanceRequests m
--			inner join MaintenanceRequestStores s
--			on s.MaintenanceRequestID=m.MaintenanceRequestID 
--			inner join zztemp_store_product_set02112015 z
--			on m.productid=z.productid
--			and s.StoreID=z.productid
--			and cost>0
--			and RequestStatus=5 and RequestTypeID in (1,2)	
--order by StoreID,productid

--select distinct p1.chainid,p1.activestartdate,p1.activestartdate, p2.activestartdate,  p2.activestartdate, p1.UnitPrice, p2.UnitPrice, p1.supplierid, p2.supplierid, p1.datetimecreated, p2.datetimecreated, *
--from productprices p1 with (nolock)
--inner join productprices p2 with (nolock)
--on p1.storeid = p2.storeid
--and p1.productid = p2.productid
--inner join zztemp_store_product_set02112015 z
--on p1.productid=z.productid
--and p1.StoreID=z.productid
--and p1.productpricetypeid = p2.productpricetypeid
--and p1.productpricetypeid = 3
--and p1.productpriceid <> p2.productpriceid
--and cast(p1.activelastdate as date) = cast(p2.activelastdate as date)
--and cast(p1.activelastdate as date) = '12/31/2099'
----and cast(p2.activestartdate as date) >= cast(p1.activestartdate as date)
----and cast(p2.datetimecreated as date) > cast(p1.datetimecreated as date)
--and p1.SupplierPackageID is null
--and p2.SupplierPackageID is null
--order by p1.storeid, p1.productid


		 
--/****************************in MR*****************************************/

--			    select  MAX(mr.MaintenanceRequestID)MaintenanceRequestID, 
--			    productpriceid ,p.productid,p.storeid,p.supplierid,p.chainid,p.UnitPrice,p.ActiveStartDate 
--                into zztemp_MR_productprices_NP_02032015 
--			    from ProductPrices p
--			    inner join MaintenanceRequests mr
--			    on p.supplierid=mr.supplierid
--				and p.ProductID=mr.productid
--				and p.chainid=mr.ChainID
--				and p.ActiveStartDate=mr.StartDateTime
--				and p.UnitPrice =mr.cost			
--				and  productpricetypeid=3 
--				inner join MaintenanceRequestStores s
--			    on mr.MaintenanceRequestID=s.MaintenanceRequestID 
--				and p.StoreID= s.storeid				
--				inner join  zztemp_ProductPrices_dupenddate_20150203 m
--				on m.productid=p.ProductID
--				and m.chainid=p.chainid
--				and m.StoreID=p.storeid		
--				and mr.RequestStatus =5
--				and mr.RequestTypeID in (1,2)
--	            and (PDIParticipant=0 or isnull(Bipad ,'N')<>'N')	        
--				group by  p.productid,productpriceid ,p.storeid,p.supplierid,p.chainid,p.UnitPrice,p.ActiveStartDate 
				
--				--select* from zztemp_MR_productprices_NP_02032015 
--    --            where  StoreID=40457 and ProductID in (10750)
--    --            order by StoreID,productid
                
--    --            select* from productprices where StoreID=40457 and ProductID in (10750)
--    --           order by StoreID,productid,ActiveLastDate			

	      

--				select distinct MaintenanceRequestID,p.productpriceid, p.productid,p.storeid,p.supplierid,p.chainid,p.UnitPrice,p.ActiveStartDate ,activelastdate 
--				into zztemp_in_MR_productprices2_NP_0203
--				from ProductPrices p with (NOLOCK)
--				inner join zztemp_MR_productprices_NP_02032015   m
--				on  p.productpriceid=m.productpriceid
				
				
--				 select p2.MaintenanceRequestID newMRID,p1.MaintenanceRequestID oldMRID,p2.productpriceid newproductpriceid,p1.productpriceid oldproductpriceid,
--				p1.ActiveStartDate oldActiveStartDate,p2.ActiveStartDate newActiveStartDate,p1.activelastdate practivelastdate,
--				p2.activelastdate newactivelastdate,p1.supplierid oldsupplier,p2.supplierid newsupplier,p2.ChainID,p2.StoreID,p2.ProductID
--				into zztemp_productprices_fix_ActiveLastDate_NP_2015
--				from zztemp_in_MR_productprices2_NP_0203 p1 with (nolock)
--				inner join zztemp_in_MR_productprices2_NP_0203 p2 with (nolock)
--				on p1.productid = p2.productid
--				and p1.chainid=p2.chainid
--				and p1.storeid = p2.storeid
--				and ((p2.MaintenanceRequestID>p1.MaintenanceRequestID ) and p1.ActiveLastDate >= p2.ActiveStartDate )			
--				order by p2.storeid
				
--				select* from zztemp_MR_productprices_NP_02032015 where StoreID=40515 and ProductID in (31018,3488939)
--                order by StoreID,productid   
			
				
--				if @@ROWCOUNT>0
--				begin	
--				update p set p.activelastdate= t.newActiveStartDate-1,LastUpdateUserID=76834,--@MyID
--				DateTimeLastUpdate=GETDATE()
--				--select newMRID,oldMRID,newproductpriceid,oldproductpriceid,newactivestartdate,newactivelastdate, p.*
--				from ProductPrices p 
--				inner join zztemp_productprices_fix_ActiveLastDate_NP_2015 t
--				on  p.ProductPriceID = t.oldproductpriceid
--				and p.activestartdate<t.newActiveStartDate
--				and p.ActiveLastDate>t.newActiveStartDate-1
--				--and p.ProductID=18535
--				--and p.ChainID=60620
--		        -- and p.StoreID in (40457,40457,40458,40459,40460,40461,40462,40463,40464)
--				--order by p.storeid,p.productid,productpriceid,newMRID
		
				
			
--				select* from zztemp_MR_productprices_NP_02032015 where StoreID=40515 and ProductID in (31018,3488939)
--                order by StoreID,productid
                
--                                update p set p.activelastdate= t.newActiveStartDate-1,LastUpdateUserID=76834,--@MyID
--								DateTimeLastUpdate=GETDATE()
--								--select t.*
--								from ProductPrices p 
--								inner join zztemp_productprices_fix_ActiveLastDate_NP_2015 t
--								on  p.ProductPriceID = t.oldproductpriceid
--								and p.ActiveStartDate> t.newActiveStartDate
--								and p.ActiveLastDate<=t.newactivelastdate
--   /**extra condition*****************/
						
--								select productpriceid into zztemp_PP_delete_extra_0310
--								from ProductPrices p 
--								inner join zztemp_productprices_fix_ActiveLastDate_NP_2015 t
--								on  p.ProductPriceID = t.oldproductpriceid
--								and p.ActiveStartDate> t.newActiveStartDate
--								and p.ActiveLastDate<=t.newactivelastdate
--				IF @@ROWCOUNT>0
--				begin				
								
--		            INSERT INTO [DataTrue_Main].[dbo].[ProductPricesDeleted]
--									   (productpriceid
--									   ,[ProductPriceTypeID]
--									   ,[ProductID]
--									   ,[ChainID]
--									   ,[StoreID]
--									   ,[BrandID]
--									   ,[SupplierID]
--									   ,[UnitPrice]
--									   ,[UnitRetail]
--									   ,[PricePriority]
--									   ,[ActiveStartDate]
--									   ,[ActiveLastDate]
--									   ,[PriceReportedToRetailerDate]
--									   ,[DateTimeCreated]
--									   ,DateTimeLastUpdate
--									   ,[LastUpdateUserID]
--									   ,[BaseCost]
--									   ,[Allowance]
--									   ,[NewActiveStartDateNeeded]
--									   ,[NewActiveLastDateNeeded]
--									   ,[OldStartDate]
--									   ,[OldEndDate])
--							SELECT p.productpriceid,
--							      p.ProductPriceTypeID
--								  ,p.ProductID
--								  ,p.ChainID
--								  ,p.StoreID
--								  ,p.BrandID
--								  ,p.SupplierID
--								  ,p.UnitPrice
--								  ,p.UnitRetail
--								  ,p.PricePriority
--								  ,p.ActiveLastDate
--								  ,p.ActiveLastDate
--								  ,p.PriceReportedToRetailerDate
--								  ,GETDATE()
--								  ,GETDATE()
--								 ,02102015
--								  ,p.BaseCost
--								  ,p.Allowance
--								  ,p.NewActiveStartDateNeeded
--								  ,p.NewActiveLastDateNeeded
--								  ,p.ActiveStartDate
--								  ,p.ActiveLastDate
								  
--								  --select p.*								
--							  FROM ProductPrices p							
--							  inner join zztemp_PP_delete_extra_0310	z
--							 on z.productpriceid=p.productpriceid
							 
--							 delete p
--							  FROM ProductPrices p							
--							  inner join zztemp_PP_delete_extra_0310	z
--							 on z.productpriceid=p.productpriceid
--						end		
--			/*************Condition Tree**************/
--								update p set p.ActiveStartDate= t.newactivelastdate+1,LastUpdateUserID=76834,--@MyID
--								DateTimeLastUpdate=GETDATE()
--								--select t.*
--								from ProductPrices p 
--								inner join zztemp_productprices_fix_ActiveLastDate_NP_2015 t
--								on  p.ProductPriceID = t.oldproductpriceid
--								and p.activelastdate>= t.newActiveStartDate
--								and p.ActiveLastDate>t.newactivelastdate
								
--			/*************Condition FOUR**************/	
				
--								select t.newActiveLastDate,p.* into ZZtemp_ppr_delete
--								--select*
--								from ProductPrices p 
--								inner join zztemp_productprices_fix_ActiveLastDate_NP_2015 t
--								on  p.ProductPriceID = t.oldproductpriceid
--								and p.activeStartdate< t.newActiveStartDate
--								and p.ActiveLastDate>t.newactivelastdate
					            
--							--    update p set p.activelastdate= t.newActiveStartDate-1,LastUpdateUserID=76834,--@MyID
--							--	DateTimeLastUpdate=GETDATE()
--							--	--select t.*
--							--	from ProductPrices p 
--							--	inner join zztemp_productprices_fix_ActiveLastDate_NP_2015 t
--							--	on  p.ProductPriceID = t.oldproductpriceid
--							--	and p.ActiveStartDate< t.newActiveStartDate
--							--	and p.ActiveLastDate<=t.newactivelastdate
							
--				   --         INSERT INTO [DataTrue_Main].[dbo].[ProductPrices]
--							--		   ([ProductPriceTypeID]
--							--		   ,[ProductID]
--							--		   ,[ChainID]
--							--		   ,[StoreID]
--							--		   ,[BrandID]
--							--		   ,[SupplierID]
--							--		   ,[UnitPrice]
--							--		   ,[UnitRetail]
--							--		   ,[PricePriority]
--							--		   ,[ActiveStartDate]
--							--		   ,[ActiveLastDate]
--							--		   ,[PriceReportedToRetailerDate]
--							--		   ,[DateTimeCreated]
--							--		   ,[LastUpdateUserID]
--							--		   ,[BaseCost]
--							--		   ,[Allowance]
--							--		   ,[NewActiveStartDateNeeded]
--							--		   ,[NewActiveLastDateNeeded]
--							--		   ,[OldStartDate]
--							--		   ,[OldEndDate])
--							--SELECT p.ProductPriceTypeID
--							--	  ,p.ProductID
--							--	  ,p.ChainID
--							--	  ,p.StoreID
--							--	  ,p.BrandID
--							--	  ,p.SupplierID
--							--	  ,p.UnitPrice
--							--	  ,p.UnitRetail
--							--	  ,p.PricePriority
--							--	  ,p.ActiveLastDate
--							--	  ,p.ActiveLastDate
--							--	  ,p.PriceReportedToRetailerDate
--							--	  ,GETDATE()
--							--	 ,02102015
--							--	  ,p.BaseCost
--							--	  ,p.Allowance
--							--	  ,p.NewActiveStartDateNeeded
--							--	  ,p.NewActiveLastDateNeeded
--							--	  ,p.ActiveStartDate
--							--	  ,p.ActiveLastDate								  
--							--	  --select*
								  
--							--  FROM ProductPrices p
							 
--							--  inner join ZZtemp_ppr_delete	z
--							-- on z.productpriceid=p.productpriceid
							  		
						
					
--				       end


--/*****************find PP records which are not in MR*********************************/


--select  maxMR,storeid,productid,chainid,supplierid,MaintenanceRequestID,StartDateTime 
--				into ZZtemp_MRS_set_dupPP_0203
--				from 
--				(select MAX(m.MaintenanceRequestId)  OVER (PARTITION BY s.storeid,m.productid,m.chainid ) as maxMR,s.storeid,m.productid,m.chainid,m.supplierid,m.MaintenanceRequestID,StartDateTime 
--				from MaintenanceRequests m
--				inner join MaintenanceRequestStores s
--				on m.MaintenanceRequestID=s.MaintenanceRequestID
--				inner join zztemp_ProductPrices_dupenddate_20150203 z				
--				on  z.storeid=s.StoreID
--		  	    and z.productid=m.productid
--			    and z.ChainID=m.chainid
--			    and RequestStatus=5
--		   		)a
--				where maxMR=MaintenanceRequestID	
				


--	select  p.ProductPriceID,p.storeid,p.productid,p.chainid,p.supplierid,p.activestartdate,p.ActiveLastDate,p.ProductPriceTypeID ,z.StartDateTime 
--	into zztemp_PRODUCTPRICE_fix_0203
--	from 
--			ProductPrices p
--			inner join 
--			(
--			select  p.storeid,p.productid,p.chainid,p.supplierid,unitprice,cast(activestartdate as date) activestartdate
--			from zztemp_ProductPrices_dupenddate_20150203 z
--			inner join productprices p
--			on  p.storeid=z.StoreID
--			and p.productid=z.productid
--			and ProductPriceTypeID=3
			
--			except
--			select  distinct s.storeid,m.productid,m.chainid,m.supplierid,m.cost,cast(m.startdatetime as date)
--			from MaintenanceRequests m
--			inner join MaintenanceRequestStores s
--			on s.MaintenanceRequestID=m.MaintenanceRequestID
--			inner join ZZtemp_MRS_set_dupPP_0203 z
--			on  s.storeid=z.StoreID
--			and m.productid=z.productid
--			and m.ChainID=z.chainid
--			and RequestTypeID in (1,2,15)
--			and RequestStatus=5
			
			
--			)a
		
--		on   a.supplierid=p.supplierid
--			and a.storeid=p.StoreID
--			and a.productid=p.productid
--			and a.ChainID=p.chainid
--			and cast(a.activestartdate as date)=cast(p.ActiveStartDate as date)
--			and a.UnitPrice=p.UnitPrice
--			inner join ZZtemp_MRS_set_dupPP_0203 z
--			on  z.storeid=p.StoreID
--			and z.productid=p.productid
--			and z.ChainID=p.chainid
--			and p.ProductPricetypeID=3
--			and cast(p.ActiveLastDate as date)>cast((z.StartDateTime)-1 as date)
--			order by p.storeid,p.productid  
			
--			--select* into zztemp_productpriceid_02102015 from productprices
--			select* from zztemp_PRODUCTPRICE_fix_0203
			
--			update p set p.ActiveLastDate=z.StartDateTime-1	,LastUpdateUserID=203	
--			--select p.ActiveStartDate,p.ActiveLastDate,z.StartDateTime,p.ProductPricetypeID,p.productid,p.storeid
--			--select p.*			
--			from productprices p
--			inner join zztemp_PRODUCTPRICE_fix_0203 z
--			on z.productpriceid=p.productpriceid
--			and p.ActiveStartDate<z.StartDateTime
--			and p.ActiveLastDate>=z.StartDateTime
		
		
--		    select p.*into zztemp_DELETE_PB_02112015	
--			from productprices p
--			inner join zztemp_PRODUCTPRICE_fix_0203 z
--			on z.productpriceid=p.productpriceid
--			and p.ActiveStartDate>=z.StartDateTime
--			and p.ActiveLastDate>=z.StartDateTime
			
--			select* from zztemp_DELETE_PB_02112015	
			
--		if @@ROWCOUNT>0
--				begin	
						
--		            INSERT INTO [DataTrue_Main].[dbo].[ProductPricesDeleted]
--									   (productpriceid
--									   ,[ProductPriceTypeID]
--									   ,[ProductID]
--									   ,[ChainID]
--									   ,[StoreID]
--									   ,[BrandID]
--									   ,[SupplierID]
--									   ,[UnitPrice]
--									   ,[UnitRetail]
--									   ,[PricePriority]
--									   ,[ActiveStartDate]
--									   ,[ActiveLastDate]
--									   ,[PriceReportedToRetailerDate]
--									   ,[DateTimeCreated]
--									   ,DateTimeLastUpdate
--									   ,[LastUpdateUserID]
--									   ,[BaseCost]
--									   ,[Allowance]
--									   ,[NewActiveStartDateNeeded]
--									   ,[NewActiveLastDateNeeded]
--									   ,[OldStartDate]
--									   ,[OldEndDate])
--							SELECT p.productpriceid,
--							      p.ProductPriceTypeID
--								  ,p.ProductID
--								  ,p.ChainID
--								  ,p.StoreID
--								  ,p.BrandID
--								  ,p.SupplierID
--								  ,p.UnitPrice
--								  ,p.UnitRetail
--								  ,p.PricePriority
--								  ,p.ActiveLastDate
--								  ,p.ActiveLastDate
--								  ,p.PriceReportedToRetailerDate
--								  ,GETDATE()
--								  ,GETDATE()
--								 ,02102015
--								  ,p.BaseCost
--								  ,p.Allowance
--								  ,p.NewActiveStartDateNeeded
--								  ,p.NewActiveLastDateNeeded
--								  ,p.ActiveStartDate
--								  ,p.ActiveLastDate
								  
--								  --select p.*								
--							  FROM ProductPrices p							
--							  inner join zztemp_DELETE_PB_02112015 z
--							 on z.productpriceid=p.productpriceid
							 
--							 delete p
--							  FROM ProductPrices p							
--							  inner join zztemp_DELETE_PB_02112015 z
--							 on z.productpriceid=p.productpriceid
--			 end
								
	
						
--			select p.*			
--			from productprices p			
--			where p.ChainID=40393
--			and ProductPriceTypeID=3
--			--and  p.StoreID in(40457,40458,40459,40460,40461,40462,40463,40464,40465,40466,40467,40467) 
--			and productid in (10750)
--			--and ActiveLastDate='2099-12-31 00:00:00.000'
--			order by p.storeid,p.productid,activelastdate
			
			
--                 select* from zztemp_PRODUCTPRICE_fix_0203 	where 1=1 and StoreID in (41033,41139,41050,41091)
--                 and productid=5674	order by storeid,productid,activelastdate
                 
--                 select* from MaintenanceRequests m
--                 inner join MaintenanceRequestStores s
--                 on m.MaintenanceRequestID=s.MaintenanceRequestID
--                 and productid=18600 and StoreID=41091
                 
--                 select* from productprices where 	ProductID=18600 and StoreID in (40457,40458,40459,41091) and ProductPriceTypeID=3
--		order by storeid,productid,activelastdate
     
   IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='ZZtemp_MRS_set_dupPP_0203') 
                  drop table ZZtemp_MRS_set_dupPP_0203        
      
IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='zztemp_PRODUCTPRICE_fix_NSP') 
                  drop table zztemp_PRODUCTPRICE_fix_NSP


IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='zztemp_PRODUCTPRICE_fix_NSP') 
                  drop table zztemp_PRODUCTPRICE_fix_NSP
            

            IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='zztemp_productprices_fix_ActiveLastDate2_NP') 
                  drop table zztemp_productprices_fix_ActiveLastDate2_NP
                  
                  


return
GO
