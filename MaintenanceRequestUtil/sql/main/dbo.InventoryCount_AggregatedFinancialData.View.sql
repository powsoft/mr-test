USE [DataTrue_Main]
GO
/****** Object:  View [dbo].[InventoryCount_AggregatedFinancialData]    Script Date: 06/25/2015 18:26:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[InventoryCount_AggregatedFinancialData]
AS
SELECT DISTINCT 
                      s.SupplierID, s.StoreID, SUM(s.Qty) AS TTLUnits, s.SaleDateTime AS InventoryCountDate, SUM(s.Qty * (s.RuleCost - ISNULL(s.PromoAllowance, 0))) 
                      AS HistoricalTTLCost, s.UPC, s.PromoAllowance, p8.UnitPrice, p3.UnitPrice AS Expr1, SUM(s.Qty * (ISNULL(p3.UnitPrice, s.RuleCost) - ISNULL(p8.UnitPrice, 0))) 
                      AS TTLCost
FROM         dbo.StoreTransactions AS s LEFT OUTER JOIN
                      dbo.ProductPrices AS p8 ON p8.SupplierID = s.SupplierID AND p8.ProductID = s.ProductID AND p8.StoreID = s.StoreID AND p8.ActiveStartDate < s.SaleDateTime AND 
                      p8.ActiveLastDate >= s.SaleDateTime AND p8.ProductPriceTypeID = 8 LEFT OUTER JOIN
                      dbo.ProductPrices AS p3 ON p3.SupplierID = s.SupplierID AND p3.ProductID = s.ProductID AND p3.StoreID = s.StoreID AND p3.ActiveStartDate < s.SaleDateTime AND 
                      p3.ActiveLastDate >= s.SaleDateTime AND p3.ProductPriceTypeID = 3
WHERE     (s.TransactionTypeID IN (10, 11))
GROUP BY s.SupplierID, s.StoreID, s.SaleDateTime, s.UPC, s.PromoAllowance, p8.UnitPrice, p3.UnitPrice
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
               Top = 27
               Left = 8
               Bottom = 135
               Right = 220
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "p8"
            Begin Extent = 
               Top = 136
               Left = 289
               Bottom = 244
               Right = 549
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "p3"
            Begin Extent = 
               Top = 36
               Left = 617
               Bottom = 144
               Right = 877
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'InventoryCount_AggregatedFinancialData'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'InventoryCount_AggregatedFinancialData'
GO
