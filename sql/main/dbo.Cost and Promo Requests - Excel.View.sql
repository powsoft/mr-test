USE [DataTrue_Main]
GO
/****** Object:  View [dbo].[Cost and Promo Requests - Excel]    Script Date: 06/25/2015 18:26:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Cost and Promo Requests - Excel]
AS
SELECT     TOP (100) PERCENT dbo.MaintenanceRequests.MaintenanceRequestID AS RequestID, dbo.Stores.Custom1 AS Banner, 
                      dbo.MaintananceRequestsTypes.RequestTypeDescription, dbo.Suppliers.SupplierName, CASE WHEN custom4 IS NULL 
                      THEN [StoreName] ELSE custom4 END AS [Store Name], dbo.Stores.StoreIdentifier AS [Store Number], dbo.Stores.Custom2 AS [SBT Number], 
                      dbo.MaintenanceRequests.UPC, dbo.MaintenanceRequests.ItemDescription, dbo.MaintenanceRequests.Cost, dbo.MaintenanceRequests.PromoAllowance, 
                      dbo.MaintenanceRequests.StartDateTime AS StartDate, dbo.MaintenanceRequests.EndDateTime AS EndDate
FROM         dbo.MaintenanceRequests INNER JOIN
                      dbo.MaintenanceRequestStores ON dbo.MaintenanceRequests.MaintenanceRequestID = dbo.MaintenanceRequestStores.MaintenanceRequestID INNER JOIN
                      dbo.Suppliers ON dbo.MaintenanceRequests.SupplierID = dbo.Suppliers.SupplierID INNER JOIN
                      dbo.Stores ON dbo.MaintenanceRequestStores.StoreID = dbo.Stores.StoreID INNER JOIN
                      dbo.MaintananceRequestsTypes ON dbo.MaintenanceRequests.RequestTypeID = dbo.MaintananceRequestsTypes.RequestType
WHERE     (dbo.MaintenanceRequests.StartDateTime >= CONVERT(DATETIME, '2011-12-01 00:00:00', 102)) AND (dbo.MaintenanceRequests.Approved = 1)
ORDER BY Banner, dbo.MaintananceRequestsTypes.RequestTypeDescription, dbo.Suppliers.SupplierName
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[36] 4[19] 2[16] 3) )"
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
         Begin Table = "MaintenanceRequests"
            Begin Extent = 
               Top = 6
               Left = 0
               Bottom = 183
               Right = 173
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "MaintenanceRequestStores"
            Begin Extent = 
               Top = 187
               Left = 358
               Bottom = 329
               Right = 550
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Suppliers"
            Begin Extent = 
               Top = 24
               Left = 544
               Bottom = 132
               Right = 724
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Stores"
            Begin Extent = 
               Top = 142
               Left = 594
               Bottom = 250
               Right = 774
            End
            DisplayFlags = 280
            TopColumn = 1
         End
         Begin Table = "MaintananceRequestsTypes"
            Begin Extent = 
               Top = 195
               Left = 108
               Bottom = 288
               Right = 305
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
         Width = 2655
         Width = 1950
         Width = 1500
         Width = 1500
         Width = 3810
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Wid' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Cost and Promo Requests - Excel'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'th = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 5175
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Cost and Promo Requests - Excel'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Cost and Promo Requests - Excel'
GO
