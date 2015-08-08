USE [DataTrue_Main]
GO
/****** Object:  View [dbo].[Login Info-Chain Users]    Script Date: 06/25/2015 18:26:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Login Info-Chain Users]
AS
SELECT     TOP (100) PERCENT dbo.Persons.PersonID, dbo.Persons.FirstName, dbo.Persons.LastName, dbo.Logins.Login, dbo.Logins.Password, dbo.Chains.ChainName, 
                      dbo.AttributeValues.AttributeValue AS [Banner Access], dbo.Chains.ChainID
FROM         dbo.PersonsAssociation INNER JOIN
                      dbo.Persons ON dbo.PersonsAssociation.PersonID = dbo.Persons.PersonID INNER JOIN
                      dbo.Logins ON dbo.Persons.PersonID = dbo.Logins.OwnerEntityId INNER JOIN
                      dbo.Chains ON dbo.PersonsAssociation.ChainIDOrSupplierID = dbo.Chains.ChainID INNER JOIN
                      dbo.AttributeValues ON dbo.PersonsAssociation.PersonID = dbo.AttributeValues.OwnerEntityID
WHERE     (dbo.AttributeValues.AttributeID = 20)
ORDER BY dbo.Persons.LastName, dbo.Persons.FirstName
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
         Configuration = "(H (1[50] 4[25] 3) )"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1[50] 2[25] 3) )"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1[56] 3) )"
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
         Configuration = "(H (1[45] 4) )"
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
      ActivePaneConfig = 9
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "PersonsAssociation"
            Begin Extent = 
               Top = 6
               Left = 474
               Bottom = 147
               Right = 653
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Persons"
            Begin Extent = 
               Top = 6
               Left = 256
               Bottom = 114
               Right = 436
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Logins"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 114
               Right = 218
            End
            DisplayFlags = 280
            TopColumn = 2
         End
         Begin Table = "Chains"
            Begin Extent = 
               Top = 6
               Left = 691
               Bottom = 114
               Right = 938
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "AttributeValues"
            Begin Extent = 
               Top = 125
               Left = 129
               Bottom = 233
               Right = 309
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
      PaneHidden = 
   End
   Begin DataPane = 
      PaneHidden = 
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Login Info-Chain Users'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'         Column = 1440
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Login Info-Chain Users'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Login Info-Chain Users'
GO
