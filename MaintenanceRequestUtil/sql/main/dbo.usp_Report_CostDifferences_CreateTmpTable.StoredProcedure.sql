USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_CostDifferences_CreateTmpTable]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE procedure [dbo].[usp_Report_CostDifferences_CreateTmpTable] 
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
Declare @Query varchar(5000)
Declare @Query2 varchar(5000)	
	
	set @Query ='select * 
	
	into tmpSeanChains
	
	from
	
	(SELECT     dbo.Chains.ChainName, dbo.Stores.Custom1 AS Banner, dbo.Suppliers.SupplierName, dbo.Products.ProductName, 
                      cast(dbo.ProductIdentifiers.IdentifierValue as varchar) AS UPC, CAST(SUM(S.Qty) AS varchar) AS Qty, CAST(S.SetupCost AS varchar) 
                      AS [Setup Cost], CAST(S.PromoAllowance AS varchar) AS [Setup Promo], 
                      CAST(S.SetupCost - S.PromoAllowance AS varchar) AS [Setup Net], CAST((S.ReportedCost+S.ReportedAllowance) AS varchar) 
                      AS [Reported Cost], CAST(S.ReportedAllowance AS varchar) AS [Reported Promo], 
                      CAST(S.ReportedCost AS varchar) as RetailerNet,
                      cast( dbo.FDatetime(S.SaleDateTime) as varchar) AS SaleDate
FROM         dbo.TransactionTypes INNER JOIN
                      datatrue_report.dbo.StoreTransactions S INNER JOIN
                      dbo.Suppliers ON S.SupplierID = dbo.Suppliers.SupplierID INNER JOIN
                      dbo.Chains ON dbo.Chains.ChainID = S.ChainID INNER JOIN
                      dbo.Stores ON S.StoreID = dbo.Stores.StoreID and dbo.Stores.ActiveStatus=''Active'' INNER JOIN
                      dbo.Products ON S.ProductID = dbo.Products.ProductID INNER JOIN
                      dbo.ProductIdentifiers ON dbo.Products.ProductID = dbo.ProductIdentifiers.ProductID ON 
                      dbo.TransactionTypes.TransactionTypeID = S.TransactionTypeID 
  
WHERE     (dbo.ProductIdentifiers.ProductIdentifierTypeID = 2) AND (dbo.TransactionTypes.BucketTypeName = ''POS'') AND 
                      (S.SetupCost - S.PromoAllowance <> S.ReportedCost) '

                      
	set @Query2 ='select * 
	
	into tmpSeanSuppliers
	
	from
	

	(SELECT     dbo.Chains.ChainName, dbo.Stores.Custom1 AS Banner, dbo.Suppliers.SupplierName, dbo.Products.ProductName, 
                      cast(dbo.ProductIdentifiers.IdentifierValue as varchar) as UPC, CAST(SUM(S.Qty) AS varchar) AS Qty, CAST(S.SetupCost AS varchar) 
                      AS [Setup Cost], cast(S.PromoAllowance as varchar) AS [Setup Promo], 
                      CAST(S.SetupCost - S.PromoAllowance AS varchar) AS [Setup Net], CAST((S.ReportedCost+S.ReportedAllowance) AS varchar) 
                      AS [Reported Cost], CAST(S.ReportedAllowance AS varchar) AS [Reported Promo], 
                      CAST(S.ReportedCost AS varchar) as RetailerNet,
                      cast(dbo.FDatetime( S.SaleDateTime ) as varchar) AS SaleDate
FROM         dbo.TransactionTypes INNER JOIN
                      datatrue_report.dbo.StoreTransactions INNER JOIN
                      dbo.Suppliers ON S.SupplierID = dbo.Suppliers.SupplierID INNER JOIN
                      dbo.Chains ON dbo.Chains.ChainID = S.ChainID INNER JOIN
                      dbo.Stores ON S.StoreID = dbo.Stores.StoreID INNER JOIN
                      dbo.Products ON S.ProductID = dbo.Products.ProductID INNER JOIN
                      dbo.ProductIdentifiers ON dbo.Products.ProductID = dbo.ProductIdentifiers.ProductID ON 
                      dbo.TransactionTypes.TransactionTypeID = S.TransactionTypeID 
                      
WHERE     (dbo.ProductIdentifiers.ProductIdentifierTypeID = 2) AND (dbo.TransactionTypes.BucketTypeName = ''POS'') AND 
                      (S.SetupCost - S.PromoAllowance <> S.ReportedCost) '
                  
 set @query = @query + ' GROUP BY dbo.Chains.ChainName, dbo.Stores.Custom1, dbo.Suppliers.SupplierName, dbo.Products.ProductName, 
                      cast(dbo.ProductIdentifiers.IdentifierValue as varchar), CAST(S.SetupCost AS varchar), CAST(S.PromoAllowance AS varchar), 
                      CAST(S.SetupCost - S.PromoAllowance AS varchar), 
                      CAST((S.ReportedCost+S.ReportedAllowance) AS varchar), 
                      CAST(S.ReportedAllowance AS varchar), 
                      CAST(S.ReportedCost AS varchar),
                      cast(dbo.FDateTime( S.SaleDateTime) as varchar)
					HAVING      (CAST(SUM(S.Qty) AS varchar) <> ''0'')  )';

set @query2 = @Query2 + ' GROUP BY dbo.Chains.ChainName, dbo.Stores.Custom1, dbo.Suppliers.SupplierName, dbo.Products.ProductName, 
                      cast(dbo.ProductIdentifiers.IdentifierValue as varchar), CAST(S.SetupCost AS varchar), CAST(S.PromoAllowance AS varchar), 
                      CAST(S.SetupCost - S.PromoAllowance AS varchar), 
                      CAST((S.ReportedCost+S.ReportedAllowance) AS varchar), 
                      CAST(S.ReportedAllowance AS varchar), 
                      CAST(S.ReportedCost AS varchar),
                      cast(dbo.FDateTime( S.SaleDateTime) as varchar)
					HAVING      (CAST(SUM(S.Qty) AS varchar) <> ''0'')  )';



exec  (@Query )
exec  (@Query2 )
END
GO
