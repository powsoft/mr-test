USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SaveSupplierAddress]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[usp_SaveSupplierAddress]
 @SupplierId varchar(10),
 @Address1 varchar(50),
 @Address2 varchar(50),
 @City varchar(50),
 @CountyName varchar(20),
 @State varchar(50),
 @PostalCode varchar(50),
 @Country varchar(50),
 @CurrentUserId varchar(10)
 
       
as
begin
	Declare @AddressExist int 
	Select @AddressExist=COUNT(AddressId) from Addresses where OwnerEntityID=@SupplierId
	
    if(@AddressExist=0)
		INSERT INTO [Addresses]([OwnerEntityID], [Address1], [Address2], [City], [CountyName], [State], [PostalCode], [Country],[DateTimeCreated], [LastUpdateUserID], [DateTimeLastUpdate], [AddressTypeID])
		VALUES(@SupplierId, @Address1, @Address2, @City, @CountyName, @State, @PostalCode, @Country, getDate(), @CurrentUserId, getDate(), 0)
    else
		UPDATE [DataTrue_Main].[dbo].[Addresses]
		   SET [Address1] =@Address1
			  ,[Address2] =@Address2
			  ,[City] = @City
			  ,[CountyName] = @CountyName
			  ,[State] = @State
			  ,[PostalCode] = @PostalCode
			  ,[Country] = @Country
			  ,[LastUpdateUserID] = @CurrentUserId
			  ,[DateTimeLastUpdate] = GETDATE()
		 WHERE [OwnerEntityID] = @SupplierId
end
GO
