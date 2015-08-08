USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[ZNU_prGetMaintenanceRequestExceptionsToSend]    Script Date: 06/25/2015 18:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[ZNU_prGetMaintenanceRequestExceptionsToSend]
@MaintenanceRequestid int
as
/*
prGetMaintenanceRequestExceptionsToSend 34401
*/
select ' ' as 'NewOrExisting'
	,'SubmitDate' as SubmitDate
	,'RequestID' as RequestID
	,'iCProductId' as ProductID
	,'UPC' as UPC
	,'Allowance' As Allowance
	,'AllStores' As AllStores
	,'Banner' As Banner
	,'iCCostZoneID' As CostZone
	,'StartDate' As StartDate
	,'EndDate' as EndDate
	,'PromotionNumber' as PromotionNumber
	,'BatchID' as BatchID
Union All
select  ' ' as 'NewOrOld'
	,' ' as SubmitDate
	,' ' as RequestID
	,' ' as ProductID
	,' ' as UPC
	,' ' As Allowance
	,' ' As AllStores
	,' ' As Banner
	,' ' As CostZone
	,' ' As StartDate
	,' ' as EndDate
	,' ' as PromotionNumber
	,' ' as BatchID
Union All
SELECT  'New Request' as 'NewOrOld'
	  ,cast(cast(mr.[SubmitDateTime] as date) as nvarchar(50)) as SubmitDate
	  ,cast(mr.[MaintenanceRequestID] as nvarchar(50)) as RequestID
      ,cast(mr.[productid] as nvarchar(50)) as ProductID
      ,cast(mr.[upc] as nvarchar(50)) as UPC
      ,cast(mr.[PromoAllowance] as nvarchar(50)) As Allowance
      ,cast(case when mr.[AllStores] = 1 then 'YES' else 'NO' end as nvarchar(50)) As AllStores
      ,cast(mr.[Banner] as nvarchar(50)) As Banner
      ,cast(isnull(mr.[CostZoneID], ' ') as nvarchar(50)) As CostZone
      ,cast(mr.[StartDateTime] as nvarchar(50)) As StartDate
      ,cast(mr.[EndDateTime] as nvarchar(50)) as EndDate
      ,cast(isnull(mr.[TradingPartnerPromotionIdentifier], ' ') as nvarchar(50)) as PromotionNumber
      ,cast(' ' as nvarchar(50)) as BatchID
      from MaintenanceRequests mr
	where mr.MaintenanceRequestid = @MaintenanceRequestid
Union All
select  ' ' as 'NewOrOld'
	,' ' as SubmitDate
	,' ' as RequestID
	,' ' as ProductID
	,' ' as UPC
	,' ' As Allowance
	,' ' As AllStores
	,' ' As Banner
	,' ' As CostZone
	,' ' As StartDate
	,' ' as EndDate
	,' ' as PromotionNumber
	,' ' as BatchID
Union All
SELECT  'Existing Deal' as 'NewOrOld'
	  ,cast(re.datedealadded as nvarchar(50)) as SubmitDate
	  ,' '  as RequestID
      ,cast(re.[productid] as nvarchar(50)) as ProductID
      ,cast(mr.[upc] as nvarchar(50)) as UPC
      ,cast(re.[UnitValue] as nvarchar(50)) As Allowance
      ,cast(case when mr.[AllStores] = 1 then 'YES' else 'NO' end as nvarchar(50)) As AllStores
      ,cast(mr.[Banner] as nvarchar(50)) As Banner
      ,cast(isnull(mr.[CostZoneID], ' ') as nvarchar(50)) As CostZone
      ,cast(re.[StartDateTime] as nvarchar(50)) As StartDate
      ,cast(re.[EndDateTime] as nvarchar(50)) as EndDate
      ,cast(isnull(re.[TradingPartnerPromotionIdentifier], ' ') as nvarchar(50)) as PromotionNumber
      ,cast(re.[BatchID] as nvarchar(50)) as BatchID
  FROM dbo.MaintenanceRequestExceptions re
  inner join MaintenanceRequests mr
  on re.maintenancerequestid = mr.MaintenanceRequestID
where re.MaintenanceRequestid = @MaintenanceRequestid





return
GO
