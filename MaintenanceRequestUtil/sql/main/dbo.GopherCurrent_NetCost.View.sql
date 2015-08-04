USE [DataTrue_Main]
GO
/****** Object:  View [dbo].[GopherCurrent_NetCost]    Script Date: 06/25/2015 18:26:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[GopherCurrent_NetCost]
AS
SELECT     1 AS Expr1, { fn NOW() } AS SubmitDate, 2 AS Type, dbo.Stores.ChainID, dbo.GopherCurrentPromo.SupplierID, dbo.Stores.Custom1 AS Banner, 1 AS AllStores, 
                      dbo.GopherCurrentPromo.UPC, '' AS Brand, '' AS ItemDesc, dbo.GopherCurrentCosts.UnitPrice AS CurrentCost, 
                      dbo.GopherCurrentCosts.UnitPrice - dbo.GopherCurrentPromo.Promo AS NetCost, 0 AS Retail, 0 AS PromoType, 0 AS PromoAll, { fn NOW() } AS Startdate, 
                      dbo.GopherCurrentCosts.LastDate AS EndDate, 40384 AS RequestID, 40384 AS ChainLogin, 1 AS Approved, { fn NOW() } AS AppDate, NULL AS [1], NULL AS [2], NULL 
                      AS [3], NULL AS [4], NULL AS [5], NULL AS [6], NULL AS [7], NULL AS [8], NULL AS [9], NULL AS [0], NULL AS [11], NULL AS [12], NULL AS [13], NULL AS [14], NULL 
                      AS [15], NULL AS [16], { fn NOW() } AS [17], 1 AS SkipPopulating, 1 AS SkipComplete
FROM         dbo.GopherCurrentCosts INNER JOIN
                      dbo.GopherCurrentPromo ON dbo.GopherCurrentCosts.SupplierID = dbo.GopherCurrentPromo.SupplierID AND 
                      dbo.GopherCurrentCosts.UPC = dbo.GopherCurrentPromo.UPC AND dbo.GopherCurrentCosts.StoreID = dbo.GopherCurrentPromo.StoreID INNER JOIN
                      dbo.Stores ON dbo.GopherCurrentCosts.StoreID = dbo.Stores.StoreID
GROUP BY dbo.Stores.ChainID, dbo.GopherCurrentPromo.SupplierID, dbo.Stores.Custom1, dbo.GopherCurrentPromo.UPC, dbo.GopherCurrentCosts.UnitPrice, 
                      dbo.GopherCurrentCosts.UnitPrice - dbo.GopherCurrentPromo.Promo, dbo.GopherCurrentCosts.LastDate
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[26] 4[18] 2[24] 3) )"
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
         Top = -2396
         Left = 0
      End
      Begin Tables = 
         Begin Table = "GopherCurrentCosts"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 246
               Right = 213
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "GopherCurrentPromo"
            Begin Extent = 
               Top = 6
               Left = 251
               Bottom = 244
               Right = 426
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Stores"
            Begin Extent = 
               Top = 6
               Left = 464
               Bottom = 114
               Right = 644
            End
            DisplayFlags = 280
            TopColumn = 12
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 41
         Width = 284
         Width = 1500
         Width = 885
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
         W' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'GopherCurrent_NetCost'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'idth = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 1035
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'GopherCurrent_NetCost'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'GopherCurrent_NetCost'
GO
