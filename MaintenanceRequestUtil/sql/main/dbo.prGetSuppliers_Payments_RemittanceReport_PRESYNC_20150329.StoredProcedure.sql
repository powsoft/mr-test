USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetSuppliers_Payments_RemittanceReport_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prGetSuppliers_Payments_RemittanceReport_PRESYNC_20150329]
	@ChainID int
as
Begin
	select distinct PayeeEntityID as "SupplierID"
	from PaymentHistory h join Payments p
	on h.PaymentID=p.PaymentID
	and h.PaymentStatus=p.PaymentStatus
	join PaymentDisbursements d
	on h.DisbursementID=d.DisbursementID 
	and p.PaymentStatus=10
	where PayerEntityID=@ChainID
End
GO
