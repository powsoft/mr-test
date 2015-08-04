USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SupplierInvoiceBilling30Days_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[usp_SupplierInvoiceBilling30Days_PRESYNC_20150415]

AS
BEGIN
	Select CONVERT(Date, TimeStamp) AS Date, SUM(RetailerInvoiceCount)  [Transaction #], SUM(TotalBilledAmount) AS [Billed $], SUM(ACHAmount)[ACH $]
	From DataTrue_edi..processtracking_billing_sup
	Where CONVERT(Date, TimeStamp) >= GETDATE()-30
	Group By CONVERT(Date, TimeStamp)
	Order By Date DESC
END
GO
