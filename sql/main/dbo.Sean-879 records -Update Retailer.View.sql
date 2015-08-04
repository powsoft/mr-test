USE [DataTrue_Main]
GO
/****** Object:  View [dbo].[Sean-879 records -Update Retailer]    Script Date: 06/25/2015 18:26:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Sean-879 records -Update Retailer]
AS
SELECT     dbo.Stores.StoreID, dbo.['Cost differences_41575_12211112$'].[Store Number], dbo.['Cost differences_41575_12211112$'].Banner, 
                      dbo.['Cost differences_41575_12211112$'].UPC12, dbo.['Cost differences_41575_12211112$'].[Instructions for iControl IT], 
                      dbo.['Cost differences_41575_12211112$'].[iC Setup Cost]
FROM         dbo.['Cost differences_41575_12211112$'] INNER JOIN
                      dbo.Stores ON dbo.['Cost differences_41575_12211112$'].[Store Number] = dbo.Stores.StoreIdentifier AND 
                      dbo.['Cost differences_41575_12211112$'].Banner = dbo.Stores.Custom1
WHERE     (dbo.['Cost differences_41575_12211112$'].[New Entry] = 1)
GROUP BY dbo.['Cost differences_41575_12211112$'].[Store Number], dbo.['Cost differences_41575_12211112$'].Banner, dbo.['Cost differences_41575_12211112$'].UPC12, 
                      dbo.['Cost differences_41575_12211112$'].[Instructions for iControl IT], dbo.['Cost differences_41575_12211112$'].[iC Setup Cost], 
                      dbo.['Cost differences_41575_12211112$'].[Confirmed base], dbo.['Cost differences_41575_12211112$'].[iC Setup _Net], 
                      dbo.['Cost differences_41575_12211112$'].[SV Reported_ Cost], dbo.['Cost differences_41575_12211112$'].[SV Reported _Promo], 
                      dbo.['Cost differences_41575_12211112$'].[iC Setup _Promo], 
                      dbo.['Cost differences_41575_12211112$'].[SV Reported_ Cost] + dbo.['Cost differences_41575_12211112$'].[SV Reported _Promo], dbo.Stores.StoreID
HAVING      (dbo.['Cost differences_41575_12211112$'].[Instructions for iControl IT] = N'879' OR
                      dbo.['Cost differences_41575_12211112$'].[Instructions for iControl IT] = N'both') AND 
                      (dbo.['Cost differences_41575_12211112$'].[Confirmed base] <> dbo.['Cost differences_41575_12211112$'].[SV Reported_ Cost] + dbo.['Cost differences_41575_12211112$'].[SV Reported _Promo])
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[36] 4[26] 2[21] 3) )"
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
         Begin Table = "''Cost differences_41575_12211112$''"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 114
               Right = 261
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Stores"
            Begin Extent = 
               Top = 6
               Left = 298
               Bottom = 259
               Right = 478
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
      Begin ColumnWidths = 13
         Width = 284
         Width = 1185
         Width = 1185
         Width = 1455
         Width = 2100
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1560
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 2505
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 10200
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Sean-879 records -Update Retailer'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Sean-879 records -Update Retailer'
GO
