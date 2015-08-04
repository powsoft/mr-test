USE [DataTrue_Main]
GO
/****** Object:  View [dbo].[CurrentPromotions_FUTURE]    Script Date: 06/25/2015 18:26:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[CurrentPromotions_FUTURE]
AS
SELECT     dbo.Suppliers.SupplierName, dbo.Products.ProductName, dbo.Brands.BrandName, dbo.Stores.StoreIdentifier AS [Store Number], 
                      dbo.Stores.StoreName AS [Store Name], dbo.Stores.Custom2 AS [SBT Number], dbo.ProductIdentifiers.IdentifierValue AS UPC, 
                      dbo.ProductPrices.UnitPrice AS Allowance, dbo.ProductPrices.UnitRetail AS [Allowance Retail], dbo.ProductPrices.PricePriority, 
                      CAST(dbo.ProductPrices.ActiveStartDate AS datetime) AS [Begin Date], CONVERT(VARCHAR(10), dbo.ProductPrices.ActiveLastDate, 101) AS [End Date], 
                      dbo.Stores.StoreID, dbo.Stores.ChainID, dbo.Suppliers.SupplierID, dbo.ProductIdentifiers.ProductIdentifierTypeID, dbo.Brands.BrandID, 
                      dbo.ProductIdentifiers.ProductID, dbo.Chains.ChainName, dbo.Stores.Custom1 AS Banner
FROM         dbo.ProductPrices INNER JOIN
                      dbo.Suppliers ON dbo.ProductPrices.SupplierID = dbo.Suppliers.SupplierID INNER JOIN
                      dbo.Products ON dbo.ProductPrices.ProductID = dbo.Products.ProductID INNER JOIN
                      dbo.ProductIdentifiers ON dbo.Products.ProductID = dbo.ProductIdentifiers.ProductID INNER JOIN
                      dbo.Brands ON dbo.ProductPrices.BrandID = dbo.Brands.BrandID INNER JOIN
                      dbo.Stores ON dbo.ProductPrices.StoreID = dbo.Stores.StoreID INNER JOIN
                      dbo.Chains ON dbo.Stores.ChainID = dbo.Chains.ChainID
WHERE     (dbo.ProductPrices.ProductPriceTypeID = 8) AND (dbo.ProductPrices.ActiveStartDate > CONVERT(varchar(10), GETDATE(), 101)) AND 
                      (dbo.ProductPrices.ActiveLastDate >= CONVERT(varchar(10), GETDATE(), 101)) AND (dbo.Stores.ActiveStatus = 'Active') AND 
                      (dbo.ProductIdentifiers.ProductIdentifierTypeID = 2)
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[29] 4[32] 2[20] 3) )"
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
               Top = 7
               Left = 48
               Bottom = 135
               Right = 297
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Suppliers"
            Begin Extent = 
               Top = 7
               Left = 345
               Bottom = 135
               Right = 547
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Products"
            Begin Extent = 
               Top = 7
               Left = 595
               Bottom = 135
               Right = 797
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ProductIdentifiers"
            Begin Extent = 
               Top = 140
               Left = 48
               Bottom = 268
               Right = 266
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Brands"
            Begin Extent = 
               Top = 140
               Left = 314
               Bottom = 268
               Right = 516
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Stores"
            Begin Extent = 
               Top = 140
               Left = 564
               Bottom = 268
               Right = 766
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Chains"
            Begin Extent = 
               Top = 273
               Left = 48
               Bottom = 401
               Right = 330
            End
            Disp' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'CurrentPromotions_FUTURE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'layFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 20
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
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 3015
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'CurrentPromotions_FUTURE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'CurrentPromotions_FUTURE'
GO
