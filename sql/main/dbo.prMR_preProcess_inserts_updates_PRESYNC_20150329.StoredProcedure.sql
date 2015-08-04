USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMR_preProcess_inserts_updates_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create procedure [dbo].[prMR_preProcess_inserts_updates_PRESYNC_20150329]
as


begin




update m set m.requeststatus=0
--select  m.requeststatus,m.bipad,m.submitdatetime,upc12,m.PDIParticipant,m.Approved,m.DenialReason,m.RequestTypeID,dtstoreid,supplierid,chainid
--,m.Bipad,m.OwnerMarketID,m.RequestTypeID,m.dtstorecontexttypeid,productid,MaintenanceRequestID
from 
DataTrue_EDI..costs c
inner join MaintenanceRequests m
on datatrue_edi_costs_recordid=RecordID
and c.datetimecreated>GETDATE()-15
and m.dtstorecontexttypeid=1
and dtstoreid is not null
and c.Bipad is  null
and m.MaintenanceRequestID not in (select distinct MaintenanceRequestID from MaintenanceRequestStores where datetimecreated>GETDATE()-50)

insert into maintenancerequeststores
			(m.MaintenanceRequestID, StoreID, Included)
		
select m.MaintenanceRequestID,dtstoreid,1

--select  m.requeststatus,m.bipad,m.submitdatetime,upc12,m.PDIParticipant,m.Approved,m.DenialReason,m.RequestTypeID,dtstoreid,supplierid,chainid
from 
DataTrue_EDI..costs c
inner join MaintenanceRequests m
on datatrue_edi_costs_recordid=RecordID
and c.datetimecreated>GETDATE()-15
and m.dtstorecontexttypeid=1
and dtstoreid is not null
and c.Bipad is  null
and m.MaintenanceRequestID not in (select distinct MaintenanceRequestID from MaintenanceRequestStores where datetimecreated>GETDATE()-50)


update r 
 set  SyncToRetailer  = 1
 --select SkipPopulating879_889Records,*
 from MaintenanceRequests r
 inner join Memberships m
 ON m.OrganizationEntityID = r.chainid
 AND m.MemberEntityID = r.supplierid
 AND m.MembershipTypeID = 14
 where RequestStatus = 0 
 and isnull(SyncToRetailer ,0)<>1
			
			end
return
GO
