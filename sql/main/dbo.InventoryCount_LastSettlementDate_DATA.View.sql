USE [DataTrue_Main]
GO
/****** Object:  View [dbo].[InventoryCount_LastSettlementDate_DATA]    Script Date: 06/25/2015 18:26:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[InventoryCount_LastSettlementDate_DATA]
AS
SELECT     dbo.InventoryCount_LastSettlementDate.supplierId, dbo.InventoryCount_LastSettlementDate.StoreID, dbo.InventoryCount_LastSettlementDate.LastSettlementDate, 
                      ISNULL(dbo.InventoryCount_AggregatedFinancialData.TTLUnits, 0) AS LS_TTLQnt, ISNULL(dbo.InventoryCount_AggregatedFinancialData.TTLCost, 0) AS LS_TTLCost, 
                      dbo.InventoryCount_LastSettlementDate.UPC
FROM         dbo.InventoryCount_LastSettlementDate LEFT OUTER JOIN
                      dbo.InventoryCount_AggregatedFinancialData ON dbo.InventoryCount_LastSettlementDate.StoreID = dbo.InventoryCount_AggregatedFinancialData.StoreID AND 
                      dbo.InventoryCount_LastSettlementDate.supplierId = dbo.InventoryCount_AggregatedFinancialData.SupplierID AND 
                      dbo.InventoryCount_LastSettlementDate.LastSettlementDate = dbo.InventoryCount_AggregatedFinancialData.InventoryCountDate AND 
                      dbo.InventoryCount_LastSettlementDate.UPC = dbo.InventoryCount_AggregatedFinancialData.UPC
WHERE     (dbo.InventoryCount_LastSettlementDate.LastSettlementDate >= CONVERT(DATETIME, '2011-11-30 00:00:00', 102))
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
         Begin Table = "InventoryCount_LastSettlementDate"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 135
               Right = 243
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "InventoryCount_AggregatedFinancialData"
            Begin Extent = 
               Top = 7
               Left = 291
               Bottom = 183
               Right = 694
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
      Begin ColumnWidths = 9
         Width = 284
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
         Column = 1650
         Alias = 900
         Table = 3270
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'InventoryCount_LastSettlementDate_DATA'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'InventoryCount_LastSettlementDate_DATA'
GO
