USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_EDIPromotions_Load_To_MaintenanceRequests_ZoneOrBanner_Job_New_jun]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_EDIPromotions_Load_To_MaintenanceRequests_ZoneOrBanner_Job_New_jun]
as
DECLARE @Subject VARCHAR(MAX)
DECLARE @errMessage1 varchar(max)=''
DECLARE @badrecords table (recordid int)

DECLARE @badrecids varchar(max)=''

update datatrue_edi.dbo.Promotions set RequestTypeID = 3 where RequestTypeID is null and Loadstatus = 0

update p set dtcostzoneid=costzoneid							
from DataTrue_EDI..promotions p
inner join costzones c
on c.OwnerEntityID=p.chainid
and c.OwnerMarketID=p.MarketAreaCode
and c.SupplierId=p.supplierid	
and p.MarketAreaCode is not null
and dtstorecontexttypeid=3
and (StoreNumber is null or StoreNumber='')
and Loadstatus=0


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
	and dtstorecontexttypeid in (2,3,4)
	and dtbanner is not null
	and supplierid is not null
	and chainid is not null
	and Recordsource is not null
	and PDIParticipant = 0
	and (StoreNumber is null or StoreNumber='')
	
		
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

	--update datatrue_edi.dbo.Promotions set loadstatus = 1 where recordid = @maintenancerequestid
	update p set loadstatus = 1 
	from datatrue_edi.dbo.Promotions p
	inner join maintenancerequests m
	on datatrue_edi_promotions_recordid=recordid
	and RecordID= @maintenancerequestid
	
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
