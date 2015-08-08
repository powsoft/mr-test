USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetProductIdentifiersLSN]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetProductIdentifiersLSN]    
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
    
    
    
SET @from_lsn = sys.fn_cdc_get_min_lsn(N'dbo_ProductIdentifiers');    
SET @to_lsn = sys.fn_cdc_get_max_lsn();    
    
    
--print @from_lsn    
    
--print @to_lsn    
    
--Archive all CDC records    
    
--/*    
    
insert into DataTrue_Archive..dbo_ProductIdentifiers_CT     
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
  FROM [DataTrue_Main].[cdc].[dbo_ProductIdentifiers_CT]    
 where __$start_lsn >= @from_lsn    
 and __$start_lsn <= @to_lsn    
--*/    
    
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
       FROM cdc.fn_cdc_get_net_changes_dbo_ProductIdentifiers(0x00079385000158C70001, 0x0007D36E000526A800EF, 'all') 
  where 1 = 1  
  group by __$operation,
			ProductID,
		 [ProductIdentifierTypeID]  
		, [OwnerEntityId]  
		, [IdentifierValue]  
		, [Bipad]  
		  , [Priority]  
		  , [Comments]  
		  , [DateTimeCreated]  
		  , [LastUpdateUserID]  
		  , [DateTimeLastUpdate]
		  --having count(1) > 1  
  ) as  s    
  on s.ProductId = t.ProductId  
  and t.ProductIdentifierTypeId = s.ProductIdentifierTypeID  
  --group by s.__$operation,s.ProductID,
		--s.[ProductIdentifierTypeID]  
		--,s.[OwnerEntityId]  
		--,s.[IdentifierValue]  
		--,s.[Bipad]  
		--  ,s.[Priority]  
		--  ,s.[Comments]  
		--  ,s.[DateTimeCreated]  
		--  ,s.[LastUpdateUserID]  
		--  ,s.[DateTimeLastUpdate]
	    
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
           ,[DateTimeLastUpdate])    
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
           ,s.DateTimeLastUpdate);    
    
 delete cdc.dbo_ProductIdentifiers_CT    
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
  --exec dbo.prLogExceptionAndNotifySupport    
  --1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue    
  --,@errorlocation    
  --,@errormessage    
  --,@errorsenderstring    
  --,@MyID   
  Print  @errormessage  
end catch    
     
    
return
GO
