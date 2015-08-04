USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetCreateStoresLSN_New]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetCreateStoresLSN_New]
as
--exec [prCDCGetCreateStoresLSN]
declare @MyID int
declare @startlsn binary(10)
declare @endlsn binary(10)
declare @count int
declare @from_lsn binary(10)
declare @to_lsn binary(10)

set @MyID = 0

begin try

--begin transaction


exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMinLSN_TableName 'dbo_CreateStores',@from_lsn output

exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMaxLSN @to_lsn output--sys.fn_cdc_get_max_lsn();


--print @from_lsn

--print @to_lsn

--Archive all CDC records

/*
--select * into CreateStores_CT_Archiv11e from [IC-HQSQL1\DataTrue].[IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_CreateStores_CT
--select * from [IC-HQSQL1INST2].[DataTrue_Archive].[dbo].[dbo_CreateStores_CT]
--insert into [IC-HQSQL1INST2].[DataTrue_Archive].[dbo].[dbo_CreateStores_CT] select * from [IC-HQSQL1INST2].[DataTrue_Archive].[dbo].[dbo_CreateStores_CT]
insert into [IC-HQSQL1INST2].[DataTrue_Archive].[dbo].[dbo_CreateStores_CT]
([__$start_lsn]
      ,[__$end_lsn]
      ,[__$seqval]
      ,[__$operation]
      ,[__$update_mask]
      ,[ID]
,[StoreNumber]
,[SBTNumber]
,[Address]
,[City]
,[ZipCode]
,[State]
,[Banner]
,[OpeningDate]
,[StoreMgr]
,[District]
,[Area]
,[UserID]
,[DateEntered]
,[ChainId]
,[Recordstatus]
)
SELECT [__$start_lsn]
      ,[__$end_lsn]
      ,[__$seqval]
      ,[__$operation]
      ,[__$update_mask]
      ,[ID]
,[StoreNumber]
,[SBTNumber]
,[Address]
,[City]
,[ZipCode]
,[State]
,[Banner]
,[OpeningDate]
,[StoreMgr]
,[District]
,[Area]
,[UserID]
,[DateEntered]
,[ChainId]
,[Recordstatus]
  FROM [IC-HQSQL1\DataTrue].DataTrue_Main.[cdc].[dbo_CreateStores_CT]
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn


MERGE INTO [DataTrue_Report].[dbo].CreateStores t

USING (SELECT __$operation
	 ,[ID]
,[StoreNumber]
,[SBTNumber]
,[Address]
,[City]
,[ZipCode]
,[State]
,[Banner]
,[OpeningDate]
,[StoreMgr]
,[District]
,[Area]
,[UserID]
,[DateEntered]
,[ChainId]
,[Recordstatus]
	FROM FROM [IC-HQSQL1\DataTrue].DataTrue_Main.[cdc].[dbo_CreateStores_CT]
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
	and __$operation<>3
	order by __$start_lsn
		) s
		on t.[ID] = s.[ID]

WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
WHEN MATCHED THEN

   UPDATE 
   SET 
   --[LoginID]=s.LoginID
--,[ID]=s.ID
[StoreNumber]=s.StoreNumber
,[SBTNumber]=s.SBTNumber
,[Address]=s.Address
,[City]=s.City
,[ZipCode]=s.ZipCode
,[State]=s.State
,[Banner]=s.Banner
,[OpeningDate]=s.OpeningDate
,[StoreMgr]=s.StoreMgr
,[District]=s.District
,[Area]=s.Area
,[UserID]=s.UserID
,[DateEntered]=s.DateEntered
,[ChainId]=s.ChainId
,[Recordstatus]=s.Recordstatus
 
WHEN NOT MATCHED 

THEN INSERT 
           ( [ID]
,[StoreNumber]
,[SBTNumber]
,[Address]
,[City]
,[ZipCode]
,[State]
,[Banner]
,[OpeningDate]
,[StoreMgr]
,[District]
,[Area]
,[UserID]
,[DateEntered]
,[ChainId]
,[Recordstatus]
)
     VALUES
           ( s.[ID]
,s.[StoreNumber]
,s.[SBTNumber]
,s.[Address]
,s.[City]
,s.[ZipCode]
,s.[State]
,s.[Banner]
,s.[OpeningDate]
,s.[StoreMgr]
,s.[District]
,s.[Area]
,s.[UserID]
,s.[DateEntered]
,s.[ChainId]
,s.[Recordstatus]
);


	delete [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_CreateStores_CT
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
