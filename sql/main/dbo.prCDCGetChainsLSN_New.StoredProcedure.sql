USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetChainsLSN_New]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetChainsLSN_New]
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

exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMinLSN_TableName 'dbo_Chains',@from_lsn output

exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMaxLSN @to_lsn output--sys.fn_cdc_get_max_lsn();


--print @from_lsn

--print @to_lsn

--Archive all CDC records

/*

INSERT INTO [IC-HQSQL1INST2].[DataTrue_Archive].[dbo].[dbo_Chains_CT]
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
           ,PDITradingPartner
           ,UseReportedCostForBilling
      )
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
      ,UseReportedCostForBilling
  FROM [IC-HQSQL1\DataTrue].DataTrue_Main.[cdc].[dbo_Chains_CT]
  where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn


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
      , UseReportedCostForBilling
      	FROM [IC-HQSQL1\DataTrue].DataTrue_Main.[cdc].[dbo_Chains_CT]
  where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
	and __$operation<>3
	order by __$start_lsn
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
	  ,UseReportedCostForBilling = s.UseReportedCostForBilling

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
           ,UseReportedCostForBilling
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
           ,s.UseReportedCostForBilling
           );

--EDI

MERGE INTO [IC-HQSQL1\DataTrue].[DataTrue_EDI].[dbo].Chains t

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
      , UseReportedCostForBilling
    FROM [IC-HQSQL1\DataTrue].DataTrue_Main.[cdc].[dbo_Chains_CT]
		where __$start_lsn >= @from_lsn
		and __$start_lsn <= @to_lsn
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
	  ,UseReportedCostForBilling = s.UseReportedCostForBilling

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
           ,UseReportedCostForBilling
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
           ,s.UseReportedCostForBilling
           );




	delete [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_Chains_CT
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
