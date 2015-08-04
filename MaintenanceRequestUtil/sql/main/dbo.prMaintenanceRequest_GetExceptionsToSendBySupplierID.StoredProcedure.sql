USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_GetExceptionsToSendBySupplierID]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_GetExceptionsToSendBySupplierID]
@Supplierid int--,
--@requeststatusvalue int
as

declare @requeststatusvalue int=8
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

select * 
--update mr set mr.requeststatus = 108
from maintenancerequests mr where requeststatus = 8
and supplierid = 40570
select * from suppliers where supplierid = 40567
*/
--drop table #tempPendingRecords declare @Supplierid int=40557 declare @requeststatusvalue int=8
declare @MaintenanceRequestid int
declare @rec cursor

		select cast(' ' as nvarchar(50)) as NewOrExisting
			,cast('SubmitDate' as nvarchar(50)) as SubmitDate
			,cast('SubmitBy' as nvarchar(50)) as SubmitBy
			,cast('RequestID' as nvarchar(50)) as RequestID
			,cast('iCProductId' as nvarchar(50)) as ProductID
			,cast('UPC' as nvarchar(50)) as UPC
			,cast('Allowance' as nvarchar(50)) As Allowance
			,cast('AllStores' as nvarchar(50)) As AllStores
			,cast('Banner' as nvarchar(50)) As Banner
			,cast('iCCostZoneID' as nvarchar(50)) As CostZone
			,cast('StoreNumber' as nvarchar(50)) As StoreNumber
			,cast('StartDate' as nvarchar(50)) As StartDate
			,cast('EndDate' as nvarchar(50)) as EndDate
			,cast('PromotionNumber' as nvarchar(50)) as PromotionNumber
			,cast('BatchID' as nvarchar(50)) as BatchID
			,cast('Action (Please type DELETE in the row(s) that will be deleted)' as nvarchar(255)) as [Action]
		into #tempPendingRecords
			
			truncate table #tempPendingRecords

set @rec = CURSOR local fast_forward FOR
	select maintenancerequestid from MaintenanceRequests
	where requeststatus = @requeststatusvalue
	and SupplierID = @Supplierid
	order by maintenancerequestid

open @rec

fetch next from @rec into @MaintenanceRequestid

while @@FETCH_STATUS = 0
	begin
/*
INSERT INTO [#tempPendingRecords]
           ([NewOrExisting]
           ,[SubmitDate]
           ,[SubmitBy]
           ,[RequestID]
           ,[ProductID]
           ,[UPC]
           ,[Allowance]
           ,[AllStores]
           ,[Banner]
           ,[CostZone]
           ,[StoreNumber]
           ,[StartDate]
           ,[EndDate]
           ,[PromotionNumber]
           ,[BatchID]
           ,[Action])
		select ' ' as NewOrExisting
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
*/
INSERT INTO [#tempPendingRecords]
           ([NewOrExisting]
           ,[SubmitDate]
           ,[SubmitBy]
           ,[RequestID]
           ,[ProductID]
           ,[UPC]
           ,[Allowance]
           ,[AllStores]
           ,[Banner]
           ,[CostZone]
           ,[StoreNumber]
           ,[StartDate]
           ,[EndDate]
           ,[PromotionNumber]
           ,[BatchID]
           ,[Action])
		select  ' ' as NewOrExisting
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

INSERT INTO [#tempPendingRecords]
           ([NewOrExisting]
           ,[SubmitDate]
           ,[SubmitBy]
           ,[RequestID]
           ,[ProductID]
           ,[UPC]
           ,[Allowance]
           ,[AllStores]
           ,[Banner]
           ,[CostZone]
           ,[StoreNumber]
           ,[StartDate]
           ,[EndDate]
           ,[PromotionNumber]
           ,[BatchID]
           ,[Action])
		SELECT  Distinct 'New Request' as NewOrExisting
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
			--and mr.MaintenanceRequestID in (35611)

INSERT INTO [#tempPendingRecords]
           ([NewOrExisting]
           ,[SubmitDate]
           ,[SubmitBy]
           ,[RequestID]
           ,[ProductID]
           ,[UPC]
           ,[Allowance]
           ,[AllStores]
           ,[Banner]
           ,[CostZone]
           ,[StoreNumber]
           ,[StartDate]
           ,[EndDate]
           ,[PromotionNumber]
           ,[BatchID]
           ,[Action])
		select  ' ' as NewOrExisting
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

INSERT INTO [#tempPendingRecords]
           ([NewOrExisting]
           ,[SubmitDate]
           ,[SubmitBy]
           ,[RequestID]
           ,[ProductID]
           ,[UPC]
           ,[Allowance]
           ,[AllStores]
           ,[Banner]
           ,[CostZone]
           ,[StoreNumber]
           ,[StartDate]
           ,[EndDate]
           ,[PromotionNumber]
           ,[BatchID]
           ,[Action])
		SELECT  distinct 'Existing Deal' as NewOrExisting
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
		--and mr.MaintenanceRequestID in (35611)
	
		fetch next from @rec into @MaintenanceRequestid	
	end
	
close @rec
deallocate @rec

select * from #tempPendingRecords --where Banner = 'FARM FRESH MARKETS'


select * 
--update mr set mr.requeststatus = 108
from maintenancerequests mr where requeststatus = 8
--and Banner = 'FARM FRESH MARKETS'
and supplierid = 40558


--115(15) and 116(16) is cancelled but questionable

select *
--select distinct requeststatus
--update mr set mr.requeststatus = 116
from maintenancerequests mr
where RequestStatus = 7
and SupplierID = 40557
order by requeststatus

select * 
--update mr set requeststatus = 3
from maintenancerequests mr
 where maintenancerequestid = 208881

select * 
--update mr set requeststatus = 15
from maintenancerequeststores mr
 where maintenancerequestid = 208881


return
GO
