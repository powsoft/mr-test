USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUpdateJobSchedules]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUpdateJobSchedules]
AS
Begin
---------Archiving the job history-----------------------------------
	INSERT INTO DataTrue_Main.[dbo].[JobHistory]
           ([ScheduleID]
           ,[JobInstanceID]
           ,[Status]
           ,[RunDate]
           ,[RunTime]
           ,[DateTimeCreated]
           ,[DateTimeLastUpdate]
           ,[LastUpdateUserID])
		SELECT [ScheduleID]
		  ,[JobInstanceID]
		  ,[Status]
		  ,[NextRunDate]
		  ,[NextRunTime]
		  ,[DateTimeCreated]
		  ,[DateTimeLastUpdate]
		  ,[LastUpdateUserID]
		FROM [dbo].[JobSchedules]
		where Status<>0


Declare @rec CURSOR;
Declare @ScheduleID int;
Declare @JobInstanceID int;
Declare @FrequencyType int;
Declare @NextRunDate date;

Set @rec =CURSOR local fast_forward FOR
			SELECT j.[ScheduleID]
			  ,[JobInstanceID]
			  ,s.[FrequencyType]
			  ,j.NextRunDate
			FROM [dbo].[JobSchedules] j
			join dbo.Schedules s
			on j.ScheduleID=s.ScheduleID
			where Status<>0
	open @rec
	Fetch next from @rec into @ScheduleID,@JobInstanceID,@FrequencyType,@NextRunDate
		while @@FETCH_STATUS=0
			Begin
				---------Updating the next date and time to exeute job--------------
				update j
				set j.NextRunDate= case s.FrequencyType when 2  then DATEADD(day, 1, NextRunDate)
				when 3 then DATEADD(Week, 1, NextRunDate)
				when 4 then DATEADD(month, 1, NextRunDate)
				else NextRunDate
				end,
				status=0,
				j.DateTimeLastUpdate=GETDATE()
				--select * 
				FROM [dbo].[JobSchedules] j
				join dbo.Schedules s
				on j.ScheduleID=s.ScheduleID
				where Status<>0
				and j.ScheduleID=@ScheduleID
				and j.JobInstanceID=@JobInstanceID
				
				Fetch next from @rec into @ScheduleID,@JobInstanceID,@FrequencyType,@NextRunDate
			End
	close @rec
	deallocate @rec
	
End
GO
