USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_DcrAdjBreakdown]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC amb_DcrAdjBreakdown 40393
CREATE PROCEDURE [dbo].[amb_DcrAdjBreakdown]
    (
      @ChainID VARCHAR(20)
    )
AS 
  BEGIN

DECLARE @sqlQuery VARCHAR(8000)

SET @sqlQuery = ' SELECT C.ChainIdentifier AS [ChainID],
                     Convert(varchar(12),ID.SaleDate,101) AS [EndWeek],
					 SUM(isnull(ID.TotalQty,0)*ID.UnitCost) AS [TotalDCRADJ]
			         
			
				  FROM InvoiceDetails ID
                       INNER JOIN Chains C ON C.ChainID=ID.ChainID and ID.InvoiceDetailTypeID=5 
                        
				  GROUP BY C.ChainIdentifier,ID.SaleDate,ID.ChainID
				  HAVING ID.ChainID='+@ChainID
			
EXEC(@sqlQuery);		
			
  END
GO
