USE [DataTrue_Main]
GO
/****** Object:  View [dbo].[CostDifferences_Costs_OLD]    Script Date: 06/25/2015 18:26:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[CostDifferences_Costs_OLD]
AS
SELECT     (ISNULL(ProductPrices_Costs.UnitPrice, 0) - dbo.StoreTransactions.ReportedCost + dbo.StoreTransactions.ReportedAllowance) 
                      * dbo.StoreTransactions.Qty AS LineTotalDifference, ISNULL(ProductPrices_Costs.UnitPrice, 0) 
                      - dbo.StoreTransactions.ReportedCost + dbo.StoreTransactions.ReportedAllowance AS [Cost Difference], ProductPrices_Costs.UnitPrice AS [Setup Unit Cost], 
                      dbo.StoreTransactions.ReportedCost + dbo.StoreTransactions.ReportedAllowance AS [Reported Gross Cost], dbo.StoreTransactions.TransactionTypeID, 
                      dbo.StoreTransactions.Qty, dbo.StoreTransactions.SaleDateTime, dbo.StoreTransactions.UPC AS [Standard UPC], 
                      dbo.StoreTransactions.RawProductIdentifier AS [Reported UPC], dbo.StoreTransactions.SupplierName AS [Reported Supplier Name], 
                      dbo.StoreTransactions.SupplierIdentifier AS [Reported SupplierID], dbo.StoreTransactions.DivisionIdentifier, dbo.StoreTransactions.PONo, 
                      dbo.Suppliers.SupplierName, dbo.Stores.StoreIdentifier AS [Store Number], dbo.Chains.ChainName, dbo.Products.ProductName
FROM         dbo.StoreTransactions INNER JOIN
                      dbo.Chains ON dbo.StoreTransactions.ChainID = dbo.Chains.ChainID INNER JOIN
                      dbo.Products ON dbo.StoreTransactions.ProductID = dbo.Products.ProductID INNER JOIN
                      dbo.Suppliers ON dbo.StoreTransactions.SupplierID = dbo.Suppliers.SupplierID INNER JOIN
                      dbo.Stores ON dbo.StoreTransactions.StoreID = dbo.Stores.StoreID LEFT OUTER JOIN
                      dbo.ProductPrices_Costs AS ProductPrices_Costs ON dbo.StoreTransactions.ProductPriceTypeID = ProductPrices_Costs.ProductPriceTypeID AND 
                      dbo.StoreTransactions.BrandID = ProductPrices_Costs.BrandID AND dbo.StoreTransactions.SupplierID = ProductPrices_Costs.SupplierID AND 
                      dbo.StoreTransactions.StoreID = ProductPrices_Costs.StoreID AND dbo.StoreTransactions.ChainID = ProductPrices_Costs.ChainID AND 
                      dbo.StoreTransactions.ProductID = ProductPrices_Costs.ProductID AND 
                      ProductPrices_Costs.UnitPrice <> dbo.StoreTransactions.ReportedCost + dbo.StoreTransactions.ReportedAllowance
WHERE     (dbo.StoreTransactions.SaleDateTime BETWEEN ProductPrices_Costs.ActiveStartDate AND ProductPrices_Costs.ActiveLastDate) AND 
                      (dbo.StoreTransactions.SaleDateTime >= '12/1/2011') AND (dbo.StoreTransactions.ChainID = 40393)
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[42] 4[25] 2[16] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1[50] 4[25] 3) )"
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
               Top = 0
               Left = 468
               Bottom = 177
               Right = 664
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Chains"
            Begin Extent = 
               Top = 8
               Left = 807
               Bottom = 116
               Right = 1054
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Products"
            Begin Extent = 
               Top = 173
               Left = 787
               Bottom = 281
               Right = 967
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Suppliers"
            Begin Extent = 
               Top = 221
               Left = 373
               Bottom = 329
               Right = 553
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Stores"
            Begin Extent = 
               Top = 237
               Left = 557
               Bottom = 345
               Right = 737
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ProductPrices_Costs"
            Begin Extent = 
               Top = 2
               Left = 0
               Bottom = 214
               Right = 220
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
      Begin ColumnWidths = 62
         Width = 284
         Width = 1590
      ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'CostDifferences_Costs_OLD'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'   Width = 1320
         Width = 1500
         Width = 1695
         Width = 1500
         Width = 465
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 660
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
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 10920
         Alias = 2760
         Table = 1530
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'CostDifferences_Costs_OLD'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'CostDifferences_Costs_OLD'
GO
