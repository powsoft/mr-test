USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prPerson_Authenticate]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prPerson_Authenticate]
@loginid nvarchar(100),
@password nvarchar(100)

as
/*
prPerson_Authenticate 'charlie.clark@icontroldsd.com'

*/
declare @MyID int
declare @userid uniqueidentifier
declare @returnstring nvarchar(50)


set @MyID = 40385

select @userid = u.userid from ASPNETDB.dbo.aspnet_Users u
inner join ASPNETDB.dbo.aspnet_Membership m
on u.UserId = m.UserId
where u.UserName = @loginid
and m.Password = @password

if @@ROWCOUNT = 1
	set @returnstring = 'USERAUTHENTICATED'
ELSE
	set @returnstring = 'USERDIDNOTAUTHENTICATE'



select @returnstring as AuthenticatePhrase

return
GO
