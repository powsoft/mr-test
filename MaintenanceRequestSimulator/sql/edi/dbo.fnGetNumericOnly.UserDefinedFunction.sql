USE [DataTrue_EDI]
GO
/****** Object:  UserDefinedFunction [dbo].[fnGetNumericOnly]    Script Date: 06/25/2015 16:58:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnGetNumericOnly] (@string VARCHAR(500))
RETURNS VARCHAR(500)
AS
BEGIN
DECLARE @NumericOnlyPart VARCHAR(500) = '';
DECLARE @Numeric VARCHAR(1) = ''
DECLARE @start INT = 1;
DECLARE @end INT = 1
 
SELECT @end = LEN(@string);
 
WHILE (@start <= @end)
BEGIN
SET @Numeric = SUBSTRING(@string, @start, @start + 1)
 
IF ASCII(@Numeric) >= 48
AND ASCII(@Numeric) <= 57
BEGIN
SET @NumericOnlyPart = @NumericOnlyPart + @Numeric;
END
 
SET @start = @start + 1;
END
 
RETURN @NumericOnlyPart
END
GO
