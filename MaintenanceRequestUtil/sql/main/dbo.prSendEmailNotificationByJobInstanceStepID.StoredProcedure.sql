USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prSendEmailNotificationByJobInstanceStepID]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prSendEmailNotificationByJobInstanceStepID]
	@JobInstanceID int,
	@JobInstanceStepID int,
	@FileFormat nvarchar(50),
	@FilePath nvarchar(512)
AS
Begin
--	declare @JobInstanceID int=1 declare @FileFormat nvarchar(50)='xls' declare @FilePath nvarchar(512)='\\IC-HQAPP2\Documents\June2012\1\Missing Product Description Report652012_3552200d_5e54_4e95_97b0_c08615f91f24.zip.txt'
	declare @rec cursor;
	declare @login nvarchar(128);
	declare @emailIds nvarchar(1000)='';
	declare @subject nvarchar(255)='';
	declare @body nvarchar(4000)='';
		
	if(@FileFormat='xls')
		Begin
			Set @rec = CURSOR local fast_forward FOR
				SELECT distinct Login
				FROM JobRecipients r join logins l
				on r.LoginId=l.LoginId
				WHERE 1=1
				and JobInstanceID = @JobInstanceID
				and FileFormat='xls'
			 
			open @rec
			fetch next from @rec into @login
			while @@FETCH_STATUS = 0
				Begin
					Set @emailIds=@emailIds+@login+';';
					fetch next from @rec into @login
				End
			
			close @rec
			deallocate @rec
		End
	Else
		Begin
			Set @rec = CURSOR local fast_forward FOR
				SELECT distinct Login
				FROM JobRecipients r join logins l
				on r.LoginId=l.LoginId
				WHERE 1=1
				and JobInstanceID = @JobInstanceID
				and FileFormat='csv'
			 
			open @rec
			fetch next from @rec into @login
			while @@FETCH_STATUS = 0
				Begin
					Set @emailIds=@emailIds+@login+';';
					fetch next from @rec into @login
				End

			close @rec
			deallocate @rec
		End	
		
			
		select @subject= EmailSubject,@body=EmailBody from  jobInstanceSteps
		where JobInstanceStepID=@JobInstanceStepID
				
		if(@emailIds<>'')
			Begin
				declare @senderstring nvarchar (255)=''
				declare @senderid int=0


				exec [dbo].[prSendEmailNotification_PassEmailAddresses_HTML_Attachment]
				@subject
				,@body
				,@senderstring
				,@senderid
				,@emailIds
				,''
				,''
				,@FilePath
			End		
End
GO
