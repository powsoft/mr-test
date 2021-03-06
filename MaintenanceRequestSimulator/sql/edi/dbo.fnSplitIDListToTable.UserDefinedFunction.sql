USE [DataTrue_EDI]
GO
/****** Object:  UserDefinedFunction [dbo].[fnSplitIDListToTable]    Script Date: 06/25/2015 16:58:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[fnSplitIDListToTable]
(
	@sInputList VARCHAR(MAX), -- List of delimited items
    @sDelimiter VARCHAR(50) = ',' -- delimiter that separates items
)
RETURNS @List TABLE (RecordID VARCHAR(8000))
AS
BEGIN
	DECLARE @sItem VARCHAR(8000)
	WHILE CHARINDEX(@sDelimiter,@sInputList,0) <> 0
	 BEGIN
	 SELECT
	  @sItem=RTRIM(LTRIM(SUBSTRING(@sInputList,1,CHARINDEX(@sDelimiter,@sInputList,0)-1))),
	  @sInputList=RTRIM(LTRIM(SUBSTRING(@sInputList,CHARINDEX(@sDelimiter,@sInputList,0)+LEN(@sDelimiter),LEN(@sInputList))))
	 
	 IF LEN(@sItem) > 0
	  INSERT INTO @List SELECT @sItem
	 END

	IF LEN(@sInputList) > 0
	 INSERT INTO @List SELECT @sInputList -- Put the last item in
	RETURN
END
GO
