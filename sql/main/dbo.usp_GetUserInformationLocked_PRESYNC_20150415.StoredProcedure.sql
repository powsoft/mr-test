USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetUserInformationLocked_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec [usp_GetUserInformationLocked] '','',1,76953
CREATE procedure [dbo].[usp_GetUserInformationLocked_PRESYNC_20150415]  
@Name nvarchar(100),
@Email nvarchar(100),
@PDIAdmin varchar(10),
@UserId varchar(10)
as

Begin
 Declare @sqlQuery varchar(4000)

 set @sqlQuery = '
				select m.UserID, (P.FirstName + '' '' +  P.LastName) as LoginName, L.Login, L.Password, 
				convert(datetime,M.LastLockoutDate,101) as [Last Lock Date], 
				case when FailedPasswordAttemptCount=0 then ''FALSE'' else ''TRUE'' end as FailedPasswordAttemptCount,
				case when FailedPasswordAttemptCount=0 then ''Account deleted by administrator'' else ''Account locked due to failed login attempts'' end as [Lock Reason]
				from ASPNETDB.dbo.aspnet_Users  U  WITH(NOLOCK) 
				INNER JOIN ASPNETDB.dbo.aspnet_Membership M  WITH(NOLOCK) ON M.UserId = U.UserId
				inner join Logins L WITH(NOLOCK) on U.UserName =L.Login
				inner join Persons P WITH(NOLOCK) on P.PersonID=L.OwnerEntityId
				WHERE  islockedout=1'

 if(@Name<>'')
    set @sqlQuery = @sqlQuery +  ' and (p.firstname like ''%' + @Name  + '%'' or   p.lastname like ''%' + @Name  + '%'')'
 
 if(@Email<>'')
    set @sqlQuery = @sqlQuery +  ' and L.Login like ''%' + @Email  + '%''' 

  if(@PDIAdmin <> '0' ) 
	set @sqlQuery = @sqlQuery + ' and L.PDIPartner = 1'		

  if(@PDIAdmin <> '1' ) 
	BEGIN
		  if(@UserId <> '0' ) 
			set @sqlQuery = @sqlQuery + ' and L.OwnerEntityId in (Select distinct AV.OwnerEntityID
																		from AssignUserRoles_New A
																		inner join UserRoles_New R on R.RoleID=A.RoleID
																		Left Join RetailerAccess RA on RA.PersonId=A.UserID 
																		Left Join SupplierAccess SA on SA.PersonId=A.UserID 
																		Left Join AttributeValues AV on AV.AttributeValue =  isnull(RA.ChainId, SA.SupplierId) and AV.AttributeID=R.RoleTypeID
																		where UserID=' + @UserId +
																 ')'	
	END	
		   
   Exec(@sqlQuery);
   Print(@sqlQuery);

End
GO
