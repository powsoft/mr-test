USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_OverlappingDates_Report_Send_BySupplier]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_OverlappingDates_Report_Send_BySupplier]
@supplierloginid int,
@requesttypeid smallint

as
/*
select *
from MaintenanceRequests
where requeststatus = 8
*/
--declare @supplierloginid int=0 declare @requesttypeid smallint=3
declare @supplieremail nvarchar(100)
declare @ccemail nvarchar(100)='charlie.clark@icontroldsd.com'
declare @filename nvarchar(100)
declare @filepath nvarchar(255)='E:\excelfiles\'
declare @subject nvarchar(255)='iControl - Maintenace Request Exception Report'
declare @body nvarchar(3000)
declare @filepathandname nvarchar(1000)
declare @recsupplierloginid cursor
declare @mrid int

select @supplieremail = login from Logins where OwnerEntityId = @supplierloginid


set @recsupplierloginid = CURSOR local fast_forward FOR
	select maintenancerequestid from MaintenanceRequests
	where requeststatus = 8
	and supplierloginid = @supplierloginid
	and SupplierID = 40557 
	order by maintenancerequestid
/*
select * from MaintenanceRequests where supplierid = 40557 and requeststatus in (8, 108) order by maintenancerequestid
*/	
open @recsupplierloginid

fetch next from @recsupplierloginid into @mrid

while @@FETCH_STATUS = 0
	begin
	
		set @filename = 'iControl_MRE' + CAST(@supplierloginid as nvarchar) + '_' + CAST(@mrid as nvarchar) + '.csv'

		exec prMaintenanceRequest_OverlappingDates_ReportFile_Create
			@mrid,
			@filename,
			@filepath,
			@requesttypeid
		fetch next from @recsupplierloginid into @mrid

	end
	
close @recsupplierloginid
deallocate @recsupplierloginid
	
set @body = 'You have requested an update on the iControl Maintenance Request system that has conflicting date ranges with an existing setup.  Please review the attached file and indicate which setup should be used.  If you choose the new request, the existing request(s) have to be deleted from the system before the new setup can be applied.  After marking which setups to delete please return the file to MaintenanceRequestExceptions@icontroldsd.com.'
set @filepathandname = @filepath + @filename

/*	
exec prSendEmailNotification_WithAttachments_PassEmailAddresses
@subject,
@body,
'iControl DataTrue System',
0,
'charlie.clark@icontroldsd.com',
'',
'',
@filepathandname
*/

return
GO
