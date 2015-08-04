USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetACHFilterTypesLSN]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetACHFilterTypesLSN]
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



SET @from_lsn = sys.fn_cdc_get_min_lsn(N'dbo_ACHFilterTypes');
SET @to_lsn = sys.fn_cdc_get_max_lsn();

insert into DataTrue_Archive..dbo_ACHFilterTypes_CT 
select * from cdc.dbo_ACHFilterTypes_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
--*/

MERGE INTO [DataTrue_Report].[dbo].ACHFilterTypes t

USING (SELECT __$operation
		,[ACHFilterTypeId]
		,[ACHFilterTypeName]
		,[DefaultValue]
      	FROM cdc.fn_cdc_get_net_changes_dbo_ACHFilterTypes(@from_lsn, @to_lsn, 'all')
		where 1 = 1
		) s
		on t.[ACHFilterTypeId] = s.[ACHFilterTypeId]

WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
WHEN MATCHED THEN

   UPDATE 
   SET 	[ACHFilterTypeId]=s.[ACHFilterTypeId]
		,[ACHFilterTypeName]=s.[ACHFilterTypeName]
		,[DefaultValue]=s.[DefaultValue]
   
   WHEN NOT MATCHED 

THEN INSERT 
           (
         [ACHFilterTypeId]
		,[ACHFilterTypeName]
		,[DefaultValue]
		)
     VALUES
           (
           s.[ACHFilterTypeId]
		  ,s.[ACHFilterTypeName]
		  ,s.[DefaultValue]
           );

	delete cdc.dbo_ACHFilterTypes_CT
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
