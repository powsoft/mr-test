USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetSuppliers_Payments_RemittanceReport_debug]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prGetSuppliers_Payments_RemittanceReport_debug]
	@ChainID int
as
Begin
	select distinct PayeeEntityID as "SupplierID"
	from import.dbo.PaymentHistory_temp h join import.dbo.Payments_temp p
	on h.PaymentID=p.PaymentID
	and h.PaymentStatus=p.PaymentStatus
	join import.dbo.Paymentdisbursements_temp d
	on h.DisbursementID=d.DisbursementID 
	and p.PaymentStatus=10
	where PayerEntityID=@ChainID
End
GO
