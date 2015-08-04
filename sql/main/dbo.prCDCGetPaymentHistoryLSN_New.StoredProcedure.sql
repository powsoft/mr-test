USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetPaymentHistoryLSN_New]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetPaymentHistoryLSN_New]
as

declare @MyID int
declare @startlsn binary(10)
declare @endlsn binary(10)
declare @count int
declare @from_lsn binary(10)
declare @to_lsn binary(10)

SET @MyID = 0

begin try

--begin transaction

exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMinLSN_TableName 'dbo_PaymentHistory',@from_lsn output

exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMaxLSN @to_lsn output--sys.fn_cdc_get_max_lsn();


--print @from_lsn

--print @to_lsn

--Archive all CDC records

/*

INSERT INTO [IC-HQSQL1INST2].DataTrue_Archive.dbo.dbo_PaymentHistory_CT (
		[__$start_lsn]
		,[__$end_lsn]
		,[__$seqval]
		,[__$operation]
		,[__$update_mask]
		,[RecordID]
		,[PaymentID]
		,[DateTimeCreated]
		,[LastUpdateUserID]
		,[PaymentStatus]
		,[PaymentStatusChangeDateTime]
		,[AmountPaid]
		,[CheckNoReceived]
		,[DatePaymentReceived]
		,[Comments]
		,[DisbursementID])
	SELECT
		[__$start_lsn],
		[__$end_lsn],
		[__$seqval],
		[__$operation],
		[__$update_mask],
		[RecordID],
		[PaymentID],
		[DateTimeCreated],
		[LastUpdateUserID],
		[PaymentStatus],
		[PaymentStatusChangeDateTime],
		[AmountPaid],
		[CheckNoReceived],
		[DatePaymentReceived],
		[Comments],
		[DisbursementID]
	FROM [IC-HQSQL1\DataTrue].DataTrue_Main.[cdc].[dbo_PaymentHistory_CT]
	WHERE __$start_lsn >= @from_lsn
	AND __$start_lsn <= @to_lsn


MERGE INTO [DataTrue_Report].[dbo].PaymentHistory t

USING ( SELECT
	__$operation,
	[RecordID],
	[PaymentID],
	[DateTimeCreated],
	[LastUpdateUserID],
	[PaymentStatus],
	[PaymentStatusChangeDateTime],
	[AmountPaid],
	[CheckNoReceived],
	[DatePaymentReceived],
	[Comments],
	[DisbursementID]
FROM [IC-HQSQL1\DataTrue].DataTrue_Main.[cdc].[dbo_PaymentHistory_CT]
	WHERE __$start_lsn >= @from_lsn
	AND __$start_lsn <= @to_lsn	
	and __$operation<>3
	order by __$start_lsn
	) s
		on t.RecordID = s.RecordID

WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
WHEN MATCHED THEN

   UPDATE 
   SET
  [PaymentID]=s.PaymentID
	,[DateTimeCreated]=s.DateTimeCreated
	 ,[LastUpdateUserID]=s.LastUpdateUserID
	,[PaymentStatus]=s.PaymentStatus
	 ,[PaymentStatusChangeDateTime]=s.PaymentStatusChangeDateTime
	,[AmountPaid]=s.AmountPaid 
	,[CheckNoReceived]=s.CheckNoReceived
	,[DatePaymentReceived]=s.DatePaymentReceived
	,[Comments]=s.Comments
	,[DisbursementID]=s.DisbursementID
 
WHEN NOT MATCHED 

THEN INSERT 
           ([RecordID]
      ,[PaymentID]
	,[DateTimeCreated]
	 ,[LastUpdateUserID]
	,[PaymentStatus]
	 ,[PaymentStatusChangeDateTime]
	,[AmountPaid]
	,[CheckNoReceived]
	,[DatePaymentReceived]
	,[Comments]
	,[DisbursementID])
     VALUES
           (s.[RecordID]
           ,s.[PaymentID]
           ,s.[DateTimeCreated]
           ,s.[LastUpdateUserID]
           ,s.[PaymentStatus]
           ,s.[PaymentStatusChangeDateTime]
           ,s.[AmountPaid]
           ,s.[CheckNoReceived]
           
           ,s.[DatePaymentReceived]
           ,s.[Comments]
           ,s.[DisbursementID]);


DELETE [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_PaymentHistory_CT
WHERE __$start_lsn >= @from_lsn
	AND __$start_lsn <= @to_lsn
	*/
--commit transaction
	
end try
	
begin catch
		--rollback transaction
		
		declare @errormessage varchar(4500)
		declare @errorlocation varchar(255)
		declare @errorsenderstring nvarchar(255)

SET @errormessage = ERROR_MESSAGE()
SET @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
SET @errorsenderstring = ERROR_PROCEDURE()

EXEC [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prLogExceptionAndNotifySupport	1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
										,
										@errorlocation,
										@errormessage,
										@errorsenderstring,
										@MyID
end catch
	

return
GO
