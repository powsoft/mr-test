USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_ViewCheckByInvoiceNumberWHL_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter date: <alter Date,,>
-- Description:	<Description,,>
-- =============================================
-- exec amb_ViewCheckByInvoiceNumberWHL 'CLL','24164','DQ','-1','','','09/09/2013','09/15/2013'
-- exec amb_ViewCheckByInvoiceNumberWHL 'WR1428','24503','TA','-1','','','11/06/2011','11/30/2011'

-- exec amb_ViewCheckByInvoiceNumberWHL 'NYDNW','28822','CF','-1','','','03/09/2014','03/09/2014'


CREATE PROCEDURE [dbo].[amb_ViewCheckByInvoiceNumberWHL_PRESYNC_20150329]
	@supplieridentifier as varchar(20),
	@supplierid as varchar(20),
	@ChainID varchar(10),
	@State varchar(10),
	@StoreNumber varchar(10),
	@InvoiceNo varchar(10),
	@StartDate varchar(50),
	@EndDate varchar(50)
	
AS
BEGIN

	Declare @sqlQueryNew varchar(8000)

SET @sqlQueryNew = ' SELECT DISTINCT c.ChainIdentifier as ChainID
				, s.StoreIdentifier as StoreNumber
				, a.Address1 +''  ''+ a.City+''  ''+ a.State+''  ''+ a.PostalCode as Address
				, Convert(datetime,ISup.InvoicePeriodEnd,101) as WeekEnding
				, CONVERT(varchar(10),ISup.supplierInvoiceID) AS InvoiceNo
				, ''<a href="invoice_whls_pdf.aspx?InvoiceNo=''+CONVERT(varchar(10),ISup.supplierInvoiceID)+ ''>'' + C.ChainIdentifier   +''">'' + CONVERT(varchar(10),ISup.supplierInvoiceID)+'' </a>'' as InvoiceNo1
				, ''0.00'' as Charges
				, ISNULL(ISup.OpenAmount,0)-ISNULL(dbo.GetAdjustments(ID.ChainID,id.SupplierID,ID.StoreID,''-1'',dbo.GetWeekEnd_TimeOutFix(ID.SaleDate, BC.BillingControlDay)),0) as Credits
				, 0 as Shortages 
				--, ISNULL(SF.ServiceFeeFactorValue,0) as DeliveryFee
				, isnull(dbo.[GetServiceFee](ID.ChainID,id.SupplierID,ID.StoreID,pd.CheckNo),0) as DeliveryFee
				, ISNULL(ISup.OriginalAmount,0)-ISNULL(dbo.GetAdjustments(ID.ChainID,id.SupplierID,ID.StoreID,''-1'',dbo.GetWeekEnd_TimeOutFix(ID.SaleDate, BC.BillingControlDay)),0) + isnull(dbo.[GetServiceFee](ID.ChainID,id.SupplierID,ID.StoreID,pd.CheckNo),0) as NetInvoice
				, IT.InvoiceTypeName as InvType
				, pd.CheckNo AS CheckNumber
				, Convert(datetime,pd.DisbursementDate,101) as DateIssued
				, pd.DisbursementAmount
				, ''<a href="invoice_whls_combined_pdf.aspx?InvoiceNo=''+ CONVERT(varchar(10), ISup.supplierInvoiceID)+ ''>'' + C.ChainIdentifier +''"> POS+DCR Combined </a>'' as InvoiceNo2

			FROM dbo.invoicesSupplier ISup  WITH (NOLOCK) 
				INNER JOIN dbo.InvoiceDetails ID  WITH (NOLOCK) ON ID.supplierInvoiceID=ISup.SupplierInvoiceID and RetailerInvoiceID<>0
				INNER JOIN dbo.Stores s  WITH (NOLOCK) ON s.StoreID=ID.StoreID
				INNER JOIN dbo.Addresses a  WITH (NOLOCK) ON a.OwnerEntityID=s.StoreId
				INNER JOIN dbo.invoicetypes IT  WITH (NOLOCK) on IT.InvoiceTypeID=ISup.InvoiceTypeID and  IT.InvoiceTypeID NOT IN (10,16)
				INNER JOIN dbo.Chains c  WITH (NOLOCK) ON s.ChainID = c.ChainID
				INNER JOIN (Select distinct DisbursementID, PaymentID, PaymentStatus from dbo.PaymentHistory WITH (NOLOCK)) P ON ID.PaymentID=p.PaymentID
				INNER JOIN dbo.PaymentDisbursements pd  WITH (NOLOCK) ON p.DisbursementID=pd.DisbursementID and pd.VoidStatus is null
				LEFT JOIN DataTrue_Main.dbo.BillingControl BC WITH (NOLOCK) ON BC.EntityIDToInvoice = ID.SupplierID AND BC.ChainID = C.ChainID
				--Left JOIN dbo.servicefees SF  WITH (NOLOCK) on SF.SupplierID=ISup.SupplierID
			Where 1=1 and ISup.SupplierID=' + @supplierid 
		 
				
				IF(CAST(@StartDate AS DATE) <> CAST('1900-01-01' AS DATE))
					SET @sqlQueryNew = @sqlQueryNew + ' and ISup.InvoicePeriodEnd >= ''' + convert(VARCHAR, +@StartDate, 101) + ''''
		
				IF(CAST(@EndDate AS DATE) <> CAST('1900-01-01' AS DATE))
					SET @sqlQueryNew = @sqlQueryNew + ' AND ISup.InvoicePeriodEnd <= ''' + convert(VARCHAR, +@EndDate, 101) + ''''
						
				IF(@ChainID<>'-1')
					SET @sqlQueryNew = @sqlQueryNew + '	 AND c.ChainIdentifier  = ''' + @ChainID + ''''
				
				IF(@State<>'-1')
					SET @sqlQueryNew = @sqlQueryNew + '	 AND a.State  = ''' + @State + ''''
						
				IF(@StoreNumber<>'')
					SET @sqlQueryNew = @sqlQueryNew + '	 AND s.LegacySystemStoreIdentifier like ''%' + @StoreNumber + '%'''
					
				IF(@InvoiceNo<>'')
					SET @sqlQueryNew = @sqlQueryNew + '	 AND ISup.supplierInvoiceID like ''%' + @InvoiceNo + '%'''
	PRINT @sqlQueryNew
	EXEC (@sqlQueryNew)
End
GO
