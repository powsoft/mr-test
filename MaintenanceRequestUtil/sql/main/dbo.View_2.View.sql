USE [DataTrue_Main]
GO
/****** Object:  View [dbo].[View_2]    Script Date: 06/25/2015 18:26:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[View_2]
AS
SELECT     dbo.Chains.ChainID, dbo.[InventoryCount_MAIN REPORT].ChainName, dbo.[InventoryCount_MAIN REPORT].SupplierName, 
                      dbo.[InventoryCount_MAIN REPORT].StoreNumber, dbo.[InventoryCount_MAIN REPORT].Banner, dbo.[InventoryCount_MAIN REPORT].[Last Count Date], 
                      dbo.[InventoryCount_MAIN REPORT].[BI Date], dbo.[InventoryCount_MAIN REPORT].[BI Count], dbo.[InventoryCount_MAIN REPORT].[BI $], 
                      dbo.[InventoryCount_MAIN REPORT].[Total Deliveries], dbo.[InventoryCount_MAIN REPORT].[Total Deliveries$], dbo.[InventoryCount_MAIN REPORT].[Total POS], 
                      dbo.[InventoryCount_MAIN REPORT].[Total POS$], dbo.[InventoryCount_MAIN REPORT].[Expected EI], dbo.[InventoryCount_MAIN REPORT].[Expected EI$], 
                      dbo.[InventoryCount_MAIN REPORT].[Last Count], dbo.[InventoryCount_MAIN REPORT].[Last Count$], dbo.[InventoryCount_MAIN REPORT].[Shrink Units], 
                      dbo.[InventoryCount_MAIN REPORT].[Shrink $]
FROM         dbo.[InventoryCount_MAIN REPORT] INNER JOIN
                      dbo.Chains ON dbo.[InventoryCount_MAIN REPORT].ChainName = dbo.Chains.ChainName INNER JOIN
                      dbo.Suppliers ON dbo.[InventoryCount_MAIN REPORT].SupplierName = dbo.Suppliers.SupplierName INNER JOIN
                      dbo.PersonsAssociation ON dbo.Chains.ChainID = dbo.PersonsAssociation.ChainIDOrSupplierID INNER JOIN
                      dbo.Stores ON dbo.Chains.ChainID = dbo.Stores.ChainID AND dbo.[InventoryCount_MAIN REPORT].StoreNumber = dbo.Stores.StoreIdentifier AND 
                      dbo.[InventoryCount_MAIN REPORT].Banner = dbo.Stores.Custom1
WHERE     (dbo.PersonsAssociation.PersonID = 40384)
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[26] 4[36] 2[21] 3) )"
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
         Begin Table = "InventoryCount_MAIN REPORT"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 190
               Right = 197
            End
            DisplayFlags = 280
            TopColumn = 9
         End
         Begin Table = "PersonsAssociation"
            Begin Extent = 
               Top = 6
               Left = 235
               Bottom = 99
               Right = 414
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Suppliers"
            Begin Extent = 
               Top = 6
               Left = 452
               Bottom = 114
               Right = 632
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Chains"
            Begin Extent = 
               Top = 145
               Left = 231
               Bottom = 253
               Right = 478
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Stores"
            Begin Extent = 
               Top = 76
               Left = 571
               Bottom = 207
               Right = 751
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
         Column = 1440
   ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_2'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'      Alias = 900
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_2'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_2'
GO
