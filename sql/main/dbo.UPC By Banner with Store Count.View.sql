USE [DataTrue_Main]
GO
/****** Object:  View [dbo].[UPC By Banner with Store Count]    Script Date: 06/25/2015 18:26:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[UPC By Banner with Store Count]
AS
SELECT     dbo.Suppliers.SupplierName, dbo.Stores.Custom1 AS Banner, dbo.Products.ProductName, dbo.ProductIdentifiers.IdentifierValue AS UPC, 
                      COUNT(dbo.StoreSetup.StoreID) AS [# of Stores Setup], dbo.NoOfStoresByBanner.[No of Stores] AS [TTL Stores In Banner]
FROM         dbo.StoreSetup INNER JOIN
                      dbo.Stores ON dbo.StoreSetup.StoreID = dbo.Stores.StoreID INNER JOIN
                      dbo.ProductIdentifiers ON dbo.StoreSetup.ProductID = dbo.ProductIdentifiers.ProductID INNER JOIN
                      dbo.NoOfStoresByBanner ON dbo.Stores.Custom1 = dbo.NoOfStoresByBanner.Banner AND dbo.Stores.ChainID = dbo.NoOfStoresByBanner.ChainID INNER JOIN
                      dbo.Products ON dbo.ProductIdentifiers.ProductID = dbo.Products.ProductID INNER JOIN
                      dbo.Suppliers ON dbo.StoreSetup.SupplierID = dbo.Suppliers.SupplierID
WHERE     (dbo.ProductIdentifiers.ProductIdentifierTypeID = 2) AND (dbo.Suppliers.SupplierID = 40558)
GROUP BY dbo.Stores.Custom1, dbo.ProductIdentifiers.IdentifierValue, dbo.NoOfStoresByBanner.[No of Stores], dbo.Products.ProductName, dbo.Suppliers.SupplierName
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
         Begin Table = "StoreSetup"
            Begin Extent = 
               Top = 12
               Left = 438
               Bottom = 252
               Right = 663
            End
            DisplayFlags = 280
            TopColumn = 12
         End
         Begin Table = "Stores"
            Begin Extent = 
               Top = 141
               Left = 222
               Bottom = 249
               Right = 402
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ProductIdentifiers"
            Begin Extent = 
               Top = 27
               Left = 68
               Bottom = 135
               Right = 264
            End
            DisplayFlags = 280
            TopColumn = 1
         End
         Begin Table = "NoOfStoresByBanner"
            Begin Extent = 
               Top = 141
               Left = 36
               Bottom = 234
               Right = 187
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Products"
            Begin Extent = 
               Top = 6
               Left = 701
               Bottom = 114
               Right = 881
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Suppliers"
            Begin Extent = 
               Top = 142
               Left = 711
               Bottom = 250
               Right = 891
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'UPC By Banner with Store Count'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1710
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1965
         Alias = 1860
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'UPC By Banner with Store Count'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'UPC By Banner with Store Count'
GO
