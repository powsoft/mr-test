USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_Product_Manage_Manual]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_Product_Manage_Manual]
as

declare @rec cursor
declare @rec2 cursor
declare @rec3 cursor
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
/*
select top 100 * from dbo.MaintenanceRequests where supplierid = 40567
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
	and RequestStatus in (0, 7, 8)
	and ProductId is null
	and SupplierID = 4111191991
	--and MaintenanceRequestID in ()
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
			if @@ROWCOUNT < 1 and @addnewproduct = 1
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
	and requesttypeid = 1
	--and MaintenanceRequestID in (8563,8560)
	and SupplierID = 404111191991
	and LEN(LTRIM(rtrim(upc))) = 11
	and Approved = 1
	
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
			if @@ROWCOUNT < 1 and @addnewproduct = 1
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
	
	


set @rec2 = CURSOR local fast_forward FOR
	select maintenancerequestid, LTRIM(rtrim(upc)), LTRIM(rtrim(ItemDescription)) , Chainid, approved--, productid
	--select approved, *
	--into import.dbo.tmpMaintenanceRequestRecordsThatGotWrongProductIDs_20111231
	from dbo.MaintenanceRequests
	where 1 = 1
	--and RequestStatus in (0, 1)
	--and RequestStatus = -90
	and ProductId is null
	and requesttypeid in (1,2,3)
	and (Approved = 1 or Approved is null)
	--and Approved = 1
	and LEN(LTRIM(rtrim(upc))) = 12
			and maintenancerequestid in (177967)

	
	
open @rec2

fetch next from @rec2 into @maintenancerequestid, @upc12, @itemdescription, @chainid, @approved

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
			end
		--/*
		  else
			begin
				if @approved = 1
					begin
							if @addnewproduct = 1
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
										   
								update MaintenanceRequests set Productid = @productid, upc12 = @upc12, dtproductdescription = @productdescription
								where MaintenanceRequestID = @maintenancerequestid	
																	   
							end
					
					end
					--*/
			
			end
		
			
		fetch next from @rec2 into @maintenancerequestid, @upc12, @itemdescription, @chainid, @approved
	end
	
close @rec2
deallocate @rec2




return
GO
