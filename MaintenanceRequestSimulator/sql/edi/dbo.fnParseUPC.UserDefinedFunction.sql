USE [DataTrue_EDI]
GO
/****** Object:  UserDefinedFunction [dbo].[fnParseUPC]    Script Date: 06/25/2015 16:58:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[fnParseUPC]
(
	-- Add the parameters for the function here
	@RawProductIdentifier VARCHAR(50)
)
RETURNS VARCHAR(14)
AS
BEGIN

	-- Declare the return variable here
	DECLARE @ReturnUPC VARCHAR(14)

	-- Declare Source UPC variable and set to RawProductIdentifier
	DECLARE @InputUPC VARCHAR(50)
	SET @InputUPC = @RawProductIdentifier
	
	-- If length > 12 return what was sent for EAN or GTIN
	IF LEN(@RawProductIdentifier) > 12
		BEGIN
			SET @ReturnUPC = @InputUPC
			RETURN @ReturnUPC
		END
	
	-- Remove trailing zero (one)
	IF SUBSTRING(@InputUPC, LEN(@InputUPC), 1) = '0'
		BEGIN
			SET @InputUPC = SUBSTRING(@InputUPC, 1, LEN(@InputUPC) - 1)
			SET @InputUPC = REPLICATE('0', 11-LEN(@InputUPC)) + @InputUPC
			SET @InputUPC = @InputUPC + dbo.fnGetCheckDigit(SUBSTRING(@InputUPC, 1, 11))
		END
			
	-- Remove leading zeros (many)
	SET @InputUPC = SUBSTRING(@InputUPC, PATINDEX('%[^0 ]%', @InputUPC + ' '), LEN(@InputUPC))
	
	-- Check for UPC-E format
	IF LEN(@InputUPC) < 9
		BEGIN
			SET @InputUPC = DataTrue_EDI.dbo.fnConvertUPCEtoUPCA(@InputUPC)
		END

	-- Check length, pad front with zeros
	IF LEN(@InputUPC) < 12
		BEGIN
			SET @InputUPC =  REPLICATE('0', 12-LEN(@InputUPC)) + @InputUPC
		END

	-- Check for valid checksum
	WHILE SUBSTRING(@InputUPC, 12, 1) <> dbo.fnGetCheckDigit(SUBSTRING(@InputUPC, 1, 11))
		BEGIN
			IF SUBSTRING(@InputUPC, 1, 1) <> 0 
				BEGIN --Invalid but does not start with 0, replace 12th character with checksum.
					SET @InputUPC = SUBSTRING(@InputUPC, 1, 11) + dbo.fnGetCheckDigit(SUBSTRING(@InputUPC, 1, 11))
				END
			ELSE
				BEGIN --Invalid but first character is 0.  Remove 0 and append checksum.  
					SET @InputUPC = SUBSTRING(@InputUPC, 2, 11) + dbo.fnGetCheckDigit(SUBSTRING(@InputUPC, 2, 11))
				END
		END

	SET @ReturnUPC = @InputUPC
	
	-- Return the result of the function
	RETURN @ReturnUPC

END
GO
