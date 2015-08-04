USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_GetInvoiceDetailsView]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_GetInvoiceDetailsView]
@chainid int=null
as

if @chainid is null

	select InvoiceDetailTypeName as DetailType, saledate as Saledate2, d.*
	from InvoiceDetails d
	inner join invoicedetailtypes t
	on d.InvoiceDetailTypeID = t.InvoiceDetailTypeID
else
	select InvoiceDetailTypeName as DetailType, saledate as Saledate2, d.*
	from InvoiceDetails d
	inner join invoicedetailtypes t
	on d.InvoiceDetailTypeID = t.InvoiceDetailTypeID
	where ChainID = @chainid
/*
SELECT [InvoiceDetailID]
      ,[RetailerInvoiceID]
      ,[SupplierInvoiceID]
      ,[ChainID]
      ,[StoreID]
      ,[ProductID]
      ,[BrandID]
      ,[SupplierID]
      ,[InvoiceDetailTypeID]
      ,[TotalQty]
      ,[UnitCost]
      ,[UnitRetail]
      ,[TotalCost]
      ,[TotalRetail]
      ,[SaleDate]
      ,[RecordStatus]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[BatchID]
  FROM [DataTrue_Main].[dbo].[InvoiceDetails]
*/





return
GO
