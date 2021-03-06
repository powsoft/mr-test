USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_EDIPromotions_Load_To_MaintenanceRequests_ZoneOrBanner_Job_New_PDI_jun]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_EDIPromotions_Load_To_MaintenanceRequests_ZoneOrBanner_Job_New_PDI_jun]
as
DECLARE @badrecidsP1 varchar(max)=''
DECLARE @SubjectP1 VARCHAR(MAX)=''
DECLARE @errMessageP1 varchar(max)=''
DECLARE @badrecordsP1 table (recordid int)

update datatrue_edi.dbo.Promotions set SupplierIdentifier = 
(select UniqueEDIName from Suppliers where SupplierID=ltrim(rtrim(datatrue_edi.dbo.Promotions.SupplierId)))
where SupplierIdentifier is null
and loadstatus = 0
and Pdiparticipant = 1



update c set c.ProductName = ''
--select *
from datatrue_edi.dbo.Promotions c
where 1 = 1
and c.ProductName is null
and c.Pdiparticipant = 1

update c set dtstorecontexttypeid = 3
--select *
from datatrue_edi.dbo.Promotions c
where 1 = 1
and c.Loadstatus = 0
and c.dtstorecontexttypeid is null
and c.dtstorecontexttypeid not in (1,-1)
and c.Pdiparticipant = 1
and (StoreNumber is null or StoreNumber='')


update datatrue_edi.dbo.Promotions set RequestTypeID = 3 where RequestTypeID is null and Loadstatus = 0



update p set p.dtcostzoneid =costzoneid
from datatrue_edi.dbo.Promotions p
inner join datatrue_main.dbo.CostZoneRelations c
on p.supplierid=c.SupplierID
and p.storeid=c.storeid
and dtcostzoneid is null
and loadStatus = 0
and p.PDIParticipant = 1

update r set  r.dtcostzoneid = z.CostZoneID
--select recordid,r.dtCostZoneID,dtsupplierid,dtchainid , r.OwnerMarketID, z.*
from datatrue_edi.dbo.promotions r
inner join costzones z
on r.chainid = z.ownerentityid
and r.supplierid = z.supplierid
and ltrim(rtrim(r.OwnerMarketID)) = ltrim(rtrim(z.OwnerMarketID))
and PDIParticipant=1
and r.OwnerMarketID is not null
and r.dtcostzoneid is null
and loadStatus=0
and (StoreNumber is null or StoreNumber='')


update r set  r.OwnerMarketID = z.OwnerMarketID
--select r.dtCostZoneID, z.CostZoneID, z.*
from datatrue_edi.dbo.promotions r
inner join costzones z
on r.chainid = z.ownerentityid
and r.supplierid = z.supplierid
and ltrim(rtrim(r.dtCostZoneID)) = ltrim(rtrim(z.CostZoneID))
and r.PDIParticipant = 1
and r.OwnerMarketID is null
and z.OwnerMarketID is not null
and loadStatus = 0


select *
from [DataTrue_EDI].[dbo].[promotions] p
where loadstatus =0
and PDIParticipant =1
and (OwnerMarketID is null )
and dtstorecontexttypeid=3
if @@ROWCOUNT >0
begin
insert @badrecordsP1
	select RecordID from [DataTrue_EDI].[dbo].[promotions] p
where loadstatus =0
and PDIParticipant =1
and (OwnerMarketID is null)
and dtstorecontexttypeid=3
and (storenumber is null or storenumber='')

set @errMessageP1+='Promotion OwnerMarketID is null' +CHAR(13)+CHAR(10)
end

select *
from [DataTrue_EDI].[dbo].[promotions] p
where loadstatus =0
and PDIParticipant =1
and ( VIN is null or OwnerMarketID  is null)
and dtstorecontexttypeid=3


if @@ROWCOUNT >0
begin
insert @badrecordsP1
	select RecordID from [DataTrue_EDI].[dbo].[promotions] p
where loadstatus =0
and PDIParticipant =1
and ( VIN is null or OwnerMarketID is null)
and dtstorecontexttypeid=3

set @errMessageP1+=' VIN or OwnerMarketID are null for PDIParticipant' +CHAR(13)+CHAR(10)
end
 

if @errMessageP1 <>''
		begin;
			with c as (select ROW_NUMBER() over (partition by recordid order by recordid)dupe from @badrecordsP1)
				delete c where dupe>1
			set @SubjectP1 ='Promotion PDI records can not be move to MaintenanceRequest.VIN or OwnerMarketID are null' 
			select @badrecidsP1 += cast(recordid as varchar(13))+ ','
			from @badrecordsP1
			set @errMessageP1+=CHAR(13)+CHAR(10)+'Message sent from SP prUtil_EDIPromotions_Load_To_MaintenanceRequests_ZoneOrBanner_Job_New_PDI_jun'+CHAR(13)+CHAR(10)+'Promotion Record ID:'+CHAR(13)+CHAR(10)+@badrecidsP1
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com',--;gilad.keren@icucsolutions.com;charlie.clark@icucsolutions.com',
				@subject=@SubjectP1,@body=@errMessageP1				
	
       end       



	Begin try
declare @rec2 cursor
declare @brandid int=0
declare 	@recordid int
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
declare @PDIParticipant int
declare @vin nvarchar(50)
	
set @rec2 = CURSOR local fast_forward FOR
	select recordid, storeid, ProductId, supplierid, 
	DateStartPromotion, DateEndPromotion, Allowance_ChargeRate,
	ProductName, ProductIdentifier, ltrim(rtrim(MarketAreaCode)),
	ltrim(rtrim(dtbanner)), dtcostzoneid, dtstorecontexttypeid, promotionnumber
	,Approved,ApprovalDateTime,BrandIdentifier,ChainLoginID,CurrentSetupCost
	,DealNumber,DeleteDateTime,DeleteLoginId,DeleteReason,DenialReason,EmailGeneratedToSupplier
	,EmailGeneratedToSupplierDateTime,MarkDeleted
	,Skip_879_889_Conversion_ProcessCompleted,SkipPopulating879_889Records
	,SuggestedRetail,chainid,SupplierLoginID,Cost,RequestTypeID,Recordsource, PDIParticipant,ltrim(rtrim(VIN))
	--select *
	from datatrue_edi.dbo.Promotions
	where Loadstatus = 0
	--and chainid in (63614)
	and VIN is not null 
	and OwnerMarketID is not null
	and dtstorecontexttypeid in (2,3,4)
	and dtbanner is not null
	and supplierid is not null
	and chainid is not null
	and Recordsource is not null
	and PDIParticipant = 1
	and RequestTypeID =3
	and (StoreNumber is null or StoreNumber='')
	

open @rec2

fetch next from @rec2 into
	@recordid
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
	,@PDIParticipant
	,@vin
	
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
	,SuggestedRetail,RequestSource,PDIParticipant,VIN)
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
           ,17 --0
           ,@productid
           ,0
           ,@costzoneid
           ,@banner
           ,@storecontexttypeid
           ,@recordid
           ,@tradingpartnerpromotionidentifier
           ,@Approved,@ApprovalDateTime,@BrandIdentifier,@ChainLoginID,@CurrentSetupCost
	,@DealNumber,@DeleteDateTime,@DeleteLoginId,@DeleteReason,@DenialReason,@EmailGeneratedToSupplier
	,@EmailGeneratedToSupplierDateTime,@MarkDeleted
	,@Skip_879_889_Conversion_ProcessCompleted,1 --@SkipPopulating879_889Records
	,@SuggestedRetail,@recordsource, @PDIParticipant, @vin)

	update p set loadstatus = 1 
	from datatrue_edi.dbo.Promotions p
	inner join maintenancerequests m
	on datatrue_edi_promotions_recordid=recordid
	and RecordID= 	@recordid
	--for template updates above doesn't update recordsource update datatrue_edi.dbo.Promotions set loadstatus = 1, recordsource = 'EDI' where recordid = @maintenancerequestid


fetch next from @rec2 into
		@recordid
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
	,@SuggestedRetail,@chainid,@SupplierLoginID,@Cost,@RequestTypeID,@recordsource, @PDIParticipant, @vin
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
