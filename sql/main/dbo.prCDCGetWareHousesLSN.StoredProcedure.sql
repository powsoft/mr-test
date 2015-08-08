USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetWareHousesLSN]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetWareHousesLSN]  
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
  
SET @from_lsn = sys.fn_cdc_get_min_lsn(N'dbo_WareHouses');  
SET @to_lsn = sys.fn_cdc_get_max_lsn();  
  
insert into DataTrue_Archive..dbo_WareHouses_CT   
select * from cdc.dbo_WareHouses_CT  
 where __$start_lsn >= @from_lsn  
 and __$start_lsn <= @to_lsn  
  
  
MERGE INTO [DataTrue_Report].[dbo].WareHouses t  
  
USING (SELECT __$operation,  
				WarehouseID ,  
				ChainID ,  
				WarehouseName ,  
				WarehouseIdentifier ,  
				LocationTypeID ,  
				ActiveFromDate ,  
				ActiveLastDate ,  
				Comments ,  
				DateTimeCreated ,  
				LastUpdateUserID ,  
				DateTimeLastUpdate ,  
				EconomicLevel ,  
				WarehouseSize ,  
				Custom1 ,  
				Custom2 ,  
				Custom3 ,  
				DunsNumber ,  
				Custom4 ,  
				ActiveStatus   
			  
       FROM cdc.fn_cdc_get_net_changes_dbo_WareHouses(@from_lsn, @to_lsn, 'all')  
  where 1 = 1  
  ) s  
  on t.WarehouseID = s.WarehouseID  
  
WHEN MATCHED AND s.__$operation = 1 THEN  
 Delete  
WHEN MATCHED THEN  
  
   UPDATE   
   SET   
	   WarehouseID =s.WarehouseID,   
	   ChainID =s.ChainID ,  
	   WarehouseName =s.WarehouseName ,  
	   WarehouseIdentifier =s.WarehouseIdentifier ,  
	   LocationTypeID =s.LocationTypeID ,  
	   ActiveFromDate =s.ActiveFromDate ,  
	   ActiveLastDate =s.ActiveLastDate ,  
	   Comments =s.Comments ,  
	   DateTimeCreated =s.DateTimeCreated ,  
	   LastUpdateUserID =s.LastUpdateUserID ,  
	   DateTimeLastUpdate =s.DateTimeLastUpdate,   
	   EconomicLevel =s.EconomicLevel ,  
	   WarehouseSize =s.WarehouseSize ,  
	   Custom1 =s.Custom1 ,  
	   Custom2 =s.Custom2 ,  
	   Custom3 =s.Custom3 ,  
	   DunsNumber =s.DunsNumber ,  
	   Custom4 =s.Custom4 ,  
	   ActiveStatus =s.ActiveStatus   
  
WHEN NOT MATCHED   
  
THEN INSERT   
           (  
           [WarehouseID] ,  
		   [ChainID],  
		   [WarehouseName],  
		   [WarehouseIdentifier],  
		   [LocationTypeID],  
		   [ActiveFromDate],  
		   [ActiveLastDate],  
		   [Comments],  
		   [DateTimeCreated],  
		   [LastUpdateUserID],  
		   [DateTimeLastUpdate],  
		   [EconomicLevel],  
		   [WarehouseSize],  
		   [Custom1],  
		   [Custom2],  
		   [Custom3],  
		   [DunsNumber],  
		   [Custom4],  
		   [ActiveStatus]  
			)  
  
     VALUES  
           (             
		   s.[WarehouseID] ,  
		   s.[ChainID],  
		   s.[WarehouseName],  
		   s.[WarehouseIdentifier],  
		   s.[LocationTypeID],  
		   s.[ActiveFromDate],  
		   s.[ActiveLastDate],  
		   s.[Comments],  
		   s.[DateTimeCreated],  
		   s.[LastUpdateUserID],  
		   s.[DateTimeLastUpdate],  
		   s.[EconomicLevel],  
		   s.[WarehouseSize],  
		   s.[Custom1],  
		   s.[Custom2],  
		   s.[Custom3],  
		   s.[DunsNumber],  
		   s.[Custom4],  
		   s.[ActiveStatus]  
           );  
  
 delete cdc.dbo_WareHouses_CT  
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
