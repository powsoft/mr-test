USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[SP_GetFileTypes]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_GetFileTypes]
	-- Add the parameters for the stored procedure here
	AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    
	SELECT FileTypeId, FileTypeDesc from lkFileTypes order by FileTypeDesc
END
GO
