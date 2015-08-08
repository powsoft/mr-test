USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prProductCategories_HierarchyID_Update]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prProductCategories_HierarchyID_Update]
as
/*
update ProductCategories set HierarchyID = null
select HierarchyID.ToString() AS LogicalNode, * from ProductCategories
select HierarchyID.ToString() AS LogicalNode, * from ProductCategories where left(HierarchyID.ToString(),3) = '/3/'

*/
declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @MyID int

set @MyID = 24121

begin try

begin transaction

CREATE TABLE #NewOrg
(
  OrgNode hierarchyid,
  ChildID int,
  LoginID nvarchar(50),
  ParentID int
CONSTRAINT PK_NewOrg_OrgNode
  PRIMARY KEY CLUSTERED (OrgNode)
);

CREATE TABLE #Children 
   (
    ParentID int,
    ChildID int,
    Num int
);

CREATE CLUSTERED INDEX tmpind ON #Children(ParentID, ChildID);

INSERT #Children (ChildID, ParentID, Num)
SELECT ProductCategoryID, ProductCategoryParentID,
  ROW_NUMBER() OVER (PARTITION BY ProductCategoryParentID ORDER BY ProductCategoryParentID) 
FROM ProductCategories;

--SELECT * FROM #Children ORDER BY ParentID, Num
--select * from #NewOrg

WITH paths(path, ChildID) 
AS (
-- This section provides the value for the root of the hierarchy
SELECT hierarchyid::GetRoot() AS OrgNode, ChildID 
FROM #Children AS C 
WHERE ParentID IS NULL 

UNION ALL 
-- This section provides values for all nodes except the root
SELECT 
CAST(p.path.ToString() + CAST(C.Num AS varchar(30)) + '/' AS hierarchyid), 
C.ChildID
FROM #Children AS C 
JOIN paths AS p 
   ON C.ParentID = P.ChildID 
)
INSERT #NewOrg (OrgNode, O.ChildID, O.ParentID)
SELECT P.path, O.ProductCategoryID, O.ProductCategoryParentID
FROM ProductCategories AS O 
JOIN Paths AS P 
   ON O.ProductCategoryID = P.ChildID;

/*
SELECT OrgNode.ToString() AS LogicalNode, * 
FROM #NewOrg 
ORDER BY LogicalNode;
*/


--SELECT OrgNode.ToString() AS LogicalNode, o.OrgNode, c.* 
update c set HierarchyID = OrgNode
FROM #NewOrg o
inner join ProductCategories c
on o.ChildID = c.ProductCategoryID;

commit transaction
	
end try
	
begin catch
		rollback transaction
		
		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
end catch

return;
GO
