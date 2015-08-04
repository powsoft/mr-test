USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateJobRunning]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Vince Moore
-- Create date: 05/08/2013
-- Description:	Cleans up entries in table JobRunning that may be left over from a failed process
-- =============================================
CREATE PROCEDURE [dbo].[prValidateJobRunning]
AS
BEGIN
	Declare @RunningJobs table(JobName varchar(100))
	
	Insert Into @RunningJobs (JobName) 
	Select Name
	From MSDB.DBO.sysjobs sj 
	JOIN MSDB.DBO.sysjobactivity sja 
		ON sj.job_id = sja.job_id
	JOIN (SELECT MaxSessionid = MAX(Session_id) FROM MSDB.DBO.syssessions) ss 
		ON ss.MaxSessionid = sja.session_id 
	LEFT JOIN MSDB.DBO.sysjobhistory sjh 
		ON sjh.instance_id = sja.job_history_id     
	Where start_execution_date is not null
	and stop_execution_date is null 
	
	Update JobRunning
	Set JobIsRunningNow = 0
	Where SQLAgentJobName not in(Select JobName From @RunningJobs)
	
END
GO
