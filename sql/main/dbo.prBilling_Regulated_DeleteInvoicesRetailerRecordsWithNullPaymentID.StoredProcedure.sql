USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_Regulated_DeleteInvoicesRetailerRecordsWithNullPaymentID]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Vince Moore
-- Create date: 05/09/2013
-- Description:	Delete any regulated billing records with a null PaymentID. 
--				The null payment records throw off the total
-- select * from DataTrue_EDI.[dbo].[InvoicesRetailer_Errors] order by RetailerInvoiceID desc
-- =============================================
CREATE PROCEDURE [dbo].[prBilling_Regulated_DeleteInvoicesRetailerRecordsWithNullPaymentID]
AS
BEGIN

DECLARE @ProcessID INT

SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobName = 'DailyRegulatedBilling'


-------- SAVING RECORDS FIRST ---------------------------

INSERT INTO DataTrue_Main.[dbo].[InvoicesRetailer_Errors]
(
	   RetailerInvoiceID
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
	  ,[ErrorDetails]
)
SELECT
	   ir.RetailerInvoiceID
	  ,ir.[ChainID]
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
      ,ir.[DateTimeCreated]
      ,ir.[LastUpdateUserID]
      ,ir.[DateTimeLastUpdate]
      ,[InvoiceDetailGroupID]
      ,ir.[RawStoreIdentifier]
      ,ir.[Route]
      ,[InvoiceNumber]
      ,ir.[PaymentID]
      ,ir.[PaymentDueDate]
      ,ir.[StoreID]
      ,[AggregationID]    
      ,'Paymentid IS NULL Issue'
FROM 
	DataTrue_Main.dbo.InvoicesRetailer AS ir WITH (NOLOCK)
	LEFT OUTER JOIN DataTrue_Main.dbo.InvoiceDetails AS id WITH (NOLOCK)
	ON ir.RetailerInvoiceID = id.RetailerInvoiceID
	WHERE CAST(ir.DateTimeCreated as date) = CAST(getdate() as date)
	and ir.PaymentID Is Null
	AND ISNULL(id.RecordType, 0) NOT IN (3)
	and ISNULL(id.ProcessID, @ProcessID) = @ProcessID
	
INSERT INTO DataTrue_EDI.[dbo].[InvoicesRetailer_Errors]
(
	   RetailerInvoiceID
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

	  ,[ErrorDetails]
)
SELECT
	   ir.RetailerInvoiceID
	  ,ir.[ChainID]
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
      ,ir.[DateTimeCreated]
      ,ir.[LastUpdateUserID]
      ,ir.[DateTimeLastUpdate]
      ,[InvoiceDetailGroupID]
      ,ir.[RawStoreIdentifier]
      ,ir.[Route]
      ,[InvoiceNumber]
      ,ir.[PaymentID]
      ,ir.[PaymentDueDate]
      ,ir.[StoreID]
      ,[AggregationID]
      
      ,'Paymentid IS NULL Issue'
FROM 
	DataTrue_EDI.dbo.InvoicesRetailer AS ir WITH (NOLOCK)
	LEFT OUTER JOIN DataTrue_EDI.dbo.InvoiceDetails AS id WITH (NOLOCK)
	ON ir.RetailerInvoiceID = id.RetailerInvoiceID
	WHERE CAST(ir.DateTimeCreated as date) = CAST(getdate() as date)
	and ir.PaymentID Is Null
	AND ISNULL(id.RecordType, 0) NOT IN (3)
	AND ir.InvoiceTypeID = 1
	AND id.InvoiceDetailTypeID = 2
	and ISNULL(id.ProcessID, @ProcessID) = @ProcessID
	
-------- SAVING RECORDS FIRST ---------------------------

	Delete ir
	--select *
	From DataTrue_Main.dbo.InvoicesRetailer AS ir
	LEFT OUTER JOIN DataTrue_Main.dbo.InvoiceDetails AS id
	ON ir.RetailerInvoiceID = id.RetailerInvoiceID
	Where CAST(ir.DateTimeCreated as date) = CAST(getdate() as date)
	and ir.Paymentid Is Null
	and InvoiceTypeID = 1
	AND ISNULL(id.RecordType, 0) NOT IN (3)
	AND ir.InvoiceTypeID = 1
	AND ISNULL(id.InvoiceDetailTypeID, 2) = 2
	and ISNULL(id.ProcessID, @ProcessID) = @ProcessID
	
	Delete ir
	--select *
	From DataTrue_EDI.dbo.InvoicesRetailer AS ir
	LEFT OUTER JOIN DataTrue_EDI.dbo.InvoiceDetails AS id
	ON ir.RetailerInvoiceID = id.RetailerInvoiceID
	Where CAST(ir.DateTimeCreated as date) = CAST(getdate() as date)
	and ir.Paymentid Is Null
	and InvoiceTypeID = 1
	AND ISNULL(id.RecordType, 0) NOT IN (3)
	AND ir.InvoiceTypeID = 1
	AND ISNULL(id.InvoiceDetailTypeID, 2) = 2
	and ISNULL(id.ProcessID, @ProcessID) = @ProcessID

END
GO
