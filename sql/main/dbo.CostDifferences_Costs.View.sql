USE [DataTrue_Main]
GO
/****** Object:  View [dbo].[CostDifferences_Costs]    Script Date: 06/25/2015 18:26:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[CostDifferences_Costs]
AS
SELECT     dbo.StoreTransactions.SaleDateTime, dbo.StoreTransactions.ReportedCost + dbo.StoreTransactions.ReportedAllowance AS [Retailer Cost], 
                      dbo.ProductPrices.UnitPrice AS [Setup Cost], dbo.ProductPrices.ActiveStartDate, dbo.StoreTransactions.StoreID, dbo.StoreTransactions.ProductID, 
                      dbo.StoreTransactions.SupplierID, dbo.StoreTransactions.Qty, dbo.StoreTransactions.UPC
FROM         dbo.StoreTransactions LEFT OUTER JOIN
                      dbo.ProductPrices ON dbo.StoreTransactions.ChainID = dbo.ProductPrices.ChainID AND dbo.StoreTransactions.StoreID = dbo.ProductPrices.StoreID AND 
                      dbo.StoreTransactions.ProductID = dbo.ProductPrices.ProductID AND dbo.StoreTransactions.SupplierID = dbo.ProductPrices.SupplierID
WHERE     (dbo.StoreTransactions.TransactionTypeID IN (2, 16)) AND (dbo.StoreTransactions.SaleDateTime >= CONVERT(DATETIME, '2011-12-01 00:00:00', 102) AND 
                      dbo.StoreTransactions.SaleDateTime >= { fn NOW() } - 60) AND (dbo.StoreTransactions.SaleDateTime BETWEEN dbo.ProductPrices.ActiveStartDate AND 
                      dbo.ProductPrices.ActiveLastDate) AND (dbo.ProductPrices.ProductPriceTypeID = 3) AND (dbo.StoreTransactions.Reversed = 0)
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[35] 4[25] 2[24] 3) )"
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
         Begin Table = "StoreTransactions"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 230
               Right = 234
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ProductPrices"
            Begin Extent = 
               Top = 9
               Left = 361
               Bottom = 233
               Right = 581
            End
            DisplayFlags = 280
            TopColumn = 1
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 10
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
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 6225
         Alias = 1275
         Table = 1530
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 6360
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'CostDifferences_Costs'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'CostDifferences_Costs'
GO
