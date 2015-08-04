USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetAttributeValueRowSet]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prGetAttributeValueRowSet]

as
	select Cast(case when charindex(',',AttributeValue) > 0 then substring(AttributeValue, 0, charindex(',',AttributeValue)) else AttributeValue end as int) As attributepart
	from AttributeValues where OwnerEntityID = 40384 and AttributeID = 17
	union all
	select Cast(case when charindex(',',AttributeValue) > 0 then substring(AttributeValue, charindex(',',AttributeValue)+1, len(AttributeValue) - charindex(',',AttributeValue)) else AttributeValue end as int) As attributepart
	from AttributeValues where OwnerEntityID = 40384 and AttributeID = 17
/*
	select Cast(case when charindex(',',AttributeValue) > 0 then substring(AttributeValue, 0, charindex(',',AttributeValue)) else AttributeValue end as int) As attributepart
	from AttributeValues where OwnerEntityID = @LoginID and AttributeID = @AttributeID
	union all
	select Cast(case when charindex(',',AttributeValue) > 0 then substring(AttributeValue, charindex(',',AttributeValue)+1, len(AttributeValue) - charindex(',',AttributeValue)) else AttributeValue end as int) As attributepart
	from AttributeValues where OwnerEntityID = @LoginID and AttributeID = @AttributeID
*/
return
GO
