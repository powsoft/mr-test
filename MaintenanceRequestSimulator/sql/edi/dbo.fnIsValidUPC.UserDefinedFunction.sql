USE [DataTrue_EDI]
GO
/****** Object:  UserDefinedFunction [dbo].[fnIsValidUPC]    Script Date: 06/25/2015 16:58:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[fnIsValidUPC]
(
	-- Add the parameters for the function here
	@ProductIdentifier VARCHAR(14)
)
RETURNS BIT
AS
BEGIN
	DECLARE @retValue BIT = 0
	-- Declare the return variable here
	IF ISNUMERIC(@ProductIdentifier) = 1 
		BEGIN
			IF ISNULL(DataTrue_EDI.dbo.fnParseUPC(@ProductIdentifier), '') <> ''
				BEGIN
					SET @retValue = 1
				END			
		END
	IF (ISNULL(@ProductIdentifier, '') LIKE '%+%' OR ISNULL(@ProductIdentifier, '') LIKE '%.%') 
		BEGIN
			SET @retValue = 0
		END	
	RETURN @retValue
END
GO
