USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCUpdateEntityTables]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCUpdateEntityTables]
as

/*
INSERT INTO [DataTrue_EDI].[dbo].[Stores]
           ([StoreID]
           ,[ChainID]
           ,[StoreName]
           ,[StoreIdentifier]
           ,[ActiveFromDate]
           ,[ActiveLastDate]
           ,[Comments]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[EconomicLevel]
           ,[StoreSize]
           ,[Custom1]
           ,[Custom2]
           ,[Custom3]
           ,[DunsNumber])
SELECT [StoreID]
      ,[ChainID]
      ,[StoreName]
      ,[StoreIdentifier]
      ,[ActiveFromDate]
      ,[ActiveLastDate]
      ,[Comments]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[EconomicLevel]
      ,[StoreSize]
      ,[Custom1]
      ,[Custom2]
      ,[Custom3]
      ,[DunsNumber]
  FROM [DataTrue_Main].[dbo].[Stores]
where StoreID not in
(select StoreID from [DataTrue_EDI].[dbo].[Stores])

update es set es.GroupNumber = ms.GroupNumber
,es.Custom1 = ms.Custom1
,es.Custom2 = ms.Custom2
,es.Custom3 = ms.Custom3
,es.Custom4 = ms.Custom4
,es.SBTNumber = ms.SBTNumber
,es.DunsNumber = ms.DunsNumber
,es.StoreName = ms.StoreName
,es.EconomicLevel = ms.EconomicLevel
from [DataTrue_EDI].[dbo].[Stores] es
inner join [DataTrue_Main].[dbo].[Stores] ms
on es.StoreID = ms.storeid
*/


INSERT INTO [DataTrue_Report].[dbo].[Stores]
           ([StoreID]
           ,[ChainID]
           ,[StoreName]
           ,[StoreIdentifier]
           ,[ActiveFromDate]
           ,[ActiveLastDate]
           ,[Comments]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[EconomicLevel]
           ,[StoreSize]
           ,[Custom1]
           ,[Custom2]
           ,[Custom3]
           ,[DunsNumber])
SELECT [StoreID]
      ,[ChainID]
      ,[StoreName]
      ,[StoreIdentifier]
      ,[ActiveFromDate]
      ,[ActiveLastDate]
      ,[Comments]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[EconomicLevel]
      ,[StoreSize]
      ,[Custom1]
      ,[Custom2]
      ,[Custom3]
      ,[DunsNumber]
  FROM [DataTrue_Main].[dbo].[Stores]
where StoreID not in
(select StoreID from [DataTrue_Report].[dbo].[Stores])

update es set es.GroupNumber = ms.GroupNumber
,es.Custom1 = ms.Custom1
,es.Custom2 = ms.Custom2
,es.Custom3 = ms.Custom3
,es.Custom4 = ms.Custom4
,es.SBTNumber = ms.SBTNumber
,es.DunsNumber = ms.DunsNumber
,es.StoreName = ms.StoreName
,es.EconomicLevel = ms.EconomicLevel
from [DataTrue_Report].[dbo].[Stores] es
inner join [DataTrue_Main].[dbo].[Stores] ms
on es.StoreID = ms.storeid

/*
--update EDI database
INSERT INTO [DataTrue_EDI].[dbo].[Products]
           ([ProductID]
           ,[ProductName]
           ,[Description]
           ,[ActiveStartDate]
           ,[ActiveLastDate]
           ,[Comments]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[UOM]
           ,[UOMQty]
           ,[PACKQty])
SELECT [ProductID]
      ,[ProductName]
      ,[Description]
      ,[ActiveStartDate]
      ,[ActiveLastDate]
      ,[Comments]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[UOM]
      ,[UOMQty]
      ,[PACKQty]
  FROM [DataTrue_Main].[dbo].[Products]
where ProductID not in
(select ProductID from [DataTrue_EDI].[dbo].[Products])

INSERT INTO [DataTrue_EDI].[dbo].[ProductIdentifiers]
           ([ProductID]
           ,[ProductIdentifierTypeID]
           ,[OwnerEntityId]
           ,[IdentifierValue]
           ,[Comments]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate])
SELECT [ProductID]
      ,[ProductIdentifierTypeID]
      ,[OwnerEntityId]
      ,[IdentifierValue]
      ,[Comments]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
  FROM [DataTrue_Main].[dbo].[ProductIdentifiers]
where ProductID not in
(select ProductID from [DataTrue_EDI].[dbo].[ProductIdentifiers])

*/

INSERT INTO [DataTrue_EDI].[dbo].[Suppliers]
           ([SupplierID]
           ,[SupplierName]
           ,[SupplierIdentifier]
           ,[SupplierDescription]
           ,[ActiveStartDate]
           ,[ActiveLastDate]
           ,[RegistrationDate]
           ,[Comments]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[DunsNumber])
SELECT [SupplierID]
      ,[SupplierName]
      ,[SupplierIdentifier]
      ,[SupplierDescription]
      ,[ActiveStartDate]
      ,[ActiveLastDate]
      ,[RegistrationDate]
      ,[Comments]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[DunsNumber]
  FROM [DataTrue_Main].[dbo].[Suppliers]
where SupplierID not in 
(select SupplierID from [DataTrue_EDI].[dbo].[Suppliers])

update rp set rp.productname = mp.productname, rp.Description = mp.description
  FROM [DataTrue_Main].[dbo].[Products] mp
inner join [DataTrue_EDI].[dbo].[Products] rp
on mp.ProductID = rp.ProductID 
--select * into import.dbo.ediproducts_20111221 from [DataTrue_EDI].[dbo].[Products]

--update report database

INSERT INTO [DataTrue_Report].[dbo].[Products]
           ([ProductID]
           ,[ProductName]
           ,[Description]
           ,[ActiveStartDate]
           ,[ActiveLastDate]
           ,[Comments]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[UOM]
           ,[UOMQty]
           ,[PACKQty])
SELECT [ProductID]
      ,[ProductName]
      ,[Description]
      ,[ActiveStartDate]
      ,[ActiveLastDate]
      ,[Comments]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[UOM]
      ,[UOMQty]
      ,[PACKQty]
  FROM [DataTrue_Main].[dbo].[Products]
where ProductID not in
(select ProductID from [DataTrue_Report].[dbo].[Products])

INSERT INTO [DataTrue_Report].[dbo].[ProductIdentifiers]
           ([ProductID]
           ,[ProductIdentifierTypeID]
           ,[OwnerEntityId]
           ,[IdentifierValue]
           ,[Comments]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate])
SELECT [ProductID]
      ,[ProductIdentifierTypeID]
      ,[OwnerEntityId]
      ,[IdentifierValue]
      ,[Comments]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
  FROM [DataTrue_Main].[dbo].[ProductIdentifiers]
where ProductID not in
(select ProductID from [DataTrue_Report].[dbo].[ProductIdentifiers])


INSERT INTO [DataTrue_Report].[dbo].[Suppliers]
           ([SupplierID]
           ,[SupplierName]
           ,[SupplierIdentifier]
           ,[SupplierDescription]
           ,[ActiveStartDate]
           ,[ActiveLastDate]
           ,[RegistrationDate]
           ,[Comments]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[DunsNumber])
SELECT [SupplierID]
      ,[SupplierName]
      ,[SupplierIdentifier]
      ,[SupplierDescription]
      ,[ActiveStartDate]
      ,[ActiveLastDate]
      ,[RegistrationDate]
      ,[Comments]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[DunsNumber]
  FROM [DataTrue_Main].[dbo].[Suppliers]
where SupplierID not in 
(select SupplierID from [DataTrue_Report].[dbo].[Suppliers])

update rp set rp.productname = mp.productname, rp.Description = mp.description
  FROM [DataTrue_Main].[dbo].[Products] mp
inner join [DataTrue_Report].[dbo].[Products] rp
on mp.ProductID = rp.ProductID 


MERGE INTO datatrue_edi.dbo.productbrandassignments ba

USING (select productid, brandid, customownerentityid, lastupdateuserid, datetimecreated, datetimelastupdate
	from datatrue_main.dbo.productbrandassignments) s
on ba.ProductID = s.ProductID
and ba.BrandID = s.BrandID
and ba.customownerentityid = s.customownerentityid

WHEN NOT MATCHED 

        THEN INSERT
           ([ProductID]
           ,[BrandID]
           ,customownerentityid
           ,lastupdateuserid
           ,datetimecreated
           ,datetimelastupdate)
     VALUES
     (S.[ProductID]
           ,S.[BrandID]
           ,s.customownerentityid
           ,s.lastupdateuserid
           ,s.datetimecreated
           ,s.datetimelastupdate);

return
GO
