USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGenerateInvoice]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prGenerateInvoice]
as
Begin
	select * from DataTrue_EDI..InvoiceDetails
	where InvoiceDetailTypeID in (14,15)
End
GO
