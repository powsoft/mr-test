USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UpdateFamilyAssociation]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec [usp_UpdateFamilyAssociation] 60719
CREATE PROCEDURE [dbo].[usp_UpdateFamilyAssociation]
	@ClusterId varchar(20)
AS

Begin
	update Clusters
	set  ImmediateParentID= dbo.fnGetFamilyAssociation(@ClusterId,0),
	FamilyAssociation=dbo.fnGetFamilyAssociation(@ClusterId,1) 
	where ClusterID=@ClusterId
End
GO
