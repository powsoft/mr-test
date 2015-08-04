USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prPDI_PriceBook_Master_Automated_AddMissingItemPKG_RollBack_20141225]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prPDI_PriceBook_Master_Automated_AddMissingItemPKG_RollBack_20141225]
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
declare @filedatecost date
declare @FutureEndDate date = '12/31/2099'

select @filedate = MAX(cast(Datetimereceived as date)) from datatrue_edi.dbo.Temp_PDI_ItemPKG where DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
select @filedatecost = MAX(cast(Datetimereceived as date)) from datatrue_edi.dbo.Temp_PDI_Costs where DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid

 

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
     from datatrue_edi.dbo.Temp_PDI_ItemPKG
 where 1 = 1
  and datatruechainid = @chainid
    and datatruesupplierid = @supplierid
    and cast(datetimereceived as date) = @filedate
    and Purchasable = 'Y'
  )
  
--  and pdiitemnumber in ('2743' , '8720')
  order by pdiitemnumber
  
open @rec

fetch next from @rec into @productid, @upc12, @pdino, @packagecode,@longdesc

while @@fetch_status = 0
	begin

print 'Start Step'	 

INSERT INTO [DataTrue_EDI].[dbo].[Temp_PDI_ItemPKG]
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
           ,@productid --[DataTrueProductID]
           ,p.[DataTrueSupplierID]
           ,p.[DataTrueManufacturerID]
           ,p.[DataTrueBrandID]
           ,p.[DataTrueProductCategoryID]
           ,p.[PackageCode_Scrubbed]	 
	 from datatrue_edi.dbo.Temp_PDI_ItemPKG p
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
	 	  and p.pdiitemnumber = @pdino 
	 	  and p.PackageCode_Scrubbed = @packagecode

	if @@rowcount < 1
		begin
			--- if there was inserted record on prev interation 
			if 
			
			 not exists
				(select p.*
				from datatrue_edi.dbo.Temp_PDI_ItemPKG p
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
	 				  and p.pdiitemnumber = @pdino 
	 				  --and p.PackageCode_Scrubbed = @packagecode
	 				  and p.DataTrueProductID = @productid 
		 )
			begin
			INSERT INTO datatrue_edi.dbo.Temp_PDI_ItemPKG
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
						Top 1 p.[ChainIdentifier]
					   ,p.[PDIItemNumber]
					   ,@longdesc --[ItemDescription]
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
					   ,@productid --[DataTrueProductID]
					   ,p.[DataTrueSupplierID]
					   ,p.[DataTrueManufacturerID]
					   ,p.[DataTrueBrandID]
					   ,p.[DataTrueProductCategoryID]	 
					   ,p.[PackageCode_Scrubbed]
				 from datatrue_edi.dbo.Temp_PDI_ItemPKG p
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
	 				  and p.pdiitemnumber = @pdino 
	 				  --and p.PackageCode_Scrubbed = @packagecode
				end	
		end
	
	 	 
		fetch next from @rec into @productid, @upc12, @pdino, @packagecode, @longdesc
	
	end
	
close @rec
deallocate @rec
GO
