USE [DataTrue_Main]
GO
/****** Object:  View [dbo].[InventoryReport_Dates of Settlement and Counts]    Script Date: 06/25/2015 18:26:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[InventoryReport_Dates of Settlement and Counts]
AS
SELECT     TOP (100) PERCENT dbo.Suppliers.SupplierName, dbo.Chains.ChainName, dbo.Stores.StoreIdentifier AS StoreNo, NULL AS SupplierAcctNo, 
                      dbo.Stores.Custom1 AS Banner, CONVERT(varchar, s.SaleDateTime, 101) AS LastInventoryCountDate, CONVERT(varchar, 
                      dbo.InventoryCount_LastSettlementDate_FACT_Table.LastInventorySettelmentDate, 101) AS LastSettlementDate, s.UPC, 
                      dbo.InventoryCount_LastSettlementDate_FACT_Table.LS_TTLUnits AS [BI Count], dbo.InventoryCount_LastSettlementDate_FACT_Table.LS_TTLCost AS BI$, NULL 
                      AS [Net Deliveries], NULL AS [Net Deliveries$], NULL AS [Net POS], NULL AS POS$, NULL AS [Expected EI], NULL AS [Expected EI$], SUM(s.Qty) AS LastCountQty, 
                      SUM(s.Qty * (ISNULL(p3.UnitPrice, s.RuleCost) - ISNULL(p8.UnitPrice, ISNULL(s.PromoAllowance, 0)))) AS LastCount$, NULL AS ShrinkUnits, NULL AS Shrink$, 
                      s.SupplierID, dbo.Chains.ChainID, s.StoreID, s.ProductID, NULL AS SupplierUniqueProductID, NULL AS LastCountCost, NULL AS LastCountBaseCost
FROM         dbo.StoreTransactions AS s INNER JOIN
                      dbo.Stores ON s.StoreID = dbo.Stores.StoreID INNER JOIN
                      dbo.Chains ON s.ChainID = dbo.Chains.ChainID INNER JOIN
                      dbo.Suppliers ON s.SupplierID = dbo.Suppliers.SupplierID LEFT OUTER JOIN
                      dbo.InventoryCount_LastSettlementDate_FACT_Table ON s.SupplierID = dbo.InventoryCount_LastSettlementDate_FACT_Table.SupplierID AND 
                      s.StoreID = dbo.InventoryCount_LastSettlementDate_FACT_Table.StoreID AND s.UPC = dbo.InventoryCount_LastSettlementDate_FACT_Table.UPC LEFT OUTER JOIN
                      dbo.ProductPrices AS p8 ON p8.SupplierID = s.SupplierID AND p8.ProductID = s.ProductID AND p8.StoreID = s.StoreID AND p8.ActiveStartDate < s.SaleDateTime AND 
                      p8.ActiveLastDate >= s.SaleDateTime AND p8.ProductPriceTypeID = 8 LEFT OUTER JOIN
                      dbo.ProductPrices AS p3 ON p3.SupplierID = s.SupplierID AND p3.ProductID = s.ProductID AND p3.StoreID = s.StoreID AND p3.ActiveStartDate < s.SaleDateTime AND 
                      p3.ActiveLastDate >= s.SaleDateTime AND p3.ProductPriceTypeID = 3
WHERE     (s.TransactionTypeID IN (11, 10)) AND (s.SaleDateTime > ISNULL(dbo.InventoryCount_LastSettlementDate_FACT_Table.LastInventorySettelmentDate, 
                      CONVERT(DATETIME, '2000-01-01 00:00:00', 102)))
GROUP BY s.SupplierID, s.StoreID, s.UPC, CONVERT(varchar, s.SaleDateTime, 101), CONVERT(varchar, 
                      dbo.InventoryCount_LastSettlementDate_FACT_Table.LastInventorySettelmentDate, 101), dbo.InventoryCount_LastSettlementDate_FACT_Table.LS_TTLCost, 
                      dbo.InventoryCount_LastSettlementDate_FACT_Table.LS_TTLUnits, s.ProductID, dbo.Suppliers.SupplierName, dbo.Chains.ChainID, dbo.Chains.ChainName, 
                      dbo.Stores.StoreIdentifier, dbo.Stores.Custom1
ORDER BY s.SupplierID, s.StoreID, LastInventoryCountDate DESC
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "s"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 114
               Right = 250
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Stores"
            Begin Extent = 
               Top = 6
               Left = 288
               Bottom = 114
               Right = 484
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Chains"
            Begin Extent = 
               Top = 6
               Left = 522
               Bottom = 114
               Right = 785
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Suppliers"
            Begin Extent = 
               Top = 114
               Left = 38
               Bottom = 222
               Right = 255
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "InventoryCount_LastSettlementDate_FACT_Table"
            Begin Extent = 
               Top = 114
               Left = 293
               Bottom = 222
               Right = 532
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "p8"
            Begin Extent = 
               Top = 114
               Left = 570
               Bottom = 222
               Right = 830
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "p3"
            Begin Extent = 
               Top = 222
               Left = 38
               Bottom = 330
               Right = 298
            End
            ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'InventoryReport_Dates of Settlement and Counts'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1665
         Alias = 2010
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'InventoryReport_Dates of Settlement and Counts'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'InventoryReport_Dates of Settlement and Counts'
GO
