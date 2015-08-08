USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetBrandsLSN]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetBrandsLSN]
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



SET @from_lsn = sys.fn_cdc_get_min_lsn(N'dbo_Brands');
SET @to_lsn = sys.fn_cdc_get_max_lsn();


--print @from_lsn

--print @to_lsn

--Archive all CDC records

--/*

insert into DataTrue_Archive..dbo_Brands_CT 
select * from cdc.dbo_Brands_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
--*/

MERGE INTO [DataTrue_Report].[dbo].Brands t

USING (SELECT __$operation
	  ,[BrandID]
      ,[ManufacturerID]
      ,[BrandName]
      ,[BrandIdentifier]
      ,[BrandDescription]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,OwnerEntityID
      ,OwnerBrandIdentifier
      	FROM cdc.fn_cdc_get_net_changes_dbo_Brands(@from_lsn, @to_lsn, 'all')
		where 1 = 1
		) s
		on t.BrandId = s.BrandId
WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
WHEN MATCHED THEN

update 	
   SET [BrandId]=s.BrandId
	  ,[ManufacturerID] = s.ManufacturerID
      ,[BrandName] = s.BrandName
      ,[BrandIdentifier] = s.BrandIdentifier
      ,[BrandDescription] = s.BrandDescription
      ,[DateTimeCreated] = s.DateTimeCreated
      ,[LastUpdateUserID] = s.LastUpdateUserID
      ,[DateTimeLastUpdate] = s.DateTimeLastUpdate
      ,OwnerEntityID=s.OwnerEntityID
      ,OwnerBrandIdentifier=s.OwnerBrandIdentifier
 	
WHEN NOT MATCHED 

THEN INSERT 
      ([BrandId]
		   ,[ManufacturerID]
           ,[BrandName]
           ,[BrandIdentifier]
           ,[BrandDescription]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,OwnerEntityID
           ,OwnerBrandIdentifier)
     VALUES
           (s.BrandId
           ,s.ManufacturerID
           ,s.BrandName
           ,s.BrandIdentifier
           ,s.BrandDescription
           ,s.DateTimeCreated
           ,s.LastUpdateUserID
           ,s.DateTimeLastUpdate
           ,s.OwnerEntityID
           ,s.OwnerBrandIdentifier);

	delete cdc.dbo_Brands_CT
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
