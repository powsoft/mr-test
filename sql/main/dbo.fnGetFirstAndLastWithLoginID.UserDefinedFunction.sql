USE [DataTrue_Main]
GO
/****** Object:  UserDefinedFunction [dbo].[fnGetFirstAndLastWithLoginID]    Script Date: 06/25/2015 18:26:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fnGetFirstAndLastWithLoginID]
(
@LoginID int
--select dbo.fnGetFirstAndLastWithLoginID(41586)
)
returns nvarchar(50)

with execute as caller

as
--select top 100 * from persons
begin
	declare @firstlast as nvarchar(50)
	
	select @firstlast = isnull(FirstName, '') + ' ' + isnull(LastName, '') 
	from Logins l
	inner join Persons p
	on l.OwnerEntityId = p.PersonID
	where l.OwnerEntityId = @LoginID
	
	return @firstlast
	
end
GO
