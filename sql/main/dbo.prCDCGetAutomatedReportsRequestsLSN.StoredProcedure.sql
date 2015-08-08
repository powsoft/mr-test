USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetAutomatedReportsRequestsLSN]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetAutomatedReportsRequestsLSN]
as
--exec [prCDCGetAutomatedReportsRequestsLSN]
--sp_columns AutomatedReportsRequests
declare @MyID int
declare @startlsn binary(10)
declare @endlsn binary(10)
declare @count int
declare @from_lsn binary(10)
declare @to_lsn binary(10)

set @MyID = 0

begin try

--begin transaction



SET @from_lsn = sys.fn_cdc_get_min_lsn(N'dbo_AutomatedReportsRequests');
SET @to_lsn = sys.fn_cdc_get_max_lsn();


--print @from_lsn

--print @to_lsn

--Archive all CDC records

--/*

insert into [IC-HQSQL1INST2].[DataTrue_Archive].[dbo].[dbo_AutomatedReportsRequests_CT]
([__$start_lsn]
      ,[__$end_lsn]
      ,[__$seqval]
      ,[__$operation]
      ,[__$update_mask]
      ,[AutoReportRequestID]
      ,[PersonID]
      ,[ReportID]
      ,[DateRequested]
      ,[LastXDays]
      ,[ChainID]
      ,[Banner]
      ,[SupplierID]
      ,[StoreID]
      ,[ProductUPC]
      ,[GetEveryXDays]
      ,[Days]
      ,[SubscriptionStartDate]
      ,[By12pmEST]
      ,[By5pmEST]
      ,[FileType]
      ,[LastProcessDate]
      ,[RecordCount]
      ,[LastDateSent]
)
SELECT [__$start_lsn]
      ,[__$end_lsn]
      ,[__$seqval]
      ,[__$operation]
      ,[__$update_mask]
      ,[AutoReportRequestID]
      ,[PersonID]
      ,[ReportID]
      ,[DateRequested]
      ,[LastXDays]
      ,[ChainID]
      ,[Banner]
      ,[SupplierID]
      ,[StoreID]
      ,[ProductUPC]
      ,[GetEveryXDays]
      ,[Days]
      ,[SubscriptionStartDate]
      ,[By12pmEST]
      ,[By5pmEST]
      ,[FileType]
      ,[LastProcessDate]
      ,[RecordCount]
      ,[LastDateSent]
  FROM [DataTrue_Main].[cdc].[dbo_AutomatedReportsRequests_CT]
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
--*/

MERGE INTO [DataTrue_Report].[dbo].AutomatedReportsRequests t

USING (SELECT __$operation
	 ,[AutoReportRequestID]
      ,[PersonID]
      ,[ReportID]
      ,[DateRequested]
      ,[LastXDays]
      ,[ChainID]
      ,[Banner]
      ,[SupplierID]
      ,[StoreID]
      ,[ProductUPC]
      ,[GetEveryXDays]
      ,[Days]
      ,[SubscriptionStartDate]
      ,[By12pmEST]
      ,[By5pmEST]
      ,[FileType]
      ,[LastProcessDate]
      ,[RecordCount]
      ,[LastDateSent]
      	FROM cdc.fn_cdc_get_net_changes_dbo_AutomatedReportsRequests(@from_lsn, @to_lsn, 'all')
		where 1 = 1
		) s
		on t.[AutoReportRequestID] = s.[AutoReportRequestID] 

WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
WHEN MATCHED THEN

   UPDATE 
   SET 
   --[LoginID]=s.LoginID
--[AutoReportRequestID]=s.[AutoReportRequestID]
      [PersonID]=s.[PersonID]
      ,[ReportID]=s.[ReportID]
      ,[DateRequested]=s.[DateRequested]
      ,[LastXDays]=s.[LastXDays]
      ,[ChainID]=s.[ChainID]
      ,[Banner]=s.[Banner]
      ,[SupplierID]=s.[SupplierID]
      ,[StoreID]=s.[StoreID]
      ,[ProductUPC]=s.[ProductUPC]
      ,[GetEveryXDays]=s.[GetEveryXDays]
      ,[Days]=s.[Days]
      ,[SubscriptionStartDate]=s.[SubscriptionStartDate]
      ,[By12pmEST]=s.[By12pmEST]
      ,[By5pmEST]=s.[By5pmEST]
      ,[FileType]=s.[FileType]
      ,[LastProcessDate]=s.[LastProcessDate]
      ,[RecordCount]=s.[RecordCount]
      ,[LastDateSent]=s.[LastDateSent]
 
WHEN NOT MATCHED 

THEN INSERT 
           ([AutoReportRequestID]
      ,[PersonID]
      ,[ReportID]
      ,[DateRequested]
      ,[LastXDays]
      ,[ChainID]
      ,[Banner]
      ,[SupplierID]
      ,[StoreID]
      ,[ProductUPC]
      ,[GetEveryXDays]
      ,[Days]
      ,[SubscriptionStartDate]
      ,[By12pmEST]
      ,[By5pmEST]
      ,[FileType]
      ,[LastProcessDate]
      ,[RecordCount]
      ,[LastDateSent])
     VALUES
           (s.[AutoReportRequestID]
      ,s.[PersonID]
      ,s.[ReportID]
      ,s.[DateRequested]
      ,s.[LastXDays]
      ,s.[ChainID]
      ,s.[Banner]
      ,s.[SupplierID]
      ,s.[StoreID]
      ,s.[ProductUPC]
      ,s.[GetEveryXDays]
      ,s.[Days]
      ,s.[SubscriptionStartDate]
      ,s.[By12pmEST]
      ,s.[By5pmEST]
      ,s.[FileType]
      ,s.[LastProcessDate]
      ,s.[RecordCount]
      ,s.[LastDateSent]);


	delete cdc.dbo_AutomatedReportsRequests_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
	
--commit transaction
	
end try
	
begin catch
		--rollback transaction
		
		declare @errormessage varchar(4500)
		declare @errorlocation varchar(255)
		declare @errorsenderstring nvarchar(255)

		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring =  ERROR_PROCEDURE()
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
end catch
	

return
GO
