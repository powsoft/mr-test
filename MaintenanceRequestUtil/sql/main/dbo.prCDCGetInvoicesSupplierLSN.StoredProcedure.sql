USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetInvoicesSupplierLSN]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetInvoicesSupplierLSN]
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



SET @from_lsn = sys.fn_cdc_get_min_lsn(N'dbo_InvoicesSupplier');
SET @to_lsn = sys.fn_cdc_get_max_lsn();


--print @from_lsn

--print @to_lsn

--Archive all CDC records

--/*

insert into DataTrue_Archive..dbo_InvoicesSupplier_CT 
select * from cdc.dbo_InvoicesSupplier_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
--*/

MERGE INTO [DataTrue_Report].[dbo].InvoicesSupplier t

USING (SELECT __$operation,[SupplierInvoiceID]
      ,[SupplierID]
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
      ,[PaymentID]
      ,[AggregationID]
      	FROM cdc.fn_cdc_get_net_changes_dbo_InvoicesSupplier(@from_lsn, @to_lsn, 'all')
		where 1 = 1
		) s
		on t.[SupplierInvoiceID] = s.SupplierInvoiceID

WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
	
WHEN MATCHED THEN

	UPDATE 
	SET [SupplierID] = s.SupplierID
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
      ,[PaymentID] = s.PaymentID
      ,[AggregationID] = s.AggregationID

	
WHEN NOT MATCHED 

THEN INSERT 
           ([SupplierInvoiceID]
           ,[SupplierID]
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
           ,[PaymentID]
           ,[AggregationID])
     VALUES
           (s.[SupplierInvoiceID]
           ,s.SupplierID
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
           ,s.PaymentID
           ,s.AggregationID);	


	delete cdc.dbo_InvoicesSupplier_CT
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
		--print @errormessage;
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
end catch
	

return
GO
