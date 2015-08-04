USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prPerson_Attributes_Get]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prPerson_Attributes_Get]
@loginid nvarchar(100)

as
/*
prPerson_Attributes_Get 'charlie.clark@icontroldsd.com'
prPerson_Attributes_Get 'sean.zlotnitsky@icontroldsd.com'
prPerson_Attributes_Get 'DRehe@mailBBU.com'
prPerson_Attributes_Get 'lwinter@bbumail.com'
prPerson_Attributes_Get 'ann@tttradingnj.com'


EntityTypeName=Role_Person_DataTrue EntityTypeID=12
RoleName=DataTrue_Admin RoleID(entityid)=40382
MembershipTypeName=DataTrueRoleMembership MembershipTypeID=9
*/
--declare @loginid nvarchar(100) = 'sean.zlotnitsky@icontroldsd.com'
declare @MyID int
declare @attributes nvarchar(4000)
declare @oneattribute nvarchar(500)
declare @personentityid int
declare @ownerentityid int
declare @rec cursor
declare @rec2 cursor

set @MyID = 40383
set @attributes = ''

select @personentityid = p.PersonID
from Logins l
inner join Persons p
on l.OwnerEntityId = p.PersonID
where l.Login = @loginid
--print @personentityid
--Check for Chain or Supplier
declare @userData TABLE(
Attributes varchar(max) NOT NULL
)

declare @IsChain varchar(10)
if Exists(select   AttributeName + '-' + AttributeValue  from AttributeDefinitions d 	inner join AttributeValues v 	on d.AttributeID = v.AttributeID 	where OwnerEntityID = @personentityid 	and v.IsActive = 1  and AttributeName = 'ChainAccess')
begin
		set @IsChain = 'True'
		if exists(select * FROM RetailerAccess where personid = @personentityid)
		begin  
		insert INTO @userData  
			select   AttributeName + '-' + AttributeValue  
			from AttributeDefinitions d
			inner join AttributeValues v
			on d.AttributeID = v.AttributeID
			where OwnerEntityID = @personentityid
			and v.IsActive = 1 AND d.AttributeID <> 20
			 
		insert INTO @userData 	select DISTINCT  'BannerAccess-' + rtrim(ltrim(banneraccess))  FROM RetailerAccess where personid = @personentityid 
		end 
		else
		begin
		insert INTO @userData 
		select   AttributeName + '-' + AttributeValue  
			from AttributeDefinitions d
			inner join AttributeValues v
			on d.AttributeID = v.AttributeID
			where OwnerEntityID = @personentityid
			and v.IsActive = 1
		end 
end

if Exists(select   AttributeName + '-' + AttributeValue  from AttributeDefinitions d 	inner join AttributeValues v 	on d.AttributeID = v.AttributeID 	where OwnerEntityID = @personentityid 	and v.IsActive = 1  and AttributeName = 'ManufacturerAccess')
begin
		set @IsChain = 'False'
		if exists(select * FROM RetailerAccess where personid = @personentityid)
		begin  
		insert INTO @userData  
			select   AttributeName + '-' + AttributeValue  
			from AttributeDefinitions d
			inner join AttributeValues v
			on d.AttributeID = v.AttributeID
			where OwnerEntityID = @personentityid
			and v.IsActive = 1 AND d.AttributeID <> 20
			 
		insert INTO @userData 	select DISTINCT  'BannerAccess-' + rtrim(ltrim(banneraccess))  FROM RetailerAccess where personid = @personentityid 
		end 
		else
		begin
		insert INTO @userData 
		select   AttributeName + '-' + AttributeValue  
			from AttributeDefinitions d
			inner join AttributeValues v
			on d.AttributeID = v.AttributeID
			where OwnerEntityID = @personentityid
			and v.IsActive = 1
		end 
end

if Exists(select   AttributeName + '-' + AttributeValue   from AttributeDefinitions d 	inner join AttributeValues v 	on d.AttributeID = v. AttributeID 	where OwnerEntityID = @personentityid 	and v.IsActive = 1  and AttributeName = 'SupplierAccess')
 begin
	
	set @IsChain = 'False'
	if exists(select * FROM SupplierAccess where personid = @personentityid)
	begin   
	insert INTO @userData 
	select AttributeName + '-' + AttributeValue
		from AttributeDefinitions d
		inner join AttributeValues v
		on d.AttributeID = v.AttributeID
		where OwnerEntityID = @personentityid
		and v.IsActive = 1   AND d.AttributeID <> 20
		 insert INTO @userData  
		select DISTINCT  'BannerAccess-' +  rtrim(ltrim(banneraccess))  FROM SupplierAccess where personid = @personentityid 
	end	
	else
	begin
	insert INTO @userData 
	select   AttributeName + '-' + AttributeValue  
		from AttributeDefinitions d
		inner join AttributeValues v
		on d.AttributeID = v.AttributeID
		where OwnerEntityID = @personentityid
		and v.IsActive = 1
	
	end
	end	


 	set @rec = CURSOR local fast_forward FOR
		 SELECT Attributes from @userData 
	open @rec

		fetch next from @rec into @oneattribute

		while @@FETCH_STATUS = 0
			begin
				set @attributes = @attributes + @oneattribute + '|'	
				fetch next from @rec into @oneattribute	
			end
		
	close @rec
	deallocate @rec
  
 

set @rec2 = CURSOR local fast_forward FOR
	select OrganizationEntityID 
	from Memberships
	where MemberEntityID = @personentityid
	and MembershipTypeID = 9
/*
	select OrganizationEntityID 
	from Memberships
	where MemberEntityID = 40739
	and MembershipTypeID = 9
*/	
	
	
open @rec2

fetch next from @rec2 into @ownerentityid

while @@FETCH_STATUS = 0
	begin
		set @rec = CURSOR local fast_forward FOR
			select AttributeName + '-' + AttributeValue
			from AttributeDefinitions d
			inner join AttributeValues v
			on d.AttributeID = v.AttributeID
			where OwnerEntityID = @ownerentityid
			and v.IsActive = 1

		open @rec

		fetch next from @rec into @oneattribute

		while @@FETCH_STATUS = 0
			begin
				set @attributes = @attributes + @oneattribute + '|'	
				fetch next from @rec into @oneattribute	
			end
			
		close @rec
		deallocate @rec
	end
	
close @rec2
deallocate @rec2

select @attributes as Column1

return
GO
