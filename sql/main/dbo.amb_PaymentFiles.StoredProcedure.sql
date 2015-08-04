USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_PaymentFiles]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC amb_PaymentFiles 40393
CREATE PROCEDURE [dbo].[amb_PaymentFiles]
    (
      @ChainID VARCHAR(20)
    )
AS 
  BEGIN

DECLARE @sqlQuery VARCHAR(8000)

SET @sqlQuery = ' SELECT Convert(varchar(12),ID.SaleDate,101) AS [WeekEnding],
					 SUM(P.AmountOriginallyBilled) AS [SumOfNetInvoice],
					 C.ChainIdentifier AS [ChainID],
					 '''' [By File],
                     '''' [Difference]
			         
			
				  FROM InvoiceDetails ID
					   Inner JOIN Payments P on P.PaymentID=ID.PaymentID
                       INNER JOIN Chains C ON C.ChainID=ID.ChainID 
                       
				  GROUP BY ID.SaleDate,C.ChainIdentifier,ID.ChainID
				  HAVING ID.ChainID='+@ChainID
			
EXEC(@sqlQuery);		
			
  END
GO
