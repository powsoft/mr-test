USE [DataTrue_EDI]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_ReplaceNonNumericChars]    Script Date: 06/25/2015 16:58:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fn_ReplaceNonNumericChars] (@string VARCHAR(5000))
RETURNS VARCHAR(1000)
AS 
    BEGIN
        SET @string = REPLACE(@string, ',', '.')
        SET @string = (SELECT   SUBSTRING(@string, v.number, 1)
                       FROM     master..spt_values v
                       WHERE    v.type = 'P'
                                AND v.number BETWEEN 1 AND LEN(@string)
                                AND (SUBSTRING(@string, v.number, 1) LIKE '[0-9]'
                                     OR SUBSTRING(@string, v.number, 1) LIKE '[.]')
                       ORDER BY v.number
                      FOR
                       XML PATH('')
                      )
        RETURN @string
    END
GO
