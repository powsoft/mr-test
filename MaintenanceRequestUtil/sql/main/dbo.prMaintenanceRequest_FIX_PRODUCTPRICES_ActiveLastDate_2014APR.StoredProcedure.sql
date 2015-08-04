USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_FIX_PRODUCTPRICES_ActiveLastDate_2014APR]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[prMaintenanceRequest_FIX_PRODUCTPRICES_ActiveLastDate_2014APR]
as





begin 
  
--select *
--from maintenancerequests
--where productid  in (5187,15571,5498,21638)

--and requeststatus = 5
--and chainid = 40393
--order by datetimecreated desc


--select *
--from productprices
--where 1 = 1
--and storeid in (41974,41021,41112,41121)
--and chainid = 40393
--and productid in (5187,15571,5498,21638)
--order by storeid, productid

/****** all records from product price table where moved to 
 select*into zztemp_ProductPrices_Updated_20140527 from ProductPrices
****/

/***********************find wrong Active Last Date***********************/  


select*into temp_productprices_fix_ActiveLastDate
from (

select 
max(p1.ActiveStartDate) prActiveStartDate,min(p2.ActiveStartDate) newActiveStartDate,p1.activelastdate,p1.brandid,p1.supplierid oldsupplier,p2.supplierid newsupplier,p2.ChainID,p2.StoreID,p2.ProductID,p2.productpricetypeid
from productprices p1 with (nolock)
inner join productprices p2 with (nolock)
on p1.productid = p2.productid
and p1.chainid=p2.chainid
and p1.storeid = p2.storeid
and p1.brandid=p2.brandid
and p1.productpricetypeid = p2.productpricetypeid
and p1.SupplierID<>p2.SupplierID
and (p1.ActiveStartDate < p2.ActiveStartDate and p1.ActiveLastDate >= p2.ActiveStartDate )
--and p1.storeid in (41974,41021,41112,41121)
--and p1.chainid = 40393
--and p1.productid in (5187,15571,5498,21638)
group by p1.brandid, p2.ChainID,p2.StoreID,p2.ProductID,p2.productpricetypeid,p2.supplierid,p1.ChainID,
p1.StoreID,p1.ProductID,p1.productpricetypeid,p1.activelastdate,p1.supplierid
) a

/** insert records from privious query for future check **/
if @@ROWCOUNT >0
insert into ProductPrices_updated_for_new_supplier_actdate
                                            (ProductPriceTypeID	
	                                          ,ProductID
											   ,ChainID
											   ,StoreID
											   ,BrandID
											   ,SupplierID											   
											   ,ActiveStartDate
											   ,ActiveLastDate											   
											   ,Dateinsert
											   )
											    				
					         Select		                
					                           ProductPriceTypeID	
	                                          ,ProductID
											   ,ChainID
											   ,StoreID
											   ,BrandID
											   ,oldSupplier
											   ,prActiveStartDate
											   ,ActiveLastDate
											   
											   ,getdate()
									from temp_productprices_fix_ActiveLastDate

update p set p.activelastdate= t.newActiveStartDate-1
from productprices p 
inner join temp_productprices_fix_ActiveLastDate t 
on  p.storeid = t.storeid
and p.productid = t.productid
and p.chainid=t.chainid
and p.productpricetypeid = t.productpricetypeid
and p.SupplierID=t.oldSupplier
and p.BrandID=t.brandid
and (p.ActiveStartDate = prActiveStartDate and p.ActiveLastDate = t.ActiveLastDate )

/*** chack after update******/
--select* from temp_productprices_fix_ActiveLastDate
--where  storeid in (41974,41021,41112,41121)
--and chainid = 40393
--and productid in (5187)--,15571,5498,21638)
--order by productid,storeid

--select* from productprices
--where  storeid in (41974,41021,41112,41121)
--and chainid = 40393
--and productid in (5187)--,15571,5498,21638)
--order by productid,storeid

drop table temp_productprices_fix_ActiveLastDate

    
return
end
GO
