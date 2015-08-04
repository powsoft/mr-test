USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UpdateCostDifferencesTable]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_UpdateCostDifferencesTable]
AS
BEGIN
if object_id('DataTrue_CustomResultSets.dbo.tmpCostDifferences') is not null
	drop table DataTrue_CustomResultSets.dbo.tmpCostDifferences
	/** Cost Differences Data for JobRunningID 3 **/
	SELECT    dbo.Chains.ChainName, dbo.Stores.Custom1 AS Banner, dbo.Suppliers.SupplierName, dbo.Products.ProductName, 
			  cast(dbo.ProductIdentifiers.IdentifierValue as varchar) AS UPC, CAST(SUM(S.Qty) AS varchar) AS Qty, 
			  CAST(case when S.ChainID=60620 then S.SetupCost else S.RuleCost end AS decimal(10,4)) AS [Setup Cost], 
			  CAST(case when S.ChainID=60620 then S.SetupAllowance else S.PromoAllowance end AS decimal(10,4)) AS [Setup Promo], 
			  cast(case when S.ChainID=60620 then S.SetupCost else S.RuleCost end as decimal(10,4)) - cast(isnull(case when S.ChainID=60620 then S.SetupAllowance else S.PromoAllowance end, 0) as decimal(10,4)) AS [Setup Net], 
			  CAST(ISNULL( case when S.ChainID=60620 then S.RuleCost else S.ReportedCost end,0) as decimal(10,4))+ case when PCR.PartnerContextRuleTypeId=1 then 0 else cast(ISNULL(case when S.ChainID=60620 then S.PromoAllowance else S.ReportedAllowance end,0) as decimal(10,4)) end AS [Reported Cost], 
			  CAST(ISNULL(case when S.ChainID=60620 then S.PromoAllowance else S.ReportedAllowance end,0) AS decimal(10,4)) AS [Reported Promo], 
			  CAST(isnull(case when S.ChainID=60620 then S.RuleCost else S.ReportedCost end,0) AS decimal(10,4)) - case when PCR.PartnerContextRuleTypeId=1 then cast(case when S.ChainID=60620 then S.PromoAllowance else S.ReportedAllowance end as decimal(10,4)) else 0 end as RetailerNet,
			  cast( dbo.FDatetime(S.SaleDateTime) as varchar) AS SaleDate,
			  isnull(dbo.StoresUniqueValues.RouteNumber,'') as RouteNumber,
			  isnull(dbo.StoresUniqueValues.DriverName,'') as DriverName,
			  isnull(dbo.StoresUniqueValues.SupplierAccountNumber,'') as SuppAccountNo,
			  isnull(dbo.StoresUniqueValues.SBTNumber,'') as SBTNumber, dbo.suppliers.SupplierID ,chains.ChainID, dbo.Products.ProductID, 
			  isnull(dbo.CostZones.CostZoneId,'') as CostZoneName,
			  S.SupplierItemNumber as VIN, S.ProcessID,J.JobRunningID

	into  DataTrue_CustomResultSets.dbo.tmpCostDifferences

	FROM         
			  StoreTransactions  S with(nolock) INNER JOIN
			  dbo.Suppliers with(nolock)  ON S.SupplierID = dbo.Suppliers.SupplierID INNER JOIN
			  dbo.Chains with(nolock)  ON dbo.Chains.ChainID = S.ChainID INNER JOIN
			  dbo.Stores with(nolock)  ON S.StoreID = dbo.Stores.StoreID INNER JOIN
			  dbo.Products with(nolock)  ON S.ProductID = dbo.Products.ProductID INNER JOIN
			  dbo.ProductIdentifiers with(nolock)  ON dbo.Products.ProductID = dbo.ProductIdentifiers.ProductID inner join 
			  dbo.TransactionTypes with(nolock)  ON   dbo.TransactionTypes.TransactionTypeID = S.TransactionTypeID 
			  Left JOIN JobProcesses J with (nolock)  ON  J.ProcessId = S.ProcessID  and J.JobRunningID = 3 
			  left join dbo.PartnerContextRules PCR with(nolock)  on PCR.ChainId=S.ChainID and PCR.StoreId=S.StoreID
			  left join dbo.StoresUniqueValues  with(nolock) on dbo.Stores.Storeid=dbo.StoresUniqueValues.StoreID and dbo.StoresUniqueValues.SupplierID=dbo.Suppliers.SupplierID
			  Left Join dbo.CostZoneRelations  with(nolock) ON dbo.CostZoneRelations.StoreID = dbo.Stores.StoreID and dbo.CostZoneRelations.SupplierID = dbo.Suppliers.SupplierID 
			  left join dbo.CostZones  with(nolock) on dbo.CostZones.CostZoneID=dbo.CostZoneRelations.CostZoneID
		WHERE     (dbo.ProductIdentifiers.ProductIdentifierTypeID IN (2,8)) AND (dbo.TransactionTypes.BucketTypeName = 'POS') 
			AND (cast(case when S.ChainID=60620 then S.SetupCost else S.RuleCost end as decimal(10,4)) - cast(isnull(case when S.ChainID=60620 then S.SetupAllowance else isnull(S.PromoAllowance,0) end, 0) as decimal(10,4)) <>
			cast(isnull(case when S.ChainID=60620 then S.RuleCost else S.ReportedCost end,0) as decimal(10,4)) - case when PCR.PartnerContextRuleTypeId=1 then cast(ISNULL(case when S.ChainID=60620 then S.PromoAllowance else S.ReportedAllowance end,0) as decimal(10,4)) else 0 end)
			and (S.SaleDateTime > getdate()-60) 
			and (S.ReportedCost is not null )
			and ((S.RecordType in (0,3) and J.ProcessID is not null) or S.RecordType not in (0,3) or RecordType is null)
			--and s.ReportedAllowance is not null 
			--and ((s.ReportedCost is not null and isnull(s.RecordType,0)=0) OR (isnull(s.ReportedCost,0)=0 and s.RecordType=2)) 
			and ((s.ReportedAllowance is not null and isnull(s.RecordType,0)=0) OR (isnull(s.ReportedAllowance,0)=0 and s.RecordType=2)) 

	GROUP BY dbo.Chains.ChainName, dbo.Stores.Custom1, dbo.Suppliers.SupplierName, dbo.Products.ProductName, 
			  cast(dbo.ProductIdentifiers.IdentifierValue as varchar), 
			  CAST(case when S.ChainID=60620 then S.SetupCost else S.RuleCost end AS decimal(10,4)), 
			  CAST(case when S.ChainID=60620 then S.SetupAllowance else S.PromoAllowance end AS decimal(10,4)), 
			  cast(case when S.ChainID=60620 then S.SetupCost else S.RuleCost end as decimal(10,4)) - cast(isnull(case when S.ChainID=60620 then S.SetupAllowance else S.PromoAllowance end, 0) as decimal(10,4)), 
			  CAST(ISNULL( case when S.ChainID=60620 then S.RuleCost else S.ReportedCost end,0) as decimal(10,4))+ case when PCR.PartnerContextRuleTypeId=1 then 0 else cast(ISNULL(case when S.ChainID=60620 then S.PromoAllowance else S.ReportedAllowance end,0) as decimal(10,4)) end, 
			  CAST(ISNULL(case when S.ChainID=60620 then S.PromoAllowance else S.ReportedAllowance end,0) AS decimal(10,4)), 
			  CAST(isnull(case when S.ChainID=60620 then S.RuleCost else S.ReportedCost end,0) AS decimal(10,4)) - case when PCR.PartnerContextRuleTypeId=1 then cast(case when S.ChainID=60620 then S.PromoAllowance else S.ReportedAllowance end as decimal(10,4)) else 0 end,
			  cast(dbo.FDateTime( S.SaleDateTime) as varchar),
			  dbo.StoresUniqueValues.RouteNumber,dbo.StoresUniqueValues.DriverName,dbo.StoresUniqueValues.SupplierAccountNumber,dbo.StoresUniqueValues.SBTNumber, 
			  dbo.suppliers.SupplierID ,chains.ChainID , dbo.Products.ProductID, dbo.CostZones.CostZoneId, S.SupplierItemNumber , S.ProcessID,J.JobRunningID
			HAVING      (CAST(SUM(S.Qty) AS varchar) <> '0')


/** Cost Differences Data for JobRunningID 14 **/
INSERT INTO DataTrue_CustomResultSets.dbo.tmpCostDifferences

SELECT    dbo.Chains.ChainName, dbo.Stores.Custom1 AS Banner, dbo.Suppliers.SupplierName, dbo.Products.ProductName, 
			  cast(dbo.ProductIdentifiers.IdentifierValue as varchar) AS UPC, CAST(SUM(S.Qty) AS varchar) AS Qty, 
			  CAST(case when S.ChainID=60620 then S.SetupCost else S.RuleCost end AS decimal(10,4)) AS [Setup Cost], 
			  CAST(case when S.ChainID=60620 then S.SetupAllowance else S.PromoAllowance end AS decimal(10,4)) AS [Setup Promo], 
			  cast(case when S.ChainID=60620 then S.SetupCost else S.RuleCost end as decimal(10,4)) - cast(isnull(case when S.ChainID=60620 then S.SetupAllowance else S.PromoAllowance end, 0) as decimal(10,4)) AS [Setup Net], 
			  CAST(ISNULL( case when S.ChainID=60620 then S.RuleCost else S.ReportedCost end,0) as decimal(10,4))+ case when PCR.PartnerContextRuleTypeId=1 then 0 else cast(ISNULL(case when S.ChainID=60620 then S.PromoAllowance else S.ReportedAllowance end,0) as decimal(10,4)) end AS [Reported Cost], 
			  CAST(ISNULL(case when S.ChainID=60620 then S.PromoAllowance else S.ReportedAllowance end,0) AS decimal(10,4)) AS [Reported Promo], 
			  CAST(isnull(case when S.ChainID=60620 then S.RuleCost else S.ReportedCost end,0) AS decimal(10,4)) - case when PCR.PartnerContextRuleTypeId=1 then cast(case when S.ChainID=60620 then S.PromoAllowance else S.ReportedAllowance end as decimal(10,4)) else 0 end as RetailerNet,
			  cast( dbo.FDatetime(S.SaleDateTime) as varchar) AS SaleDate,
			  isnull(dbo.StoresUniqueValues.RouteNumber,'') as RouteNumber,
			  isnull(dbo.StoresUniqueValues.DriverName,'') as DriverName,
			  isnull(dbo.StoresUniqueValues.SupplierAccountNumber,'') as SuppAccountNo,
			  isnull(dbo.StoresUniqueValues.SBTNumber,'') as SBTNumber, dbo.suppliers.SupplierID ,chains.ChainID, dbo.Products.ProductID, 
			  isnull(dbo.CostZones.CostZoneId,'') as CostZoneName,
			  S.SupplierItemNumber as VIN, S.ProcessID,J.JobRunningID

	FROM         
			  StoreTransactions  S with(nolock) INNER JOIN
			  dbo.Suppliers with(nolock)  ON S.SupplierID = dbo.Suppliers.SupplierID INNER JOIN
			  dbo.Chains with(nolock)  ON dbo.Chains.ChainID = S.ChainID INNER JOIN
			  dbo.Stores with(nolock)  ON S.StoreID = dbo.Stores.StoreID INNER JOIN
			  dbo.Products with(nolock)  ON S.ProductID = dbo.Products.ProductID INNER JOIN
			  dbo.ProductIdentifiers with(nolock)  ON dbo.Products.ProductID = dbo.ProductIdentifiers.ProductID inner join 
			  dbo.TransactionTypes with(nolock)  ON   dbo.TransactionTypes.TransactionTypeID = S.TransactionTypeID 
			  left JOIN (Select Processid, JobRunningID  From JobProcesses J  Where J.JobRunningID = 14 ) J ON  J.ProcessId = S.ProcessID 
			  left join dbo.PartnerContextRules PCR with(nolock)  on PCR.ChainId=S.ChainID and PCR.StoreId=S.StoreID
			  left join dbo.StoresUniqueValues  with(nolock) on dbo.Stores.Storeid=dbo.StoresUniqueValues.StoreID and dbo.StoresUniqueValues.SupplierID=dbo.Suppliers.SupplierID
			  Left Join dbo.CostZoneRelations  with(nolock) ON dbo.CostZoneRelations.StoreID = dbo.Stores.StoreID and dbo.CostZoneRelations.SupplierID = dbo.Suppliers.SupplierID 
			  left join dbo.CostZones  with(nolock) on dbo.CostZones.CostZoneID=dbo.CostZoneRelations.CostZoneID
		WHERE     (dbo.ProductIdentifiers.ProductIdentifierTypeID IN (2,8)) AND (dbo.TransactionTypes.BucketTypeName = 'POS') 
			AND (cast(case when S.ChainID=60620 then S.SetupCost else S.RuleCost end as decimal(10,4)) - cast(isnull(case when S.ChainID=60620 then S.SetupAllowance else isnull(S.PromoAllowance,0) end, 0) as decimal(10,4)) <>
			cast(isnull(case when S.ChainID=60620 then S.RuleCost else S.ReportedCost end,0) as decimal(10,4)) - case when PCR.PartnerContextRuleTypeId=1 then cast(ISNULL(case when S.ChainID=60620 then S.PromoAllowance else S.ReportedAllowance end,0) as decimal(10,4)) else 0 end)
			and (S.SaleDateTime > getdate()-60) 
			and (S.ReportedCost is not null )
			and ((isnull(S.RecordType, 0) in (0,2)  and J.ProcessID is not null) Or (isnull(S.RecordType, 0) in (0,2)  and J.ProcessID is null))
			and ((s.ReportedAllowance is not null and isnull(s.RecordType,0)=0) OR (isnull(s.ReportedAllowance,0)=0 and s.RecordType=2)) 

	GROUP BY dbo.Chains.ChainName, dbo.Stores.Custom1, dbo.Suppliers.SupplierName, dbo.Products.ProductName, 
			  cast(dbo.ProductIdentifiers.IdentifierValue as varchar), 
			  CAST(case when S.ChainID=60620 then S.SetupCost else S.RuleCost end AS decimal(10,4)), 
			  CAST(case when S.ChainID=60620 then S.SetupAllowance else S.PromoAllowance end AS decimal(10,4)), 
			  cast(case when S.ChainID=60620 then S.SetupCost else S.RuleCost end as decimal(10,4)) - cast(isnull(case when S.ChainID=60620 then S.SetupAllowance else S.PromoAllowance end, 0) as decimal(10,4)), 
			  CAST(ISNULL( case when S.ChainID=60620 then S.RuleCost else S.ReportedCost end,0) as decimal(10,4))+ case when PCR.PartnerContextRuleTypeId=1 then 0 else cast(ISNULL(case when S.ChainID=60620 then S.PromoAllowance else S.ReportedAllowance end,0) as decimal(10,4)) end, 
			  CAST(ISNULL(case when S.ChainID=60620 then S.PromoAllowance else S.ReportedAllowance end,0) AS decimal(10,4)), 
			  CAST(isnull(case when S.ChainID=60620 then S.RuleCost else S.ReportedCost end,0) AS decimal(10,4)) - case when PCR.PartnerContextRuleTypeId=1 then cast(case when S.ChainID=60620 then S.PromoAllowance else S.ReportedAllowance end as decimal(10,4)) else 0 end,
			  cast(dbo.FDateTime( S.SaleDateTime) as varchar),
			  dbo.StoresUniqueValues.RouteNumber,dbo.StoresUniqueValues.DriverName,dbo.StoresUniqueValues.SupplierAccountNumber,dbo.StoresUniqueValues.SBTNumber, 
			  dbo.suppliers.SupplierID ,chains.ChainID , dbo.Products.ProductID, dbo.CostZones.CostZoneId, S.SupplierItemNumber , S.ProcessID,J.JobRunningID
			HAVING      (CAST(SUM(S.Qty) AS varchar) <> '0')


if object_id('DataTrue_CustomResultSets.dbo.tmpCostDifferencesByStore') is not null
	drop table DataTrue_CustomResultSets.dbo.tmpCostDifferencesByStore
	/** Cost Differences by store data for JobRunningID 3 **/
	SELECT    dbo.Chains.ChainName, dbo.Stores.Custom1 AS Banner,dbo.Stores.StoreIdentifier as [Store Number], dbo.Suppliers.SupplierName, dbo.Products.ProductName, 
			  cast(dbo.ProductIdentifiers.IdentifierValue as varchar) AS UPC, CAST(SUM(S.Qty) AS varchar) AS Qty, 
			  CAST(case when S.ChainID=60620 then S.SetupCost else S.RuleCost end AS decimal(10,4)) AS [Setup Cost], 
			  CAST(case when S.ChainID=60620 then S.SetupAllowance else S.PromoAllowance end AS decimal(10,4)) AS [Setup Promo], 
			  cast(case when S.ChainID=60620 then S.SetupCost else S.RuleCost end as decimal(10,4)) - cast(isnull(case when S.ChainID=60620 then S.SetupAllowance else S.PromoAllowance end, 0) as decimal(10,4)) AS [Setup Net], 
			  CAST(ISNULL( case when S.ChainID=60620 then S.RuleCost else S.ReportedCost end,0) as decimal(10,4))+ case when PCR.PartnerContextRuleTypeId=1 then 0 else cast(ISNULL(case when S.ChainID=60620 then S.PromoAllowance else S.ReportedAllowance end,0) as decimal(10,4)) end AS [Reported Cost], 
			  CAST(ISNULL(case when S.ChainID=60620 then S.PromoAllowance else S.ReportedAllowance end,0) AS decimal(10,4)) AS [Reported Promo], 
			  CAST(isnull(case when S.ChainID=60620 then S.RuleCost else S.ReportedCost end,0) AS decimal(10,4)) - case when PCR.PartnerContextRuleTypeId=1 then cast(case when S.ChainID=60620 then S.PromoAllowance else S.ReportedAllowance end as decimal(10,4)) else 0 end as RetailerNet,
			  cast( dbo.FDatetime(S.SaleDateTime) as varchar) AS SaleDate,
			  isnull(dbo.StoresUniqueValues.RouteNumber,'') as RouteNumber,
			  isnull(dbo.StoresUniqueValues.DriverName,'') as DriverName,
			  isnull(dbo.StoresUniqueValues.SupplierAccountNumber,'') as SuppAccountNo,
			  isnull(dbo.StoresUniqueValues.SBTNumber,'') as SBTNumber, dbo.suppliers.SupplierID ,chains.ChainID, dbo.Products.ProductID, dbo.Stores.StoreId,
			  isnull(dbo.CostZones.CostZoneId,'') as CostZoneName,
			  S.SupplierItemNumber as VIN, S.ProcessID,J.JobRunningID

	into  DataTrue_CustomResultSets.dbo.tmpCostDifferencesByStore

	FROM         
			  StoreTransactions  S with(nolock)  INNER JOIN
			  dbo.Suppliers with(nolock)  ON S.SupplierID = dbo.Suppliers.SupplierID INNER JOIN
			  dbo.Chains with(nolock)  ON dbo.Chains.ChainID = S.ChainID INNER JOIN
			  dbo.Stores with(nolock)  ON S.StoreID = dbo.Stores.StoreID INNER JOIN
			  dbo.Products with(nolock)  ON S.ProductID = dbo.Products.ProductID INNER JOIN
			  dbo.ProductIdentifiers with(nolock)  ON dbo.Products.ProductID = dbo.ProductIdentifiers.ProductID inner join 
			  dbo.TransactionTypes with(nolock)  ON   dbo.TransactionTypes.TransactionTypeID = S.TransactionTypeID
			  Left JOIN JobProcesses J with (nolock)  ON  J.ProcessId = S.ProcessID  and J.JobRunningID = 3 
			  left join dbo.PartnerContextRules PCR with(nolock)  on PCR.ChainId=S.ChainID and PCR.StoreId=S.StoreID
			  left join dbo.StoresUniqueValues with(nolock)  on dbo.Stores.Storeid=dbo.StoresUniqueValues.StoreID and dbo.StoresUniqueValues.SupplierID=dbo.Suppliers.SupplierID
			  Left Join dbo.CostZoneRelations with(nolock)  ON dbo.CostZoneRelations.StoreID = dbo.Stores.StoreID and dbo.CostZoneRelations.SupplierID = dbo.Suppliers.SupplierID 
			  left join dbo.CostZones with(nolock)  on dbo.CostZones.CostZoneID=dbo.CostZoneRelations.CostZoneID
	WHERE     (dbo.ProductIdentifiers.ProductIdentifierTypeID in (2,8)) AND (dbo.TransactionTypes.BucketTypeName = 'POS') 
			AND (cast(case when S.ChainID=60620 then S.SetupCost else S.RuleCost end as decimal(10,4)) - cast(isnull(case when S.ChainID=60620 then S.SetupAllowance else isnull(S.PromoAllowance,0) end, 0) as decimal(10,4)) <>
				cast(isnull(case when S.ChainID=60620 then S.RuleCost else S.ReportedCost end,0) as decimal(10,4)) - case when PCR.PartnerContextRuleTypeId=1 then cast(ISNULL(case when S.ChainID=60620 then S.PromoAllowance else S.ReportedAllowance end,0) as decimal(10,4)) else 0 end)
			and (S.SaleDateTime > getdate()-60)  
			and s.ReportedCost is not null 
			and ((S.RecordType in (0,3) and J.ProcessID is not null) or S.RecordType not in (0,3) or RecordType is null)
			--and s.ReportedAllowance is not null 
			--and ((s.ReportedCost is not null and isnull(s.RecordType,0)=0) OR (isnull(s.ReportedCost,0)=0 and s.RecordType=2)) 
			and ((s.ReportedAllowance is not null and isnull(s.RecordType,0)=0) OR (isnull(s.ReportedAllowance,0)=0 and s.RecordType=2)) 
		
	GROUP BY dbo.Chains.ChainName, dbo.Stores.Custom1, dbo.Suppliers.SupplierName, dbo.Stores.StoreIdentifier, dbo.Products.ProductName, 
			  cast(dbo.ProductIdentifiers.IdentifierValue as varchar), 
			  CAST(case when S.ChainID=60620 then S.SetupCost else S.RuleCost end AS decimal(10,4)), 
			  CAST(case when S.ChainID=60620 then S.SetupAllowance else S.PromoAllowance end AS decimal(10,4)), 
			  cast(case when S.ChainID=60620 then S.SetupCost else S.RuleCost end as decimal(10,4)) - cast(isnull(case when S.ChainID=60620 then S.SetupAllowance else S.PromoAllowance end, 0) as decimal(10,4)), 
			  CAST(ISNULL( case when S.ChainID=60620 then S.RuleCost else S.ReportedCost end,0) as decimal(10,4))+ case when PCR.PartnerContextRuleTypeId=1 then 0 else cast(ISNULL(case when S.ChainID=60620 then S.PromoAllowance else S.ReportedAllowance end,0) as decimal(10,4)) end, 
			  CAST(ISNULL(case when S.ChainID=60620 then S.PromoAllowance else S.ReportedAllowance end,0) AS decimal(10,4)), 
			  CAST(isnull(case when S.ChainID=60620 then S.RuleCost else S.ReportedCost end,0) AS decimal(10,4)) - case when PCR.PartnerContextRuleTypeId=1 then cast(case when S.ChainID=60620 then S.PromoAllowance else S.ReportedAllowance end as decimal(10,4)) else 0 end,
			  cast(dbo.FDateTime( S.SaleDateTime) as varchar),
			  dbo.StoresUniqueValues.RouteNumber,dbo.StoresUniqueValues.DriverName,dbo.StoresUniqueValues.SupplierAccountNumber,dbo.StoresUniqueValues.SBTNumber, 
			  dbo.suppliers.SupplierID ,chains.ChainID, dbo.Stores.StoreId , dbo.Products.ProductID, dbo.CostZones.CostZoneId, S.SupplierItemNumber, S.ProcessID,J.JobRunningID
			HAVING      (CAST(SUM(S.Qty) AS varchar) <> '0')

/** Cost Differences by store data for JobRunningID 14 **/
	INSERT INTO  DataTrue_CustomResultSets.dbo.tmpCostDifferencesByStore
	
	SELECT    dbo.Chains.ChainName, dbo.Stores.Custom1 AS Banner,dbo.Stores.StoreIdentifier as [Store Number], dbo.Suppliers.SupplierName, dbo.Products.ProductName, 
			  cast(dbo.ProductIdentifiers.IdentifierValue as varchar) AS UPC, CAST(SUM(S.Qty) AS varchar) AS Qty, 
			  CAST(case when S.ChainID=60620 then S.SetupCost else S.RuleCost end AS decimal(10,4)) AS [Setup Cost], 
			  CAST(case when S.ChainID=60620 then S.SetupAllowance else S.PromoAllowance end AS decimal(10,4)) AS [Setup Promo], 
			  cast(case when S.ChainID=60620 then S.SetupCost else S.RuleCost end as decimal(10,4)) - cast(isnull(case when S.ChainID=60620 then S.SetupAllowance else S.PromoAllowance end, 0) as decimal(10,4)) AS [Setup Net], 
			  CAST(ISNULL( case when S.ChainID=60620 then S.RuleCost else S.ReportedCost end,0) as decimal(10,4))+ case when PCR.PartnerContextRuleTypeId=1 then 0 else cast(ISNULL(case when S.ChainID=60620 then S.PromoAllowance else S.ReportedAllowance end,0) as decimal(10,4)) end AS [Reported Cost], 
			  CAST(ISNULL(case when S.ChainID=60620 then S.PromoAllowance else S.ReportedAllowance end,0) AS decimal(10,4)) AS [Reported Promo], 
			  CAST(isnull(case when S.ChainID=60620 then S.RuleCost else S.ReportedCost end,0) AS decimal(10,4)) - case when PCR.PartnerContextRuleTypeId=1 then cast(case when S.ChainID=60620 then S.PromoAllowance else S.ReportedAllowance end as decimal(10,4)) else 0 end as RetailerNet,
			  cast( dbo.FDatetime(S.SaleDateTime) as varchar) AS SaleDate,
			  isnull(dbo.StoresUniqueValues.RouteNumber,'') as RouteNumber,
			  isnull(dbo.StoresUniqueValues.DriverName,'') as DriverName,
			  isnull(dbo.StoresUniqueValues.SupplierAccountNumber,'') as SuppAccountNo,
			  isnull(dbo.StoresUniqueValues.SBTNumber,'') as SBTNumber, dbo.suppliers.SupplierID ,chains.ChainID, dbo.Products.ProductID, dbo.Stores.StoreId,
			  isnull(dbo.CostZones.CostZoneId,'') as CostZoneName,
			  S.SupplierItemNumber as VIN, S.ProcessID,J.JobRunningID

	FROM         
			  StoreTransactions  S with(nolock)  INNER JOIN
			  dbo.Suppliers with(nolock)  ON S.SupplierID = dbo.Suppliers.SupplierID INNER JOIN
			  dbo.Chains with(nolock)  ON dbo.Chains.ChainID = S.ChainID INNER JOIN
			  dbo.Stores with(nolock)  ON S.StoreID = dbo.Stores.StoreID INNER JOIN
			  dbo.Products with(nolock)  ON S.ProductID = dbo.Products.ProductID INNER JOIN
			  dbo.ProductIdentifiers with(nolock)  ON dbo.Products.ProductID = dbo.ProductIdentifiers.ProductID inner join 
			  dbo.TransactionTypes with(nolock)  ON   dbo.TransactionTypes.TransactionTypeID = S.TransactionTypeID
			  left JOIN (Select Processid, JobRunningID  From JobProcesses J  Where J.JobRunningID = 14 ) J ON  J.ProcessId = S.ProcessID  
			  left join dbo.PartnerContextRules PCR with(nolock)  on PCR.ChainId=S.ChainID and PCR.StoreId=S.StoreID
			  left join dbo.StoresUniqueValues with(nolock)  on dbo.Stores.Storeid=dbo.StoresUniqueValues.StoreID and dbo.StoresUniqueValues.SupplierID=dbo.Suppliers.SupplierID
			  Left Join dbo.CostZoneRelations with(nolock)  ON dbo.CostZoneRelations.StoreID = dbo.Stores.StoreID and dbo.CostZoneRelations.SupplierID = dbo.Suppliers.SupplierID 
			  left join dbo.CostZones with(nolock)  on dbo.CostZones.CostZoneID=dbo.CostZoneRelations.CostZoneID
	WHERE     (dbo.ProductIdentifiers.ProductIdentifierTypeID in (2,8)) AND (dbo.TransactionTypes.BucketTypeName = 'POS') 
			AND (cast(case when S.ChainID=60620 then S.SetupCost else S.RuleCost end as decimal(10,4)) - cast(isnull(case when S.ChainID=60620 then S.SetupAllowance else isnull(S.PromoAllowance,0) end, 0) as decimal(10,4)) <>
				cast(isnull(case when S.ChainID=60620 then S.RuleCost else S.ReportedCost end,0) as decimal(10,4)) - case when PCR.PartnerContextRuleTypeId=1 then cast(ISNULL(case when S.ChainID=60620 then S.PromoAllowance else S.ReportedAllowance end,0) as decimal(10,4)) else 0 end)
			and (S.SaleDateTime > getdate()-60)  
			and s.ReportedCost is not null 
			and ((isnull(S.RecordType, 0) in (0,2)  and J.ProcessID is not null) Or (isnull(S.RecordType, 0) in (0,2)  and J.ProcessID is null))
			and ((s.ReportedAllowance is not null and isnull(s.RecordType,0)=0) OR (isnull(s.ReportedAllowance,0)=0 and s.RecordType=2)) 
		
	GROUP BY dbo.Chains.ChainName, dbo.Stores.Custom1, dbo.Suppliers.SupplierName, dbo.Stores.StoreIdentifier, dbo.Products.ProductName, 
			  cast(dbo.ProductIdentifiers.IdentifierValue as varchar), 
			  CAST(case when S.ChainID=60620 then S.SetupCost else S.RuleCost end AS decimal(10,4)), 
			  CAST(case when S.ChainID=60620 then S.SetupAllowance else S.PromoAllowance end AS decimal(10,4)), 
			  cast(case when S.ChainID=60620 then S.SetupCost else S.RuleCost end as decimal(10,4)) - cast(isnull(case when S.ChainID=60620 then S.SetupAllowance else S.PromoAllowance end, 0) as decimal(10,4)), 
			  CAST(ISNULL( case when S.ChainID=60620 then S.RuleCost else S.ReportedCost end,0) as decimal(10,4))+ case when PCR.PartnerContextRuleTypeId=1 then 0 else cast(ISNULL(case when S.ChainID=60620 then S.PromoAllowance else S.ReportedAllowance end,0) as decimal(10,4)) end, 
			  CAST(ISNULL(case when S.ChainID=60620 then S.PromoAllowance else S.ReportedAllowance end,0) AS decimal(10,4)), 
			  CAST(isnull(case when S.ChainID=60620 then S.RuleCost else S.ReportedCost end,0) AS decimal(10,4)) - case when PCR.PartnerContextRuleTypeId=1 then cast(case when S.ChainID=60620 then S.PromoAllowance else S.ReportedAllowance end as decimal(10,4)) else 0 end,
			  cast(dbo.FDateTime( S.SaleDateTime) as varchar),
			  dbo.StoresUniqueValues.RouteNumber,dbo.StoresUniqueValues.DriverName,dbo.StoresUniqueValues.SupplierAccountNumber,dbo.StoresUniqueValues.SBTNumber, 
			  dbo.suppliers.SupplierID ,chains.ChainID, dbo.Stores.StoreId , dbo.Products.ProductID, dbo.CostZones.CostZoneId, S.SupplierItemNumber, S.ProcessID,J.JobRunningID
			HAVING      (CAST(SUM(S.Qty) AS varchar) <> '0')
	
	
	 				
End

CREATE NONCLUSTERED INDEX [CDIndex] ON  DataTrue_CustomResultSets.[dbo].[tmpCostDifferences] 
(
	[Banner] ASC,
	[UPC] ASC,
	[SaleDate] ASC,
	[SupplierID] ASC,
	[ChainID] ASC,
	[ProductID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
 
CREATE NONCLUSTERED INDEX [CDIndexPOS] ON  DataTrue_CustomResultSets.[dbo].tmpCostDifferencesByStore 
(
	[Banner] ASC,
	[UPC] ASC,
	[SaleDate] ASC,
	[SupplierID] ASC,
	[ChainID] ASC,
	[ProductID] ASC,
	[Storeid] asc
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
