USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Load_Products]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Load_Products]
as
/*
ADD, DEFAULTPRICE, CHAINPRICE, DEFAULTCOST, SUPPLIERCOST
*/
declare @MyID int
set @MyID = 7602


declare @rec cursor
declare @chainidentifier nvarchar(50)
declare @storeidentifier nvarchar(50)
declare @productidentifier nvarchar(50)
declare @brandidentifier nvarchar(50)
declare @supplieridentifier nvarchar(50)
declare @categoryidentifier nvarchar(50)
declare @productdescription nvarchar(500)
declare @startdate datetime
declare @enddate datetime
declare @existingproductid int
declare @newproductid int
declare @chainid int
declare @storeid int
declare @brandid int
declare @supplierid int
declare @categoryid int
declare @loadstatus int
declare @loadtype nvarchar(50)
declare @productpricetypeid int
declare @productprice money
declare @productcost money
declare @productretail money
declare @recordid int
declare @bipad nvarchar(50)


set @loadstatus = 1

set @rec = CURSOR local fast_forward FOR
SELECT isnull(ltrim(rtrim([ChainIdentifier])), '')
	  ,isnull(ltrim(rtrim([StoreIdentifier])), '')
      ,isnull(ltrim(rtrim([ProductIdentifier])), '')
      ,isnull(ltrim(rtrim([ProductBrandIdentifier])), '')
      ,isnull(ltrim(rtrim([ProductCategoryIdentifier])), '')
      ,isnull(ltrim(rtrim([ProductDescription])), '')
      ,isnull([ProductPrice],0.00)
      ,isnull(ltrim(rtrim([SupplierIdentifier])),'')
      ,isnull([ProductCost],0.00)
      ,[ActiveStartDate]
      ,[ActiveLastDate]
      ,[LoadType]
      ,isnull([ProductRetailPrice],0.00)
      ,RecordID
      ,ltrim(rtrim([Bipad]))
  FROM [DataTrue_EDI].[dbo].[Load_Products]
  where LoadStatus = 0

open @rec

fetch next from @rec into 
@chainidentifier
,@storeidentifier
,@productidentifier
,@brandidentifier
,@categoryidentifier
,@productdescription
,@productprice
,@supplieridentifier
,@productcost
,@startdate
,@enddate
,@loadtype
,@productretail
,@recordid
,@bipad

while @@FETCH_STATUS = 0
	begin --1	
	
		begin try
		
		begin transaction
		
		set @loadstatus = 1
		
		if LEN(@brandidentifier) > 0
			begin
				select @brandid = BrandID
				from Brands
				where ltrim(rtrim(BrandName)) = @brandidentifier

				if @@ROWCOUNT < 1
					begin
						set @loadstatus = -2 --provided brandidentifier not found
					end
			end
		else
			begin
				set @brandid = 0
			end
print @loadstatus
--if @loadstatus = 1
--	begin --2
		if @loadstatus = 1 and upper(@loadtype) = 'ADD'
			begin
				select ProductID from .ProductIdentifiers
				where ltrim(rtrim(IdentifierValue)) = @productidentifier
				and ProductIdentifierTypeID = 8 --Unique Identifier
				
				if @@ROWCOUNT > 0
					begin
						set @loadstatus = -1 --productidentifier already in use
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
								   (@productdescription
								   ,@productdescription
								   ,@startdate
								   ,@enddate
								   ,@MyID
								   ,GETDATE())

						set @newproductid = SCOPE_IDENTITY()
						
						INSERT INTO [dbo].[ProductIdentifiers]
								([ProductID]
								,[ProductIdentifierTypeID]
								,[OwnerEntityId]
								,[IdentifierValue]
							    ,[LastUpdateUserID]
							    ,[Bipad])
						 VALUES
							   (@newproductid
							   ,case when @bipad is null then 2 else 8 end
							   ,0
							   ,@productidentifier
							   ,@MyID
							   ,@bipad)	

						if @bipad is not null
							begin
							
								--select * from DataTrue_EDI..nwsp_upcs
								INSERT INTO [dbo].[ProductIdentifiers]
									([ProductID]
									,[ProductIdentifierTypeID]
									,[OwnerEntityId]
									,[IdentifierValue]
									,[LastUpdateUserID]
									,[BIPAD])
								select distinct @newproductid
								   ,8
								   ,0
								   ,ltrim(rtrim(UPC))
								   ,@MyID
								   ,@bipad
								from DataTrue_EDI..nwsp_upcs
								where BIPAD = @bipad
								and ltrim(rtrim(UPC)) <> @productidentifier
								
							
							end

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
							
						if @loadstatus = 1 and LEN(@categoryidentifier) > 0
							begin
								select @categoryid = ProductCategoryID
								from [dbo].ProductCategories
								where ltrim(rtrim(ProductCategoryName)) = @categoryidentifier
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

					end
/*					
				select @existingproductid = ProductID 
				from ProductIdentifiers
				where ltrim(rtrim(IdentifierValue)) = @productidentifier
				and ProductIdentifierTypeID = 2 --Unique Identifier
				
				if @@ROWCOUNT < 1
					begin
						set @loadstatus = -2
					end
				else
					begin
						select @productpricetypeid = ProductPriceTypeID 
						from dbo.ProductPriceTypes
						where ltrim(rtrim(ProductPriceTypeName)) = 'DEFAULTPRICE'
						
						exec dbo.prProductPrice_Manage 
							0,
							@storeid,
							@existingproductid, 
							@brandid, 
							@supplierid,
							@productpricetypeid, 
							@productprice, 
							@startdate, 
							@enddate,
							@productretail,
							@MyID
					end

				select @existingproductid = ProductID 
				from ProductIdentifiers
				where ltrim(rtrim(IdentifierValue)) = @productidentifier
				and ProductIdentifierTypeID = 2 --Unique Identifier
			
				if @@ROWCOUNT < 1
					begin
						set @loadstatus = -2
					end
				else
					begin
						select @productpricetypeid = ProductPriceTypeID 
						from dbo.ProductPriceTypes
						where ltrim(rtrim(ProductPriceTypeName)) = 'DEFAULTCOST'
						
					
						exec dbo.prProductCost_Manage
							0--@chainid
							,0--@storeid
							,@existingproductid
							,@brandid
							,0 --@supplierid
							,@productpricetypeid
							,@productcost
							,@startdate
							,@enddate
							,@MyID
							,@productretail
					end	
*/					
			end --If ADD
			
		if @loadstatus = 1 and upper(@loadtype) = 'DEFAULTPRICE'
			begin
				select @existingproductid = ProductID 
				from ProductIdentifiers
				where ltrim(rtrim(IdentifierValue)) = @productidentifier
				and ProductIdentifierTypeID = 2 --Unique Identifier
				
				if @@ROWCOUNT < 1
					begin
						set @loadstatus = -2
					end
				else
					begin
						select @productpricetypeid = ProductPriceTypeID 
						from dbo.ProductPriceTypes
						where ltrim(rtrim(ProductPriceTypeName)) = 'DEFAULTPRICE'
						
						exec dbo.prProductPrice_Manage 
							0,
							@storeid,
							@existingproductid, 
							@brandid, 
							@supplierid,
							@productpricetypeid, 
							@productprice, 
							@startdate, 
							@enddate,
							@productretail,
							@MyID
					end

			end	
					
		if @loadstatus = 1 and upper(@loadtype) = 'CHAINPRICE'
			begin
				select @existingproductid = ProductID 
				from ProductIdentifiers
				where ltrim(rtrim(IdentifierValue)) = @productidentifier
				and ProductIdentifierTypeID = 2 --Unique Identifier
			
				if @@ROWCOUNT < 1
					begin
						set @loadstatus = -2
					end
				else
					begin
						select @productpricetypeid = ProductPriceTypeID 
						from dbo.ProductPriceTypes
						where ltrim(rtrim(ProductPriceTypeName)) = 'CHAINPRICE'
					
						exec dbo.prProductPrice_Manage 
							@chainid,
							@storeid,
							@existingproductid, 
							@brandid, 
							@supplierid,
							@productpricetypeid, 
							@productprice, 
							@startdate, 
							@enddate,
							@productretail,
							@MyID
					end
			end
						
		if @loadstatus = 1 and upper(@loadtype) = 'DEFAULTCOST'
			begin
				select @existingproductid = ProductID 
				from ProductIdentifiers
				where ltrim(rtrim(IdentifierValue)) = @productidentifier
				and ProductIdentifierTypeID = 2 --Unique Identifier
			
				if @@ROWCOUNT < 1
					begin
						set @loadstatus = -2
					end
				else
					begin
						select @productpricetypeid = ProductPriceTypeID 
						from dbo.ProductPriceTypes
						where ltrim(rtrim(ProductPriceTypeName)) = 'DEFAULTCOST'
						
					
						exec dbo.prProductCost_Manage
							0--@chainid
							,0--@storeid
							,@existingproductid
							,@brandid
							,0 --@supplierid
							,@productpricetypeid
							,@productcost
							,@startdate
							,@enddate
							,@MyID
							,@productretail
					end			
			end	
					
		if @loadstatus = 1 and upper(@loadtype) = 'SUPPLIERCOST'
			begin
				select @existingproductid = ProductID from .ProductIdentifiers
				where ltrim(rtrim(IdentifierValue)) = @productidentifier
				and ProductIdentifierTypeID = 2 --Unique Identifier
				
				select @supplierid = SupplierID 
				from Suppliers 
				where ltrim(rtrim(SupplierName)) = @supplieridentifier

			
			
				if @@ROWCOUNT < 1
					begin
						set @loadstatus = -2
					end
				else
					begin
						select @productpricetypeid = ProductPriceTypeID 
						from dbo.ProductPriceTypes
						where ltrim(rtrim(ProductPriceTypeName)) = 'SUPPLIERCOST'
					
						exec dbo.prProductCost_Manage
							0--@chainid
							,0--@storeid
							,@existingproductid
							,@brandid
							,@supplierid
							,@productpricetypeid
							,@productcost
							,@startdate
							,@enddate
							,@MyID
							,@productretail
							/*
							@chainid int=0
,@storeid int=0
,@productid int=0
,@brandid int=0
,@supplierid int=0
,@productpricetypeid int=0
,@productcost money=0.00
,@coststartdate datetime='1/1/2000'
,@costenddate datetime='12/31/2100'
,@userid int
							*/
					end
			end
	COMMIT TRANSACTION

end try
	
begin catch
		rollback transaction
		
		set @loadstatus = -3
		
		declare @errormessage varchar(4500)
		declare @errorlocation varchar(255)

		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		
		exec dbo.prSendEmailNotification
		@errorlocation,
		@errormessage,
		@errorlocation,
		@MyID
		
end catch
			
		UPDATE [DataTrue_EDI].[dbo].[Load_Products]
		   SET [LoadStatus] = @loadstatus
		 WHERE RecordID = @recordid
		 and LoadStatus = 0
	
		fetch next from @rec into 
			@chainidentifier
			,@storeidentifier
			,@productidentifier
			,@brandidentifier
			,@categoryidentifier
			,@productdescription
			,@productprice
			,@supplieridentifier
			,@productcost
			,@startdate
			,@enddate
			,@loadtype
			,@productretail
			,@recordid
			,@bipad
		
	end --1
	
close @rec
deallocate @rec

return
GO
