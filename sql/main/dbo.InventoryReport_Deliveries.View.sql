USE [DataTrue_Main]
GO
/****** Object:  View [dbo].[InventoryReport_Deliveries]    Script Date: 06/25/2015 18:26:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[InventoryReport_Deliveries]
AS
SELECT     TOP (100) PERCENT SUM(s.Qty * dbo.TransactionTypes.QtySign) AS NetDeliveries, SUM((s.Qty * dbo.TransactionTypes.QtySign) * (ISNULL(p3.UnitPrice, s.RuleCost) 
                      - ISNULL(p8.UnitPrice, ISNULL(s.PromoAllowance, 0)))) AS NetDeliveries$, dbo.InventoryReport_New_FactTable.LastSettlementDate, 
                      dbo.InventoryReport_New_FactTable.LastInventoryCountDate, dbo.InventoryReport_New_FactTable.UPC, dbo.Stores.StoreIdentifier AS StoreNumber, s.StoreID, 
                      s.ProductID, s.SupplierID
FROM         dbo.Stores INNER JOIN
                      dbo.InventoryReport_New_FactTable INNER JOIN
                      dbo.InventoryRulesTimesBySupplierID ON dbo.InventoryReport_New_FactTable.SupplierID = dbo.InventoryRulesTimesBySupplierID.SupplierID AND 
                      dbo.InventoryReport_New_FactTable.ChainID = dbo.InventoryRulesTimesBySupplierID.ChainID ON 
                      dbo.Stores.StoreID = dbo.InventoryReport_New_FactTable.StoreID LEFT OUTER JOIN
                      dbo.TransactionTypes INNER JOIN
                      dbo.StoreTransactions AS s ON dbo.TransactionTypes.TransactionTypeID = s.TransactionTypeID ON dbo.InventoryReport_New_FactTable.ProductID = s.ProductID AND
                       dbo.InventoryReport_New_FactTable.StoreID = s.StoreID AND dbo.InventoryReport_New_FactTable.SupplierID = s.SupplierID LEFT OUTER JOIN
                      dbo.ProductPrices AS p8 ON p8.SupplierID = s.SupplierID AND p8.ProductID = s.ProductID AND p8.StoreID = s.StoreID AND p8.ActiveStartDate < s.SaleDateTime AND 
                      p8.ActiveLastDate >= s.SaleDateTime AND p8.ProductPriceTypeID = 8 LEFT OUTER JOIN
                      dbo.ProductPrices AS p3 ON p3.SupplierID = s.SupplierID AND p3.ProductID = s.ProductID AND p3.StoreID = s.StoreID AND p3.ActiveStartDate < s.SaleDateTime AND 
                      p3.ActiveLastDate >= s.SaleDateTime AND p3.ProductPriceTypeID = 3
WHERE     (dbo.TransactionTypes.BucketType = 2) AND (dbo.InventoryRulesTimesBySupplierID.InventoryTakenBeforeDeliveries = 1) AND 
                      (s.SaleDateTime >= CONVERT(DATETIME, '2011-12-01 00:00:00', 102)) AND (s.SaleDateTime >= ISNULL(dbo.InventoryReport_New_FactTable.LastSettlementDate, 
                      CONVERT(DATETIME, '1900-01-01 00:00:00', 102))) AND (s.SaleDateTime < dbo.InventoryReport_New_FactTable.LastInventoryCountDate)
GROUP BY dbo.InventoryReport_New_FactTable.LastSettlementDate, dbo.InventoryReport_New_FactTable.LastInventoryCountDate, dbo.InventoryReport_New_FactTable.UPC, 
                      dbo.Stores.StoreIdentifier, s.StoreID, s.ProductID, s.SupplierID
ORDER BY dbo.InventoryReport_New_FactTable.LastInventoryCountDate
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
         Begin Table = "Stores"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 114
               Right = 234
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "InventoryReport_New_FactTable"
            Begin Extent = 
               Top = 6
               Left = 272
               Bottom = 114
               Right = 488
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "InventoryRulesTimesBySupplierID"
            Begin Extent = 
               Top = 6
               Left = 526
               Bottom = 114
               Right = 777
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "TransactionTypes"
            Begin Extent = 
               Top = 114
               Left = 38
               Bottom = 222
               Right = 267
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "s"
            Begin Extent = 
               Top = 114
               Left = 305
               Bottom = 222
               Right = 517
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "p8"
            Begin Extent = 
               Top = 114
               Left = 555
               Bottom = 222
               Right = 815
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
            ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'InventoryReport_Deliveries'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'End
            DisplayFlags = 280
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
         Column = 1440
         Alias = 900
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'InventoryReport_Deliveries'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'InventoryReport_Deliveries'
GO
