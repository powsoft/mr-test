USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInventorySettlement_NewProducts_Intialize]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prInventorySettlement_NewProducts_Intialize]
as

update h set h.OriginalAmount = d.IDSum, h.OpenAmount = d.IDSum
 from InvoicesRetailer h
 inner join
 (
 select retailerinvoiceid, SUM(totalcost) as IDsum
 from datatrue_main.dbo.Invoicedetails
 where 1 = 1
 --and InvoiceDetailTypeID = 11
 --and saledate > '11/30/2011'
 group by RetailerInvoiceID
 ) d
 on h.RetailerInvoiceID = d.RetailerInvoiceID
 and d.IDSum <> h.OriginalAmount


update h set h.OriginalAmount = d.IDSum, h.OpenAmount = d.IDSum
 from datatrue_edi.dbo.InvoicesRetailer h
 inner join
 (
 select retailerinvoiceid, SUM(totalcost) as IDsum
 from datatrue_main.dbo.Invoicedetails
 where 1 = 1
 --and InvoiceDetailTypeID = 11
 --and saledate > '11/30/2011'
 group by RetailerInvoiceID
 ) d
 on h.RetailerInvoiceID = d.RetailerInvoiceID
 and d.IDSum <> h.OriginalAmount


delete from InventoryReport_New_FactTable_Active where supplierid in (40558)


SELECT     StoreID, Settle, MAX(PhysicalInventoryDate) AS LastSettlementDate, supplierId, UPC
Into #tmpLSD
FROM         dbo.InventorySettlementRequests
where supplierId in (40558) and SettlementFinalized = 1
GROUP BY StoreID, Settle, supplierId, UPC
HAVING      (Settle = 'y')

SELECT     LSD.supplierId, LSD.StoreID, LSD.LastSettlementDate, 
                      ISNULL(IC.qty, 0) AS LS_TTLQnt, 
                      ISNULL(IC.Qty*(ic.rulecost-isnull(ic.PromoAllowance,0)), 0) AS LS_TTLCost, 
                      LSD.UPC
into #tmpLS_FactTable
FROM         #tmpLSD LSD 
				LEFT OUTER JOIN
                      dbo.StoreTransactions IC ON 
						  LSD.StoreID = IC.StoreID AND 
						  LSD.supplierId = IC.SupplierID AND 
						  LSD.LastSettlementDate = IC.SaleDateTime  AND 
						  LSD.UPC = IC.UPC and ic.TransactionTypeID in(10,11)
WHERE     (LSD.LastSettlementDate >= CONVERT(DATETIME, '2011-11-30 00:00:00', 102))
and ic.SupplierID in (40558)

insert Into InventoryReport_New_FactTable_Active
	SELECT     SP.SupplierName, dbo.Chains.ChainName, ST.StoreIdentifier AS StoreNo, NULL AS SupplierAcctNo, 
						  ST.Custom1 AS Banner, CONVERT(varchar, s.SaleDateTime, 101) AS LastInventoryCountDate, CONVERT(varchar, 
						  LSFT.LastSettlementDate , 101) AS LastSettlementDate, s.UPC, 
						  LSFT.LS_TTLQnt  AS [BI Count], LSFT.LS_TTLCost AS BI$, NULL 
						  AS [Net Deliveries], NULL AS [Net Deliveries$], NULL AS [Net POS], NULL AS POS$, NULL AS [Expected EI], NULL AS [Expected EI$], SUM(s.Qty) AS LastCountQty, 
						  SUM(s.Qty * (ISNULL(s.RuleCost,0) - ISNULL(s.PromoAllowance, 0))) AS LastCount$, NULL AS ShrinkUnits, NULL AS Shrink$, 
						  s.SupplierID, dbo.Chains.ChainID, s.StoreID, s.ProductID, NULL AS SupplierUniqueProductID, 
						  NULL AS LastCountCost, NULL AS LastCountBaseCost, null AS WeightedAvgCost, Null AS SharedShrinkUnits, 0 as Settle

	FROM         dbo.StoreTransactions AS s INNER JOIN
						  dbo.Stores ST ON s.StoreID = ST.StoreID INNER JOIN
						  dbo.Chains ON s.ChainID = dbo.Chains.ChainID INNER JOIN
						  dbo.Suppliers  SP ON s.SupplierID = SP.SupplierID LEFT OUTER JOIN
						  #tmpLS_FactTable  LSFT ON s.SupplierID = LSFT.SupplierID AND 
						  s.StoreID = LSFT.StoreID AND s.UPC = LSFT.UPC 
	WHERE     (s.TransactionTypeID IN (11, 10)) AND (s.SaleDateTime >= ISNULL(LSFT.LastSettlementDate,CONVERT(DATETIME, '2000-01-01 00:00:00', 102)))
	and s.SupplierID in (40558)
	GROUP BY s.SupplierID, s.StoreID, s.UPC, CONVERT(varchar, s.SaleDateTime, 101), CONVERT(varchar, 
						  LSFT.LastSettlementDate , 101), LSFT.LS_TTLCost, 
						  LSFT.LS_TTLQnt , s.ProductID, SP.SupplierName, dbo.Chains.ChainID, dbo.Chains.ChainName, 
						  ST.StoreIdentifier, ST.Custom1
	ORDER BY s.SupplierID, s.StoreID, LastInventoryCountDate DESC
	
return
GO
