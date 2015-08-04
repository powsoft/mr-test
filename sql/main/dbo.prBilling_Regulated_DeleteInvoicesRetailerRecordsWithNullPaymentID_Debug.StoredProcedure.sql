USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_Regulated_DeleteInvoicesRetailerRecordsWithNullPaymentID_Debug]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Vince Moore
-- Create date: 05/09/2013
-- Description:	Delete any regulated billing records with a null PaymentID. 
--				The null payment records throw off the total
-- =============================================
CREATE PROCEDURE [dbo].[prBilling_Regulated_DeleteInvoicesRetailerRecordsWithNullPaymentID_Debug]
AS
BEGIN
	
	Delete
	--select * into import.dbo.InvoicesRetailerDeleted_20130829_Null
	From datatrue_main.dbo.InvoicesRetailer 
	Where CAST(DateTimeCreated as date) = CAST(getdate() as date)
	and ChainID In(50964
		--Select distinct ChainID 
		--From DataTrue_EDI.dbo.ProcessStatus_ACH ps
		--Inner Join Chains c on c.ChainIdentifier = ps.ChainName
		--Where ps.BillingIsRunning = 1
		--and ps.BillingComplete = 0
		--and ps.[Date] = CAST(getdate() as date)
		)
	and Paymentid Is Null

	Delete
	--select *
	From DataTrue_EDI.dbo.InvoicesRetailer 
	Where CAST(DateTimeCreated as date) = CAST(getdate() as date)
	and ChainID In(50964
		--Select distinct ChainID 
		--From DataTrue_EDI.dbo.ProcessStatus_ACH ps
		--Inner Join Chains c on c.ChainIdentifier = ps.ChainName
		--Where ps.BillingIsRunning = 1
		--and ps.BillingComplete = 0
		--and ps.[Date] = CAST(getdate() as date)
		)
	and Paymentid Is Null

    
END
GO
