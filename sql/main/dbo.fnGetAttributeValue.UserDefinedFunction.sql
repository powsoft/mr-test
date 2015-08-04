USE [DataTrue_Main]
GO
/****** Object:  UserDefinedFunction [dbo].[fnGetAttributeValue]    Script Date: 06/25/2015 18:26:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fnGetAttributeValue]
(
@LoginID int,
@AttributeID int

--select dbo.fnGetAttributeValue(40384, 17)
)
returns nvarchar(50)

with execute as caller

as

begin
	declare @attrVal as nvarchar(50)
	
	select @attrVal = Attributevalue
	from AttributeValues
	where OwnerEntityId = @LoginID
	and AttributeID = @AttributeID
	
	return @attrVal
	
end
GO
