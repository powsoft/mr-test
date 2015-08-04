USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_Product_Manage_Debug_PDI]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_Product_Manage_Debug_PDI]
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
/*
select top 100 * from dbo.MaintenanceRequests where supplierid = 44269
select * from productidentifiers where productid = 16396 --16640 024126008221
select * 
--update mr set mr.dtproductdescription = p.description
from dbo.MaintenanceRequests mr
inner join products p
on mr.productid = p.productid
where mr.productid is not null and mr.dtproductdescription is null
*/
--***************************TEN****************************************

set @recten = CURSOR local fast_forward FOR
	select maintenancerequestid, LTRIM(rtrim(upc)), LTRIM(rtrim(ItemDescription)) , Chainid--, productid
	from dbo.MaintenanceRequests
	where 1 = 1
	and RequestStatus in (1,2)
	and ProductId is null
	and Approved = 1
	--and MaintenanceRequestID in (8563,8560)
	--and SupplierID = 40567
	and SupplierID = 50725111111111111111111111
	and LEN(LTRIM(rtrim(upc))) = 10
/*	
	and MaintenanceRequestID in (35770,
35771,
35772,
35773,
35774,
35775,
35776,
35777,
40924,
40923,
40925,
42008)
*/
	
open @recten

fetch next from @recten into @maintenancerequestid, @mrupc, @itemdescription, @chainid

while @@FETCH_STATUS = 0
	begin
	
				set @productfound = 0
				


			if @productfound = 0
				begin
				
				--set @upc11 = @mrupc
				set @upc11 = '0' + @mrupc
				
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

				
				end

--/*			
			if @@ROWCOUNT < 1 and @addnewproduct = 1 and 1 = 2
				begin
			
				INSERT INTO [dbo].[Products]
				   ([ProductName]
				   ,[Description]
				   ,[ActiveStartDate]
				   ,[ActiveLastDate]
				   ,[LastUpdateUserID])
				VALUES
				   (@UPC12
				   ,@itemdescription
				   ,GETDATE()
				   ,'12/31/2025'
				   ,2)

				set @productid = Scope_Identity()
		--print 'four'	
		
		--insert default ChainProductFactors record for new product
		--select * from ChainProductFactors where productid = 0
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
		           
				 INSERT INTO [dbo].[ProductBrandAssignments]
						   ([BrandID]
						   ,[ProductID]
						   ,[CustomOwnerEntityID]
						   ,[LastUpdateUserID])
					 VALUES
						   (0 --@brandid
						   ,@productid
						   ,0
						   ,2)
						   
					set @productfound = 1	   
			end
--*/		  
		  print @productid
		  if @productfound = 1
			begin
				update MaintenanceRequests set Productid = @productid, upc12 = @upc12, dtproductdescription = @productdescription
				where MaintenanceRequestID = @maintenancerequestid
			end
--********************************************************************************	
/*	
		set @lenofupc = LEN(@mrupc)
		if @lenofupc = 12
			begin
				select @productid = ProductId
				from ProductIdentifiers
				where IdentifierValue = @mrupc
				and ProductIdentifierTypeID = 2
				if @@ROWCOUNT > 0
					begin
						update MaintenanceRequests set Productid = @productid
						where MaintenanceRequestID = @maintenancerequestid
					end
			end
		if @lenofupc = 11
			begin
				select @productid = ProductId
				from ProductIdentifiers
				where IdentifierValue = '0' + @mrupc
				and ProductIdentifierTypeID = 2			
				if @@ROWCOUNT > 0
					begin
						update MaintenanceRequests set Productid = @productid
						where MaintenanceRequestID = @maintenancerequestid
					end			
			end
		if @lenofupc = 11 and @productid is null
			begin
				set @CheckDigit = ''
				exec [dbo].[prUtil_UPC_GetCheckDigit]
					 @mrupc,
					 @CheckDigit OUT

				select @productid = productid
				from productidentifiers
				where identifiervalue = @mrupc + @CheckDigit
		
				if @@ROWCOUNT > 0
					begin
						update MaintenanceRequests set Productid = @productid
						where MaintenanceRequestID = @maintenancerequestid
					end			
			end		
*/			
			
		fetch next from @recten into @maintenancerequestid, @mrupc, @itemdescription, @chainid
	end
	
close @recten
deallocate @recten
	
	

--**************************ELEVEN***************************************
set @rec = CURSOR local fast_forward FOR
	select maintenancerequestid, LTRIM(rtrim(upc)), LTRIM(rtrim(ItemDescription)) , Chainid--, productid
	from dbo.MaintenanceRequests
	where 1 = 1
	and RequestStatus in (0, 7, 8)
	and ProductId is null
	--and MaintenanceRequestID in (8563,8560)
	--and SupplierID = 40567
	and SupplierID = 41111111111111
	and LEN(LTRIM(rtrim(upc))) = 11
	
open @rec

fetch next from @rec into @maintenancerequestid, @mrupc, @itemdescription, @chainid

while @@FETCH_STATUS = 0
	begin
	
				set @productfound = 0
				

				set @upc12 = '0' + @mrupc

--********************************************************************************
			select @productid = productid from ProductIdentifiers 
			where LTRIM(rtrim(identifiervalue)) = @upc12
			and ProductIdentifierTypeID = 2
			
			if @@ROWCOUNT > 0
				begin
					set @productfound = 1
					select @productdescription = description from Products where ProductID = @productid
				end
				
			if @productfound = 0
				begin
				
				set @upc11 = @mrupc
				--set @upc11 = '0' + @mrupc
				
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

				
				end

--/*			
			if @@ROWCOUNT < 1 and @addnewproduct = 1 and 1 = 2
				begin
			
				INSERT INTO [dbo].[Products]
				   ([ProductName]
				   ,[Description]
				   ,[ActiveStartDate]
				   ,[ActiveLastDate]
				   ,[LastUpdateUserID])
				VALUES
				   (@UPC12
				   ,@itemdescription
				   ,GETDATE()
				   ,'12/31/2025'
				   ,2)

				set @productid = Scope_Identity()
		--print 'four'	
		
		--insert default ChainProductFactors record for new product
		--select * from ChainProductFactors where productid = 0
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
		           
				 INSERT INTO [dbo].[ProductBrandAssignments]
						   ([BrandID]
						   ,[ProductID]
						   ,[CustomOwnerEntityID]
						   ,[LastUpdateUserID])
					 VALUES
						   (0 --@brandid
						   ,@productid
						   ,0
						   ,2)
						   
					set @productfound = 1	   
			end
--*/		  
		  print @productid
		  if @productfound = 1
			begin
				update MaintenanceRequests set Productid = @productid, upc12 = @upc12, dtproductdescription = @productdescription
				where MaintenanceRequestID = @maintenancerequestid
			end
--********************************************************************************	
/*	
		set @lenofupc = LEN(@mrupc)
		if @lenofupc = 12
			begin
				select @productid = ProductId
				from ProductIdentifiers
				where IdentifierValue = @mrupc
				and ProductIdentifierTypeID = 2
				if @@ROWCOUNT > 0
					begin
						update MaintenanceRequests set Productid = @productid
						where MaintenanceRequestID = @maintenancerequestid
					end
			end
		if @lenofupc = 11
			begin
				select @productid = ProductId
				from ProductIdentifiers
				where IdentifierValue = '0' + @mrupc
				and ProductIdentifierTypeID = 2			
				if @@ROWCOUNT > 0
					begin
						update MaintenanceRequests set Productid = @productid
						where MaintenanceRequestID = @maintenancerequestid
					end			
			end
		if @lenofupc = 11 and @productid is null
			begin
				set @CheckDigit = ''
				exec [dbo].[prUtil_UPC_GetCheckDigit]
					 @mrupc,
					 @CheckDigit OUT

				select @productid = productid
				from productidentifiers
				where identifiervalue = @mrupc + @CheckDigit
		
				if @@ROWCOUNT > 0
					begin
						update MaintenanceRequests set Productid = @productid
						where MaintenanceRequestID = @maintenancerequestid
					end			
			end		
*/			
			
		fetch next from @rec into @maintenancerequestid, @mrupc, @itemdescription, @chainid
	end
	
close @rec
deallocate @rec

declare @requesttypeid int
declare @requestsource nvarchar(50)



set @rec4 = CURSOR local fast_forward FOR
	select maintenancerequestid, LTRIM(rtrim(rawproductidentifier)), LTRIM(rtrim(ItemDescription)) , Chainid, approved--, productid
	,RequestTypeID, ltrim(rtrim(BrandIdentifier)), supplierid, Ltrim(rtrim(isnull(RequestSource, '')))
	--into import.dbo.tmpMaintenanceRequestRecordsThatGotWrongProductIDs_20111231
	from dbo.MaintenanceRequests
	where 1 = 1
	and RequestStatus in (0, 1, 2, -90, -30, -333, -31, 5, 17, 999)
	and ProductId is null
	and (len(upc) < 1 or upc is null)
	and LEN(LTRIM(rtrim(rawproductidentifier))) = 12
	--and SupplierID <> 40559
	--and @requestsource in ('EDI')
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

set @rec2 = CURSOR local fast_forward FOR
	select maintenancerequestid, LTRIM(rtrim(upc)), LTRIM(rtrim(ItemDescription)) , Chainid, approved--, productid
	,RequestTypeID, ltrim(rtrim(BrandIdentifier)), SupplierID, requestsource, Size, SellPkgVINAllowReorder, SellPkgVINAllowReclaim, 
	PrimarySellablePkgIdentifier, ltrim(rtrim(VIN)), VINDescription, ltrim(rtrim(PurchPackDescription)), PurchPackQty, AltSellPackage1, AltSellPackage1Qty, AltSellPackage1UPC, AltSellPackage1Retail
	--into import.dbo.tmpMaintenanceRequestRecordsThatGotWrongProductIDs_20111231
	from dbo.MaintenanceRequests
	where 1 = 1
	--and RequestStatus in (0, 1, -90, -30, -333, -31, 5, 17)
	and ProductId is null
	and RequestStatus in (17)
	--and RequestStatus not in (5, 15, 6, 16, 999)
	--and requesttypeid in (1,2)
	and isnull(Approved, -1) <> 0
	--and SupplierID = 50725
	and ChainID = 62597
	and RequestSource is not null
	--and (Approved = 1 or RequestStatus in (-25, -26, -90, -30, -333, -31))
	and LEN(LTRIM(rtrim(upc))) = 12
	and PDIParticipant = 1
	--and SupplierID <> 40559
	order by requesttypeid


	
	
open @rec2

fetch next from @rec2 into @maintenancerequestid, @upc12, @itemdescription, @chainid, @approved, 
@requesttypeid, @brandname, @supplierid, @requestsource, @SizeDescription,@SellPkgVINAllowReorder, 
@SellPkgVINAllowReclaim,@PrimarySellablePkgIdentifier,@VIN,@VINDescription,
@PurchPackDescription,@PurchPackQty,@AltSellPackage1,@AltSellPackage1Qty,
@AltSellPackage1UPC,@AltSellPackage1Retail

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
				update MaintenanceRequests set Productid = @productid, upc12 = @upc12, dtproductdescription = @productdescription
				where MaintenanceRequestID = @maintenancerequestid
				
								--		set @brandid = null
										
								--		select @brandid = brandid
								--		from Brands
								--		where LTRIM(rtrim(OwnerBrandIdentifier)) = @BrandName
								--		and OwnerEntityID = @supplierid
								--/*
						  --         select top 100 * 
						  --         --delete
						  --         from ProductBrandAssignments 
						  --         where productid = 31908 
						  --         order by datetimecreated desc
						  --         */
						           
								-- INSERT INTO [dbo].[ProductBrandAssignments]
								--		   ([BrandID]
								--		   ,[ProductID]
								--		   ,[CustomOwnerEntityID]
								--		   ,[LastUpdateUserID])
								--	 VALUES
								--		   (isnull(@brandid, 0)
								--		   ,@productid
								--		   ,@supplierid
								--		   ,2)
			end
		--/*
		  else
			begin
				if @approved = 1 or @chainid = 62597
					begin
							if @addnewproduct = 1 and @requesttypeid in (1)
								begin
								
											
									--if @requestsource in ('EDI')
									--	begin		
									--		select * from datatrue_edi.dbo.TranslationTypes t
									--		inner join datatrue_edi.dbo.TranslationMaster m
									--		on t.TranslationTypeID = m.TranslationTypeID
									--		and t.TranslationTypeName = 'MainMaintenanceRequestTableUPCTranslation'
									--		and m.TranslationSupplierID = @supplierid
										
									--		if @@ROWCOUNT > 0
									--			begin
												
									--				set @CheckDigit = ''
									--				exec [dbo].[prUtil_UPC_GetCheckDigit]
									--					 @upc11,
									--					 @CheckDigit OUT	
														 
									--				set @upc12 = @upc11 + @CheckDigit
									--			end
									--	end
							
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
						--print 'four'	
						--select top 1000 * from products order by productid desc
						/*
						select p.*, r.*
						--update p set p.UOM = r.PrimarySellablePkgIdentifier
						from maintenancerequests r
						inner join products p
						on r.productid = p.productid
						where supplierid = 44269
						
						select *
						from supplierpackages
						where supplierid = 44269
						
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
SELECT 1
      ,SupplierID
      ,SupplierID
      ,[PurchPackDescription]
      ,[VINDescription]
      ,[Size]
      ,[PurchPackQty]      
      ,[VIN]
      ,[ProductID]
	  ,[PurchPackDescription]
	  ,1
	  ,[PurchPackQty]
	  ,1
	  ,0
	  ,1
	  ,1
	  --select *
  FROM [DataTrue_Main].[dbo].[MaintenanceRequests]
where supplierid = 44269

--select *
from productprices
where productpricetypeid = 11

select SupplierPackageID, p.ProductID, r.Cost, r.SuggestedRetail, r.SupplierID, r.ChainID, r.startdatetime, r.enddatetime
into #tempPackCosts
from supplierpackages p
inner join maintenancerequests r
on p.productid = r.productid

INSERT INTO [DataTrue_Main].[dbo].[ProductPrices]
           ([ProductPriceTypeID]
           ,[ProductID]
           ,[ChainID]
           ,[StoreID]
           ,[BrandID]
           ,[SupplierID]
           ,[UnitPrice]
           ,[UnitRetail]
           ,[ActiveStartDate]
           ,[ActiveLastDate]
           ,[LastUpdateUserID]
           ,[SupplierPackageID])
		select 11
			,t.[ProductId]
			,t.[ChainID]
			,s.storeid
			,0
			,t.Supplierid
			,t.Cost
			,t.SuggestedRetail
			,t.StartDateTime
			,t.EndDateTime
			,0
			,t.[SupplierPackageID]
			from #tempPackCosts t
			inner join stores s
			on t.chainid = s.chainid
						
						
						
						
						
						*/
						--insert default ChainProductFactors record for new product
						--select * from ChainProductFactors where productid = 0

										   
								update MaintenanceRequests set Productid = @productid, upc = @upc12, upc12 = @upc12, dtproductdescription = @itemdescription
								where MaintenanceRequestID = @maintenancerequestid	
																	   
							end
					
					end
					--*/
			
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
								from [DataTrue_Main].[dbo].[ProductIdentifiers]
								where IdentifierValue = @VIN
								and ProductIdentifierTypeID = 3
								and OwnerEntityId = @chainid
								
								If @count < 1 and @requesttypeid = 1
									begin						           
										INSERT INTO [dbo].[ProductIdentifiers]
										   ([ProductID]
										   ,[ProductIdentifierTypeID]
										   ,[OwnerEntityId]
										   ,[IdentifierValue]
										   ,[LastUpdateUserID])
										VALUES
										   (@productid
										   ,3 --UPC is type 2
										   ,@chainid -- 0 is default entity
										   ,@VIN
										   ,0)
									end

								set @count = 0
								
								select @count= count(*)
								from [DataTrue_Main].[dbo].[SupplierPackages]
								where ltrim(rtrim(VIN)) = @VIN
								and OwnerPackageIdentifier = @PurchPackDescription
								and OwnerEntityId = @chainid
								
								If @count < 1 and @requesttypeid = 1
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
									end							  
								   
						         If @brandname is not null
									begin
									
										set @brandid = null
										
										select @brandid = brandid
										from Brands
										where LTRIM(rtrim(BrandName)) = @BrandName
										
									end  
						           
						        set @count = 0
								
								select @count= count(*)
								from [DataTrue_Main].[dbo].[ProductBrandAssignments]
								where BrandID = @brandid
								and ProductId = @productid
								and CustomOwnerEntityID = @chainid
								
								If @count < 1 and @requesttypeid = 1
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
		fetch next from @rec2 into @maintenancerequestid, @upc12, @itemdescription, @chainid, @approved, 
			@requesttypeid, @brandname, @supplierid, @requestsource, @SizeDescription,@SellPkgVINAllowReorder, 
			@SellPkgVINAllowReclaim,@PrimarySellablePkgIdentifier,@VIN,@VINDescription,
			@PurchPackDescription,@PurchPackQty,@AltSellPackage1,@AltSellPackage1Qty,
			@AltSellPackage1UPC,@AltSellPackage1Retail
	end
	
close @rec2
deallocate @rec2

return
GO
