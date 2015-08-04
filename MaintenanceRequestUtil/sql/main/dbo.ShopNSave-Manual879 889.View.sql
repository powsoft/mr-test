USE [DataTrue_Main]
GO
/****** Object:  View [dbo].[ShopNSave-Manual879/889]    Script Date: 06/25/2015 18:26:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[ShopNSave-Manual879/889]
AS
SELECT     TOP (100) PERCENT dbo.Stores.Custom1 AS Banner, dbo.Stores.StoreIdentifier AS [Store No], dbo.Stores.Custom2 AS [SBT Number], dbo.Suppliers.SupplierName, 
                      dbo.ProductIdentifiers.IdentifierValue AS UPC, CASE WHEN ProductPriceTypeID = 8 THEN 'Promo' WHEN ProductPriceTypeID = 3 THEN 'Cost' END AS [Price Type], 
                      dbo.ProductPrices.UnitPrice, CONVERT(varchar(10), dbo.ProductPrices.ActiveStartDate, 101) AS [Begin Date], CONVERT(varchar(10), dbo.ProductPrices.ActiveLastDate, 
                      101) AS [End Date]
FROM         dbo.ProductPrices INNER JOIN
                      dbo.Stores ON dbo.ProductPrices.StoreID = dbo.Stores.StoreID INNER JOIN
                      dbo.Suppliers ON dbo.ProductPrices.SupplierID = dbo.Suppliers.SupplierID INNER JOIN
                      dbo.ProductIdentifiers ON dbo.ProductPrices.ProductID = dbo.ProductIdentifiers.ProductID
WHERE     (dbo.Stores.Custom1 LIKE N'%Shop n%') AND (dbo.ProductIdentifiers.ProductIdentifierTypeID = 2) AND (dbo.ProductPrices.ActiveStartDate >= CONVERT(DATETIME, 
                      '2012-01-01 00:00:00', 102))
ORDER BY [Price Type], UPC
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
         Begin Table = "ProductPrices"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 189
               Right = 282
            End
            DisplayFlags = 280
            TopColumn = 9
         End
         Begin Table = "Stores"
            Begin Extent = 
               Top = 44
               Left = 330
               Bottom = 213
               Right = 510
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Suppliers"
            Begin Extent = 
               Top = 6
               Left = 538
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
            TopColumn = 2
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
         Begin ParameterName = "@Param1"
            ParameterValue = "1/1/2012 12:00:00 AM"
         End
      End
      Begin ColumnWidths = 11
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1725
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 2520
         Alias = 2520
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
  ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ShopNSave-Manual879/889'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'       SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ShopNSave-Manual879/889'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ShopNSave-Manual879/889'
GO
