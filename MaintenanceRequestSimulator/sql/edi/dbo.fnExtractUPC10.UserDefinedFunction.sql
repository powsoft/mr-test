USE [DataTrue_EDI]
GO
/****** Object:  UserDefinedFunction [dbo].[fnExtractUPC10]    Script Date: 06/25/2015 16:58:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[fnExtractUPC10]
(
	-- Add the parameters for the function here
	@InputString VARCHAR(500)
)
RETURNS VARCHAR(12)
AS
BEGIN

	SET @InputString = REPLACE(@InputString, '-', ' - ')
	SET @InputString = REPLACE(@InputString, '(', ' ( ')
	SET @InputString = REPLACE(@InputString, ')', ' ) ')
	SET @InputString = @InputString + ' '
	
	DECLARE @SplitString VARCHAR(500)
	DECLARE @ReturnUPC VARCHAR(12)
	DECLARE @LastPOS INT
	DECLARE @POS INT

	SET @SplitString = @InputString
	SET @LastPOS = 0
	SET @POS = 0	
	
	WHILE (ISNULL(@ReturnUPC, '') = '')
		BEGIN
			SET @POS = CHARINDEX(' ', @InputString, @LastPOS )
			IF ISNULL(@POS, 0) = 0
				BEGIN
					SET @POS = (LEN(@InputString) + 1)
				END		
			SET @SplitString = SUBSTRING(@InputString, (@LastPOS), (@POS-@LastPOS))
			--ATTEMPT TO GET CHAIN ID
			IF LEN(@SplitString) >= 10 AND ISNUMERIC(@SplitString) = 1
				BEGIN			
					SET @ReturnUPC = @SplitString	
					SET @SplitString = ''
				END
			ELSE
				BEGIN
					SET @LastPOS = (@POS + 1)
					IF @LastPOS >= LEN(@InputString)
						BEGIN
							RETURN ''
						END
				END	
		END
	RETURN @ReturnUPC
END
GO
