USE [DataTrue_Main]
GO
/****** Object:  UserDefinedFunction [dbo].[fnGetAttributeValueTableTest]    Script Date: 06/25/2015 18:26:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fnGetAttributeValueTableTest]
(
@LoginID int,
@AttributeID int

--select * from dbo.fnGetAttributeValueTableTest(0, 17)

)

RETURNS TABLE 


RETURN 


SELECT Cast(SUBSTRING(',' + dbo.fnGetAttributeValue(@LoginID, @AttributeID) + ',', Number + 1,     CHARINDEX(',', ',' + dbo.fnGetAttributeValue(@LoginID, @AttributeID) + ',', Number + 1) - Number -1) as int) AS attributepart     FROM master..spt_values     WHERE Type = 'P'     AND Number <= LEN(',' + dbo.fnGetAttributeValue(@LoginID, @AttributeID) + ',') - 1     AND SUBSTRING(',' + dbo.fnGetAttributeValue(@LoginID, @AttributeID) + ',', Number, 1) = ','
GO
