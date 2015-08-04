USE [DataTrue_Main]
GO
/****** Object:  View [dbo].[LastScanActivityDetails]    Script Date: 06/25/2015 18:26:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[LastScanActivityDetails]
AS
SELECT     dbo.TransactionTypes.BucketTypeName, dbo.Chains.ChainName, dbo.Stores.StoreIdentifier AS [Store Number], dbo.Stores.Custom1 AS Banner, 
                      dbo.Suppliers.SupplierName, dbo.Products.ProductName, dbo.ProductIdentifiers.IdentifierValue AS UPC, SUM(S.Qty * dbo.TransactionTypes.QtySign) AS Qty
FROM         DataTrue_Report.dbo.StoreTransactions AS S INNER JOIN
                      dbo.TransactionTypes ON S.TransactionTypeID = dbo.TransactionTypes.TransactionTypeID INNER JOIN
                      dbo.Stores ON S.StoreID = dbo.Stores.StoreID INNER JOIN
                      dbo.Suppliers ON S.SupplierID = dbo.Suppliers.SupplierID INNER JOIN
                      dbo.Products ON S.ProductID = dbo.Products.ProductID INNER JOIN
                      dbo.ProductIdentifiers ON dbo.Products.ProductID = dbo.ProductIdentifiers.ProductID INNER JOIN
                      dbo.Chains ON S.ChainID = dbo.Chains.ChainID INNER JOIN
                      dbo.LastScanActivity ON S.StoreID = dbo.LastScanActivity.StoreID AND S.SupplierID = dbo.LastScanActivity.SupplierID AND 
                      S.SaleDateTime = dbo.LastScanActivity.LastScanDate
WHERE     (dbo.ProductIdentifiers.ProductIdentifierTypeID = 2) AND (dbo.Suppliers.SupplierID = 40558)
GROUP BY dbo.TransactionTypes.BucketTypeName, dbo.Stores.StoreIdentifier, dbo.Stores.Custom1, dbo.Suppliers.SupplierName, dbo.Products.ProductName, 
                      dbo.ProductIdentifiers.IdentifierValue, dbo.Chains.ChainName
HAVING      (dbo.TransactionTypes.BucketTypeName = N'POS')
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
         Begin Table = "TransactionTypes"
            Begin Extent = 
               Top = 6
               Left = 272
               Bottom = 114
               Right = 485
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Stores"
            Begin Extent = 
               Top = 6
               Left = 523
               Bottom = 114
               Right = 703
            End
            DisplayFlags = 280
            TopColumn = 12
         End
         Begin Table = "Suppliers"
            Begin Extent = 
               Top = 6
               Left = 741
               Bottom = 114
               Right = 921
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Products"
            Begin Extent = 
               Top = 6
               Left = 959
               Bottom = 114
               Right = 1139
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ProductIdentifiers"
            Begin Extent = 
               Top = 133
               Left = 901
               Bottom = 250
               Right = 1097
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Chains"
            Begin Extent = 
               Top = 123
               Left = 289
               Bottom = 231
               Right = 536
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "LastScanActivity"
            Begin Extent = 
               Top = 132
               Left = 41
               Bottom = 257
               Right = 204
            End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'LastScanActivityDetails'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "S"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 114
               Right = 250
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'LastScanActivityDetails'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'LastScanActivityDetails'
GO
