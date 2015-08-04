USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_POSDetails]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC amb_POSDetails 40393
CREATE PROCEDURE [dbo].[amb_POSDetails]
    (
      @ChainID VARCHAR(20)
    )
AS 
  BEGIN

DECLARE @sqlQuery VARCHAR(8000)

SET @sqlQuery = ' SELECT top 10000 C.ChainIdentifier AS [ChainID],
					Convert(varchar(12),ID.SaleDate,101) AS [EndWeek],
					Id.TotalQty*Id.UnitCost as [TotalCost]
						
					FROM InvoiceDetails ID
					INNER JOIN Chains C ON C.ChainID =ID.ChainID AND ID.InvoiceDetailTypeID=1
					Where ID.ChainID='+@ChainID
			
EXEC(@sqlQuery);					
END
GO
