USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_UserSetup_Supplier]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_UserSetup_Supplier]
as


INSERT INTO [DataTrue_Main].[dbo].[AttributeValues]
           ([OwnerEntityID]
           ,[AttributeID]
           ,[AttributeValue]
           ,[IsActive]
           ,[LastUpdateUserID])
SELECT [PersonID]
		,15
		,'FULL'
		,1
		,2

  FROM [DataTrue_Main].[dbo].[Persons]
where personid >= 41359

select * from Import.dbo.SHAValues

select *
--update l set Custom1 = v.SHAValue
from Import.dbo.SHAValues v
inner join Logins l
on v.Email = l.Login

/*
--************enable OLE Automation Procedures***************
EXEC sp_configure 'Ole Automation Procedures';
GO
--The following example shows how to enable OLE Automation procedures.

--Copy
sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
sp_configure 'Ole Automation Procedures', 0;
GO
RECONFIGURE;
GO
--*****************************************************

--send to Gilad
	select FirstName + ' ' + LastName as Name, Login, password
	from Logins l
	inner join Persons p
	on l.OwnerEntityId = p.PersonID
	where p.PersonID > 41475
	order by FirstName + ' ' + LastName

	select LoginID, Login, FirstName + ' ' + LastName, Custom1, password
	from Logins l
	inner join Persons p
	on l.OwnerEntityId = p.PersonID
	where p.PersonID > 41475
	--and LOGIN = 'Patsy.L.Lundquist@supervalu.com'
	and LoginID not in (Select LoginID from Import.dbo.LoginsAdded)
	order by p.PersonID

*/
select CAST(0 as int) as LoginID into Import.dbo.LoginsAdded
truncate table Import.dbo.LoginsAdded

select * from Import.dbo.LoginsAdded

declare @rec cursor
declare @loginname nvarchar(50)
declare @loginpassword nvarchar(50)
declare @fullname nvarchar(50)
declare @loginid int
declare @shavalue nvarchar(255)
declare @ownerentityid int
declare @supplierid nvarchar(50)

 DECLARE @nCDO INT, 
        @nOLEResult INT, 
        @nOutput INT, 
        @sProgID VARCHAR(50)

    SET @sProgID = 'EncPwd.SHA'



set @rec = CURSOR local fast_forward FOR
	select v.AttributeValue, l.OwnerEntityId, LoginID, Login, FirstName + ' ' + LastName, Custom1
	from Logins l
	inner join Persons p
	on l.OwnerEntityId = p.PersonID
	inner join AttributeValues v
	on p.personid = v.OwnerEntityID
	where p.PersonID > 41476
	--and LOGIN = 'Patsy.L.Lundquist@supervalu.com'
	and LoginID not in (Select LoginID from Import.dbo.LoginsAdded)
	order by p.PersonID
	
open @rec

fetch next from @rec into @supplierid, @ownerentityid, @loginid, @loginname, @fullname, @shavalue

while @@FETCH_STATUS = 0
	begin
print @loginname

		--EXECUTE @nOLEResult = sp_OACreate @sProgID, @nCDO OUT
		
INSERT INTO [DataTrue_Main].[dbo].[AttributeValues]
           ([OwnerEntityID]
           ,[AttributeID]
           ,[AttributeValue]
           ,[IsActive]
           ,[LastUpdateUserID])
     VALUES
           (@ownerentityid
           ,15
           ,'FULL'
           ,1
           ,2)

INSERT INTO [DataTrue_Main].[dbo].[AttributeValues]
           ([OwnerEntityID]
           ,[AttributeID]
           ,[AttributeValue]
           ,[IsActive]
           ,[LastUpdateUserID])
     VALUES
           (@ownerentityid
           ,16
           ,'FULL'
           ,1
           ,2)
		
INSERT INTO [DataTrue_Main].[dbo].[AttributeValues]
           ([OwnerEntityID]
           ,[AttributeID]
           ,[AttributeValue]
           ,[IsActive]
           ,[LastUpdateUserID])
     VALUES
           (@ownerentityid
           ,21
           ,CAST(@ownerentityid as nvarchar)
           ,1
           ,2)		
--/*
		exec prUser_Reporting_Role_Manage_MultiChain
			'ReportSupplier'
			,@loginname
			,@shavalue --'033532C8 554FA843 8D72757C B3F5FC1C 76586270'
			,@fullname
			,@supplierid
			,3000
			,'ADD'
			,''
--*/			
		--EXECUTE @nOLEResult = sp_OADestroy @nCDO

		insert into Import.dbo.LoginsAdded (LoginID) values(@loginid)
		
		fetch next from @rec into  @supplierid, @ownerentityid, @loginid, @loginname, @fullname, @shavalue

	end
	
close @rec
deallocate @rec

/*
alter procedure [dbo].[prUser_Reporting_Role_Manage_MultiChain]
@rolename nvarchar(255) --ReportAdmin ReportChain ReportStore ReportSupplier ReportManufacturer
,@loginname nvarchar(50) --email address preferred
,@loginpassword nvarchar(50)
,@fullname nvarchar(50)
,@organizationentityid nvarchar(100)
,@packagetype int
,@actioncode nvarchar(50) --ADD UPDATE CHANGE DELETE
,@actionresult nvarchar(1000) output


prUser_Reporting_Role_Manage_MultiChain 'ReportChain', 'sabrina.m.gonzalez@supervalu.com', 
'ED8BABA6 8C07D9E7 2A58BF18 78EA9491 4AD7CE44','Sabrina Gonzalez','7608,40393',3000,'ADD', '' 





"033532C8 554FA843 8D72757C B3F5FC1C 76586270"
*/
return
GO
