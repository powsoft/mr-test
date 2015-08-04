USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetSuppliersLSN_New]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetSuppliersLSN_New]
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


exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMinLSN_TableName 'dbo_Suppliers',@from_lsn output

exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMaxLSN @to_lsn output--sys.fn_cdc_get_max_lsn();

--print @from_lsn

--print @to_lsn

--Archive all CDC records

/*

insert into [IC-HQSQL1INST2].DataTrue_Archive.dbo.dbo_Suppliers_CT 
select * from [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_Suppliers_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn


MERGE INTO [DataTrue_Report].[dbo].Suppliers t

USING (SELECT __$operation, [SupplierID]
      ,[SupplierName]
      ,[SupplierIdentifier]
      ,[SupplierDescription]
      ,[ActiveStartDate]
      ,[ActiveLastDate]
      ,[RegistrationDate]
      ,[Comments]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[DunsNumber]
      ,[EDIName]
      ,[SupplierDeliveryIdentifier]
      ,[CreateZeroCountRecordsForMissingProductCounts]
      ,[StoreProductContextMethod]
      ,InventoryIsActive
      ,UniqueEDIName
      ,PromotionOverwriteAllowed
      ,PDITradingPartner
      ,IsRegulated
      	FROM [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_Suppliers_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
	and __$operation<>3
    order by __$start_lsn
		) s
		on t.SupplierId = s.SupplierId

WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
	
WHEN MATCHED THEN

update 	
   SET [SupplierName] = s.SupplierName
      ,[SupplierIdentifier] = s.SupplierIdentifier
      ,[SupplierDescription] = s.SupplierDescription
      ,[ActiveStartDate] = s.ActiveStartDate
      ,[ActiveLastDate] = s.ActiveLastDate
      ,[RegistrationDate] = s.RegistrationDate
      ,[Comments] = s.Comments
      ,[DateTimeCreated] = s.DateTimeCreated
      ,[LastUpdateUserID] = s.LastUpdateUserID
      ,[DateTimeLastUpdate] = s.DateTimeLastUpdate
      ,[DunsNumber] = s.DunsNumber
      ,[EDIName] = s.EDIName
      ,PDITradingPartner=s.PDITradingPartner
      ,InventoryIsActive=s.InventoryIsActive
      ,UniqueEDIName=s.UniqueEDIName
      ,PromotionOverwriteAllowed=s.PromotionOverwriteAllowed
     
      ,IsRegulated=s.IsRegulated

WHEN NOT MATCHED 

THEN INSERT 
           ([SupplierID]
           ,[SupplierName]
           ,[SupplierIdentifier]
           ,[SupplierDescription]
           ,[ActiveStartDate]
           ,[ActiveLastDate]
           ,[RegistrationDate]
           ,[Comments]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[DunsNumber]
           ,[EDIName]
           ,InventoryIsActive
      ,UniqueEDIName
      ,PromotionOverwriteAllowed
      ,PDITradingPartner
      ,IsRegulated)
     VALUES
           (s.SupplierID
           ,s.SupplierName
           ,s.SupplierIdentifier
           ,s.SupplierDescription
           ,s.ActiveStartDate
           ,s.ActiveLastDate
           ,s.RegistrationDate
           ,s.Comments
           ,s.DateTimeCreated
           ,s.LastUpdateUserID
           ,s.DateTimeLastUpdate
           ,s.DunsNumber
           ,s.EDIName
           ,s.InventoryIsActive
      ,s.UniqueEDIName
      ,s.PromotionOverwriteAllowed
      ,s.PDITradingPartner
      ,s.IsRegulated
           );


MERGE INTO [IC-HQSQL1\DataTrue].[DataTrue_EDI].[dbo].Suppliers t

USING (SELECT [SupplierID]
      ,[SupplierName]
      ,[SupplierIdentifier]
      ,[SupplierDescription]
      ,[ActiveStartDate]
      ,[ActiveLastDate]
      ,[RegistrationDate]
      ,[Comments]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[DunsNumber]
      ,[EDIName]
      ,[SupplierDeliveryIdentifier]
      ,[CreateZeroCountRecordsForMissingProductCounts]
      ,[StoreProductContextMethod]
      ,InventoryIsActive
      ,UniqueEDIName
      ,PromotionOverwriteAllowed
      ,PDITradingPartner
      ,IsRegulated
      	FROM [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_Suppliers_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
		) s
		on t.SupplierId = s.SupplierId

WHEN MATCHED THEN

update 	
   SET [SupplierName] = s.SupplierName
      ,[SupplierIdentifier] = s.SupplierIdentifier
      ,[SupplierDescription] = s.SupplierDescription
      ,[ActiveStartDate] = s.ActiveStartDate
      ,[ActiveLastDate] = s.ActiveLastDate
      ,[RegistrationDate] = s.RegistrationDate
      ,[Comments] = s.Comments
      ,[DateTimeCreated] = s.DateTimeCreated
      ,[LastUpdateUserID] = s.LastUpdateUserID
      ,[DateTimeLastUpdate] = s.DateTimeLastUpdate
      ,[DunsNumber] = s.DunsNumber
      ,[EDIName] = s.EDIName
      ,InventoryIsActive=s.InventoryIsActive
      ,UniqueEDIName=s.UniqueEDIName
      ,PromotionOverwriteAllowed=s.PromotionOverwriteAllowed
      ,PDITradingPartner=s.PDITradingPartner
      ,IsRegulated=s.IsRegulated

WHEN NOT MATCHED 

THEN INSERT 
           ([SupplierID]
           ,[SupplierName]
           ,[SupplierIdentifier]
           ,[SupplierDescription]
           ,[ActiveStartDate]
           ,[ActiveLastDate]
           ,[RegistrationDate]
           ,[Comments]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[DunsNumber]
           ,[EDIName]
           ,InventoryIsActive
      ,UniqueEDIName
      ,PromotionOverwriteAllowed
      ,PDITradingPartner
      ,IsRegulated)
     VALUES
           (s.SupplierID
           ,s.SupplierName
           ,s.SupplierIdentifier
           ,s.SupplierDescription
           ,s.ActiveStartDate
           ,s.ActiveLastDate
           ,s.RegistrationDate
           ,s.Comments
           ,s.DateTimeCreated
           ,s.LastUpdateUserID
           ,s.DateTimeLastUpdate
           ,s.DunsNumber
           ,s.EDIName
           ,s.InventoryIsActive
      ,s.UniqueEDIName
      ,s.PromotionOverwriteAllowed
      ,s.PDITradingPartner
      ,s.IsRegulated
           );
           
           
	delete [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_Suppliers_CT
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
