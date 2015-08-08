USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetManufacturersLSN_New]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetManufacturersLSN_New]
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



exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMinLSN_TableName 'dbo_Manufacturers',@from_lsn output

exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMaxLSN @to_lsn output--sys.fn_cdc_get_max_lsn();


--print @from_lsn

--print @to_lsn

--Archive all CDC records

/*

insert into [IC-HQSQL1INST2].DataTrue_Archive.dbo.dbo_Manufacturers_CT 
select * from [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_Manufacturers_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn


MERGE INTO [DataTrue_Report].[dbo].Manufacturers t

USING (SELECT __$operation,[ManufacturerID]
      ,[ManufacturerName]
      ,[ManufacturerIdentifier]
      ,[ActiveStartDate]
      ,[ActiveLastDate]
      ,[Comments]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,OwnerEntityID
      ,OwnerManufacturerIdentifier
      	FROM [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_Manufacturers_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
	and __$operation<>3
	order by __$start_lsn
		) s
		on t.[ManufacturerID] = s.[ManufacturerID]
		
WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
	
WHEN MATCHED THEN

UPDATE 
   SET [ManufacturerName] = s.ManufacturerName
      ,[ManufacturerIdentifier] = s.ManufacturerIdentifier
      ,[ActiveStartDate] = s.ActiveStartDate
      ,[ActiveLastDate] = s.ActiveLastDate
      ,[Comments] = s.Comments
      ,[DateTimeCreated] = s.DateTimeCreated
      ,[LastUpdateUserID] = s.LastUpdateUserID
      ,[DateTimeLastUpdate] = s.DateTimeLastUpdate
      ,OwnerEntityID=s.OwnerEntityID
      ,OwnerManufacturerIdentifier=s.OwnerManufacturerIdentifier
      
WHEN NOT MATCHED 

THEN INSERT 
           ([ManufacturerID]
           ,[ManufacturerName]
           ,[ManufacturerIdentifier]
           ,[ActiveStartDate]
           ,[ActiveLastDate]
           ,[Comments]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,OwnerEntityID
           ,OwnerManufacturerIdentifier
           )
     VALUES
           (s.ManufacturerID
           ,s.ManufacturerName
           ,s.ManufacturerIdentifier
           ,s.ActiveStartDate
           ,s.ActiveLastDate
           ,s.Comments
           ,s.DateTimeCreated
           ,s.LastUpdateUserID
           ,s.DateTimeLastUpdate
           ,s.OwnerEntityID
           ,s.OwnerManufacturerIdentifier
       );
*/
	delete [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_Manufacturers_CT
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
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
end catch
	

return
GO
