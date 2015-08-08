USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[zTestScripts]    Script Date: 06/25/2015 18:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[zTestScripts]

as

select EntityTypeID, COUNT(EntityTypeID)
from SystemEntities e
group by EntityTypeID

select * from Stores


--***************Clusters******************

select *
--delete 
from Clusters where ChainID > 3 
order by ClusterID

select * 
--delete
from Memberships where ChainID > 3

select *
--update l set l.LoadStatus = 0
from DataTrue_EDI.dbo.Load_StoreClusters l
where RecordID > 8

select *
--delete
from Memberships
WHERE (OrganizationEntityID > 7600) OR
               --(OrganizationEntityID IS NULL) OR
               (OrganizationEntityID = 0)
               
select *
--delete
FROM  Clusters
WHERE (ChainID > 3)

--********************Stores*********************************

select * 
--delete
from Stores where StoreName = 'worldmart' 

--update Stores set chainid = 7608 where StoreName = 'worldmart'

select top 20 * from Stores order by StoreID desc
select * from Memberships where ChainID > 3

select *
--update l set l.LoadStatus = 0
from DataTrue_EDI.dbo.Load_Stores l

select *
--delete
from Memberships
WHERE ChainID > 3
               
select *
--delete
FROM  ContactInfo
WHERE (ContactID > 7326)     
     
--******************Suppliers**********************
select *
--delete
from ProductCosts
where SupplierID > 7584

select top 10 *
--delete
from Suppliers
where SupplierID > 7584
order by SupplierID desc               
return

--********************Brands*********************************
select *
--delete
from Brands
where BrandID > 0

update [DataTrue_EDI].[dbo].[Load_Brands] set LoadStatus = 0
--********************ProductCategories*********************************

select *
--delete  
from ProductCategories
where ProductCategoryID > 7


update [DataTrue_EDI].[dbo].[Load_ProductCategories] set LoadStatus = 0
--********************Products*********************************
select top 10 * 
--delete
from Products 
where ProductID > 1144
order by ProductID desc

select top 10 * 
--delete
from ProductIdentifiers 
where ProductID > 1144

select top 10 * 
--delete
from ProductIdentifiers
where ProductID > 1144

select top 10 * 
--delete
from ProductBrandAssignments
where ProductID > 1144

select * 
--delete
from ProductCategoryAssignments
where ProductID > 1144

update [DataTrue_EDI].[dbo].[Load_Products] set LoadStatus = 0

update [DataTrue_EDI].[dbo].[Load_Products] set chainidentifier = null

--********************Product Prices*********************************
select top 10 * 
--delete
from ProductPrices 
where ProductID > 1144
order by ProductID desc

--********************Product Costs*********************************
select top 10 * 
--delete
from ProductCosts
where ProductID > 1144
order by ProductID desc

--********************Store Setup*********************************

select *
--delete
from StoreSetup
where StoreID > 7588
GO
