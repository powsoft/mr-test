USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_OverlappingDates_Report_Send]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_OverlappingDates_Report_Send]
@maintenancerequestid int,
@supplierloginid int,
@requesttypeid smallint

as
/*

*/
--declare @maintenancerequestid int=34401 declare @supplierloginid int=41708 declare @requesttypeid smallint=3
declare @supplieremail nvarchar(100)
declare @ccemail nvarchar(100)='charlie.clark@icontroldsd.com'
declare @filename nvarchar(100)
declare @filepath nvarchar(255)='E:\excelfiles\'
declare @subject nvarchar(255)='iControl - Maintenace Request Exception Report'
declare @body nvarchar(3000)
declare @filepathandname nvarchar(1000)

select @supplieremail = login from Logins where OwnerEntityId = @supplierloginid

set @filename = 'iControl_MRE' + CAST(@supplierloginid as nvarchar) + '_' + CAST(@maintenancerequestid as nvarchar) + '.csv'

exec prMaintenanceRequest_OverlappingDates_ReportFile_Create
	@maintenancerequestid,
	@filename,
	@filepath,
	@requesttypeid
	
set @body = 'You have requested an update on the iControl Maintenance Request system that has conflicting date ranges with an existing setup.  Please review the attached file and indicate which setup should be used.  If you choose the new request, the existing request(s) have to be deleted from the system before the new setup can be applied.  After marking which setups to delete please return the file to MaintenanceRequestExceptions@icontroldsd.com.'
set @filepathandname = @filepath + @filename
	
exec prSendEmailNotification_WithAttachments_PassEmailAddresses
@subject,
@body,
'iControl DataTrue System',
0,
'charlie.clark@icontroldsd.com',
'',
'',
@filepathandname

return
GO
