USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetAssignUserRoles_NewLSN_New]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetAssignUserRoles_NewLSN_New]
as
--exec [prCDCGetAssignUserRoles_NewLSN]
declare @MyID int
declare @startlsn binary(10)
declare @endlsn binary(10)
declare @count int
declare @from_lsn binary(10)
declare @to_lsn binary(10)

set @MyID = 0

begin try

--begin transaction
exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMinLSN_TableName 'dbo_AssignUserRoles_New',@from_lsn output
exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMaxLSN @to_lsn output--sys.fn_cdc_get_max_lsn();

--print @from_lsn

--print @to_lsn

--Archive all CDC records

/*
--
-- drop table [IC-HQSQL1INST2].[DataTrue_Archive].[dbo].[dbo_AssignUserRoles_New_CT]
--select * into [IC-HQSQL1INST2].[DataTrue_Archive].[dbo].[dbo_AssignUserRoles_New_CT] from [IC-HQSQL1\DataTrue].[IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_AssignUserRoles_New_CT
--insert into [IC-HQSQL1INST2].[DataTrue_Archive].[dbo].[dbo_AssignUserRoles_New_CT] select * from [IC-HQSQL1INST2].[DataTrue_Archive].[dbo].[dbo_AssignUserRoles_New_CT]

insert into [IC-HQSQL1INST2].[DataTrue_Archive].[dbo].[dbo_AssignUserRoles_New_CT]
([__$start_lsn]
      ,[__$end_lsn]
      ,[__$seqval]
      ,[__$operation]
      ,[__$update_mask]
      ,[RecordID]
,[UserID]
,[RoleID]
)
SELECT [__$start_lsn]
      ,[__$end_lsn]
      ,[__$seqval]
      ,[__$operation]
      ,[__$update_mask]
      ,[RecordID]
,[UserID]
,[RoleID]

  FROM [IC-HQSQL1\DataTrue].DataTrue_Main.[cdc].[dbo_AssignUserRoles_New_CT]
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
	


MERGE INTO [DataTrue_Report].[dbo].AssignUserRoles_New t

USING (SELECT __$operation
	 ,[RecordID]
,[UserID]
,[RoleID]

      	FROM [IC-HQSQL1\DataTrue].DataTrue_Main.[cdc].[dbo_AssignUserRoles_New_CT]
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
	and __$operation<>3
		) s
		on t.[RecordID] = s.[RecordID]

WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
WHEN MATCHED THEN

   UPDATE 
   SET 
  
[UserID]=s.UserID
,[RoleID]=s.RoleID
 
WHEN NOT MATCHED 

THEN INSERT 
           ( [RecordID]
,[UserID]
,[RoleID]
)
     VALUES
           ( s.[RecordID]
,s.[UserID]
,s.[RoleID]
);
*/

	delete [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_AssignUserRoles_New_CT
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
		--print(@errormessage)
		exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
end catch
	

return
GO
