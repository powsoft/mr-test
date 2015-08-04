USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_GetInvoiceHeaderView]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_GetInvoiceHeaderView]
@chainid int=null
as

if @chainid is null
	begin
SELECT ir.[RetailerInvoiceID]
      ,ir.[ChainID]
      ,ir.[InvoiceDate]
      ,ir.[InvoicePeriodStart]
      ,ir.[InvoicePeriodEnd]
      ,ir.[OriginalAmount]
      ,it.[InvoiceTypeName] as InvoiceType --case when [InvoiceTypeID] = 0 then 'Original' else 'Adjustment' end as InvoiceType
      ,ir.[TransmissionDate]
      ,ir.[TransmissionRef]
      ,ir.[InvoiceStatus]
      ,ir.[OpenAmount]
      ,ir.[DateTimeClosed]
      ,ir.[DateTimeCreated]
      ,ir.[LastUpdateUserID]
      ,ir.[DateTimeLastUpdate]
  FROM [DataTrue_Main].[dbo].[InvoicesRetailer] ir
  inner join InvoiceTypes it
  on ir.InvoiceTypeID = it.InvoiceTypeID

SELECT ir.[SupplierInvoiceID]
      ,ir.[SupplierID]
      ,ir.[InvoiceDate]
      ,ir.[InvoicePeriodStart]
      ,ir.[InvoicePeriodEnd]
      ,ir.[OriginalAmount]
      ,it.[InvoiceTypeName] as InvoiceType --case when [InvoiceTypeID] = 0 then 'Original' else 'Adjustment' end as InvoiceType
      ,ir.[TransmissionDate]
      ,ir.[TransmissionRef]
      ,ir.[InvoiceStatus]
      ,ir.[OpenAmount]
      ,ir.[DateTimeClosed]
      ,ir.[DateTimeCreated]
      ,ir.[LastUpdateUserID]
      ,ir.[DateTimeLastUpdate]
  FROM [DataTrue_Main].[dbo].[InvoicesSupplier] ir
  inner join InvoiceTypes it
  on ir.InvoiceTypeID = it.InvoiceTypeID
	end
else
	begin
	
SELECT ir.[RetailerInvoiceID]
      ,ir.[ChainID]
      ,ir.[InvoiceDate]
      ,ir.[InvoicePeriodStart]
      ,ir.[InvoicePeriodEnd]
      ,ir.[OriginalAmount]
      ,it.[InvoiceTypeName] as InvoiceType --case when [InvoiceTypeID] = 0 then 'Original' else 'Adjustment' end as InvoiceType
      ,ir.[TransmissionDate]
      ,ir.[TransmissionRef]
      ,ir.[InvoiceStatus]
      ,ir.[OpenAmount]
      ,ir.[DateTimeClosed]
      ,ir.[DateTimeCreated]
      ,ir.[LastUpdateUserID]
      ,ir.[DateTimeLastUpdate]
  FROM [DataTrue_Main].[dbo].[InvoicesRetailer] ir
  inner join InvoiceTypes it
  on ir.InvoiceTypeID = it.InvoiceTypeID
  where ChainID = @chainid

SELECT ir.[SupplierInvoiceID]
      ,ir.[SupplierID]
      ,ir.[InvoiceDate]
      ,ir.[InvoicePeriodStart]
      ,ir.[InvoicePeriodEnd]
      ,ir.[OriginalAmount]
      ,it.[InvoiceTypeName] as InvoiceType --case when [InvoiceTypeID] = 0 then 'Original' else 'Adjustment' end as InvoiceType
      ,ir.[TransmissionDate]
      ,ir.[TransmissionRef]
      ,ir.[InvoiceStatus]
      ,ir.[OpenAmount]
      ,ir.[DateTimeClosed]
      ,ir.[DateTimeCreated]
      ,ir.[LastUpdateUserID]
      ,ir.[DateTimeLastUpdate]
  FROM [DataTrue_Main].[dbo].[InvoicesSupplier] ir
  inner join InvoiceTypes it
  on ir.InvoiceTypeID = it.InvoiceTypeID	
	
	
	end



return
GO
