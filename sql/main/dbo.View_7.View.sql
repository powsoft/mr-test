USE [DataTrue_Main]
GO
/****** Object:  View [dbo].[View_7]    Script Date: 06/25/2015 18:26:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[View_7]
AS
SELECT     dbo.CurrentPromotions_ViewALL.ChainName, dbo.CurrentPromotions_ViewALL.Banner, dbo.CurrentPromotions_ViewALL.SupplierName, 
                      dbo.CurrentPromotions_ViewALL.ProductName, dbo.CurrentPromotions_ViewALL.[Store Number], dbo.CurrentPromotions_ViewALL.UPC, 
                      dbo.CurrentPromotions_ViewALL.Allowance, dbo.CurrentPromotions_ViewALL.[Begin Date], dbo.CurrentPromotions_ViewALL.[End Date], 
                      dbo.ProductPrices.UnitPrice AS [Base Cost], dbo.ProductPrices.UnitRetail AS [Base Retail], CONVERT(varchar(10), dbo.ProductPrices.ActiveStartDate, 101) 
                      AS [Base Begin], CONVERT(varchar(10), dbo.ProductPrices.ActiveLastDate, 101) AS [Base End]
FROM         dbo.CurrentPromotions_ViewALL INNER JOIN
                      dbo.ProductPrices ON dbo.CurrentPromotions_ViewALL.StoreID = dbo.ProductPrices.StoreID AND 
                      dbo.CurrentPromotions_ViewALL.SupplierID = dbo.ProductPrices.SupplierID AND dbo.CurrentPromotions_ViewALL.BrandID = dbo.ProductPrices.BrandID AND 
                      dbo.CurrentPromotions_ViewALL.ProductID = dbo.ProductPrices.ProductID
WHERE     (dbo.ProductPrices.ProductPriceTypeID = 3) AND (dbo.ProductPrices.ActiveStartDate <= { fn NOW() }) AND (dbo.ProductPrices.ActiveLastDate >= { fn NOW() }) AND 
                      (dbo.CurrentPromotions_ViewALL.SupplierID = 40559)
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
         Begin Table = "CurrentPromotions_ViewALL"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 198
               Right = 234
            End
            DisplayFlags = 280
            TopColumn = 9
         End
         Begin Table = "ProductPrices"
            Begin Extent = 
               Top = 8
               Left = 440
               Bottom = 202
               Right = 660
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_7'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_7'
GO
