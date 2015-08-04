USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[MR_RetireDuplicateRecordsInMaintananceRequestTableUPC_StoreLevel_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[MR_RetireDuplicateRecordsInMaintananceRequestTableUPC_StoreLevel_PRESYNC_20150415]

as
Begin
 
IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='ZZtemp_setMRstore_999') 
                  drop table ZZtemp_setMRstore_999


select  maxMR,storeid,productid,chainid,supplierid,MaintenanceRequestID,StartDateTime 
				into ZZtemp_setMRstore_999
				from 
				(select MAX(m.MaintenanceRequestId)  OVER (PARTITION BY storeid, m.RequestTypeID , 
                isnull(m.vin,'') , m.upc,isnull(PromoAllowance,0),CAST(m.EndDateTime as date) ,
             	CAST(m.StartDateTime as date) ,	m.SupplierID,m.Cost,productid ) as maxMR,s.storeid,m.productid,m.chainid,m.supplierid,m.MaintenanceRequestID,StartDateTime 
				from MaintenanceRequests m
				inner join MaintenanceRequestStores s
				on m.MaintenanceRequestID=s.MaintenanceRequestID
				and upc12 is not null
				and productid is not null
				and RequestStatus not in (5,999)
			    and isnull(Approved,-1)<>0
			    and dtstorecontexttypeid=1
		   		)a
				where maxMR<>MaintenanceRequestID
				
				
				
				update m set RequestStatus=999 ,DenialReason= 'Marked Duplicate by the Process on ' + cast(getdate() as varchar)
              --select * 
              from MaintenanceRequests m
              inner join ZZtemp_setMRstore_999 z
              on m.MaintenanceRequestID=z.MaintenanceRequestID


IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='ZZtemp_setMRstore_999') 
                  drop table ZZtemp_setMRstore_999
	
end
GO
