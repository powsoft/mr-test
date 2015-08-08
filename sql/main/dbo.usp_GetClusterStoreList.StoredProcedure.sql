USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetClusterStoreList]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec [usp_UpdateClusterHierarchy] 60712
CREATE  PROCEDURE [dbo].[usp_GetClusterStoreList]
	@ClusterId varchar(20)
AS

Begin
	select distinct S.* 
	from Clusters C
	 inner join Memberships M on M.OrganizationEntityId=C.ClusterId
	 inner join Stores S on S.StoreId=M.MemberEntityId
	where C.ClusterId = @ClusterId
		or C.FamilyAssociation like '%' + @ClusterId + '%'
End
GO
