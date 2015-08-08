USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_AddSyncUsers]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC [amb_AddSyncUsers] '41713','vishal123@amebasoftwares.com','','vishal123@amebasoftwares.com','vishal1982','27506C49 D0AA0134 C7029621 14D52970 047DF659','40393','17','FULL','EDIT'
--select * from #tmpuser
--select * from dbo.Logins where loginid='41713'

--SELECT * FROM AttributeValues where OwnerEntityID='60781'

CREATE proc [dbo].[amb_AddSyncUsers]
(
 @CurrentUserId nvarchar(50),
 @FirstName nvarchar(50),
 @LastName nvarchar(50),
 @LoginName nvarchar(50),
 @LoginPassword nvarchar(50),
 @PasswordSalt nvarchar(50),
 @AttributeValue nvarchar(50),
 @AttributeId nvarchar(2),
 @BannerAccess nvarchar(100),
 @EditRights nvarchar(100)
)

as 
begin

	declare @datatruepersonid int
		Declare @RoleType varchar(50)
		declare @RoleTypeID varchar(50)
	exec dbo.prPerson_create @FirstName, @LastName, null, @datatruepersonid output
	             
	INSERT INTO dbo.Logins
			   ([OwnerEntityId]
			   ,[UniqueIdentifier]
			   ,[Login]
			   ,[Password]
			   ,[DateTimecreated]
			   ,[LastUpdateUserID]
			   ,[DateTimeLastUpdate])
		 VALUES
			   (@datatruepersonid
			   ,null
			   ,@LoginName  --email address preferred
			   ,@LoginPassword 
			   ,GETDATE()
			   ,@CurrentUserId
			   ,GETDATE())           
		
		if object_id('tempdb.dbo.##tmpuser') is not null
			begin
			 drop table ##tmpuser;
			end
			
		IF(@AttributeId='9')
			set @RoleType='Newspaper Supplier'
		IF(@AttributeId='17')
			set @RoleType='NewsPaper Retailer'
		IF(@AttributeId='23')
			set @RoleType='Newspaper Manufacturer'
			
		SELECT @RoleTypeID=RoleId from UserRoles_New where RoleName=@RoleType
		
		select * into ##tmpuser from dbo.AttributeValues where OwnerEntityID=(SELECT top 1  OwnerEntityID FROM AttributeValues where AttributeID=@RoleTypeID)
		
		update ##tmpuser set OwnerEntityID=@datatruepersonid;
		
		update ##tmpuser set AttributeValue=@datatruepersonid where AttributeID=21;
		
		update ##tmpuser set AttributeValue=@AttributeValue, AttributeID=@AttributeId where AttributeID in (9, 17, 23)
		
		insert into dbo.AttributeValues select * from ##tmpuser;
		
		exec [usp_SaveAssignUserRoles_New] @datatruepersonid,@RoleTypeID
end
GO
