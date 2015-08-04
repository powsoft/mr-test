USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetProductIdentifiersLSN_New]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetProductIdentifiersLSN_New]
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
    
    

exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMinLSN_TableName 'dbo_ProductIdentifiers',@from_lsn output

exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMaxLSN @to_lsn output--sys.fn_cdc_get_max_lsn();

    
--print @from_lsn    
    
--print @to_lsn    
    
--Archive all CDC records    
    
/*    
    
insert into [IC-HQSQL1INST2].DataTrue_Archive.dbo.dbo_ProductIdentifiers_CT     
SELECT [__$start_lsn]    
      ,[__$end_lsn]    
      ,[__$seqval]    
      ,[__$operation]    
      ,[__$update_mask]    
      ,[ProductID]    
      ,[ProductIdentifierTypeID]    
      ,[OwnerEntityId]    
      ,[IdentifierValue]    
      ,[Bipad]    
      ,[Priority]    
      ,[Comments]    
      ,[DateTimeCreated]    
      ,[LastUpdateUserID]    
      ,[DateTimeLastUpdate]
      ,[ContextProductDescription]
      ,[SupplierPackageID]   
  FROM [IC-HQSQL1\DataTrue].DataTrue_Main.[cdc].[dbo_ProductIdentifiers_CT]    
 where __$start_lsn >= @from_lsn    
 and __$start_lsn <= @to_lsn    

    
--select * from DataTrue_Archive..dbo_ProductIdentifiers_CT       
    
MERGE INTO [DataTrue_Report].[dbo].ProductIdentifiers t    
    
USING (SELECT __$operation,[ProductID]    
      ,[ProductIdentifierTypeID]    
      ,[OwnerEntityId]    
      ,[IdentifierValue]    
       ,[Bipad]    
      ,[Priority]    
      ,[Comments]    
      ,[DateTimeCreated]    
      ,[LastUpdateUserID]    
      ,[DateTimeLastUpdate]
      ,[ContextProductDescription]
      ,[SupplierPackageID] 
       FROM [IC-HQSQL1\DataTrue].DataTrue_Main.[cdc].[dbo_ProductIdentifiers_CT]    
 where __$start_lsn >= @from_lsn    
 and __$start_lsn <= @to_lsn    
 and __$operation<>3
	order by __$start_lsn
  ) as  s    
  on s.ProductId = t.ProductId  
  and t.ProductIdentifierTypeId = s.ProductIdentifierTypeID  
   and t.OwnerEntityId = s.OwnerEntityId  
    and t.IdentifierValue = s.IdentifierValue  

WHEN MATCHED AND s.__$operation = 1 THEN    
 Delete    
     
WHEN MATCHED THEN    
    
update set      
  [ProductIdentifierTypeID] = s.ProductIdentifierTypeID    
      ,[OwnerEntityId] = s.OwnerEntityId    
      ,[IdentifierValue] = s.IdentifierValue    
      ,[Bipad]=s.[Bipad]    
      ,[Priority]=s.[Priority]    
      ,[Comments] = s.Comments    
      ,[DateTimeCreated] = s.DateTimeCreated    
      ,[LastUpdateUserID] = s.LastUpdateUserID    
      ,[DateTimeLastUpdate] = s.DateTimeLastUpdate
      ,[ContextProductDescription]=s.ContextProductDescription   
      ,[SupplierPackageID]=s.SupplierPackageID    
WHEN NOT MATCHED     
    
THEN INSERT     
      ([ProductID]    
           ,[ProductIdentifierTypeID]    
           ,[OwnerEntityId]    
           ,[IdentifierValue]    
           ,[Bipad]    
		   ,[Priority]    
           ,[Comments]    
           ,[DateTimeCreated]    
           ,[LastUpdateUserID]    
           ,[DateTimeLastUpdate]
           ,ContextProductDescription
           ,SupplierPackageID)    
     VALUES    
           (s.ProductID    
           ,s.ProductIdentifierTypeID    
           ,s.OwnerEntityId    
           ,s.IdentifierValue    
           ,s.[Bipad]    
		  ,s.[Priority]    
           ,s.Comments    
           ,s.DateTimeCreated    
           ,s.LastUpdateUserID    
           ,s.DateTimeLastUpdate
           ,s.ContextProductDescription
           ,s.SupplierPackageID);    
           
           
 
MERGE INTO [IC-HQSQL1\DataTrue].[DataTrue_EDI].[dbo].ProductIdentifiers t    
    
USING (SELECT __$operation,[ProductID]    
      ,[ProductIdentifierTypeID]    
      ,[OwnerEntityId]    
      ,[IdentifierValue]    
       ,[Bipad]    
      ,[Priority]    
      ,[Comments]    
      ,[DateTimeCreated]    
      ,[LastUpdateUserID]    
      ,[DateTimeLastUpdate]
      ,[ContextProductDescription]
      ,[SupplierPackageID] 
       FROM [IC-HQSQL1\DataTrue].DataTrue_Main.[cdc].[dbo_ProductIdentifiers_CT]    
 where __$start_lsn >= @from_lsn    
 and __$start_lsn <= @to_lsn    
  
  ) as  s    
  on s.ProductId = t.ProductId  
  and t.ProductIdentifierTypeId = s.ProductIdentifierTypeID  
  
	    
WHEN MATCHED AND s.__$operation = 1 THEN    
 Delete    
     
WHEN MATCHED THEN    
    
update set      
  [ProductIdentifierTypeID] = s.ProductIdentifierTypeID    
      ,[OwnerEntityId] = s.OwnerEntityId    
      ,[IdentifierValue] = s.IdentifierValue    
      ,[Bipad]=s.[Bipad]    
      ,[Priority]=s.[Priority]    
      ,[Comments] = s.Comments    
      ,[DateTimeCreated] = s.DateTimeCreated    
      ,[LastUpdateUserID] = s.LastUpdateUserID    
      ,[DateTimeLastUpdate] = s.DateTimeLastUpdate
      ,[ContextProductDescription]=s.ContextProductDescription   
      ,[SupplierPackageID]=s.SupplierPackageID    
WHEN NOT MATCHED     
    
THEN INSERT     
      ([ProductID]    
           ,[ProductIdentifierTypeID]    
           ,[OwnerEntityId]    
           ,[IdentifierValue]    
           ,[Bipad]    
		   ,[Priority]    
           ,[Comments]    
           ,[DateTimeCreated]    
           ,[LastUpdateUserID]    
           ,[DateTimeLastUpdate]
           ,ContextProductDescription
           ,SupplierPackageID)    
     VALUES    
           (s.ProductID    
           ,s.ProductIdentifierTypeID    
           ,s.OwnerEntityId    
           ,s.IdentifierValue    
           ,s.[Bipad]    
		  ,s.[Priority]    
           ,s.Comments    
           ,s.DateTimeCreated    
           ,s.LastUpdateUserID    
           ,s.DateTimeLastUpdate
           ,s.ContextProductDescription
           ,s.SupplierPackageID);    
    
 delete [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_ProductIdentifiers_CT    
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

  --Print(@errormessage)
end catch    
     
    
return
GO
