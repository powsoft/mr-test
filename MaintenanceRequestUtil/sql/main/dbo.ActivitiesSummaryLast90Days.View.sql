USE [DataTrue_Main]
GO
/****** Object:  View [dbo].[ActivitiesSummaryLast90Days]    Script Date: 06/25/2015 18:26:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*Deliveries*/
CREATE VIEW [dbo].[ActivitiesSummaryLast90Days]
AS
SELECT     ISNULL(D.StoreID, Po.StoreID) AS StoreID, ISNULL(D.ProductID, Po.ProductID) AS ProductID, ISNULL(D.SupplierID, Po.SupplierID) AS SupplierID, ISNULL(D.Deliveries, 
                      0) AS Deliveries, ISNULL(D.Credits, 0) AS Credits, ISNULL(D.NetDeliveries, 0) AS NetDeliveries, ISNULL(Po.POSQnt, 0) AS POS, ISNULL(D.FirstActivityDate, 
                      Po.PFirstActivityDate) AS FirstActivityDate, ISNULL(D.WeeksSinceFirstActivity, Po.PWeeksSinceFirstActivity) AS WeeksSinceFirstActivity, ISNULL(Po.POSQnt, 0) 
                      / ISNULL(D.WeeksSinceFirstActivity, Po.PWeeksSinceFirstActivity) AS WeeklyMovement, ISNULL(D.NetDeliveries, 0) / ISNULL(D.WeeksSinceFirstActivity, 
                      Po.PWeeksSinceFirstActivity) AS WeeklyDelivery
FROM         (SELECT     ISNULL(D_1.StoreID, P.StoreID) AS StoreID, ISNULL(D_1.ProductID, P.ProductID) AS ProductID, ISNULL(D_1.SupplierID, P.SupplierID) AS SupplierID, 
                                              ISNULL(D_1.DeliveryQnt, 0) AS Deliveries, ISNULL(P.CreditQnt, 0) AS Credits, ISNULL(ISNULL(D_1.DeliveryQnt, 0) + ISNULL(P.CreditQnt, 0), 0) 
                                              AS NetDeliveries, ISNULL(D_1.FirstActivityDate, P.PFirstActivityDate) AS FirstActivityDate, ISNULL(D_1.WeeksSinceFirstActivity, 
                                              P.PWeeksSinceFirstActivity) AS WeeksSinceFirstActivity
                       FROM          (SELECT     S.StoreID, S.SupplierID, S.ProductID, SUM(S.Qty) AS DeliveryQnt, MIN(S.SaleDateTime) AS FirstActivityDate, CONVERT(integer, GETDATE() 
                                                                      - MIN(S.SaleDateTime)) / 7 AS WeeksSinceFirstActivity
                                               FROM          dbo.StoreTransactions AS S INNER JOIN
                                                                      dbo.TransactionTypes AS t ON t.TransactionTypeID = S.TransactionTypeID
                                               WHERE      (S.SaleDateTime >= GETDATE() - 90) AND (t.TransactionTypeName LIKE '%deliver%')
                                               GROUP BY S.StoreID, S.SupplierID, S.ProductID) AS D_1 FULL OUTER JOIN
                                                  (SELECT     S.StoreID, S.SupplierID, S.ProductID, - SUM(S.Qty) AS CreditQnt, MIN(S.SaleDateTime) AS PFirstActivityDate, CONVERT(integer, GETDATE() 
                                                                           - MIN(S.SaleDateTime)) / 7 AS PWeeksSinceFirstActivity
                                                    FROM          dbo.StoreTransactions AS S INNER JOIN
                                                                           dbo.TransactionTypes AS t ON t.TransactionTypeID = S.TransactionTypeID
                                                    WHERE      (S.SaleDateTime >= GETDATE() - 90) AND (t.TransactionTypeName LIKE '%pickup%')
                                                    GROUP BY S.StoreID, S.SupplierID, S.ProductID) AS P ON D_1.ProductID = P.ProductID AND D_1.StoreID = P.StoreID AND D_1.SupplierID = P.SupplierID) 
                      AS D FULL OUTER JOIN
                          (SELECT     S.StoreID, S.SupplierID, S.ProductID, SUM(S.Qty) AS POSQnt, MIN(S.SaleDateTime) AS PFirstActivityDate, CONVERT(integer, GETDATE() 
                                                   - MIN(S.SaleDateTime)) / 7 AS PWeeksSinceFirstActivity
                            FROM          dbo.StoreTransactions AS S INNER JOIN
                                                   dbo.TransactionTypes AS t ON t.TransactionTypeID = S.TransactionTypeID
                            WHERE      (S.SaleDateTime >= GETDATE() - 90) AND (t.TransactionTypeName LIKE '%POS%')
                            GROUP BY S.StoreID, S.SupplierID, S.ProductID
                            HAVING      (SUM(S.Qty) <> 0)) AS Po ON Po.ProductID = D.ProductID AND Po.StoreID = D.StoreID AND Po.SupplierID = D.SupplierID
WHERE     (ISNULL(D.WeeksSinceFirstActivity, Po.PWeeksSinceFirstActivity) <> 0)
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
         Begin Table = "D"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 114
               Right = 232
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Po"
            Begin Extent = 
               Top = 6
               Left = 270
               Bottom = 114
               Right = 470
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
      Begin ColumnWidths = 11
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ActivitiesSummaryLast90Days'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ActivitiesSummaryLast90Days'
GO
