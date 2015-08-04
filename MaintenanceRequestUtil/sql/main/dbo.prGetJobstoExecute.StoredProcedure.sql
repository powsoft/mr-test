USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetJobstoExecute]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[prGetJobstoExecute]

AS

Begin
	
	SELECT [ScheduleID]
      ,[JobInstanceID],[IsAvailableonProduction]
	 FROM [dbo].[JobSchedules]
	where NextRunDate <= Cast(Getdate() as date)
	and NextRunTime <= Cast(Getdate() as time)
	and Status=0
	--select * FROM [dbo].[JobSchedules]
End
GO
