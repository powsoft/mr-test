USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_AddNewUser_API]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[usp_AddNewUser_API]
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
		
		if object_id('tempdb.dbo.#tmpuser') is not null
			begin
			 drop table #tmpuser;
			end
		
		select * into #tmpuser from dbo.AttributeValues where OwnerEntityID=(select OwnerEntityID from dbo.Logins where login=@CurrentUserId);
		
		update #tmpuser set OwnerEntityID=@datatruepersonid;
		
		update #tmpuser set AttributeValue=@AttributeValue, AttributeID=@AttributeId where AttributeID in (9, 17, 23)
		
		insert into dbo.AttributeValues select * from #tmpuser;
	
end
GO
