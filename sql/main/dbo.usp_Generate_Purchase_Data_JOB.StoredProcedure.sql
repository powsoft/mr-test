USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Generate_Purchase_Data_JOB]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec [usp_Generate_Purchase_Data_JOB]
CREATE procedure [dbo].[usp_Generate_Purchase_Data_JOB]
as 
Begin
	declare @OldRecordCount varchar(100)
	declare @EmailMessage varchar(1000)
	declare @ToEmailId as varchar(50)
	
	set @ToEmailId='edi@icontroldsd.com;vishal.gupta@icontroldsd.com'
	
	begin try
		exec msdb..sp_send_dbmail @profile_name ='DataTrue System',@recipients=@ToEmailId,
				@subject='VMI Job Started !',@body='VMI Job has been started.',@body_format = 'HTML'
	end try
	begin catch
	end catch
	
	;with AllDates AS
	(
		SELECT SupplierId, ChainId, isNull(dateadd(d,1,LastExecutionTime),FirstPODate) as ForDate, dateadd(d,RunJobEveryXDays-1,isNull(LastExecutionTime,FirstPODate)) as ToDate 
			from POJobScheduler ST
			where ISNULL(LastExecutionTime,dateadd(d,-RunJobEveryXDays,FirstPODate))=cast(GETDATE()-RunJobEveryXDays as date)
		
		UNION ALL
		
		SELECT SupplierId, ChainId, dateadd(d,1,ForDate), ToDate FROM AllDates WHERE ToDate>ForDate
	)
	select SupplierId, ChainId, CAST(ForDate as varchar) as ForDate into #tmpJobSchedule from AllDates  order by 1,2,3
	OPTION (MAXRECURSION 0)
	
	Declare @SupplierId varchar(10), @ChainID varchar(10), @ForDate date
	
	DECLARE JOB_CURSOR CURSOR FOR 
		
	Select * from #tmpJobSchedule	
	
	OPEN JOB_CURSOR;
		FETCH NEXT FROM JOB_CURSOR INTO @SupplierId, @ChainId, @ForDate
	
		while @@FETCH_STATUS = 0
			begin
				
				exec [usp_Generate_Purchase_Data_New] @SupplierId, @ChainId, '', '-1', '', @ForDate	
				FETCH NEXT FROM JOB_CURSOR INTO @SupplierId, @ChainId, @ForDate
			end
	CLOSE JOB_CURSOR;
	DEALLOCATE JOB_CURSOR;
	
	--select * from PO_PurchaseOrderHistoryData --where StoreSetupId in (59229,59234) order by 1,2
--			update PO_Criteria set PlanogramCapacityMin=15, PlanogramCapacityMax=50 where StoreSetupId=59234
	Update POJobScheduler set LastExecutionTime=GETDATE() where ISNULL(LastExecutionTime,dateadd(d,-RunJobEveryXDays,FirstPODate))=cast(GETDATE()-RunJobEveryXDays as date)
	--Update POJobScheduler set FirstPODate=getDate(), LastExecutionTime=NULL where supplierid=44246
	--select * from POJobScheduler
	
	--Send Bulk Order Files
	begin try
		exec [usp_GenerateAndSendBulkOrderFile]
	end try
	begin catch
		set @EmailMessage=N'Error in sending the Bulk Order File.<br><br>'
	end catch
	
	--Send Detailed Order Files
	begin try
		exec [usp_GenerateAndSendDetailedOrderFile]
	end try
	begin catch
		set @EmailMessage=@EmailMessage+N'Error in sending the Detailed Order File.<br><br>'
	end catch
	
	begin try
		exec [dbo].[prCDCGetPO_PurchaseOrderHistoryDataLSN]
	end try
	begin catch
		set @EmailMessage=@EmailMessage+N'VMI Job Failed while creating records in the CDC table.<br><br>'
	end catch
	
	if(@EmailMessage<>'')
		set	@EmailMessage=N'VMI Job has been completed.<br><br>'
	 else
		set	@EmailMessage=N'VMI Job has been completed with the following errors.<br><br>' + @EmailMessage
	 
	select @EmailMessage=N'Total Number of records created are:' + cast(count(RecordId) as varchar) from PO_PurchaseOrderHistoryData	
	where cast(POGenerationDate as date) = cast(getdate() as date)
	
	begin try
		exec msdb..sp_send_dbmail @profile_name ='DataTrue System',@recipients=@ToEmailId,
			@subject='VMI Job Completed !',@body=@EmailMessage, @body_format = 'HTML' 
	end try
	begin catch
	end catch
		
End
GO
