USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_UpdateProductStatusByMaintenanceRequestID]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_UpdateProductStatusByMaintenanceRequestID]
	@maintenancerequestids nvarchar(512)
as
Begin
	declare @strQuery nvarchar(max)
	Set @strQuery='update MaintenanceRequests Set RequestStatus=-31	where MaintenanceRequestID in ('+@maintenancerequestids+')';
	exec (@strQuery)
	
end
GO
