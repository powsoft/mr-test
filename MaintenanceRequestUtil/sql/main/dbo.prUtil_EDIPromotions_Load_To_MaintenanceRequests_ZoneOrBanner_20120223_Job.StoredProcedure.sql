USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_EDIPromotions_Load_To_MaintenanceRequests_ZoneOrBanner_20120223_Job]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_EDIPromotions_Load_To_MaintenanceRequests_ZoneOrBanner_20120223_Job]
as
/*
select top 1000 * from MaintenanceRequests order by MaintenanceRequestID desc
select distinct custom1 from stores

select * from datatrue_edi.dbo.costs where recordstatus = 0 
select * from datatrue_edi.dbo.promotions where loadstatus = 0 
select distinct Supplieridentifier from datatrue_edi.dbo.promotions where loadstatus = 0 
*/

--update datatrue_edi.dbo.Promotions set chainid = 40393 


update  [DataTrue_EDI].[dbo].[promotions] set chainid = 
case when (Banner = 'KNG' or dtBanner = 'The Pantry') then 42491
else 40393
end 
where chainid is null

/*
select *
--update p set p.loadstatus = 0
from datatrue_edi.dbo.Promotions p
where DateTimeCreated > '2012-01-11 14:00:00.050'
*/

update datatrue_edi.dbo.Promotions set supplierid = 
case when SupplierIdentifier = 'LWS' then 41464
	when  SupplierIdentifier = 'BIM' then 40557
	when SupplierIdentifier = 'SAR' then 41465
	when SupplierIdentifier = 'NST' then 40559
	when SupplierIdentifier = 'GOP' then 40558
end
where supplierid is null
and loadstatus = 0


update datatrue_edi.dbo.Promotions set dtbanner = 'Cub Foods'                                
,dtstorecontexttypeid = 3
,dtcostzoneid = 875
where dtbanner is null
and loadstatus = 0
and supplierid =  40558

/*
select *
from  datatrue_edi.dbo.Promotions
where charindex( 'SHOPNSAV', LTRIM(rtrim(PromotionNumber))) > 0
and Loadstatus = 0
*/

--select
update p set p.dtcostzoneid = 
case when charindex( 'SHOPNSAV', LTRIM(rtrim(PromotionNumber))) > 0 then 874
	when charindex('SNSSPRI', LTRIM(rtrim(PromotionNumber)) ) > 0 then 876
else null
end
,dtstorecontexttypeid = 3
,dtbanner = 'Shop N Save Warehouse Foods Inc'
from datatrue_edi.dbo.Promotions p
where loadstatus = 0
and SupplierId = 41464
and dtstorecontexttypeid is null


/*
select distinct custom1 from stores

select * from stores where Custom1 = 'Farm Fresh Markets'

update datatrue_edi.dbo.Promotions set dtbanner = 
case when LTRIM(rtrim(StoreDuns)) = '1939636180000' then 'Farm Fresh Markets'
else null
end
where loadstatus = 0

select * from datatrue_edi.dbo.Promotions where loadstatus = 0
and dtstorecontexttypeid is not null
select distinct custom1 from stores
select distinct dunsnumber from stores
*/

update datatrue_edi.dbo.Promotions set dtbanner = 
case 
	when LTRIM(rtrim(StoreDuns)) = '1939636180001' then 'Farm Fresh Markets'
	when LTRIM(rtrim(StoreDuns)) = '1939636180000' then 'Farm Fresh Markets'
	when LTRIM(rtrim(StoreDuns)) = '0069271863600' then 'Albertsons - SCAL'
	when LTRIM(rtrim(StoreDuns)) = '0069271833301' then 'Albertsons - IMW'
	when LTRIM(rtrim(StoreDuns)) = '0069271833302' then 'Albertsons - IMW'
	when LTRIM(rtrim(StoreDuns)) = '0069271833300' then 'Albertsons - IMW'
	when LTRIM(rtrim(StoreDuns)) = '0069271877700' then 'Albertsons - ACME'
	when LTRIM(rtrim(StoreDuns)) = '0032326880002' then 'Cub Foods'
	when LTRIM(rtrim(StoreDuns)) = '8008812780000' then 'Shop N Save Warehouse Foods Inc'
	when LTRIM(rtrim(StoreDuns)) = '4233100000000' then 'Shoppers Food and Pharmacy'	                                     
else null
end
,dtstorecontexttypeid = 2
where loadstatus = 0
and dtstorecontexttypeid is null
and ltrim(rtrim(SupplierIdentifier)) in ('BIM','NST')
/*
select distinct storeduns from datatrue_edi.dbo.Promotions where loadstatus = 0 
select * from stores where dunsnumber = '8008812780000'
select * from stores where ltrim(rtrim(custom1)) = 'Shop N Save Warehouse Foods Inc'
0069271833301  
0032326880002  
0069271877700  
8008812780000 


select *
--update p set p.dtstorecontexttypeid = 1, dtbanner = 'Shop N Save Warehouse Foods Inc' --p.dtcostzoneid = marketareacode
from datatrue_edi.dbo.Promotions p
where Loadstatus = 0
and SupplierIdentifier = 'SAR'
and storeid is not null

select p.*, r.*
--update r set requeststatus = -200, r.dtstorecontexttypeid = 1
from maintenancerequests r
inner join datatrue_edi.dbo.Promotions p
on r.maintenancerequestid = p.dtmaintenancerequestid 
where p.storeid is not null
and p.dtstorecontexttypeid = 2

select distinct requeststatus from maintenancerequests


select * from dbo.MaintenanceRequestStores where MaintenanceRequestID in
(
select MaintenanceRequestID
--update r set requeststatus = -200
from maintenancerequests r
inner join datatrue_edi.dbo.Promotions p
on r.maintenancerequestid = p.dtmaintenancerequestid 
where p.storeid is not null
and p.dtstorecontexttypeid = 2
)

select * into import.dbo.MaintenanceRequestStores_20111228BeforeSaraLeeReload from MaintenanceRequestStores

insert into dbo.MaintenanceRequestStores
select MaintenanceRequestID, p.storeid, 1
from maintenancerequests r
inner join datatrue_edi.dbo.Promotions p
on r.maintenancerequestid = p.dtmaintenancerequestid 
where p.storeid is not null
and p.dtstorecontexttypeid = 2

select *
--update p set p.storeid = s.storeid, p.dtstorecontexttypeid = 1
from datatrue_edi.dbo.Promotions p
inner join stores s
--on CAST(storenumber as int) = CAST(s.custom2 as int)
on CAST(storenumber as int) = CAST(s.storeidentifier as int)
and LTRIM(rtrim(p.dtbanner)) = LTRIM(rtrim(custom1))
and SupplierIdentifier = 'SAR'
and loadstatus = 0

update datatrue_edi.dbo.Promotions set dtstorecontexttypeid = 
case when storeid is null and dtcostzoneid is not null then 3
	when storeid is null and dtcostzoneid IS null and banner IS Not null then 2
	when storeid Is Not null then 2
else null end
where loadstatus = 0
*/
	
declare @rec2 cursor
declare @brandid int=0
declare @maintenancerequestid int
declare @storeid int
declare @productid int
declare @supplierid int
declare @startdate date
declare @enddate date
declare @allowance money
declare @newmaintenancerequestid int
declare @productname nvarchar(100)
declare @RawProductIdentifier nvarchar(50)
declare @marketareacode nvarchar(50)
declare @allstores bit=1
declare @banner nvarchar(50)
declare @costzoneid int
declare @storecontexttypeid smallint
declare @tradingpartnerpromotionidentifier nvarchar(50)
	
set @rec2 = CURSOR local fast_forward FOR
	select recordid, storeid, ProductId, supplierid, 
	DateStartPromotion, DateEndPromotion, Allowance_ChargeRate,
	ProductName, ProductIdentifier, ltrim(rtrim(MarketAreaCode)),
	ltrim(rtrim(dtbanner)), dtcostzoneid, dtstorecontexttypeid, promotionnumber
	--select *
	from datatrue_edi.dbo.Promotions
	where Loadstatus = 0
	and dtstorecontexttypeid is not null
	and dtstorecontexttypeid in (2,3)
	and dtbanner is not null
	and supplierid is not null
	and chainid is not null
	--and SupplierIdentifier = 'LWS'
	
	


open @rec2

fetch next from @rec2 into
	@maintenancerequestid
	,@storeid
	,@productid
	,@supplierid
	,@startdate
	,@enddate
	,@allowance
	,@productname
	,@RawProductIdentifier
	,@marketareacode
	,@banner
	,@costzoneid
	,@storecontexttypeid
	,@tradingpartnerpromotionidentifier

while @@FETCH_STATUS = 0
	begin

--select top 10 * from [DataTrue_Main].[dbo].[MaintenanceRequests]
INSERT INTO [DataTrue_Main].[dbo].[MaintenanceRequests]
           ([SubmitDateTime]
           ,[RequestTypeID]
           ,[ChainID]
           ,[SupplierID]
           ,[AllStores]
           ,[UPC]
           ,[ItemDescription]
           ,[Cost]
           ,[PromoTypeID]
           ,[PromoAllowance]
           ,[StartDateTime]
           ,[EndDateTime]
           ,[SupplierLoginID]
           ,[RequestStatus]
           ,[productid]
           ,[brandid]
           ,[CostZoneID]
           ,[Banner]
           ,[dtstorecontexttypeid]
           ,[datatrue_edi_promotions_recordid]
           ,[TradingPartnerPromotionIdentifier])
     VALUES
           (getdate()
           ,3
           ,40393
           ,@supplierid
           ,@allstores
           ,@RawProductIdentifier
           ,@productname
           ,0.00
           ,1
           ,@allowance
           ,@startdate
           ,@enddate
           ,-1 --0
           ,0
           ,@productid
           ,0
           ,@costzoneid
           ,@banner
           ,@storecontexttypeid
           ,@maintenancerequestid
           ,@tradingpartnerpromotionidentifier
           )
           
		update datatrue_edi.dbo.Promotions set loadstatus = 1, recordsource = 'EDI' where recordid = @maintenancerequestid

		fetch next from @rec2 into
			@maintenancerequestid
			,@storeid
			,@productid
			,@supplierid
			,@startdate
			,@enddate
			,@allowance
			,@productname
			,@RawProductIdentifier
			,@marketareacode
			,@banner
			,@costzoneid
			,@storecontexttypeid
			,@tradingpartnerpromotionidentifier
	end
	
close @rec2
deallocate @rec2
	
/*
select * from datatrue_edi.dbo.costs where recordstatus = 0 
select * from datatrue_edi.dbo.promotions where loadstatus = 0 

order by DateStartPromotion

select distinct SupplierIdentifier from datatrue_edi.dbo.promotions where loadstatus = 0 
select distinct PartnerIdentifier from datatrue_edi.dbo.costs where recordstatus = 0 

select * 
--UPDATE P SET dtstorecontexttypeid = 1
from datatrue_edi.dbo.Promotions p 
where loadstatus = 0 
and SupplierIdentifier = 'SAR'
and len(storenumber) > 0
order by DateStartPromotion
select distinct SupplierIdentifier from datatrue_edi.dbo.promotions where loadstatus = 0

select datatrue_edi_promotions_recordid from MaintenanceRequests order by datatrue_edi_promotions_recordid
--and SupplierIdentifier = 'BIM'
order by DateStartPromotion
Farm Fresh Duns = 1939636180000

select distinct dunsnumber from stores where ltrim(rtrim(custom1)) = 'Cub Foods'
select * from stores where ltrim(rtrim(custom1)) = 'Cub Foods'

Albertsons - ACME 461
Albertsons - IMW 570 575 0069271833300 / 0069271833301(recieved)
Albertsons - SCAL 10
Cub Foods
Farm Fresh Markets
Hornbachers
Shop N Save Warehouse Foods Inc 321
Shoppers Food and Pharmacy
10
321
461
570
575
870
321       	8008812780000  
461       	0032326880002  
570       	0069271833301  
577       	0069271877700 
select * from datatrue_edi.dbo.edi_suppliercrossreference 
select distinct custom1 from stores
select distinct dunsnumber from stores where ltrim(rtrim(custom1)) = 'Albertsons - IMW'
select * from stores where ltrim(rtrim(custom1)) = 'Albertsons - IMW'
select * from stores where ltrim(rtrim(dunsnumber)) = '0069271833300'
select * from costzones
select * from stores where storeid in
--(select storeid from stores where custom1 = 'Albertsons - SCAL')
(
select storeid from costzones z 
inner join costzonerelations r 
on z.costzoneid = r.costzoneid 
where ltrim(rtrim(z.costzonename)) = '10'
)
select distinct marketareacode, storeduns from datatrue_edi.dbo.Promotions where loadstatus = 0 

0069271833301  
0032326880002  
0069271877700  
8008812780000  
select distinct dunsnumber from stores
*/
	
return
GO
