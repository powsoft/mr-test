USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_PendingPaymentDetails]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC amb_PendingPaymentDetails 40393
CREATE PROCEDURE [dbo].[amb_PendingPaymentDetails]
    (
      @ChainID VARCHAR(20)
    )
AS 
  BEGIN

DECLARE @sqlQuery VARCHAR(8000)

SET @sqlQuery = ' SELECT  Convert(varchar(12),ID.SaleDate,101) AS [WeekEnding],
                     S.SupplierIdentifier AS [WholesalerID],
                     S.SupplierName AS [WholesalerName],
			         sum(AmountOriginallyBilled)-sum(ID.totalcost) AS [SumOfNetInvoice]
			
				  FROM InvoiceDetails ID
				       Inner JOIN Payments P on P.PaymentID=ID.PaymentID
					   INNER JOIN Suppliers S ON S.SupplierID=ID.SupplierID AND S.SupplierID=P.PayeeEntityID
					   

				  GROUP BY S.SupplierName,ID.TotalCost,ID.ChainID,ID.SaleDate,S.SupplierIdentifier
				  HAVING ID.ChainID='+@ChainID
			
EXEC(@sqlQuery);		
			
  END
GO
