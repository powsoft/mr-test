USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetAttributesXMLForAnEntityByIdentifier]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     PROCEDURE [dbo].[prGetAttributesXMLForAnEntityByIdentifier]
	@pintOwnerEntityID int=0
AS
/*
prGetAttributesXMLForAnEntityByIdentifier 0
*/
SELECT 1			as Tag, 
         NULL			as Parent,
	 @pintOwnerEntityID	as [Attribute!1!OwnerEntityID],
         NULL			as [Attribute!2!AttributeName],
         NULL			as [Attribute!2!AttributeValue]
UNION ALL
SELECT 2			as Tag, 
         1			as Parent,
	 @pintOwnerEntityID,
         AttributeDefinitions.AttributeName,
         AttributeValues.AttributeValue
FROM AttributeDefinitions, AttributeValues
WHERE AttributeDefinitions.AttributeID = AttributeValues.AttributeID
AND OwnerEntityID = @pintOwnerEntityID
AND IsActive = 1
ORDER BY [Attribute!2!AttributeName], [Attribute!2!AttributeValue]
FOR XML EXPLICIT
GO
