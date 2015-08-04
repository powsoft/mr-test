USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetStoreAndVendorActivityDetails]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec usp_GetActivityDetails_New '-1'
Create procedure [dbo].[usp_GetStoreAndVendorActivityDetails]
 @ChainId varchar(10)
as
Begin
	Select * from Datatrue_CustomResultSets..tmpStoreAndVendorActivity
      Where ChainId like CASE WHEN @ChainId<>'-1' THEN @ChainId ELSE '%' End
		
End
GO
