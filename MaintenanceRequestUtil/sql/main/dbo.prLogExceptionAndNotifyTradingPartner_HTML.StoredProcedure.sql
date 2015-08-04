USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prLogExceptionAndNotifyTradingPartner_HTML]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prLogExceptionAndNotifyTradingPartner_HTML]
@typeid smallint=0,
@subject nvarchar(255)='',
@body nvarchar(4000)='',
@senderstring nvarchar (255)='',
@senderid int=0,
@supplierid int =0,
@jobrecipienttypeid tinyint=0,
@banner nvarchar(50)=''

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
declare @EmailIDs nvarchar(1000)='';
declare @systemsupportemail nvarchar(100)
declare @edisupportemail nvarchar(200)
declare @costsupportemail nvarchar(100)
declare @supportemailtouse nvarchar(100)
declare @exceptionstatus smallint
declare @MyID int

set @MyID = 0
		if @jobrecipienttypeid<>0
			Begin
				if @banner = ''
					Begin
						select @EmailIDs=Coalesce(@EmailIDs,'')+ EmailId +';'
						from DataTrue_Main.dbo.JobRecipients
						where SupplierId=@supplierid
						and JobRecipientTypeID=@jobrecipienttypeid
					end
				else
					Begin
						select @EmailIDs=Coalesce(@EmailIDs,'')+ EmailId +';'
						from DataTrue_Main.dbo.JobRecipients
						where SupplierId=@supplierid
						and JobRecipientTypeID=@jobrecipienttypeid
						and CHARINDEX(@banner, Banner)>0
					end	
				
			end
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
		
		--if @jobrecipienttypeid<>0
		--	set @supportemailtouse = @supportemailtouse +';' + @EmailIDs	
			
		exec [dbo].[prSendEmailNotification_PassEmailAddresses_HTML]
			@subject
			,@body
			,@senderstring
			,@senderid
			,@supportemailtouse
			,''
			,''

	end

return
GO
