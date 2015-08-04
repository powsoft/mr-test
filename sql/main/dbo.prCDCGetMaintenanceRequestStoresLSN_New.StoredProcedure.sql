USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetMaintenanceRequestStoresLSN_New]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetMaintenanceRequestStoresLSN_New]
as

declare @MyID int
declare @startlsn binary(10)
declare @endlsn binary(10)
declare @count int
declare @from_lsn binary(10)
declare @to_lsn binary(10)

SET @MyID = 0

begin try

--begin transaction

SET @from_lsn = sys.fn_cdc_get_min_lsn(N'dbo_MaintenanceRequestStores_New');
SET @to_lsn = sys.fn_cdc_get_max_lsn();


--print @from_lsn

--print @to_lsn

--Archive all CDC records

/*

INSERT INTO [IC-HQSQL1INST2].DataTrue_Archive.dbo.dbo_MaintenanceRequestStores_CT (
		[__$start_lsn]
		,[__$end_lsn]
		,[__$seqval]
		,[__$operation]
		,[__$update_mask]
		,[MaintenanceRequestID] ,
	[StoreID] ,
	[Included],
	[DateTimeCreated])
	SELECT
		[__$start_lsn],
		[__$end_lsn],
		[__$seqval],
		[__$operation],
		[__$update_mask],
		[MaintenanceRequestID] ,
	[StoreID] ,
	[Included],
	[DateTimeCreated]
	FROM [IC-HQSQL1\DataTrue].DataTrue_Main.[cdc].[dbo_MaintenanceRequestStores_CT]
	WHERE __$start_lsn >= @from_lsn
	AND __$start_lsn <= @to_lsn


MERGE INTO [DataTrue_Report].[dbo].MaintenanceRequestStores t

USING ( SELECT
	__$operation,
	[MaintenanceRequestID] ,
	[StoreID] ,
	[Included],
	[DateTimeCreated]
FROM [IC-HQSQL1\DataTrue].DataTrue_Main.[cdc].[dbo_MaintenanceRequestStores_CT]
	WHERE __$start_lsn >= @from_lsn
	AND __$start_lsn <= @to_lsn
	and __$operation<>3
	order by __$start_lsn
WHERE 1 = 1		) s
		on t.MaintenanceRequestID = s.MaintenanceRequestID

WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
WHEN MATCHED THEN

   UPDATE 
   SET
   [MaintenanceRequestID]=s.MaintenanceRequestID ,
	[StoreID]=s.StoreID ,
	[Included]=s.Included,
	[DateTimeCreated]=s.DateTimeCreated
 
 
WHEN NOT MATCHED 

THEN INSERT 
           ([MaintenanceRequestID] ,
	[StoreID] ,
	[Included],
	[DateTimeCreated])
     VALUES
           (s.[MaintenanceRequestID]
           ,s.[StoreID]
           ,s.[Included]
           ,s.[DateTimeCreated]
          );


DELETE [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_MaintenanceRequestStores_CT
WHERE __$start_lsn >= @from_lsn
	AND __$start_lsn <= @to_lsn
	*/
--commit transaction
	
end try
	
begin catch
		--rollback transaction
		
		declare @errormessage varchar(4500)
		declare @errorlocation varchar(255)
		declare @errorsenderstring nvarchar(255)

SET @errormessage = ERROR_MESSAGE()
SET @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
SET @errorsenderstring = ERROR_PROCEDURE()

EXEC [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prLogExceptionAndNotifySupport	1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
										,
										@errorlocation,
										@errormessage,
										@errorsenderstring,
										@MyID
end catch
	

return
GO
