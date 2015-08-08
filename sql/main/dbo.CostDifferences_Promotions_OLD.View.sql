USE [DataTrue_Main]
GO
/****** Object:  View [dbo].[CostDifferences_Promotions_OLD]    Script Date: 06/25/2015 18:26:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[CostDifferences_Promotions_OLD]
AS
SELECT     (ISNULL(ProductPrices_Promotions.UnitPrice, 0) - dbo.StoreTransactions.PromoAllowance) * dbo.StoreTransactions.Qty AS LineTotalDifference, 
                      ISNULL(ProductPrices_Promotions.UnitPrice, 0) - dbo.StoreTransactions.PromoAllowance AS [Cost Difference], 
                      ProductPrices_Promotions.UnitPrice AS [Setup Unit Cost], dbo.StoreTransactions.ReportedCost + dbo.StoreTransactions.ReportedAllowance AS [Reported Gross Cost], 
                      dbo.StoreTransactions.TransactionTypeID, dbo.StoreTransactions.Qty, dbo.StoreTransactions.SaleDateTime, dbo.StoreTransactions.UPC AS [Standard UPC], 
                      dbo.StoreTransactions.RawProductIdentifier AS [Reported UPC], dbo.StoreTransactions.SupplierName AS [Reported Supplier Name], 
                      dbo.StoreTransactions.SupplierIdentifier AS [Reported SupplierID], dbo.StoreTransactions.DivisionIdentifier, dbo.StoreTransactions.PONo, 
                      dbo.Suppliers.SupplierName, dbo.Stores.StoreIdentifier AS [Store Number], dbo.Chains.ChainName, dbo.Products.ProductName
FROM         dbo.StoreTransactions INNER JOIN
                      dbo.Chains ON dbo.StoreTransactions.ChainID = dbo.Chains.ChainID INNER JOIN
                      dbo.Products ON dbo.StoreTransactions.ProductID = dbo.Products.ProductID INNER JOIN
                      dbo.Suppliers ON dbo.StoreTransactions.SupplierID = dbo.Suppliers.SupplierID INNER JOIN
                      dbo.Stores ON dbo.StoreTransactions.StoreID = dbo.Stores.StoreID LEFT OUTER JOIN
                      dbo.ProductPrices_Promotions AS ProductPrices_Promotions ON dbo.StoreTransactions.BrandID = ProductPrices_Promotions.BrandID AND 
                      dbo.StoreTransactions.SupplierID = ProductPrices_Promotions.SupplierID AND dbo.StoreTransactions.StoreID = ProductPrices_Promotions.StoreID AND 
                      dbo.StoreTransactions.ChainID = ProductPrices_Promotions.ChainID AND dbo.StoreTransactions.ProductID = ProductPrices_Promotions.ProductID AND 
                      ProductPrices_Promotions.UnitPrice <> dbo.StoreTransactions.ReportedCost + dbo.StoreTransactions.ReportedAllowance
WHERE     (dbo.StoreTransactions.SaleDateTime BETWEEN ProductPrices_Promotions.ActiveStartDate AND ProductPrices_Promotions.ActiveLastDate) AND 
                      (dbo.StoreTransactions.SaleDateTime >= '12/1/2011') AND ((ISNULL(ProductPrices_Promotions.UnitPrice, 0) - dbo.StoreTransactions.PromoAllowance) 
                      * dbo.StoreTransactions.Qty <> 0)
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[33] 4[17] 2[36] 3) )"
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
               Top = 23
               Left = 13
               Bottom = 230
               Right = 209
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Suppliers"
            Begin Extent = 
               Top = 6
               Left = 775
               Bottom = 114
               Right = 955
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Stores"
            Begin Extent = 
               Top = 132
               Left = 788
               Bottom = 305
               Right = 968
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ProductPrices_Promotions"
            Begin Extent = 
               Top = 1
               Left = 512
               Bottom = 170
               Right = 732
            End
            DisplayFlags = 280
            TopColumn = 1
         End
         Begin Table = "Products"
            Begin Extent = 
               Top = 199
               Left = 582
               Bottom = 307
               Right = 762
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Chains"
            Begin Extent = 
               Top = 174
               Left = 247
               Bottom = 282
               Right = 494
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
      Begin ColumnWidths = 18
         Width = 284
         Width = 1590' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'CostDifferences_Promotions_OLD'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'
         Width = 1500
         Width = 1110
         Width = 1365
         Width = 1500
         Width = 465
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
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 12015
         Alias = 1845
         Table = 2085
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 2625
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'CostDifferences_Promotions_OLD'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'CostDifferences_Promotions_OLD'
GO
