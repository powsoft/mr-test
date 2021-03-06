USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[MR_Exception_Logger]    Script Date: 8/17/2015 12:19:22 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Powell, Timothy>
-- Create date: <15 Aug 2015>
-- Description:	<Log instance of MRException>
-- =============================================
ALTER  PROCEDURE [dbo].[MR_Exception_Logger]
@errors MRException READONLY
AS
BEGIN
	--For now, just insert to exception table.
    INSERT INTO DataTrue_EDI.dbo.MRExceptionDetail
	(source, sourceId, exceptionType, date)
	SELECT source, recordId, exceptionType, CURRENT_TIMESTAMP
		FROM @errors;

	return @@ROWCOUNT;
END
