USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Login_Lookup]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Login_Lookup]
as

select FirstName, LastName, Login, Password
from Persons p
inner join Logins l
on p.PersonID = l.OwnerEntityId
where PersonID >= 40735
order by Firstname

declare @personentityid int = 41379 --41375 --41363 --41359 --40735--41370 --40735

select * from Logins where OwnerEntityId = @personentityid
select * from attributevalues where OwnerEntityId = @personentityid
select * from Memberships where MemberEntityId = @personentityid

select personid
from persons
where personid not in
(select ownerentityid from AttributeValues where AttributeID = 15)


declare @rec cursor
declare @personid int
declare @personlogin nvarchar(100)
declare @access nvarchar(50)
declare @dummy tinyint

set @rec = CURSOR local fast_forward FOR
	select distinct email, access from Import.dbo.SVUsers
	
open @rec

fetch next from @rec into @personlogin, @access

while @@FETCH_STATUS = 0
	begin

		if 	upper(@access) In ('FULL','READ')
			begin
				select @personid = ownerentityid from Logins where login = @personlogin
				select * from AttributeValues where OwnerEntityID = @personid and AttributeID = 15
				--select * from Memberships where OrganizationEntityID = 40382 and MemberEntityID = @personid
				if @@ROWCOUNT > 0
					begin
						set @dummy = 1
--print 'Already There|' + @personlogin + '|' + @access + str(@personid)				
					end
				else
					begin
print 'Need to Add|' + @personlogin + '|' + @access + str(@personid)
/*
INSERT INTO [DataTrue_Main].[dbo].[Memberships]
           ([MembershipTypeID]
           ,[OrganizationEntityID]
           ,[MemberEntityID]
           ,[LastUpdateUserID])
     VALUES
           (9
           ,40382
           ,@personid
           ,2)
*/

					
					end
			end
		fetch next from @rec into @personlogin, @access	
	end
	
close @rec
deallocate @rec


return
GO
