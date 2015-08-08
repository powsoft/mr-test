USE [DataTrue_Main]
GO
/****** Object:  View [dbo].[CurrentPromotions_ViewALL-Gilad]    Script Date: 06/25/2015 18:26:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[CurrentPromotions_ViewALL-Gilad]
AS
SELECT     TOP (100) PERCENT dbo.Suppliers.SupplierName, dbo.Products.ProductName, dbo.Stores.StoreIdentifier AS [Store Number], 
                      dbo.ProductIdentifiers.IdentifierValue AS UPC, dbo.ProductPrices.UnitPrice AS Allowance, dbo.ProductPrices.UnitRetail AS [Allowance Retail], CONVERT(VARCHAR(10), 
                      dbo.ProductPrices.ActiveStartDate, 101) AS [Begin Date], CONVERT(VARCHAR(10), dbo.ProductPrices.ActiveLastDate, 101) AS [End Date], 
                      dbo.ProductIdentifiers.ProductIdentifierTypeID, dbo.Chains.ChainName, dbo.Stores.Custom1 AS Banner
FROM         dbo.ProductPrices INNER JOIN
                      dbo.Suppliers ON dbo.ProductPrices.SupplierID = dbo.Suppliers.SupplierID INNER JOIN
                      dbo.Products ON dbo.ProductPrices.ProductID = dbo.Products.ProductID INNER JOIN
                      dbo.ProductIdentifiers ON dbo.Products.ProductID = dbo.ProductIdentifiers.ProductID INNER JOIN
                      dbo.Brands ON dbo.ProductPrices.BrandID = dbo.Brands.BrandID INNER JOIN
                      dbo.Stores ON dbo.ProductPrices.StoreID = dbo.Stores.StoreID INNER JOIN
                      dbo.Chains ON dbo.Stores.ChainID = dbo.Chains.ChainID
WHERE     (dbo.ProductPrices.ProductPriceTypeID = 8) AND (NOT (dbo.Stores.Custom1 LIKE N'Shop N Save Warehouse Foods Inc')) AND 
                      (dbo.ProductIdentifiers.ProductIdentifierTypeID = 2)
ORDER BY dbo.Chains.ChainName
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[41] 4[20] 2[13] 3) )"
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
      ActivePaneConfig = 1
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "ProductPrices"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 114
               Right = 282
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Suppliers"
            Begin Extent = 
               Top = 6
               Left = 320
               Bottom = 114
               Right = 521
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Products"
            Begin Extent = 
               Top = 6
               Left = 559
               Bottom = 114
               Right = 739
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ProductIdentifiers"
            Begin Extent = 
               Top = 6
               Left = 777
               Bottom = 114
               Right = 973
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Brands"
            Begin Extent = 
               Top = 114
               Left = 38
               Bottom = 222
               Right = 218
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Stores"
            Begin Extent = 
               Top = 114
               Left = 256
               Bottom = 222
               Right = 436
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Chains"
            Begin Extent = 
               Top = 114
               Left = 474
               Bottom = 222
               Right = 721
            End
            Displa' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'CurrentPromotions_ViewALL-Gilad'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'yFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
      PaneHidden = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 19
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
         Column = 2145
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 3645
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'CurrentPromotions_ViewALL-Gilad'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'CurrentPromotions_ViewALL-Gilad'
GO
