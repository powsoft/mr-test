USE [DataTrue_Main]
GO
/****** Object:  UserDefinedFunction [dbo].[fnGetAttributeValueTableTwoValues]    Script Date: 06/25/2015 18:26:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[fnGetAttributeValueTableTwoValues]
(
@LoginID int,
@AttributeID int

--select * from dbo.fnGetAttributeValueTableTwoValues(40384, 17)

)
--declare @attrString nvarchar(1000)
RETURNS TABLE 


RETURN 
(

	select Cast(case when charindex(',',AttributeValue) > 0 then substring(AttributeValue, 0, charindex(',',AttributeValue)) else AttributeValue end as int) As atributepart
	from AttributeValues where OwnerEntityID = @LoginID and AttributeID = @AttributeID
	union all
	select Cast(case when charindex(',',AttributeValue) > 0 then substring(AttributeValue, charindex(',',AttributeValue)+1, len(AttributeValue) - charindex(',',AttributeValue)) else AttributeValue end as int) As atributepart
	from AttributeValues where OwnerEntityID = @LoginID and AttributeID = @AttributeID

	
)
GO
