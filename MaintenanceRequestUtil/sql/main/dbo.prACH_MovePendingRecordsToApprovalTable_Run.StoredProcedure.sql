USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prACH_MovePendingRecordsToApprovalTable_Run]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[prACH_MovePendingRecordsToApprovalTable_Run]
AS
BEGIN

BEGIN TRY

WHILE (
SELECT COUNT(RecordID)
FROM DataTrue_EDI.dbo.Inbound846Inventory_ACH
WHERE RecordStatus = 0
) > 0
	BEGIN
		if DATEDIFF(mi,convert(time,stuff(stuff('135700',3,0,':'),6,0,':')),CONVERT(time,getdate())) >20
 			begin
				EXEC DataTrue_Main.dbo.[prSendEmailNotification_PassEmailAddresses_HTML_Logos] 'Billing_Regulated_NewEDIData Warning'
				,'Step prACH_MovePendingRecordsToApprovalTable has been running for longer than 20 minutes.  Please review pending records.'
				,'DataTrue System', 0
				,'datatrueit@icontroldsd.com; edi@icontroldsd.com'
   				break
			end

		EXEC DATATRUE_MAIN.dbo.prACH_MovePendingRecordsToApprovalTable
	END

END TRY

BEGIN CATCH
declare @errormessage varchar(500)
	declare @errorlocation varchar(500)
	declare @errorsenderstring varchar(500)

	set @errormessage = error_message()
	set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
	set @errorsenderstring = ERROR_PROCEDURE()
	
	declare @emailbody varchar(max)
	set @emailbody = 'An exception occurred in [prACH_MovePendingRecordsToApprovalTable_Run].  Manual review, resolution, and re-start will be required for the job to continue. Error Message: ' + @errormessage
	
	exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated_NewEDIJob Job Stopped'
			,@emailbody
			,'DataTrue System', 0, 'william.heine@icucsolutions.com'--'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
	
	IF EXISTS(     
		select 1 
		from msdb.dbo.sysjobs_view job  
		inner join msdb.dbo.sysjobactivity activity on job.job_id = activity.job_id 
		where  
			activity.run_Requested_date is not null  
		and activity.stop_execution_date is null  
		and job.name = 'Billing_Regulated_NewEDIData' 
	) 
	Begin
		exec [msdb].[dbo].[sp_stop_job] 
		@job_name = 'Billing_Regulated_NewEDIData'
	End
END CATCH

END
GO
