USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[zUtil_ASPNETDB_MODS]    Script Date: 06/25/2015 18:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[zUtil_ASPNETDB_MODS]

as

declare @dummy int

/*
[ASPNETDB].[dbo].[aspnet_Membership_CreateUser]
	Added create user syncronization
	
[ASPNETDB].[dbo].[aspnet_Membership_ResetPassword]
	Added update to logins table password
	
[ASPNETDB].[dbo].[aspnet_Membership_SetPassword]
	Added update to logins table password
*/	


return
GO
