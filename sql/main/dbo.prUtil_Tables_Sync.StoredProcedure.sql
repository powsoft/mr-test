USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Tables_Sync]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prUtil_Tables_Sync]

as




INSERT INTO [DataTrue_Report].[dbo].[Addresses]
           ([OwnerEntityID]
           ,[AddressDescription]
           ,[Address1]
           ,[Address2]
           ,[City]
           ,[CountyName]
           ,[State]
           ,[PostalCode]
           ,[Country]
           ,[Comments]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate])
SELECT [OwnerEntityID]
      ,[AddressDescription]
      ,[Address1]
      ,[Address2]
      ,[City]
      ,[CountyName]
      ,[State]
      ,[PostalCode]
      ,[Country]
      ,[Comments]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
  FROM [DataTrue_Main].[dbo].[Addresses]
  where AddressID not in (select AddressID from [DataTrue_Report].[dbo].[Addresses])

/*
UPDATE ra
   SET ra.[OwnerEntityID] = ma.[OwnerEntityID]
      ,ra.[AddressDescription] = ma.[AddressDescription]
      ,ra.[Address1] = ma.[Address1]
      ,ra.[Address2] = ma.[Address2]
      ,ra.[City] = ma.[City]
      ,ra.[CountyName] = ma.[CountyName
      ,ra.[State] = ma.[State]
      ,ra.[PostalCode] = ma.[PostalCode]
      ,ra.[Country] = ma.[Country]
      ,ra.[Comments] = ma.[Comments]
      ,ra.[DateTimeCreated] = ma.[DateTimeCreated]
      ,ra.[LastUpdateUserID] = ma.[LastUpdateUserID]
      ,ra.[DateTimeLastUpdate] = ma.[DateTimeLastUpdate]
from [DataTrue_Report].[dbo].[Addresses] ra
inner join [DataTrue_Main].[dbo].[Addresses] ma
on ra.addressid = ma.addressid

*/
















return
GO
