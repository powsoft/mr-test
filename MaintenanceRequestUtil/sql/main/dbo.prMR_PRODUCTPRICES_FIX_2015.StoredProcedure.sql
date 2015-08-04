USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMR_PRODUCTPRICES_FIX_2015]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMR_PRODUCTPRICES_FIX_2015]
as

declare @rec cursor
DECLARE @badrecids varchar(max)=''
DECLARE @ActivestartDate DATETIME
DECLARE @endDate DATETIME
DECLARE @startDate DATETIME
DECLARE @ActiveLastDate DATETIME
DECLARE @chainid int
DECLARE @SupplierID int
DECLARE @Storeid int
DECLARE @productid int

DECLARE @productpriceid int
DECLARE @Subject VARCHAR(MAX)=''

declare @rec1 cursor
 
 IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='ZZtemp_MRS_set_no_dup') 
                  drop table ZZtemp_MRS_set_no_dup                            
 
begin 

--drop table ZZtemp_PP_set_dup
select  COUNT(*) cnt,p.storeid,p.productid,p.chainid into ZZtemp_PP_set_dup
             from
			 productprices p	with(nolock)
			 inner join chains c
			 on c.ChainID=p.chainid
			 and c.PDITradingPartner=0
			where  cast(p.ActiveLastDate as date)='2099-12-31'
			and ProductPriceTypeID=3
			group by p.storeid,p.productid,p.chainid
			having COUNT(*)>1
			
			--select  *
   --          from
			-- productprices p	with(nolock)
			 
			--where  cast(p.ActiveLastDate as date)='2099-12-31'
			--and ProductPriceTypeID=3
			--and StoreID=69717
			--and ProductID=38913
			--and ChainID=60626

--drop table ZZtemp_MRS_set_no_dup2

				select  maxMR,storeid,productid,chainid,supplierid,MaintenanceRequestID,StartDateTime 
				into ZZtemp_MRS_set_no_dup2
				from 
				(select MAX(m.MaintenanceRequestId)  OVER (PARTITION BY s.storeid,m.productid,m.chainid,supplierid ) as maxMR,s.storeid,m.productid,m.chainid,supplierid,m.MaintenanceRequestID,StartDateTime 
				from MaintenanceRequests  m
				inner join MaintenanceRequestStores s
				on m.MaintenanceRequestID=s.MaintenanceRequestID
				inner join ZZtemp_PP_set_dup z
				on z.ProductId=m.productid
				and m.ChainID=z.chainid
				and z.StoreID=s.StoreID
				and RequestTypeID<>3
				and Bipad is null 
                and PDIParticipant=0
				)a
				where maxMR=MaintenanceRequestID			
				
				
--drop table zztemp_PRODUCTPRICE_fix2				
select  p.ProductPriceID,p.storeid,p.productid,p.chainid,p.supplierid,p.activestartdate,p.ActiveLastDate ,z.startdatetime,p.ProductPriceTypeID  
into zztemp_PRODUCTPRICE_fix2
from 
			ProductPrices p
			inner join 
			(
			select  p.storeid,p.productid,p.chainid,p.supplierid,unitprice,cast(activestartdate as date) activestartdate--,activelastdate
			from ZZtemp_MRS_set_no_dup2 z
			inner join productprices p	with(nolock)
			on p.storeid=z.StoreID
			--and  p.supplierid=z.supplierid
		     and p.ChainID=z.chainid
			and p.productid=z.productid
			and ProductPriceTypeID=3
			and cast(p.ActiveLastDate as date)='2099-12-31'
			--and p.productid = 39546
           -- and p.storeid = 44345
			except
			select  distinct s.storeid,m.productid,m.chainid,m.supplierid,m.cost,cast(m.startdatetime as date)
			from MaintenanceRequests m
			inner join MaintenanceRequestStores s
			on s.MaintenanceRequestID=m.MaintenanceRequestID
			inner join ZZtemp_MRS_set_no_dup2 z
			on m.supplierid=z.supplierid
			and s.storeid=z.StoreID
			and m.productid=z.productid
			and m.ChainID=z.chainid
			and RequestTypeID <>3)a
		
		on   a.supplierid=p.supplierid
			and a.storeid=p.StoreID
			and a.productid=p.productid
			and a.ChainID=p.chainid
			and cast(a.activestartdate as date)=cast(p.ActiveStartDate as date)
			and a.UnitPrice=p.UnitPrice
			inner join ZZtemp_MRS_set_no_dup2 z
			on  z.storeid=p.StoreID
			--and z.supplierid=p.supplierid
			and z.productid=p.productid
			and z.ChainID=p.chainid
			and p.ProductPricetypeID=3
			and cast(p.ActiveLastDate as date)>cast((z.StartDateTime-1) as date)
			order by p.storeid,p.productid  
			
			
			update p set p.ActiveLastDate=z.StartDateTime-1	,OldEndDate=p.ActiveLastDate	
			--select p.ActiveStartDate,p.ActiveLastDate,z.StartDateTime,p.ProductPricetypeID,*			
			from productprices p
			inner join zztemp_PRODUCTPRICE_fix2 z
			on z.productpriceid=p.productpriceid
			and cast(p.ActiveLastDate as date)>cast((z.StartDateTime-1) as date)
			
			select* from zztemp_PRODUCTPRICE_fix2
			where StoreID=51031
			and ProductID=3495030
			and ChainID=50964

			
		select* from productprices
		where 1=1
		and cast(ActiveLastDate as date)='2099-12-31'
		and storeid = 78457 
		and ProductID in (3506011,3524726,3524727,3524728,3524765,3524766,3524767,3524768,3524769,3524795,3524796,3524797,3524799,3524800,3534957,3534958,3536376,3536377,3536378,
		3536401,3536402,3536409,3536410,3536411,3536412,3536421,3536422,3536423,3536441,3536463,3536477,3536488,
		3536489,3536768,3536769,3536949,3536950)
		order  by productid,activestartdate
			
			select *
from maintenancerequests r
inner join maintenancerequeststores s
on r.maintenancerequestid = s.maintenancerequestid
and productid = 38883	
and storeid = 40996

			
			drop table ZZtemp_MRS_set_no_dup2
            drop table zztemp_PRODUCTPRICE_fix2




			
  drop table ZZtemp_MRS_set_no_dup

return
end
GO
