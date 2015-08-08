USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetInvoicesRetailerLSN_New]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetInvoicesRetailerLSN_New]
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

exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMinLSN_TableName 'dbo_InvoicesRetailer',@from_lsn output
exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMaxLSN @to_lsn output--sys.fn_cdc_get_max_lsn();

--print @from_lsn

--print @to_lsn

--Archive all CDC records

/*

insert into [IC-HQSQL1INST2].DataTrue_Archive.dbo.dbo_InvoicesRetailer_CT 
select * from [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_InvoicesRetailer_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn


MERGE INTO [DataTrue_Report].[dbo].InvoicesRetailer t

USING (SELECT __$operation, [RetailerInvoiceID]
      ,[ChainID]
      ,[InvoiceDate]
      ,[InvoicePeriodStart]
      ,[InvoicePeriodEnd]
      ,[OriginalAmount]
      ,[InvoiceTypeID]
      ,[TransmissionDate]
      ,[TransmissionRef]
      ,[InvoiceStatus]
      ,[OpenAmount]
      ,[DateTimeClosed]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[InvoiceDetailGroupID]
      ,[RawStoreIdentifier]
      ,[Route]
      ,[InvoiceNumber]
      ,[PaymentID]
      ,[PaymentDueDate]
      ,[StoreID]
      ,[AggregationID]
      ,AccountCode
      from	[IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_InvoicesRetailer_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
	and __$operation<>3
	order by __$start_lsn
		) s
		on t.RetailerInvoiceID = s.RetailerInvoiceID

WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
	
WHEN MATCHED THEN

	UPDATE 
	SET [ChainID] = s.ChainID
      ,[InvoiceDate] = s.InvoiceDate
      ,[InvoicePeriodStart] = s.InvoicePeriodStart
      ,[InvoicePeriodEnd] = s.InvoicePeriodEnd
      ,[OriginalAmount] = s.OriginalAmount
      ,[InvoiceTypeID] = s.InvoiceTypeID
      ,[TransmissionDate] = s.TransmissionDate
      ,[TransmissionRef] = s.TransmissionRef
      ,[InvoiceStatus] = s.InvoiceStatus
      ,[OpenAmount] = s.OpenAmount
      ,[DateTimeClosed] = s.DateTimeClosed
      ,[DateTimeCreated] = s.DateTimeCreated
      ,[LastUpdateUserID] = s.LastUpdateUserID
      ,[DateTimeLastUpdate] = s.DateTimeLastUpdate
      ,[InvoiceDetailGroupID] = s.InvoiceDetailGroupID
      ,[RawStoreIdentifier] = s.RawStoreIdentifier
      ,[Route] = s.Route
      ,[InvoiceNumber] = s.InvoiceNumber
      ,[PaymentID] = s.PaymentID
      ,[PaymentDueDate] = s.PaymentDueDate
      ,[StoreID] = s.StoreID
      ,[AggregationID] = s.AggregationID
      ,AccountCode=s.AccountCode
	
WHEN NOT MATCHED 

THEN INSERT 
           (RetailerInvoiceID
           ,[ChainID]
           ,[InvoiceDate]
           ,[InvoicePeriodStart]
           ,[InvoicePeriodEnd]
           ,[OriginalAmount]
           ,[InvoiceTypeID]
           ,[TransmissionDate]
           ,[TransmissionRef]
           ,[InvoiceStatus]
           ,[OpenAmount]
           ,[DateTimeClosed]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[InvoiceDetailGroupID]
           ,[RawStoreIdentifier]
           ,[Route]
           ,[InvoiceNumber]
           ,[PaymentID]
           ,[PaymentDueDate]
           ,[StoreID]
           ,[AggregationID]
           ,AccountCode)
     VALUES
           (s.RetailerInvoiceID
           ,s.ChainID
           ,s.InvoiceDate
           ,s.InvoicePeriodStart
           ,s.InvoicePeriodEnd
           ,s.OriginalAmount
           ,s.InvoiceTypeID
           ,s.TransmissionDate
           ,s.TransmissionRef
           ,s.InvoiceStatus
           ,s.OpenAmount
           ,s.DateTimeClosed
           ,s.DateTimeCreated
           ,s.LastUpdateUserID
           ,s.DateTimeLastUpdate
           ,s.InvoiceDetailGroupID
           ,s.RawStoreIdentifier
           ,s.Route
           ,s.InvoiceNumber
           ,s.PaymentID
           ,s.PaymentDueDate
           ,s.StoreID
           ,s.AggregationID
           ,s.AccountCode
           );	


	delete [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_InvoicesRetailer_CT
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
		--print @errormessage;
		exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
end catch
	

return
GO
