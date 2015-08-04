USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_Product_Manage_fab2014]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_Product_Manage_fab2014]
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
declare @spcnt int


set @rec2 = CURSOR local fast_forward FOR
	select maintenancerequestid, LTRIM(rtrim(upc))upc,LEN(LTRIM(rtrim(rawproductidentifier)))rawprod, LTRIM(rtrim(ItemDescription)) , Chainid, approved--, productid
	,RequestTypeID, ltrim(rtrim(BrandIdentifier)), SupplierID, requestsource
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

   	/* where  RequestStatus in (0, 1, 2, -90, -30, -333, -31, 5, 17, 999)
	and ProductId is null
	and (len(upc) < 1 or upc is null)
	and LEN(LTRIM(rtrim(rawproductidentifier))) = 12
	and ISNULL(PDIParticipant, 0) <> 1	

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
fetch next from @rec2 into @maintenancerequestid, @upc12,@rawprod, @itemdescription, @chainid, @approved, @requesttypeid, @brandname, @supplierid, @requestsource
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
			end
			else
			begin
			set	@ProdIdTypeID=2
			end		
			select @productid = productid from ProductIdentifiers 
			where LTRIM(rtrim(identifiervalue)) = @upc12
			and ProductIdentifierTypeID =@ProdIdTypeID		
			
			if @@ROWCOUNT > 0
				begin
					set @productfound = 1
					select @productdescription = description from Products where ProductID = @productid
				end			
			
				begin				
				set @upc11 = RIGHT(@upc12, 11)				
				set @CheckDigit = ''
				exec [dbo].[prUtil_UPC_GetCheckDigit]
					 @upc11,
					 @CheckDigit OUT						 
				set @upc12 = @upc11 + @CheckDigit					
				select @productid = productid from ProductIdentifiers 
				where LTRIM(rtrim(identifiervalue)) = @upc12
				and ProductIdentifierTypeID = @ProdIdTypeID
				
					
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
			 if @noupc=1
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
													
													update MaintenanceRequests set upc = @upc12, upc12 = @upc12
													where MaintenanceRequestID = @maintenancerequestid
													
												end
										end
		     end
			
			else
				if @approved = 1
					begin
					if @addnewproduct = 1 and @requesttypeid in (1)
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
							end
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
