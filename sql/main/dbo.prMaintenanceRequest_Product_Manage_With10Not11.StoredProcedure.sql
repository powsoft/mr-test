USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_Product_Manage_With10Not11]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_Product_Manage_With10Not11]
as

declare @rec cursor
declare @rec2 cursor
declare @rec3 cursor
declare @upc nvarchar(50)
declare @productid int
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
declare @addnewproduct bit=0
declare @productfound bit
declare @approved bit
/*
select top 100 * from dbo.MaintenanceRequests where supplierid = 40567
select * from productidentifiers where productid = 16396 --16640 024126008221
*/

set @rec = CURSOR local fast_forward FOR
	select maintenancerequestid, LTRIM(rtrim(upc)), LTRIM(rtrim(ItemDescription)) , Chainid--, productid
	from dbo.MaintenanceRequests
	where 1 = 1
	and RequestStatus = 0
	and ProductId is null
	--and MaintenanceRequestID = 1247
	--and SupplierID = 40567
	and LEN(upc) = 10
	
open @rec

fetch next from @rec into @maintenancerequestid, @mrupc, @itemdescription, @chainid

while @@FETCH_STATUS = 0
	begin
	
				set @productfound = 0
				

				set @upc12 = '0' + @mrupc

--********************************************************************************
			select @productid = productid from ProductIdentifiers 
			where LTRIM(rtrim(identifiervalue)) = @upc12
			
			if @@ROWCOUNT > 0
				begin
					set @productfound = 1
				end
				
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
					
					if @@ROWCOUNT > 0
						begin
							set @productfound = 1
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
				update MaintenanceRequests set Productid = @productid, upc12 = @upc12
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
	--into import.dbo.tmpMaintenanceRequestRecordsThatGotWrongProductIDs_20111231
	from dbo.MaintenanceRequests
	where 1 = 1
	and RequestStatus = 0
	and ProductId is null
		--and MaintenanceRequestID = 1247
	and LEN(upc) = 12
	
open @rec2

fetch next from @rec2 into @maintenancerequestid, @upc12, @itemdescription, @chainid, @approved

while @@FETCH_STATUS = 0
	begin
	
			set @productfound = 0
			
			select @productid = productid from ProductIdentifiers 
			where LTRIM(rtrim(identifiervalue)) = @upc12
			
			if @@ROWCOUNT > 0
				begin
					set @productfound = 1
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
				
				if @@ROWCOUNT > 0
					begin
						set @productfound = 1
					end			
				
				end
				
		  if @productfound = 1
			begin
				update MaintenanceRequests set Productid = @productid, upc12 = @upc12
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
										   
								update MaintenanceRequests set Productid = @productid, upc12 = @upc12
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
