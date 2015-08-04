USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_DataScrubbing_MaintenanceRequests_Update]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prUtil_DataScrubbing_MaintenanceRequests_Update]
@mrid int,
@banner nvarchar(50),
@upc nvarchar(50),
@productdescription nvarchar(255)
--select top 100 * from maintenancerequests
as

update mr set Banner = @banner, UPC = @upc, [ItemDescription] = @productdescription
from MaintenanceRequests mr
where MaintenanceRequestID = @mrid


return
GO
