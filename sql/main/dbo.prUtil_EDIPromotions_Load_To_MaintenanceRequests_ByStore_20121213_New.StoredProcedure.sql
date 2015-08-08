USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_EDIPromotions_Load_To_MaintenanceRequests_ByStore_20121213_New]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_EDIPromotions_Load_To_MaintenanceRequests_ByStore_20121213_New]
as

/*


select * from datatrue_edi.dbo.Promotions where loadstatus = 0
select * from datatrue_edi.dbo.Promotions where Supplieridentifier = 'SAR' order by datetimecreated desc
Farm Fresh Duns = 1939636180000
select * from costzones where supplierid = 41465
select * from costzonerelations where costzoneid = 1777
*/

--update datatrue_edi.dbo.Promotions 
--set chainid = 40393 
--where loadstatus = 0
--and ltrim(rtrim(StoreDuns)) = '8008812780000'


update p  set p.chainid = s.chainid
from [DataTrue_EDI].[dbo].[promotions] p
inner join stores s
on LTRIM(rtrim(p.StoreDuns)) = LTRIM(rtrim(s.DunsNumber))
where p.chainid is null


update datatrue_edi.dbo.Promotions set supplierid = 
case --when SupplierIdentifier = 'LWS' then 41464
	--when  SupplierIdentifier = 'BIM' then 40557
	when SupplierIdentifier = 'SAR' then 41465
end
where supplierid is null
and loadstatus = 0

update datatrue_edi.dbo.Promotions set dtcostzoneid = 1777
where loadstatus = 0
and supplierid = 41465

/*
update datatrue_edi.dbo.Promotions set dtcostzoneid = 
case when LTRIM(rtrim(PromotionNumber)) = 'SHOPNSAV11122601' then 874
	when  LTRIM(rtrim(PromotionNumber)) = 'SNSSPRI 11122602' then 876
else null
end
where loadstatus = 0



select distinct custom1 from stores

select * from stores where Custom1 = 'Farm Fresh Markets'

update datatrue_edi.dbo.Promotions set banner = 
case when LTRIM(rtrim(StoreDuns)) = '1939636180000' then 'Farm Fresh Markets'
else null
end
where loadstatus = 0

select * from datatrue_edi.dbo.Promotions where loadstatus = 0

select * from datatrue_edi.dbo.Promotions where supplieridentifier = 'SAR'
select distinct storeduns from datatrue_edi.dbo.Promotions where supplieridentifier = 'SAR'

select distinct custom1 from stores where storeid in
(select distinct storeid from storetransactions where supplierid = 41465 and saledatetime > '11/30/2011')

update datatrue_edi.dbo.Promotions set dtbanner = 'Shop N Save Warehouse Foods Inc'
--case when LTRIM(rtrim(StoreDuns)) = '1939636180000' then 'Farm Fresh Markets'
--else null
--end
where loadstatus = 0
and storeid is not null

select distinct custom1
from stores
where storeid in
(select distinct storeid from storetransactions where supplierid = 41465)

select *
from datatrue_edi.dbo.Promotions p
where Loadstatus = 0
and p.StoreNumber is not null
and len(p.StoreNumber) > 0
*/
update datatrue_edi.dbo.Promotions set recordsource = 
case when SupplierIdentifier IS null and supplierid IS Not null then 'TMP' else 'EDI' end where Loadstatus = 0

--select *
update p set p.storeid = s.storeid, p.dtstorecontexttypeid = 1
from datatrue_edi.dbo.Promotions p
inner join stores s
--on CAST(storenumber as int) = CAST(s.custom2 as int)
on CAST(storenumber as int) = CAST(s.storeidentifier as int)
--and LTRIM(rtrim(p.banner)) = LTRIM(rtrim(custom1))
and LTRIM(rtrim(s.custom3)) = 'SS'
where Loadstatus = 0
and p.StoreNumber is not null
and len(p.StoreNumber) > 0
and SupplierIdentifier = 'SAR'

update datatrue_edi.dbo.Promotions set dtbanner = --'Shop N Save Warehouse Foods Inc'
case when LTRIM(rtrim(StoreDuns)) = '8008812780000' then 'Shop N Save Warehouse Foods Inc'
else null
end
where loadstatus = 0
and storeid is not null

/*
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
declare @allstores bit=0
declare @banner nvarchar(50)
declare @costzoneid int
declare @storecontexttypeid smallint
declare @promotionnumber nvarchar(50)
declare @Approved bit
declare @ApprovalDateTime DateTime
declare @BrandIdentifier nvarchar(50)
declare @ChainLoginID int
declare @CurrentSetupCost money
declare @DealNumber nvarchar(50)
declare @DeleteDateTime datetime
declare @DeleteLoginId int
declare @DeleteReason nvarchar(150)
declare @DenialReason nvarchar(150)
declare @EmailGeneratedToSupplier nvarchar(50)
declare @EmailGeneratedToSupplierDateTime DateTime
Declare @Skip_879_889_Conversion_ProcessCompleted int
declare @SkipPopulating879_889Records bit
declare @MarkDeleted bit
declare @SuggestedRetail money
declare @SupplierLoginID int
declare @chainid int
declare @recordsource nvarchar(10)

set @rec2 = CURSOR local fast_forward FOR
	select recordid, storeid, ProductId, supplierid, 
	DateStartPromotion, DateEndPromotion, Allowance_ChargeRate,
	ProductName, ProductIdentifier, ltrim(rtrim(MarketAreaCode)),
	dtbanner, dtcostzoneid, dtstorecontexttypeid, PromotionNumber
	,Approved,ApprovalDateTime,BrandIdentifier,ChainLoginID
	,CurrentSetupCost,DealNumber,DeleteDateTime,DeleteLoginId
	,DeleteReason,DenialReason,EmailGeneratedToSupplier,EmailGeneratedToSupplierDateTime
	,MarkDeleted,Skip_879_889_Conversion_ProcessCompleted,SkipPopulating879_889Records
	,SuggestedRetail,SupplierLoginID,chainid,Recordsource
	--select *
	from datatrue_edi.dbo.Promotions
	where Loadstatus = 0
	and dtstorecontexttypeid = 1
	and storeid is not null
	and chainid is not null
	and supplierid is not null
	and dtbanner is not null
	and Recordsource is not null
	and PDIParticipant = 0
	
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
	,@promotionnumber
	,@Approved,@ApprovalDateTime,@BrandIdentifier,@ChainLoginID
	,@CurrentSetupCost,@DealNumber,@DeleteDateTime,@DeleteLoginId
	,@DeleteReason,@DenialReason,@EmailGeneratedToSupplier,@EmailGeneratedToSupplierDateTime
	,@MarkDeleted,@Skip_879_889_Conversion_ProcessCompleted,@SkipPopulating879_889Records
	,@SuggestedRetail,@SupplierLoginID,@chainid,@recordsource

while @@FETCH_STATUS = 0
	begin


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
           ,[TradingPartnerPromotionIdentifier]
           ,[datatrue_edi_promotions_recordid]
           ,[dtstorecontexttypeid]
           ,[Banner]
           ,CostZoneID
           ,Approved 
		,ApprovalDateTime 
		,BrandIdentifier
		,ChainLoginID
		,CurrentSetupCost
		,DealNumber
		,DeleteDateTime
		,DeleteLoginId
		,DeleteReason
		,DenialReason
		,EmailGeneratedToSupplier
		,EmailGeneratedToSupplierDateTime
		,MarkDeleted
		,Skip_879_889_Conversion_ProcessCompleted
		,SkipPopulating879_889Records
		,SuggestedRetail
		,RequestSource)
     VALUES
           (getdate()
           ,3
           ,@chainid
           ,@supplierid
           ,@allstores
           ,@RawProductIdentifier
           ,@productname
           ,0.00
           ,1
           ,@allowance
           ,@startdate
           ,@enddate
           ,0
           ,0
           ,@productid
           ,0
           ,@promotionnumber
           ,@maintenancerequestid
           ,@storecontexttypeid
           ,@banner
           ,@costzoneid
           ,@Approved 
		,@ApprovalDateTime 
		,@BrandIdentifier
		,@ChainLoginID
		,@CurrentSetupCost
		,@DealNumber
		,@DeleteDateTime
		,@DeleteLoginId
		,@DeleteReason
		,@DenialReason
		,@EmailGeneratedToSupplier
		,@EmailGeneratedToSupplierDateTime
		,@MarkDeleted
		,@Skip_879_889_Conversion_ProcessCompleted
		,@SkipPopulating879_889Records
		,@SuggestedRetail,@recordsource)
           --,case when @marketareacode = 'SHOPNSAV' then 874 when @marketareacode = 'SNSSPRI' then 876 else null end)
           
           if 1 = 1 --@allstores = 0
			begin
				   set @newmaintenancerequestid = SCOPE_IDENTITY()
		           
				INSERT INTO [DataTrue_Main].[dbo].[MaintenanceRequestStores]
				   ([MaintenanceRequestID]
				   ,[StoreID]
				   ,[Included])
				VALUES
				   (@newmaintenancerequestid
				   ,@storeid
				   ,1)
			end

   update datatrue_edi.dbo.Promotions set loadstatus = 1 where recordid = @maintenancerequestid
   --20121205 for templates update datatrue_edi.dbo.Promotions set loadstatus = 1,Recordsource = 'EDI' where recordid = @maintenancerequestid

		
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
	,@promotionnumber
	,@Approved,@ApprovalDateTime,@BrandIdentifier,@ChainLoginID
	,@CurrentSetupCost,@DealNumber,@DeleteDateTime,@DeleteLoginId
	,@DeleteReason,@DenialReason,@EmailGeneratedToSupplier,@EmailGeneratedToSupplierDateTime
	,@MarkDeleted,@Skip_879_889_Conversion_ProcessCompleted,@SkipPopulating879_889Records
	,@SuggestedRetail,@SupplierLoginID,@chainid,@recordsource

	end
	
close @rec2
deallocate @rec2
	
	
return
GO
