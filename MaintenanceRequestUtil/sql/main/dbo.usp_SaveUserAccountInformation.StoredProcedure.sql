USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SaveUserAccountInformation]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec usp_SavePOPrintInformation '06/18/2012', 40557, 40365, 15
CREATE  Procedure [dbo].[usp_SaveUserAccountInformation]
     @PersonId varchar(50),
     @FirstName varchar(50),
     @LastName varchar(50),
     @Email varchar(50),
     @Address varchar(150),
     @City varchar(50),
     @State varchar(50),
     @PostalCode varchar(50),
     @Phone varchar(50),
     @Mobile varchar(50),
     @Fax varchar(50)
     
as
begin

	Declare @ContactId numeric(10)
    Select @ContactId = (ContactId) from ContactInfo where OwnerEntityID=@PersonId
    
    if(@ContactId is null)
		INSERT INTO ContactInfo([OwnerEntityID],[FirstName],[LastName],[DeskPhone],[MobilePhone],[Fax],[Email],[DateTimeCreated],[ContactTypeID],LastUpdateUserID)
	    VALUES (@PersonId,@FirstName,@LastName,@Phone,@Mobile,@Fax,@Email,GETDATE(),0,@PersonId)
	else
		Update ContactInfo set FirstName=@FirstName, LastName=@LastName, Email=@Email, DeskPhone=@Phone, MobilePhone=@Mobile, Fax=@Fax where ContactID=@ContactId
	
	Declare @AddressId numeric(10)
    Select @AddressId = (AddressId) from Addresses where OwnerEntityID=@PersonId
    
    if(@AddressId is null)
		INSERT INTO Addresses ([OwnerEntityID],[Address1],[City],[State],[PostalCode],[DateTimeCreated],[AddressTypeId],LastUpdateUserID)
		VALUES (@PersonId,@Address,@City,@State, @PostalCode,GETDATE(),0,@PersonId)
	else
		Update Addresses set Address1=@Address, City=@City, State=@State, PostalCode=@PostalCode, DateTimeLastUpdate=GETDATE() where AddressID=@AddressId
	
end
GO
