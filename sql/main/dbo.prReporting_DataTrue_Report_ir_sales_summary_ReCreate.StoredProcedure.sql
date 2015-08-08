USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prReporting_DataTrue_Report_ir_sales_summary_ReCreate]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prReporting_DataTrue_Report_ir_sales_summary_ReCreate]
as

truncate table DataTrue_Report.dbo.ir_sales_summary_table
--select * from DataTrue_Report.dbo.ir_sales_summary_table
insert into DataTrue_Report.dbo.ir_sales_summary_table
SELECT     CategoryID, SupplierID, StoreID, BrandID, ProductID, UPC, ChainID, saledate, SUM(sales_units_ret_cy) AS sales_units_ret_cy, SUM(sales_units_cy) 
                      AS sales_units_cy, SUM(sales_cost_cy) AS sales_cost_cy, SUM(sales_units_ret_ly) AS sales_units_ret_ly, SUM(sales_units_ly) AS sales_units_ly, 
                      SUM(sales_cost_ly) AS sales_cost_ly
FROM         (SELECT     pca.ProductCategoryID AS CategoryID, st.SupplierID, st.StoreID, st.BrandID, st.ProductID, st.UPC, S.ChainID, st.Qty * st.RuleRetail AS sales_units_ret_cy, 
                                              st.Qty AS sales_units_cy, st.Qty * st.RuleCost AS sales_cost_cy, 0 AS sales_units_ret_ly, 0 AS sales_units_ly, 0 AS sales_cost_ly, 
                                              st.SaleDateTime AS saledate
                       FROM          dbo.TransactionTypes AS tt INNER JOIN
                                              dbo.StoreTransactions AS st ON tt.TransactionTypeID = st.TransactionTypeID INNER JOIN
                                              dbo.Stores AS S ON st.StoreID = S.StoreID LEFT OUTER JOIN
                                              dbo.ProductCategoryAssignments AS pca ON st.ProductID = pca.ProductID
                       WHERE      (tt.TransactionSourceID = 1)
) AS dud                       
GROUP BY CategoryID, SupplierID, StoreID, BrandID, ProductID, UPC, ChainID, saledate

update ss
set ss.sales_units_ret_ly = z.sales_units_ret_ly
,ss.sales_units_ly = z.sales_units_ly
,ss.sales_cost_ly = z.sales_cost_ly
--select *
from datatrue_report.dbo.ir_sales_summary_table ss
inner join
(SELECT     pca.ProductCategoryID AS CategoryID, st.SupplierID as SupID, st.StoreID as StrID, 
			st.BrandID as BrdID, st.ProductID as PrdID, st.UPC as UPC, S.ChainID as ChnID, 
			sum(st.Qty * st.RuleRetail) AS sales_units_ret_ly, sum(st.Qty) AS sales_units_ly, 
			sum(st.Qty * st.RuleCost) AS sales_cost_ly, 
                     st.SaleDateTime + 365 AS saledate
FROM         dbo.TransactionTypes AS tt INNER JOIN
                     dbo.StoreTransactions AS st ON tt.TransactionTypeID = st.TransactionTypeID INNER JOIN
                     dbo.Stores AS S ON st.StoreID = S.StoreID LEFT OUTER JOIN
                     dbo.ProductCategoryAssignments AS pca ON st.ProductID = pca.ProductID
     
WHERE     (tt.TransactionSourceID = 1)
GROUP BY pca.ProductCategoryID,  st.SupplierID,  st.StoreID,  st.BrandID,  st.ProductID,  st.UPC,  s.ChainID,  st.SaleDateTime
) z
on ss.CategoryID = z.CategoryID and ss.supplierid = z.SupID and ss.storeid = z.StrID 
and ss.brandid = z.BrdID and ss.productid = z.PrdID and ss.chainid = z.chnid and ss.upc = z.UPC

return
GO
