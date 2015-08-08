USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetProductCategoriesLSN_New]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetProductCategoriesLSN_New]
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



exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMinLSN_TableName 'dbo_ProductCategories',@from_lsn output

exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMaxLSN @to_lsn output--sys.fn_cdc_get_max_lsn();



--print @from_lsn

--print @to_lsn

--Archive all CDC records

/*

insert into [IC-HQSQL1INST2].DataTrue_Archive.dbo.dbo_ProductCategories_CT 
select * from [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_ProductCategories_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn


MERGE INTO [DataTrue_Report].[dbo].ProductCategories t

USING (SELECT __$operation, [ProductCategoryID]
      ,[ProductCategoryParentID]
      ,[HierarchyID]
      ,[ProductCategoryName]
      ,[ProductCategoryDescription]
      ,[ChainID]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[MemberNumber]
      ,[StoreBanner]
      ,[OwnerEntityID]
,[OwnerGroupLevelID]
,[OwnerGroupID]

      	FROM [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_ProductCategories_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
	and __$operation<>3
	order by __$start_lsn
		) s
		on t.[ProductCategoryID] = s.[ProductCategoryID]

WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
	
WHEN MATCHED THEN

UPDATE 
   SET [ProductCategoryParentID] = s.ProductCategoryParentID
      ,[HierarchyID] = s.HierarchyID
      ,[ProductCategoryName] = s.ProductCategoryName
      ,[ProductCategoryDescription] = s.ProductCategoryDescription
      ,[ChainID] = s.ChainID
      ,[DateTimeCreated] = s.DateTimeCreated
      ,[LastUpdateUserID] = s.LastUpdateUserID
      ,[DateTimeLastUpdate] = s.DateTimeLastUpdate
      ,[MemberNumber] = s.MemberNumber
      ,[StoreBanner]=s.StoreBanner
	,[OwnerEntityID]=s.OwnerEntityID
	,[OwnerGroupLevelID]=s.OwnerGroupLevelID
	,[OwnerGroupID]=s.OwnerGroupID


 	
WHEN NOT MATCHED 

THEN INSERT 
      (ProductCategoryID,[ProductCategoryParentID]
           ,[HierarchyID]
           ,[ProductCategoryName]
           ,[ProductCategoryDescription]
           ,[ChainID]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[MemberNumber]
           ,[StoreBanner]
      
      ,[OwnerEntityID]
      ,[OwnerGroupLevelID]
)
     VALUES
           (s.ProductCategoryID,s.ProductCategoryParentID
           ,s.HierarchyID
           ,s.ProductCategoryName
           ,s.ProductCategoryDescription
           ,s.ChainID
           ,s.DateTimeCreated
           ,s.LastUpdateUserID
           ,s.DateTimeLastUpdate
           ,s.MemberNumber
           ,s.StoreBanner
     
      ,s.OwnerEntityID
      ,s.OwnerGroupLevelID
		);	


	delete [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_ProductCategories_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
	*/
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
		
		exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
end catch
	

return
GO
