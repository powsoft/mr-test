USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_ViewPaymentWHLS]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec amb_ViewPaymentWHLS 'TOP','09/21/2014','','WR6405','28943'
--exec amb_ViewPaymentWHLS '-1','01/01/1900','','CLL','24164'
--exec amb_ViewPaymentWHLS 'DOIL','01/01/1900','','wr1488','24538'
--exec amb_ViewPaymentWHLS 'LG','02/09/2014','','WR1023','24279'

CREATE procedure [dbo].[amb_ViewPaymentWHLS]
(
	@ChainID varchar(10),
	@WeekEnd varchar(20),
	@StoreNumber varchar(10),
	@SupplierIdentifier varchar(20),
	@SupplierId varchar(20)
)

AS 

BEGIN
--select * from invoicedetails  where 
Declare @sqlQueryNew varchar(8000)
		SET @sqlQueryNew=' select distinct sup.SupplierIdentifier as WholesalerID 
			, c.ChainIdentifier  as ChainID
			, Convert(varchar(12),InvoicePeriodEnd,101) as WeekEnding
			, Convert(varchar(12),pd.DisbursementDate,101) as DateIssued
			, pd.CheckNo AS CheckNumber
			, s.LegacySystemStoreIdentifier AS StoreID
			, SumOfTotalCheck
			, t.InvoiceDetailTypeName AS InvType
		
		from dbo.InvoicesSupplier i  WITH (NOLOCK) 
		join (Select distinct SupplierInvoiceID, ChainId, StoreId, PaymentId,InvoiceDetailTypeID, 
				SUM(TotalCost-Adjustment1)  as SumOfTotalCheck
				from dbo.InvoiceDetails WITH (NOLOCK) 
				group by SupplierInvoiceID, ChainId, StoreId, PaymentId,InvoiceDetailTypeID) d on i.SupplierInvoiceID=d.SupplierInvoiceID
		join dbo.Stores s  WITH (NOLOCK) on s.StoreID=d.StoreID and s.ChainID=d.ChainID
		join (Select distinct DisbursementID, PaymentID, PaymentStatus from dbo.PaymentHistory WITH (NOLOCK)) h on h.PaymentID=d.PaymentID 
		join dbo.PaymentDisbursements pd  WITH (NOLOCK) on pd.DisbursementID=h.DisbursementID and pd.VoidStatus is null
		join dbo.Suppliers sup  WITH (NOLOCK) on sup.SupplierID=i.SupplierID
		join dbo.Chains c  WITH (NOLOCK) on c.ChainID=d.ChainID
		join dbo.InvoiceDetailTypes t  WITH (NOLOCK) on t.InvoiceDetailTypeID=d.InvoiceDetailTypeID
		LEFT JOIN DataTrue_Main.dbo.BillingControl BC WITH (NOLOCK) ON BC.EntityIDToInvoice = sup.SupplierID AND BC.ChainID = C.ChainID
		where 1=1 AND i.SupplierID =''' +@SupplierId +''''
		
		IF(@ChainID<>'-1')
				SET @sqlQueryNew += ' AND C.ChainIdentifier = ''' + @ChainID+''''
				
		IF(CAST( @WeekEnd as DATE) <> CAST( '1900-01-01' as DATE))
			SET @sqlQueryNew += ' and convert(varchar,InvoicePeriodEnd,101) = ''' + CONVERT(varchar,+ @WeekEnd,101)+''''
			 		
		IF(@StoreNumber<>'')
				SET @sqlQueryNew += ' AND s.LegacySystemStoreIdentifier like ''%'+@StoreNumber+'%'''
		
	
		set @sqlQueryNew=@sqlQueryNew+ ' ORDER BY CheckNumber Desc, StoreID, InvType'
		
		EXEC(@sqlQueryNew)	
		print(@sqlQueryNew)	
End
GO
