USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetLoginsLSN_New]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetLoginsLSN_New]
as
--exec [prCDCGetLoginsLSN]
declare @MyID int
declare @startlsn binary(10)
declare @endlsn binary(10)
declare @count int
declare @from_lsn binary(10)
declare @to_lsn binary(10)

set @MyID = 0

begin try

--begin transaction



exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMinLSN_TableName 'dbo_Source',@from_lsn output
--SET @to_lsn = 

exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMaxLSN @to_lsn output--sys.fn_cdc_get_max_lsn();


/*
insert into [IC-HQSQL1INST2].[DataTrue_Archive].[dbo].[dbo_Logins_CT]
([__$start_lsn]
      ,[__$end_lsn]
      ,[__$seqval]
      ,[__$operation]
      ,[__$update_mask]
      ,[LoginID]
,[OwnerEntityId]
,[UniqueIdentifier]
,[Login]
,[Password]
,[DateTimeCreated]
,[LastUpdateUserID]
,[DateTimeLastUpdate]
,[Custom1]
,[PDIPartner])
SELECT [__$start_lsn]
      ,[__$end_lsn]
      ,[__$seqval]
      ,[__$operation]
      ,[__$update_mask]
      ,[LoginID]
,[OwnerEntityId]
,[UniqueIdentifier]
,[Login]
,[Password]
,[DateTimeCreated]
,[LastUpdateUserID]
,[DateTimeLastUpdate]
,[Custom1]
,[PDIPartner]
  FROM [IC-HQSQL1\DataTrue].[DataTrue_Main].[cdc].[dbo_Logins_CT]
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn


MERGE INTO [IC-HQSQL1INST2].[DataTrue_Report].[dbo].Logins t

 USING (SELECT __$operation
	 ,[LoginID]
,[OwnerEntityId]
,[UniqueIdentifier]
,[Login]
,[Password]
,[DateTimeCreated]
,[LastUpdateUserID]
,[DateTimeLastUpdate]
,[Custom1]
,[PDIPartner]
from [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.logins      	
		where 1 = 1
		) s
		on t.[LoginID] = s.[LoginID]

WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
WHEN MATCHED THEN

   UPDATE 
   SET 
   --[LoginID]=s.LoginID
[OwnerEntityId]=s.OwnerEntityId
,[UniqueIdentifier]=s.UniqueIdentifier
,[Login]=s.Login
,[Password]=s.Password
,[DateTimeCreated]=s.DateTimeCreated
,[LastUpdateUserID]=s.LastUpdateUserID
,[DateTimeLastUpdate]=s.DateTimeLastUpdate
,[Custom1]=s.[Custom1]
,[PDIPartner]=s.PDIPartner
 
WHEN NOT MATCHED 

THEN INSERT 
           ([LoginID]
,[OwnerEntityId]
,[UniqueIdentifier]
,[Login]
,[Password]
,[DateTimeCreated]
,[LastUpdateUserID]
,[DateTimeLastUpdate]
,[Custom1]
,[PDIPartner])
     VALUES
           (s.[LoginID]
,s.[OwnerEntityId]
,s.[UniqueIdentifier]
,s.[Login]
,s.[Password]
,s.[DateTimeCreated]
,s.[LastUpdateUserID]
,s.[DateTimeLastUpdate]
,s.[Custom1]
,s.[PDIPartner]);
*/
	delete [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_Logins_CT
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
		
		print(@errormessage)
		--exec dbo.prLogExceptionAndNotifySupport
		--1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		--,@errorlocation
		--,@errormessage
		--,@errorsenderstring
		--,@MyID
end catch
	

return
GO
