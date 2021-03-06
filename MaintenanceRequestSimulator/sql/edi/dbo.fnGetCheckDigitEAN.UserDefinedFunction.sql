USE [DataTrue_EDI]
GO
/****** Object:  UserDefinedFunction [dbo].[fnGetCheckDigitEAN]    Script Date: 06/25/2015 16:58:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnGetCheckDigitEAN]
(
	@EAN VARCHAR(13)
)
RETURNS VARCHAR(14)
AS
BEGIN

	IF @EAN LIKE '+' OR @EAN LIKE '%.%' OR @EAN LIKE '%e%'
		BEGIN
			RETURN NULL
		END

	IF ISNUMERIC(@EAN) = 0
		BEGIN
			RETURN NULL
		END

	DECLARE	@Index TINYINT,
		@Multiplier TINYINT,
		@Sum TINYINT

	SELECT	@Index = LEN(@EAN),
		@Multiplier = 3,
		@Sum = 0

	WHILE @Index > 0
		SELECT	@Sum = @Sum + @Multiplier * CAST(SUBSTRING(@EAN, @Index, 1) AS TINYINT),
			@Multiplier = 4 - @Multiplier,
			@Index = @Index - 1

	RETURN	CASE @Sum % 10
			WHEN 0 THEN '0'
			ELSE CAST(10 - @Sum % 10 AS CHAR(1))
		END
END
GO
