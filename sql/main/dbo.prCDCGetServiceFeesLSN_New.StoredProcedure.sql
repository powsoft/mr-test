USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetServiceFeesLSN_New]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetServiceFeesLSN_New]
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

exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMinLSN_TableName 'dbo_ServiceFees',@from_lsn output

exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMaxLSN @to_lsn output--sys.fn_cdc_get_max_lsn();


--print @from_lsn

--print @to_lsn

--Archive all CDC records

/*

insert into [IC-HQSQL1INST2].DataTrue_Archive.dbo.dbo_ServiceFees_CT 
select * from [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_ServiceFees_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn


MERGE INTO [DataTrue_Report].[dbo].ServiceFees t

USING (SELECT __$operation
				,[ServiceFeeID]
				,[ServiceFeeTypeID]
				,[ChainID]
				,[SupplierID]
				,[StoreID]
				,[ProductID]
				,[ServiceFeeFactorValue]
				,[ActiveStartDate]
				,[ActiveLastDate]
				,[ServiceFeeReportedToRetailerDate]
				,[FileName]
				,[Comments]
				,[DateTimeCreated]
				,[LastUpdateUserID]
				,[DateTimeLastUpdate]
				,[FromFactor]
				,[ToFactor]
      	--FROM cdc.fn_cdc_get_net_changes_dbo_ServiceFees(@from_lsn, @to_lsn, 'all')
      	from [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_ServiceFees_CT
		where __$start_lsn >= @from_lsn
		and __$start_lsn <= @to_lsn
		and __$operation<>3
    order by __$start_lsn
		) s
		on t.ServiceFeeID = s.ServiceFeeID
WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
WHEN MATCHED THEN

UPDATE 	
   SET [ServiceFeeTypeID] = s.ServiceFeeTypeID
      ,[ChainID] = s.ChainID
      ,[SupplierID] = s.SupplierID
      ,[StoreID] = s.StoreID
      ,[ProductID] = s.ProductID
      ,[ServiceFeeFactorValue] = s.ServiceFeeFactorValue
      ,[ActiveStartDate] = s.ActiveStartDate
      ,[ActiveLastDate] = s.ActiveLastDate
      ,[ServiceFeeReportedToRetailerDate] = s.ServiceFeeReportedToRetailerDate
      ,[FileName] = s.FileName
      ,[Comments] = s.Comments
      ,[DateTimeCreated] = s.DateTimeCreated
      ,[LastUpdateUserID] = s.LastUpdateUserID
      ,[DateTimeLastUpdate] = s.DateTimeLastUpdate
      ,[FromFactor] = s.FromFactor
      ,[ToFactor] = s.ToFactor
 	
WHEN NOT MATCHED 

THEN INSERT 
		    ([ServiceFeeID]
			,[ServiceFeeTypeID]
			,[ChainID]
			,[SupplierID]
			,[StoreID]
			,[ProductID]
			,[ServiceFeeFactorValue]
			,[ActiveStartDate]
			,[ActiveLastDate]
			,[ServiceFeeReportedToRetailerDate]
			,[FileName]
			,[Comments]
			,[DateTimeCreated]
			,[LastUpdateUserID]
			,[DateTimeLastUpdate]
			,[FromFactor]
			,[ToFactor])
     VALUES
           (s.ServiceFeeID
			,s.ServiceFeeTypeID
			,s.ChainID
			,s.SupplierID
			,s.StoreID
			,s.ProductID
			,s.ServiceFeeFactorValue
			,s.ActiveStartDate
			,s.ActiveLastDate
			,s.ServiceFeeReportedToRetailerDate
			,s.FileName
			,s.Comments
			,s.DateTimeCreated
			,s.LastUpdateUserID
			,s.DateTimeLastUpdate
			,s.FromFactor
			,s.ToFactor);
           
	delete [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_ServiceFees_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
	
--commit transaction
	*/
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
