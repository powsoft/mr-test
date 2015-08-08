USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prPDI_PriceBook_Master_Automated_AddMissingItemPKG_Pending Deployment_20141224]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prPDI_PriceBook_Master_Automated_AddMissingItemPKG_Pending Deployment_20141224]
@chainid int=null,
@supplierid int=null

as
--Declare @chainid int = 75130 declare @supplierid int = 76949
declare @filedate date
declare @filedatecost date
declare @FutureEndDate date = '12/31/2099'

select @filedate = MAX(cast(Datetimereceived as date)) from datatrue_edi.dbo.Temp_PDI_ItemPKG_CTM_TEST where DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
select @filedatecost = MAX(cast(Datetimereceived as date)) from datatrue_edi.dbo.Temp_PDI_Costs where DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid

 
select distinct datatrueproductid, UPC12, rtrim(ltrim(pdiitemnumber)) as PDINo, PackageCode_Scrubbed, LongDescription--, *
--select * 
into #temp_UPCs_wo_Pkg
from datatrue_edi.dbo.temp_PDI_UPC
where 1 = 1
	and cast(datetimecreated as date) = @filedate
	and datatruechainid = @chainid
	and datatruesupplierid = @supplierid
	and datatrueproductid not in 
	(
	 select ISNull(datatrueproductid,-10) 
	 from datatrue_edi.dbo.Temp_PDI_ItemPKG_CTM_TEST
	where 1 = 1
	and datatruechainid = @chainid
	and datatruesupplierid = @supplierid
	and cast(datetimereceived as date) = @filedate
	and Purchasable = 'Y'
	)

--  and pdiitemnumber in ('2743' , '8720')


declare @Inserted_Miss_Pkg table (ProductID int)

--create data with full matching
insert into [DataTrue_EDI].[dbo].[Temp_PDI_ItemPKG_CTM_TEST]
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
       output inserted.DataTrueProductID into  @Inserted_Miss_Pkg    
 select distinct --purchasable, sellable, datatrueproductid, * 
		p.[ChainIdentifier]
       ,p.[PDIItemNumber]
       ,p.[ItemDescription]
       ,p.[ItemType]
       ,p.[SizeDescription]
       ,p.[BrandID]
       ,p.[ManufacturerID]
       ,p.[PrimaryLevel1GroupID]
       ,p.[PrimaryLevel2GroupID]
       ,p.[PrimaryLevel3GroupID]
       ,p.[PrimaryLevel4GroupID]
       ,p.[AlternateLevel1GroupID]
       ,p.[AlternateLevel2GroupID]
       ,p.[AlternateLevel3GroupID]
       ,p.[PackageCode]
       ,p.[PackageQuantity]
       ,p.[Purchasable]
       ,p.[PurchaseDiscontinueDate]
       ,p.[Sellable]
       ,p.[SaleDiscontinueDate]
       ,p.[Auditable]
       ,p.[PrintLabels]
       ,p.[UseinRecipe]
       ,p.[WeightVolume]
       ,p.[UnitofMeasure]
       ,p.[ItemTaxGroupID]
       ,p.[SellingUOM]
       ,p.[SellingUOMShortLabelDesc]
       ,p.[Vendorname]
       ,p.[Vendoridentifier]
       ,''--[filename]
       ,p.[Datetimereceived] --getdate() --[Datetimereceived]
       ,0 --[Recordstatus]
       ,p.[DataTrueChainID]
       ,t.DataTrueProductID --[DataTrueProductID]
       ,p.[DataTrueSupplierID]
       ,p.[DataTrueManufacturerID]
       ,p.[DataTrueBrandID]
       ,p.[DataTrueProductCategoryID]
       ,p.[PackageCode_Scrubbed]	 
 from datatrue_edi.dbo.Temp_PDI_ItemPKG_CTM_TEST p
	  inner join #temp_UPCs_wo_Pkg t
		on t.PDINo = ltrim(rtrim(p.pdiitemnumber))
		and t.PackageCode_Scrubbed	= p.PackageCode_Scrubbed
	  inner join [DataTrue_EDI].dbo.Temp_PDI_Costs c
		  on ltrim(rtrim(c.PDIItemNo)) = ltrim(rtrim(p.PDIItemNumber))
		  and c.PackageCode_Scrubbed= p.PackageCode_Scrubbed
		  and p.DataTrueChainID = @chainid
		  and p.DataTrueSupplierID = @supplierid
		  and p.DataTrueChainID = c.DataTrueChainID
		  and p.DataTrueSupplierID = c.DataTrueSupplierID
 where  p.DataTrueProductID is not null
	  and cast(p.datetimereceived as date) = @filedate
	  and cast(c.datetimereceived as date) = @filedatecost
	  and ISNull(c.DiscontinueDate, @FutureEndDate)  > cast(GETDATE() as date) 
	  --and c.PromotionEndDate is null
	  and p.Purchasable = 'Y' 
 	  --and p.pdiitemnumber = @pdino 
 	  --and p.PackageCode_Scrubbed = @packagecode

--add data for non full matching w/o PackageCode
insert into datatrue_edi.dbo.Temp_PDI_ItemPKG_CTM_TEST
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
			p.[ChainIdentifier]
		   ,p.[PDIItemNumber]
		   ,mx.LongDescription --[ItemDescription]
		   ,p.[ItemType]
		   ,p.[SizeDescription] --@packagecode --[SizeDescription]
		   ,p.[BrandID]
		   ,p.[ManufacturerID]
		   ,p.[PrimaryLevel1GroupID]
		   ,p.[PrimaryLevel2GroupID]
		   ,p.[PrimaryLevel3GroupID]
		   ,p.[PrimaryLevel4GroupID]
		   ,p.[AlternateLevel1GroupID]
		   ,p.[AlternateLevel2GroupID]
		   ,p.[AlternateLevel3GroupID]
		   ,p.[PackageCode] --@packagecode --[PackageCode]
		   ,p.[PackageQuantity] --case when @packagecode in ('EACH', 'SINGLE') then 1 else [PackageQuantity] end
		   ,p.[Purchasable] --'N' --[Purchasable]
		   ,p.[PurchaseDiscontinueDate]
		   ,p.[Sellable] --'Y' --[Sellable]
		   ,p.[SaleDiscontinueDate]
		   ,p.[Auditable]
		   ,p.[PrintLabels]
		   ,p.[UseinRecipe]
		   ,p.[WeightVolume]
		   ,p.[UnitofMeasure]
		   ,p.[ItemTaxGroupID]
		   ,p.[SellingUOM]
		   ,p.[SellingUOMShortLabelDesc]
		   ,p.[Vendorname]
		   ,p.[Vendoridentifier]
		   ,''--[filename]
		   ,p.[Datetimereceived] --getdate() --[Datetimereceived]
		   ,0 --[Recordstatus]
		   ,p.[DataTrueChainID]
		   ,mx.DataTrueProductID --[DataTrueProductID]
		   ,p.[DataTrueSupplierID]
		   ,p.[DataTrueManufacturerID]
		   ,p.[DataTrueBrandID]
		   ,p.[DataTrueProductCategoryID]	 
		   ,p.[PackageCode_Scrubbed]
	 from datatrue_edi.dbo.Temp_PDI_ItemPKG_CTM_TEST p
		inner join (
			 select  max(pkg.RecordID) RecordID, ltrim(rtrim(pkg.pdiitemnumber)) pdiitemnumber, max(t.LongDescription) LongDescription, t.DataTrueProductID
			 from datatrue_edi.dbo.Temp_PDI_ItemPKG_CTM_TEST pkg
				  inner join #temp_UPCs_wo_Pkg t
						on t.PDINo = ltrim(rtrim(pkg.pdiitemnumber))
						--and t.PackageCode_Scrubbed	= pkg.PackageCode_Scrubbed
				  left join @Inserted_Miss_Pkg ins
						on ins.ProductID = t.DataTrueProductID
				  inner join [DataTrue_EDI].dbo.Temp_PDI_Costs c
					  on ltrim(rtrim(c.PDIItemNo)) = ltrim(rtrim(pkg.PDIItemNumber))
					  and c.PackageCode_Scrubbed= pkg.PackageCode_Scrubbed
					  and pkg.DataTrueChainID = @chainid
					  and pkg.DataTrueSupplierID = @supplierid
					  and pkg.DataTrueChainID = c.DataTrueChainID
					  and pkg.DataTrueSupplierID = c.DataTrueSupplierID
			 where  pkg.DataTrueProductID is not null
				  and cast(pkg.datetimereceived as date) = @filedate
				  and cast(c.datetimereceived as date) = @filedatecost
				  and ISNull(c.DiscontinueDate, @FutureEndDate)  > cast(GETDATE() as date) 
				  --and c.PromotionEndDate is null
				  and pkg.Purchasable = 'Y' 
				  and ins.ProductID is Null
			group  by ltrim(rtrim(pkg.pdiitemnumber)) ,   t.DataTrueProductID
			) mx on  p.RecordID = mx.RecordID

drop table #temp_UPCs_wo_Pkg


--while @@fetch_status = 0
--	begin

--print 'Start Step'	 

--INSERT INTO [DataTrue_EDI].[dbo].[Temp_PDI_ItemPKG_CTM_TEST]
--           ([ChainIdentifier]
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
--           ,[filename]
--           ,[Datetimereceived]
--           ,[Recordstatus]
--           ,[DataTrueChainID]
--           ,[DataTrueProductID]
--           ,[DataTrueSupplierID]
--           ,[DataTrueManufacturerID]
--           ,[DataTrueBrandID]
--           ,[DataTrueProductCategoryID]
--           ,[PackageCode_Scrubbed])	  	
--	 select distinct --purchasable, sellable, datatrueproductid, * 
--			p.[ChainIdentifier]
--           ,p.[PDIItemNumber]
--           ,p.[ItemDescription]
--           ,p.[ItemType]
--           ,p.[SizeDescription]
--           ,p.[BrandID]
--           ,p.[ManufacturerID]
--           ,p.[PrimaryLevel1GroupID]
--           ,p.[PrimaryLevel2GroupID]
--           ,p.[PrimaryLevel3GroupID]
--           ,p.[PrimaryLevel4GroupID]
--           ,p.[AlternateLevel1GroupID]
--           ,p.[AlternateLevel2GroupID]
--           ,p.[AlternateLevel3GroupID]
--           ,p.[PackageCode]
--           ,p.[PackageQuantity]
--           ,p.[Purchasable]
--           ,p.[PurchaseDiscontinueDate]
--           ,p.[Sellable]
--           ,p.[SaleDiscontinueDate]
--           ,p.[Auditable]
--           ,p.[PrintLabels]
--           ,p.[UseinRecipe]
--           ,p.[WeightVolume]
--           ,p.[UnitofMeasure]
--           ,p.[ItemTaxGroupID]
--           ,p.[SellingUOM]
--           ,p.[SellingUOMShortLabelDesc]
--           ,p.[Vendorname]
--           ,p.[Vendoridentifier]
--           ,''--[filename]
--           ,p.[Datetimereceived] --getdate() --[Datetimereceived]
--           ,0 --[Recordstatus]
--           ,p.[DataTrueChainID]
--           ,@productid --[DataTrueProductID]
--           ,p.[DataTrueSupplierID]
--           ,p.[DataTrueManufacturerID]
--           ,p.[DataTrueBrandID]
--           ,p.[DataTrueProductCategoryID]
--           ,p.[PackageCode_Scrubbed]	 
--	 from datatrue_edi.dbo.Temp_PDI_ItemPKG_CTM_TEST p
--		  inner join [DataTrue_EDI].dbo.Temp_PDI_Costs c
--			  on ltrim(rtrim(c.PDIItemNo)) = ltrim(rtrim(p.PDIItemNumber))
--			  and c.PackageCode_Scrubbed= p.PackageCode_Scrubbed
--			  and p.DataTrueChainID = @chainid
--			  and p.DataTrueSupplierID = @supplierid
--			  and p.DataTrueChainID = c.DataTrueChainID
--			  and p.DataTrueSupplierID = c.DataTrueSupplierID
--	 where  p.DataTrueProductID is not null
--		  and cast(p.datetimereceived as date) = @filedate
--		  and cast(c.datetimereceived as date) = @filedatecost
--		  and ISNull(c.DiscontinueDate, @FutureEndDate)  > cast(GETDATE() as date) 
--		  --and c.PromotionEndDate is null
--		  and p.Purchasable = 'Y' 
--	 	  and p.pdiitemnumber = @pdino 
--	 	  and p.PackageCode_Scrubbed = @packagecode

--	if @@rowcount < 1
--		begin
--			--- if there was inserted record on prev interation 
--			if 
			
--			 not exists
--				(select p.*
--				from datatrue_edi.dbo.Temp_PDI_ItemPKG_CTM_TEST p
--					  inner join [DataTrue_EDI].dbo.Temp_PDI_Costs c
--						  on ltrim(rtrim(c.PDIItemNo)) = ltrim(rtrim(p.PDIItemNumber))
--						  and c.PackageCode_Scrubbed= p.PackageCode_Scrubbed
--						  and p.DataTrueChainID = @chainid
--						  and p.DataTrueSupplierID = @supplierid
--						  and p.DataTrueChainID = c.DataTrueChainID
--						  and p.DataTrueSupplierID = c.DataTrueSupplierID
--				 where  p.DataTrueProductID is not null
--					  and cast(p.datetimereceived as date) = @filedate
--					  and cast(c.datetimereceived as date) = @filedatecost
--					  and ISNull(c.DiscontinueDate, @FutureEndDate)  > cast(GETDATE() as date) 
--					  --and c.PromotionEndDate is null
--					  and p.Purchasable = 'Y' 
--	 				  and p.pdiitemnumber = @pdino 
--	 				  --and p.PackageCode_Scrubbed = @packagecode
--	 				  and p.DataTrueProductID = @productid 
--		 )
--			begin
--			INSERT INTO datatrue_edi.dbo.Temp_PDI_ItemPKG_CTM_TEST
--					   ([ChainIdentifier]
--					   ,[PDIItemNumber]
--					   ,[ItemDescription]
--					   ,[ItemType]
--					   ,[SizeDescription]
--					   ,[BrandID]
--					   ,[ManufacturerID]
--					   ,[PrimaryLevel1GroupID]
--					   ,[PrimaryLevel2GroupID]
--					   ,[PrimaryLevel3GroupID]
--					   ,[PrimaryLevel4GroupID]
--					   ,[AlternateLevel1GroupID]
--					   ,[AlternateLevel2GroupID]
--					   ,[AlternateLevel3GroupID]
--					   ,[PackageCode]
--					   ,[PackageQuantity]
--					   ,[Purchasable]
--					   ,[PurchaseDiscontinueDate]
--					   ,[Sellable]
--					   ,[SaleDiscontinueDate]
--					   ,[Auditable]
--					   ,[PrintLabels]
--					   ,[UseinRecipe]
--					   ,[WeightVolume]
--					   ,[UnitofMeasure]
--					   ,[ItemTaxGroupID]
--					   ,[SellingUOM]
--					   ,[SellingUOMShortLabelDesc]
--					   ,[Vendorname]
--					   ,[Vendoridentifier]
--					   ,[filename]
--					   ,[Datetimereceived]
--					   ,[Recordstatus]
--					   ,[DataTrueChainID]
--					   ,[DataTrueProductID]
--					   ,[DataTrueSupplierID]
--					   ,[DataTrueManufacturerID]
--					   ,[DataTrueBrandID]
--					   ,[DataTrueProductCategoryID]
--					   ,[PackageCode_Scrubbed])	  	
--				 select distinct --purchasable, sellable, datatrueproductid, * 
--						Top 1 p.[ChainIdentifier]
--					   ,p.[PDIItemNumber]
--					   ,@longdesc --[ItemDescription]
--					   ,p.[ItemType]
--					   ,p.[SizeDescription] --@packagecode --[SizeDescription]
--					   ,p.[BrandID]
--					   ,p.[ManufacturerID]
--					   ,p.[PrimaryLevel1GroupID]
--					   ,p.[PrimaryLevel2GroupID]
--					   ,p.[PrimaryLevel3GroupID]
--					   ,p.[PrimaryLevel4GroupID]
--					   ,p.[AlternateLevel1GroupID]
--					   ,p.[AlternateLevel2GroupID]
--					   ,p.[AlternateLevel3GroupID]
--					   ,p.[PackageCode] --@packagecode --[PackageCode]
--					   ,p.[PackageQuantity] --case when @packagecode in ('EACH', 'SINGLE') then 1 else [PackageQuantity] end
--					   ,p.[Purchasable] --'N' --[Purchasable]
--					   ,p.[PurchaseDiscontinueDate]
--					   ,p.[Sellable] --'Y' --[Sellable]
--					   ,p.[SaleDiscontinueDate]
--					   ,p.[Auditable]
--					   ,p.[PrintLabels]
--					   ,p.[UseinRecipe]
--					   ,p.[WeightVolume]
--					   ,p.[UnitofMeasure]
--					   ,p.[ItemTaxGroupID]
--					   ,p.[SellingUOM]
--					   ,p.[SellingUOMShortLabelDesc]
--					   ,p.[Vendorname]
--					   ,p.[Vendoridentifier]
--					   ,''--[filename]
--					   ,p.[Datetimereceived] --getdate() --[Datetimereceived]
--					   ,0 --[Recordstatus]
--					   ,p.[DataTrueChainID]
--					   ,@productid --[DataTrueProductID]
--					   ,p.[DataTrueSupplierID]
--					   ,p.[DataTrueManufacturerID]
--					   ,p.[DataTrueBrandID]
--					   ,p.[DataTrueProductCategoryID]	 
--					   ,p.[PackageCode_Scrubbed]
--				 from datatrue_edi.dbo.Temp_PDI_ItemPKG_CTM_TEST p
--					  inner join [DataTrue_EDI].dbo.Temp_PDI_Costs c
--						  on ltrim(rtrim(c.PDIItemNo)) = ltrim(rtrim(p.PDIItemNumber))
--						  and c.PackageCode_Scrubbed= p.PackageCode_Scrubbed
--						  and p.DataTrueChainID = @chainid
--						  and p.DataTrueSupplierID = @supplierid
--						  and p.DataTrueChainID = c.DataTrueChainID
--						  and p.DataTrueSupplierID = c.DataTrueSupplierID
--				 where  p.DataTrueProductID is not null
--					  and cast(p.datetimereceived as date) = @filedate
--					  and cast(c.datetimereceived as date) = @filedatecost
--					  and ISNull(c.DiscontinueDate, @FutureEndDate)  > cast(GETDATE() as date) 
--					  --and c.PromotionEndDate is null
--					  and p.Purchasable = 'Y' 
--	 				  and p.pdiitemnumber = @pdino 
--	 				  --and p.PackageCode_Scrubbed = @packagecode
--				end	
--		end
	
	 	 
--		fetch next from @rec into @productid, @upc12, @pdino, @packagecode, @longdesc
	
--	end
	
--close @rec
--deallocate @rec
GO
