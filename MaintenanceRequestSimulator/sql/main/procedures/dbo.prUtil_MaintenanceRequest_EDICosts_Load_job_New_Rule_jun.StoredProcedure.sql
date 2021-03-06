USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_MaintenanceRequest_EDICosts_Load_job_New_Rule_jun]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Modifier:		<Irina ,Trush>
-- Create date: <02-2014>

-- =============================================
CREATE PROCEDURE [dbo].[prUtil_MaintenanceRequest_EDICosts_Load_job_New_Rule_jun]
	
AS
DECLARE @Subject VARCHAR(MAX)
DECLARE @errMessage varchar(max)=''
DECLARE @badrecords table (recordid int)

DECLARE @badrecids varchar(max)=''

BEGIN



begin try

begin transaction

select recordid
into tempCOSTrecords_fab
FROM [DataTrue_EDI].[dbo].[Costs]
where recordstatus = 0
and dtstorecontexttypeid in (2,3,4)
and dtchainid is not null
and dtbanner is not null
and dtsupplierid is not null
and PriceChangeCode in ('A','B','W','D')
and PDIParticipant = 0
and ProductIdentifier is not null
and (StoreNumber is null or StoreNumber='')
					

INSERT INTO [DataTrue_Main].[dbo].[MaintenanceRequests]
           ([datatrue_edi_costs_recordid]
           ,[SubmitDateTime]
           ,[RequestTypeID]
           ,[ChainID]
           ,[SupplierID]
           ,[Banner]
           ,[AllStores]
           ,[UPC]
           ,[ItemDescription]
           ,[Cost]
           ,[SuggestedRetail]
           ,[StartDateTime]
           ,[EndDateTime]
           ,[SupplierLoginID]
           ,[dtstorecontexttypeid]
           ,[CostZoneID]
           ,ApprovalDateTime 
			,Approved 
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
			,RequestStatus 
			,Skip_879_889_Conversion_ProcessCompleted 
			,SkipPopulating879_889Records  
			,Requestsource
			,Rawproductidentifier
			           ,[PrimaryGroupLevel]
           ,[AlternateGroupLevel]
           ,[ItemGroup]
           ,[AlternateItemGroup]
           ,[Size]
           ,[ManufacturerIdentifier]
           ,[SellPkgVINAllowReorder]
           ,[SellPkgVINAllowReClaim]
           ,[PrimarySellablePkgIdentifier]
           ,[VIN]
           ,[VINDescription]
           ,[PurchPackDescription]
           ,[PurchPackQty]
           ,[AltSellPackage1]
           ,[AltSellPackage1Qty]
           ,[AltSellPackage1UPC]
           ,[AltSellPackage1Retail]
			
)
SELECT c.[RecordID]
      ,cast([DateCreated] as date)
      ,case when isnull([PriceChangeCode], '') in ('A','W') and RequestTypeID is null then 1 
			when isnull([PriceChangeCode], '') in ('B') and RequestTypeID is null then 2
			when isnull([PriceChangeCode], '') in ('D') and RequestTypeID is null then 9
			else RequestTypeID end
      ,c.dtchainid
      ,c.dtsupplierid
      ,LTRIM(rtrim(dtbanner))
      ,case when dtstorecontexttypeid in (2,3) then 1 else 0 end --[AllStores] 
      ,[ProductIdentifier]
      ,isnull([ProductName], '')
      ,isnull([Cost], 0.0)
      ,isnull([SuggRetail], 0.0)
      ,cast(isnull([EffectiveDate], '12/1/2011') as date)
      --,cast(isnull([EffectiveDate], '12/19/2011') as date)
      ,cast(isnull([EndDate], '12/31/2099') as Date)
      ,isnull([SupplierLoginID], 0.0)
      ,[dtstorecontexttypeid]
      ,[dtcostzoneid]
      ,ApprovalDateTime 
	,Approved 
	,BrandIdentifier 
	,ChainLoginID 
	,isnull(CurrentSetupCost, 0.0)
	,DealNumber
	,DeleteDateTime
	,DeleteLoginId
	,DeleteReason
	,DenialReason 
	,EmailGeneratedToSupplier 
	,EmailGeneratedToSupplierDateTime
	,case when dtsupplierid = 40559 then 17 else isnull(RequestStatus, 0) end
	,Skip_879_889_Conversion_ProcessCompleted 
	,SkipPopulating879_889Records 
	,Recordsource 
	,RawProductIdentifier
	           ,[PrimaryGroupLevel]
           ,[AlternateGroupLevel]
           ,[ItemGroup]
           ,[AlternateItemGroup]
           ,[Size]
           ,[ManufacturerIdentifier]
           ,[SellPkgVINAllowReorder]
           ,[SellPkgVINAllowReClaim]
           ,[PrimarySellablePkgIdentifier]
           ,[VIN]
           ,[VINDescription]
           ,[PurchPackDescription]
           ,[PurchPackQty]
           ,[AltSellPackage1]
           ,[AltSellPackage1Qty]
           ,[AltSellPackage1UPC]
           ,[AltSellPackage1Retail]
	--select *
  FROM [DataTrue_EDI].[dbo].[Costs] c
  inner join tempCOSTrecords_fab t
  on c.RecordID = t. RecordID
  where 1 = 1
  and RecordStatus = 0
  
  
  

update c set c.recordstatus = 1
from [DataTrue_EDI].[dbo].[Costs] c
inner join tempCOSTrecords_fab t
on c.RecordID = t. RecordID
inner join MaintenanceRequests m
on m.datatrue_edi_costs_recordid=c.RecordID

update MaintenanceRequestS
set RequestStatus = 17 
where RequestTypeID = 20
and RequestStatus = 0

if @@rowcount > 0
	begin
	
		exec dbo.prSendEmailNotification_PassEmailAddresses 'NEW TYPE 20 LOADED'
		,'NEW TYPE 20 LOADED IN MR TABLE'
		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;irina.trush@icontroldsd.com'
	
	
	end

commit transaction
drop  table tempCOSTrecords_fab 
end try

begin catch

rollback transaction

end catch

return

    
END
GO
