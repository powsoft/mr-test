USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetStoreSetupLSN_New]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetStoreSetupLSN_New]
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


exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMinLSN_TableName 'dbo_StoreSetup',@from_lsn output

exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMaxLSN @to_lsn output--sys.fn_cdc_get_max_lsn();


--print @from_lsn

--print @to_lsn

--Archive all CDC records

/*

insert into [IC-HQSQL1INST2].DataTrue_Archive.dbo.dbo_StoreSetup_CT 
select * from [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_StoreSetup_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn


MERGE INTO [DataTrue_Report].[dbo].StoreSetup t

USING (SELECT __$operation
      ,[StoreSetupID]
      ,[ChainID]
      ,[StoreID]
      ,[ProductID]
      ,[SupplierID]
      ,[BrandID]
      ,[InventoryRuleID]
      ,[InventoryCostMethod]
      ,[SunLimitQty]
      ,[SunFrequency]
      ,[MonLimitQty]
      ,[MonFrequency]
      ,[TueLimitQty]
      ,[TueFrequency]
      ,[WedLimitQty]
      ,[WedFrequency]
      ,[ThuLimitQty]
      ,[ThuFrequency]
      ,[FriLimitQty]
      ,[FriFrequency]
      ,[SatLimitQty]
      ,[SatFrequency]
      ,[RetailerShrinkPercent]
      ,[SupplierShrinkPercent]
      ,[ManufacturerShrinkPercent]
      ,[ActiveStartDate]
      ,[ActiveLastDate]
      ,[SetupReportedToRetailerDate]
      ,[FileName]
      ,[Comments]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      	--FROM cdc.fn_cdc_get_net_changes_dbo_StoreSetup(@from_lsn, @to_lsn, 'all')
       FROM [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_StoreSetup_CT
	   where __$start_lsn >= @from_lsn
	   and __$start_lsn <= @to_lsn
	   and __$operation<>3
    order by __$start_lsn
		) s
		on t.StoreSetupId = s.StoreSetupId
WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
	
WHEN MATCHED THEN

update 	
   SET [ChainID] = s.ChainID
      ,[StoreID] = s.StoreID
      ,[ProductID] = s.ProductID
      ,[SupplierID] = s.SupplierID
      ,[BrandID] = s.BrandID
      ,[InventoryRuleID] = s.InventoryRuleID
      ,[InventoryCostMethod] = s.InventoryCostMethod
      ,[SunLimitQty] = s.SunLimitQty
      ,[SunFrequency] = s.SunFrequency
      ,[MonLimitQty] = s.MonLimitQty
      ,[MonFrequency] = s.MonFrequency
      ,[TueLimitQty] = s.TueLimitQty
      ,[TueFrequency] = s.TueFrequency
      ,[WedLimitQty] = s.WedLimitQty
      ,[WedFrequency] = s.WedFrequency
      ,[ThuLimitQty] = s.ThuLimitQty
      ,[ThuFrequency] = s.ThuFrequency
      ,[FriLimitQty] = s.FriLimitQty
      ,[FriFrequency] = s.FriFrequency
      ,[SatLimitQty] = s.SatLimitQty
      ,[SatFrequency] = s.SatFrequency
      ,[RetailerShrinkPercent] = s.RetailerShrinkPercent
      ,[SupplierShrinkPercent] = s.SupplierShrinkPercent
      ,[ManufacturerShrinkPercent] = s.ManufacturerShrinkPercent
      ,[ActiveStartDate] = s.ActiveStartDate
      ,[ActiveLastDate] = s.ActiveLastDate
      ,[SetupReportedToRetailerDate] = s.SetupReportedToRetailerDate
      ,[FileName] = s.FileName
      ,[Comments] = s.Comments
      ,[DateTimeCreated] = s.DateTimeCreated
      ,[LastUpdateUserID] = s.LastUpdateUserID
      ,[DateTimeLastUpdate] = s.DateTimeLastUpdate

WHEN NOT MATCHED 

THEN INSERT 
           (StoreSetupId
           ,[ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[SupplierID]
           ,[BrandID]
           ,[InventoryRuleID]
           ,[InventoryCostMethod]
           ,[SunLimitQty]
           ,[SunFrequency]
           ,[MonLimitQty]
           ,[MonFrequency]
           ,[TueLimitQty]
           ,[TueFrequency]
           ,[WedLimitQty]
           ,[WedFrequency]
           ,[ThuLimitQty]
           ,[ThuFrequency]
           ,[FriLimitQty]
           ,[FriFrequency]
           ,[SatLimitQty]
           ,[SatFrequency]
           ,[RetailerShrinkPercent]
           ,[SupplierShrinkPercent]
           ,[ManufacturerShrinkPercent]
           ,[ActiveStartDate]
           ,[ActiveLastDate]
           ,[SetupReportedToRetailerDate]
           ,[FileName]
           ,[Comments]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate])
     VALUES
           (s.StoreSetupId
           ,s.ChainID
           ,s.StoreID
           ,s.ProductID
           ,s.SupplierID
           ,s.BrandID
           ,s.InventoryRuleID
           ,s.InventoryCostMethod
           ,s.SunLimitQty
           ,s.SunFrequency
           ,s.MonLimitQty
           ,s.MonFrequency
           ,s.TueLimitQty
           ,s.TueFrequency
           ,s.WedLimitQty
           ,s.WedFrequency
           ,s.ThuLimitQty
           ,s.ThuFrequency
           ,s.FriLimitQty
           ,s.FriFrequency
           ,s.SatLimitQty
           ,s.SatFrequency
           ,s.RetailerShrinkPercent
           ,s.SupplierShrinkPercent
           ,s.ManufacturerShrinkPercent
           ,s.ActiveStartDate
           ,s.ActiveLastDate
           ,s.SetupReportedToRetailerDate
           ,s.FileName
           ,s.Comments
           ,s.DateTimeCreated
           ,s.LastUpdateUserID
           ,s.DateTimeLastUpdate);

	delete [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_StoreSetup_CT
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
