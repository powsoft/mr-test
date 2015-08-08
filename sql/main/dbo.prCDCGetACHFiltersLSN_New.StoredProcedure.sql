USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetACHFiltersLSN_New]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetACHFiltersLSN_New]
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

exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMinLSN_TableName 'dbo_ACHFilters',@from_lsn output

exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMaxLSN @to_lsn output--sys.fn_cdc_get_max_lsn();
/*
--insert into [IC-HQSQL1INST2].DataTrue_Archive..dbo_ACHFilters_CT 
insert into [IC-HQSQL1INST2].[DataTrue_Archive].[dbo].dbo_ACHFilters_CT 
select * from [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_ACHFilters_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn


MERGE INTO [DataTrue_Report].[dbo].ACHFilters t

USING (SELECT __$operation
	    ,	[ACHFilterID]
		,	[ChainId]
		,	[SupplierID]
		,	[State]
		,	[ACHFilterTypeId]
		,	[ACHFilterValue]

      	FROM [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_ACHFilters_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
	and __$operation<>3
		) s
		on t.[ACHFilterID] = s.[ACHFilterID]

WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
WHEN MATCHED THEN

   UPDATE 
   SET 		[ACHFilterID]=	s.[ACHFilterID]
		,	[ChainId]=	s.[ChainId]
		,	[SupplierID]=	s.[SupplierID]
		,	[State]=	s.[State]
		,	[ACHFilterTypeId]=	s.[ACHFilterTypeId]
		,	[ACHFilterValue]=	s.[ACHFilterValue]

WHEN NOT MATCHED 

THEN INSERT 
           (	[ACHFilterID]
			,	[ChainId]
			,	[SupplierID]
			,	[State]
			,	[ACHFilterTypeId]
			,	[ACHFilterValue]
)
     VALUES
           (
				s.[ACHFilterID]
			,	s.[ChainId]
			,	s.[SupplierID]
			,	s.[State]
			,	s.[ACHFilterTypeId]
			,	s.[ACHFilterValue]
			);
*/
	delete [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_ACHFilters_CT
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
