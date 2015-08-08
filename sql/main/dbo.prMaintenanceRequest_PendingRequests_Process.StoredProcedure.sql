USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_PendingRequests_Process]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Batch submitted through debugger: SQLQuery28.sql|7|0|C:\Users\timothy.powell\AppData\Local\Temp\10\~vsC2B0.sql
CREATE procedure [dbo].[prMaintenanceRequest_PendingRequests_Process]
as

/*
RequestTypeID 1=New Item 2 =Cost Change 3 = Promo
RequestStatus 0 = new -2 = invalid setup -1 = approvaldenied 1 = approved 9 = processed

Anja.K.Bochenski@supervalu.com
*/

declare @rec cursor
declare @maintenancerequestid int
declare @datetimesubmitted datetime
declare @requesttypeid smallint
declare @chainid int
declare @supplierid int
declare @banner nvarchar(50)
declare @allstores bit
declare @upc nvarchar(50)
declare @brandidentifier nvarchar(50)
declare @itemdescription nvarchar(500)
declare @currentsetupcost money
declare @requestedcost money
declare @suggestedretail money
declare @promotypeid tinyint --OI BB CC 1=OFF INVOICE 2=BUY BACK 3=CC
declare @promoallowance money
declare @startdatetime datetime
declare @enddatetime datetime
declare @supplierloginid int --really the supplier person entityid
declare @chainloginid int --really the chain person entityid
declare @approvaldatetime datetime
declare @denialreason nvarchar(255)
declare @emailsubject nvarchar(100)
declare @emailbody nvarchar(2000)
declare @supplieremail nvarchar(100)
declare @dummyplaceholder int
declare @datatrueproductid int
declare @datatruebrandid int
declare @datatruepricetypeid int
declare @MyID int = 0
declare @brandid int
declare @invaliddatafound bit
declare @productpricetypeid int
declare @newproductid int
declare @existingproductid int


select cast(0 as int) as storeid into #storestoupdate

truncate table #storestoupdate

--process denials
set @rec = CURSOR local fast_forward FOR
SELECT [MaintenanceRequestID]
      ,[SubmitDateTime]
      ,[RequestTypeID]
      ,[ChainID]
      ,[SupplierID]
      ,[Banner]
      ,[AllStores]
      ,[UPC]
      ,[BrandIdentifier]
      ,[ItemDescription]
      ,[Cost]
      ,[SuggestedRetail]
      ,[PromoTypeID]
      ,[PromoAllowance]
      ,[StartDateTime]
      ,[EndDateTime]
      ,[SupplierLoginID]
      ,[ChainLoginID]
      ,[ApprovalDateTime]
      ,[DenialReason]
  FROM [DataTrue_Main].[dbo].[MaintenanceRequests]
  where RequestStatus = -1 --0 = new -2 = invalid setup -1 = approval denied 1 = approved -9 = processed denied 9 = processed approved
  --and [RequestTypeID] = 3 --1=New Item 2 =Cost Change 3 = Promo
  order by MaintenanceRequestID
  
open @rec

fetch next from @rec into
	@maintenancerequestid
	,@datetimesubmitted
	,@requesttypeid
	,@chainid
	,@supplierid
	,@banner
	,@allstores
	,@upc
	,@brandidentifier
	,@itemdescription
	,@requestedcost
	,@suggestedretail
	,@promotypeid
	,@promoallowance
	,@startdatetime
	,@enddatetime
	,@supplierloginid
	,@chainloginid
	,@approvaldatetime
	,@denialreason
	
while @@fetch_status = 0
	begin
	
print @denialreason

		select @supplieremail = Login from Logins where OwnerEntityId = @supplierloginid
--temp hardcode wait
set @supplieremail = 'charlie.clark@icontroldsd.com'
		
print @supplieremail
	
		update MaintenanceRequests set RequestStatus = -9 
		,EmailGeneratedToSupplier = @supplieremail
		,EmailGeneratedToSupplierDateTime = GETDATE()		
		where MaintenanceRequestID = @maintenancerequestid
		
		set @emailsubject = 'Request Denied'
		
		set @emailbody = 'Your ' + case when @requesttypeid = 1 then 'new item request '
									when @requesttypeid = 2 then 'cost change request '
									when @requesttypeid = 3 then 'promo cost request '
								else 'request '
								end
							+ 'submitted ' + CAST(@datetimesubmitted as nvarchar)
							+ ' for UPC ' + @upc
							+ ' with description ' + @itemdescription
							+ ' has been denied.  Reason: ' + @denialreason
							
		exec [prSendEmailNotification_PassEmailAddresses]
			@emailsubject
			,@emailbody
			,''
			,0
			,@supplieremail
							
		
		fetch next from @rec into
			@maintenancerequestid
			,@datetimesubmitted
			,@requesttypeid
			,@chainid
			,@supplierid
			,@banner
			,@allstores
			,@upc
			,@itemdescription
			,@requestedcost
			,@suggestedretail
			,@promotypeid
			,@promoallowance
			,@startdatetime
			,@enddatetime
			,@supplierloginid
			,@chainloginid
			,@approvaldatetime
			,@denialreason	
	end
	
close @rec
deallocate @rec
	

--process approvals
set @rec = CURSOR local fast_forward FOR
SELECT [MaintenanceRequestID]
      ,[SubmitDateTime]
      ,[RequestTypeID]
      ,[ChainID]
      ,[SupplierID]
      ,[Banner]
      ,[AllStores]
      ,[UPC]
      ,[BrandIdentifier]
      ,[ItemDescription]
      ,[Cost]
      ,[SuggestedRetail]
      ,[PromoTypeID]
      ,[PromoAllowance]
      ,[StartDateTime]
      ,[EndDateTime]
      ,[SupplierLoginID]
      ,[ChainLoginID]
      ,[ApprovalDateTime]
      ,[DenialReason]
  FROM [DataTrue_Main].[dbo].[MaintenanceRequests]
  where RequestStatus = 1 --0 = new -2 = invalid setup -1 = approval denied 1 = approved -9 = processed denied 9 = processed approved
  --and [RequestTypeID] = 3 --1=New Item 2 =Cost Change 3 = Promo
  order by MaintenanceRequestID
  
open @rec

fetch next from @rec into
	@maintenancerequestid
	,@datetimesubmitted
	,@requesttypeid
	,@chainid
	,@supplierid
	,@banner
	,@allstores
	,@upc
	,@brandidentifier
	,@itemdescription
	,@requestedcost
	,@suggestedretail
	,@promotypeid
	,@promoallowance
	,@startdatetime
	,@enddatetime
	,@supplierloginid
	,@chainloginid
	,@approvaldatetime
	,@denialreason
	
while @@fetch_status = 0
	begin
	
	select @datatrueproductid = ProductId from ProductIdentifiers
	where IdentifierValue = @upc
	and ProductIdentifierTypeID = 2 --2 = upc

		select @supplieremail = Login from Logins where OwnerEntityId = @supplierloginid
--temp hardcode wait
set @supplieremail = 'charlie.clark@icontroldsd.com'
	
if @@ROWCOUNT > 0 --@datatrueproductid
	begin
	
		truncate table #storestoupdate
		
		if @brandidentifier is null
			begin
				set @datatruebrandid = 0
			end
		else
			begin
						if LEN(ltrim(rtrim(@brandidentifier))) > 0
							begin
								select @brandid = BrandID, @datatruebrandid = BrandID
								from Brands
								where ltrim(rtrim(BrandName)) = ltrim(rtrim(@brandidentifier))

								if @@ROWCOUNT < 1
									begin
										set @invaliddatafound = 1 --provided brandidentifier not found
									end
							end
						else
							begin
								set @brandid = 0
								set @datatruebrandid = 0
							end

			end


				if @requesttypeid = 1 --New Item
					begin
--************************New Item*************************************

								select ProductID from .ProductIdentifiers
								where ltrim(rtrim(IdentifierValue)) = ltrim(rtrim(@upc))
								and ProductIdentifierTypeID = 2 --Unique Identifier
								
								if @@ROWCOUNT > 0
									begin
										set @invaliddatafound = 1 --productidentifier already in use
									end
								else
									begin
										INSERT INTO [dbo].[Products]
												   ([ProductName]
												   ,[Description]
												   ,[ActiveStartDate]
												   ,[ActiveLastDate]
												   ,[LastUpdateUserID]
												   ,[DateTimeLastUpdate])
											 VALUES
												   (@upc
												   ,@itemdescription
												   ,@startdatetime
												   ,@enddatetime
												   ,@MyID
												   ,GETDATE())

										set @newproductid = SCOPE_IDENTITY()
										
										INSERT INTO [dbo].[ProductIdentifiers]
												([ProductID]
												,[ProductIdentifierTypeID]
												,[OwnerEntityId]
												,[IdentifierValue]
												,[LastUpdateUserID])
										 VALUES
											   (@newproductid
											   ,2
											   ,0
											   ,@upc
											   ,@MyID)	

										

										INSERT INTO [dbo].[ProductBrandAssignments]
												   ([BrandID]
												   ,[ProductID]
												   ,[CustomOwnerEntityID]
												   ,[LastUpdateUserID]
												   ,[DateTimeLastUpdate])
											 VALUES
												   (@brandid
												   ,@newproductid
												   ,0
												   ,@MyID
												   ,GETDATE())		
											--end
									-- here now				
											--end
/*											
										if @loadstatus = 1 and LEN(@categoryidentifier) > 0
											begin
												select @categoryid = ProductCategoryID
												from [dbo].ProductCategories
												where ProductCategoryName = @categoryidentifier
												if @@ROWCOUNT < 1
													begin
														set @loadstatus = -2 --provided categoryidentifier not found
													end
												else
													begin
													
														INSERT INTO [dbo].[ProductCategoryAssignments]
																   ([ProductCategoryID]
																   ,[ProductID]
																   ,[CustomOwnerEntityID]
																   ,[LastUpdateUserID]
																   ,[DateTimeLastUpdate])
															 VALUES
																   (@categoryid
																   ,@newproductid
																   ,0
																   ,@MyID
																   ,GETDATE())		
													end						
											end
										else
											begin
												set @categoryid = 0
											end
*/
									end
						end

		
		if @allstores = 1
			begin
				insert #storestoupdate 
				select storeid from storesetup 
				where SupplierID =  @supplierid
				and ActiveLastDate > @startdatetime
				and ActiveStartDate < @enddatetime  
			end
		else
			begin
				insert #storestoupdate 
				select storeid from MaintenanceRequestStores
				where MaintenanceRequestID = @maintenancerequestid
			end
			
		declare @recsetup cursor
		declare @sustoreid int
		declare @suproductid int
		declare @subrandid int
		
		set @recsetup = CURSOR local fast_forward FOR
			select ss.storeid, ProductId, brandid
			from storesetup ss
			inner join #storestoupdate su
			on ss.StoreID = su.storeid
			where SupplierID = @supplierid
			and ProductID = @suproductid
			and BrandID = @subrandid
			
		open @recsetup
		
		fetch next from @recsetup into
			@sustoreid
			,@suproductid
			,@subrandid
						
		while @@FETCH_STATUS = 0
			begin				
				if @requesttypeid = 1 --New Item
					begin
--************************New Item*************************************
									
								select @existingproductid = ProductID 
								from ProductIdentifiers
								where IdentifierValue = @upc
								and ProductIdentifierTypeID = 2 --Unique Identifier
								
								if @@ROWCOUNT < 1
									begin
										set @invaliddatafound = 1
									end
								else
									begin
										select @productpricetypeid = ProductPriceTypeID 
										from dbo.ProductPriceTypes
										where ProductPriceTypeName = 'CHAINPRICE'
										
										exec dbo.prProductPrice_Manage 
											0,
											@sustoreid,
											@existingproductid, 
											@subrandid, 
											@supplierid,
											@productpricetypeid, 
											@requestedcost, 
											@startdatetime, 
											@enddatetime,
											@suggestedretail,
											@MyID
									end

								select @existingproductid = ProductID 
								from .ProductIdentifiers
								where IdentifierValue = @upc
								and ProductIdentifierTypeID = 2 --Unique Identifier
							
								if @@ROWCOUNT < 1
									begin
										set @invaliddatafound = 1
									end
								else
									begin
										select @productpricetypeid = ProductPriceTypeID 
										from dbo.ProductPriceTypes
										where ProductPriceTypeName = 'SUPPLIERCOST'
										
									
										exec dbo.prProductCost_Manage
											0--@chainid
											,@sustoreid
											,@existingproductid
											,@brandid
											,@supplierid
											,@productpricetypeid
											,@requestedcost
											,@startdatetime
											,@enddatetime
											,@MyID
											,@suggestedretail
									end						

			
					end
					
				if @requesttypeid = 2 --Cost Change
					begin
						exec prProductCost_Manage
							0
							,@sustoreid
							,@suproductid
							,@subrandid
							,@supplierid
							,3
							,@promoallowance
							,@startdatetime
							,@enddatetime
							,@MyID
							,0
							
						exec prProductCost_Manage
							0
							,@sustoreid
							,@suproductid
							,@subrandid
							,@supplierid
							,5
							,@promoallowance
							,@startdatetime
							,@enddatetime
							,@MyID
							,0
							
						
						
					end
					
				if @requesttypeid = 3 --PromoAllowance
					begin
						set @datatruepricetypeid = 
						case when @promotypeid = 1 then 8
							when @promotypeid = 2 then 9
							when @promotypeid = 3 then 10
							else 8
						end
						
					exec prProductCost_Manage
						0
						,@sustoreid
						,@suproductid
						,@subrandid
						,@supplierid
						,@datatruepricetypeid
						,@promoallowance
						,@startdatetime
						,@enddatetime
						,@MyID
						,0
								
					end					
			end
			
			close @recsetup
			deallocate @recsetup
			
		update MaintenanceRequests set RequestStatus = 9 
		,EmailGeneratedToSupplier = @supplieremail
		,EmailGeneratedToSupplierDateTime = GETDATE()		
		where MaintenanceRequestID = @maintenancerequestid
		
		set @emailsubject = 'Request Approved'
		
		set @emailbody = 'Your ' + case when @requesttypeid = 1 then 'new item request '
									when @requesttypeid = 2 then 'cost change request '
									when @requesttypeid = 3 then 'promo cost request '
								else 'request '
								end
							+ 'submitted ' + CAST(@datetimesubmitted as nvarchar)
							+ ' for UPC ' + @upc
							+ ' with description ' + @itemdescription
							+ ' has been approved.'
	end --@datatrueproductid
else --product invalid
	begin
		set @emailsubject = 'Invalid Request Information'
		
		set @emailbody = 'Your ' + case when @requesttypeid = 1 then 'new item request '
									when @requesttypeid = 2 then 'cost change request '
									when @requesttypeid = 3 then 'promo cost request '
								else 'request '
								end
							+ 'submitted ' + CAST(@datetimesubmitted as nvarchar)
							+ ' for UPC ' + @upc
							+ ' with description ' + @itemdescription
							+ ' can not be processed because some information provide is invalid.  Please review and correct your request and re-submit.'	
	end
									
		exec [prSendEmailNotification_PassEmailAddresses]
			@emailsubject
			,@emailbody
			,''
			,0
			,@supplieremail
							
		
		fetch next from @rec into
			@maintenancerequestid
			,@datetimesubmitted
			,@requesttypeid
			,@chainid
			,@supplierid
			,@banner
			,@allstores
			,@upc
			,@brandidentifier
			,@itemdescription
			,@requestedcost
			,@suggestedretail
			,@promotypeid
			,@promoallowance
			,@startdatetime
			,@enddatetime
			,@supplierloginid
			,@chainloginid
			,@approvaldatetime
			,@denialreason	
	end
	
close @rec
deallocate @rec


return
GO
