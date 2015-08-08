USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[Utilities_RetireDuplicateRecordsInMaintananceRequestTableUPC_StoreLevel_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Utilities_RetireDuplicateRecordsInMaintananceRequestTableUPC_StoreLevel_PRESYNC_20150415]

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



select count(*) as NoofRecords, storeid, m.RequestTypeID , 
isnull(m.vin,'') VIN, m.upc, m.Banner,  m.AllStores, m.CostZoneID, 
m.PromoAllowance,m.PromoTypeID,	m.EndDateTime ,	m.StartDateTime,	m.SupplierID,m.Cost 
into #tmp1
from MaintenanceRequests M
inner join MaintenanceRequestStores s
on m.MaintenanceRequestID = s.MaintenanceRequestID
and storeid=79478 and productid=3477380
where (m.UPC is not null and LEN(LTRIM(rtrim(upc)))>5)  and m.EndDateTime >GETDATE() and (m.RequestStatus <>999) and isnull(m.dtstorecontexttypeid,-1)=1 and  (m.MarkDeleted is null or m.MarkDeleted =0) and (m.Approved is null or m.approved=1)
group by storeid, isnull(m.vin,''), m.upc, m.Banner, m.AllStores, m.CostZoneID, m.PromoAllowance,m.PromoTypeID, m.EndDateTime ,	m.StartDateTime,	m.SupplierID,m.Cost  ,m.RequestTypeID

select COUNT(*) from #tmp1

select s.storeid, t.NoofRecords,  m.RequestTypeID, m.Banner,isnull(m.vin,'') VIN, m.upc,m.AllStores, m.CostZoneID, m.PromoAllowance,m.PromoTypeID, m.EndDateTime, m.StartDateTime,	m.SupplierID,m.Cost,
	sum(isnull(cast(m.Approved as integer),1000)) as ApprovedAnalysis
into #tmp2
from #tmp1 t 
inner join 
	MaintenanceRequests m 
	on isnull(m.vin,'')=isnull(t.vin,'')
	 and m.upc=t.upc and m.AllStores=t.AllStores 
	 and isnull(m.CostZoneID,0)=isnull(t.CostZoneID,0) and m.PromoAllowance=t.PromoAllowance
	and m.PromoTypeID=t.PromoTypeID and m.EndDateTime=t.EndDateTime and m.StartDateTime=t.StartDateTime
	and m.SupplierID=t.SupplierID and m.Cost=t.Cost and m.RequestTypeID=t.RequestTypeID and m.Banner=t.Banner
inner join MaintenanceRequestStores s
on m.MaintenanceRequestID = s.MaintenanceRequestID
where t.NoofRecords>1 and  (m.MarkDeleted is null or m.MarkDeleted =0) and (m.Approved is null or m.approved=1)
group by s.storeid, t.NoofRecords, m.RequestTypeID, isnull(m.vin,''), m.upc, m.Banner, m.AllStores, m.CostZoneID, m.PromoAllowance, m.PromoTypeID,m .EndDateTime, m.StartDateTime,	m.SupplierID,m.Cost

order by 4,8,9


--All Approved---
--select * from #tmp2 t where t.NoofRecords=t.ApprovedAnalysis

select max(m.MaintenanceRequestID )as MaxIds, s.storeid, t.NoofRecords,  m.RequestTypeID, isnull(m.vin,'') VIN,m.upc, m.Banner, m.AllStores, m.CostZoneID, m.PromoAllowance, m.PromoTypeID,	m.EndDateTime ,	m.StartDateTime,	m.SupplierID,m.Cost
into #tmp3
from MaintenanceRequests m 
inner join #tmp2 t on isnull(m.vin,'')=isnull(t.vin,'') and m.upc=t.upc and m.Banner=t.Banner and m.AllStores=t.AllStores and isnull(m.CostZoneID,0)=isnull(t.CostZoneID,0) and m.PromoAllowance=t.PromoAllowance
	and m.PromoTypeID=t.PromoTypeID and m.EndDateTime=t.EndDateTime and m.StartDateTime=t.StartDateTime
	and m.SupplierID=t.SupplierID and m.Cost=t.Cost and m.RequestTypeID=t.RequestTypeID 
inner join MaintenanceRequestStores s
on m.MaintenanceRequestID = s.MaintenanceRequestID
where t.NoofRecords=t.ApprovedAnalysis and dtstorecontexttypeid=1
group by s.StoreID, t.NoofRecords,  m.RequestTypeID, isnull(m.vin,''), m.upc, m.Banner, m.AllStores, m.CostZoneID, m.PromoAllowance,m.PromoTypeID,	m.EndDateTime ,	m.StartDateTime,	m.SupplierID,m.Cost

update MaintenanceRequests set RequestStatus=999 ,DenialReason= 'Marked Duplicate by the Process on ' + cast(getdate() as varchar)
where MaintenanceRequestID in (
select    m.MaintenanceRequestID	 from MaintenanceRequests m
inner join MaintenanceRequestStores s
on s.MaintenanceRequestID=m.MaintenanceRequestID
inner join #tmp2 t on isnull(m.vin,'')=isnull(t.vin,'') and m.upc=t.upc and m.Banner=t.Banner and m.AllStores=t.AllStores and isnull(m.CostZoneID,0)=isnull(t.CostZoneID,0) and m.PromoAllowance=t.PromoAllowance
	and m.PromoTypeID=t.PromoTypeID and m.EndDateTime=t.EndDateTime and m.StartDateTime=t.StartDateTime
	and m.SupplierID=t.SupplierID and m.Cost=t.Cost and m.RequestTypeID=t.RequestTypeID 
	and s.StoreID=t.storeid
left join #tmp3 t1 on isnull(m.vin,'')=isnull(t1.vin,'') and m.upc=t1.upc and m.Banner=t1.Banner and m.AllStores=t1.AllStores and  isnull(m.CostZoneID,0)=isnull(t1.CostZoneID,0) and m.PromoAllowance=t1.PromoAllowance
	and m.PromoTypeID=t1.PromoTypeID and m.EndDateTime=t1.EndDateTime and m.StartDateTime=t1.StartDateTime
	and m.SupplierID=t1.SupplierID and m.Cost=t1.Cost and m.RequestTypeID=t1.RequestTypeID 
	and s.StoreID=t1.storeid
where t.NoofRecords=t.ApprovedAnalysis and m.MaintenanceRequestID <> t1.MaxIds and m.dtstorecontexttypeid=1
									
									)




--herenow

--All Rejected---
--select * from #tmp2 t where t.ApprovedAnalysis=0

select max(m.MaintenanceRequestID )as MaxIds,t.storeid, t.NoofRecords,  m.RequestTypeID, isnull(m.vin,'') VIN,m.upc, m.Banner, m.AllStores, m.CostZoneID ,m.PromoAllowance, m.PromoTypeID,	m.EndDateTime ,	m.StartDateTime,	m.SupplierID,m.Cost
into #tmp4
from MaintenanceRequests m 
inner join MaintenanceRequestStores s
on s.MaintenanceRequestID=m.MaintenanceRequestID
inner join #tmp2 t on isnull(m.vin,'')=isnull(t.vin,'') and m.upc=t.upc and m.AllStores=t.AllStores and isnull(m.CostZoneID,0)=isnull(t.CostZoneID,0) and m.PromoAllowance=t.PromoAllowance
	and m.PromoTypeID=t.PromoTypeID and m.EndDateTime=t.EndDateTime and m.StartDateTime=t.StartDateTime
	and m.SupplierID=t.SupplierID and m.Cost=t.Cost and m.RequestTypeID=t.RequestTypeID and m.Banner=t.Banner
where t.ApprovedAnalysis=0 and m.dtstorecontexttypeid=1
group by t.storeid, t.NoofRecords,  m.RequestTypeID, isnull(m.vin,''),m.upc, m.Banner, m.AllStores, m.CostZoneID, m.PromoAllowance, m.PromoTypeID, m.EndDateTime ,	m.StartDateTime,	m.SupplierID,m.Cost

update MaintenanceRequests set RequestStatus=999 ,DenialReason= 'Marked Duplicate by the Process on ' + cast(getdate() as varchar)
where MaintenanceRequestID in (
select    m.MaintenanceRequestID	 from MaintenanceRequests m
inner join MaintenanceRequestStores s
on s.MaintenanceRequestID=m.MaintenanceRequestID
inner join #tmp2 t on isnull(m.vin,'')=isnull(t.vin,'') and m.upc=t.upc and m.Banner=t.Banner and m.AllStores=t.AllStores and isnull(m.CostZoneID,0)=isnull(t.CostZoneID,0) and m.PromoAllowance=t.PromoAllowance
	and m.PromoTypeID=t.PromoTypeID and m.EndDateTime=t.EndDateTime and m.StartDateTime=t.StartDateTime
	and m.SupplierID=t.SupplierID and m.Cost=t.Cost and m.RequestTypeID=t.RequestTypeID 
left join #tmp4 t1 on isnull(m.vin,'')=isnull(t1.vin,'') and m.upc=t1.upc and m.Banner=t1.Banner and m.AllStores=t1.AllStores and  isnull(m.CostZoneID,0)=isnull(t1.CostZoneID,0) and m.PromoAllowance=t1.PromoAllowance
	and m.PromoTypeID=t1.PromoTypeID and m.EndDateTime=t1.EndDateTime and m.StartDateTime=t1.StartDateTime
	and m.SupplierID=t1.SupplierID and m.Cost=t1.Cost and m.RequestTypeID=t1.RequestTypeID 
where t.ApprovedAnalysis=0 and m.MaintenanceRequestID <> t1.MaxIds  and m.dtstorecontexttypeid=1
)


--All Pending----
--select * from #tmp2 t where t.NoofRecords*1000 = t.ApprovedAnalysis

select max(m.MaintenanceRequestID )as MaxIds,t.storeid, t.NoofRecords,  m.RequestTypeID, isnull(m.vin,'') VIN,m.upc, m.Banner, m.AllStores, m.CostZoneID,m.PromoAllowance,m.PromoTypeID,	m.EndDateTime ,	m.StartDateTime,	m.SupplierID,m.Cost
into #tmp5
from MaintenanceRequests m 
inner join MaintenanceRequestStores s
on s.MaintenanceRequestID=m.MaintenanceRequestID
inner join #tmp2 t on isnull(m.vin,'')=isnull(t.vin,'') and m.upc=t.upc and isnull(m.CostZoneID,0)=isnull(t.CostZoneID,0) and m.PromoAllowance=t.PromoAllowance
	and m.PromoTypeID=t.PromoTypeID and m.EndDateTime=t.EndDateTime and m.StartDateTime=t.StartDateTime
	and m.SupplierID=t.SupplierID and m.Cost=t.Cost and m.RequestTypeID=t.RequestTypeID and m.Banner=t.Banner
   and t.storeid = s.storeid
where t.NoofRecords*1000 = t.ApprovedAnalysis and m.dtstorecontexttypeid=1
group by t.storeid,t.NoofRecords,  m.RequestTypeID, isnull(m.vin,''), m.upc, m.Banner, m.AllStores, m.CostZoneID, m.PromoAllowance, m.PromoTypeID,	m.EndDateTime ,	m.StartDateTime,	m.SupplierID,m.Cost

update MaintenanceRequests set RequestStatus=999 ,DenialReason= 'Marked Duplicate by the Process on ' + cast(getdate() as varchar)
where MaintenanceRequestID in (
select    m.MaintenanceRequestID	 from MaintenanceRequests m
inner join MaintenanceRequestStores s
on s.MaintenanceRequestID=m.MaintenanceRequestID
inner join #tmp2 t on isnull(m.vin,'')=isnull(t.vin,'') and m.upc=t.upc and m.Banner=t.Banner and isnull(m.CostZoneID,0)=isnull(t.CostZoneID,0) and m.PromoAllowance=t.PromoAllowance
	and m.PromoTypeID=t.PromoTypeID and m.EndDateTime=t.EndDateTime and m.StartDateTime=t.StartDateTime
	and m.SupplierID=t.SupplierID and m.Cost=t.Cost and m.RequestTypeID=t.RequestTypeID 
	   and t.storeid = s.storeid
left join #tmp5 t1 on t.storeid = t1.storeid and isnull(m.vin,'')=isnull(t1.vin,'') and m.upc=t1.upc and m.Banner=t1.Banner and m.AllStores=t1.AllStores and  isnull(m.CostZoneID,0)=isnull(t1.CostZoneID,0) and m.PromoAllowance=t1.PromoAllowance
	and m.PromoTypeID=t1.PromoTypeID and m.EndDateTime=t1.EndDateTime and m.StartDateTime=t1.StartDateTime
	and m.SupplierID=t1.SupplierID and m.Cost=t1.Cost and m.RequestTypeID=t1.RequestTypeID
	   and t1.storeid = s.storeid 
where t.NoofRecords*1000 = t.ApprovedAnalysis and m.MaintenanceRequestID <> t1.MaxIds  and m.dtstorecontexttypeid=1
)


--Some Approved and Some Pending
--select * from #tmp2 t where t.NoofRecords *1000 > t.ApprovedAnalysis and t.ApprovedAnalysis>1000

select max(m.MaintenanceRequestID )as MaxIds, s.storeid,t.NoofRecords,  m.RequestTypeID, isnull(m.vin,'') VIN,m.upc, m.Banner, m.AllStores, m.CostZoneID,m.PromoAllowance,m.PromoTypeID,	m.EndDateTime ,	m.StartDateTime,	m.SupplierID,m.Cost
into #tmp6
from MaintenanceRequests m 
inner join MaintenanceRequestStores s
on s.MaintenanceRequestID=m.MaintenanceRequestID
inner join #tmp2 t on isnull(m.vin,'')=isnull(t.vin,'') and m.upc=t.upc and m.AllStores=t.AllStores and isnull(m.CostZoneID,0)=isnull(t.CostZoneID,0) and m.PromoAllowance=t.PromoAllowance
	and m.PromoTypeID=t.PromoTypeID and m.EndDateTime=t.EndDateTime and m.StartDateTime=t.StartDateTime
	and m.SupplierID=t.SupplierID and m.Cost=t.Cost and m.RequestTypeID=t.RequestTypeID and m.Banner=t.Banner  
	 and t.storeid = s.storeid
where t.NoofRecords *1000 > t.ApprovedAnalysis and t.ApprovedAnalysis>1000 and m.Approved=1 and m.dtstorecontexttypeid=1

group by t.NoofRecords, s.StoreID, m.RequestTypeID, isnull(m.vin,''), m.upc, m.Banner, m.AllStores, m.CostZoneID, m.PromoAllowance, m.PromoTypeID,	m.EndDateTime ,	m.StartDateTime,	m.SupplierID,m.Cost

update MaintenanceRequests set RequestStatus=999 ,DenialReason= 'Marked Duplicate by the Process on ' + cast(getdate() as varchar)
where MaintenanceRequestID in (
select    m.MaintenanceRequestID	 from MaintenanceRequests m
inner join MaintenanceRequestStores s
on s.MaintenanceRequestID=m.MaintenanceRequestID
inner join #tmp2 t on isnull(m.vin,'')=isnull(t.vin,'') and m.upc=t.upc and m.Banner=t.Banner and m.AllStores=t.AllStores and isnull(m.CostZoneID,0)=isnull(t.CostZoneID,0) and m.PromoAllowance=t.PromoAllowance
	and m.PromoTypeID=t.PromoTypeID and m.EndDateTime=t.EndDateTime and m.StartDateTime=t.StartDateTime
	and m.SupplierID=t.SupplierID and m.Cost=t.Cost and m.RequestTypeID=t.RequestTypeID 
	   and t.storeid = s.storeid
left join #tmp6 t1 on isnull(m.vin,'')=isnull(t1.vin,'') and m.upc=t1.upc and m.Banner=t1.Banner and m.AllStores=t1.AllStores and  isnull(m.CostZoneID,0)=isnull(t1.CostZoneID,0) and m.PromoAllowance=t1.PromoAllowance
	and m.PromoTypeID=t1.PromoTypeID and m.EndDateTime=t1.EndDateTime and m.StartDateTime=t1.StartDateTime
	and m.SupplierID=t1.SupplierID and m.Cost=t1.Cost and m.RequestTypeID=t1.RequestTypeID 
	   and t1.storeid = s.storeid
where t.NoofRecords *1000 > t.ApprovedAnalysis and t.ApprovedAnalysis>1000 and m.MaintenanceRequestID <> t1.MaxIds  and m.dtstorecontexttypeid=1
)

--herenow
--Some Rejected and Some Pending
--select * from #tmp2 t where t.NoofRecords *1000 > t.ApprovedAnalysis and right(t.ApprovedAnalysis,3)='000'


select max(m.MaintenanceRequestID )as MaxIds,s.storeid,t.NoofRecords,  m.RequestTypeID, isnull(m.vin,'') VIN, m.upc, m.Banner, m.AllStores, m.CostZoneID,m.PromoAllowance,m.PromoTypeID,	m.EndDateTime ,	m.StartDateTime,	m.SupplierID,m.Cost
into #tmp7
from MaintenanceRequests m 
inner join MaintenanceRequestStores s
on s.MaintenanceRequestID=m.MaintenanceRequestID
inner join #tmp2 t on isnull(m.vin,'')=isnull(t.vin,'') and m.upc=t.upc and m.AllStores=t.AllStores and isnull(m.CostZoneID,0)=isnull(t.CostZoneID,0) and m.PromoAllowance=t.PromoAllowance
	and m.PromoTypeID=t.PromoTypeID and m.EndDateTime=t.EndDateTime and m.StartDateTime=t.StartDateTime
	and m.SupplierID=t.SupplierID and m.Cost=t.Cost and m.RequestTypeID=t.RequestTypeID and m.Banner=t.Banner 
	   and t.storeid = s.storeid
where t.NoofRecords *1000 > t.ApprovedAnalysis and right(t.ApprovedAnalysis,3)='000' and m.Approved=0 and m.dtstorecontexttypeid=1
group by t.NoofRecords, s.StoreID, m.RequestTypeID, isnull(m.vin,''), m.upc, m.Banner, m.AllStores, m.CostZoneID, m.PromoAllowance, m.PromoTypeID,	m.EndDateTime ,	m.StartDateTime,	m.SupplierID,m.Cost

update MaintenanceRequests set RequestStatus=999 ,DenialReason= 'Marked Duplicate by the Process on ' + cast(getdate() as varchar)
where MaintenanceRequestID in (
select    m.MaintenanceRequestID	 from MaintenanceRequests m
inner join MaintenanceRequestStores s
on s.MaintenanceRequestID=m.MaintenanceRequestID
inner join #tmp2 t on isnull(m.vin,'')=isnull(t.vin,'') and m.upc=t.upc and m.Banner=t.Banner and m.AllStores=t.AllStores and isnull(m.CostZoneID,0)=isnull(t.CostZoneID,0) and m.PromoAllowance=t.PromoAllowance
	and m.PromoTypeID=t.PromoTypeID and m.EndDateTime=t.EndDateTime and m.StartDateTime=t.StartDateTime
	and m.SupplierID=t.SupplierID and m.Cost=t.Cost and m.RequestTypeID=t.RequestTypeID 
	   and t.storeid = s.storeid
left join #tmp7 t1 on isnull(m.vin,'')=isnull(t1.vin,'') and m.upc=t1.upc and m.Banner=t1.Banner and m.AllStores=t1.AllStores and  isnull(m.CostZoneID,0)=isnull(t1.CostZoneID,0) and m.PromoAllowance=t1.PromoAllowance
	and m.PromoTypeID=t1.PromoTypeID and m.EndDateTime=t1.EndDateTime and m.StartDateTime=t1.StartDateTime
	and m.SupplierID=t1.SupplierID and m.Cost=t1.Cost and m.RequestTypeID=t1.RequestTypeID 
	   and t1.storeid = s.storeid
where t.NoofRecords *1000 > t.ApprovedAnalysis and right(t.ApprovedAnalysis,3)='000' and m.MaintenanceRequestID <> t1.MaxIds  and m.dtstorecontexttypeid=1
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
