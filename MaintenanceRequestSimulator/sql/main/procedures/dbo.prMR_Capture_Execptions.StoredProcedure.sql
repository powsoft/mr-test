USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMR_Capture_MRExceptions_Logger]    Script Date: 8/17/2015 12:25:26 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Batch submitted through debugger: SQLQuery34.sql|7|0|C:\Users\WinDev\AppData\Local\Temp\~vsC3D1.sql
-- =============================================
-- Author:		<Powell, Timothy>
-- Create date: <15 Aug 2015>
-- Description:	<Log instance of >
-- =============================================
ALTER PROCEDURE [dbo].[prMR_Capture_MRExceptions_Logger]
AS
BEGIN

	--Create a type to pass to the Exception logging procedure
	DECLARE @errorTable AS MRException;
	
	--Check for 1st error condition
	INSERT INTO @errorTable
		(recordId, source, exceptionType)
	SELECT recordid, 'C', 1
		FROM DataTrue_EDI.dbo.costs WHERE recordStatus = 0
		AND dtChainId IS NULL;
  
	--Check for 2nd error condition
	INSERT INTO @errorTable
		(recordId, source, exceptionType)
	SELECT RecordID, 'C', 2
		FROM DataTrue_EDI.dbo.costs WHERE recordStatus = 0
		AND dtsupplierid IS NULL;

	--TODO: Add more conditions.

	--Call the Exception Logging Stored Procedure.
	EXEC dbo.MR_Exception_Logger @errorTable;

	return @@ROWCOUNT;
END
