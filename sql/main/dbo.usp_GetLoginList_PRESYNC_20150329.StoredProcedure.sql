USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetLoginList_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[usp_GetLoginList_PRESYNC_20150329] 
@PersonID int,
@PDIAdmin bit
AS
BEGIN
declare @strSQL varchar(max)
    set @strSQL = 'Select L.OwnerEntityId, L.Login from Logins L
				   left join ASPNETDB.dbo.aspnet_Membership M on M.Email = L.Login and M.IsLockedOut=1 and M.FailedPasswordAttemptCount=0
				   where M.Email is null '
    
	if (@PDIAdmin <> 0)
	  begin
		 set @strSQL = @strSQL + ' AND (L.LastUpdateUserID = '+ @PersonID
		 set @strSQL = @strSQL + ' or L.PDIPartner= 1 )'
	  end	
	else
		 set @strSQL = @strSQL + ' AND L.LastUpdateUserID = '+ @PersonID
							    
	set @strSQL = ' order by L.Login'
	
	exec (@strSQL)
END
GO
