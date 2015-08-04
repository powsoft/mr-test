USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetStoresLSN]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetStoresLSN]
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



SET @from_lsn = sys.fn_cdc_get_min_lsn(N'dbo_Stores');
SET @to_lsn = sys.fn_cdc_get_max_lsn();


--print @from_lsn

--print @to_lsn

--Archive all CDC records

--/*

INSERT INTO [DataTrue_Archive].[dbo].[dbo_Stores_CT]
           ([__$start_lsn]
           ,[__$end_lsn]
           ,[__$seqval]
           ,[__$operation]
           ,[__$update_mask]
           ,[StoreID]
           ,[ChainID]
           ,[StoreName]
           ,[StoreIdentifier]
           ,[ActiveFromDate]
           ,[ActiveLastDate]
           ,[Comments]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[EconomicLevel]
           ,[StoreSize]
           ,[Custom1]
           ,[Custom2]
           ,[Custom3]
           ,[DunsNumber]
           ,[Custom4]
           ,[GopherStoreName]
           ,[SBTNumber]
           ,[GroupNumber]
           ,[ActiveStatus]
           ,[ClassOfTrade]
		   ,[LegacySystemStoreIdentifier]) 
SELECT [__$start_lsn]
      ,[__$end_lsn]
      ,[__$seqval]
      ,[__$operation]
      ,[__$update_mask]
      ,[StoreID]
      ,[ChainID]
      ,[StoreName]
      ,[StoreIdentifier]
      ,[ActiveFromDate]
      ,[ActiveLastDate]
      ,[Comments]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[EconomicLevel]
      ,[StoreSize]
      ,[Custom1]
      ,[Custom2]
      ,[Custom3]
      ,[DunsNumber]
      ,[Custom4]
      ,[GopherStoreName]
      ,[SBTNumber]
      ,[GroupNumber]
      ,[ActiveStatus]
      ,[ClassOfTrade]
      ,[LegacySystemStoreIdentifier]
  FROM [DataTrue_Main].[cdc].[dbo_Stores_CT]
  where __$start_lsn >= @from_lsn and __$start_lsn <= @to_lsn
--*/

MERGE INTO [DataTrue_Report].[dbo].Stores t

USING (SELECT __$operation,[StoreID]
      ,[ChainID]
      ,[StoreName]
      ,[StoreIdentifier]
      ,[ActiveFromDate]
      ,[ActiveLastDate]
      ,[Comments]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[EconomicLevel]
      ,[StoreSize]
      ,[Custom1]
      ,[Custom2]
      ,[Custom3]
      ,[DunsNumber]
      ,[Custom4]
      ,[GopherStoreName]
      ,[SBTNumber]
      ,[GroupNumber]
      ,[ActiveStatus]
      ,[ClassOfTrade]
      ,[LegacySystemStoreIdentifier]
      	FROM cdc.fn_cdc_get_net_changes_dbo_Stores(@from_lsn, @to_lsn, 'all')
		where 1 = 1
		) s
		on t.StoreId = s.StoreId

WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
	
WHEN MATCHED THEN

update 	
   SET [ChainID] = s.ChainID
      ,[StoreName] = s.StoreName
      ,[StoreIdentifier] = s.StoreIdentifier
      ,[ActiveFromDate] = s.ActiveFromDate
      ,[ActiveLastDate] = s.ActiveLastDate
      ,[Comments] = s.Comments
      ,[DateTimeCreated] = s.DateTimeCreated
      ,[LastUpdateUserID] = s.LastUpdateUserID
      ,[DateTimeLastUpdate] = s.DateTimeLastUpdate
      ,[EconomicLevel] = s.EconomicLevel
      ,[StoreSize] = s.StoreSize
      ,[Custom1] = s.Custom1
      ,[Custom2] = s.Custom2
      ,[Custom3] = s.Custom3
      ,[DunsNumber] = s.DunsNumber
      ,[Custom4] = s.Custom4
      ,[GopherStoreName] = s.GopherStoreName
      ,[SBTNumber] = s.SBTNumber
      ,[GroupNumber] = s.GroupNumber
	  ,[ActiveStatus] = s.ActiveStatus
	  ,[ClassOfTrade]=s.[ClassOfTrade]
      ,[LegacySystemStoreIdentifier]=s.[LegacySystemStoreIdentifier]

WHEN NOT MATCHED 

THEN INSERT 
           ([StoreID]
           ,[ChainID]
           ,[StoreName]
           ,[StoreIdentifier]
           ,[ActiveFromDate]
           ,[ActiveLastDate]
           ,[Comments]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[EconomicLevel]
           ,[StoreSize]
           ,[Custom1]
           ,[Custom2]
           ,[Custom3]
           ,[DunsNumber]
           ,[Custom4]
           ,[GopherStoreName]
           ,[SBTNumber]
           ,[GroupNumber]
           ,[ActiveStatus]
           ,[ClassOfTrade]
           ,[LegacySystemStoreIdentifier])
     VALUES
           (s.StoreID
           ,s.ChainID
           ,s.StoreName
           ,s.StoreIdentifier
           ,s.ActiveFromDate
           ,s.ActiveLastDate
           ,s.Comments
           ,s.DateTimeCreated
           ,s.LastUpdateUserID
           ,s.DateTimeLastUpdate
           ,s.EconomicLevel
           ,s.StoreSize
           ,s.Custom1
           ,s.Custom2
           ,s.Custom3
           ,s.DunsNumber
           ,s.Custom4
           ,s.GopherStoreName
           ,s.SBTNumber
           ,s.GroupNumber
           ,s.ActiveStatus
           ,s.[ClassOfTrade]
           ,s.[LegacySystemStoreIdentifier]);
           
MERGE INTO [DataTrue_EDI].[dbo].Stores t

USING (SELECT [StoreID]
      ,[ChainID]
      ,[StoreName]
      ,[StoreIdentifier]
      ,[ActiveFromDate]
      ,[ActiveLastDate]
      ,[Comments]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[EconomicLevel]
      ,[StoreSize]
      ,[Custom1]
      ,[Custom2]
      ,[Custom3]
      ,[DunsNumber]
      ,[Custom4]
      ,[GopherStoreName]
      ,[SBTNumber]
      ,[GroupNumber]
      ,[ActiveStatus]
      ,[ClassOfTrade]
      ,[LegacySystemStoreIdentifier]
      	FROM cdc.fn_cdc_get_net_changes_dbo_Stores(@from_lsn, @to_lsn, 'all')
		where 1 = 1
		) s
		on t.StoreId = s.StoreId

WHEN MATCHED THEN

update 	
   SET [ChainID] = s.ChainID
      ,[StoreName] = s.StoreName
      ,[StoreIdentifier] = s.StoreIdentifier
      ,[ActiveFromDate] = s.ActiveFromDate
      ,[ActiveLastDate] = s.ActiveLastDate
      ,[Comments] = s.Comments
      ,[DateTimeCreated] = s.DateTimeCreated
      ,[LastUpdateUserID] = s.LastUpdateUserID
      ,[DateTimeLastUpdate] = s.DateTimeLastUpdate
      ,[EconomicLevel] = s.EconomicLevel
      ,[StoreSize] = s.StoreSize
      ,[Custom1] = s.Custom1
      ,[Custom2] = s.Custom2
      ,[Custom3] = s.Custom3
      ,[DunsNumber] = s.DunsNumber
      ,[Custom4] = s.Custom4
      ,[GopherStoreName] = s.GopherStoreName
      ,[SBTNumber] = s.SBTNumber
      ,[GroupNumber] = s.GroupNumber
	  --,[ActiveStatus] = s.ActiveStatus
	  --,[ClassOfTrade]=s.[ClassOfTrade]
      ,[LegacySystemStoreIdentifier]=s.[LegacySystemStoreIdentifier]

WHEN NOT MATCHED 

THEN INSERT 
           ([StoreID]
           ,[ChainID]
           ,[StoreName]
           ,[StoreIdentifier]
           ,[ActiveFromDate]
           ,[ActiveLastDate]
           ,[Comments]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[EconomicLevel]
           ,[StoreSize]
           ,[Custom1]
           ,[Custom2]
           ,[Custom3]
           ,[DunsNumber]
           ,[Custom4]
           ,[GopherStoreName]
           ,[SBTNumber]
           ,[GroupNumber]
           --,[ActiveStatus]
           --,[ClassOfTrade]
           ,[LegacySystemStoreIdentifier])
     VALUES
           (s.StoreID
           ,s.ChainID
           ,s.StoreName
           ,s.StoreIdentifier
           ,s.ActiveFromDate
           ,s.ActiveLastDate
           ,s.Comments
           ,s.DateTimeCreated
           ,s.LastUpdateUserID
           ,s.DateTimeLastUpdate
           ,s.EconomicLevel
           ,s.StoreSize
           ,s.Custom1
           ,s.Custom2
           ,s.Custom3
           ,s.DunsNumber
           ,s.Custom4
           ,s.GopherStoreName
           ,s.SBTNumber
           ,s.GroupNumber
           --,s.ActiveStatus
           --,s.[ClassOfTrade]
           ,s.[LegacySystemStoreIdentifier]);           

	delete cdc.dbo_Stores_CT
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
