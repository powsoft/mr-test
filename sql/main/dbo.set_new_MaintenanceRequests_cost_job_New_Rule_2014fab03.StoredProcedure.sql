USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[set_new_MaintenanceRequests_cost_job_New_Rule_2014fab03]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE [dbo].[set_new_MaintenanceRequests_cost_job_New_Rule_2014fab03]
	
AS


BEGIN

begin try

begin transaction

select recordid
into #tempCOSTrecords
FROM [DataTrue_EDI].[dbo].[Costs]
where recordstatus = 0
and dtstorecontexttypeid is not null
and dtchainid is not null
and dtbanner is not null
and dtsupplierid is not null
and PriceChangeCode in ('A','B','W')


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
			
)
SELECT c.[RecordID]
      ,cast([DateCreated] as date)
      ,case when [PriceChangeCode] in ('A','W') then 1 else 2 end
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
	,isnull(RequestStatus, 0)
	,Skip_879_889_Conversion_ProcessCompleted 
	,SkipPopulating879_889Records  
	--select *
  FROM [DataTrue_EDI].[dbo].[Costs] c
  inner join #tempCOSTrecords t
  on c.RecordID = t. RecordID
  where 1 = 1
  --and RecordStatus = 0
  and PriceChangeCode in ('A','B','W')
  and dtstorecontexttypeid is not null
  
  

update c set c.recordstatus = 1
from [DataTrue_EDI].[dbo].[Costs] c
inner join #tempCOSTrecords t
on c.RecordID = t. RecordID

commit transaction
drop  table #tempCOSTrecords
end try

begin catch

rollback transaction

end catch

return

    
END
GO
