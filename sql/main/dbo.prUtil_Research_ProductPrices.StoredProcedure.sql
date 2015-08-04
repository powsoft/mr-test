USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Research_ProductPrices]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Research_ProductPrices]
as


/* below are three bimbo promotions one that Bill Harris provided										MarketAreaCodeIdentifier MarketAreaCode
327	BIM                 	2011-12-23 00:00:00.000	2012-01-10 00:00:00.000	01        	20111220215547                	001       	0145      	EA             	BIMBO FOODS INC..                                                               	0743939760000  	DEAL                                              	FARM FRESH                                                                      	0446155450000  	0         	RICH FRSTD CH DONUTS                                                                                	97        	02        	1.97      	EA        	07203000018         	072030000183        	340	249            	IN1117416968140.INT                                                                                 	2011-12-22 10:10:10.713
328	BIM                 	2011-12-23 00:00:00.000	2012-01-10 00:00:00.000	01        	20111220215547                	001       	0145      	EA             	BIMBO FOODS INC..                                                               	0743939760000  	DEAL                                              	FARM FRESH                                                                      	0446155450000  	0         	VARIETY PK DONUT 8P                                                                                 	97        	02        	1.97      	EA        	07203001421         	072030014210        	341	249            	IN1117416968140.INT                                                                                 	2011-12-22 10:10:10.713
329	BIM                 	2011-12-23 00:00:00.000	2012-01-10 00:00:00.000	01        	20111220215547                	001       	0145      	EA             	BIMBO FOODS INC..                                                               	0743939760000  	DEAL                                              	FARM FRESH                                                                      	0446155450000  	0         	RICH FRSTD SPRLD DON                                                                                	97        	02        	1.97      	EA        	07203002083         	072030020839        	342	249            	IN1117416968140.INT                                                                                 	2011-12-22 10:10:10.713
*/
select * from datatrue_edi.dbo.Promotions
where RecordID 
in
(327,
328,
329)

select * from MaintenanceRequestS where PromoAllowance = 1.97

select * from stores where Custom2 = '55676' --=40549


select *
from ProductIdentifiers where IdentifierValue = '072030000183' --=5692

select *
from ProductPrices
where 1 = 1
--and StoreID = 40549
and ProductID = 5692
and ActiveStartDate = '2011-12-23 00:00:00.000'
and ActiveLastDate = '2012-01-10 00:00:00.000'

select * from costzones

select top 100 * from dbo.[Sean-889--UpdateOurRecords]
where 1 = 1
--and StoreID = 40549
and UPC12 = '072030000183'


select *
from ProductPrices p
where SupplierID = 40559
and ProductPriceTypeID = 8
and StoreID in
(select StoreID from CostZoneRelations r inner join CostZones z on r.CostZoneID = z.costzoneid where LTRIM(rtrim(costzonename)) = '321')
and cast(ActiveStartDate as date) < '1/1/2012'
and cast(ActiveLastDate as date) > '12/11/2011'
and ActiveStartDate = '2011-11-27 00:00:00.000'

select * from StoreTransactions
where ProductID in (21085, 21089)


select *
from stores
where StoreID in
(select StoreID from CostZoneRelations r inner join CostZones z on r.CostZoneID = z.costzoneid where LTRIM(rtrim(costzonename)) = '321')




select * into import.dbo.productprices_20111215BeforePromoUpdates from productprices

select *
--update p set UnitPrice = 0.00
from ProductPrices p
where SupplierID = 41342
and cast(activelastdate as date) = '12/1/2012'
and ProductPriceTypeID = 8
order by activelastdate

select * from CostZoneRelations where CostZoneID = 1766

select * 
from costzonerelations zr
inner join ProductPrices p
on zr.StoreID = p.StoreID
and zr.SupplierID = p.SupplierID
where costzoneid = 1766
and ProductPriceTypeID = 8
and ActiveStartDate < '1/1/2012'
and activelastdate > '11/30/2011'


select * into import.dbo.productprices_20111219 from productprices

select * 
--update p set p.UnitPrice = 0.00
from costzonerelations zr
inner join ProductPrices p
on zr.StoreID = p.StoreID
and zr.SupplierID = p.SupplierID
where costzoneid = 1766
and ProductPriceTypeID = 8
--and ProductID = 6021
and cast(ActiveStartDate as date) = '11/27/2011'
--and cast(ActiveLastDate as date) = '12/31/2011'
--and ProductID in (21085, 21089)

select * from StoreTransactions where ProductID in (21085, 21089)

select *
from MaintenanceRequests
where RequestStatus = -33

select *
from MaintenanceRequests
where RequestStatus = 0

select * from ProductIdentifiers where IdentifierValue = '074570651689'--6021 --074570082056'5018 --074570082018'5978 --074570082025'5017 --074570651092' 6006


select *
from ProductPrices
where ProductID = 5582 --6717
and supplierid = 40557
and ProductPriceTypeID = 3
/*
6717
40557
Dec 19 2011 12:00AM
Dec  1 2013 12:00AM
2
Cub Foods




select *
from ProductPrices
where ProductID = 5657
and supplierid = 40559
and ProductPriceTypeID = 8
and storeid =  40840

select *
from MaintenanceRequestStores
where MaintenanceRequestid = 1235


						select *
						from ProductPrices
						where 1 = 1
						and ProductPriceTypeID = 8 --@productpricetypeid
						and ProductID = 6602
						and SupplierID = 40563
						and StoreID in
						(select storeid 
						from stores
						where LTRIM(rtrim(custom1)) = 'Farm Fresh Markets')
*/


select *
from ProductPrices
where ProductID = 6717
and supplierid = 40557
and ProductPriceTypeID = 3



select * from tmpMaintenanceRequestStoreIDList


return
GO
