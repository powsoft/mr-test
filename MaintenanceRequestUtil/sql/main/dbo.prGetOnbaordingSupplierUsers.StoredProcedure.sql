USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetOnbaordingSupplierUsers]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prGetOnbaordingSupplierUsers]
	@SupplierId int,
	@iControlSupplierID int
As
Begin
	declare @rec cursor
	declare @FirstName nvarchar(50)
	declare @LastName nvarchar(50)
	declare @Title nvarchar(50)
	declare @EmailID nvarchar(50)
	declare @SuppPDITradingPartner bit
	
	set @rec = CURSOR local fast_forward FOR
			select u.Firstname,u.LastName,u.Title,u.EmailID,SuppPDITradingPartner
			--select *
			from Onboarding..Onboarding_Supplier_Users u
			join Onboarding.dbo.Onboarding_Survey_Result r
			on u.TempSupplierID=r.TempSupplierID
			where r.SupplierID=@SupplierId
			and u.RecordStatus=0
	
	open @rec

	fetch next from @rec into  @FirstName,@LastName,@Title,@EmailID,@SuppPDITradingPartner

	while @@FETCH_STATUS = 0
	Begin
			
		INSERT INTO [DataTrue_Main].[dbo].[SystemEntities]
		([EntityTypeID]
		,[DateTimeCreated]
		,[LastUpdateUserID]
		,[DateTimeLastUpdate]
		--,[APIKey]
		,[PDIPartner]
		)
	values
		(3--<EntityTypeID, int,>
		,GETDATE()--<DateTimeCreated, datetime,>
		,0--<LastUpdateUserID, int,>
		,GETDATE()--<DateTimeLastUpdate, datetime,>
		--,<APIKey, nvarchar(50),>
		,@SuppPDITradingPartner
		)
		
		declare @NewPersonID int;
		
		SELECT @NewPersonID = SCOPE_IDENTITY();
		
		INSERT INTO [DataTrue_Main].[dbo].[Persons]
           ([PersonID]
           ,[FirstName]
           ,[LastName]
           --,[MiddleName]
           ,[Comments]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate])
		  values
           (@NewPersonID--<PersonID, int,>
           ,@FirstName
           ,@LastName
           --,<MiddleName, nvarchar(50),>
           ,@Title--<Comments, nvarchar(100),>
           ,GETDATE()--<DateTimeCreated, datetime,>
           ,0--<LastUpdateUserID, int,>
           ,GETDATE()--<DateTimeLastUpdate, datetime,		
           )
		
		
		INSERT INTO [DataTrue_Main].[dbo].[ContactInfo]
           ([OwnerEntityID]
           ,[Title]
           ,[FirstName]
           ,[LastName]
           --,[MiddleName]
           --,[DeskPhone]
           --,[MobilePhone]
           --,[Fax]
           ,[Email]
           --,[Comments]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           --,[ContactTypeID]
           )
		 Values 
           (@NewPersonID
           ,@Title
           ,@FirstName
           ,@LastName
           --,<MiddleName, nvarchar(50),>
           --,<DeskPhone, nvarchar(50),>
           --,<MobilePhone, nvarchar(50),>
           --,<Fax, nvarchar(50),>
           ,@EmailID
           --,<Comments, nvarchar(500),>
           ,GETDATE()--<DateTimeCreated, datetime,>
           ,0--<LastUpdateUserID, nvarchar(50),>
           ,GETDATE()--<DateTimeLastUpdate, datetime,>
           --,<ContactTypeID, smallint,>
			)
		
			INSERT INTO [DataTrue_Main].[dbo].[AttributeValues]
			   ([OwnerEntityID]
			   ,[AttributeID]
			   ,[AttributeValue]
			   ,[IsActive]
			   ,[DateTimeCreated]
			   ,[LastUpdateUserID]
			   ,[DateTimeLastUpdate])
			Values
			   (@NewPersonID--<OwnerEntityID, int,>
			   ,9--<AttributeID, int,>
			   ,@iControlSupplierID--<AttributeValue, nvarchar(255),>
			   ,'true'--<IsActive, bit,>
			   ,GETDATE()--<DateTimeCreated, datetime,>
			   ,0--<LastUpdateUserID, int,>
			   ,GETDATE()--,<DateTimeLastUpdate, datetime,>)
				--select * 
				)
	declare @UserID UniqueIdentifier = NEWID();			
	
		--select * from [DataTrue_Main].[dbo].[Logins]
		INSERT INTO [DataTrue_Main].[dbo].[Logins]
           ([OwnerEntityId]
           ,[UniqueIdentifier]
           ,[Login]
           ,[Password]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           --,[Custom1]
           )
		 Values
           (@NewPersonID
           ,@UserID--,<UniqueIdentifier, nvarchar(255),>
           ,@EmailID--<Login, nvarchar(255),>
           ,'NewPasswordNeeded'
           ,GETDATE()--<DateTimeCreated, datetime,>
           ,0--<LastUpdateUserID, int,>
           ,GETDATE()--<DateTimeLastUpdate, datetime,>
           --,<Custom1, nvarchar(255),>
           )
		

    INSERT INTO AspnetDB.dbo.aspnet_Membership
                ( ApplicationId,
                  UserId,
                  Password,
                  PasswordSalt,
                  Email,
                  LoweredEmail,
                  --PasswordQuestion,
                  --PasswordAnswer,
                  --PasswordFormat,
                  IsApproved,
                  IsLockedOut,
                  CreateDate,
                  LastLoginDate,
                  LastPasswordChangedDate,
                  LastLockoutDate,
                  FailedPasswordAttemptCount,
                  FailedPasswordAttemptWindowStart,
                  FailedPasswordAnswerAttemptCount,
                  FailedPasswordAnswerAttemptWindowStart 
                  )
         VALUES ( '23cb4237-3882-48da-954b-737e8198c9d1',
                  @UserID,
                  'NewPasswordNeeded',
                  'p82mTsS88+JsFjYI/EXuSQ==',
                  @EmailID,
                  LOWER(@EmailID),
                  --@PasswordQuestion,
                  --@PasswordAnswer,
                  --@PasswordFormat,
                  1,--@IsApproved,
                  0,--@IsLockedOut,
                  getdate(),
                  '1754-01-01 00:00:00.000',
                  '1754-01-01 00:00:00.000',
                  '1754-01-01 00:00:00.000',
                  0,
                  '1754-01-01 00:00:00.000',
                  0,
                  '1754-01-01 00:00:00.000'
                   )

		declare @FullName varchar(100) =(@FirstName + ' ' + @LastName)
		exec [prUser_Reporting_Role_Manage_MultiChain] 'ReportSupplier',@EmailID,'NewPasswordNeeded',@FullName,@iControlSupplierID,3000,'ADD', '' 
		
		                   	
		fetch next from @rec into  @FirstName,@LastName,@Title,@EmailID,@SuppPDITradingPartner
		
	End
	close @rec
	deallocate @rec
	
	update u set u.RecordStatus=1
	from Onboarding..Onboarding_Supplier_Users u
	join Onboarding.dbo.Onboarding_Survey_Result r
	on u.TempSupplierID=r.TempSupplierID
	where r.SupplierID=@SupplierId
	and u.RecordStatus=0
	
End
GO
