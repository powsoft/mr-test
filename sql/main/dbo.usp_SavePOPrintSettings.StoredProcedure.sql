USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SavePOPrintSettings]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_SavePOPrintSettings]
     @SupplierId varchar(50),
     @CompanyName varchar(50),
     @Slogan varchar(50),
     @Address varchar(50),
     @City varchar(50),
     @State varchar(50),
     @ZipCode varchar(10),
     @Phone varchar(20),
     @Fax varchar(20),
     @BillToName varchar(50),
     @BillToCompany varchar(50),
     @BillToAddress varchar(50),
     @BillToCity varchar(50),
     @BillToState varchar(50),
     @BillToZipCode varchar(10),
     @BillToPhone varchar(20),
     @BillToFax varchar(20),
     @ContactName varchar(50),
     @ContactPhone varchar(20),
     @ContactEmail varchar(50),
     @ContactFax varchar(20),
     @POPrefix varchar(10),
     @POBeginFrom varchar(10)
as
begin
    Delete from  [PO_PrintSettings] where SupplierId=@SupplierId
           
     INSERT INTO [DataTrue_Main].[dbo].[PO_PrintSettings]
           ([SupplierId]
           ,[CompanyName]
           ,[Slogan]
           ,[Address]
           ,[City]
           ,[State]
           ,[ZipCode]
           ,[Phone]
           ,[Fax]
           ,[BillToName]
           ,[BillToCompany]
           ,[BillToAddress]
           ,[BillToCity]
           ,[BillToState]
           ,[BillToZipCode]
           ,[BillToPhone]
           ,[BillToFax]
           ,[ContactName]
           ,[ContactPhone]
           ,[ContactEmail]
           ,[ContactFax]
           ,[POPrefix]
           ,[POBeginFrom])
     VALUES
           (@SupplierId
           ,@CompanyName
           ,@Slogan
           ,@Address
           ,@City
           ,@State
           ,@ZipCode
           ,@Phone
           ,@Fax
           ,@BillToName
           ,@BillToCompany
           ,@BillToAddress
           ,@BillToCity
           ,@BillToState
           ,@BillToZipCode
           ,@BillToPhone
           ,@BillToFax
           ,@ContactName
           ,@ContactPhone
           ,@ContactEmail
           ,@ContactFax
           ,@POPrefix
           ,@POBeginFrom)
    
end
GO
