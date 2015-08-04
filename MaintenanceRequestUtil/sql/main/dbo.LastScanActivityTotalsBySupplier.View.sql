USE [DataTrue_Main]
GO
/****** Object:  View [dbo].[LastScanActivityTotalsBySupplier]    Script Date: 06/25/2015 18:26:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[LastScanActivityTotalsBySupplier]
AS
SELECT     TOP (100) PERCENT dbo.LastScanActivity.ChainName, dbo.LastScanActivity.Banner, dbo.LastScanActivity.StoreIdentifier AS [Store No], 
                      dbo.LastScanActivity.SupplierName, SUM(dbo.StoreTransactions.Qty * dbo.TransactionTypes.QtySign) AS Qty, dbo.LastScanActivity.LastScanDate
FROM         dbo.StoreTransactions INNER JOIN
                      dbo.TransactionTypes ON dbo.StoreTransactions.TransactionTypeID = dbo.TransactionTypes.TransactionTypeID INNER JOIN
                      dbo.LastScanActivity ON dbo.StoreTransactions.StoreID = dbo.LastScanActivity.StoreID AND dbo.StoreTransactions.SupplierID = dbo.LastScanActivity.SupplierID AND 
                      dbo.StoreTransactions.SaleDateTime = dbo.LastScanActivity.LastScanDate
WHERE     (dbo.TransactionTypes.BucketType = 1) AND (dbo.LastScanActivity.SupplierID = 2) AND (dbo.LastScanActivity.ChainID = 2)
GROUP BY dbo.LastScanActivity.LastScanDate, dbo.LastScanActivity.ChainName, dbo.LastScanActivity.StoreIdentifier, dbo.LastScanActivity.Banner, 
                      dbo.LastScanActivity.SupplierName
ORDER BY dbo.LastScanActivity.ChainName, dbo.LastScanActivity.Banner, [Store No], dbo.LastScanActivity.SupplierName
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[36] 4[27] 2[20] 3) )"
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
               Left = 573
               Bottom = 225
               Right = 785
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "TransactionTypes"
            Begin Extent = 
               Top = 6
               Left = 823
               Bottom = 114
               Right = 1052
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "LastScanActivity"
            Begin Extent = 
               Top = 29
               Left = 220
               Bottom = 137
               Right = 399
            End
            DisplayFlags = 280
            TopColumn = 5
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
         Width = 1500
         Width = 1500
         Width = 1590
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1830
         Alias = 1920
         Table = 1530
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1680
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'LastScanActivityTotalsBySupplier'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'LastScanActivityTotalsBySupplier'
GO
