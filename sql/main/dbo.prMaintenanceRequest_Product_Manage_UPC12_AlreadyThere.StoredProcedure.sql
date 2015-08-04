USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_Product_Manage_UPC12_AlreadyThere]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_Product_Manage_UPC12_AlreadyThere]
as

declare @rec cursor
declare @upc nvarchar(50)
declare @productid int
declare @brandid int
declare @mrupc nvarchar(50)
declare @checkdigit char(1)
declare @lenofupc tinyint
declare @maintenancerequestid int
declare @addnewproduct smallint=1
declare @itemdescription nvarchar(255)
declare @upc12 nvarchar(50)
declare @chainid int
/*
select top 100 * from dbo.MaintenanceRequests where supplierid = 40567


	select * --maintenancerequestid, LTRIM(rtrim(upc)), LTRIM(rtrim(ItemDescription)) , Chainid
	--update r set upc12 = upc
	from dbo.MaintenanceRequests r
	where 1 = 1
	and RequestStatus = 0
	and ProductId is null
	--and MaintenanceRequestID = 12
	--and SupplierID = 40558
	and LEN(upc) = 12
	--and LEN(upc) <> 11
	and upc12 is null
	
	select * --maintenancerequestid, LTRIM(rtrim(upc)), LTRIM(rtrim(ItemDescription)) , Chainid
	--update r set approved = 1, approvaldatetime = getdate()
	from dbo.MaintenanceRequests r
	where 1 = 1
	and RequestStatus = 0
	and ProductId is null
	--and MaintenanceRequestID = 12
	and SupplierID = 40558
	and approved is null
	and LEN(upc) <> 12
	and LEN(upc) <> 11	
	
*/

set @rec = CURSOR local fast_forward FOR
	select maintenancerequestid, LTRIM(rtrim(upc12)), LTRIM(rtrim(ItemDescription)) , Chainid
	from dbo.MaintenanceRequests
	where 1 = 1
	and RequestStatus = 0
	--and SupplierID = 40558
	and ProductId is null
	and Approved = 1
	and MaintenanceRequestID = 44556
	--and LEN(upc) = 12
	and upc12 is not null
	
open @rec

fetch next from @rec into @maintenancerequestid, @upc12, @itemdescription, @chainid

while @@FETCH_STATUS = 0
	begin
	
/*	
				set @CheckDigit = ''
				exec [dbo].[prUtil_UPC_GetCheckDigit]
					 @mrupc,
					 @CheckDigit OUT	
					 
				set @upc12 = @mrupc + @CheckDigit
*/	
--********************************************************************************
			select @productid = productid from ProductIdentifiers 
			where LTRIM(rtrim(identifiervalue)) = @upc12
--/*			
			if @@ROWCOUNT < 1
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
						   
			end
			--*/
		  
		update MaintenanceRequests set Productid = @productid --, upc12 = @upc12
		where MaintenanceRequestID = @maintenancerequestid
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
			
		fetch next from @rec into @maintenancerequestid, @upc12, @itemdescription, @chainid
	end
	
close @rec
deallocate @rec
	
	






return
GO
