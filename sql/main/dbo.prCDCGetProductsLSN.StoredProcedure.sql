USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetProductsLSN]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetProductsLSN]
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



SET @from_lsn = sys.fn_cdc_get_min_lsn(N'dbo_Products');
SET @to_lsn = sys.fn_cdc_get_max_lsn();


--print @from_lsn

--print @to_lsn

--Archive all CDC records

--/*

insert into DataTrue_Archive..dbo_Products_CT 
select * from cdc.dbo_Products_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
--*/

MERGE INTO [DataTrue_Report].[dbo].Products t

USING (SELECT __$operation, [ProductID]
      ,[ProductName]
      ,[Description]
      ,[ActiveStartDate]
      ,[ActiveLastDate]
      ,[Comments]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[UOM]
      ,[UOMQty]
      ,[PACKQty]
      	FROM cdc.fn_cdc_get_net_changes_dbo_Products(@from_lsn, @to_lsn, 'all')
		where 1 = 1
		) s
		on t.ProductId = s.ProductId

WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
	
WHEN MATCHED THEN

update set  
		[ProductName] =s.ProductName
      ,[Description] = s.Description
      ,[ActiveStartDate] = s.ActiveStartDate
      ,[ActiveLastDate] = s.ActiveLastDate
      ,[Comments] = s.Comments
      ,[DateTimeCreated] = s.DateTimeCreated
      ,[LastUpdateUserID] = s.LastUpdateUserID
      ,[DateTimeLastUpdate] = s.DateTimeLastUpdate
      ,[UOM] = s.UOM
      ,[UOMQty] = s.UOMQty
      ,[PACKQty] = s.PACKQty
      
WHEN NOT MATCHED 

THEN INSERT 
      (ProductId,[ProductName]
       ,[Description]
       ,[ActiveStartDate]
       ,[ActiveLastDate]
       ,[Comments]
       ,[DateTimeCreated]
       ,[LastUpdateUserID]
       ,[DateTimeLastUpdate]
       ,[UOM]
       ,[UOMQty]
       ,[PACKQty])
     VALUES
       (s.ProductId
       ,s.ProductName
           ,s.Description
           ,s.ActiveStartDate
           ,s.ActiveLastDate
           ,s.Comments
           ,s.DateTimeCreated
           ,s.LastUpdateUserID
           ,s.DateTimeLastUpdate
           ,s.UOM
           ,s.UOMQty
           ,s.PACKQty);
     

MERGE INTO [DataTrue_EDI].[dbo].Products t

USING (SELECT [ProductID]
      ,[ProductName]
      ,[Description]
      ,[ActiveStartDate]
      ,[ActiveLastDate]
      ,[Comments]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[UOM]
      ,[UOMQty]
      ,[PACKQty]
      	FROM cdc.fn_cdc_get_net_changes_dbo_Products(@from_lsn, @to_lsn, 'all')
		where 1 = 1
		) s
		on t.ProductId = s.ProductId

WHEN MATCHED THEN

update set  
		[ProductName] =s.ProductName
      ,[Description] = s.Description
      ,[ActiveStartDate] = s.ActiveStartDate
      ,[ActiveLastDate] = s.ActiveLastDate
      ,[Comments] = s.Comments
      ,[DateTimeCreated] = s.DateTimeCreated
      ,[LastUpdateUserID] = s.LastUpdateUserID
      ,[DateTimeLastUpdate] = s.DateTimeLastUpdate
      ,[UOM] = s.UOM
      ,[UOMQty] = s.UOMQty
      ,[PACKQty] = s.PACKQty
      
WHEN NOT MATCHED 

THEN INSERT 
      (ProductId,[ProductName]
       ,[Description]
       ,[ActiveStartDate]
       ,[ActiveLastDate]
       ,[Comments]
       ,[DateTimeCreated]
       ,[LastUpdateUserID]
       ,[DateTimeLastUpdate]
       ,[UOM]
       ,[UOMQty]
       ,[PACKQty])
     VALUES
       (s.ProductId
       ,s.ProductName
           ,s.Description
           ,s.ActiveStartDate
           ,s.ActiveLastDate
           ,s.Comments
           ,s.DateTimeCreated
           ,s.LastUpdateUserID
           ,s.DateTimeLastUpdate
           ,s.UOM
           ,s.UOMQty
           ,s.PACKQty);
     



	delete cdc.dbo_Products_CT
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
