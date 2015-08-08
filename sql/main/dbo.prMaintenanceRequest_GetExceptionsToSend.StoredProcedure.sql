USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_GetExceptionsToSend]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_GetExceptionsToSend]
@MaintenanceRequestid int
as
/*
declare @mrid int=35321 --35320
select markdeleted as md, * from MaintenanceRequests where MaintenanceRequestID = @mrid
exec prMaintenanceRequest_GetExceptionsToSend @mrid
SELECT     e.MaintenanceRequestID, e.productid, e.brandid, e.UnitValue, e.StartDateTime, e.EndDateTime, e.TradingPartnerPromotionIdentifier, e.datetimecreated, e.BatchID, 
                      e.datedealadded, e.recordstatus
FROM         MaintenanceRequests AS r INNER JOIN
                      MaintenanceRequestExceptions AS e ON r.MaintenanceRequestID = e.MaintenanceRequestID AND r.SupplierID = 40567 AND e.recordstatus = 0 AND 
                      r.CorrectedProductID IS NULL AND e.correctedproductid IS NULL
ORDER BY r.approvaldatetime desc
select * from productprices where productpricetypeid = 8 and productid = 5761 and storeid in (select storeid from costzonerelations where costzoneid = 1774)
*/
select ' ' as 'NewOrExisting'
	,'SubmitDate' as SubmitDate
	,'SubmitBy' as SupplierLoginID
	,'RequestID' as RequestID
	,'iCProductId' as ProductID
	,'UPC' as UPC
	,'Allowance' As Allowance
	,'AllStores' As AllStores
	,'Banner' As Banner
	,'iCCostZoneID' As CostZone
	,'StoreNumber' As StoreNumber
	,'StartDate' As StartDate
	,'EndDate' as EndDate
	,'PromotionNumber' as PromotionNumber
	,'BatchID' as BatchID
	,'Action (Please type DELETE in the row(s) that will be deleted)' as Action
Union All
select  ' ' as 'NewOrOld'
	,' ' as SubmitDate
	,' ' as SupplierLoginID
	,' ' as RequestID
	,' ' as ProductID
	,' ' as UPC
	,' ' As Allowance
	,' ' As AllStores
	,' ' As Banner
	,' ' As CostZone
	,' ' As StoreNumber
	,' ' As StartDate
	,' ' as EndDate
	,' ' as PromotionNumber
	,' ' as BatchID
	,' ' as Action
Union All
SELECT  'New Request' as 'NewOrOld'
	  ,cast(cast(mr.[SubmitDateTime] as date) as nvarchar(50)) as SubmitDate
	  ,cast(dbo.fnGetFirstAndLastWithLoginID(mr.[SupplierLoginID]) as nvarchar(50)) as SupplierLoginID
	  ,cast(mr.[MaintenanceRequestID] as nvarchar(50)) as RequestID
      ,cast(mr.[productid] as nvarchar(50)) as ProductID
      ,cast(mr.[upc] as nvarchar(50)) as UPC
      ,cast(case when mr.[PromoAllowance] > 0 then mr.[PromoAllowance] * -1 else mr.[PromoAllowance] end as nvarchar(50)) As Allowance
      ,cast(case when mr.[AllStores] = 1 then 'YES' else 'NO' end as nvarchar(50)) As AllStores
      ,cast(mr.[Banner] as nvarchar(50)) As Banner
      ,cast(isnull(mr.[CostZoneID], ' ') as nvarchar(50)) As CostZone
      	,' ' As StoreNumber
      ,cast(mr.[StartDateTime] as nvarchar(50)) As StartDate
      ,cast(mr.[EndDateTime] as nvarchar(50)) as EndDate
      ,cast(isnull(mr.[TradingPartnerPromotionIdentifier], ' ') as nvarchar(50)) as PromotionNumber
      ,cast(' ' as nvarchar(50)) as BatchID
      ,' ' as Action
      from MaintenanceRequests mr
      inner join MaintenanceRequestExceptions me
      on mr.MaintenanceRequestID = me.MaintenanceRequestID
	where mr.MaintenanceRequestid = @MaintenanceRequestid
	and me.recordstatus = 0
	and mr.correctedproductid is null and me.correctedproductid is null
Union All
select  ' ' as 'NewOrOld'
	,' ' as SubmitDate
	,' ' as SupplierLoginID
	,' ' as RequestID
	,' ' as ProductID
	,' ' as UPC
	,' ' As Allowance
	,' ' As AllStores
	,' ' As Banner
	,' ' As CostZone
		,' ' As StoreNumber
	,' ' As StartDate
	,' ' as EndDate
	,' ' as PromotionNumber
	,' ' as BatchID
    ,' ' as Action
Union All
SELECT  distinct 'Existing Deal' as 'NewOrOld'
	  ,cast(re.datedealadded as nvarchar(50)) as SubmitDate
		,' ' as SupplierLoginID
	  ,' '  as RequestID
      ,cast(re.[productid] as nvarchar(50)) as ProductID
      ,cast(mr.[upc] as nvarchar(50)) as UPC
      ,cast(case when re.[UnitValue] > 0 then re.[UnitValue] * -1 else re.[UnitValue] end as nvarchar(50)) As Allowance
      ,cast(case when mr.[AllStores] = 1 then 'YES' else 'NO' end as nvarchar(50)) As AllStores
      ,cast(mr.[Banner] as nvarchar(50)) As Banner
      ,cast(isnull(mr.[CostZoneID], ' ') as nvarchar(50)) As CostZone
      	,' ' As StoreNumber
      ,cast(re.[StartDateTime] as nvarchar(50)) As StartDate
      ,cast(re.[EndDateTime] as nvarchar(50)) as EndDate
      ,cast(isnull(re.[TradingPartnerPromotionIdentifier], ' ') as nvarchar(50)) as PromotionNumber
      ,'' as BatchID
      --,cast(re.[BatchID] as nvarchar(50)) as BatchID
      ,' ' as Action
  FROM dbo.MaintenanceRequestExceptions re
  inner join MaintenanceRequests mr
  on re.maintenancerequestid = mr.MaintenanceRequestID
where re.MaintenanceRequestid = @MaintenanceRequestid
and recordstatus = 0 and re.correctedproductid is null





return
GO
