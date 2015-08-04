USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_GetAttributeNamesAndValues]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_GetAttributeNamesAndValues]
/*
prUtil_GetAttributeNamesAndValues
*/
as

select d.AttributeID, AttributeName, AttributeValue, AttributeDescription, OwnerEntityID, IsActive
from AttributeDefinitions d
inner join AttributeValues v
on d.AttributeID = v.AttributeID
order by d.AttributeName

return
GO
