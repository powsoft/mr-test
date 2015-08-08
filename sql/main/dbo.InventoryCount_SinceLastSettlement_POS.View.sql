USE [DataTrue_Main]
GO
/****** Object:  View [dbo].[InventoryCount_SinceLastSettlement_POS]    Script Date: 06/25/2015 18:26:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[InventoryCount_SinceLastSettlement_POS]
AS
SELECT     SUM(dbo.StoreTransactions.Qty * dbo.TransactionTypes.QtySign) AS TTLPOS, 
                      SUM(dbo.StoreTransactions.Qty * dbo.TransactionTypes.QtySign * dbo.StoreTransactions.RuleCost) AS TTLPOS$, 
                      dbo.InventoryCount_LastSettlementDate_FACT_Table.SupplierID, dbo.InventoryCount_LastSettlementDate_FACT_Table.StoreID, 
                      dbo.InventoryCount_LastSettlementDate_FACT_Table.UPC
FROM         dbo.InventoryCount_LastSettlementDate_FACT_Table INNER JOIN
                      dbo.StoreTransactions ON dbo.InventoryCount_LastSettlementDate_FACT_Table.StoreID = dbo.StoreTransactions.StoreID AND 
                      dbo.InventoryCount_LastSettlementDate_FACT_Table.SupplierID = dbo.StoreTransactions.SupplierID AND 
                      dbo.InventoryCount_LastSettlementDate_FACT_Table.LastInventorySettelmentDate <= dbo.StoreTransactions.SaleDateTime AND 
                      dbo.InventoryCount_LastSettlementDate_FACT_Table.UPC = dbo.StoreTransactions.UPC INNER JOIN
                      dbo.TransactionTypes ON dbo.StoreTransactions.TransactionTypeID = dbo.TransactionTypes.TransactionTypeID INNER JOIN
                      dbo.InventoryCount_LastCountDate_FACT_Table ON dbo.StoreTransactions.SupplierID = dbo.InventoryCount_LastCountDate_FACT_Table.SupplierID AND 
                      dbo.StoreTransactions.StoreID = dbo.InventoryCount_LastCountDate_FACT_Table.StoreID AND 
                      dbo.StoreTransactions.SaleDateTime < dbo.InventoryCount_LastCountDate_FACT_Table.LastInventoryCountDate AND 
                      dbo.StoreTransactions.UPC = dbo.InventoryCount_LastCountDate_FACT_Table.UPC
GROUP BY dbo.TransactionTypes.BucketTypeName, dbo.InventoryCount_LastSettlementDate_FACT_Table.SupplierID, 
                      dbo.InventoryCount_LastSettlementDate_FACT_Table.StoreID, dbo.InventoryCount_LastSettlementDate_FACT_Table.UPC
HAVING      (dbo.TransactionTypes.BucketTypeName = N'POS')
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[44] 4[19] 2[28] 3) )"
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
         Begin Table = "InventoryCount_LastSettlementDate_FACT_Table"
            Begin Extent = 
               Top = 41
               Left = 70
               Bottom = 169
               Right = 466
            End
            DisplayFlags = 280
            TopColumn = 1
         End
         Begin Table = "StoreTransactions"
            Begin Extent = 
               Top = 5
               Left = 635
               Bottom = 301
               Right = 857
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "TransactionTypes"
            Begin Extent = 
               Top = 7
               Left = 881
               Bottom = 135
               Right = 1123
            End
            DisplayFlags = 280
            TopColumn = 1
         End
         Begin Table = "InventoryCount_LastCountDate_FACT_Table"
            Begin Extent = 
               Top = 176
               Left = 72
               Bottom = 324
               Right = 465
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
      Begin ColumnWidths = 12
         Width = 284
         Width = 1200
         Width = 1200
         Width = 1620
         Width = 1200
         Width = 1200
         Width = 2340
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 3120
         Alias = 900
         Table = 3855
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'InventoryCount_SinceLastSettlement_POS'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N' = 1350
         SortOrder = 1410
         GroupBy = 1356
         Filter = 7410
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'InventoryCount_SinceLastSettlement_POS'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'InventoryCount_SinceLastSettlement_POS'
GO
