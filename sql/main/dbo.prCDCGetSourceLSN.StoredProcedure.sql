USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetSourceLSN]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetSourceLSN]
as

declare @MyID int
declare @startlsn binary(10)
declare @endlsn binary(10)
declare @count int
declare @from_lsn binary(10)
declare @to_lsn binary(10)

set @MyID = 0

begin try

--begin transaction



--SET @from_lsn = 
exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMinLSN_TableName 'dbo_Source',@from_lsn output
--SET @to_lsn = 

exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMaxLSN @to_lsn output--sys.fn_cdc_get_max_lsn();

--Archive all CDC records


/*
insert into [IC-HQSQL1INST2].DataTrue_Archive.dbo.dbo.dbo_Source_CT 
select * from [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_Source_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
*/

MERGE INTO [DataTrue_Main].[dbo].Source_Test t

USING (SELECT __$operation,[SourceID]
      ,[SourceTypeID]
      ,[SourceName]
      ,[SourceLocation]
      ,[DateTimeReceived]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,SourceEntityID
      ,BatchID
      from [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_Source_CT
      	--FROM [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.fn_cdc_get_net_changes_dbo_Source(@from_lsn, @to_lsn, 'all')
		where 1 = 1 and __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
		) s
		on t.[SourceID] = s.[SourceID]
		
WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
	
WHEN MATCHED THEN

UPDATE 
   SET [SourceTypeID] = s.SourceTypeID
      ,[SourceName] = s.SourceName
      ,[SourceLocation] = s.SourceLocation
      ,[DateTimeReceived] = s.DateTimeReceived
      ,[DateTimeCreated] = s.DateTimeCreated
      ,[LastUpdateUserID] = s.LastUpdateUserID
      ,[DateTimeLastUpdate] = s.DateTimeLastUpdate
      ,SourceEntityID=s.SourceEntityID
      ,BatchID=s.BatchID

      
WHEN NOT MATCHED 

THEN INSERT 
           ([SourceID]
           ,[SourceTypeID]
           ,[SourceName]
           ,[SourceLocation]
           ,[DateTimeReceived]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,SourceEntityID
           ,BatchID)
     VALUES
           (s.[SourceID]
           ,s.SourceTypeID
           ,s.SourceName
           ,s.SourceLocation
           ,s.DateTimeReceived
           ,s.DateTimeCreated
           ,s.LastUpdateUserID
           ,s.DateTimeLastUpdate
           ,s.SourceEntityID
           ,s.BatchID
       );

	delete [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_Source_CT
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
		print @errormessage
		--exec dbo.prLogExceptionAndNotifySupport
		--1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		--,@errorlocation
		--,@errormessage
		--,@errorsenderstring
		--,@MyID
end catch
	

return
GO
