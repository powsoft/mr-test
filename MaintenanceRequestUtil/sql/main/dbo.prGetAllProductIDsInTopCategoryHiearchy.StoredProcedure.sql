USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetAllProductIDsInTopCategoryHiearchy]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prGetAllProductIDsInTopCategoryHiearchy]
@topcategoryid int
/*
prGetAllProductIDsInTopCategoryHiearchy 5
select HierarchyID.ToString() AS LogicalNode, * from ProductCategories
select HierarchyID.ToString() AS LogicalNode, * from ProductCategories where left(HierarchyID.ToString(),3) = '/3/'
SELECT distinct ProductCategoryID FROM ProductCategoryAssignments ORDER BY ProductCategoryID DESC
select HierarchyID.ToString() AS LogicalNode, * from ProductCategories where len(HierarchyID.ToString()) = 3
*/
as

declare @tophierarchyidtostring nvarchar(50)

select @tophierarchyidtostring = HierarchyID.ToString()
from ProductCategories
where ProductCategoryID = @topcategoryid

--print @tophierarchyidtostring

select a.productid 
from ProductCategories c
inner join ProductCategoryAssignments a
on c.ProductCategoryID = a.ProductCategoryID
where left(c.HierarchyID.ToString(),3) = @tophierarchyidtostring


return
GO
