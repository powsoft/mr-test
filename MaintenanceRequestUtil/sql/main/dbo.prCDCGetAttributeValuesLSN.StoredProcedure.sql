USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetAttributeValuesLSN]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetAttributeValuesLSN]
as

declare @MyID int
declare @startlsn binary(10)
declare @endlsn binary(10)
declare @count int
declare @from_lsn binary(10)
declare @to_lsn binary(10)

set @MyID = 0

begin try

begin transaction



SET @from_lsn = sys.fn_cdc_get_min_lsn(N'dbo_AttributeValues');
SET @to_lsn = sys.fn_cdc_get_max_lsn();


--print @from_lsn

--print @to_lsn

--Archive all CDC records

--/*

insert into DataTrue_Archive..dbo_AttributeValues_CT 
select * from cdc.dbo_AttributeValues_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
--*/

MERGE INTO [DataTrue_Report].[dbo].AttributeValues t

USING (SELECT __$operation
	  ,[OwnerEntityID]
      ,[AttributeID]
      ,[AttributeValue]
      ,[IsActive]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      	FROM cdc.fn_cdc_get_net_changes_dbo_AttributeValues(@from_lsn, @to_lsn, 'all')
		where 1 = 1
		) s
		on t.[OwnerEntityID] = s.[OwnerEntityID]
		and t.[AttributeID]=s.[AttributeID]
		and t.[AttributeValue]=s.[AttributeValue]

WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
WHEN MATCHED THEN

   UPDATE 
   SET [OwnerEntityID] = s.OwnerEntityID
      ,[AttributeID] = s.AttributeID
      ,[AttributeValue] = s.AttributeValue
      ,[IsActive] = s.IsActive
      ,[DateTimeCreated] = s.DateTimeCreated
      ,[LastUpdateUserID] = s.LastUpdateUserID
      ,[DateTimeLastUpdate] = s.DateTimeLastUpdate


WHEN NOT MATCHED 

THEN INSERT 
           ([OwnerEntityID]
           ,[AttributeID]
           ,[AttributeValue]
           ,[IsActive]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate])
     VALUES
           (s.OwnerEntityID
           ,s.AttributeID
           ,s.AttributeValue
           ,s.IsActive
           ,s.DateTimeCreated
           ,s.LastUpdateUserID
           ,s.DateTimeLastUpdate
           );

	delete cdc.dbo_AttributeValues_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
	
commit transaction
	
end try
	
begin catch
		rollback transaction
		
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
