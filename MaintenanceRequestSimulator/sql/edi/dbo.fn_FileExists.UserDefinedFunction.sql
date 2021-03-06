USE [DataTrue_EDI]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_FileExists]    Script Date: 06/25/2015 16:58:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fn_FileExists](@path varchar(512))
RETURNS BIT
AS
BEGIN
     DECLARE @result INT
     EXEC master.dbo.xp_fileexist @path, @result OUTPUT
     RETURN cast(@result as bit)
END;
GO
