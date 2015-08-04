USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_ItemGroups_Manage]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prMaintenanceRequest_ItemGroups_Manage]
as

declare @rec cursor
declare @rec2 cursor
declare @rec3 cursor
declare @rec4 cursor
declare @upc nvarchar(50)
declare @productid int
declare @productdescription nvarchar(100)
declare @brandid int
declare @mrupc nvarchar(50)
declare @checkdigit char(1)
declare @lenofupc tinyint
declare @maintenancerequestid int
--declare @addnewproduct smallint=1
declare @itemdescription nvarchar(255)
declare @upc12 nvarchar(50)
declare @upc11 nvarchar(50)
declare @chainid int
declare @addnewproduct bit=1
declare @productfound bit
declare @approved bit
declare @recten cursor
declare @brandname nvarchar(50)
declare @supplierid int
declare @manufactureridentifier nvarchar(100)
declare @manufacturerid int
declare @requesttypeid int
declare @requestsource nvarchar(50)
/*
select top 100 * from dbo.MaintenanceRequests where supplierid = 40567
select top 100 * from dbo.MaintenanceRequests where chainid = 44285 and supplierid = 44269
select * from productidentifiers where productid = 16396 --16640 024126008221
select * 
--update mr set mr.dtproductdescription = p.description
from dbo.MaintenanceRequests mr
inner join products p
on mr.productid = p.productid
where mr.productid is not null and mr.dtproductdescription is null
select * from entitytypes
*/
select cast(primarygrouplevel as int) as grouplevel, cast(Itemgroup as int) as groupid, (select suppliername from Suppliers where SupplierID = SupplierID) as VendorName, cast(Itemgroup as int) as categoryidentifier, cast(null as int) as ParentGroupID,
CAST(null as nvarchar(255)) as parentcategoryidentifier
into #tempcategories --drop table #tempcategories
--select *
from dbo.MaintenanceRequests 
where chainid = 44285 and supplierid = 44269
--and groupid = 4



return
GO
