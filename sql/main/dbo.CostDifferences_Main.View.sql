USE [DataTrue_Main]
GO
/****** Object:  View [dbo].[CostDifferences_Main]    Script Date: 06/25/2015 18:26:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[CostDifferences_Main]
AS
SELECT     dbo.Stores.Custom1 AS Banner, dbo.Stores.StoreIdentifier AS [Store Number], dbo.Stores.Custom2 AS [SBT Number], dbo.Suppliers.SupplierName, 
                      dbo.Products.ProductName, dbo.CostDifferences_Costs.UPC, dbo.CostDifferences_Costs.Qty, dbo.CostDifferences_Costs.[Retailer Cost], 
                      dbo.CostDifferences_Costs.[Setup Cost], dbo.CostDifferences_Promotions.[Retailer Allowance], dbo.CostDifferences_Promotions.[Setup Allowance], 
                      dbo.CostDifferences_Costs.SaleDateTime, (dbo.CostDifferences_Costs.[Retailer Cost] - ISNULL(dbo.CostDifferences_Promotions.[Retailer Allowance], 0)) 
                      - (dbo.CostDifferences_Costs.[Setup Cost] - ISNULL(dbo.CostDifferences_Promotions.[Setup Allowance], 0)) AS [TTL Difference]
FROM         dbo.CostDifferences_Costs INNER JOIN
                      dbo.Products ON dbo.CostDifferences_Costs.ProductID = dbo.Products.ProductID INNER JOIN
                      dbo.Stores ON dbo.CostDifferences_Costs.StoreID = dbo.Stores.StoreID INNER JOIN
                      dbo.Suppliers ON dbo.CostDifferences_Costs.SupplierID = dbo.Suppliers.SupplierID LEFT OUTER JOIN
                      dbo.CostDifferences_Promotions ON dbo.CostDifferences_Costs.StoreID = dbo.CostDifferences_Promotions.StoreID AND 
                      dbo.CostDifferences_Costs.ProductID = dbo.CostDifferences_Promotions.ProductID AND 
                      dbo.CostDifferences_Costs.SupplierID = dbo.CostDifferences_Promotions.SupplierID AND 
                      dbo.CostDifferences_Costs.SaleDateTime = dbo.CostDifferences_Promotions.SaleDateTime
WHERE     ((dbo.CostDifferences_Costs.[Retailer Cost] - ISNULL(dbo.CostDifferences_Promotions.[Retailer Allowance], 0)) 
                      - (dbo.CostDifferences_Costs.[Setup Cost] - ISNULL(dbo.CostDifferences_Promotions.[Setup Allowance], 0)) <> 0)
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[35] 4[10] 2[16] 3) )"
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
         Begin Table = "CostDifferences_Costs"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 230
               Right = 209
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Products"
            Begin Extent = 
               Top = 6
               Left = 453
               Bottom = 114
               Right = 633
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Stores"
            Begin Extent = 
               Top = 6
               Left = 671
               Bottom = 225
               Right = 851
            End
            DisplayFlags = 280
            TopColumn = 8
         End
         Begin Table = "Suppliers"
            Begin Extent = 
               Top = 6
               Left = 889
               Bottom = 114
               Right = 1069
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "CostDifferences_Promotions"
            Begin Extent = 
               Top = 86
               Left = 406
               Bottom = 304
               Right = 574
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
      Begin ColumnWidths = 14
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 465
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'CostDifferences_Main'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'   Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 4455
         Alias = 1215
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'CostDifferences_Main'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'CostDifferences_Main'
GO
