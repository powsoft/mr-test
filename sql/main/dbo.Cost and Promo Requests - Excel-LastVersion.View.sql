USE [DataTrue_Main]
GO
/****** Object:  View [dbo].[Cost and Promo Requests - Excel-LastVersion]    Script Date: 06/25/2015 18:26:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Cost and Promo Requests - Excel-LastVersion]
AS
SELECT     TOP (100) PERCENT dbo.MaintenanceRequests.MaintenanceRequestID AS RequestID, dbo.Stores.Custom1 AS Banner, 
                      dbo.MaintananceRequestsTypes.RequestTypeDescription, dbo.Suppliers.SupplierName, CASE WHEN custom4 IS NULL 
                      THEN [StoreName] ELSE custom4 END AS [Store Name], dbo.Stores.StoreIdentifier AS [Store Number], dbo.Stores.Custom2 AS [SBT Number], 
                      dbo.MaintenanceRequests.UPC, dbo.MaintenanceRequests.ItemDescription, dbo.MaintenanceRequests.Cost, dbo.MaintenanceRequests.PromoAllowance, 
                      dbo.MaintenanceRequests.StartDateTime AS StartDate, dbo.MaintenanceRequests.EndDateTime AS EndDate
FROM         dbo.MaintananceRequestsTypes INNER JOIN
                      dbo.MaintenanceRequests INNER JOIN
                      dbo.Suppliers ON dbo.MaintenanceRequests.SupplierID = dbo.Suppliers.SupplierID ON 
                      dbo.MaintananceRequestsTypes.RequestType = dbo.MaintenanceRequests.RequestTypeID LEFT OUTER JOIN
                      dbo.Stores LEFT OUTER JOIN
                      dbo.MaintenanceRequestStores ON dbo.Stores.StoreID = dbo.MaintenanceRequestStores.StoreID ON 
                      dbo.MaintenanceRequests.MaintenanceRequestID = dbo.MaintenanceRequestStores.MaintenanceRequestID
WHERE     (dbo.MaintenanceRequests.StartDateTime >= CONVERT(DATETIME, '2011-12-01 00:00:00', 102)) AND (dbo.MaintenanceRequests.Approved = 1) AND 
                      (dbo.Stores.Custom1 LIKE N'Shop%Save%')
ORDER BY Banner, dbo.MaintananceRequestsTypes.RequestTypeDescription, dbo.Suppliers.SupplierName
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[41] 4[20] 2[10] 3) )"
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
               Left = 38
               Bottom = 122
               Right = 316
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "MaintenanceRequestStores"
            Begin Extent = 
               Top = 123
               Left = 380
               Bottom = 216
               Right = 614
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Suppliers"
            Begin Extent = 
               Top = 6
               Left = 556
               Bottom = 114
               Right = 757
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Stores"
            Begin Extent = 
               Top = 78
               Left = 801
               Bottom = 186
               Right = 981
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "MaintananceRequestsTypes"
            Begin Extent = 
               Top = 130
               Left = 91
               Bottom = 223
               Right = 317
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
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Cost and Promo Requests - Excel-LastVersion'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N' = 1500
         Width = 1500
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Cost and Promo Requests - Excel-LastVersion'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Cost and Promo Requests - Excel-LastVersion'
GO
