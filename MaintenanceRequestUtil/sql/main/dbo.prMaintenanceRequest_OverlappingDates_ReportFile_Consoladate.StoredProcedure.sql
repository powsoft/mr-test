USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_OverlappingDates_ReportFile_Consoladate]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prMaintenanceRequest_OverlappingDates_ReportFile_Consoladate]
as

declare @mrid int
declare @recsupplier cursor
declare @recreport cursor
declare @supplierid int

set @recsupplier = CURSOR local fast_forward FOR
	select distinct r.supplierid
	from MaintenanceRequests r
	inner join MaintenanceRequestExceptions e
	on r.MaintenanceRequestID = e.MaintenanceRequestID
	where e.recordstatus = 0
	order by r.supplierid
	
open @recsupplier

fetch next from @recsupplier into @supplierid

while @@FETCH_STATUS = 0
	begin
		exec prMaintenanceRequest_GetExceptionsToSendBySupplier @supplierid		
		fetch next from @recsupplier into @supplierid	
	end
	
close @recsupplier
deallocate @recsupplier
GO
