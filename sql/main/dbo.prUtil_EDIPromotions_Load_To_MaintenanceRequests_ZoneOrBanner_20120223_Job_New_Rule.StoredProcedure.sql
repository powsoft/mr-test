USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_EDIPromotions_Load_To_MaintenanceRequests_ZoneOrBanner_20120223_Job_New_Rule]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_EDIPromotions_Load_To_MaintenanceRequests_ZoneOrBanner_20120223_Job_New_Rule]
as

--Temporary Block of Bimbo Farm Fresh EDI
update c set c.loadstatus = 20
from datatrue_edi.dbo.Promotions c
where 1 = 1
and supplieridentifier = 'BIM'
--and Supplierid = 40557
and (charindex('Farm Fresh', CorporateName)>0 or charindex('Farm Fresh', dtbanner)>0 or charindex('Farm Fresh', StoreName)>0)
and loadstatus = 0


--update  [DataTrue_EDI].[dbo].[promotions] set chainid = 
--case when (Banner = 'KNG' or dtBanner = 'The Pantry' or dtBanner = 'Pantry') then 42491
--else 40393
--end 
--where chainid is null


update p  set p.chainid = s.chainid
from [DataTrue_EDI].[dbo].[promotions] p
inner join stores s
on LTRIM(rtrim(p.StoreDuns)) = LTRIM(rtrim(s.DunsNumber))
where p.chainid is null

update  [DataTrue_EDI].[dbo].[promotions] set dtbanner = 'Pantry' where chainid = 42491


update datatrue_edi.dbo.Promotions set supplierid = 
(select SupplierID from Suppliers where UniqueEDIName=datatrue_edi.dbo.Promotions.SupplierIdentifier)
where supplierid is null
and loadstatus = 0
--and recordid between 88220 and 88238

update datatrue_edi.dbo.Promotions set SupplierIdentifier = 
(select UniqueEDIName from Suppliers where SupplierID=ltrim(rtrim(datatrue_edi.dbo.Promotions.SupplierId)))
where SupplierIdentifier is null
and loadstatus = 0
--and recordid between 88220 and 88238


update datatrue_edi.dbo.Promotions set dtstorecontexttypeid = 
(select Case StoreProductContextMethod
			when 'BANNER' then 2
			when 'COSTZONE' then 3
			else null
		end
from Suppliers where UniqueEDIName=SupplierIdentifier)
where dtstorecontexttypeid is null
and loadstatus = 0
--and recordid between 88220 and 88238

update datatrue_edi.dbo.Promotions set dtbanner = 'Cub Foods'                                
,dtstorecontexttypeid = 3
,dtcostzoneid = 875
where 1=1
-- dtbanner is null
and loadstatus = 0
and supplierid =  40558
--and recordid between 88220 and 88238
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
--and dtbanner is null
--and recordid between 88220 and 88238


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


update c set c.dtbanner=
case 
	when LTRIM(rtrim(StoreIdentifier)) = '1939636180001' then 'Farm Fresh Markets'
	when LTRIM(rtrim(StoreIdentifier)) = '1939636180000' then 'Farm Fresh Markets'
	when LTRIM(rtrim(StoreIdentifier)) = '193963618' then 'Farm Fresh Markets'	                                         
	when LTRIM(rtrim(StoreIdentifier)) = '0069271863600' then 'Albertsons - SCAL'
	when LTRIM(rtrim(StoreIdentifier)) = '0069271833301' then 'Albertsons - IMW'
	when LTRIM(rtrim(StoreIdentifier)) = '0069271833302' then 'Albertsons - IMW'
	when LTRIM(rtrim(StoreIdentifier)) = '0069271877700' then 'Albertsons - ACME'
	when LTRIM(rtrim(StoreIdentifier)) = '0032326880002' then 'Cub Foods'
	when LTRIM(rtrim(StoreIdentifier)) = '8008812780000' then 'Shop N Save Warehouse Foods Inc'
	when LTRIM(rtrim(StoreIdentifier)) = '800881278000P' then 'Shop N Save Warehouse Foods Inc'
	when LTRIM(rtrim(StoreIdentifier)) = '4233100000000' then 'Shoppers Food and Pharmacy'	                                     
else null
end
--select *
from RuleUse u join Rules r
on u.RuleId=r.RuleId
and r.RuleTypeId=6
join datatrue_edi.dbo.costs c on
u.EdiName=c.partneridentifier
and r.RuleId=17
and c.RecordStatus=0
and c.dtbanner is null
/*
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
and dtbanner is null
--and recordid between 88220 and 88238

*/


update c set c.dtbanner=
case 
	when LTRIM(rtrim(StoreName)) = 'JEWEL OSCO' then 'JEWEL'
	when LTRIM(rtrim(StoreName)) = 'FARM FRESH' then 'Farm Fresh Markets'
	when LTRIM(rtrim(StoreName)) = 'ALBERTSONS SOCAL' then 'Albertsons - SCAL'
	--when LTRIM(rtrim(StoreName)) = '0069271833302' then 'Albertsons - IMW'
	when LTRIM(rtrim(StoreName)) = 'ACME FOODS' then 'Albertsons - ACME'
	--when LTRIM(rtrim(StoreName)) = '800881278000P' then 'Shop N Save Warehouse Foods Inc'
	when LTRIM(rtrim(StoreName)) = 'SHOPPERS FOOD' then 'Shoppers Food and Pharmacy'
	when LTRIM(rtrim(StoreName)) = 'Shoppers Food and Pharmacy' then 'Shoppers Food and Pharmacy'
	when LTRIM(rtrim(StoreName)) = 'Albertsons - SCAL' then 'Albertsons - SCAL'
	when LTRIM(rtrim(StoreName)) = 'Albertsons - ACME' then 'Albertsons - ACME'
	when LTRIM(rtrim(StoreName)) = 'Albertsons - IMW' then 'Albertsons - IMW'
	when LTRIM(rtrim(StoreName)) = 'JEWEL' then 'JEWEL'
	when LTRIM(rtrim(StoreName)) = 'Farm Fresh Markets' then 'Farm Fresh Markets'			                                     
else null
end
--select *
from RuleUse u join Rules r
on u.RuleId=r.RuleId
and r.RuleTypeId=6
join datatrue_edi.dbo.costs c on
u.EdiName=c.partneridentifier
and r.RuleId=16
and c.RecordStatus=0
and c.dtbanner is null

	
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

declare @ApprovalDateTime datetime
declare @Approved tinyint
declare @ChainLoginID int
declare @DealNumber nvarchar(50)
declare @DeleteDateTime datetime
declare @DeleteLoginId int
declare @DeleteReason nvarchar(150)
declare @DenialReason nvarchar(150)
declare @EmailGeneratedToSupplier nvarchar(50)
declare @EmailGeneratedToSupplierDateTime DateTime
Declare @Skip_879_889_Conversion_ProcessCompleted int
declare @SkipPopulating879_889Records bit
declare @CurrentSetupCost money
declare @Cost money
declare @MarkDeleted bit
declare @SuggestedRetail money
declare @SupplierLoginID int
declare @BrandIdentifier nvarchar(50)
declare @chainid int
declare @RequestTypeID int
	
set @rec2 = CURSOR local fast_forward FOR
	select recordid, storeid, ProductId, supplierid, 
	DateStartPromotion, DateEndPromotion, Allowance_ChargeRate,
	ProductName, ProductIdentifier, ltrim(rtrim(MarketAreaCode)),
	ltrim(rtrim(dtbanner)), dtcostzoneid, dtstorecontexttypeid, promotionnumber
	,Approved,ApprovalDateTime,BrandIdentifier,ChainLoginID,CurrentSetupCost
	,DealNumber,DeleteDateTime,DeleteLoginId,DeleteReason,DenialReason,EmailGeneratedToSupplier
	,EmailGeneratedToSupplierDateTime,MarkDeleted
	,Skip_879_889_Conversion_ProcessCompleted,SkipPopulating879_889Records
	,SuggestedRetail,chainid,SupplierLoginID,Cost,RequestTypeID
	--select *
	from datatrue_edi.dbo.Promotions
	where Loadstatus = 0
	and dtstorecontexttypeid is not null
	and dtstorecontexttypeid in (2,3)
	and dtbanner is not null
	and supplierid is not null
	and chainid is not null
	--and SupplierIdentifier = 'LWS'
	--and recordid between 88220 and 88238
	
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
	,@Approved,@ApprovalDateTime
	,@BrandIdentifier,@ChainLoginID,@CurrentSetupCost
	,@DealNumber,@DeleteDateTime,@DeleteLoginId,@DeleteReason,@DenialReason
	,@EmailGeneratedToSupplier,@EmailGeneratedToSupplierDateTime,@MarkDeleted
	,@Skip_879_889_Conversion_ProcessCompleted,@SkipPopulating879_889Records
	,@SuggestedRetail
	,@chainid
	,@SupplierLoginID
	,@Cost
	,@RequestTypeID

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
           ,[TradingPartnerPromotionIdentifier]
           ,Approved,ApprovalDateTime,BrandIdentifier,ChainLoginID,CurrentSetupCost
	,DealNumber,DeleteDateTime,DeleteLoginId,DeleteReason,DenialReason,EmailGeneratedToSupplier
	,EmailGeneratedToSupplierDateTime,MarkDeleted
	,Skip_879_889_Conversion_ProcessCompleted,SkipPopulating879_889Records
	,SuggestedRetail)
     VALUES
           (getdate()
           ,@RequestTypeID
           ,@chainid
           ,@supplierid
           ,@allstores
           ,@RawProductIdentifier
           ,@productname
           ,@Cost
           ,1
           ,@allowance
           ,@startdate
           ,@enddate
           ,ISnull(@SupplierLoginID,0)
           ,0
           ,@productid
           ,0
           ,@costzoneid
           ,@banner
           ,@storecontexttypeid
           ,@maintenancerequestid
           ,@tradingpartnerpromotionidentifier
           ,@Approved,@ApprovalDateTime,@BrandIdentifier,@ChainLoginID,@CurrentSetupCost
	,@DealNumber,@DeleteDateTime,@DeleteLoginId,@DeleteReason,@DenialReason,@EmailGeneratedToSupplier
	,@EmailGeneratedToSupplierDateTime,@MarkDeleted
	,@Skip_879_889_Conversion_ProcessCompleted,@SkipPopulating879_889Records
	,@SuggestedRetail)

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
	,@Approved,@ApprovalDateTime
	,@BrandIdentifier,@ChainLoginID,@CurrentSetupCost
	,@DealNumber,@DeleteDateTime,@DeleteLoginId,@DeleteReason,@DenialReason
	,@EmailGeneratedToSupplier,@EmailGeneratedToSupplierDateTime,@MarkDeleted
	,@Skip_879_889_Conversion_ProcessCompleted,@SkipPopulating879_889Records
	,@SuggestedRetail,@chainid,@SupplierLoginID,@Cost,@RequestTypeID
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
