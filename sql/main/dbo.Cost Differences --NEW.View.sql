USE [DataTrue_Main]
GO
/****** Object:  View [dbo].[Cost Differences --NEW]    Script Date: 06/25/2015 18:26:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Cost Differences --NEW]
AS
SELECT     dbo.StoreTransactions.SetupCost AS [Setup: Gross Cost], dbo.StoreTransactions.RuleCost AS [Billed: Gross Cost], 
                      dbo.StoreTransactions.ReportedCost + dbo.StoreTransactions.ReportedAllowance AS [852 Cost: Gross Cost], 
                      dbo.StoreTransactions.RuleCost - (dbo.StoreTransactions.ReportedCost + dbo.StoreTransactions.ReportedAllowance) AS [Difference: Cost], 
                      dbo.StoreTransactions.PromoAllowance AS [Setup: Promo], dbo.StoreTransactions.PromoAllowance AS [Billed: Promo], 
                      dbo.StoreTransactions.ReportedAllowance AS [852:  Promo], 
                      dbo.StoreTransactions.ReportedAllowance - dbo.StoreTransactions.PromoAllowance AS [Difference: Promo], 
                      (dbo.StoreTransactions.RuleCost - (dbo.StoreTransactions.ReportedCost + dbo.StoreTransactions.ReportedAllowance)) 
                      + (dbo.StoreTransactions.ReportedAllowance - dbo.StoreTransactions.PromoAllowance) AS [Difference: Total], dbo.StoreTransactions.Qty, 
                      dbo.StoreTransactions.UPC AS [Standard UPC], dbo.StoreTransactions.RawProductIdentifier AS [Reported UPC], 
                      dbo.StoreTransactions.SupplierName AS [Reported Supplier Name], dbo.StoreTransactions.SupplierIdentifier AS [Reported SupplierID], dbo.Suppliers.SupplierName, 
                      dbo.Stores.StoreIdentifier AS [Store Number], dbo.Chains.ChainName, dbo.Stores.Custom1 AS Banner, dbo.Products.ProductName, CONVERT(varchar(10), 
                      dbo.StoreTransactions.SaleDateTime, 101) AS [Sale Date]
FROM         dbo.StoreTransactions INNER JOIN
                      dbo.Chains ON dbo.StoreTransactions.ChainID = dbo.Chains.ChainID INNER JOIN
                      dbo.Products ON dbo.StoreTransactions.ProductID = dbo.Products.ProductID INNER JOIN
                      dbo.Suppliers ON dbo.StoreTransactions.SupplierID = dbo.Suppliers.SupplierID INNER JOIN
                      dbo.Stores ON dbo.StoreTransactions.StoreID = dbo.Stores.StoreID
WHERE     (dbo.StoreTransactions.SaleDateTime >= '12/1/2011') AND (dbo.StoreTransactions.ChainID = 40393) AND 
                      ((dbo.StoreTransactions.RuleCost - (dbo.StoreTransactions.ReportedCost + dbo.StoreTransactions.ReportedAllowance)) 
                      + (dbo.StoreTransactions.ReportedAllowance - dbo.StoreTransactions.PromoAllowance) <> 0)
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[38] 4[29] 2[14] 3) )"
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
         Top = -248
         Left = 0
      End
      Begin Tables = 
         Begin Table = "StoreTransactions"
            Begin Extent = 
               Top = 274
               Left = 37
               Bottom = 536
               Right = 233
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Chains"
            Begin Extent = 
               Top = 294
               Left = 272
               Bottom = 402
               Right = 519
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Products"
            Begin Extent = 
               Top = 294
               Left = 557
               Bottom = 402
               Right = 737
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Suppliers"
            Begin Extent = 
               Top = 294
               Left = 775
               Bottom = 402
               Right = 955
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Stores"
            Begin Extent = 
               Top = 294
               Left = 993
               Bottom = 402
               Right = 1173
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
      Begin ColumnWidths = 21
         Width = 284
         Width = 1860
         Width = 1605
         Width = 1935
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Cost Differences --NEW'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'1500
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
         Column = 12000
         Alias = 3195
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 765
         SortOrder = 870
         GroupBy = 1350
         Filter = 1320
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Cost Differences --NEW'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Cost Differences --NEW'
GO
