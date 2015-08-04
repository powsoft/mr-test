USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetAutomatedReportsListLSN_New]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetAutomatedReportsListLSN_New]
as
--exec [prCDCGetAutomatedReportsListLSN]
--sp_columns AutomatedReportsList
declare @MyID int
declare @startlsn binary(10)
declare @endlsn binary(10)
declare @count int
declare @from_lsn binary(10)
declare @to_lsn binary(10)

set @MyID = 0

begin try

--begin transaction

exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMinLSN_TableName 'dbo_AutomatedReportsList',@from_lsn output
exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMaxLSN @to_lsn output--sys.fn_cdc_get_max_lsn();



--print @from_lsn

--print @to_lsn

--Archive all CDC records

/*
--select * into [IC-HQSQL1INST2].[DataTrue_Archive].[dbo].[dbo_AutomatedReportsList_CT] from [IC-HQSQL1\DataTrue].[IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_AutomatedReportsList_CT
--insert into [IC-HQSQL1INST2].[DataTrue_Archive].[dbo].[dbo_AutomatedReportsList_CT] select * from [IC-HQSQL1INST2].[DataTrue_Archive].[dbo].[dbo_AutomatedReportsList_CT]
insert into [IC-HQSQL1INST2].[DataTrue_Archive].[dbo].[dbo_AutomatedReportsList_CT]
([__$start_lsn]
      ,[__$end_lsn]
      ,[__$seqval]
      ,[__$operation]
      ,[__$update_mask]
      ,[ReportID]
,[ReportName]
,[ReportDescreption]
,[StoredProcedureName]
,[Category]
,[SampleImage]
)
SELECT [__$start_lsn]
      ,[__$end_lsn]
      ,[__$seqval]
      ,[__$operation]
      ,[__$update_mask]
      ,[ReportID]
,[ReportName]
,[ReportDescreption]
,[StoredProcedureName]
,[Category]
,[SampleImage]
  FROM [IC-HQSQL1\DataTrue].DataTrue_Main.[cdc].[dbo_AutomatedReportsList_CT]
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn


MERGE INTO [DataTrue_Report].[dbo].AutomatedReportsList t

USING (SELECT __$operation
	 ,[ReportID]
,[ReportName]
,[ReportDescreption]
,[StoredProcedureName]
,[Category]
,[SampleImage]
      	FROM [IC-HQSQL1\DataTrue].DataTrue_Main.[cdc].[dbo_AutomatedReportsList_CT]
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
	and __$operation<>3
		) s
		on t.[ReportID] = s.[ReportID] 

WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
WHEN MATCHED THEN

   UPDATE 
   SET 
   --[LoginID]=s.LoginID

[ReportName]=s.ReportName
,[ReportDescreption]=s.ReportDescreption
,[StoredProcedureName]=s.StoredProcedureName
,[Category]=s.Category
,[SampleImage]=s.SampleImage
 
WHEN NOT MATCHED 

THEN INSERT 
           ([ReportID]
,[ReportName]
,[ReportDescreption]
,[StoredProcedureName]
,[Category]
,[SampleImage])
     VALUES
           (s.ReportID
,s.ReportName
,s.ReportDescreption
,s.StoredProcedureName
,s.Category
,s.SampleImage);

*/
	delete [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_AutomatedReportsList_CT
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
		
		exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
end catch
	

return
GO
