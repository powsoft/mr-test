USE [DataTrue_Main]
GO
/****** Object:  View [dbo].[InventoryCount_MAIN REPORT]    Script Date: 06/25/2015 18:26:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[InventoryCount_MAIN REPORT]
AS
SELECT     dbo.Suppliers.SupplierName, dbo.Chains.ChainName, dbo.Stores.StoreIdentifier AS StoreNumber, dbo.Stores.Custom1 AS Banner, 
                      dbo.InventoryCount_LastCountDate_FACT_Table.LastInventoryCountDate AS [Last Count Date], 
                      dbo.InventoryCount_LastSettlementDate_FACT_Table.LastInventorySettelmentDate AS [BI Date], dbo.InventoryCount_LastSettlementDate_FACT_Table.UPC, 
                      dbo.InventoryCount_LastSettlementDate_FACT_Table.LS_TTLUnits AS [BI Count], dbo.InventoryCount_LastSettlementDate_FACT_Table.LS_TTLCost AS [BI $], 
                      ISNULL(dbo.InventoryCount_SinceLastSettlement_Deliveries.TTLDeliveries, 0) AS [Total Deliveries], 
                      ISNULL(dbo.InventoryCount_SinceLastSettlement_Deliveries.TTLDeliveries$, 0) AS [Total Deliveries$], 
                      ISNULL(dbo.InventoryCount_SinceLastSettlement_POS.TTLPOS, 0) AS [Total POS], ISNULL(dbo.InventoryCount_SinceLastSettlement_POS.TTLPOS$, 0) 
                      AS [Total POS$], dbo.InventoryCount_LastSettlementDate_FACT_Table.LS_TTLUnits + ISNULL(dbo.InventoryCount_SinceLastSettlement_Deliveries.TTLDeliveries, 0) 
                      - ISNULL(dbo.InventoryCount_SinceLastSettlement_POS.TTLPOS, 0) AS [Expected EI], 
                      dbo.InventoryCount_LastSettlementDate_FACT_Table.LS_TTLCost + ISNULL(dbo.InventoryCount_SinceLastSettlement_Deliveries.TTLDeliveries$, 0) 
                      - ISNULL(dbo.InventoryCount_SinceLastSettlement_POS.TTLPOS$, 0) AS [Expected EI$], dbo.InventoryCount_LastCountDate_FACT_Table.LC_TTLUnits AS [Last Count],
                       dbo.InventoryCount_LastCountDate_FACT_Table.LC_TTLCost AS [Last Count$], 
                      - dbo.InventoryCount_LastCountDate_FACT_Table.LC_TTLUnits + (dbo.InventoryCount_LastSettlementDate_FACT_Table.LS_TTLUnits + ISNULL(dbo.InventoryCount_SinceLastSettlement_Deliveries.TTLDeliveries,
                       0) - ISNULL(dbo.InventoryCount_SinceLastSettlement_POS.TTLPOS, 0)) AS [Shrink Units], 
                      - dbo.InventoryCount_LastCountDate_FACT_Table.LC_TTLCost + (dbo.InventoryCount_LastSettlementDate_FACT_Table.LS_TTLCost + ISNULL(dbo.InventoryCount_SinceLastSettlement_Deliveries.TTLDeliveries$,
                       0) - ISNULL(dbo.InventoryCount_SinceLastSettlement_POS.TTLPOS$, 0)) AS [Shrink $], dbo.Chains.ChainID, dbo.Suppliers.SupplierID, 
                      dbo.InventoryCount_LastSettlementDate_FACT_Table.StoreID
FROM         dbo.InventoryCount_LastCountDate_FACT_Table RIGHT OUTER JOIN
                      dbo.InventoryCount_SinceLastSettlement_POS RIGHT OUTER JOIN
                      dbo.Suppliers INNER JOIN
                      dbo.Chains INNER JOIN
                      dbo.Stores ON dbo.Chains.ChainID = dbo.Stores.ChainID INNER JOIN
                      dbo.InventoryCount_LastSettlementDate_FACT_Table ON dbo.Stores.StoreID = dbo.InventoryCount_LastSettlementDate_FACT_Table.StoreID ON 
                      dbo.Suppliers.SupplierID = dbo.InventoryCount_LastSettlementDate_FACT_Table.SupplierID LEFT OUTER JOIN
                      dbo.InventoryCount_SinceLastSettlement_Deliveries ON 
                      dbo.InventoryCount_LastSettlementDate_FACT_Table.UPC = dbo.InventoryCount_SinceLastSettlement_Deliveries.UPC AND 
                      dbo.InventoryCount_LastSettlementDate_FACT_Table.SupplierID = dbo.InventoryCount_SinceLastSettlement_Deliveries.SupplierID AND 
                      dbo.InventoryCount_LastSettlementDate_FACT_Table.StoreID = dbo.InventoryCount_SinceLastSettlement_Deliveries.StoreID ON 
                      dbo.InventoryCount_SinceLastSettlement_POS.UPC = dbo.InventoryCount_LastSettlementDate_FACT_Table.UPC AND 
                      dbo.InventoryCount_SinceLastSettlement_POS.StoreID = dbo.InventoryCount_LastSettlementDate_FACT_Table.StoreID AND 
                      dbo.InventoryCount_SinceLastSettlement_POS.SupplierID = dbo.InventoryCount_LastSettlementDate_FACT_Table.SupplierID ON 
                      dbo.InventoryCount_LastCountDate_FACT_Table.UPC = dbo.InventoryCount_LastSettlementDate_FACT_Table.UPC AND 
                      dbo.InventoryCount_LastCountDate_FACT_Table.SupplierID = dbo.InventoryCount_LastSettlementDate_FACT_Table.SupplierID AND 
                      dbo.InventoryCount_LastCountDate_FACT_Table.StoreID = dbo.InventoryCount_LastSettlementDate_FACT_Table.StoreID
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[16] 4[11] 2[57] 3) )"
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
         Begin Table = "InventoryCount_LastCountDate_FACT_Table"
            Begin Extent = 
               Top = 197
               Left = 760
               Bottom = 350
               Right = 960
            End
            DisplayFlags = 280
            TopColumn = 1
         End
         Begin Table = "InventoryCount_SinceLastSettlement_POS"
            Begin Extent = 
               Top = 232
               Left = 332
               Bottom = 430
               Right = 580
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Suppliers"
            Begin Extent = 
               Top = 182
               Left = 31
               Bottom = 310
               Right = 233
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Chains"
            Begin Extent = 
               Top = 115
               Left = 1014
               Bottom = 243
               Right = 1296
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Stores"
            Begin Extent = 
               Top = 12
               Left = 827
               Bottom = 140
               Right = 1029
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "InventoryCount_LastSettlementDate_FACT_Table"
            Begin Extent = 
               Top = 37
               Left = 503
               Bottom = 194
               Right = 726
            End
            DisplayFlags = 280
            TopColumn = 1
         End
         Begin Table = "InventoryCount_SinceLastSettlement_Deliveries"
            Begin Extent = 
             ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'InventoryCount_MAIN REPORT'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'  Top = 4
               Left = 91
               Bottom = 132
               Right = 339
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
      Begin ColumnWidths = 22
         Width = 284
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 20925
         Alias = 1770
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1356
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'InventoryCount_MAIN REPORT'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'InventoryCount_MAIN REPORT'
GO
