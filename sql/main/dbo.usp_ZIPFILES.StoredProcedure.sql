USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_ZIPFILES]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE [dbo].[usp_ZIPFILES] ( @SOURCE VARCHAR(8000), @DEST VARCHAR(8000))
AS
DECLARE @WinZip varchar(8000),
		@ZipName VARCHAR(8000),
        @Result INT
SET @WINZIP = 'c:\\progra~1\\7-zip\7z.exe a ' +  @Dest + ' ' + @Source
EXEC @Result = master.dbo.XP_CMDSHELL @Winzip 
set @SOURCE = 'del ' + @SOURCE 
exec xp_cmdshell @source
GO
