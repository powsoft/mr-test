USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[Utilities_RetireDuplicateRecordsInMaintananceRequestTableUPC_RollBack_20140115]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[Utilities_RetireDuplicateRecordsInMaintananceRequestTableUPC_RollBack_20140115]

as
Begin
 

	begin try
		drop table #tmp1
		drop table #tmp2
		drop table #tmp3
		drop table #tmp4
		drop table #tmp5
		drop table #tmp6
		drop table #tmp7
	end try
	begin catch
	end catch



select count(*) as NoofRecords, m.RequestTypeID , m.upc, m.Banner,  m.AllStores, m.CostZoneID, m.PromoAllowance,m.PromoTypeID,	m.EndDateTime ,	m.StartDateTime,	m.SupplierID,m.Cost 
into #tmp1
from MaintenanceRequests M
where (m.UPC is not null and LEN(LTRIM(rtrim(upc)))>5)  and m.EndDateTime >GETDATE() and (m.RequestStatus <>999) and AllStores=1 and  (m.MarkDeleted is null or m.MarkDeleted =0) and (m.Approved is null or m.approved=1)
group by m.upc, m.Banner, m.AllStores, m.CostZoneID, m.PromoAllowance,m.PromoTypeID, m.EndDateTime ,	m.StartDateTime,	m.SupplierID,m.Cost  ,m.RequestTypeID

select t.NoofRecords,  m.RequestTypeID, m.Banner,m.upc,m.AllStores, m.CostZoneID, m.PromoAllowance,m.PromoTypeID, m.EndDateTime, m.StartDateTime,	m.SupplierID,m.Cost,
	sum(isnull(cast(m.Approved as integer),1000)) as ApprovedAnalysis
into #tmp2
from #tmp1 t 
inner join 
	MaintenanceRequests m on m.upc=t.upc and m.AllStores=t.AllStores and isnull(m.CostZoneID,0)=isnull(t.CostZoneID,0) and m.PromoAllowance=t.PromoAllowance
	and m.PromoTypeID=t.PromoTypeID and m.EndDateTime=t.EndDateTime and m.StartDateTime=t.StartDateTime
	and m.SupplierID=t.SupplierID and m.Cost=t.Cost and m.RequestTypeID=t.RequestTypeID and m.Banner=t.Banner
where t.NoofRecords>1 and  (m.MarkDeleted is null or m.MarkDeleted =0) and (m.Approved is null or m.approved=1)
group by t.NoofRecords, m.RequestTypeID, m.upc, m.Banner, m.AllStores, m.CostZoneID, m.PromoAllowance, m.PromoTypeID,m .EndDateTime, m.StartDateTime,	m.SupplierID,m.Cost

order by 3,7,8


--All Approved---
--select * from #tmp2 t where t.NoofRecords=t.ApprovedAnalysis

select max(m.MaintenanceRequestID )as MaxIds,t.NoofRecords,  m.RequestTypeID, m.upc, m.Banner, m.AllStores, m.CostZoneID, m.PromoAllowance, m.PromoTypeID,	m.EndDateTime ,	m.StartDateTime,	m.SupplierID,m.Cost
into #tmp3
from MaintenanceRequests m 
inner join #tmp2 t on m.upc=t.upc and m.Banner=t.Banner and m.AllStores=t.AllStores and isnull(m.CostZoneID,0)=isnull(t.CostZoneID,0) and m.PromoAllowance=t.PromoAllowance
	and m.PromoTypeID=t.PromoTypeID and m.EndDateTime=t.EndDateTime and m.StartDateTime=t.StartDateTime
	and m.SupplierID=t.SupplierID and m.Cost=t.Cost and m.RequestTypeID=t.RequestTypeID 
where t.NoofRecords=t.ApprovedAnalysis and m.AllStores=1
group by t.NoofRecords,  m.RequestTypeID, m.upc, m.Banner, m.AllStores, m.CostZoneID, m.PromoAllowance,m.PromoTypeID,	m.EndDateTime ,	m.StartDateTime,	m.SupplierID,m.Cost

update MaintenanceRequests set RequestStatus=999 ,DenialReason= 'Marked Duplicate by the Process on ' + cast(getdate() as varchar)
where MaintenanceRequestID in (
select    MaintenanceRequestID	 from MaintenanceRequests m
inner join #tmp2 t on m.upc=t.upc and m.Banner=t.Banner and m.AllStores=t.AllStores and isnull(m.CostZoneID,0)=isnull(t.CostZoneID,0) and m.PromoAllowance=t.PromoAllowance
	and m.PromoTypeID=t.PromoTypeID and m.EndDateTime=t.EndDateTime and m.StartDateTime=t.StartDateTime
	and m.SupplierID=t.SupplierID and m.Cost=t.Cost and m.RequestTypeID=t.RequestTypeID 
left join #tmp3 t1 on m.upc=t1.upc and m.Banner=t1.Banner and m.AllStores=t1.AllStores and  isnull(m.CostZoneID,0)=isnull(t1.CostZoneID,0) and m.PromoAllowance=t1.PromoAllowance
	and m.PromoTypeID=t1.PromoTypeID and m.EndDateTime=t1.EndDateTime and m.StartDateTime=t1.StartDateTime
	and m.SupplierID=t1.SupplierID and m.Cost=t1.Cost and m.RequestTypeID=t1.RequestTypeID 
where t.NoofRecords=t.ApprovedAnalysis and m.MaintenanceRequestID <> t1.MaxIds and m.AllStores=1
									
									)






--All Rejected---
--select * from #tmp2 t where t.ApprovedAnalysis=0

select max(m.MaintenanceRequestID )as MaxIds,t.NoofRecords,  m.RequestTypeID, m.upc, m.Banner, m.AllStores, m.CostZoneID ,m.PromoAllowance, m.PromoTypeID,	m.EndDateTime ,	m.StartDateTime,	m.SupplierID,m.Cost
into #tmp4
from MaintenanceRequests m 
inner join #tmp2 t on m.upc=t.upc and m.AllStores=t.AllStores and isnull(m.CostZoneID,0)=isnull(t.CostZoneID,0) and m.PromoAllowance=t.PromoAllowance
	and m.PromoTypeID=t.PromoTypeID and m.EndDateTime=t.EndDateTime and m.StartDateTime=t.StartDateTime
	and m.SupplierID=t.SupplierID and m.Cost=t.Cost and m.RequestTypeID=t.RequestTypeID and m.Banner=t.Banner
where t.ApprovedAnalysis=0 and m.AllStores=1
group by t.NoofRecords,  m.RequestTypeID, m.upc, m.Banner, m.AllStores, m.CostZoneID, m.PromoAllowance, m.PromoTypeID, m.EndDateTime ,	m.StartDateTime,	m.SupplierID,m.Cost

update MaintenanceRequests set RequestStatus=999 ,DenialReason= 'Marked Duplicate by the Process on ' + cast(getdate() as varchar)
where MaintenanceRequestID in (
select    MaintenanceRequestID	 from MaintenanceRequests m
inner join #tmp2 t on m.upc=t.upc and m.Banner=t.Banner and m.AllStores=t.AllStores and isnull(m.CostZoneID,0)=isnull(t.CostZoneID,0) and m.PromoAllowance=t.PromoAllowance
	and m.PromoTypeID=t.PromoTypeID and m.EndDateTime=t.EndDateTime and m.StartDateTime=t.StartDateTime
	and m.SupplierID=t.SupplierID and m.Cost=t.Cost and m.RequestTypeID=t.RequestTypeID 
left join #tmp4 t1 on m.upc=t1.upc and m.Banner=t1.Banner and m.AllStores=t1.AllStores and  isnull(m.CostZoneID,0)=isnull(t1.CostZoneID,0) and m.PromoAllowance=t1.PromoAllowance
	and m.PromoTypeID=t1.PromoTypeID and m.EndDateTime=t1.EndDateTime and m.StartDateTime=t1.StartDateTime
	and m.SupplierID=t1.SupplierID and m.Cost=t1.Cost and m.RequestTypeID=t1.RequestTypeID 
where t.ApprovedAnalysis=0 and m.MaintenanceRequestID <> t1.MaxIds  and m.AllStores=1
)


--All Pending----
--select * from #tmp2 t where t.NoofRecords*1000 = t.ApprovedAnalysis

select max(m.MaintenanceRequestID )as MaxIds,t.NoofRecords,  m.RequestTypeID, m.upc, m.Banner, m.AllStores, m.CostZoneID,m.PromoAllowance,m.PromoTypeID,	m.EndDateTime ,	m.StartDateTime,	m.SupplierID,m.Cost
into #tmp5
from MaintenanceRequests m 
inner join #tmp2 t on m.upc=t.upc and m.AllStores=t.AllStores and isnull(m.CostZoneID,0)=isnull(t.CostZoneID,0) and m.PromoAllowance=t.PromoAllowance
	and m.PromoTypeID=t.PromoTypeID and m.EndDateTime=t.EndDateTime and m.StartDateTime=t.StartDateTime
	and m.SupplierID=t.SupplierID and m.Cost=t.Cost and m.RequestTypeID=t.RequestTypeID and m.Banner=t.Banner
where t.NoofRecords*1000 = t.ApprovedAnalysis and m.AllStores=1
group by t.NoofRecords,  m.RequestTypeID, m.upc, m.Banner, m.AllStores, m.CostZoneID, m.PromoAllowance, m.PromoTypeID,	m.EndDateTime ,	m.StartDateTime,	m.SupplierID,m.Cost

update MaintenanceRequests set RequestStatus=999 ,DenialReason= 'Marked Duplicate by the Process on ' + cast(getdate() as varchar)
where MaintenanceRequestID in (
select    MaintenanceRequestID	 from MaintenanceRequests m
inner join #tmp2 t on m.upc=t.upc and m.Banner=t.Banner and m.AllStores=t.AllStores and isnull(m.CostZoneID,0)=isnull(t.CostZoneID,0) and m.PromoAllowance=t.PromoAllowance
	and m.PromoTypeID=t.PromoTypeID and m.EndDateTime=t.EndDateTime and m.StartDateTime=t.StartDateTime
	and m.SupplierID=t.SupplierID and m.Cost=t.Cost and m.RequestTypeID=t.RequestTypeID 
left join #tmp5 t1 on m.upc=t1.upc and m.Banner=t1.Banner and m.AllStores=t1.AllStores and  isnull(m.CostZoneID,0)=isnull(t1.CostZoneID,0) and m.PromoAllowance=t1.PromoAllowance
	and m.PromoTypeID=t1.PromoTypeID and m.EndDateTime=t1.EndDateTime and m.StartDateTime=t1.StartDateTime
	and m.SupplierID=t1.SupplierID and m.Cost=t1.Cost and m.RequestTypeID=t1.RequestTypeID 
where t.NoofRecords*1000 = t.ApprovedAnalysis and m.MaintenanceRequestID <> t1.MaxIds  and m.AllStores=1
)


--Some Approved and Some Pending
--select * from #tmp2 t where t.NoofRecords *1000 > t.ApprovedAnalysis and t.ApprovedAnalysis>1000

select max(m.MaintenanceRequestID )as MaxIds,t.NoofRecords,  m.RequestTypeID, m.upc, m.Banner, m.AllStores, m.CostZoneID,m.PromoAllowance,m.PromoTypeID,	m.EndDateTime ,	m.StartDateTime,	m.SupplierID,m.Cost
into #tmp6
from MaintenanceRequests m 
inner join #tmp2 t on m.upc=t.upc and m.AllStores=t.AllStores and isnull(m.CostZoneID,0)=isnull(t.CostZoneID,0) and m.PromoAllowance=t.PromoAllowance
	and m.PromoTypeID=t.PromoTypeID and m.EndDateTime=t.EndDateTime and m.StartDateTime=t.StartDateTime
	and m.SupplierID=t.SupplierID and m.Cost=t.Cost and m.RequestTypeID=t.RequestTypeID and m.Banner=t.Banner
where t.NoofRecords *1000 > t.ApprovedAnalysis and t.ApprovedAnalysis>1000 and m.Approved=1 and m.AllStores=1
group by t.NoofRecords,  m.RequestTypeID, m.upc, m.Banner, m.AllStores, m.CostZoneID, m.PromoAllowance, m.PromoTypeID,	m.EndDateTime ,	m.StartDateTime,	m.SupplierID,m.Cost

update MaintenanceRequests set RequestStatus=999 ,DenialReason= 'Marked Duplicate by the Process on ' + cast(getdate() as varchar)
where MaintenanceRequestID in (
select    MaintenanceRequestID	 from MaintenanceRequests m
inner join #tmp2 t on m.upc=t.upc and m.Banner=t.Banner and m.AllStores=t.AllStores and isnull(m.CostZoneID,0)=isnull(t.CostZoneID,0) and m.PromoAllowance=t.PromoAllowance
	and m.PromoTypeID=t.PromoTypeID and m.EndDateTime=t.EndDateTime and m.StartDateTime=t.StartDateTime
	and m.SupplierID=t.SupplierID and m.Cost=t.Cost and m.RequestTypeID=t.RequestTypeID 
left join #tmp6 t1 on m.upc=t1.upc and m.Banner=t1.Banner and m.AllStores=t1.AllStores and  isnull(m.CostZoneID,0)=isnull(t1.CostZoneID,0) and m.PromoAllowance=t1.PromoAllowance
	and m.PromoTypeID=t1.PromoTypeID and m.EndDateTime=t1.EndDateTime and m.StartDateTime=t1.StartDateTime
	and m.SupplierID=t1.SupplierID and m.Cost=t1.Cost and m.RequestTypeID=t1.RequestTypeID 
where t.NoofRecords *1000 > t.ApprovedAnalysis and t.ApprovedAnalysis>1000 and m.MaintenanceRequestID <> t1.MaxIds  and m.AllStores=1
)


--Some Rejected and Some Pending
--select * from #tmp2 t where t.NoofRecords *1000 > t.ApprovedAnalysis and right(t.ApprovedAnalysis,3)='000'


select max(m.MaintenanceRequestID )as MaxIds,t.NoofRecords,  m.RequestTypeID, m.upc, m.Banner, m.AllStores, m.CostZoneID,m.PromoAllowance,m.PromoTypeID,	m.EndDateTime ,	m.StartDateTime,	m.SupplierID,m.Cost
into #tmp7
from MaintenanceRequests m 
inner join #tmp2 t on m.upc=t.upc and m.AllStores=t.AllStores and isnull(m.CostZoneID,0)=isnull(t.CostZoneID,0) and m.PromoAllowance=t.PromoAllowance
	and m.PromoTypeID=t.PromoTypeID and m.EndDateTime=t.EndDateTime and m.StartDateTime=t.StartDateTime
	and m.SupplierID=t.SupplierID and m.Cost=t.Cost and m.RequestTypeID=t.RequestTypeID and m.Banner=t.Banner 
where t.NoofRecords *1000 > t.ApprovedAnalysis and right(t.ApprovedAnalysis,3)='000' and m.Approved=0 and m.AllStores=1
group by t.NoofRecords,  m.RequestTypeID, m.upc, m.Banner, m.AllStores, m.CostZoneID, m.PromoAllowance, m.PromoTypeID,	m.EndDateTime ,	m.StartDateTime,	m.SupplierID,m.Cost

update MaintenanceRequests set RequestStatus=999 ,DenialReason= 'Marked Duplicate by the Process on ' + cast(getdate() as varchar)
where MaintenanceRequestID in (
select    MaintenanceRequestID	 from MaintenanceRequests m
inner join #tmp2 t on m.upc=t.upc and m.Banner=t.Banner and m.AllStores=t.AllStores and isnull(m.CostZoneID,0)=isnull(t.CostZoneID,0) and m.PromoAllowance=t.PromoAllowance
	and m.PromoTypeID=t.PromoTypeID and m.EndDateTime=t.EndDateTime and m.StartDateTime=t.StartDateTime
	and m.SupplierID=t.SupplierID and m.Cost=t.Cost and m.RequestTypeID=t.RequestTypeID 
left join #tmp7 t1 on m.upc=t1.upc and m.Banner=t1.Banner and m.AllStores=t1.AllStores and  isnull(m.CostZoneID,0)=isnull(t1.CostZoneID,0) and m.PromoAllowance=t1.PromoAllowance
	and m.PromoTypeID=t1.PromoTypeID and m.EndDateTime=t1.EndDateTime and m.StartDateTime=t1.StartDateTime
	and m.SupplierID=t1.SupplierID and m.Cost=t1.Cost and m.RequestTypeID=t1.RequestTypeID 
where t.NoofRecords *1000 > t.ApprovedAnalysis and right(t.ApprovedAnalysis,3)='000' and m.MaintenanceRequestID <> t1.MaxIds  and m.AllStores=1
)


 
--!!!!Reports for Data Anslysts to resolve

	--Some Approved and Some Rejected---
	Select *, 'SomeApproved / SomeRejected' as Problem from #tmp2 t where t.NoofRecords>t.ApprovedAnalysis and t.ApprovedAnalysis <>0
	
	union all
	--Some Rejected / Some Pending / Some Approved
	select *,'Some Rejected / Some Pending / Some Approved' as Problem from #tmp2 t where t.ApprovedAnalysis>1000 and cast(left(t.ApprovedAnalysis,2) as integer)>0   
	and cast(right(t.ApprovedAnalysis,2) as integer)> 0  
	and (cast(left(t.ApprovedAnalysis,2)  as integer) +  cast(right(t.ApprovedAnalysis,2) as integer)) < t.NoofRecords

end
GO
