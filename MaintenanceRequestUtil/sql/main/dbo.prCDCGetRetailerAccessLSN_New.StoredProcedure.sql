USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetRetailerAccessLSN_New]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetRetailerAccessLSN_New]
as
--exec [prCDCGetRetailerAccessLSN]
declare @MyID int
declare @startlsn binary(10)
declare @endlsn binary(10)
declare @count int
declare @from_lsn binary(10)
declare @to_lsn binary(10)

set @MyID = 0

begin try

--begin transaction


exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMinLSN_TableName 'dbo_RetailerAccess',@from_lsn output

exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMaxLSN @to_lsn output--sys.fn_cdc_get_max_lsn();

--print @from_lsn

--print @to_lsn

--Archive all CDC records
/*
insert into [IC-HQSQL1INST2].[DataTrue_Archive].[dbo].[dbo_RetailerAccess_CT]
([__$start_lsn]
      ,[__$end_lsn]
      ,[__$seqval]
      ,[__$operation]
      ,[__$update_mask]
      ,[PersonId]
,[ChainId]
,[EditRights]
,[BannerAccess]
,[ClusterAccess])
SELECT [__$start_lsn]
      ,[__$end_lsn]
      ,[__$seqval]
      ,[__$operation]
      ,[__$update_mask]
      ,[PersonId]
,[ChainId]
,[EditRights]
,[BannerAccess]
,[ClusterAccess]
  FROM [IC-HQSQL1\DataTrue].DataTrue_Main.[cdc].[dbo_RetailerAccess_CT]
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn


MERGE INTO [DataTrue_Report].[dbo].RetailerAccess t

USING (SELECT __$operation
	 ,[PersonId]
,[ChainId]
,[EditRights]
,[BannerAccess]
,[ClusterAccess]
      	FROM [IC-HQSQL1\DataTrue].DataTrue_Main.[cdc].[dbo_RetailerAccess_CT]
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
	and __$operation<>3
    order by __$start_lsn
		) s
		on t.[PersonId] = s.[PersonId] and t.[ChainId]=s.[ChainId]

WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
WHEN MATCHED THEN

   UPDATE 
   SET 
   --[LoginID]=s.LoginID
[PersonId]=s.PersonId
,[ChainId]=s.ChainId
,[EditRights]=s.EditRights
,[BannerAccess]=s.BannerAccess
,[ClusterAccess]=s.ClusterAccess
 
WHEN NOT MATCHED 

THEN INSERT 
           ([PersonId]
,[ChainId]
,[EditRights]
,[BannerAccess]
,[ClusterAccess])
     VALUES
           (s.[PersonId]
,s.[ChainId]
,s.[EditRights]
,s.[BannerAccess]
,s.[ClusterAccess]);


	delete [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_RetailerAccess_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
	
--commit transaction
	*/
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
