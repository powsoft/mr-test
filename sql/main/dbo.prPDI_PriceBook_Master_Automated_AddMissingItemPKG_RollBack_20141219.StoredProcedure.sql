USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prPDI_PriceBook_Master_Automated_AddMissingItemPKG_RollBack_20141219]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prPDI_PriceBook_Master_Automated_AddMissingItemPKG_RollBack_20141219]
@chainid int=null,
@supplierid int=null

as
--Declare @chainid int = 75130 declare @supplierid int = 76949
declare @rec cursor
declare @productid int
declare @upc12 varchar(50)
declare @pdino varchar(50)
declare @packagecode varchar(50)
declare @longdesc varchar(50)
declare @filedate date

select @filedate = MAX(cast(Datetimereceived as date)) from datatrue_edi.dbo.temp_PDI_ItemPKG where DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid

 -- select distinct datatruesupplierid, datatrueproductid, UPC12, pdiitemnumber as PDINo, PackageCode, longdescription--, * 
 -- from datatrue_edi.dbo.temp_PDI_UPC
 --where 1 = 1
 --and cast(datetimecreated as date) = @filedate
 -- and datatruechainid = @chainid
 -- and datatruesupplierid = @supplierid
 -- and datatrueproductid not in 
 -- (
 --    select datatrueproductid from datatrue_edi.dbo.temp_PDI_ItemPKG
 --where 1 = 1
 -- and datatruechainid = @chainid
 --   and datatruesupplierid = @supplierid
 --   and cast(datetimereceived as date) = @filedate
 --   and Purchasable = 'Y'
 -- )
  --order by pdiitemnumber

set @rec = cursor local fast_forward for
  select distinct datatrueproductid, UPC12, pdiitemnumber as PDINo, PackageCode_Scrubbed, LongDescription--, *
  --select * 
  from datatrue_edi.dbo.temp_PDI_UPC
 where 1 = 1
 and cast(datetimecreated as date) = @filedate
  and datatruechainid = @chainid
    and datatruesupplierid = @supplierid
  and datatrueproductid not in 
  (
     select ISNull(datatrueproductid,-10) 
     from datatrue_edi.dbo.temp_PDI_ItemPKG
 where 1 = 1
  and datatruechainid = @chainid
    and datatruesupplierid = @supplierid
    and cast(datetimereceived as date) = @filedate
    and Purchasable = 'Y'
  )
  order by pdiitemnumber
  
open @rec

fetch next from @rec into @productid, @upc12, @pdino, @packagecode,@longdesc

while @@fetch_status = 0
	begin

--  select distinct datatrueproductid, UPC12, pdiitemnumber as PDINo, PackageCode, longDescription
--  from datatrue_edi.dbo.temp_PDI_UPC
-- where 1 = 1
--	 and pdiitemnumber = @pdino
--	 and datatruechainid = @chainid
--	 and datatruesupplierid = @supplierid
--	 and cast(datetimecreated as date) = @filedate	


--	 select distinct --purchasable, sellable, datatrueproductid, * 
--	            purchasable, sellable, [Recordstatus],[PackageCode]
--           ,[DataTrueChainID]
--           ,[DataTrueProductID]
--           ,[DataTrueSupplierID]
--			,[ChainIdentifier]
--           ,[PDIItemNumber]
--           ,[ItemDescription]
--           ,[ItemType]
--           ,[SizeDescription]
--           ,[BrandID]
--           ,[ManufacturerID]
--           ,[PrimaryLevel1GroupID]
--           ,[PrimaryLevel2GroupID]
--           ,[PrimaryLevel3GroupID]
--           ,[PrimaryLevel4GroupID]
--           ,[AlternateLevel1GroupID]
--           ,[AlternateLevel2GroupID]
--           ,[AlternateLevel3GroupID]
           
--           ,[PackageQuantity]
--           --,[Purchasable]
--           ,[PurchaseDiscontinueDate]
--           --,[Sellable]
--           ,[SaleDiscontinueDate]
--           ,[Auditable]
--           ,[PrintLabels]
--           ,[UseinRecipe]
--           ,[WeightVolume]
--           ,[UnitofMeasure]
--           ,[ItemTaxGroupID]
--           ,[SellingUOM]
--           ,[SellingUOMShortLabelDesc]
--           ,[Vendorname]
--           ,[Vendoridentifier]
--           ,[filename]
--           ,[Datetimereceived]
--           ,[DataTrueManufacturerID]
--           ,[DataTrueBrandID]
--           ,[DataTrueProductCategoryID]	 
--	 from datatrue_edi.dbo.temp_PDI_ItemPKG
--	 where 1 = 1
--	 and pdiitemnumber = @pdino --and packagecode = @packagecode
--	 and datatruechainid = @chainid	--and purchasable = 'N' and sellable = 'Y'
--	 and datatruesupplierid = @supplierid
--	 and cast(datetimereceived as date) = @filedate
	 
--	 select distinct --purchasable, sellable, datatrueproductid, * 
--	            [Recordstatus]
--           ,[DataTrueChainID]
--           ,[DataTrueProductID]
--           ,[DataTrueSupplierID]
--			,[ChainIdentifier]
--           ,[PDIItemNumber]
--           ,[ItemDescription]
--           ,[ItemType]
--           ,[SizeDescription]
--           ,[BrandID]
--           ,[ManufacturerID]
--           ,[PrimaryLevel1GroupID]
--           ,[PrimaryLevel2GroupID]
--           ,[PrimaryLevel3GroupID]
--           ,[PrimaryLevel4GroupID]
--           ,[AlternateLevel1GroupID]
--           ,[AlternateLevel2GroupID]
--           ,[AlternateLevel3GroupID]
--           ,[PackageCode]
--           ,[PackageQuantity]
--           ,[Purchasable]
--           ,[PurchaseDiscontinueDate]
--           ,[Sellable]
--           ,[SaleDiscontinueDate]
--           ,[Auditable]
--           ,[PrintLabels]
--           ,[UseinRecipe]
--           ,[WeightVolume]
--           ,[UnitofMeasure]
--           ,[ItemTaxGroupID]
--           ,[SellingUOM]
--           ,[SellingUOMShortLabelDesc]
--           ,[Vendorname]
--           ,[Vendoridentifier]
--           ,''--[filename]
--           ,getdate() --[Datetimereceived]
--           ,[DataTrueManufacturerID]
--           ,[DataTrueBrandID]
--           ,[DataTrueProductCategoryID]	 
--	 from datatrue_edi.dbo.temp_PDI_ItemPKG
--	 where 1 = 1
--	 and pdiitemnumber = @pdino and packagecode = @packagecode
--	 and datatruechainid = @chainid	and purchasable = 'Y' --N' and sellable = 'Y'
--	 and datatruesupplierid = @supplierid
--	 and cast(datetimereceived as date) = @filedate

--if @@rowcount > 1 or @packagecode like '%PPK%'
--	begin
--		print 'herenow'
--	end
		 
INSERT INTO [DataTrue_EDI].[dbo].[temp_PDI_ItemPKG]
           ([ChainIdentifier]
           ,[PDIItemNumber]
           ,[ItemDescription]
           ,[ItemType]
           ,[SizeDescription]
           ,[BrandID]
           ,[ManufacturerID]
           ,[PrimaryLevel1GroupID]
           ,[PrimaryLevel2GroupID]
           ,[PrimaryLevel3GroupID]
           ,[PrimaryLevel4GroupID]
           ,[AlternateLevel1GroupID]
           ,[AlternateLevel2GroupID]
           ,[AlternateLevel3GroupID]
           ,[PackageCode]
           ,[PackageQuantity]
           ,[Purchasable]
           ,[PurchaseDiscontinueDate]
           ,[Sellable]
           ,[SaleDiscontinueDate]
           ,[Auditable]
           ,[PrintLabels]
           ,[UseinRecipe]
           ,[WeightVolume]
           ,[UnitofMeasure]
           ,[ItemTaxGroupID]
           ,[SellingUOM]
           ,[SellingUOMShortLabelDesc]
           ,[Vendorname]
           ,[Vendoridentifier]
           ,[filename]
           ,[Datetimereceived]
           ,[Recordstatus]
           ,[DataTrueChainID]
           ,[DataTrueProductID]
           ,[DataTrueSupplierID]
           ,[DataTrueManufacturerID]
           ,[DataTrueBrandID]
           ,[DataTrueProductCategoryID]
           ,[PackageCode_Scrubbed])	  	
	 select distinct --purchasable, sellable, datatrueproductid, * 
[ChainIdentifier]
           ,[PDIItemNumber]
           ,[ItemDescription]
           ,[ItemType]
           ,[SizeDescription]
           ,[BrandID]
           ,[ManufacturerID]
           ,[PrimaryLevel1GroupID]
           ,[PrimaryLevel2GroupID]
           ,[PrimaryLevel3GroupID]
           ,[PrimaryLevel4GroupID]
           ,[AlternateLevel1GroupID]
           ,[AlternateLevel2GroupID]
           ,[AlternateLevel3GroupID]
           ,[PackageCode]
           ,[PackageQuantity]
           ,[Purchasable]
           ,[PurchaseDiscontinueDate]
           ,[Sellable]
           ,[SaleDiscontinueDate]
           ,[Auditable]
           ,[PrintLabels]
           ,[UseinRecipe]
           ,[WeightVolume]
           ,[UnitofMeasure]
           ,[ItemTaxGroupID]
           ,[SellingUOM]
           ,[SellingUOMShortLabelDesc]
           ,[Vendorname]
           ,[Vendoridentifier]
           ,''--[filename]
           ,[Datetimereceived] --getdate() --[Datetimereceived]
           ,0 --[Recordstatus]
           ,[DataTrueChainID]
           ,@productid --[DataTrueProductID]
           ,[DataTrueSupplierID]
           ,[DataTrueManufacturerID]
           ,[DataTrueBrandID]
           ,[DataTrueProductCategoryID]
           ,[PackageCode_Scrubbed]	 
	 from datatrue_edi.dbo.temp_PDI_ItemPKG
	 where 1 = 1
	 and pdiitemnumber = @pdino and PackageCode_Scrubbed = @packagecode
	 and datatruechainid = @chainid	and purchasable = 'Y' --N' and sellable = 'Y'
	 and datatruesupplierid = @supplierid
	and cast(datetimereceived as date) = @filedate

	if @@rowcount < 1
		begin
		
		 
			INSERT INTO [DataTrue_EDI].[dbo].[temp_PDI_ItemPKG]
					   ([ChainIdentifier]
					   ,[PDIItemNumber]
					   ,[ItemDescription]
					   ,[ItemType]
					   ,[SizeDescription]
					   ,[BrandID]
					   ,[ManufacturerID]
					   ,[PrimaryLevel1GroupID]
					   ,[PrimaryLevel2GroupID]
					   ,[PrimaryLevel3GroupID]
					   ,[PrimaryLevel4GroupID]
					   ,[AlternateLevel1GroupID]
					   ,[AlternateLevel2GroupID]
					   ,[AlternateLevel3GroupID]
					   ,[PackageCode]
					   ,[PackageQuantity]
					   ,[Purchasable]
					   ,[PurchaseDiscontinueDate]
					   ,[Sellable]
					   ,[SaleDiscontinueDate]
					   ,[Auditable]
					   ,[PrintLabels]
					   ,[UseinRecipe]
					   ,[WeightVolume]
					   ,[UnitofMeasure]
					   ,[ItemTaxGroupID]
					   ,[SellingUOM]
					   ,[SellingUOMShortLabelDesc]
					   ,[Vendorname]
					   ,[Vendoridentifier]
					   ,[filename]
					   ,[Datetimereceived]
					   ,[Recordstatus]
					   ,[DataTrueChainID]
					   ,[DataTrueProductID]
					   ,[DataTrueSupplierID]
					   ,[DataTrueManufacturerID]
					   ,[DataTrueBrandID]
					   ,[DataTrueProductCategoryID]
					   ,[PackageCode_Scrubbed])	  	
				 select distinct --purchasable, sellable, datatrueproductid, * 
						Top 1 [ChainIdentifier]
					   ,[PDIItemNumber]
					   ,@longdesc --[ItemDescription]
					   ,[ItemType]
					   ,[SizeDescription] --@packagecode --[SizeDescription]
					   ,[BrandID]
					   ,[ManufacturerID]
					   ,[PrimaryLevel1GroupID]
					   ,[PrimaryLevel2GroupID]
					   ,[PrimaryLevel3GroupID]
					   ,[PrimaryLevel4GroupID]
					   ,[AlternateLevel1GroupID]
					   ,[AlternateLevel2GroupID]
					   ,[AlternateLevel3GroupID]
					   ,[PackageCode] --@packagecode --[PackageCode]
					   ,[PackageQuantity] --case when @packagecode in ('EACH', 'SINGLE') then 1 else [PackageQuantity] end
					   ,[Purchasable] --'N' --[Purchasable]
					   ,[PurchaseDiscontinueDate]
					   ,[Sellable] --'Y' --[Sellable]
					   ,[SaleDiscontinueDate]
					   ,[Auditable]
					   ,[PrintLabels]
					   ,[UseinRecipe]
					   ,[WeightVolume]
					   ,[UnitofMeasure]
					   ,[ItemTaxGroupID]
					   ,[SellingUOM]
					   ,[SellingUOMShortLabelDesc]
					   ,[Vendorname]
					   ,[Vendoridentifier]
					   ,''--[filename]
					   ,[Datetimereceived] --getdate() --[Datetimereceived]
					   ,0 --[Recordstatus]
					   ,[DataTrueChainID]
					   ,@productid --[DataTrueProductID]
					   ,[DataTrueSupplierID]
					   ,[DataTrueManufacturerID]
					   ,[DataTrueBrandID]
					   ,[DataTrueProductCategoryID]	 
					   ,[PackageCode_Scrubbed]
				 from datatrue_edi.dbo.temp_PDI_ItemPKG
				 where 1 = 1
				 and pdiitemnumber = @pdino --and packagecode = @packagecode
				 and datatruechainid = @chainid	and purchasable = 'Y' --and sellable = 'Y'
				 and datatruesupplierid = @supplierid
				 and cast(datetimereceived as date) = @filedate	
					
					
		end
	
	 --select distinct --purchasable, sellable, datatrueproductid, * 
	 --           [Recordstatus]
  --         ,[DataTrueChainID]
  --         ,[DataTrueProductID]
  --         ,[DataTrueSupplierID]
		--	,[ChainIdentifier]
  --         ,[PDIItemNumber]
  --         ,[ItemDescription]
  --         ,[ItemType]
  --         ,[SizeDescription]
  --         ,[BrandID]
  --         ,[ManufacturerID]
  --         ,[PrimaryLevel1GroupID]
  --         ,[PrimaryLevel2GroupID]
  --         ,[PrimaryLevel3GroupID]
  --         ,[PrimaryLevel4GroupID]
  --         ,[AlternateLevel1GroupID]
  --         ,[AlternateLevel2GroupID]
  --         ,[AlternateLevel3GroupID]
  --         ,[PackageCode]
  --         ,[PackageQuantity]
  --         ,[Purchasable]
  --         ,[PurchaseDiscontinueDate]
  --         ,[Sellable]
  --         ,[SaleDiscontinueDate]
  --         ,[Auditable]
  --         ,[PrintLabels]
  --         ,[UseinRecipe]
  --         ,[WeightVolume]
  --         ,[UnitofMeasure]
  --         ,[ItemTaxGroupID]
  --         ,[SellingUOM]
  --         ,[SellingUOMShortLabelDesc]
  --         ,[Vendorname]
  --         ,[Vendoridentifier]
  --         ,''--[filename]
  --         ,[Datetimereceived] --getdate() --[Datetimereceived]
  --         ,[DataTrueManufacturerID]
  --         ,[DataTrueBrandID]
  --         ,[DataTrueProductCategoryID]	 
	 --from datatrue_edi.dbo.temp_PDI_ItemPKG
	 --where 1 = 1
	 --and pdiitemnumber = @pdino --and packagecode = @packagecode
	 --and datatruechainid = @chainid	and purchasable = 'Y' --N' and sellable = 'Y'
	 --and datatruesupplierid = @supplierid
	 --and cast(datetimereceived as date) = @filedate
	 	 
		fetch next from @rec into @productid, @upc12, @pdino, @packagecode, @longdesc
	
	end
	
close @rec
deallocate @rec
GO
