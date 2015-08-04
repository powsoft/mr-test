USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_PaymentsReceivedAndDisbursed]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC [usp_PaymentsReceivedAndDisbursed] '-1','-1','11/12/2014','1900-01-01'

--EXEC [usp_PaymentsReceivedAndDisbursed] '-1','-1','1900/01/01','1900/01/01'


CREATE procedure [dbo].[usp_PaymentsReceivedAndDisbursed]
(
	@ChainID varchar(10),
	@SupplierID varchar(10),
	@WeekFromDate varchar(50),
	@WeekToDate varchar(50)	
)

AS 
BEGIN

Declare @sqlQuery varchar(4000)

			SET @sqlQuery='Select Distinct C.ChainIdentifier as [Retailer Id], C.ChainName as [Retailer Name], 
						   S.SupplierIdentifier as [Supplier Id], S.SupplierName as [Supplier Name],
						   CONVERT(VARCHAR(10), SP.InvoicePeriodEnd,101) as [Week End Date],
						   max([Retailer Paid Date]) as [Retailer Paid Date], max([Disbursement Date]) as [Disbursement Date]
						From InvoiceDetails I
						Inner Join InvoicesSupplier SP on SP.SupplierInvoiceId=I.SupplierInvoiceId
						Inner Join Chains C on C.ChainID=I.ChainId
						Inner Join Suppliers S on S.SupplierId=I.SupplierId
						LEFT Join ( 
									Select distinct P.PaymentID, CONVERT(VARCHAR(10), isnull(P.DateTimePaid, P.DateTimeCreated), 101) as [Retailer Paid Date],  
									CONVERT(VARCHAR(10), D.DisbursementDate, 101)  as [Disbursement Date]
									from Payments P 
									inner join PaymentHistory H on H.PaymentId=P.PaymentId and H.PaymentStatus=P.PaymentStatus
									Left join  PaymentDisbursements D on D.DisbursementId=H.DisbursementId
								) P on P.PaymentId=I.PaymentId 
						Where 1=1 ' 

			IF(@ChainId<>'-1')
				SET @sqlQuery += ' AND C.ChainID = ''' + @ChainId+''' '	
				
			IF(@SupplierID<>'-1')
				SET @sqlQuery += ' AND S.SupplierID = ''' + @SupplierID+''' '		
				
			IF(CAST(@WeekFromDate AS DATE) <> CAST('1900-01-01' AS DATE))
				SET @sqlQuery += ' AND SP.InvoicePeriodEnd >= ''' +Convert(Varchar, +@WeekFromDate, 101)+''' '	
				
			IF(CAST(@WeekToDate AS DATE) <> CAST('1900-01-01' AS DATE))
				SET @sqlQuery += ' AND SP.InvoicePeriodEnd <= ''' +Convert(Varchar, +@WeekToDate, 101)+''' '																
			
			SET @sqlQuery += ' group by C.ChainIdentifier, C.ChainName, S.SupplierIdentifier, S.SupplierName, CONVERT(VARCHAR(10), SP.InvoicePeriodEnd,101)'
			
			SET @sqlQuery += ' order by 1, 3, 5'
			
			print(@sqlQuery)
		
			EXEC(@sqlQuery)
			
END
GO
