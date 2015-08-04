USE [DataTrue_Main]
GO
/****** Object:  View [dbo].[vPendingTransactions]    Script Date: 06/25/2015 18:26:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vPendingTransactions]
AS
SELECT     TOP (100) PERCENT dbo.Products.ProductName, dbo.Stores.StoreName, dbo.StoreTransactions.StoreTransactionID, dbo.Brands.BrandName, 
                      dbo.Suppliers.SupplierName, dbo.StoreTransactions.ReportedCost, dbo.StoreTransactions.ReportedRetail, dbo.StoreTransactions.SaleDateTime, 
                      dbo.PendingTransactions.PendingReason, dbo.PendingTransactions.PendingStatus, dbo.PendingTransactions.PendingTransactionID, 
                      dbo.StoreTransactions.ChainID
FROM         dbo.StoreTransactions INNER JOIN
                      dbo.PendingTransactions ON dbo.StoreTransactions.StoreTransactionID = dbo.PendingTransactions.StoreTransactionID LEFT OUTER JOIN
                      dbo.Brands ON dbo.Brands.BrandID = dbo.StoreTransactions.BrandID LEFT OUTER JOIN
                      dbo.Products ON dbo.StoreTransactions.ProductID = dbo.Products.ProductID LEFT OUTER JOIN
                      dbo.Stores ON dbo.StoreTransactions.StoreID = dbo.Stores.StoreID LEFT OUTER JOIN
                      dbo.Suppliers ON dbo.StoreTransactions.SupplierID = dbo.Suppliers.SupplierID
WHERE     ({ fn UCASE(dbo.PendingTransactions.PendingStatus) } <> 'APPROVED')
ORDER BY dbo.StoreTransactions.SaleDateTime, dbo.Stores.StoreName, dbo.Suppliers.SupplierName
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[32] 4[10] 2[43] 3) )"
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
         Begin Table = "Brands"
            Begin Extent = 
               Top = 222
               Left = 31
               Bottom = 341
               Right = 220
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Products"
            Begin Extent = 
               Top = 6
               Left = 497
               Bottom = 125
               Right = 686
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Stores"
            Begin Extent = 
               Top = 6
               Left = 724
               Bottom = 125
               Right = 913
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "StoreTransactions"
            Begin Extent = 
               Top = 149
               Left = 434
               Bottom = 268
               Right = 633
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Suppliers"
            Begin Extent = 
               Top = 93
               Left = 37
               Bottom = 212
               Right = 226
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "PendingTransactions"
            Begin Extent = 
               Top = 8
               Left = 225
               Bottom = 127
               Right = 419
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
      Begin ColumnWidths = 13
         Width = 284
         Width = 1500
       ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vPendingTransactions'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'  Width = 1500
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
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vPendingTransactions'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vPendingTransactions'
GO
