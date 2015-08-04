USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[Audit_Log_SP]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Audit_Log_SP]
    @Message NVARCHAR(512),
    @Source NVARCHAR(512) = N' ',
    @RowCount INT = null,
    @Delimiter NCHAR(1) = N' ',
    @PadChar NCHAR(1) = N'-',
    @RC INT = null
AS
BEGIN
	SET @RC = @@ROWCOUNT
	
	IF @RowCount IS NULL
		SET @RowCount = @RC;

    DECLARE @LogDate AS NVARCHAR(50);
    DECLARE @RowCountPadded AS NCHAR(8);

    SET @LogDate = CONVERT(NVARCHAR(50),GETDATE(),121);
    SELECT @RowCountPadded = CASE @RowCount WHEN 0 THEN REPLICATE(@PadChar,8) ELSE REPLACE(STR(@RowCount, 8), SPACE(1), @PadChar) END; 

    SET @Message = @LogDate + @Delimiter + @RowCountPadded + @Delimiter + @Message;
    
    INSERT INTO Audit_Log
    (
		 logStamp
		,source
		,logEntry
    )
    SELECT
		 GETDATE()
		,@Source
		,@Message
		
    RAISERROR (@Message, 0, 1) WITH NOWAIT;
END
GO
