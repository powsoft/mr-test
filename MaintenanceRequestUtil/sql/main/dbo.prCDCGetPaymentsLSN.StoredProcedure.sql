USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetPaymentsLSN]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetPaymentsLSN]
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



SET @from_lsn = sys.fn_cdc_get_min_lsn(N'dbo_Payments');
SET @to_lsn = sys.fn_cdc_get_max_lsn();


--print @from_lsn

--print @to_lsn

--Archive all CDC records

--/*

insert into DataTrue_Archive..dbo_Payments_CT 
([__$start_lsn]
      ,[__$end_lsn]
      ,[__$seqval]
      ,[__$operation]
      ,[__$update_mask]
      ,[PaymentID]
      ,[PaymentTypeID]
      ,[PayerEntityID]
      ,[PayeeEntityID]
      ,[AmountOriginallyBilled]
      ,[PaymentStatus]
      ,[DateTimePaid]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[Comments]
      ,[ACHAccountTypeID])
SELECT [__$start_lsn]
      ,[__$end_lsn]
      ,[__$seqval]
      ,[__$operation]
      ,[__$update_mask]
      ,[PaymentID]
      ,[PaymentTypeID]
      ,[PayerEntityID]
      ,[PayeeEntityID]
      ,[AmountOriginallyBilled]
      ,[PaymentStatus]
      ,[DateTimePaid]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[Comments]
      ,[ACHAccountTypeID]
  FROM [DataTrue_Main].[cdc].[dbo_Payments_CT]
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
--*/

MERGE INTO [DataTrue_Report].[dbo].Payments t

USING (SELECT __$operation
	  ,[PaymentID]
      ,[PaymentTypeID]
      ,[PayerEntityID]
      ,[PayeeEntityID]
      ,[AmountOriginallyBilled]
      ,[PaymentStatus]
      ,[DateTimePaid]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[Comments]
      ,[ACHAccountTypeID]
      	FROM cdc.fn_cdc_get_net_changes_dbo_Payments(@from_lsn, @to_lsn, 'all')
		where 1 = 1
		) s
		on t.PaymentID = s.PaymentID

WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
WHEN MATCHED THEN

   UPDATE 
   SET [PaymentTypeID] = s.PaymentTypeID
      ,[PayerEntityID] = s.PayerEntityID
      ,[PayeeEntityID] = s.PayeeEntityID
      ,[AmountOriginallyBilled] = s.AmountOriginallyBilled
      ,[PaymentStatus] = s.PaymentStatus
      ,[DateTimePaid] = s.DateTimePaid
      ,[DateTimeCreated] = s.DateTimeCreated
      ,[LastUpdateUserID] = s.LastUpdateUserID
      ,[DateTimeLastUpdate] = s.DateTimeLastUpdate
      ,[ACHAccountTypeID]=s.[ACHAccountTypeID]
      ,[Comments] = s.Comments
 
WHEN NOT MATCHED 

THEN INSERT 
           ([PaymentID]
           ,[PaymentTypeID]
           ,[PayerEntityID]
           ,[PayeeEntityID]
           ,[AmountOriginallyBilled]
           ,[PaymentStatus]
           ,[DateTimePaid]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[Comments]
           ,[ACHAccountTypeID])
     VALUES
           (s.[PaymentID]
           ,s.[PaymentTypeID]
           ,s.[PayerEntityID]
           ,s.[PayeeEntityID]
           ,s.[AmountOriginallyBilled]
           ,s.[PaymentStatus]
           ,s.[DateTimePaid]
           ,s.[DateTimeCreated]
           ,s.[LastUpdateUserID]
           ,s.[DateTimeLastUpdate]
           ,s.[Comments]
           ,s.[ACHAccountTypeID]);


	delete cdc.dbo_Payments_CT
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
