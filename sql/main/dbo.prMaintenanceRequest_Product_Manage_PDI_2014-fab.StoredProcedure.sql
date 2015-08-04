USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_Product_Manage_PDI_2014-fab]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_Product_Manage_PDI_2014-fab]
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
declare @requesttypeid int
declare @requestsource nvarchar(50)

set @rec4 = CURSOR local fast_forward FOR
	select maintenancerequestid, LTRIM(rtrim(rawproductidentifier)), LTRIM(rtrim(ItemDescription)) , Chainid, approved--, productid
	,RequestTypeID, ltrim(rtrim(BrandIdentifier)), supplierid, Ltrim(rtrim(isnull(RequestSource, '')))
	from dbo.MaintenanceRequests
	where 1 = 1
	and RequestStatus in (0, 1, 2, 15, -90, -30, -333, -31, 5, 17, 18, 999)
	and ProductId is null
	and (len(upc) < 1 or upc is null)
	and LEN(LTRIM(rtrim(rawproductidentifier))) = 12
	and PDIParticipant = 1
	order by requesttypeid	
	
open @rec4
fetch next from @rec4 into @maintenancerequestid, @upc12, @itemdescription, @chainid, @approved, @requesttypeid, @brandname, @supplierid, @requestsource
while @@FETCH_STATUS = 0
	begin	
			set @productfound = 0
			set @upc = @upc12
			
			select @productid = productid from ProductIdentifiers 
			where LTRIM(rtrim(identifiervalue)) = @upc12
			and ProductIdentifierTypeID = 2
			
			if @@ROWCOUNT > 0
				begin
					set @productfound = 1
					select @productdescription = description from Products where ProductID = @productid
				end
			else
				begin				
				set @upc11 = RIGHT(@upc12, 11)				
				set @CheckDigit = ''
				exec [dbo].[prUtil_UPC_GetCheckDigit]
					 @upc11,
					 @CheckDigit OUT
					 
				set @upc12 = @upc11 + @CheckDigit	
				
				select @productid = productid from ProductIdentifiers 
				where LTRIM(rtrim(identifiervalue)) = @upc12
				and ProductIdentifierTypeID = 2
				
				if @@ROWCOUNT > 0
					begin
						set @productfound = 1
						select @productdescription = description from Products where ProductID = @productid
					end
				else
					begin
						set @upc12 = @upc
					end				
				end				
		  if @productfound = 1
			begin
				update MaintenanceRequests set Productid = @productid, upc = @upc12, upc12 = @upc12, dtproductdescription = @productdescription
				where MaintenanceRequestID = @maintenancerequestid
			end
		  else
			begin			
					if @requestsource in ('EDI')
							begin		
											select * from datatrue_edi.dbo.TranslationTypes t
											inner join datatrue_edi.dbo.TranslationMaster m
											on t.TranslationTypeID = m.TranslationTypeID
											and t.TranslationTypeName = 'MainMaintenanceRequestTableUPCTranslation'
											and m.TranslationSupplierID = @supplierid
										
											if @@ROWCOUNT > 0
												begin												
													set @CheckDigit = ''
													exec [dbo].[prUtil_UPC_GetCheckDigit]
														 @upc11,
														 @CheckDigit OUT	
														 
													set @upc12 = @upc11 + @CheckDigit
													
													update MaintenanceRequests set upc = @upc12
													where MaintenanceRequestID = @maintenancerequestid													
												end
										end
			end
			
		fetch next from @rec4 into @maintenancerequestid, @upc12, @itemdescription, @chainid, @approved, @requesttypeid, @brandname, @supplierid, @requestsource
	end	
close @rec4
deallocate @rec4

Declare @SizeDescription nvarchar(50)
Declare @SellPkgVINAllowReorder nvarchar(50)
Declare @SellPkgVINAllowReclaim  nvarchar(50)
Declare @PrimarySellablePkgIdentifier nvarchar(50)
Declare @VIN nvarchar(50)
Declare @VINDescription nvarchar(50)
Declare @PurchPackDescription nvarchar(50)
Declare @PurchPackQty nvarchar(50)
Declare @AltSellPackage1 nvarchar(50)
Declare @AltSellPackage1Qty nvarchar(50)
Declare @AltSellPackage1UPC nvarchar(50)
Declare @AltSellPackage1Retail nvarchar(50)
declare @count int
declare @productcategoryid int
DECLARE @ownergrouplevelid int
declare @owneritemgroupid int
declare @supplierpackageid int
declare @manfactid int
declare @manfactname nvarchar(255)
--Focus on this one first
set @rec2 = CURSOR local fast_forward FOR
	select maintenancerequestid, LTRIM(rtrim(upc)), LTRIM(rtrim(ItemDescription)) , Chainid, approved--, productid
	,RequestTypeID, ltrim(rtrim(BrandIdentifier)), SupplierID, requestsource, Size, SellPkgVINAllowReorder, SellPkgVINAllowReclaim, 
	PrimarySellablePkgIdentifier, ltrim(rtrim(VIN)), VINDescription, ltrim(rtrim(PurchPackDescription)), PurchPackQty, AltSellPackage1
	,AltSellPackage1Qty, AltSellPackage1UPC, AltSellPackage1Retail, ProductCategoryId
	,PrimaryGroupLevel, ItemGroup, ManufacturerIdentifier
	from dbo.MaintenanceRequests
	where  ProductId is null
	and RequestStatus not in (5, 15, 6, 16, 999, 17, 18)
	and Approved = 1	
	and RequestSource is not null	
	and LEN(LTRIM(rtrim(upc))) = 12
	and PDIParticipant = 1
	order by requesttypeid
	
open @rec2
fetch next from @rec2 into @maintenancerequestid, @upc12, @itemdescription, @chainid, @approved, 
@requesttypeid, @brandname, @supplierid, @requestsource, @SizeDescription,@SellPkgVINAllowReorder, 
@SellPkgVINAllowReclaim,@PrimarySellablePkgIdentifier,@VIN,@VINDescription,
@PurchPackDescription,@PurchPackQty,@AltSellPackage1,@AltSellPackage1Qty,
@AltSellPackage1UPC,@AltSellPackage1Retail,@productcategoryid
,@ownergrouplevelid, @owneritemgroupid, @manfactname
while @@FETCH_STATUS = 0
	begin	
			set @productid = null
			set @productfound = 0
			set @upc = @upc12
			
			select @productid = productid from ProductIdentifiers 
			where LTRIM(rtrim(identifiervalue)) = @upc12
			and ProductIdentifierTypeID = 2
			
			if @@ROWCOUNT > 0
				begin
					set @productfound = 1
					set @productdescription = null
					select @productdescription = description 
					from Products where ProductID = @productid

					if @PurchPackDescription is null or LEN(@PurchPackDescription)<1
						begin
							select @PurchPackDescription = ThisPackageUOMBasis 
							from SupplierPackages 
							where ProductID = @productid 
							and VIN = @VIN
							and (LEN(@PurchPackDescription) < 1 or @PurchPackDescription is null)
						end
					
					if @PurchPackDescription is null or LEN(@PurchPackDescription)<1
						begin
							select @PurchPackDescription = PackIdentifier
							from products
							where ProductID = @productid						
						end
				end
			else
				begin				
				set @upc11 = RIGHT(@upc12, 11)				
				set @CheckDigit = ''
				exec [dbo].[prUtil_UPC_GetCheckDigit]
					 @upc11,
					 @CheckDigit OUT	
					 
				set @upc12 = @upc11 + @CheckDigit	
				
				select @productid = productid from ProductIdentifiers 
				where LTRIM(rtrim(identifiervalue)) = @upc12
				and ProductIdentifierTypeID = 2
				
				if @@ROWCOUNT > 0
					begin
						set @productfound = 1
						select @productdescription = description from Products where ProductID = @productid
					end
				else
					begin
						set @upc12 = @upc
					end			
				
				end
				
		  if @productfound = 1
			begin
				update MaintenanceRequests set Productid = @productid, upc12 = @upc12, 
				dtproductdescription = @productdescription,
				PurchPackDescription = @PurchPackDescription
				where MaintenanceRequestID = @maintenancerequestid				
			end	
		  else
			begin
				if @approved = 1 or @chainid = 44285
					begin
							if @addnewproduct = 1 and @requesttypeid in (1,15)
								begin										
								INSERT INTO [dbo].[Products]
								   ([ProductName]
								   ,[Description]
								   ,[ActiveStartDate]
								   ,[ActiveLastDate]
								   ,[LastUpdateUserID])
								VALUES
								   (@itemdescription
								   ,@itemdescription
								   ,GETDATE()
								   ,'12/31/2025'
								   ,2)

								set @productid = Scope_Identity()						
														   
								update MaintenanceRequests set Productid = @productid, upc = @upc12, 
								upc12 = @upc12, dtproductdescription = @itemdescription,
								PurchPackDescription = @PurchPackDescription
								where MaintenanceRequestID = @maintenancerequestid																	   
							end					
					end					
			end		
								set @count = 0
								
								select @count= count(*)
								from [DataTrue_Main].[dbo].[ChainProductFactors]
								where ChainID = @chainid
								and ProductID = @productid
								
								If @count < 1
									begin								
										INSERT INTO [DataTrue_Main].[dbo].[ChainProductFactors]
										   ([ChainID]
										   ,[ProductID]
										   ,[BrandID]
										   ,[BaseUnitsCalculationPerNoOfweeks]
										   ,[CostFromRetailPercent]
										   ,[BillingRuleID]
										   ,[ActiveStartDate]
										   ,[ActiveEndDate]
										   ,[LastUpdateUserID])
										SELECT @chainid
											  ,@productid
											  ,0 --@brandid
											  ,[BaseUnitsCalculationPerNoOfweeks]
											  ,[CostFromRetailPercent]
											  ,[BillingRuleID]
											  ,[ActiveStartDate]
											  ,[ActiveEndDate]
											  ,2
										  FROM [DataTrue_Main].[dbo].[ChainProductFactors]
										  where 1 = 1
										  and ChainID = @chainid
										  and productid = 0
									end
								set @count = 0
								
								select @count= count(*)
								from [DataTrue_Main].[dbo].[ProductIdentifiers]
								where IdentifierValue = @upc12
								and ProductIdentifierTypeID = 2
								
								If @count < 1
									begin								  
										INSERT INTO [dbo].[ProductIdentifiers]
										   ([ProductID]
										   ,[ProductIdentifierTypeID]
										   ,[OwnerEntityId]
										   ,[IdentifierValue]
										   ,[LastUpdateUserID])
										VALUES
										   (@productid
										   ,2 --UPC is type 2
										   ,0 -- 0 is default entity
										   ,@UPC12
										   ,0)
									end
								set @count = 0								
								select @count= count(*)
								from [DataTrue_Main].[dbo].[SupplierPackages]
								where ltrim(rtrim(VIN)) = @VIN
								and OwnerPackageIdentifier = @PurchPackDescription
								and OwnerEntityId = @chainid
								
								If @count < 1
									begin																												   
										INSERT INTO [DataTrue_Main].[dbo].[SupplierPackages]
												   ([SupplierPackageTypeID]
												   ,[SupplierID]
												   ,[OwnerEntityID]
												   ,[OwnerPackageIdentifier]
												   ,[OwnerPackageDescription]
												   ,[OwnerPackageSizeDescription]
												   ,[OwnerPackageQty]
												   ,[VIN]
												   ,[ProductID]
												   ,[ThisPackageUOMBasis]
												   ,[ThisPackageUOMBasisQty]
												   ,[ThisPackageEACHBasisQty]
												   ,[AllowReorder]
												   ,[AllowReclaim]
												   ,[Purchasable]
												   ,[Sellable])
										VALUES (1
											  ,@SupplierID
											  ,@chainid
											  ,@PurchPackDescription
											  ,@VINDescription
											  ,@SizeDescription
											  ,@PurchPackQty      
											  ,@VIN
											  ,@ProductID
											  ,@PurchPackDescription
											  ,1
											  ,@PurchPackQty
											  ,case when @SellPkgVINAllowReorder = 'Y' then 1 else 0 end
											  ,case when @SellPkgVINAllowReClaim = 'Y' then 1 else 0 end
											  ,case when @SellPkgVINAllowReorder = 'Y' then 1 else 0 end
											  ,1)
											  
										set @supplierpackageid = SCOPE_IDENTITY()
										
								update MaintenanceRequests set SupplierPackageID = @supplierpackageid
								where MaintenanceRequestID = @maintenancerequestid		
							end										   
						         If @brandname is not null
									begin
										select @manfactid = ManufacturerID
										from Manufacturers
										where OwnerEntityID = @chainid
										and OwnerManufacturerIdentifier = @manfactname					
										if @@ROWCOUNT < 1
											begin											
												INSERT INTO [DataTrue_Main].[dbo].[SystemEntities]
													   ([EntityTypeID]
													   ,[DateTimeCreated]
													   ,[LastUpdateUserID]
													   ,[DateTimeLastUpdate])
												 VALUES
													   (11 --<EntityTypeID, int,>
													   ,GETDATE() --<DateTimeCreated, datetime,>
													   ,0 --<LastUpdateUserID, int,>
													   ,GETDATE()) --<DateTimeLastUpdate, datetime,>

												set @manfactid = SCOPE_IDENTITY()																						
										
										INSERT INTO [DataTrue_Main].[dbo].[Manufacturers]
											   ([ManufacturerID]
											   ,[ManufacturerName]
											   ,[ManufacturerIdentifier]
											   ,[ActiveStartDate]
											   ,[ActiveLastDate]
											   ,[Comments]
											   ,[DateTimeCreated]
											   ,[LastUpdateUserID]
											   ,[DateTimeLastUpdate]
											   ,[OwnerEntityID]
											   ,[OwnerManufacturerIdentifier])
										 VALUES
											   (@manfactid --<ManufacturerID, int,>
											   ,@manfactname --<ManufacturerName, nvarchar(100),>
											   ,@manfactname --<ManufacturerIdentifier, nvarchar(50),>
											   ,'1/1/2013' --<ActiveStartDate, smalldatetime,>
											   ,'12/31/2025' --<ActiveLastDate, smalldatetime,>
											   ,'' --<Comments, nvarchar(500),>
											   ,GETDATE() --<DateTimeCreated, datetime,>
											   ,0 --<LastUpdateUserID, nvarchar(50),>
											   ,GETDATE() --<DateTimeLastUpdate, datetime,>
											   ,@chainid --<OwnerEntityID, int,>
											   ,@manfactname) --<OwnerManufacturerIdentifier, nvarchar(50),>)								
									end								
										set @brandid = null	
																			
										select @brandid = brandid										
										from Brands
										where LTRIM(rtrim(OwnerBrandIdentifier)) = @brandname
										and Ownerentityid = @chainid
										
										if @@ROWCOUNT < 1
											begin
												INSERT INTO [DataTrue_Main].[dbo].[Brands]
														   ([ManufacturerID]
														   ,[BrandName]
														   ,[BrandIdentifier]
														   ,[BrandDescription]
														   ,[OwnerEntityID]
														   ,[OwnerBrandIdentifier])
												Values (@manfactid, @brandname, @brandname, '', @chainid, @brandname)
												
												set @brandid = SCOPE_IDENTITY()
											end		
									end  						           
						         set @count = 0
								
								select @count= count(*)
								from [DataTrue_Main].[dbo].[ProductBrandAssignments]
								where BrandID = @brandid
								and ProductId = @productid
								and CustomOwnerEntityID = @chainid
								
								If @count < 1 and @brandid is not null
									begin										 
										 INSERT INTO [dbo].[ProductBrandAssignments]
												   ([BrandID]
												   ,[ProductID]
												   ,[CustomOwnerEntityID]
												   ,[LastUpdateUserID])
											 VALUES
												   (isnull(@brandid, 0)
												   ,@productid
												   ,@chainid
												   ,2)
									end	
									
								select @count= count(*)
								from [DataTrue_Main].[dbo].[ProductCategoryAssignments]
								where ProductCategoryID = @productcategoryid
								and ProductId = @productid
								and CustomOwnerEntityID = @chainid
								
								If @count < 1
									begin									
										select @productcategoryid = ProductCategoryID
										from [ProductCategories] 
										where [OwnerEntityID] = @chainid
										and OwnerGroupLevelID = @ownergrouplevelid
										and OwnerGroupID = @owneritemgroupid
									
											 INSERT INTO [dbo].[ProductCategoryAssignments]
												   ([ProductCategoryID]
												   ,[ProductID]
												   ,[CustomOwnerEntityID]
												   ,[LastUpdateUserID])
											 VALUES
												   (isnull(@productcategoryid, 0)
												   ,@productid
												   ,@chainid
												   ,2)
									end										
									
											
		fetch next from @rec2 into @maintenancerequestid, @upc12, @itemdescription, @chainid, @approved, 
			@requesttypeid, @brandname, @supplierid, @requestsource, @SizeDescription,@SellPkgVINAllowReorder, 
			@SellPkgVINAllowReclaim,@PrimarySellablePkgIdentifier,@VIN,@VINDescription,
			@PurchPackDescription,@PurchPackQty,@AltSellPackage1,@AltSellPackage1Qty,
			@AltSellPackage1UPC,@AltSellPackage1Retail,@productcategoryid
			,@ownergrouplevelid, @owneritemgroupid, @manfactname
	end
	
close @rec2
deallocate @rec2

return
GO
