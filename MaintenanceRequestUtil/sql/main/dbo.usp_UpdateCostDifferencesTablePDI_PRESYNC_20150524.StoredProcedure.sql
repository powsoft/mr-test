USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UpdateCostDifferencesTablePDI_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_UpdateCostDifferencesTablePDI_PRESYNC_20150524]
AS
BEGIN
	drop table DataTrue_CustomResultSets.dbo.tmpCostDifferencesPDI
	SELECT    dbo.Chains.ChainName, dbo.Stores.Custom1 AS Banner, dbo.Suppliers.SupplierName, dbo.Products.ProductName, 
			  cast(dbo.ProductIdentifiers.IdentifierValue as varchar) AS UPC, CAST(SUM(S.Qty) AS varchar) AS Qty, 
			  CAST(S.SetupCost AS decimal(10,4)) AS [Setup Cost], 
			  CAST(S.PromoAllowance AS decimal(10,4)) AS [Setup Promo], 
			  cast(S.SetupCost as decimal(10,4)) - cast(isnull(S.PromoAllowance, 0) as decimal(10,4)) AS [Setup Net], 
			  CAST(S.ReportedCost as decimal(10,4))+ case when PCR.PartnerContextRuleTypeId=1 then 0 else cast(S.ReportedAllowance as decimal(10,4)) end AS [Reported Cost], 
			  CAST(S.ReportedAllowance AS decimal(10,4)) AS [Reported Promo], 
			  CAST(S.ReportedCost AS decimal(10,4)) - case when PCR.PartnerContextRuleTypeId=1 then cast(S.ReportedAllowance as decimal(10,4)) else 0 end as RetailerNet,
			  cast( dbo.FDatetime(S.SaleDateTime) as varchar) AS SaleDate,
			  isnull(dbo.StoresUniqueValues.RouteNumber,'') as RouteNumber,
			  isnull(dbo.StoresUniqueValues.DriverName,'') as DriverName,
			  isnull(dbo.StoresUniqueValues.SupplierAccountNumber,'') as SuppAccountNo,
			  isnull(dbo.StoresUniqueValues.SBTNumber,'') as SBTNumber, dbo.suppliers.SupplierID ,chains.ChainID, dbo.Products.ProductID, 
			  isnull(dbo.CostZones.CostZoneId,'') as CostZoneName

	into  DataTrue_CustomResultSets.dbo.tmpCostDifferencesPDI

	FROM         
			  Datatrue_Report.dbo.StoreTransactions  S INNER JOIN
			  dbo.Suppliers ON S.SupplierID = dbo.Suppliers.SupplierID INNER JOIN
			  dbo.Chains ON dbo.Chains.ChainID = S.ChainID INNER JOIN
			  dbo.Stores ON S.StoreID = dbo.Stores.StoreID INNER JOIN
			  dbo.Products ON S.ProductID = dbo.Products.ProductID INNER JOIN
			  dbo.ProductIdentifiers ON dbo.Products.ProductID = dbo.ProductIdentifiers.ProductID inner join 
			  dbo.TransactionTypes ON   dbo.TransactionTypes.TransactionTypeID = S.TransactionTypeID  
			  left join dbo.PartnerContextRules PCR on PCR.ChainId=S.ChainID and PCR.StoreId=S.StoreID
			  left join dbo.StoresUniqueValues on dbo.Stores.Storeid=dbo.StoresUniqueValues.StoreID and dbo.StoresUniqueValues.SupplierID=dbo.Suppliers.SupplierID
			  Left Join dbo.CostZoneRelations ON dbo.CostZoneRelations.StoreID = dbo.Stores.StoreID and dbo.CostZoneRelations.SupplierID = dbo.Suppliers.SupplierID 
			  left join dbo.CostZones on dbo.CostZones.CostZoneID=dbo.CostZoneRelations.CostZoneID
			  
	WHERE     (dbo.ProductIdentifiers.ProductIdentifierTypeID = 2) AND (dbo.TransactionTypes.BucketType = 2) 
	
			AND (cast(S.SetupCost as decimal(10,4)) - cast(isnull(S.PromoAllowance, 0) as decimal(10,4)) <>
  				cast(S.ReportedCost as decimal(10,4)) - case when PCR.PartnerContextRuleTypeId=1 then cast(S.ReportedAllowance as decimal(10,4)) else 0 end)
			and (S.SaleDateTime > getdate()-60) 
		
	GROUP BY dbo.Chains.ChainName, dbo.Stores.Custom1, dbo.Suppliers.SupplierName, dbo.Products.ProductName, 
			  cast(dbo.ProductIdentifiers.IdentifierValue as varchar), 
			  CAST(S.SetupCost AS decimal(10,4)), 
			  CAST(S.PromoAllowance AS decimal(10,4)), 
			  CAST(S.SetupCost as decimal(10,4)) - cast(isnull(S.PromoAllowance,0) AS decimal(10,4)),
  			  CAST(S.ReportedCost as decimal(10,4))+ case when PCR.PartnerContextRuleTypeId=1 then 0 else cast(S.ReportedAllowance as decimal(10,4)) end,
			  CAST(S.ReportedAllowance AS decimal(10,4)), 
			  CAST(S.ReportedCost AS decimal(10,4)) - case when PCR.PartnerContextRuleTypeId=1 then cast(S.ReportedAllowance as decimal(10,4)) else 0 end,
			  cast(dbo.FDateTime( S.SaleDateTime) as varchar),
			  dbo.StoresUniqueValues.RouteNumber,dbo.StoresUniqueValues.DriverName,dbo.StoresUniqueValues.SupplierAccountNumber,dbo.StoresUniqueValues.SBTNumber, 
			  dbo.suppliers.SupplierID ,chains.ChainID , dbo.Products.ProductID, dbo.CostZones.CostZoneId
			HAVING      (CAST(SUM(S.Qty) AS varchar) <> '0')

	drop table DataTrue_CustomResultSets.dbo.tmpCostDifferencesPDIByStore
	
	SELECT    dbo.Chains.ChainName, dbo.Stores.Custom1 AS Banner,dbo.Stores.StoreIdentifier as [Store Number], dbo.Suppliers.SupplierName, dbo.Products.ProductName, 
			  cast(dbo.ProductIdentifiers.IdentifierValue as varchar) AS UPC, CAST(SUM(S.Qty) AS varchar) AS Qty, 
			  CAST(S.SetupCost AS decimal(10,4)) AS [Setup Cost], 
			  CAST(S.PromoAllowance AS decimal(10,4)) AS [Setup Promo], 
			  cast(S.SetupCost as decimal(10,4)) - cast(isnull(S.PromoAllowance, 0) as decimal(10,4)) AS [Setup Net], 
			  CAST(S.ReportedCost as decimal(10,4))+ case when PCR.PartnerContextRuleTypeId=1 then 0 else cast(S.ReportedAllowance as decimal(10,4)) end AS [Reported Cost], 
			  CAST(S.ReportedAllowance AS decimal(10,4)) AS [Reported Promo], 
			  CAST(S.ReportedCost AS decimal(10,4)) - case when PCR.PartnerContextRuleTypeId=1 then cast(S.ReportedAllowance as decimal(10,4)) else 0 end as RetailerNet,
			  cast( dbo.FDatetime(S.SaleDateTime) as varchar) AS SaleDate,
			  isnull(dbo.StoresUniqueValues.RouteNumber,'') as RouteNumber,
			  isnull(dbo.StoresUniqueValues.DriverName,'') as DriverName,
			  isnull(dbo.StoresUniqueValues.SupplierAccountNumber,'') as SuppAccountNo,
			  isnull(dbo.StoresUniqueValues.SBTNumber,'') as SBTNumber, dbo.suppliers.SupplierID ,chains.ChainID, dbo.Products.ProductID, dbo.Stores.StoreId,
			  isnull(dbo.CostZones.CostZoneId,'') as CostZoneName

	into DataTrue_CustomResultSets.dbo.tmpCostDifferencesPDIByStore

	FROM         
			  Datatrue_Report.dbo.StoreTransactions  S INNER JOIN
			  dbo.Suppliers ON S.SupplierID = dbo.Suppliers.SupplierID INNER JOIN
			  dbo.Chains ON dbo.Chains.ChainID = S.ChainID INNER JOIN
			  dbo.Stores ON S.StoreID = dbo.Stores.StoreID INNER JOIN
			  dbo.Products ON S.ProductID = dbo.Products.ProductID INNER JOIN
			  dbo.ProductIdentifiers ON dbo.Products.ProductID = dbo.ProductIdentifiers.ProductID inner join 
			  dbo.TransactionTypes ON   dbo.TransactionTypes.TransactionTypeID = S.TransactionTypeID  
			  left join dbo.PartnerContextRules PCR on PCR.ChainId=S.ChainID and PCR.StoreId=S.StoreID
			  left join dbo.StoresUniqueValues on dbo.Stores.Storeid=dbo.StoresUniqueValues.StoreID and dbo.StoresUniqueValues.SupplierID=dbo.Suppliers.SupplierID
			  Left Join dbo.CostZoneRelations ON dbo.CostZoneRelations.StoreID = dbo.Stores.StoreID and dbo.CostZoneRelations.SupplierID = dbo.Suppliers.SupplierID 
			  left join dbo.CostZones on dbo.CostZones.CostZoneID=dbo.CostZoneRelations.CostZoneID
	WHERE     (dbo.ProductIdentifiers.ProductIdentifierTypeID = 2) AND (dbo.TransactionTypes.BucketType = 2) 
			AND (cast(S.SetupCost as decimal(10,4)) - cast(isnull(S.PromoAllowance, 0) as decimal(10,4)) <>
				cast(S.ReportedCost as decimal(10,4)) - case when PCR.PartnerContextRuleTypeId=1 then cast(S.ReportedAllowance as decimal(10,4)) else 0 end)
			and (S.SaleDateTime > getdate()-60) 
		
	GROUP BY dbo.Chains.ChainName, dbo.Stores.Custom1, dbo.Suppliers.SupplierName, dbo.Stores.StoreIdentifier, dbo.Products.ProductName, 
			  cast(dbo.ProductIdentifiers.IdentifierValue as varchar), 
			  CAST(S.SetupCost AS decimal(10,4)), 
			  CAST(S.PromoAllowance AS decimal(10,4)), 
			  CAST(S.SetupCost as decimal(10,4)) - cast(isnull(S.PromoAllowance,0) AS decimal(10,4)), 
			  CAST(S.ReportedCost as decimal(10,4))+ case when PCR.PartnerContextRuleTypeId=1 then 0 else cast(S.ReportedAllowance as decimal(10,4)) end,
			  CAST(S.ReportedAllowance AS decimal(10,4)), 
			  CAST(S.ReportedCost AS decimal(10,4)) - case when PCR.PartnerContextRuleTypeId=1 then cast(S.ReportedAllowance as decimal(10,4)) else 0 end,
			  cast(dbo.FDateTime( S.SaleDateTime) as varchar),
			  dbo.StoresUniqueValues.RouteNumber,dbo.StoresUniqueValues.DriverName,dbo.StoresUniqueValues.SupplierAccountNumber,dbo.StoresUniqueValues.SBTNumber, 
			  dbo.suppliers.SupplierID ,chains.ChainID, dbo.Stores.StoreId , dbo.Products.ProductID, dbo.CostZones.CostZoneId
			HAVING      (CAST(SUM(S.Qty) AS varchar) <> '0')
					
End
GO
