USE [DataTrue_EDI]
GO
/****** Object:  UserDefinedFunction [dbo].[fnRemoveNonNumericCharacters]    Script Date: 06/25/2015 16:58:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Function [dbo].[fnRemoveNonNumericCharacters](@strText VARCHAR(1000))
RETURNS VARCHAR(1000)
AS
BEGIN
Declare @PATII int;
Declare @PATY int;
    WHILE PATINDEX('%[^0-9]%', @strText) >0
   
    BEGIN
     SET @PATII = PATINDEX('%[^0-9]%', @strText)
     If @PATII > 1 
		Begin
		 SEt @PATY = LEN(@strText)-@PATII
		 SET @strText = STUFF(@strText, PATINDEX('%[^0-9]%', @strText), @PATY + 1, '')
		 Break;
		 End
		 else
        SET @strText = STUFF(@strText, PATINDEX('%[^0-9]%', @strText), 1, '')
        
    END
   
    RETURN @strText
END
GO
