USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetFamilyAssociation]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create PROCEDURE [dbo].[usp_GetFamilyAssociation]
	@parentClusterID varchar(50)
AS
--exec usp_GetFamilyAssociation 60696

BEGIN
	select  dbo.fnGetFamilyAssociation(@parentClusterID,1)
END
GO
