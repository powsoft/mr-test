USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_EDIPromotions_Load_To_MaintenanceRequests_ByStore_New_PDI_jun]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_EDIPromotions_Load_To_MaintenanceRequests_ByStore_New_PDI_jun]
as
DECLARE @badrecidsP varchar(max)=''
DECLARE @SubjectP VARCHAR(MAX)=''
DECLARE @errMessageP varchar(max)=''
DECLARE @badrecordsP table (recordid int)

update p set p.storeid = s.storeid,
 p.dtstorecontexttypeid = 1
--select  SupplierIdentifier,p.storeid, s.storeid,p.banner,s.custom3,p.chainid,s.chainid
from datatrue_edi.dbo.Promotions p
inner join stores s
on CAST(storenumber as int) = CAST(s.storeidentifier as int)
and LTRIM(rtrim(p.banner)) = LTRIM(rtrim(s.custom3))
and p.storeid is null
and p.chainid=s.ChainID
and  Loadstatus = 0
and p.StoreNumber is not null 
and p.StoreNumber <>''

update p set p.storeid = s.storeid, p.dtstorecontexttypeid = 1,banner=custom3
--select  SupplierIdentifier,p.storeid, s.storeid,p.banner,s.custom3,p.chainid,s.chainid
from datatrue_edi.dbo.Promotions p
inner join stores s
on CAST(storenumber as int) = CAST(s.storeidentifier as int)
and LTRIM(rtrim(p.chainid)) = LTRIM(rtrim(s.chainid))
and ISNUMERIC(LTRIM(rtrim(p.storenumber)))=1
and p.storeid is null
and p.chainid=s.ChainID
--and len(p.storeid)=0
and  Loadstatus = 0
and p.StoreNumber is not null 
and p.StoreNumber <>''







select *from [DataTrue_EDI].[dbo].[Promotions] p
where loadstatus =0 
and PDIParticipant =1
and (VIN is null )
and dtstorecontexttypeid=1
and p.storeid is not null


if @@ROWCOUNT>0
begin
insert @badrecordsP       
	select loadstatus =0  from [DataTrue_EDI].[dbo].[Promotions] p
where loadstatus =0   
and PDIParticipant =1
and (VIN is null )
and dtstorecontexttypeid=1
and p.storeid is not null


set @errMessageP+='VIN is null.' +CHAR(13)+CHAR(10)
end

if @errMessageP <>''
		begin;
			with c as (select ROW_NUMBER() over (partition by recordid order by recordid)dupe from @badrecordsP)
				delete c where dupe>1
			set @SubjectP ='Promotions PDI records can not be move to MaintenanceRequest. VIN is null.' 
			select @badrecidsP += cast(recordid as varchar(13))+ ','
			from @badrecordsP
			set @errMessageP+=CHAR(13)+CHAR(10)+'Message sent from SP prUtil_EDIPromotions_Load_To_MaintenanceRequests_ByStore_New_PDI_jun'+CHAR(13)+CHAR(10)+'Cost Record ID:'+CHAR(13)+CHAR(10)+@badrecidsP
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com;charlie.clark@icucsolutions.com',--;gilad.keren@icucsolutions.com',
				@subject=@SubjectP,@body=@errMessageP				
	
       end  
       


	
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
declare @VIN nvarchar(20)

set @rec2 = CURSOR local fast_forward FOR
	select recordid, storeid, ProductId, supplierid, 
	DateStartPromotion, DateEndPromotion, Allowance_ChargeRate,
	ProductName, ProductIdentifier, ltrim(rtrim(MarketAreaCode)),
	dtbanner, dtcostzoneid, dtstorecontexttypeid, PromotionNumber
	,Approved,ApprovalDateTime,BrandIdentifier,ChainLoginID
	,CurrentSetupCost,DealNumber,DeleteDateTime,DeleteLoginId
	,DeleteReason,DenialReason,EmailGeneratedToSupplier,EmailGeneratedToSupplierDateTime
	,MarkDeleted,Skip_879_889_Conversion_ProcessCompleted,SkipPopulating879_889Records
	,SuggestedRetail,SupplierLoginID,chainid,Recordsource,VIN
	--select *
	from datatrue_edi.dbo.Promotions
	where Loadstatus = 0
	and dtstorecontexttypeid = 1
	and storeid is not null
	and chainid is not null
	and supplierid is not null
	and Recordsource is not null
	and PDIParticipant = 1
	and VIN is not null 
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
	,@SuggestedRetail,@SupplierLoginID,@chainid,@recordsource,@VIN

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
		,RequestSource
		,VIN)
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
		,1 --@SkipPopulating879_889Records
		,@SuggestedRetail
		,@recordsource
		,@VIN)
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
	,@SuggestedRetail,@SupplierLoginID,@chainid,@recordsource,@VIN

	end
	
close @rec2
deallocate @rec2
	
	
return
GO
