USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_FIX_PRODUCTPRICES_ActiveLastDate_2015_NWSP]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_FIX_PRODUCTPRICES_ActiveLastDate_2015_NWSP]
as

begin 
  

declare @MyID int = 76834

/***********************find wrong Active Last Date***********************/  


/*   find only Authorized product stoeres context for most recent MaintenanceRequestid*/ 
--drop table ZZtemp_products_NO_type9
--drop table ZZtemp_MaintenanceRequests_NO_type9
	
select*	
into ZZtemp_products_NO_type9 from(
/*this selects storeid,productid,supplierid ,chainid, MAX(m.MaintenanceRequestid) for all product stoeres context*/
 select storeid,productid,supplierid ,chainid, MAX(m.MaintenanceRequestid) as MaxMrID 
  from    MaintenanceRequests m with (NOLOCK)
	inner join MaintenanceRequestStores s with (NOLOCK)
	on m.MaintenanceRequestID=s.MaintenanceRequestID 
	and RequestStatus not in (0,1,999)
	and m.SupplierID  in (select SupplierID from SupplierS s where s.PDITradingPartner=0) 
	and RequestTypeID in (1,2)
	group by storeid,productid,supplierid ,chainid
except	
/*this selects storeid,productid,supplierid ,chainid, MAX(m.MaintenanceRequestid) for discontinued product stoeres context*/
	select storeid,productid,supplierid ,chainid, MAX(m.MaintenanceRequestid) as MaxMrID 
     from    MaintenanceRequests m with (NOLOCK)
	inner join MaintenanceRequestStores s with (NOLOCK)
	on m.MaintenanceRequestID=s.MaintenanceRequestID 
	and requesttypeid =9
	and m.SupplierID  in (select SupplierID from SupplierS s where s.PDITradingPartner=0) 
	and datatrue_edi_costs_recordid is not null
	group by storeid,productid,supplierid ,chainid) a




/*   find all MaintenanceRequest/MaintenanceRequestStores records for Authorized product stoeres context  */ 	
	
select	s.storeid,m.* into ZZtemp_MaintenanceRequests_NO_type9
       from    MaintenanceRequests m with (NOLOCK)
	inner join MaintenanceRequestStores s with (NOLOCK)
	on m.MaintenanceRequestID=s.MaintenanceRequestID 
	inner join ZZtemp_products_NO_type9 g with (NOLOCK)
	on m.productid=g.productid  
	and m.supplierid=g.supplierid
	and m.chainid=g.chainid
	and s.storeid=g.storeid
	and RequestTypeID in (1,2)
	and RequestStatus not in (0,1,999)
	and cast(m.DateTimeCreated as date)>'2012-06-01' 
	and startdatetime <'2025-12-31 00:00:00.000'

	
	
/* finding MAX(m.MaintenanceRequestID) in MR table for eache productpriceid  in productprices for not promotion or PDI case (productpricetypeid=3) */	
	

 
 select max(MaintenanceRequestID) MaintenanceRequestID, productpriceid ,m.productid,m.storeid,m.supplierid,m.chainid,cost UnitPrice,m.startdatetime ActiveStartDate 
 into ZZtemp_MR_productpricerecords
 from ZZtemp_MaintenanceRequests_NO_type9 m with (NOLOCK)
 inner join ProductPrices p with (NOLOCK)
 on cost=unitprice
 and p.productid=m.productid 
 and p.chainid=m.ChainID
 and p.ActiveStartDate=StartDateTime
 and p.StoreID= m.storeid
 and productpricetypeid=3
 and p.supplierid=m.supplierid
 group by productpriceid ,m.productid,m.storeid,m.supplierid,m.chainid,cost ,m.startdatetime 




/* addiding productpriceid,activelastdate to  each row of in_MR_productprices table*/

select distinct MaintenanceRequestID,p.productpriceid, p.productid,p.storeid,p.supplierid,p.chainid,p.UnitPrice,p.ActiveStartDate ,activelastdate 
into ZZtemp_in_MR_productprices
from ProductPrices p with (NOLOCK)
inner join ZZtemp_MR_productpricerecords m
on  p.productpriceid=m.productpriceid

select p2.MaintenanceRequestID newMRID,p1.MaintenanceRequestID oldMRID,p2.productpriceid newproductpriceid,p1.productpriceid oldproductpriceid,
p1.ActiveStartDate oldActiveStartDate,p2.ActiveStartDate newActiveStartDate,p1.activelastdate practivelastdate,
p2.activelastdate newactivelastdate,p1.supplierid oldsupplier,p2.supplierid newsupplier,p2.ChainID,p2.StoreID,p2.ProductID
into ZZtemp_productprices_fix_ActiveLastDate2test
from ZZtemp_in_MR_productprices p1 with (nolock)
inner join ZZtemp_in_MR_productprices p2 with (nolock)
on p1.productid = p2.productid
and p1.chainid=p2.chainid
and p1.storeid = p2.storeid
and ((p2.MaintenanceRequestID>p1.MaintenanceRequestID ) and p1.ActiveLastDate >= p2.ActiveStartDate )
--and p2.ActiveStartDate>'2011-01-01'
order by p2.storeid



/*********updating ActiveLastDate for older record**********/
update p set p.activelastdate= t.newActiveStartDate-1,LastUpdateUserID=76834,--@MyID
DateTimeLastUpdate=GETDATE()
--select t.*
from ProductPrices p 
inner join ZZtemp_productprices_fix_ActiveLastDate2test t
on  p.ProductPriceID = t.oldproductpriceid


/*********setting ActiveLastDate to '2099-12-31 00:00:00.000' for the most recent records **********/
 
update ProductPrices set ActiveLastDate='2099-12-31 00:00:00.000',LastUpdateUserID=76834,
DateTimeLastUpdate=GETDATE()
where productpriceid in(select productpriceid
--select productpriceid ,LatestMRID, ActiveStartDate ,activelastdate,StoreID,productid,chainid
from (select p.productpriceid ,newMRID,MAX( newMRID) OVER (PARTITION BY p.StoreID,p.productid,p.chainid  ) as LatestMRID,
p.StoreID,p.productid,p.chainid ,p.ActiveStartDate ,p.activelastdate
  from ProductPrices p  
  inner join ZZtemp_productprices_fix_ActiveLastDate2test t
on  p.ProductPriceID = t.newproductpriceid and p.ProductPriceTypeID =3   
  
 )a  where newMRID=LatestMRID  and   ActiveLastDate<'2099-12-31 00:00:00.000'
 )
 -- select count(*) cnt,productid,Supplierid,chainid,storeid into zztemp_single_ProductPrices  
 -- from ProductPrices p
  
 -- group by productid,Supplierid,chainid,storeid
 -- having COUNT(*)=1
  
  
 -- select p.* 
 ---- update p set   ActiveLastDate='2099-12-31 00:00:00.000'
 -- from ZZtemp_in_MR_productprices p with (nolock)
 -- inner join zztemp_single_ProductPrices z
 -- on z.ChainID=p.ChainID
 -- and z.SupplierID=p.SupplierID
 -- and z.StoreID=p.StoreID
 -- and p.ProductID=z.ProductID
 -- inner join ZZtemp_products_NO_type9 n
 -- on n.ChainID=p.ChainID
 -- and n.SupplierID=p.SupplierID
 -- and n.StoreID=p.StoreID
 -- and p.ProductID=n.ProductID
 -- and ActiveLastDate<'2099-12-31 00:00:00.000'
  
  --and p.SupplierID=78692
  --order by ProductID,StoreID,ActiveStartDate
drop table ZZtemp_productprices_fix_ActiveLastDate2test
drop table ZZtemp_in_MR_productprices
drop table ZZtemp_MR_productpricerecords
drop table ZZtemp_products_NO_type9
drop table ZZtemp_MaintenanceRequests_NO_type9








    
return
end
GO
