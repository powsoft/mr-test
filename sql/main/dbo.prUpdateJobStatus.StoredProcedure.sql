USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUpdateJobStatus]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prUpdateJobStatus]
	@ScheduleId int,
	@JobInstanceId int,
	@StatusId tinyint
As
Begin
	update JobSchedules set Status=@StatusId
	where ScheduleId=@ScheduleId
	and JobInstanceId=@JobInstanceId
End
GO
