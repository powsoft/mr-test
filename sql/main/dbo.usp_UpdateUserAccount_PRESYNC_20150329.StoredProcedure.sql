USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UpdateUserAccount_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec usp_UpdateUserAccount '62969','abc','Marks1','amarks1231'
CREATE procedure [dbo].[usp_UpdateUserAccount_PRESYNC_20150329]
  @PersonId varchar(20),
	@FirstName varchar(50),
	@LastName varchar(50),
	@Password varchar(50)
as

Begin

	Update Persons SET FirstName=@FirstName,LastName=@LastName where PersonID=@PersonId
	
	update Logins SET Password=@Password where OwnerEntityId=@PersonId
	
END


----41504,17

--sELECT * FROM Persons WHERE PersonId=41504
GO
