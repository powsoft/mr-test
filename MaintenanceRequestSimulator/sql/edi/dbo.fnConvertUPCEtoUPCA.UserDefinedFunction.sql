USE [DataTrue_EDI]
GO
/****** Object:  UserDefinedFunction [dbo].[fnConvertUPCEtoUPCA]    Script Date: 06/25/2015 16:58:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnConvertUPCEtoUPCA](@UPCE VARCHAR(8))
RETURNS VARCHAR(10)
AS
BEGIN

	DECLARE @ValidDigits VARCHAR(6)
	DECLARE @LastValidDigit VARCHAR(1)
	DECLARE @UPCA VARCHAR(10)
	
	IF LEN(@UPCE) = 6
		BEGIN
			SET @ValidDigits = @UPCE
		END
	
	IF LEN(@UPCE) = 7
		BEGIN
			IF LEFT(@UPCE, 1) <> '0'
				BEGIN
					SET @ValidDigits = SUBSTRING(@UPCE, 1, 6)
				END
			ELSE
				BEGIN
					SET @ValidDigits = SUBSTRING(@UPCE, 2, 6)
				END
		END
		
	IF LEN(@UPCE) = 8
		BEGIN
			SET @ValidDigits = SUBSTRING(@UPCE, 2, 6)
		END
		
	SET @LastValidDigit = RIGHT(@ValidDigits, 1)
	
	IF @LastValidDigit IN (0,1,2)
		BEGIN
			SET @UPCA = SUBSTRING(@ValidDigits, 1, 2) + RIGHT(@ValidDigits, 1) + '0000' + SUBSTRING(@ValidDigits, 3, 3)
		END
	IF @LastValidDigit = 3
		BEGIN
			SET @UPCA = SUBSTRING(@ValidDigits, 1, 3) + '00000' + SUBSTRING(@ValidDigits, 4, 2)
		END
	IF @LastValidDigit = 4
		BEGIN
			SET @UPCA = SUBSTRING(@ValidDigits, 1, 4) + '00000' + SUBSTRING(@ValidDigits, 5, 1)
		END
	IF @LastValidDigit IN (5,6,7,8,9)
		BEGIN
			SET @UPCA = SUBSTRING(@ValidDigits, 1, 5) + '0000' + RIGHT(@ValidDigits, 1)
		END
	
	RETURN @UPCA
  
END
GO
