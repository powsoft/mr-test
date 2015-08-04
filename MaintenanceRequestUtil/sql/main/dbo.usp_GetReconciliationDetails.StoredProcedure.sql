USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetReconciliationDetails]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC [usp_GetReconciliationDetails] '40393','','','1900-01-01','1900-01-01'

CREATE Procedure [dbo].[usp_GetReconciliationDetails]
 @ChainId varchar(20),
 @RetailerInvoiceNo varchar(20),
 @RetailerCheckNo varchar(20),
 @ReceivedDateStart varchar(20),
 @ReceivedDateEnd varchar(20)
as

Begin
	Declare @sqlQuery varchar(5000)
	SET @sqlQuery = '
										Select Distinct 
											C.ChainIdentifier as ChainIdentifier, 
											C.ChainName, 
											I.RetailerInvoiceId as [Retailer Invoice No], 
											Sum(TotalCost) as [Invoice Amount],
											Sum(I.Adjustment1) as [iControl Fee],
											convert(varchar(20),PH.DatePaymentReceived,101) as [Received Date from Retailer],
											PH.CheckNoReceived as [Retailer Check Number],
											PH.AmountPaid as [Payment From Retailer]
										from Chains C with (nolock)
										inner join InvoiceDetails I with (nolock) on I.ChainId=C.ChainID
										inner join Payments P with (nolock) on P.PaymentID=I.PaymentID
										inner join PaymentHistory PH with (nolock) on PH.PaymentID=I.PaymentID and PH.PaymentStatus=P.PaymentStatus
										WHERE 1=1 '
										
	If(@ChainId<>'-1')
		SET @sqlQuery = @sqlQuery + ' and I.ChainID= ' + @ChainId 
	
	If(@RetailerInvoiceNo<>'')
		SET @sqlQuery = @sqlQuery + ' and I.RetailerInvoiceId = ' + @RetailerInvoiceNo 
		
	If(@RetailerCheckNo<>'')
		SET @sqlQuery = @sqlQuery + ' and PH.CheckNoReceived = ''' + @RetailerCheckNo  + ''''
											
	If(convert(date, @ReceivedDateStart ) > convert(date,'1900-01-01'))
		SET @sqlQuery = @sqlQuery + ' and PH.DatePaymentReceived >= ''' + @ReceivedDateStart + ''''
		
	If(convert(date, @ReceivedDateEnd ) > convert(date,'1900-01-01'))
		SET @sqlQuery = @sqlQuery + ' and PH.DatePaymentReceived <= ''' + @ReceivedDateEnd + ''''
		
	SET @sqlQuery = @sqlQuery + ' GROUP BY C.ChainIdentifier, C.ChainName, I.RetailerInvoiceId, PH.DatePaymentReceived, PH.CheckNoReceived, PH.AmountPaid'
	
	print(@sqlQuery)
	exec(@sqlQuery)

End
GO
