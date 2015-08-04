USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prLogExceptionAndNotifySupport]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prLogExceptionAndNotifySupport]
@typeid smallint=0,
@subject nvarchar(255)='',
@body nvarchar(4000)='',
@senderstring nvarchar (255)='',
@senderid int=0

as
/*
[dbo].[prLogExceptionAndNotifySupport] 1, 'Test Email', 'Disregard - Test', 'charlie', 0

Exception Types
-1 = the call to this sp is to review/notify exceptions table records
1 = processing error - notify system support personnel - DataTrueSystemSupportEmail
2 = invalid EDI data error - notify EDI support personnel - DataTrueEDISupportEmail
3 = cost does not match - notify group responsible for researching/resolving these - DataTrueSystemSupportEmail
select * from Exceptions
*/
--declare @typeid smallint=1 declare @subject nvarchar(255)='Test Subject' declare @body nvarchar(4000)='Test Body' declare @senderstring nvarchar (255)='charlie' declare @senderid int=0
declare @systemsupportemail nvarchar(100)
declare @edisupportemail nvarchar(100)
declare @costsupportemail nvarchar(100)
declare @supportemailtouse nvarchar(100)
declare @exceptionstatus smallint
declare @MyID int

set @MyID = 24029

		--if @typeid = 1
			select @systemsupportemail = v.AttributeValue
			from AttributeDefinitions d
			inner join AttributeValues v
			on d.AttributeID = v.AttributeID
			where d.AttributeName = 'DataTrueSystemSupportEmail'
			and v.OwnerEntityID = 0


		--if @typeid = 2
			select @edisupportemail = v.AttributeValue
			from AttributeDefinitions d
			inner join AttributeValues v
			on d.AttributeID = v.AttributeID
			where d.AttributeName = 'DataTrueEDISupportEmail'
			and v.OwnerEntityID = 0
			

		--if @typeid = 1
			select @costsupportemail = v.AttributeValue
			from AttributeDefinitions d
			inner join AttributeValues v
			on d.AttributeID = v.AttributeID
			where d.AttributeName = 'DataTrueCostSupportEmail'
			and v.OwnerEntityID = 0
			


if @typeid > -1
	begin
		set @exceptionstatus = 0
		
		if @typeid = 1
			set @supportemailtouse = @systemsupportemail
		if @typeid = 2
			set @supportemailtouse = @edisupportemail
		if @typeid = 3
			set @supportemailtouse = @costsupportemail
		if @typeid = 4
			set @supportemailtouse = @edisupportemail
				
		exec [dbo].[prSendEmailNotification_PassEmailAddresses]
			@subject
			,@body
			,@senderstring
			,@senderid
			,@supportemailtouse
			,''
			,''

		INSERT INTO [dbo].[Exceptions]
				   ([ExceptionTypeID]
				   ,[ExceptionSubject]
				   ,[ExceptionBody]
				   ,[ExceptionSenderString]
				   ,[ExceptionSenderID]
				   ,[ExceptionNotifyCount])
			 VALUES
				   (@typeid
				   ,@subject
				   ,@body
				   ,@senderstring
				   ,@senderid
				   ,1)
	end
else --@type must be < 0 to go through else
	begin
		declare @rec cursor
		declare @ExceptionID bigint
		declare @ExceptionTypeID int
		declare @ExceptionSubject nvarchar(50)
		declare @ExceptionBody nvarchar(4000)
		declare @ExceptionSenderString nvarchar(250)
		declare @ExceptionSenderID int
		declare @ExceptionNotifyCount int
		declare @ExceptionNotifyCountCurrent int
		--declare @ExceptionStatus smallint
		declare @ExceptionSubjectWithCount nvarchar(50)
		
		set @rec = CURSOR local fast_forward for
		
		SELECT [ExceptionID]
			  ,[ExceptionTypeID]
			  ,[ExceptionSubject]
			  ,[ExceptionBody]
			  ,[ExceptionSenderString]
			  ,[ExceptionSenderID]
			  ,[ExceptionNotifyCount]
			  ,[ExceptionStatus]
		  FROM [dbo].[Exceptions]
		where ExceptionStatus <> 100

		open @rec
		
		fetch next from @rec into
			@ExceptionID
			,@ExceptionTypeID
			,@ExceptionSubject
			,@ExceptionBody
			,@ExceptionSenderString
			,@ExceptionSenderID
			,@ExceptionNotifyCount
			,@ExceptionStatus
		
		while @@FETCH_STATUS = 0
			begin
			
				if @ExceptionTypeID = 1
					set @supportemailtouse = @systemsupportemail
				if @ExceptionTypeID = 2
					set @supportemailtouse = @edisupportemail
				if @ExceptionTypeID = 3
					set @supportemailtouse = @costsupportemail
					
				set @ExceptionSubjectWithCount = 'Notification ' + ltrim(rtrim(str(@ExceptionNotifyCount + 1))) + '-' + @subject
					
				exec [dbo].[prSendEmailNotification_PassEmailAddresses]
					@ExceptionSubjectWithCount
					,@ExceptionBody
					,@ExceptionSenderString
					,@ExceptionSenderID
					,@supportemailtouse
					,''
					,''		
					
				UPDATE [dbo].[Exceptions]
				   SET [ExceptionLastNotifyDateTime] = GETDATE()
					  ,[ExceptionNotifyCount] = [ExceptionNotifyCount] + 1
					  ,[ExceptionStatus] = [ExceptionStatus] +1
				 WHERE ExceptionID = @ExceptionID
								
			
				fetch next from @rec into
					@ExceptionID
					,@ExceptionTypeID
					,@ExceptionSubject
					,@ExceptionBody
					,@ExceptionSenderString
					,@ExceptionSenderID
					,@ExceptionNotifyCount
					,@ExceptionStatus			
			end
			
		close @rec
		deallocate @rec
		
		
		
	end

return
GO
