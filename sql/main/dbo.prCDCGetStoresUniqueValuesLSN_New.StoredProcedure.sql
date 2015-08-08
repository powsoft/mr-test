USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetStoresUniqueValuesLSN_New]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetStoresUniqueValuesLSN_New]
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


exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMinLSN_TableName 'dbo_StoresUniqueValues',@from_lsn output

exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMaxLSN @to_lsn output--sys.fn_cdc_get_max_lsn(


--print @from_lsn

--print @to_lsn

--Archive all CDC records
--select * from DataTrue_Archive..dbo_StoresUniqueValues_CT 
/*

insert into [IC-HQSQL1INST2].DataTrue_Archive.dbo.dbo_StoresUniqueValues_CT 
select * from [IC-HQSQL1\DataTrue].[DataTrue_Main].cdc.dbo_StoresUniqueValues_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn

MERGE INTO [DataTrue_Report].[dbo].StoresUniqueValues t

USING (SELECT [__$start_lsn]
      ,[__$operation]
      ,[__$update_mask]
      ,[StoreID]
      ,[SupplierID]
      ,[RouteNumber]
      ,[DriverName]
      ,[SupplierAccountNumber]
      ,[SBTNumber]
      ,[ShipToField]
      ,[DistributionCenter]
      ,[SalesRep]
      ,[RegionalMgr]
      ,[Comments]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[District]
      ,[Region]
      	--FROM cdc.fn_cdc_get_net_changes_dbo_StoresUniqueValues(@from_lsn, @to_lsn, 'all')
		from [IC-HQSQL1\DataTrue].[DataTrue_Main].cdc.dbo_StoresUniqueValues_CT
		where __$start_lsn >= @from_lsn
		and __$start_lsn <= @to_lsn
		and __$operation<>3
    order by __$start_lsn
		) s
		on t.StoreID = s.StoreID
		and t.SupplierID=s.SupplierID and t.SupplierAccountNumber=s.SupplierAccountNumber
		
WHEN MATCHED THEN

UPDATE 
   SET [SupplierID]=s.[SupplierID]
	  ,[RouteNumber]=s.[RouteNumber]
      ,[DriverName]=s.[DriverName]
      ,[SupplierAccountNumber]=s.[SupplierAccountNumber]
      ,[SBTNumber]=s.[SBTNumber]
      ,[ShipToField]=s.[ShipToField]
      ,[DistributionCenter]=s.[DistributionCenter]
      ,[SalesRep]=s.[SalesRep]
      ,[RegionalMgr]=s.[RegionalMgr]
      ,[Comments] = s.Comments
      ,[DateTimeCreated] = s.DateTimeCreated
      ,[LastUpdateUserID] = s.LastUpdateUserID
      ,[DateTimeLastUpdate] = s.DateTimeLastUpdate
      ,[District]=s.District
      ,[Region]=s.Region
WHEN NOT MATCHED 

THEN INSERT 
           ([StoreID]
			,[SupplierID]
            ,[RouteNumber]
			,[DriverName]
			,[SupplierAccountNumber]
			,[SBTNumber]
			,[ShipToField]
			,[DistributionCenter]
			,[SalesRep]
			,[RegionalMgr]
           ,[Comments]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[District]
           ,[Region])
     VALUES
           (
             s.[StoreID]
			,s.[SupplierID]
            ,s.[RouteNumber]
			,s.[DriverName]
			,s.[SupplierAccountNumber]
			,s.[SBTNumber]
			,s.[ShipToField]
			,s.[DistributionCenter]
			,s.[SalesRep]
			,s.[RegionalMgr]
           ,s.Comments
           ,s.DateTimeCreated
           ,s.LastUpdateUserID
           ,s.DateTimeLastUpdate
           ,s.District
           ,s.Region
       );

	delete [IC-HQSQL1\DataTrue].[DataTrue_Main].cdc.dbo_StoresUniqueValues_CT	
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
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec [IC-HQSQL1\DataTrue].[DataTrue_Main].dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
end catch
	

return
GO
