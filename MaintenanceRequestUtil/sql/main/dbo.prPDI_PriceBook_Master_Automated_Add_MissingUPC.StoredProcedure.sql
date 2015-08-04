USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prPDI_PriceBook_Master_Automated_Add_MissingUPC]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prPDI_PriceBook_Master_Automated_Add_MissingUPC]
@chainid int,
@supplierid int
as

declare @myid int = 0

--get set of non Purchasable PKG with missing UPC
select  p.PDIItemNumber as PDIItemNo, MIN(RawProductIdentifier) as VIN, p.[RecordID], p.ItemDescription
into #temp_pkg_missing_upc 
--select *
from  datatrue_edi.dbo.temp_PDI_ItemPKG p
  --where 1 = 1
  inner join [DataTrue_EDI].dbo.Temp_PDI_Costs c
  on ltrim(rtrim(c.PDIItemNo)) = ltrim(rtrim(p.PDIItemNumber))
	  and c.PackageCode_Scrubbed = p.PackageCode_Scrubbed
	  and p.DataTrueChainID = @chainid
	  and p.DataTrueSupplierID = @supplierid
	  and p.DataTrueChainID = c.DataTrueChainID
	  and p.DataTrueSupplierID = c.DataTrueSupplierID
where p.DataTrueProductID is  null
  and p.Recordstatus = 0
  and c.RecordStatus = 0
  and c.DiscontinueDate is null
  --and c.PromotionEndDate is null
  and p.Purchasable = 'Y' 
group by p.PDIItemNumber, p.[RecordID], p.ItemDescription

--create fake UPC and use VIN instead UPC
declare @Insertted_Product table( id int, Comments nvarchar(100)  );


insert into [DataTrue_Main].[dbo].[Products]
		   ([ProductName]
		   ,[Description]
		   ,[ActiveStartDate]
		   ,[ActiveLastDate]
		   ,[LastUpdateUserID]
		   ,[UOM]
		   ,[UOMQty]
		   ,Comments
		   )
	output inserted.ProductID, inserted.Comments	into @Insertted_Product
select  ItemDescription ProductName
	   ,ItemDescription [Description]
	   ,'1/1/2013' ActiveStartDate
	   ,'12/31/2025' [ActiveLastDate]
	   ,@myid LastUpdateUserID
	   ,NULL UOM
	   ,NULL UOMQty
	   ,RecordID Comments
	   
from  #temp_pkg_missing_upc

print 'New Product w/o UPC'
select  * from @Insertted_Product

--insert into [DataTrue_Main].[dbo].[ProductIdentifiers]
--	   ([ProductID]
--	   ,[ProductIdentifierTypeID]
--	   ,[OwnerEntityId]
--	   ,[IdentifierValue]
--	   ,[LastUpdateUserID]
--	   ,[Comments])
--select  
--		pr.id
--	   ,2 --[ProductIdentifierTypeID]
--	   ,@chainid
--	   ,pkg.VIN
--	   ,0
--	   ,pkg.PDIItemNo
--from  #temp_pkg_missing_upc	 pkg
--		inner  join  @Insertted_Product  pr
--			on pr.Comments = pkg.RecordID 
	   

--set productid for PKG
update p set p.DataTrueProductID = pr.id
--select p.*
from  datatrue_edi.dbo.temp_PDI_ItemPKG p
	inner join #temp_pkg_missing_upc	 pkg
		on p.RecordID = pkg.RecordID
	inner  join  @Insertted_Product  pr
		on pr.Comments = pkg.RecordID 
where p.DataTrueChainID = @chainid
	  and p.DataTrueSupplierID = @supplierid
 

print 'Package logic'
--TO DO  update using revert package logic
update u set u.DataTrueProductID = u2.DataTrueProductID
--select *
from datatrue_edi.dbo.Temp_PDI_ItemPKG u
	inner join datatrue_edi.dbo.Temp_PDI_ItemPKG u2
	on ltrim(rtrim(u.PDIItemNumber)) = ltrim(rtrim(u2.PDIItemNumber))
		and u2.DataTrueProductID is not null
		and u.DataTrueProductID is null
		and CAST(u.datetimereceived as date) = CAST(u2.datetimereceived as date)
		and u.DataTrueChainID = @chainid and u.DataTrueSupplierID = @supplierid 
		and u2.DataTrueChainID = @chainid and u2.DataTrueSupplierID = @supplierid
	inner join  datatrue_edi.dbo.PackageCodeCompare pcg_com 
		on  ltrim(rtrim(u2.PackageCode_Scrubbed)) = pcg_com.MasterPackageCode
			and ltrim(rtrim(u.PackageCode_Scrubbed)) = pcg_com.DetailPackageCode
	inner join #temp_pkg_missing_upc	 pkg
		on u2.RecordID = pkg.RecordID


drop  table #temp_pkg_missing_upc


return
GO
