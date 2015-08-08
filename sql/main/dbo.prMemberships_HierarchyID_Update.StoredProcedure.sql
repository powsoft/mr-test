USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMemberships_HierarchyID_Update]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMemberships_HierarchyID_Update]
as
/*
update Memberships set HierarchyID = null
select HierarchyID.ToString() AS LogicalNode, * from Memberships
drop table #NewOrg
drop table #Children
*/
declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @MyID int

set @MyID = 24120

begin try

begin transaction

CREATE TABLE #NewOrg
(
  OrgNode hierarchyid,
  ChildID int,
  ParentID int
CONSTRAINT PK_NewOrg_OrgNode
  PRIMARY KEY CLUSTERED (OrgNode)
);
--drop table #Children
CREATE TABLE #Children 
   (
    ParentID int,
    ChildID int,
    Num int
);

CREATE CLUSTERED INDEX tmpind ON #Children(ParentID, ChildID);

INSERT #Children (ChildID, ParentID, Num)
SELECT MemberEntityID, OrganizationEntityID,
  ROW_NUMBER() OVER (PARTITION BY OrganizationEntityID ORDER BY OrganizationEntityID) 
FROM Memberships;

--SELECT * FROM #Children ORDER BY ParentID, Num
--select * from #NewOrg

WITH paths(path, ChildID, ParentID) 
AS (
-- This section provides the value for the root of the hierarchy
--/*
SELECT hierarchyid::GetRoot() AS OrgNode, ChildID, ParentID 
FROM #Children AS C 
WHERE ParentID is null

UNION ALL 
--*/
-- This section provides values for all nodes except the root
SELECT 
CAST(p.path.ToString() + CAST(C.Num AS varchar(30)) + '/' AS hierarchyid), 
C.ChildID, C.ParentID
FROM #Children AS C 
JOIN paths AS p 
   ON C.ParentID = P.ChildID 
)
INSERT #NewOrg (OrgNode, O.ChildID, O.ParentID)
SELECT P.path, O.MemberEntityID, O.OrganizationEntityID
FROM Memberships AS O 
JOIN Paths AS P 
   ON O.OrganizationEntityID = p.ParentID
   and O.MemberEntityID = P.ChildID;

/*
SELECT OrgNode.ToString() AS LogicalNode, * 
FROM #NewOrg 
where ChildID = 12
order by OrgNode
ORDER BY LogicalNode;

select * from Memberships
*/


--SELECT OrgNode.ToString() AS LogicalNode, o.OrgNode, c.* 
update c set HierarchyID = OrgNode
FROM #NewOrg o
inner join Memberships c
on o.ParentID = c.OrganizationEntityID
and o.ChildID = c.MemberEntityID;


drop table #NewOrg
drop table #Children

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
