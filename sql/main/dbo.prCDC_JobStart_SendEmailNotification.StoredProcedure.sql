USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDC_JobStart_SendEmailNotification]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDC_JobStart_SendEmailNotification]
as
Begin
	
	declare @subject nvarchar(255)='Mid Night Synchronisation Job Started'
	declare @body nvarchar(4000)='The mid night synchronisation job has started'
	declare @senderstring nvarchar (255)='DataTrue System'
	declare @senderid int=0
	declare @edisupportemail nvarchar(100)
	
	
	select @edisupportemail = v.AttributeValue
			from AttributeDefinitions d
			inner join AttributeValues v
			on d.AttributeID = v.AttributeID
			where d.AttributeName = 'DataTrueEDISupportEmail'
			and v.OwnerEntityID = 0
	Set @edisupportemail=@edisupportemail;--+';edi@icontroldsd.com';
	exec [dbo].[prSendEmailNotification_PassEmailAddresses]
				@subject
				,@body
				,@senderstring
				,@senderid
				,@edisupportemail
				,''
				,''
				
End
GO
