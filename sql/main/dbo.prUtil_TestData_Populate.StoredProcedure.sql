USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_TestData_Populate]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_TestData_Populate]
as
--truncate table [dbo].[StoreSetup]

INSERT INTO [dbo].[StoreSetup]
           ([StoreID]
           ,[ProductID]
           ,[SupplierID]
           ,[BrandID]
           --,[SetupQty]
           ,[ActiveStartDate]
           ,[ActiveLastDate]
           ,[SetupReportedToRetailerDate]
           ,[FileName]
           ,[Comments]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate])

select distinct StoreID
           ,ProductID
           ,SupplierID
           ,BrandID
           --,100
           ,'2000-01-01'
           ,'2025-01-01'
           ,'2011-01-01'
           ,''
           ,''
           ,'2011-01-01'
           ,2
           ,'2011-01-01'
from storeTransactions


INSERT INTO [dbo].[ChainProductFactors]
           ([ChainID]
           ,[ProductID]
           ,[BrandID]
           ,[BaseUnitsCalculationPerNoOfweeks]
           ,[ActiveStartDate]
           ,[ActiveEndDate]
           ,[LastUpdateUserID])
     
     select distinct 3
           ,ProductID
           ,0
           ,17
           ,'1/1/2000'
           ,'1/1/2025'
           ,2
           from Products
GO
