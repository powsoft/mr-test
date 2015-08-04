USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_DataScrubbing_GetMRRecords]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_DataScrubbing_GetMRRecords]
as

/*
select top 1000 * from maintenancerequests order by datetimecreated desc
*/

select MaintenanceRequestID as MRID, Banner, UPC, [ItemDescription]
from MaintenanceRequests
where DATEDIFF(day, datetimecreated, getdate()) < 10
order by MaintenanceRequestID


return
GO
