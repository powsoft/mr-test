USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prPerson_Create]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prPerson_Create]
@firstname nvarchar(50),
@lastname nvarchar(50),
@middlename nvarchar(50)=null,
@personid int output

/*
prPerson_Create 'John', 'Doe', 'One', 0
*/

as

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @MyID int
declare @entitytypeid int
--declare @personid int

set @MyID = 40377

begin try

begin transaction

select @entitytypeid = EntityTypeID
--select EntityTypeID
from dbo.EntityTypes
where upper(EntityTypeName) = 'PERSON'

INSERT INTO [dbo].[SystemEntities]
           ([EntityTypeID]
           ,[LastUpdateUserID])
     VALUES
           (@entitytypeid
           ,@MyID)

set @personid = SCOPE_IDENTITY()

INSERT INTO [dbo].[Persons]
           ([personid]
           ,[FirstName]
           ,[LastName]
           ,[MiddleName]
           ,[LastUpdateUserID])
     VALUES
           (@personid
           ,@firstname
           ,@lastname
           ,@middlename
           ,@MyID)

	commit transaction
	
end try
	
begin catch
		rollback transaction
		
		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
end catch

return
GO
