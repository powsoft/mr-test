USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetManufacturersLSN]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetManufacturersLSN]
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



SET @from_lsn = sys.fn_cdc_get_min_lsn(N'dbo_Manufacturers');
SET @to_lsn = sys.fn_cdc_get_max_lsn();


--print @from_lsn

--print @to_lsn

--Archive all CDC records

--/*

insert into DataTrue_Archive..dbo_Manufacturers_CT 
select * from cdc.dbo_Manufacturers_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
--*/

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
      	FROM cdc.fn_cdc_get_net_changes_dbo_Manufacturers(@from_lsn, @to_lsn, 'all')
		where 1 = 1
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

	delete cdc.dbo_Manufacturers_CT
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
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
end catch
	

return
GO
