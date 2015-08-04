USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_EDIPromotions_Load_To_MaintenanceRequests_ZoneOrBanner_Job_New_2014fab03]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_EDIPromotions_Load_To_MaintenanceRequests_ZoneOrBanner_Job_New_2014fab03]
as
DECLARE @Subject VARCHAR(MAX)
DECLARE @errMessage1 varchar(max)=''
DECLARE @badrecords table (recordid int)

DECLARE @badrecids varchar(max)=''

--update c set c.loadstatus = 20 
--update p  set p.chainid = s.chainid
--update datatrue_edi.dbo.Promotions set supplierid = 
/*update p  set p.chainid = s.chainid
select  p.SupplierIdentifier 
from [DataTrue_EDI].[dbo].[promotions] p
inner join stores s
on CHARINDEX(LTRIM(rtrim(p.StoreDuns)), s.DunsNumber)>0
and p.chainid is null

update p  set p.chainid = s.chainid
select distinct p.SupplierIdentifier
from [DataTrue_EDI].[dbo].[promotions] p
inner join stores s
on CHARINDEX(LTRIM(rtrim(replace(p.StoreDuns,'P',''))), s.DunsNumber)>0
--where p.chainid is null
and ltrim(rtrim(SupplierIdentifier)) in ('NST')

--update  [DataTrue_EDI].[dbo].[promotions] set dtbanner = 'Pantry' where chainid = 42491 or SupplierIdentifier = 'KNG'
--update datatrue_edi.dbo.Promotions set dtbanner = 'Cub Foods'                                
--,dtstorecontexttypeid = 3
--,dtcostzoneid = 875
--where  loadstatus = 0
--and supplierid =  40558
--update datatrue_edi.dbo.Promotions set dtbanner = 
--case 
--	when LTRIM(rtrim(StoreDuns)) = '1939636180001' then 'Farm Fresh Markets'
--	when LTRIM(rtrim(StoreDuns)) = '1939636180000' then 'Farm Fresh Markets'
--	when LTRIM(rtrim(StoreDuns)) = '0069271863600' then 'Albertsons - SCAL'
--	when LTRIM(rtrim(StoreDuns)) = '0069271833301' then 'Albertsons - IMW'
--	when LTRIM(rtrim(StoreDuns)) = '0069271833302' then 'Albertsons - IMW'
--	when LTRIM(rtrim(StoreDuns)) = '0069271833300' then 'Albertsons - IMW'
--	when LTRIM(rtrim(StoreDuns)) = '0069271877700' then 'Albertsons - ACME'
--	when LTRIM(rtrim(StoreDuns)) = '0032326880002' then 'Cub Foods'
--	when LTRIM(rtrim(StoreDuns)) = '8008812780000' then 'Shop N Save Warehouse Foods Inc'
--	when LTRIM(rtrim(StoreDuns)) = '800881278000P' then 'Shop N Save Warehouse Foods Inc'
--	when LTRIM(rtrim(StoreDuns)) = '4233100000000' then 'Shoppers Food and Pharmacy'	                                     
--else null end
--where loadstatus = 0
--and ltrim(rtrim(SupplierIdentifier)) in ('BIM','NST')
--and dtbanner is null
--update datatrue_edi.dbo.Promotions set supplierid = 
--(select SupplierID from Suppliers where UniqueEDIName=datatrue_edi.dbo.Promotions.SupplierIdentifier)
--where supplierid is null
--and loadstatus = 0

--update datatrue_edi.dbo.Promotions set supplierid = 
--case when SupplierIdentifier = 'LWS' then 41464
--	when  SupplierIdentifier = 'BIM' then 40557
--	when SupplierIdentifier = 'SAR' then 41465
--	when SupplierIdentifier = 'NST' then 40559
--	when SupplierIdentifier = 'GOP' then 40558
--	when SupplierIdentifier = 'FLOW' then 40567
--	when SupplierIdentifier = 'MRV' then 40563
--	when SupplierIdentifier = 'XON' then 44188
--	when SupplierIdentifier = 'CHER' then 59979
--	when SupplierIdentifier = 'GUAP' then 62596
--end
--where supplierid is null
--and loadstatus = 0

--update datatrue_edi.dbo.Promotions set SupplierIdentifier = 
--(select UniqueEDIName from Suppliers where SupplierID=ltrim(rtrim(datatrue_edi.dbo.Promotions.SupplierId)))
--where SupplierIdentifier is null
--and loadstatus = 0

--update datatrue_edi.dbo.Promotions set SupplierIdentifier = 
--case when SupplierId =  41464 then 'LWS'
--	when  SupplierId = 40557 then 'BIM' 
--	when SupplierId = 41465 then 'SAR' 
--	when SupplierId = 40559 then 'NST' 
--	when SupplierId = 40558 then 'GOP'
--	when SupplierId = 40562 then 'PEP'
--	when SupplierId = 40567 then 'FLOW'
--	when SupplierId = 40563 then 'MRV'
--	when SupplierId = 44188 then 'XON'
--	when SupplierId = 59979 then 'CHER'
--	when SupplierId = 62596 then 'GUAP'
--	else null
--end
--where SupplierIdentifier is null
--and loadstatus = 0

--update datatrue_edi.dbo.Promotions set dtstorecontexttypeid = 
--case when SupplierId = 40561 then 2	else dtstorecontexttypeid end
--where dtstorecontexttypeid is null
--and loadstatus = 0

--update datatrue_edi.dbo.Promotions set dtstorecontexttypeid = 
--case when SupplierIdentifier = 'LWS' then 3
--	when  SupplierIdentifier = 'BIM' then 2
--	when SupplierIdentifier = 'SAR' then 3
--	when SupplierIdentifier = 'NST' then 2
--	when SupplierIdentifier = 'GOP' then 3
--	when SupplierIdentifier = 'PEP' then 2
--	when SupplierIdentifier = 'FLOW' then 3
--	when SupplierIdentifier = 'MRV' then 2
--	when SupplierIdentifier = 'XON' then 2
--	when SupplierIdentifier = 'CHER' then 3
--	when SupplierIdentifier = 'GUAP' then 2
--	else null end
--where dtstorecontexttypeid is null
--and loadstatus = 0
--update datatrue_edi.dbo.Promotions set SupplierIdentifier = 
--(select UniqueEDIName from Suppliers where SupplierID=ltrim(rtrim(datatrue_edi.dbo.Promotions.SupplierId)))
--where SupplierIdentifier is null
--and loadstatus = 0

--update datatrue_edi.dbo.Promotions set SupplierIdentifier = 
--case when SupplierId =  41464 then 'LWS'
--	when  SupplierId = 40557 then 'BIM' 
--	when SupplierId = 41465 then 'SAR' 
--	when SupplierId = 40559 then 'NST' 
--	when SupplierId = 40558 then 'GOP'
--	when SupplierId = 40562 then 'PEP'
--	when SupplierId = 40567 then 'FLOW'
--	when SupplierId = 40563 then 'MRV'
--	when SupplierId = 44188 then 'XON'
--	when SupplierId = 59979 then 'CHER'
--	when SupplierId = 62596 then 'GUAP'
--	else null
--end
--where SupplierIdentifier is null
--and loadstatus = 0

--update datatrue_edi.dbo.Promotions set dtstorecontexttypeid = 
--case when SupplierId = 40561 then 2	else dtstorecontexttypeid end
--where dtstorecontexttypeid is null
--and loadstatus = 0

--update datatrue_edi.dbo.Promotions set dtstorecontexttypeid = 
--case when SupplierIdentifier = 'LWS' then 3
--	when  SupplierIdentifier = 'BIM' then 2
--	when SupplierIdentifier = 'SAR' then 3
--	when SupplierIdentifier = 'NST' then 2
--	when SupplierIdentifier = 'GOP' then 3
--	when SupplierIdentifier = 'PEP' then 2
--	when SupplierIdentifier = 'FLOW' then 3
--	when SupplierIdentifier = 'MRV' then 2
--	when SupplierIdentifier = 'XON' then 2
--	when SupplierIdentifier = 'CHER' then 3
--	when SupplierIdentifier = 'GUAP' then 2
--	else null end
--where dtstorecontexttypeid is null
--and loadstatus = 0
--update datatrue_edi.dbo.Promotions
--set dtcostzoneid = 1818
--where Banner = 'KNG'
--and (SupplierIdentifier = 'CHER' or supplierid = 59979)

--update p set p.dtcostzoneid = 
--case when charindex( 'SHOPNSAV', LTRIM(rtrim(PromotionNumber))) > 0 then 874
--	when charindex('SNSSPRI', LTRIM(rtrim(PromotionNumber)) ) > 0 then 876
--else null
--end
--,dtstorecontexttypeid = 3
--,dtbanner = 'Shop N Save Warehouse Foods Inc'
--from datatrue_edi.dbo.Promotions p
--where loadstatus = 0
--and SupplierId = 41464
--and (dtstorecontexttypeid is null or dtstorecontexttypeid = 3)
--and Recordsource <> 'TMP'


--update datatrue_edi.dbo.Promotions set dtstorecontexttypeid = 2
--where loadstatus = 0
--and dtstorecontexttypeid is null
--and ltrim(rtrim(SupplierIdentifier)) in ('BIM','NST')
*/

update datatrue_edi.dbo.Promotions set recordsource = 
case when SupplierIdentifier IS null and supplierid IS Not null 
then 'TMP' else 'EDI' end where Loadstatus = 0


update p  set p.chainid = s.chainid
from [DataTrue_EDI].[dbo].[promotions] p
inner join [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp] s
on LTRIM(rtrim(p.StoreDuns)) = LTRIM(rtrim(s.CorporateIdentifier))
and p.chainid is null

insert @badrecords
	select RecordID from [DataTrue_EDI].[dbo].[costs] p
inner join [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp] s
on LTRIM(rtrim(p.StoreDuns)) = LTRIM(rtrim(s.CorporateIdentifier))
and p.dtchainid is null	
	if @@ROWCOUNT >0
		set @errMessage1+='One or more chainid are missing when StoreDuns exists' +CHAR(13)+CHAR(10)
				

update datatrue_edi.dbo.Promotions set supplierid = 
(select SupplierID from Suppliers where UniqueEDIName=datatrue_edi.dbo.Promotions.SupplierIdentifier)
where supplierid is null
and loadstatus = 0


update datatrue_edi.dbo.Promotions set SupplierIdentifier = 
(select UniqueEDIName from Suppliers where SupplierID=ltrim(rtrim(datatrue_edi.dbo.Promotions.SupplierId)))
where SupplierIdentifier is null
and loadstatus = 0





update p set p.dtbanner= e.custom1
from datatrue_edi.dbo.promotions p
join  [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp]e
on LTRIM(rtrim(p.StoreDuns))=LTRIM(rtrim(e.CorporateIdentifier))
and e.EdiName=p.SupplierIdentifier
and p.dtbanner is null
and p.StoreDuns is not null
and p.StoreDuns<>''
and p.datetimecreated>='10-01-2013'

insert @badrecords
	select RecordID from  datatrue_edi.dbo.promotions p
join  [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp]e
on LTRIM(rtrim(p.StoreDuns))=LTRIM(rtrim(e.CorporateIdentifier))
and e.EdiName=p.SupplierIdentifier
and p.dtbanner is null
and p.StoreDuns is not null
and p.StoreDuns<>''
and p.datetimecreated>='10-01-2013'
	
	if @@ROWCOUNT >0
		set @errMessage1+='One or more dtbanner are missing when StoreIdentifier exists ' +CHAR(13)+CHAR(10)

update c set c.dtbanner= e.custom1
from datatrue_edi.dbo.promotions c 
join  [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp]e
on LTRIM(rtrim(c.StoreName))=LTRIM(rtrim(e.CorporateName))
and e.EdiName=c.SupplierIdentifier
and c.dtbanner is null
and c.StoreName is not null
and c.StoreName<>''
and (c.StoreDuns is  null or c.StoreDuns='')
and c.datetimecreated>='10-01-2013'
and c.loadStatus=0

update c set c.loadstatus = 20 
from datatrue_edi.dbo.Promotions c
join Exclusions e on c.supplierid=e.SupplierId
and (dtbanner=e.custom1 or c.dtcostzoneid=e.costzoneid or c.storeid= e.storeid) 
join ExclusionTypes t on t.ExclusionTypeID=e.ExclusionTypeID
and loadstatus = 0
and isActive=1
and t.ExclusionName = 'EDITablePromotionsRecordExclusion'

insert @badrecords
select RecordID from  datatrue_edi.dbo.promotions c 
join  [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp]e
on LTRIM((c.StoreName))=LTRIM(rtrim(e.CorporateName))
and e.EdiName=c.SupplierIdentifier
and c.dtbanner is null
and c.StoreName is not null
and c.StoreName<>''
and (c.StoreDuns is  null or c.StoreDuns='')
and c.datetimecreated>='10-01-2013'
and c.loadStatus=0
	
	if @@ROWCOUNT >0
		set @errMessage1+='One or more dtbanner are missing when StoreName exists ' +CHAR(13)+CHAR(10)


update datatrue_edi.dbo.Promotions set RequestTypeID = 3 where RequestTypeID is null and Loadstatus = 0


update c set dtstorecontexttypeid = 
( Case StoreProductContextMethod when 'BANNER' then 2	when 'COSTZONE' then 3	else null end)
from datatrue_edi.dbo.Promotions c inner join SupplierStoreProductContextMethod m
on UniqueEDIName=SupplierIdentifier
and c.ChainId=m.chainid
and dtstorecontexttypeid is null and loadStatus = 0

update p set p.dtcostzoneid =costzoneid
from datatrue_edi.dbo.Promotions p
inner join datatrue_main.dbo.CostZoneRelations c
on p.supplierid=c.SupplierID
and p.storeid=c.storeid
and dtcostzoneid is null
and loadStatus = 0


	Begin try
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
declare @recordsource nvarchar(10)

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
	,SuggestedRetail,chainid,SupplierLoginID,Cost,RequestTypeID,Recordsource
	from datatrue_edi.dbo.Promotions p
	where Loadstatus = 0
	--and RecordID in (118461,118462)
	and dtstorecontexttypeid is not null
	and dtstorecontexttypeid in (2,3)
	and dtbanner is not null
	and supplierid is not null
	and chainid is not null
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
	,@recordsource

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
           ,[CostZoneID]
           ,[Banner]
           ,[dtstorecontexttypeid]
           ,[datatrue_edi_promotions_recordid]
           ,[TradingPartnerPromotionIdentifier]
           ,Approved,ApprovalDateTime,BrandIdentifier,ChainLoginID,CurrentSetupCost
	,DealNumber,DeleteDateTime,DeleteLoginId,DeleteReason,DenialReason,EmailGeneratedToSupplier
	,EmailGeneratedToSupplierDateTime,MarkDeleted
	,Skip_879_889_Conversion_ProcessCompleted,SkipPopulating879_889Records
	,SuggestedRetail,RequestSource)
     VALUES
           (getdate()
           ,@RequestTypeID
           ,@chainid
           ,@supplierid
           ,@allstores
           ,@RawProductIdentifier
           ,@productname
           ,isnull(@Cost, 0)
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
	,@SuggestedRetail,@recordsource)

	update datatrue_edi.dbo.Promotions set loadstatus = 1 where recordid = @maintenancerequestid
	
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
	,@SuggestedRetail,@chainid,@SupplierLoginID,@Cost,@RequestTypeID,@recordsource
	end
	
close @rec2
deallocate @rec2
	End Try
	Begin Catch
		declare @errormessage varchar(4500)
		declare @errorlocation varchar(255)
		declare @errorsenderstring nvarchar(255)

		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
--		print @errormessage
		
		exec DataTrue_Main.dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,0

	End Catch	
return
GO
