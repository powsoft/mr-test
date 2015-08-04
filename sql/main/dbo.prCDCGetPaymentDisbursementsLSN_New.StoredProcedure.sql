USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetPaymentDisbursementsLSN_New]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetPaymentDisbursementsLSN_New]
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

exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMinLSN_TableName 'dbo_PaymentDisbursements',@from_lsn output

exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMaxLSN @to_lsn output--sys.fn_cdc_get_max_lsn();


--print @from_lsn

--print @to_lsn

--Archive all CDC records

/*

INSERT INTO [IC-HQSQL1INST2].DataTrue_Archive.dbo.dbo_PaymentDisbursements_CT (
		[__$start_lsn]
		,[__$end_lsn]
		,[__$seqval]
		,[__$operation]
		,[__$update_mask]
		,[DisbursementID],
	[DisbursementAmount],
	[CheckNo],
	[DisbursementDate] ,
	[Comments],
	[DateTimeCreated],
	[LastUpdateUserID] ,
	[BatchNo] )
	SELECT
		[__$start_lsn],
		[__$end_lsn],
		[__$seqval],
		[__$operation],
		[__$update_mask],
		[DisbursementID],
		[DisbursementAmount],
	[CheckNo],
	[DisbursementDate] ,
	[Comments],
	[DateTimeCreated],
	[LastUpdateUserID] ,
	[BatchNo]
	FROM [IC-HQSQL1\DataTrue].DataTrue_Main.[cdc].[dbo_PaymentDisbursements_CT]
	WHERE __$start_lsn >= @from_lsn
	AND __$start_lsn <= @to_lsn


MERGE INTO [DataTrue_Report].[dbo].PaymentDisbursements t

USING ( SELECT
	__$operation,
	[DisbursementID],
		[DisbursementAmount],
	[CheckNo],
	[DisbursementDate] ,
	[Comments],
	[DateTimeCreated],
	[LastUpdateUserID] ,
	[BatchNo]
FROM [IC-HQSQL1\DataTrue].DataTrue_Main.[cdc].[dbo_PaymentDisbursements_CT]
	WHERE __$start_lsn >= @from_lsn
	AND __$start_lsn <= @to_lsn
	and __$operation<>3
	order by __$start_lsn
	) s
		on t.DisbursementID = s.DisbursementID

WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
WHEN MATCHED THEN

   UPDATE 
   SET
  
		[DisbursementAmount]=s.DisbursementAmount,
	[CheckNo]=s.CheckNo,
	[DisbursementDate]=s.DisbursementDate ,
	[Comments]=s.Comments,
	[DateTimeCreated]=s.DateTimeCreated,
	[LastUpdateUserID] =s.LastUpdateUserID,
	[BatchNo]=s.BatchNo
  
 
WHEN NOT MATCHED 

THEN INSERT 
           ([DisbursementID],
		[DisbursementAmount],
	[CheckNo],
	[DisbursementDate] ,
	[Comments],
	[DateTimeCreated],
	[LastUpdateUserID] ,
	[BatchNo])
     VALUES
           (s.[DisbursementID]
           ,s.[DisbursementAmount]
           ,s.[CheckNo]
           ,s.[DisbursementDate]
           ,s.[Comments]
           ,s.[DateTimeCreated]
           ,s.[LastUpdateUserID]
           ,s.[BatchNo]);
         

DELETE [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_PaymentDisbursements_CT
WHERE __$start_lsn >= @from_lsn
	AND __$start_lsn <= @to_lsn
	
--commit transaction
	*/
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
