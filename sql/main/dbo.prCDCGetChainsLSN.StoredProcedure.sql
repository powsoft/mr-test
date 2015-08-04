USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetChainsLSN]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetChainsLSN]
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



SET @from_lsn = sys.fn_cdc_get_min_lsn(N'dbo_Chains');
SET @to_lsn = sys.fn_cdc_get_max_lsn();


--print @from_lsn

--print @to_lsn

--Archive all CDC records

--/*

INSERT INTO [DataTrue_Archive].[dbo].[dbo_Chains_CT]
           ([__$start_lsn]
           ,[__$end_lsn]
           ,[__$seqval]
           ,[__$operation]
           ,[__$update_mask]
           ,[ChainID]
           ,[ChainName]
           ,[ChainIdentifier]
           ,[ActiveStartDate]
           ,[ActiveEndDate]
           ,[Comments]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[UseStoresCustom1ForStoreLookup]
           ,[LeadTimetoCostChanges]
           ,[LeadTimetoPromoChanges]
           ,AllowProductAddFromPOS
      ,PDITradingPartner)
SELECT [__$start_lsn]
      ,[__$end_lsn]
      ,[__$seqval]
      ,[__$operation]
      ,[__$update_mask]
      ,[ChainID]
      ,[ChainName]
      ,[ChainIdentifier]
      ,[ActiveStartDate]
      ,[ActiveEndDate]
      ,[Comments]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[UseStoresCustom1ForStoreLookup]
      ,[LeadTimetoCostChanges]
      ,[LeadTimetoPromoChanges]
      ,AllowProductAddFromPOS
      ,PDITradingPartner
  FROM [DataTrue_Main].[cdc].[dbo_Chains_CT]
  where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
--*/

MERGE INTO [DataTrue_Report].[dbo].Chains t

USING (SELECT __$operation,[ChainID]
      ,[ChainName]
      ,[ChainIdentifier]
      ,[ActiveStartDate]
      ,[ActiveEndDate]
      ,[Comments]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[UseStoresCustom1ForStoreLookup]
      ,[LeadTimetoCostChanges]
      ,[LeadTimetoPromoChanges]
      ,AllowProductAddFromPOS
      ,PDITradingPartner
      	FROM cdc.fn_cdc_get_net_changes_dbo_Chains(@from_lsn, @to_lsn, 'all')
		where 1 = 1
		) s
		on t.[ChainID] = s.[ChainID]
		
WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
	
WHEN MATCHED THEN

   UPDATE 
   SET [ChainID] = s.ChainID
      ,[ChainName] = s.ChainName
      ,[ChainIdentifier] = s.ChainIdentifier
      ,[ActiveStartDate] = s.ActiveStartDate
      ,[ActiveEndDate] = s.ActiveEndDate
      ,[Comments] = s.Comments
      ,[DateTimeCreated] = s.DateTimeCreated
      ,[LastUpdateUserID] = s.LastUpdateUserID
      ,[DateTimeLastUpdate] = s.DateTimeLastUpdate
      ,[UseStoresCustom1ForStoreLookup] = s.UseStoresCustom1ForStoreLookup
	  ,[LeadTimetoCostChanges]=s.LeadTimetoCostChanges
	  ,[LeadTimetoPromoChanges]=s.LeadTimetoPromoChanges
	  ,AllowProductAddFromPOS=s.AllowProductAddFromPOS
	  ,PDITradingPartner=s.PDITradingPartner

WHEN NOT MATCHED 

THEN INSERT 
           ([ChainID]
           ,[ChainName]
           ,[ChainIdentifier]
           ,[ActiveStartDate]
           ,[ActiveEndDate]
           ,[Comments]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[UseStoresCustom1ForStoreLookup]
           ,[LeadTimetoCostChanges]
           ,[LeadTimetoPromoChanges]
           ,AllowProductAddFromPOS
           ,PDITradingPartner
           )
     VALUES
           (s.ChainID
           ,s.ChainName
           ,s.ChainIdentifier
           ,s.ActiveStartDate
           ,s.ActiveEndDate
           ,s.Comments
           ,s.DateTimeCreated
           ,s.LastUpdateUserID
           ,s.DateTimeLastUpdate
           ,s.UseStoresCustom1ForStoreLookup
           ,s.[LeadTimetoCostChanges]
           ,s.[LeadTimetoPromoChanges]
           ,s.AllowProductAddFromPOS
           ,s.PDITradingPartner
           );

	delete cdc.dbo_Chains_CT
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
