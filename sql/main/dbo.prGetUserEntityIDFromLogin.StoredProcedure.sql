USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetUserEntityIDFromLogin]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prGetUserEntityIDFromLogin]
@login nvarchar(100)='',
@password nvarchar(100)=''--,
--@userEntityID int output
/*
declare @int int
exec prGetUserEntityIDFromLogin 'charlie.clark@icontroldsd.com', 'testpwd', @int output
print @int
*/
as

select OwnerEntityID
--select @userEntityID = OwnerEntityID
from dbo.Logins
where Login=@login
and Password = @password

--if @userEntityID is null
-- set @userEntityID = 0


return
GO
