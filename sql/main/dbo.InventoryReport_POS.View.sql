USE [DataTrue_Main]
GO
/****** Object:  View [dbo].[InventoryReport_POS]    Script Date: 06/25/2015 18:26:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[InventoryReport_POS]
AS
SELECT     TOP (100) PERCENT SUM(dbo.StoreTransactions.Qty * dbo.TransactionTypes.QtySign) AS NetPOS, SUM((dbo.StoreTransactions.Qty * dbo.TransactionTypes.QtySign) 
                      * (dbo.StoreTransactions.RuleCost - ISNULL(dbo.StoreTransactions.PromoAllowance, 0))) AS NetPOS$, dbo.InventoryReport_New_FactTable.LastSettlementDate, 
                      dbo.InventoryReport_New_FactTable.LastInventoryCountDate, dbo.InventoryReport_New_FactTable.UPC, dbo.Stores.StoreIdentifier AS StoreNumber, 
                      dbo.InventoryReport_New_FactTable.SupplierID, dbo.InventoryReport_New_FactTable.ChainID, dbo.InventoryReport_New_FactTable.StoreID, 
                      dbo.InventoryReport_New_FactTable.ProductID
FROM         dbo.Stores INNER JOIN
                      dbo.InventoryReport_New_FactTable INNER JOIN
                      dbo.InventoryRulesTimesBySupplierID ON dbo.InventoryReport_New_FactTable.SupplierID = dbo.InventoryRulesTimesBySupplierID.SupplierID AND 
                      dbo.InventoryReport_New_FactTable.ChainID = dbo.InventoryRulesTimesBySupplierID.ChainID ON 
                      dbo.Stores.StoreID = dbo.InventoryReport_New_FactTable.StoreID LEFT OUTER JOIN
                      dbo.TransactionTypes INNER JOIN
                      dbo.StoreTransactions ON dbo.TransactionTypes.TransactionTypeID = dbo.StoreTransactions.TransactionTypeID ON 
                      dbo.InventoryReport_New_FactTable.ProductID = dbo.StoreTransactions.ProductID AND 
                      dbo.InventoryReport_New_FactTable.StoreID = dbo.StoreTransactions.StoreID AND 
                      dbo.InventoryReport_New_FactTable.SupplierID = dbo.StoreTransactions.SupplierID
WHERE     (dbo.TransactionTypes.BucketType = 1) AND (dbo.InventoryRulesTimesBySupplierID.InventoryTakenBeforeDeliveries = 1) AND 
                      (dbo.StoreTransactions.SaleDateTime >= CONVERT(DATETIME, '2011-12-01 00:00:00', 102)) AND 
                      (dbo.StoreTransactions.SaleDateTime >= ISNULL(dbo.InventoryReport_New_FactTable.LastSettlementDate, CONVERT(DATETIME, '1900-01-01 00:00:00', 102))) AND 
                      (dbo.StoreTransactions.SaleDateTime < dbo.InventoryReport_New_FactTable.LastInventoryCountDate)
GROUP BY dbo.InventoryReport_New_FactTable.LastSettlementDate, dbo.InventoryReport_New_FactTable.LastInventoryCountDate, dbo.InventoryReport_New_FactTable.UPC, 
                      dbo.Stores.StoreIdentifier, dbo.InventoryReport_New_FactTable.SupplierID, dbo.InventoryReport_New_FactTable.ChainID, 
                      dbo.InventoryReport_New_FactTable.StoreID, dbo.InventoryReport_New_FactTable.ProductID
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
               Bottom = 178
               Right = 234
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "InventoryReport_New_FactTable"
            Begin Extent = 
               Top = 6
               Left = 272
               Bottom = 229
               Right = 488
            End
            DisplayFlags = 280
            TopColumn = 15
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
               Top = 6
               Left = 815
               Bottom = 114
               Right = 1044
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "StoreTransactions"
            Begin Extent = 
               Top = 180
               Left = 347
               Bottom = 288
               Right = 559
            End
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
      Begin ColumnWidths = 11
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
 ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'InventoryReport_POS'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'  Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 10380
         Alias = 900
         Table = 2655
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 6195
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'InventoryReport_POS'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'InventoryReport_POS'
GO
