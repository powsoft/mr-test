USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[zTestScripts_LoadEntities_Prep]    Script Date: 06/25/2015 18:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[zTestScripts_LoadEntities_Prep]

as
/*
exec prUtil_Load_Clusters
exec prUtil_Load_Stores
exec prUtil_Load_Suppliers
exec prUtil_Load_Manufacturers
exec prUtil_Load_Brands
exec prUtil_Load_ProductCategories
exec prUtil_Load_Products
exec prUtil_Load_StoreSetup
*/


delete from ProductPrices where ProductID > 3000

delete 
--select *
from StoreTransactions
where ProductID > 1144

delete
--select *
from InventoryPerpetual
where ProductID > 1144

delete
--select *
from StoreSetup
where StoreID > 7588
--go

delete
--select * 
from ProductCategoryAssignments
where ProductID > 1144
--go

delete
--select * 
from ProductBrandAssignments
where ProductID > 1144
--go

delete
--select * 
from ProductIdentifiers
where ProductID > 1144
--go



delete
--select * 
from Products 
where ProductID > 1144
--go

delete  
--select *
from ProductCategories
where ProductCategoryID > 7
--go

delete from StoreTransactions where BrandID > 0
delete from InventoryPerpetual where BrandID > 0

delete
--select *
from Brands
where BrandID > 0
--go

delete
--select *
FROM  ContactInfo
WHERE (ContactID > 7326)
--go

delete
--select *
FROM  Addresses
--order by AddressID desc
WHERE (AddressID > 7403)

delete
--select *
from Manufacturers
where ManufacturerID > 0


delete
--select *
FROM  ContactInfo
WHERE (ContactID > 7326)
--go

delete
--select *
FROM  Addresses
--order by AddressID desc
WHERE (AddressID > 7403)

delete
--select *
from Suppliers
where SupplierID > 7584
--go

delete
--select *
FROM  ContactInfo
WHERE (ContactID > 7326)
--go

delete
--select *
FROM  Addresses
--order by AddressID desc
WHERE (AddressID > 7403)

delete
--select *
from Memberships
where OrganizationEntityID is not null
--WHERE ChainID > 3
--order by OrganizationEntityID
--go
--update Memberships set hierarchyid = null

delete
--select * 
from Stores where StoreName = 'worldmart' 
--go

--select * from Memberships where OrganizationEntityID is not null

delete
--select *
FROM  Clusters
WHERE (ChainID > 3)

--delete from DataTrue_EDI..Load_Manufacturers


delete
--select *
from ContactInfo
where OwnerEntityID > 24000

delete
--select *
from Addresses
where OwnerEntityID > 24000

update l set l.LoadStatus = 0
--select *
from DataTrue_EDI.dbo.Load_Manufacturers l

update l set l.LoadStatus = 0
--select *
from DataTrue_EDI.dbo.Load_Stores l
--go

update l set l.LoadStatus = 0
--select *
from DataTrue_EDI.dbo.Load_StoreClusters l
where RecordID > 8
--go




update l set l.LoadStatus = 0
--select *
from DataTrue_EDI.dbo.Load_Brands l
--go

update l set l.LoadStatus = 0
--select *
from DataTrue_EDI.dbo.Load_ProductCategories l
--go

update l set l.LoadStatus = 0
--select *
from DataTrue_EDI.dbo.Load_Products l
--go

update l set l.LoadStatus = 0
--select *
from DataTrue_EDI.dbo.Load_StoreSetup l
--go

update l set l.LoadStatus = 0
--select *
from DataTrue_EDI.dbo.Load_Suppliers l
--go
GO
