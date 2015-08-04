USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetFileFormatsToExportByInstanceID]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prGetFileFormatsToExportByInstanceID]
	@JobInstanceID int
AS
Begin
	
	SELECT DISTINCT FileFormat,EmailID
	FROM JobRecipients
	WHERE JobInstanceID = @JobInstanceID

End
GO
