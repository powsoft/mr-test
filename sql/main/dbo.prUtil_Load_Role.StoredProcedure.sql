USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Load_Role]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Load_Role]
@roleidentifier nvarchar(50),
@roleentitytypename nvarchar(50),
@roledescription nvarchar(500),
@rolecomments nvarchar(500),
@userid int,
@newentityid int output

/*
declare @int int
exec prUtil_Load_Role 
'prBilling_ServiceFees_Retailer_InvoiceDetails_Create'
,'Role_Process_StoredProcedure'
,'prBilling_ServiceFees_Retailer_InvoiceDetails_Create'
,''
,0
,@int output
print @int

declare @int int
exec prUtil_Load_Role 
'DataTrue_Manufacturer'
,'Role_Person_DataTrue'
,'This role grants access to all features for a manufacturer in the DataTrue system'
,''
,0
,@int output
print @int

select * from Roles
update Roles set DateTimeCreated = '2011-1-01', DateTimeLastUpdate = '2011-01-01'
*/

as

declare @entitytypeid int
declare @roleid int

begin transaction

select @entitytypeid = EntityTypeID
from dbo.EntityTypes
where EntityTypeName = @roleentitytypename

INSERT INTO [dbo].[SystemEntities]
           ([EntityTypeID]
           ,[LastUpdateUserID])
     VALUES
           (@entitytypeid
           ,@userid)

set @roleid = SCOPE_IDENTITY()

INSERT INTO [dbo].[Roles]
           ([RoleID]
           ,[RoleName]
           ,[RoleDescription]
           ,[Comments]
           ,[LastUpdateUserID])
     VALUES
           (@roleid
           ,@roleidentifier
           ,@roledescription
           ,@rolecomments
           ,@userid)
           
set @newentityid = @roleid

if @@ERROR = 0
	commit transaction
else
	rollback transaction
	
return
GO
