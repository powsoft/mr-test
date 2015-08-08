USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_OverlappingDates_ReportFile_Create]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_OverlappingDates_ReportFile_Create]
@maintenancerequestid int,
@filename nvarchar(255),
@filepath nvarchar(255),
@requesttypeid smallint --2 = cost 3 = promo

as

--
declare @sql varchar(8000)
/*
if @requesttypeid = 2
	begin
		select @sql = 'bcp "exec DataTrue_main.dbo.prMaintenanceRequest_GetExceptionsToSend_Cost ' + CAST(@maintenancerequestid as nvarchar) + '" queryout ' + @FilePath + @FileName + ' -c  -t, -T -S' + @@servername
	end
*/	
if @requesttypeid = 3
	begin
		select @sql = 'bcp "exec DataTrue_main.dbo.prMaintenanceRequest_GetExceptionsToSend ' + CAST(@maintenancerequestid as nvarchar) + '" queryout ' + @FilePath + @FileName + ' -c  -t, -T -S' + @@servername
	end
	
exec master..xp_cmdshell @sql

return
GO
