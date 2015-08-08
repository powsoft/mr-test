USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetSupplierAccessLSN_New]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetSupplierAccessLSN_New]
as
--exec [prCDCGetSupplierAccessLSN]
declare @MyID int
declare @startlsn binary(10)
declare @endlsn binary(10)
declare @count int
declare @from_lsn binary(10)
declare @to_lsn binary(10)

set @MyID = 0

begin try

--begin transaction

exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMinLSN_TableName 'dbo_SupplierAccess',@from_lsn output

exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMaxLSN @to_lsn output--sys.fn_cdc_get_max_lsn();


--print @from_lsn

--print @to_lsn

--Archive all CDC records
--drop table dbo_SupplierAccess_CT_Archive
/*
--select * into [IC-HQSQL1INST2].[DataTrue_Archive].[dbo].[dbo_SupplierAccess_CT] from [IC-HQSQL1\DataTrue].[IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_SupplierAccess_CT
--insert into [IC-HQSQL1INST2].[DataTrue_Archive].[dbo].[dbo_SupplierAccess_CT] select * from SupplierAccess_CT_Archive
insert into [IC-HQSQL1INST2].[DataTrue_Archive].[dbo].[dbo_SupplierAccess_CT]
([__$start_lsn]
      ,[__$end_lsn]
      ,[__$seqval]
      ,[__$operation]
      ,[__$update_mask]
      ,[PersonId]
,[SupplierId]
,[EditRights]
,[BannerAccess]
)
SELECT [__$start_lsn]
      ,[__$end_lsn]
      ,[__$seqval]
      ,[__$operation]
      ,[__$update_mask]
      ,[PersonId]
	,[SupplierId]
	,[EditRights]
	,[BannerAccess]
  FROM [IC-HQSQL1\DataTrue].DataTrue_Main.[cdc].[dbo_SupplierAccess_CT]
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn


MERGE INTO [DataTrue_Report].[dbo].SupplierAccess t

USING (SELECT __$operation
	,[PersonId]
	,[SupplierId]
	,[EditRights]
	,[BannerAccess]
	FROM [IC-HQSQL1\DataTrue].DataTrue_Main.[cdc].[dbo_SupplierAccess_CT]
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
		and __$operation<>3
    order by __$start_lsn
		) s
		on t.[PersonId] = s.[PersonId] and t.[SupplierId]=s.[SupplierId]

WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
WHEN MATCHED THEN

   UPDATE 
   SET 
   --[LoginID]=s.LoginID
[PersonId]=s.PersonId
,[SupplierId]=s.SupplierId
,[EditRights]=s.EditRights
,[BannerAccess]=s.BannerAccess

 
WHEN NOT MATCHED 

THEN INSERT 
           ([PersonId]
,[SupplierId]
,[EditRights]
,[BannerAccess]
)
     VALUES
           (s.[PersonId]
,s.[SupplierId]
,s.[EditRights]
,s.[BannerAccess]
);


	delete [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_SupplierAccess_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
	*/
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
