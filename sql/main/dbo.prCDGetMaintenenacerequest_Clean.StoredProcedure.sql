USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDGetMaintenenacerequest_Clean]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDGetMaintenenacerequest_Clean]
as
Begin 
delete from DataTrue_Main.[cdc].[dbo_MaintenanceRequests_CT] 
where datetimecreated <'12/5/2014'
and __$operation=4

end
GO
