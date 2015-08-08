USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_Product_Manage_2014fab03_UPC13]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_Product_Manage_2014fab03_UPC13]
as

declare @rec cursor
declare @rec2 cursor
declare @rec5 cursor
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
declare @rawprod nvarchar(50)
declare @noupc bit=1
declare @chainid int
declare @addnewproduct bit=1
declare @productfound bit
declare @approved bit
declare @recten cursor
declare @brandname nvarchar(50)
declare @supplierid int
declare @requesttypeid int
declare @requestsource nvarchar(50)
declare @ProdIdTypeID int
--******************
declare @spcnt int
declare @bipad varchar(50)
declare @PDIParticipant bit
--************
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
declare @PrimarySellablePkg nvarchar(50)
declare @PrimarySellablePkgQty nvarchar(50)

set @rec2 = CURSOR local fast_forward FOR
	select maintenancerequestid, LTRIM(rtrim(upc))upc,LEN(LTRIM(rtrim(rawproductidentifier)))rawprod, LTRIM(rtrim(ItemDescription)) , Chainid, approved--, productid
	,RequestTypeID, ltrim(rtrim(BrandIdentifier)), SupplierID, requestsource,PDIParticipant, ltrim(rtrim(Bipad)),
	 Size, SellPkgVINAllowReorder, SellPkgVINAllowReclaim,PrimarySellablePkgIdentifier, ltrim(rtrim(VIN)), 
	 VINDescription, ltrim(rtrim(PurchPackDescription)), PurchPackQty, AltSellPackage1,AltSellPackage1Qty,
	  AltSellPackage1UPC, AltSellPackage1Retail, ProductCategoryId,PrimaryGroupLevel, ItemGroup, ManufacturerIdentifier, PrimarySellablePkgIdentifier, PrimarySellablePkgQty
     from dbo.MaintenanceRequests
	where ProductId is null
	and RequestStatus not in (5, 15, 6, 16, 999)	
	and ISNULL(PDIParticipant, 0) <> 1
	and ((isnull(Approved, -1) <> 0	and RequestSource is not null and LEN(LTRIM(rtrim(upc))) = 12)
	or ((len(upc) < 1 or upc is null)
	and LEN(LTRIM(rtrim(rawproductidentifier))) = 12)
	--and RequestTypeID not in (1)	
	--and requestsource in ('EDI')
	 )
		
	order by requesttypeid

   	/*
    where  RequestStatus in (0, 1, 2, -90, -30, -333, -31, 5, 17, 999)
	and ProductId is null
	and (len(upc) < 1 or upc is null or LEFT(LTRIM(rtrim(upc)), 2) = '00')
 	and LEFT(LTRIM(rtrim(rawproductidentifier)), 2) = '00'
	and LEN(LTRIM(rtrim(rawproductidentifier))) = 12
	and ISNULL(PDIParticipant, 0) <> 1
	and SupplierID = 40559
	and RequestTypeID not in (1)	
	and requestsource in ('EDI')*/
	
open @rec2
fetch next from @rec2 into @maintenancerequestid, @upc12,@rawprod, @itemdescription, @chainid, 
@approved, @requesttypeid, @brandname, @supplierid, @requestsource,@PDIParticipant, @Bipad,
 @SizeDescription,@SellPkgVINAllowReorder, 
@SellPkgVINAllowReclaim,@PrimarySellablePkgIdentifier,@VIN,@VINDescription,
@PurchPackDescription,@PurchPackQty,@AltSellPackage1,@AltSellPackage1Qty,
@AltSellPackage1UPC,@AltSellPackage1Retail,@productcategoryid
,@ownergrouplevelid, @owneritemgroupid, @manfactname, @PrimarySellablePkg, @PrimarySellablePkgQty
while @@FETCH_STATUS = 0
	begin	
	       if len(@upc12) <>12
	       begin
	          set @noupc=1
	          set @upc12 = @rawprod
	        end
	        else
	        begin
	          set @noupc=0
	        end	 
	        set @productfound = 0
			set @upc = @upc12	     
	        select @spcnt=COUNT(*)  from ChainSupplierProductType where supplierId=@supplierId;
	        if @spcnt>0
	        begin
	        set	@ProdIdTypeID=8
	        select @productid = productid from ProductIdentifiers 
			where ltrim(rtrim(Bipad)) = @bipad
			and ProductIdentifierTypeID = @ProdIdTypeID
	        
			end
			else
			begin
			set	@ProdIdTypeID=2
			select @productid = productid from ProductIdentifiers 
			where LTRIM(rtrim(identifiervalue)) = @upc12
			and ProductIdentifierTypeID =@ProdIdTypeID	
			end		
				
			
			
			--select 	*from ProductIdentifiers p
			--inner join  storesetup s on s.productid=p.productid
			--inner join ChainSupplierProductType t on t.supplierid=s.supplierid
			--and LTRIM(rtrim(identifiervalue)) = @upc12
			--and ProductIdentifierTypeID =8
		
if @@ROWCOUNT > 0
				begin
					set @productfound = 1
					select @productdescription = description from Products where ProductID = @productid
				end
			 /* only for PDI******/		
			 If @PDIParticipant=1
		     begin
		           if @PurchPackDescription is null or LEN(@PurchPackDescription)<1
						begin	

                            select * from SupplierPackages 
                            where ProductID = @productid    and VIN = @VIN
							
							select @PurchPackDescription = OwnerPackageIdentifier --20131219ThisPackageUOMBasis 
							from SupplierPackages 
							where ProductID = @productid 
							and VIN = @VIN
							and (LEN(@PurchPackDescription) < 1 or @PurchPackDescription is null)
													
							select @PurchPackDescription = PackIdentifier
							from products
							where ProductID = @productid 
						
						end
            /**********end of if PDI***********/			  
		     end	
	else /*the product is not found */    	 
			
				begin				
				set @upc11 = RIGHT(@upc12, 11)				
				set @CheckDigit = ''
				exec [dbo].[prUtil_UPC_GetCheckDigit]
					 @upc11,
					 @CheckDigit OUT						 
				set @upc12 = @upc11 + @CheckDigit	
				if	@ProdIdTypeID=2	
				begin		
				select @productid = productid from ProductIdentifiers 
				where LTRIM(rtrim(identifiervalue)) = @upc12
				and ProductIdentifierTypeID = @ProdIdTypeID
				end
				if	@ProdIdTypeID=8
				begin
				select @productid = productid from ProductIdentifiers 
			    where ltrim(rtrim(Bipad)) = @bipad
			    and ProductIdentifierTypeID = @ProdIdTypeID
				end
				
				
					
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
			/*product is in the system********/	
		if @productfound = 1
		  begin 
		    If @PDIParticipant=1
		    /**updates only for PDI************/
		       begin
		       select @supplierpackageid = supplierpackageid
				from SupplierPackages
				where SupplierID = @supplierid
				and OwnerEntityID = @chainid
				and ProductID = @productid
				and OwnerPackageIdentifier = @PurchPackDescription
			
				update MaintenanceRequests set Productid = @productid, upc12 = @upc12, 
				dtproductdescription = @productdescription,
				PurchPackDescription = @PurchPackDescription
				,Supplierpackageid = @supplierpackageid
				,RequestStatus = 18
				where MaintenanceRequestID = @maintenancerequestid
		       end
		      
		     else
		     /*******not for PDI****************/
			   begin
				update MaintenanceRequests set Productid = @productid, upc = @upc12, upc12 = @upc12, dtproductdescription = @productdescription
				where MaintenanceRequestID = @maintenancerequestid
			   end
		  end
	 else
		/*product is not in the system********/	
		begin
			    
			if @approved = 1
				begin
					if @addnewproduct = 1 and @requesttypeid in (1) and @PDIParticipant<>1
					begin			
											
									if @requestsource in ('EDI') and LEFT(@upc, 2) = '00'
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
												end
										end
							
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
								   ,2)						           
						         If @brandname is not null
									begin									
										set @brandid = null										
										select @brandid = brandid
										from Brands
										where LTRIM(rtrim(BrandName)) = @BrandName										
									end 						           
						           
								 INSERT INTO [dbo].[ProductBrandAssignments]
										   ([BrandID]
										   ,[ProductID]
										   ,[CustomOwnerEntityID]
										   ,[LastUpdateUserID])
									 VALUES
										   (isnull(@brandid, 0)
										   ,@productid
										   ,0
										   ,2)										   
								update MaintenanceRequests set Productid = @productid, upc = @upc12, upc12 = @upc12, dtproductdescription = @itemdescription
								where MaintenanceRequestID = @maintenancerequestid																		   
/*end of @PDIParticipant<>1*/
                            end
                        if @PDIParticipant=1 and @addnewproduct = 1 and @requesttypeid in (1,15)
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
								PurchPackDescription = @PurchPackDescription, RequestStatus = 18
								where MaintenanceRequestID = @maintenancerequestid																		   
/*end of @PDIParticipant<>1*/
							end		
/*end of Aproved=1*/						
                      end
 /* for PDI records and not only Aproved*/
                     
                   if @PDIParticipant=1 
                   begin
                   set @count = 0
								
								select @count= count(*)
								from [DataTrue_Main].[dbo].[ChainProductFactors]
								where ChainID = @chainid
								and ProductID = @productid
								
								If @count < 1 and @productid is not null
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
								
								If @count < 1and @productid is not null
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
								set @supplierpackageid = null
								
								select @count= count(*)
								from [DataTrue_Main].[dbo].[SupplierPackages]
								where ltrim(rtrim(VIN)) = @VIN
								and OwnerPackageIdentifier = @PurchPackDescription
								and OwnerEntityId = @chainid
								and ProductID = @productid
								
								If @count < 1and @productid is not null and @PurchPackDescription is not null and @VIN is not null
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
												   ,[Sellable]
												   ,[OwnerTradeItemSizeUOM]
												   ,[OwnerTradeItemSizeQty])
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
											  ,1
											  ,@PrimarySellablePkg
											  ,@PrimarySellablePkgQty)
											  
										set @supplierpackageid = SCOPE_IDENTITY()
								
										if @supplierpackageid is not null
											begin		
												update MaintenanceRequests set SupplierPackageID = @supplierpackageid
												where MaintenanceRequestID = @maintenancerequestid		
												--alter table MaintenanceRequests add SupplierPackageID INT  
											end
									
									end							  
								   
						         If @brandname is not null and @productid is not null
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
										--select *
										from Brands
										where LTRIM(rtrim(OwnerBrandIdentifier)) = @brandname
										and Ownerentityid = @chainid
										
										if @@ROWCOUNT < 1 and @productid is not null and @brandname is not null and @manfactid is not null
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
								
								If @count < 1 and @brandid is not null and @productid is not null
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

								
								If @count < 1 and @productid is not null and @productcategoryid is not null
									begin	
									
										select @productcategoryid = ProductCategoryID
										from [ProductCategories] 
										where [OwnerEntityID] = @chainid
										and OwnerGroupLevelID = @ownergrouplevelid
										and OwnerGroupID = @owneritemgroupid
									
									--select * from [ProductCategories] where [OwnerEntityID] = 59973
									 --select * from [ProductCategoryAssignments] where [CustomOwnerEntityID] = 59973
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
			,@ownergrouplevelid, @owneritemgroupid, @manfactname,@PrimarySellablePkg,@PrimarySellablePkgQty

                   end  
                      
                      
		end			
		fetch next from @rec2 into @maintenancerequestid, @upc12,@rawprod, @itemdescription, @chainid, @approved, @requesttypeid, @brandname, @supplierid, @requestsource
	end	
close @rec2
deallocate @rec2

declare @mrid int
declare @banner nvarchar(50)
declare @cost money

set @rec5 = CURSOR local fast_forward FOR
	select MaintenanceRequestid, ltrim(rtrim(Banner)), UPC12, ProductID, supplierid
	from MaintenanceRequests
	where ProductId is not null
	and requesttypeid = 1
	and ISNULL(cost, 0) = 0
	and (approved is null or approved = 1)
	and requeststatus not in (5, 6, 15, 16, 17, 18, 999, -89, 9, -5)
	
open @rec5
fetch next from @rec5 into @mrid, @banner, @upc12, @productid, @supplierid
while @@FETCH_STATUS = 0
	begin	
		set @cost = null		
		select @cost = cost from MaintenanceRequests
		where productid = @productid 
		and LTRIM(rtrim(Banner)) = @banner
		and requesttypeid in (1, 2)
		and cost > 0
		and requeststatus in (0, 1, 2)
		and supplierid = @supplierid
		
		if isnull(@cost, 0) > 0
			begin
				update MaintenanceRequests set Cost = @cost where Maintenancerequestid = @mrid			
			end
		else
			begin
				update MaintenanceRequests set requeststatus = -30 where Maintenancerequestid = @mrid
								
				exec dbo.prSendEmailNotification_PassEmailAddresses 'MaintenanceRequest Records Found With Zero Costs Set to -31'
				,'MaintenanceRequest Records Found With Zero Costs Set to -30'
				,'DataTrue System', 0, 'irina.trush@icontroldsd.com'
			end		
		fetch next from @rec5 into @mrid, @banner, @upc12, @productid, @supplierid	
	end
	
close @rec5
deallocate @rec5

declare @rec6 cursor
declare @validupc nvarchar(50)

set @rec6 = CURSOR local fast_forward FOR
	select MaintenanceRequestid, ltrim(rtrim(Banner)), ltrim(rtrim(UPC12)), ProductID, supplierid
	from MaintenanceRequests
	where ProductId is not null
	and LEN(ltrim(rtrim(UPC12))) = 12
	and (approved is null or approved = 1)
	and requeststatus not in (5, 6, 15, 16, 17, 18, 999, -89, 9, -5)
	and CAST(submitdatetime as date) > '3/1/2013'
	
open @rec6
fetch next from @rec6 into @mrid, @banner, @upc12, @productid, @supplierid
while @@FETCH_STATUS = 0
	begin	
		set @validupc = null		
		select @validupc = LTRIM(rtrim(identifiervalue))
		from ProductIdentifiers
		where productid = @productid 
		and ProductIdentifierTypeID = 2		
	
		if @upc12 <> @validupc
			begin
				update MaintenanceRequests set upc = @validupc, upc12 = @validupc where Maintenancerequestid = @mrid			
			end	
		fetch next from @rec6 into @mrid, @banner, @upc12, @productid, @supplierid	
	end	
close @rec6
deallocate @rec6
return
GO
