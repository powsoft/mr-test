USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_Attributes_Populate_All_PDI]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_Attributes_Populate_All_PDI]
as

declare @rec cursor
declare @mrid int
declare @productid int
declare @upc nvarchar(50)
declare @vin nvarchar(50)
declare @BrandIdentifier nvarchar(50)
declare @itemdescription nvarchar(255)
declare @dtproductdescription nvarchar(255)
declare @PrimaryGroupLevel nvarchar(255)
declare @AlternateGroupLevel nvarchar(255)
declare @ItemGroup nvarchar(255)
declare @AlternateItemGroup nvarchar(255)
declare @Size nvarchar(255)
declare @ManufacturerIdentifier nvarchar(255)
declare @PrimarySellablePkgIdentifier nvarchar(255)
declare @PrimarySellablePkgQty nvarchar(255)
declare @VINDescription nvarchar(255)
declare @PurchPackDescription nvarchar(255)
declare @PurchPackQty int
declare @ProductCategoryId nvarchar(255)
declare @ProductSubCategory nvarchar(255)
declare @chainid int
declare @manufacturerid int
declare @brandid int
declare @invalidVIN bit
declare @insupplierpackagetable bit
declare @pdiitemno nvarchar(50)
declare @chainidentifier varchar(50)
declare @mrcost money


set @rec = CURSOR local fast_forward FOR


select MaintenanceRequestId, ProductId, ltrim(rtrim(UPC)), ltrim(rtrim(vin)), ltrim(rtrim(BrandIdentifier)), 
ltrim(rtrim(ItemDescription)), ltrim(rtrim(dtproductdescription)), 
ltrim(rtrim(PrimaryGroupLevel)), ltrim(rtrim(AlternateGroupLevel)), ltrim(rtrim(ItemGroup)),
ltrim(rtrim(AlternateItemGroup)), ltrim(rtrim(Size)), ltrim(rtrim(ManufacturerIdentifier)),
ltrim(rtrim(PrimarySellablePkgIdentifier)),ltrim(rtrim(PrimarySellablePkgQty)),ltrim(rtrim(VINDescription)),
ltrim(rtrim(PurchPackDescription)),ltrim(rtrim(PurchPackQty)),
ProductCategoryId, chainid, brandid, cost
--select *
--update r set r.Requeststatus = 18
from maintenancerequests r
where 1 = 1
--and requeststatus not in (5,15,16,17,18)
and CAST(r.datetimecreated as date) >= GETDATE()-30 --CAST(GETDATE() as date)
and PDIParticipant = 1
and requeststatus in (18)
--and maintenancerequestid between 225352 and 225376
--and maintenancerequestid = 225673
--and Maintenancerequestid in()
and skip_879_889_Conversion_ProcessCompleted is null
and RequestTypeID not in (1)
and ProductId is not null
and VIN is not null
--and LEFT(VIN, 6) = '000000'
--and MaintenanceRequestID = 224116

open @rec

fetch next from @rec into @mrid,@productid,@upc,@vin,@BrandIdentifier,@itemdescription,@dtproductdescription
,@PrimaryGroupLevel,@AlternateGroupLevel,@ItemGroup,@AlternateItemGroup,@Size,@ManufacturerIdentifier
,@PrimarySellablePkgIdentifier,@PrimarySellablePkgQty,@VINDescription,@PurchPackDescription,@PurchPackQty
,@ProductCategoryId, @chainid, @brandid, @mrcost

while @@FETCH_STATUS = 0
	begin
	
				set @chainidentifier = null
				select @chainidentifier = chainidentifier from chains where  ChainID = @chainid
				
				--select top 10 *
				--from MaintenanceRequests
				--where MaintenanceRequestID = @mrid

				--select top 10 *
				--from Products
				--where ProductID = @productid
				
				--select top 10 *
				--from ProductIdentifiers
				--where ProductID = @productid
				--and ProductIdentifierTypeID = 2				

				--select top 10 *
				--FROM [DataTrue_EDI].[dbo].[Temp_PDI_Costs]
				--  where LTRIM(rtrim(Rawproductidentifier)) = @vin
	
				set @pdiitemno = null
				
				SELECT @pdiitemno = PDIItemNo
				  FROM [DataTrue_EDI].[dbo].[Temp_PDI_Costs]
				  where LTRIM(rtrim(Rawproductidentifier)) = @vin
				  
				  if @pdiitemno is null
					begin
						select @pdiitemno = LTRIM(rtrim(Comments))
						from ProductIdentifiers
						where ProductID = @productid
						and ProductIdentifierTypeID = 2							
					end
					
				  if @pdiitemno is null
					begin
						select @pdiitemno = LTRIM(rtrim(OwnerPDIItemNo))
						from SupplierPackages
						where ProductID = @productid
						and OwnerEntityID = @chainid
						and VIN = @vin				
					end
									  
				 -- select top 10 *
				 -- from SupplierPackages
				 -- where ProductID = @productid
				  
					--select top 10 * from datatrue_edi.dbo.temp_PDI_ItemPKG where PDIItemNumber = @pdiitemno
					--select top 10 * from datatrue_edi.dbo.Temp_PDI_Retail where PDIItemNo = @pdiitemno
					--select top 10 * from datatrue_edi.dbo.Temp_PDI_UPC where PDIItemNumber = @pdiitemno
	
	
--select *
--from maintenancerequests 
--where 1 = 1
--and MaintenanceRequestID = 210043	
	
--select top 1000 * from maintenancerequests	
		if @productid is null
			begin
				select @productid = productid
				from ProductIdentifiers
				where IdentifierValue = @upc
				and ProductIdentifierTypeID = 2 
			end
	
		if len(@BrandIdentifier) < 1 or @BrandIdentifier is null
			begin
			
				select @brandidentifier = b.BrandName, @manufacturerid = b.ManufacturerID
				,@brandid = b.brandid
				from ProductBrandAssignments a
				inner join brands b
				on a.BrandID = b.BrandID
				and a.ProductID = @productid
				
				select @ManufacturerIdentifier = ManufacturerName
				from Manufacturers
				where ManufacturerID = @manufacturerid
			end

		if len(@itemdescription) < 1 or @itemdescription is null
			begin		
				select @itemdescription = Description 
				from Products
				where ProductID = @productid
				
				if len(@dtproductdescription) < 1 or @dtproductdescription is null
				begin 
					set @dtproductdescription = @itemdescription
				end
			end	
--,@PrimarySellablePkgIdentifier,@PrimarySellablePkgQty,
		select @Size = OwnerPackageSizeDescription ,@VINDescription = OwnerPackageDescription
		,@PurchPackDescription=OwnerPackageIdentifier ,@PurchPackQty=ThisPackageUOMBasisQty	
		from SupplierPackages 
		where ProductID = @productid
		and LTRIM(rtrim(VIN)) = @vin
		
		if @@ROWCOUNT < 1
			begin
			
				Print 'Help! Invalid VIN/ProductID'
				Print @vin
				Print @productid	
				
				set @invalidVIN = 1
				
				--SELECT top 10 *
				--  FROM [DataTrue_EDI].[dbo].[Temp_PDI_Costs]
				--where LTRIM(rtrim(rawproductidentifier)) = @vin		

				--SELECT top 10 *
				--  FROM [DataTrue_EDI].[dbo].[Temp_PDI_ItemPkg]
				--where PDIItemNumber = @pdiitemno
				
				select @Size = SizeDescription ,@VINDescription = ItemDescription	
				from [DataTrue_EDI].[dbo].[Temp_PDI_ItemPkg]
				where PDIItemNumber = @pdiitemno
				and ChainIdentifier = @chainidentifier

				select @PurchPackDescription = PackageCode ,@PurchPackQty=packageqty
				from [DataTrue_EDI].[dbo].[Temp_PDI_Costs]	
				where LTRIM(rtrim(rawproductidentifier)) = @vin	
				and ChainIdentifier = @chainidentifier
				order by abs(@mrcost - PackageCost) desc
				
				if @@ROWCOUNT > 0 
					set @invalidVIN = 0
					
				select top 1 *
				from ProductIdentifiers
				where ProductIdentifierTypeID = 3
				and LTRIM(rtrim(IdentifierValue)) = @vin	
					
				if @@ROWCOUNT > 0 
					set @invalidVIN = 0		
					
				if @invalidVIN = 1
					begin
					
						update R set requeststatus = 18--, ReplaceUPC = 1
						from MaintenanceRequests r
						where MaintenanceRequestID = @mrid					
					
					end		
						
			end
		else
			begin
				print 'OK'
				set @invalidVIN = 0
			end
			
		--if len(@PrimaryGroupLevel) < 1 or @PrimaryGroupLevel is null
		--	begin	--select * from ProductCategories	select * from ProductCategoryAssignments where CustomOwnerEntityid = 59973
				select @PrimaryGroupLevel = OwnerGroupLevelID, @ItemGroup = OwnerGroupID 
				,@ProductCategoryId = a.ProductCategoryID 
				from ProductCategoryAssignments a
				inner join ProductCategories c
				on a.ProductCategoryID = c.ProductCategoryID
				and a.ProductID = @productid
				and c.OwnerEntityID = @chainid
				and a.CustomOwnerEntityid = @chainid
			--end	
		
		--select * from supplierpackages
		
		
		update R set r.BrandIdentifier = case when len(isnull(BrandIdentifier,''))<1 then @BrandIdentifier else BrandIdentifier end
		,r.ManufacturerIdentifier = case when len(isnull(ManufacturerIdentifier,''))<1 then @ManufacturerIdentifier else ManufacturerIdentifier end
		,r.ItemDescription = case when len(isnull(itemdescription,''))<1 then @itemdescription else itemdescription end
		,r.dtproductdescription = case when len(isnull(dtproductdescription,''))<1 then @dtproductdescription else dtproductdescription end
		,r.PrimaryGroupLevel = case when len(isnull(PrimaryGroupLevel,''))<1 then @PrimaryGroupLevel else PrimaryGroupLevel end
		,r.ItemGroup = case when len(isnull(ItemGroup,''))<1 then @ItemGroup else ItemGroup end
		,r.Size = case when len(isnull(Size,''))<1 then @Size else Size end
		,r.VINDescription = case when len(isnull(VINDescription,''))<1 then @VINDescription else VINDescription end
		,r.PurchPackDescription = case when len(isnull(PurchPackDescription,''))<1 then @PurchPackDescription else PurchPackDescription end
		,r.PurchPackQty = case when isnull(PurchPackQty,0)<1 then @PurchPackQty else PurchPackQty end
		,r.ProductCategoryId = case when isnull(ProductCategoryId,0)<1 then @ProductCategoryId else ProductCategoryId end
		,r.brandid = case when isnull(brandid,0)<1 then @brandid else brandid end, RequestStatus = 0
		from MaintenanceRequests r
		where MaintenanceRequestID = @mrid
		
--select *
--from maintenancerequests 
--where 1 = 1
--and MaintenanceRequestID = 210043
					
		fetch next from @rec into @mrid,@productid,@upc,@vin,@BrandIdentifier,@itemdescription,@dtproductdescription
		,@PrimaryGroupLevel,@AlternateGroupLevel,@ItemGroup,@AlternateItemGroup,@Size,@ManufacturerIdentifier
		,@PrimarySellablePkgIdentifier,@PrimarySellablePkgQty,@VINDescription,@PurchPackDescription,@PurchPackQty	
		,@ProductCategoryId, @chainid, @brandid, @mrcost
	end
	
close @rec
deallocate @rec

/*
select *
--update r set r.requeststatus = 17
from maintenancerequests r
where 1 = 1
and chainid in (62597)
and maintenancerequestid between 225656 and 225678
--and requeststatus = 0
and (Brandid is null or ItemGroup is null or Size is null or PurchPackQty is null or brandidentifier is null)
--and chainid in (44285, 59973)
--and productid is not null
order by maintenancerequestid desc


select *
from brands
where brandname like '%Cold%'

select *
from productbrandassignments
where brandid = 1802

225678
225677
225676
225675
225674
225673
225672
225671
225670
225669
225668
225667
225666
225665
225664
225663
225662
225661
225660
225659
225658
225657
225656

select *
from supplierpackages
where productid = 36147
and vin = '018200000089'

select * from datatrue_edi.dbo.Temp_PDI_AltItemGrps
select * from datatrue_edi.dbo.Temp_PDI_Costs
select * from datatrue_edi.dbo.Temp_PDI_ItemGrp
select * from datatrue_edi.dbo.temp_PDI_ItemPKG where PDIItemNumber = '29760'
select * from datatrue_edi.dbo.Temp_PDI_Retail
select * from datatrue_edi.dbo.Temp_PDI_UPC
select * from datatrue_edi.dbo.Temp_PDI_VendorCostZones
select * from datatrue_edi.dbo.Temp_PDI_Vendors
select * from datatrue_edi.dbo.Temp_PDI_VendorSiteAuthorizations
*/
GO
