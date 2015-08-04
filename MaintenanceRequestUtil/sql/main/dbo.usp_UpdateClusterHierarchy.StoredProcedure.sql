USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UpdateClusterHierarchy]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec [usp_UpdateClusterHierarchy] 60712
CREATE PROCEDURE [dbo].[usp_UpdateClusterHierarchy]
	@ClusterId varchar(20)
AS

Begin
	DECLARE CLUSTER_CURSOR CURSOR FOR 
	
	Select ClusterId from Clusters C where C.ClusterId like case when @ClusterId='-1' then '%' else '%' + @ClusterId + '%' end
	
	OPEN CLUSTER_CURSOR;
		FETCH NEXT FROM CLUSTER_CURSOR INTO @ClusterId
		while @@FETCH_STATUS = 0
			begin
					
				-- Check Immediate Parent Nodes
				Declare @ImmediateParents varchar(max) = ','
				select @ImmediateParents = COALESCE(@ImmediateParents, '') + Rtrim(cast(M.OrganizationEntityId as varchar))  + ','
				from Memberships M
				where M.MemberEntityId=@ClusterId
				
				--select @ImmediateParents			
				
				-- Check Family Tree
				Declare @FamilyTree varchar(max) = ',' 
				Declare @ParentId as varchar(10)= @ClusterId
				Declare @NextParentId as varchar(10)
				
				WHILE @ParentId != -1
				BEGIN
					
					select @NextParentId = M.OrganizationEntityId
					from Memberships M 
					where M.MemberEntityId=@ParentId
					
					set @NextParentId =isnull(@NextParentId ,-1)
					--select @NextParentId
					if(@NextParentId!=-1)	
						set @FamilyTree= @FamilyTree + @NextParentId + ','
					
					set @ParentId=@NextParentId	
					set @NextParentId=NULL
					
				END
				
				--select @FamilyTree	
				update Clusters set ImmediateParentId= @ImmediateParents, FamilyAssociation=@FamilyTree where ClusterId=@ClusterId
				
			FETCH NEXT FROM CLUSTER_CURSOR INTO @ClusterId
			end
	CLOSE CLUSTER_CURSOR;
	DEALLOCATE CLUSTER_CURSOR;

End
GO
