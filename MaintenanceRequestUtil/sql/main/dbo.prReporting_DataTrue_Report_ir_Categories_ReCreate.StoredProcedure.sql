USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prReporting_DataTrue_Report_ir_Categories_ReCreate]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prReporting_DataTrue_Report_ir_Categories_ReCreate]
as

truncate table DataTrue_Report.dbo.ir_categories_Table

insert into DataTrue_Report.dbo.ir_categories_Table
SELECT     HierarchyID.GetAncestor(CASE WHEN (HierarchyID.GetLevel() - 1) >= 0 THEN HierarchyID.GetLevel() - 1 ELSE 0 END) AS level1_id, 
                      HierarchyID.GetAncestor(CASE WHEN (HierarchyID.GetLevel() - 2) >= 0 THEN HierarchyID.GetLevel() - 2 ELSE 0 END) AS level2_id, 
                      HierarchyID.GetAncestor(CASE WHEN (HierarchyID.GetLevel() - 3) >= 0 THEN HierarchyID.GetLevel() - 3 ELSE 0 END) AS level3_id, 
                      HierarchyID.GetAncestor(CASE WHEN (HierarchyID.GetLevel() - 4) >= 0 THEN HierarchyID.GetLevel() - 4 ELSE 0 END) AS level4_id, 
                      HierarchyID.GetAncestor(CASE WHEN (HierarchyID.GetLevel() - 5) >= 0 THEN HierarchyID.GetLevel() - 5 ELSE 0 END) AS level5_id, ProductCategoryID, 
                      ProductCategoryName
FROM         DataTrue_Main.dbo.ProductCategories
GO
