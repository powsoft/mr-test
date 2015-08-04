USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UserAccountLockStatus]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_UserAccountLockStatus]  
@UserName nvarchar(100),
@Password nvarchar(100)

as

Begin
 Declare @sqlQuery varchar(4000)

 set @sqlQuery = 'select m.UserID, (P.FirstName + '' '' +  P.LastName) as LoginName, L.Login, L.Password, convert(datetime,M.LastLockoutDate,101) as [Last Lock Date], FailedPasswordAttemptCount
from ASPNETDB.dbo.aspnet_Users  U 
INNER JOIN ASPNETDB.dbo.aspnet_Membership M ON M.UserId = U.UserId
inner join Logins L on U.UserName =L.Login
inner join Persons P on P.PersonID=L.OwnerEntityId
WHERE  1=1 and (islockedout=''true'' or FailedPasswordAttemptCount=5)
'

 if(@UserName<>'')
    set @sqlQuery = @sqlQuery +  ' and L.Login = ''' + @UserName  + ''''
 
 --if(@Password<>'')
 --   set @sqlQuery = @sqlQuery +  ' and L.Password = ''' + @Password  + ''''
   
 Exec(@sqlQuery);

End
GO
