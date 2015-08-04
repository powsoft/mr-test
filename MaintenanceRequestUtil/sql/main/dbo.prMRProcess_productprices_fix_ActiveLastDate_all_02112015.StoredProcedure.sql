USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMRProcess_productprices_fix_ActiveLastDate_all_02112015]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMRProcess_productprices_fix_ActiveLastDate_all_02112015]
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
DECLARE @chainid varchar(8)=''
DECLARE @chainname varchar(60)=''
DECLARE @SupplierID varchar(8)=''
DECLARE @suppliername varchar(60)=''
DECLARE @Storenumber varchar(8)=''

			

/*************************************/
IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='zztemp_dup_PRPR_records_02102015') 
                  drop table zztemp_dup_PRPR_records_02102015
                  
 IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='zztemp_ProductPrices_dupenddate_20150203') 
                  drop table zztemp_ProductPrices_dupenddate_20150203
                  
  IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='zztemp_MR_productprices_NP_02032015') 
                  drop table zztemp_MR_productprices_NP_02032015  
                  
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
                  AND TABLE_NAME='ZZtemp_MRS_set_dupPP_0203') 
                  drop table ZZtemp_MRS_set_dupPP_0203   
                                   
 IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='zztemp_PP_delete_extra_0310') 
                  drop table zztemp_PP_delete_extra_0310  
                    
 IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='zztemp_PRODUCTPRICE_fix_0203')    
                  drop table zztemp_PRODUCTPRICE_fix_0203   
        

                                    
 IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='zztemp_productprices_fix_ActiveLastDate_NP_2015') 
                  drop table zztemp_productprices_fix_ActiveLastDate_NP_2015 
                                    
 IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='zztemp_MR_productprices_NP_02032015') 
                  drop table zztemp_MR_productprices_NP_02032015  
                                    
 IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='zztemp_MR') 
                  drop table zztemp_MR_productprices_NP_02032015                

/***********************delete full PP duplicates**************************/


select * into zztemp_dup_PRPR_records_02102015
from(
select min(productpriceid) OVER (PARTITION BY p.StoreID,p.productid,p.chainid,supplierid,unitprice,cast(activestartdate as date),cast(activelastdate as date)   ) as minproductpriceid,p.productpriceid,p.StoreID,p.productid,p.chainid,supplierid,unitprice,cast(activestartdate as date) startdt,cast(activelastdate as date) lastdt
from productprices p where ProductPriceTypeID=3 and SupplierPackageID is null)a
where productpriceid<>minproductpriceid


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
									   ,[BaseCost]
									   ,[Allowance]
									   ,[NewActiveStartDateNeeded]
									   ,[NewActiveLastDateNeeded]
									   ,[OldStartDate]
									   ,[OldEndDate]
									    ,DateTimeLastUpdate
									   )
							SELECT p.productpriceid
							      ,p.ProductPriceTypeID
								  ,p.ProductID
								  ,p.ChainID
								  ,p.StoreID
								  ,p.BrandID
								  ,p.SupplierID
								  ,p.UnitPrice
								  ,p.UnitRetail
								  ,p.PricePriority
								  ,p.ActiveLastDate
								  ,p.ActiveLastDate
								  ,p.PriceReportedToRetailerDate
								  ,GETDATE()
								 ,02102015
								  ,p.BaseCost
								  ,p.Allowance
								  ,p.NewActiveStartDateNeeded
								  ,p.NewActiveLastDateNeeded
								  ,p.ActiveStartDate
								  ,p.ActiveLastDate
								  ,p.DateTimeLastUpdate
								
								  --select p.*								
							  FROM ProductPrices p							
							  inner join zztemp_dup_PRPR_records_02102015	z
							 on z.productpriceid=p.productpriceid
							 
							 delete p
							  FROM ProductPrices p							
							  inner join zztemp_dup_PRPR_records_02102015	z
							 on z.productpriceid=p.productpriceid
/**********************find duplicates ActiveLast date by store and product*************************/
select COUNT(*) cnt, p1.chainid,p1.ProductID,storeid, cast(p1.ActiveLastDate as date)ActiveLastDate
into zztemp_ProductPrices_dupenddate_20150203
from productprices p1 with (nolock)
where p1.SupplierPackageID is null
and p1.ProductPriceTypeID=3
and cast(p1.activelastdate as date) = '12/31/2099'
group by p1.chainid,p1.ProductID,storeid, p1.ActiveLastDate
having count(*)>1
order by p1.storeid, p1.productid



/**********************find duplicates ActiveLast date*************************/


select  distinct p1.supplierid, p1.productid, p1.storeid, p2.chainid 
into zztemp_ProductPrices_dupenddate_20150202
from productprices p1 with (nolock)
inner join productprices p2 with (nolock)
on p1.storeid = p2.storeid
and p1.productid = p2.productid
and p1.productpricetypeid = p2.productpricetypeid
and p1.productpricetypeid = 3
and p1.productpriceid <> p2.productpriceid
and cast(p1.activelastdate as date) = cast(p2.activelastdate as date)
and cast(p1.activelastdate as date) = '12/31/2099'
and p1.SupplierPackageID is null
and p2.SupplierPackageID is null
where (p1.UnitPrice <> p2.UnitPrice or p1.supplierid <> p2.supplierid or cast(p1.activestartdate as date)<> cast(p2.activestartdate as date))
and p1.productid in (select productid from productidentifiers where productidentifiertypeid = 2)



/****************************in MR*****************************************/
   --drop table zztemp_MR_productprices_NP_02032015 
   


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
				and mr.RequestTypeID in (1,2,15)
	            and (PDIParticipant=0 or isnull(Bipad ,'N')<>'N')	        
				group by  p.productid,productpriceid ,p.storeid,p.supplierid,p.chainid,p.UnitPrice,p.ActiveStartDate 
				
				
			/********************check MR and productprices*************************	
                select storeid,mr.StartDateTime,EndDateTime,cost,requesttypeid, mr.*
                from
                MaintenanceRequests mr
			    inner join MaintenanceRequestStores s
			    on mr.MaintenanceRequestID=s.MaintenanceRequestID 
				and s.StoreID= 40945				
				and  mr.productid=31018
				and mr.RequestTypeID in (1,2)
				and mr.RequestStatus =5
                order by StoreID,productid,SubmitDateTime
                
                select* from productprices where StoreID=40945 and ProductID in (31018) and ProductPriceTypeID=3 and SupplierPackageID is null
                order by StoreID,productid,ActiveLastDate

                select* from ProductPricesDeleted where StoreID=40945 and ProductID in 
                (31018) and ProductPriceTypeID=3 and SupplierPackageID is null
                 order by StoreID,productid,ActiveLastDate
				
				select* from zztemp_ProductPrices_dupenddate_20150203 
				where StoreID=40945 and ProductID in (31018)
                 *********************************/
                 
                 
				select distinct MaintenanceRequestID,p.productpriceid, p.productid,p.storeid,p.supplierid,p.chainid,p.UnitPrice,p.ActiveStartDate ,activelastdate 
				into zztemp_in_MR_productprices2_NP_0203
				from ProductPrices p with (NOLOCK)
				inner join zztemp_MR_productprices_NP_02032015   m
				on  p.productpriceid=m.productpriceid	
				
		
                --select* from zztemp_in_MR_productprices2_NP_0203 where StoreID=40945 and ProductID in (31018)
				
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
				

			
				
	if @@ROWCOUNT>0
	begin	
				update p set p.activelastdate= t.newActiveStartDate-1,LastUpdateUserID=02102015,DateTimeLastUpdate=GETDATE()
				--select newMRID,oldMRID,newproductpriceid,oldproductpriceid,newactivestartdate,newactivelastdate, p.*
				from ProductPrices p 
				inner join zztemp_productprices_fix_ActiveLastDate_NP_2015 t
				on  p.ProductPriceID = t.oldproductpriceid
				and p.activestartdate<t.newActiveStartDate
				and p.ActiveLastDate>t.newActiveStartDate-1



				-- select* from MaintenanceRequests m
				-- inner join MaintenanceRequestStores s
				-- on m.MaintenanceRequestID=s.MaintenanceRequestID
				-- where productid=27707 --and chainid=42491	 
				-- and  StoreID=41224
				-- and RequestStatus=5
				-- order by m.MaintenanceRequestID



				--select* from productprices where productid=5811 --and chainid=42491
				--   and StoreID in (41224,41225,41226,41227)
				--order by storeid,ActiveLastDate

			   /********************************extra condition*****************/
								update p set activelastdate=newactivestartdate-1
								from productprices p
								inner join zztemp_productprices_fix_ActiveLastDate_NP_2015 t
								on	p.productid=t.productid
								and p.StoreID=t.storeid
								and cast(p.ActiveLastDate as date)=cast(t.oldActivestartDate-1 as date)
			   
				            				

								--drop table zztemp_PP_delete_extra_0310
								select ProductPriceID into zztemp_PP_delete_extra_0310
								from ProductPrices p 
								inner join zztemp_productprices_fix_ActiveLastDate_NP_2015 t
								on  p.ProductPriceID = t.oldproductpriceid
								and p.ActiveStartDate>= t.newActiveStartDate
								and p.ActiveLastDate<=t.newactivelastdate
								
---					if @@ROWCOUNT>0
--				    begin				
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
							 
--							 end
								
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
					            

							  		
						
					
				       end


/*****************find PP records which are not in MR*********************************/


--drop table ZZtemp_MRS_set_dupPP_0203


select  maxMR,storeid,productid,chainid,supplierid,MaintenanceRequestID,StartDateTime 
				into ZZtemp_MRS_set_dupPP_0203 
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
			    and RequestTypeID in (1,2,15)
			    --	and z.ProductID=31018 and z.StoreID=40945 
		   		)a
				where maxMR=MaintenanceRequestID	
				

					
	--drop table zztemp_PRODUCTPRICE_fix_0203

select distinct p.ProductPriceID,p.storeid,p.productid,p.chainid,p.supplierid,p.activestartdate,p.ActiveLastDate,p.ProductPriceTypeID ,z.StartDateTime 
into zztemp_PRODUCTPRICE_fix_0203
from 
			ProductPrices p
			inner join 
			(
			select  p.storeid,p.productid,p.chainid,p.supplierid,unitprice,cast(activestartdate as date) activestartdate
			from ZZtemp_MRS_set_dupPP_0203 z--zztemp_ProductPrices_dupenddate_20150203 z
			inner join productprices p
			on  p.storeid=z.StoreID
			and p.productid=z.productid
			and ProductPriceTypeID=3
			--	and z.ProductID=31018 and z.StoreID=40945 
			
			except
			select  distinct s.storeid,m.productid,m.chainid,m.supplierid,m.cost,cast(m.startdatetime as date)
			from ZZtemp_MRS_set_dupPP_0203 z
			inner 	join MaintenanceRequests m	
			on m.productid=z.productid
			inner join MaintenanceRequestStores s
			on s.MaintenanceRequestID=m.MaintenanceRequestID		
			and s.storeid=z.StoreID		
			and m.ChainID=z.chainid
			--and m.SupplierID= z.SupplierID
			and RequestTypeID in (1,2,15)
			and RequestStatus=5
			--and z.ProductID=31018 and z.StoreID=40945 
			
			
			)a
		
		on   a.supplierid=p.supplierid
			and a.storeid=p.StoreID
			and a.productid=p.productid
			and a.ChainID=p.chainid
			and cast(a.activestartdate as date)=cast(p.ActiveStartDate as date)
			and a.UnitPrice=p.UnitPrice
			inner join ZZtemp_MRS_set_dupPP_0203 z
			on  z.storeid=p.StoreID
			and z.productid=p.productid
			and z.ChainID=p.chainid
			and p.ProductPricetypeID=3
			and cast(p.ActiveLastDate as date) >=cast((z.StartDateTime)-1 as date)
			order by p.storeid,p.productid  
			
--select*from  zztemp_productpriceid_02102015 from productprices
--select* from ZZtemp_MRS_set_dupPP_0203 where StoreID=40945 and ProductID in (31018)
--select* from ZZtemp_MRS_set_dupPP_0203 

--select* from productprices where StoreID=44306 and ProductID in (3494063) and ProductPriceTypeID=3 and SupplierPackageID is null
--order by StoreID,productid,ActiveLastDate		
--select* from zztemp_PRODUCTPRICE_fix_0203 where  StoreID=40945 and ProductID in (31018) 

--select* from zztemp_MR_productprices_NP_02032015 

--select storeid,mr.StartDateTime,EndDateTime,cost,requesttypeid, mr.*
--from
--MaintenanceRequests mr
--inner join MaintenanceRequestStores s
--on mr.MaintenanceRequestID=s.MaintenanceRequestID 
--and s.StoreID= 44306
--and  mr.productid=3494063
----and mr.RequestTypeID in (1,2)
--and mr.RequestStatus =5
--order by StoreID,productid,SubmitDateTime

--select* from productprices where StoreID=41332 and ProductID in (15169) and ProductPriceTypeID=3 and SupplierPackageID is null
--order by StoreID,productid,ActiveLastDate
				
						
--select p.*			
--from productprices p			
--where and p.ChainID=40393
--and ProductPriceTypeID=3
--and storeid=62471
----and  p.StoreID in(40457,40458,40459,40460,40461,40462,40463,40464,40465,40466,40467,40467) 
--and productid in (27707,27853,3480688)
----and ActiveLastDate='2099-12-31 00:00:00.000'
--order by p.storeid,p.productid,activelastdate
			
			
			
			
		
		    update p set p.ActiveLastDate=z.StartDateTime-1	,LastUpdateUserID=203	
			--select p.ActiveStartDate,p.ActiveLastDate,z.StartDateTime,p.ProductPricetypeID,p.productid,p.storeid
			--select z.StartDateTime,p.activelastdate,p.activestartdate,p.*			
			from productprices p
			inner join zztemp_PRODUCTPRICE_fix_0203 z
			on z.productpriceid=p.productpriceid
			and p.ActiveStartDate<z.StartDateTime
			and p.ActiveLastDate>=z.StartDateTime
			
		
		--drop table zztemp_DELETE_PB_02112015
		--select* from zztemp_DELETE_PB_02112015
	
		
		 select t.activestartdate,t.startdatetime,t.activelastdate,p.* 
		                      -- update p set activelastdate=t.StartDateTime-1
								from productprices p
								inner join zztemp_PRODUCTPRICE_fix_0203 t
								on	p.productid=t.productid
								and p.StoreID=t.storeid
								and cast(p.ActiveLastDate as date)<=cast(t.ActivestartDate as date)
								and cast(p.ActivestartDate as date)<>cast(t.startdatetime-1 as date)		
								and p.ProductPriceTypeID=3
								order by p.StoreID,p.ProductID,p.activestartdate
							
			   
--select* from productprices where ProductID=5662 and StoreID=40400 and ProductPriceTypeID=3
--order by activestartdate
--drop table zztemp_DELETE_PB_02112015	

		    select p.*--distinct z.StartDateTime,p.ActiveStartDate,p.ActiveLastDate
		    into zztemp_DELETE_PB_02112015	
			from productprices p
			inner join zztemp_PRODUCTPRICE_fix_0203 z
			on z.productpriceid=p.productpriceid
			and p.ActiveStartDate>=z.StartDateTime
			and p.ActiveLastDate>=z.StartDateTime
			and p.ProductPriceTypeID=3
			
--select* from zztemp_DELETE_PB_02112015	

--select* from productprices where ProductID=19451 and StoreID in (40945,40947,40951,40952,40954,40959)
--order by storeid,ActiveLastDate
			
		if @@ROWCOUNT>0
				begin	
						
		            INSERT INTO [DataTrue_Main].[dbo].[ProductPricesDeleted]
									   (productpriceid
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
									   ,DateTimeLastUpdate
									   ,[LastUpdateUserID]
									   ,[BaseCost]
									   ,[Allowance]
									   ,[NewActiveStartDateNeeded]
									   ,[NewActiveLastDateNeeded]
									   ,[OldStartDate]
									   ,[OldEndDate])
							SELECT p.productpriceid,
							      p.ProductPriceTypeID
								  ,p.ProductID
								  ,p.ChainID
								  ,p.StoreID
								  ,p.BrandID
								  ,p.SupplierID
								  ,p.UnitPrice
								  ,p.UnitRetail
								  ,p.PricePriority
								  ,p.ActiveLastDate
								  ,p.ActiveLastDate
								  ,p.PriceReportedToRetailerDate
								  ,GETDATE()
								  ,GETDATE()
								 ,02102015
								  ,p.BaseCost
								  ,p.Allowance
								  ,p.NewActiveStartDateNeeded
								  ,p.NewActiveLastDateNeeded
								  ,p.ActiveStartDate
								  ,p.ActiveLastDate
								  
								  --select p.*								
							  FROM ProductPrices p							
							  inner join zztemp_DELETE_PB_02112015 z
							 on z.productpriceid=p.productpriceid
							 
							 delete p
							  FROM ProductPrices p							
							  inner join zztemp_DELETE_PB_02112015 z
							 on z.productpriceid=p.productpriceid
			 end
						
     
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
