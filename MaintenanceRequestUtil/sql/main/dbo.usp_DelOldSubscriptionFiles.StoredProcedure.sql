USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_DelOldSubscriptionFiles]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_DelOldSubscriptionFiles] 
as
DECLARE @CmdString VARCHAR(200)
DECLARE @FileName VARCHAR(550)
DECLARE @FileDate VARCHAR(20)
declare @FileMask varchar(10)
declare @FilePath VARCHAR(550)
set @FilePath = 'C:\DataTrueWeb\Stagging\SubscriptionReports\'
set @FileMask = '.zip'
CREATE TABLE ##DelFiles
      (FileName varchar(550) )
SET @CmdString = 'dir ' + @FilePath + '*' + @FileMask
print @cmdString
INSERT INTO ##DelFiles
EXEC master.dbo.xp_cmdshell @CmdString
--DELETE
--FROM ##DelFiles
--WHERE  Filename NOT LIKE '%' + @FileMask or Filename IS NULL
DECLARE FileCursor CURSOR
FOR SELECT REVERSE( SUBSTRING( REVERSE(Filename), 0, CHARINDEX(' ', REVERSE(Filename) ) ) ), 
SUBSTRING(Filename, 1, 22)
FROM ##DelFiles
WHERE DATEDIFF( dd, CONVERT(DATETIME, LEFT( Filename, 10) ), GETDATE() ) > 7 and ISNUMERIC(left(filename,2)) > 0 
OPEN FileCursor
      FETCH NEXT FROM FileCursor
      INTO @FileName, @FileDate
            WHILE @@FETCH_STATUS = 0
                  BEGIN
                  print @filename
                        SET @CmdString = 'del ' + @FilePath + @FileName 
                        EXEC master.dbo.xp_cmdshell @CmdString
                        FETCH NEXT FROM FileCursor
                        INTO @FileName, @FileDate
                  END
CLOSE FileCursor
DEALLOCATE FileCursor
DROP TABLE ##DelFiles
GO
