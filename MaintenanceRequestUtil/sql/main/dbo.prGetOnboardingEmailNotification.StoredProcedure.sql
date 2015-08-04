USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetOnboardingEmailNotification]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prGetOnboardingEmailNotification]
as
Begin
	
	select p.FirstName,p.LastName,l.LoginID,c.Title 
	from DataTrue_Main.dbo.Logins l
	join DataTrue_Main.dbo.Persons p
	on l.OwnerEntityId=p.PersonID
	join ContactInfo c on l.OwnerEntityId = c.OwnerEntityID
	where Password='NewPasswordNeeded'

End
GO
