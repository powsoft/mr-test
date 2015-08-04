USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMRProcess_AllMRStoresRecords_fix_storesetup_activelastdate_20150205_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMRProcess_AllMRStoresRecords_fix_storesetup_activelastdate_20150205_PRESYNC_20150329]
as

                drop table ZZtemp_STORESETUP_notactive	
				drop table ZZtemp_Productprice_active	
				drop table ZZtemp_MR_since_01012015
				
				select* into ZZtemp_storesetup_backup_20150205
				from storesetup
				
			 --   drop table ZZtemp_storesetup_test_20150205
			    	    
				--select* into ZZtemp_storesetup_test_20150205
				--from storesetup
				
				select maxMR,storeid,productid,chainid,supplierid,MaintenanceRequestID,StartDateTime,EndDateTime 
				into ZZtemp_MR_since_01012015
				from 
				(select MAX(m.MaintenanceRequestID)  OVER (PARTITION BY storeid,productid,chainid ) as maxMR,storeid,productid,chainid,supplierid,m.MaintenanceRequestID,StartDateTime,EndDateTime
				from MaintenanceRequests m
				inner join MaintenanceRequestStores s
				on m.MaintenanceRequestID=s.MaintenanceRequestID
				 and Supplierid<> 41440
				 and (bipad is NOT null or PDIParticipant=0)
				 and RequestTypeID in (1,2)
				 and m.datetimecreated>  GETDATE()-1000
				 and RequestStatus=5
				)a
				where maxMR=MaintenanceRequestID
				
				select maxSTID,storeid,productid,chainid,supplierid,StoreSetupID,ActiveLastDate,ActiveStartDate into ZZtemp_STORESETUP_notactive
				from 
				(select MAX(StoreSetupID)  OVER (PARTITION BY storeid,productid,chainid,supplierid ) as maxSTID,storeid,productid,chainid,supplierid,StoreSetupID,ActiveLastDate,ActiveStartDate
				from storesetup where  Supplierid<> 41440
				)a
				where maxSTID=StoreSetupID		
				and ActiveLastDate< '2020-01-01'
				
				
						
				select maxPD,storeid,productid,chainid,supplierid,productpriceID,ActiveLastDate,ActiveStartDate into ZZtemp_Productprice_active
				from 
				(select MAX(productpriceID)  OVER (PARTITION BY storeid,productid,chainid,supplierid ) as maxPD,storeid,productid,chainid,supplierid,productpriceID,ActiveLastDate,ActiveStartDate
				from productprices where ProductPriceTypeID=3 and Supplierid<> 41440
				)a
				where maxPD=productpriceID	
				and 	ActiveLastDate>'2020-01-01'		
				
				drop table zztemp_storesetup_incorrect_notactive		
				
				
				select s.storeid,s.productid,s.chainid,s.supplierid,productpriceID,StoreSetupID,s.ActiveLastDate storelastdate,p.ActiveLastDate 
				into zztemp_storesetup_incorrect_notactive
				from ZZtemp_STORESETUP_notactive s
				inner join ZZtemp_Productprice_active p
				on p.ProductID=s.ProductID
				and p.StoreID=s.storeid
				and p.ChainID=s.chainid
				and p.SupplierID=s.SupplierID
				and CAST(p.ActiveLastDate as date)>CAST(s.ActiveLastDate as date)			
				order by s.ActiveLastDate desc
				
				select* from zztemp_storesetup_incorrect_notactive order by storelastdate desc,StoreSetupID 			
								
						    
			    drop table zztemp_storesetup_notactive_tocorrect
					
				select s.storeid,s.productid,s.chainid,s.supplierid,productpriceID,StoreSetupID,s.ActiveLastDate storelastdate,p.ActiveLastDate 
				into zztemp_storesetup_notactive_tocorrect
				from ZZtemp_STORESETUP_notactive s
				inner join ZZtemp_Productprice_active p
				on p.ProductID=s.ProductID
				and p.StoreID=s.storeid
				and p.ChainID=s.chainid
				and p.SupplierID=s.SupplierID
				inner join ZZtemp_MR_since_01012015 m
				on m.ProductID=s.ProductID
				and m.StoreID=s.storeid
				and m.ChainID=s.chainid
				and m.SupplierID=s.SupplierID
				and CAST(p.ActiveLastDate as date)>CAST(s.ActiveLastDate as date)
				order by s.ActiveLastDate
			
				--select* from ZZtemp_MR_since_01012015 
				--where 	StoreID=78608 and productid=3539901
				
				--select*from  ZZtemp_STORESETUP_notactive
				--where 	StoreID=78608 and productid=3539901
				
				--select*from  ZZtemp_STORESETUP_notactive_tocorrect
				--where 	StoreID=78608 and productid=3539901
				
				--select*from  ZZtemp_Productprice_active
				--where 	StoreID=78608 and productid=3539901
				
				select s.* into zztemp_fixed_storesetup_records_20150209
		
				from storesetup s
				inner join zztemp_storesetup_notactive_tocorrect z
				on s.storesetupid=z.StoreSetupID
				inner join ZZtemp_MR_since_01012015 m
				on m.ProductID=s.ProductID
				and m.StoreID=s.storeid
				and m.ChainID=s.chainid
				and m.SupplierID=s.SupplierID
				and CAST(m.EndDateTime  as date)>CAST(s.ActiveLastDate as date)
			
				
			
				update s set ActiveLastDate=z.ActiveLastDate
				from storesetup s
				inner join zztemp_storesetup_notactive_tocorrect z
				on s.storesetupid=z.StoreSetupID
				inner join ZZtemp_MR_since_01012015 m
				on m.ProductID=s.ProductID
				and m.StoreID=s.storeid
				and m.ChainID=s.chainid
				and m.SupplierID=s.SupplierID
				and CAST(m.EndDateTime  as date)>CAST(s.ActiveLastDate as date)
			
return
GO
