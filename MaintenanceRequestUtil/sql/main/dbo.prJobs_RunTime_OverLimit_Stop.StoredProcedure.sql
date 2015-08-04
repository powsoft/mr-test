USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prJobs_RunTime_OverLimit_Stop]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Vince Moore
-- Create date: 05/08/2013
-- Description:	Cleans up entries in table JobRunning that may be left over from a failed process
-- =============================================
CREATE PROCEDURE [dbo].[prJobs_RunTime_OverLimit_Stop]
AS
BEGIN
	--Declare @RunningJobs table(JobName varchar(100))
	declare @rec cursor	
	declare @name nvarchar(100)
	declare @starttime datetime
	
set @rec = CURSOR local fast_forward FOR
	Select Name, start_execution_date
	--select *
	From MSDB.DBO.sysjobs sj 
	JOIN MSDB.DBO.sysjobactivity sja 
		ON sj.job_id = sja.job_id
	JOIN (SELECT MaxSessionid = MAX(Session_id) FROM MSDB.DBO.syssessions) ss 
		ON ss.MaxSessionid = sja.session_id 
	LEFT JOIN MSDB.DBO.sysjobhistory sjh 
		ON sjh.instance_id = sja.job_history_id     
	Where start_execution_date is not null
	and stop_execution_date is null 

Open @rec

fetch next from @rec into @name, @starttime

while @@FETCH_STATUS = 0
	begin
	
		if @name = 'DailyPOSAdjustments_THIS_IS_CURRENT_ONE'
			begin
				if DATEDIFF(minute, @starttime,GETDATE())>180
					begin
						exec [msdb].[dbo].[sp_stop_job] 
							@job_name = 'DailyPOSAdjustments_THIS_IS_CURRENT_ONE'

						exec dbo.prSendEmailNotification_PassEmailAddresses 'POS Adjustments Job Stopped'
								,'The job exceeded the maximum time allowed for it to run.'
								,'DataTrue System', 0, 'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
					end	
			end
		
		if @name = 'LoadInventoryCount'
			begin
				if DATEDIFF(minute, @starttime,GETDATE())>180
					begin
						exec [msdb].[dbo].[sp_stop_job] 
							@job_name = 'LoadInventoryCount'

						exec dbo.prSendEmailNotification_PassEmailAddresses 'LoadInventoryCount Job Stopped'
								,'The job exceeded the maximum time allowed for it to run.'
								,'DataTrue System', 0, 'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
					end	
			end	
	
		if @name = 'WeeklyPOSAdjustmentsBilling'
			begin
				if DATEDIFF(minute, @starttime,GETDATE())>240
					begin
						exec [msdb].[dbo].[sp_stop_job] 
							@job_name = 'WeeklyPOSAdjustmentsBilling'

						exec dbo.prSendEmailNotification_PassEmailAddresses 'WeeklyPOSAdjustmentsBilling Job Stopped'
								,'The job exceeded the maximum time allowed for it to run.'
								,'DataTrue System', 0, 'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
					end	
			end		
	
		if @name = 'DailySUPLoadDeliveriesAndPickups_THIS_IS_CURRENT_ONE_6PM'
			begin
				if DATEDIFF(minute, @starttime,GETDATE())>180
					begin
						exec [msdb].[dbo].[sp_stop_job] 
							@job_name = 'DailySUPLoadDeliveriesAndPickups_THIS_IS_CURRENT_ONE_6PM'

						exec dbo.prSendEmailNotification_PassEmailAddresses 'DeliveriesAndPickups Job Stopped'
								,'The job exceeded the maximum time allowed for it to run.'
								,'DataTrue System', 0, 'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
					end	
			end	

	
		fetch next from @rec into @name, @starttime	
	end
	
close @rec
deallocate @rec	
	
END
GO
