USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_DeleteUserAccount]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_DeleteUserAccount]
  @PersonId varchar(20)
as

Begin
Declare @sqlQuery varchar(4000)
 
 Declare @EmailId varchar(50)
 Select @EmailId = Login from Logins where OwnerEntityId = @PersonId
 update ASPNETDB.dbo.aspnet_Membership set IsLockedOut=1, LastLockoutDate=GETDATE(),FailedPasswordAttemptCount=0, Comment='Account Deleted' where Email = '' + @EmailId + ''

delete A from AutomatedReportsRequests A
inner join Logins  L on L.OwnerEntityId=A.PersonID
inner join aspnetdb.dbo.aspnet_Membership M on M.Email = L.Login
where IsLockedOut=1 and FailedPasswordAttemptCount=0

End
GO
