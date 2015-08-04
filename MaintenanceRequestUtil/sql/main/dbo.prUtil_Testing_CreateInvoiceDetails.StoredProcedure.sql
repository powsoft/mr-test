USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Testing_CreateInvoiceDetails]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prUtil_Testing_CreateInvoiceDetails]
as
exec prInvoiceDetail_ReleaseStoreTransactions
exec prInvoiceDetail_POS_Create
exec prInvoiceDetail_SUP_Create
exec prInvoiceDetail_Retailer_Shrink_Create
exec prInvoiceDetail_Supplier_Shrink_Create
exec prInvoiceDetail_POSADJ_Create
exec prInvoiceDetail_SUPADJ_Create
exec prInvoiceDetail_Retailer_Shrink_Adj_Create
exec prInvoiceDetail_Supplier_Shrink_Adj_Create
exec prInvoiceDetail_DollarDifference_Create
return
GO
