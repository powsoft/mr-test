USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMR_SkipPopulating879_889Records_RecordStatus_update_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[prMR_SkipPopulating879_889Records_RecordStatus_update_PRESYNC_20150329]
	
AS
begin
update r set  r.SkipPopulating879_889Records =ISNULL(c.SkipPopulating879_889Records,0)
from datatrue_edi.dbo.Costs c
inner join MaintenanceRequests r
on datatrue_edi_costs_recordid=c.recordid
and isnull(r.SkipPopulating879_889Records,0) <>ISNULL(c.SkipPopulating879_889Records,0)
and r.datetimecreated>GETDATE()-60




 
update r set  r.SkipPopulating879_889Records =ISNULL(c.SkipPopulating879_889Records,0)
from datatrue_edi.dbo.promotions c
inner join MaintenanceRequests r
on datatrue_edi_promotions_recordid=c.recordid
and isnull(r.SkipPopulating879_889Records,0) <>ISNULL(c.SkipPopulating879_889Records,0)
and r.datetimecreated>GETDATE()-60



update c set requeststatus=25
--select*
from DataTrue_EDI..costs c
inner join Memberships m
on c.dtSupplierID = m.MemberEntityID
and c.dtchainid = m.OrganizationEntityID
and m.MembershipTypeID  in (14)
inner join MaintenanceRequests r
on datatrue_edi_costs_recordid=recordid
where c.PDIParticipant=1
and isnull(c.SkipPopulating879_889Records,0)=0
and RecordStatus in (10,20,35)
and SentToRetailer=0
and c.datetimecreated>GETDATE()-60


update c set requeststatus=35
--select*
from DataTrue_EDI..costs c
inner join MaintenanceRequests r
on datatrue_edi_costs_recordid=recordid
where c.PDIParticipant=1
and RecordStatus<>35
and SentToRetailer=1
and c.datetimecreated>GETDATE()-60

update c set requeststatus=10
--select*
from DataTrue_EDI..costs c
inner join MaintenanceRequests m
on datatrue_edi_costs_recordid=recordid
where c.PDIParticipant=0
and isnull(c.SkipPopulating879_889Records,0)=0
and RecordStatus in (25,20,35)
and SentToRetailer=0
and c.datetimecreated>GETDATE()-60

update c set requeststatus=20
--select*
from DataTrue_EDI..costs c
inner join MaintenanceRequests m
on datatrue_edi_costs_recordid=recordid
where c.PDIParticipant=0
and RecordStatus <>20
and SentToRetailer=1
and c.datetimecreated>GETDATE()-60

update c set Loadstatus=10
--select Loadstatus,c.SkipPopulating879_889Records,c.supplierid,c.chainid,dtbanner,dtmaintenancerequestid,Recordsource,*
from DataTrue_EDI..promotions c
where c.PDIParticipant=0
and isnull(c.SkipPopulating879_889Records,0)=0
and loadStatus in (25,20,35)
and SentToRetailer=0
and c.datetimecreated>GETDATE()-60

update c set Loadstatus=20
--select*
from DataTrue_EDI..promotions c
inner join MaintenanceRequests m
on datatrue_edi_promotions_recordid=recordid
where c.PDIParticipant=0
and Loadstatus <>20
and SentToRetailer=1
and c.datetimecreated>GETDATE()-60

end
GO
