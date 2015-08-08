USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_Manufacturer_Manage]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_Manufacturer_Manage]
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
declare @manufactureridentifier nvarchar(100)
declare @manufacturerid int
declare @requesttypeid int
declare @requestsource nvarchar(50)
/*
select top 100 * from dbo.MaintenanceRequests where supplierid = 40567
select top 100 * from dbo.MaintenanceRequests where chainid = 44285 and supplierid = 44269
select * from productidentifiers where productid = 16396 --16640 024126008221
select * 
--update mr set mr.dtproductdescription = p.description
from dbo.MaintenanceRequests mr
inner join products p
on mr.productid = p.productid
where mr.productid is not null and mr.dtproductdescription is null
select * from entitytypes
*/

set @rec2 = CURSOR local fast_forward FOR
	select maintenancerequestid, LTRIM(rtrim(upc)), LTRIM(rtrim(ItemDescription)) , Chainid, approved--, productid
	,RequestTypeID, ltrim(rtrim(BrandIdentifier)), SupplierID, requestsource, ltrim(rtrim(ManufacturerIdentifier))
	--into import.dbo.tmpMaintenanceRequestRecordsThatGotWrongProductIDs_20111231
	from dbo.MaintenanceRequests
	where 1 = 1
	--and RequestStatus in (0, 1, -90, -30, -333, -31, 5, 17)
	--and ProductId is null
	and RequestStatus not in (5, 15, 6, 16, 999)
	--and requesttypeid in (1,2)
	and ChainID = 44285
	--and SupplierID = 44269
	and (isnull(Approved, 0) = 1)
	and RequestSource is not null
	and ltrim(rtrim(ManufacturerIdentifier)) is not null
	and ltrim(rtrim(BrandIdentifier)) is not null
	--and (Approved = 1 or RequestStatus in (-25, -26, -90, -30, -333, -31))
	and LEN(LTRIM(rtrim(upc))) = 12
	--and SupplierID <> 40559
	order by requesttypeid


	
	
open @rec2

fetch next from @rec2 into @maintenancerequestid, @upc12, @itemdescription, @chainid, 
							@approved, @requesttypeid, @brandname, @supplierid, @requestsource, @manufactureridentifier

while @@FETCH_STATUS = 0
	begin
	
	
			set @manufacturerid = null
			set @productfound = 0
			--set @upc = @upc12
			
			select @manufacturerid = Manufacturerid from manufacturers
			where LTRIM(rtrim(OwnerManufacturerIdentifier)) = @manufactureridentifier
			and OwnerEntityID = @supplierid
			
			if @@ROWCOUNT < 1
				begin
				
					--select top 10 * from systementities order by entityid desc
					--select * delete from brands where brandid = 791
					INSERT INTO [dbo].[SystemEntities]
					   ([EntityTypeID]
					   ,[LastUpdateUserID])
					VALUES
					   (11 --@entitytypeid
					   ,0) --@MyID)

					set @manufacturerid = Scope_Identity()
				
					INSERT INTO [DataTrue_Main].[dbo].[Manufacturers]
						   ([ManufacturerID]
						   ,[ManufacturerName]
						   ,[ManufacturerIdentifier]
						   ,[OwnerEntityID]
						   ,[OwnerManufacturerIdentifier])
					 VALUES
						   (@manufacturerid
						   ,@manufactureridentifier
						   ,@manufactureridentifier
						   ,@supplierid
						   ,@manufactureridentifier)
						   
				end
				
				
			select @brandid = Brandid from Brands
			where OwnerEntityID = @supplierid
			and ltrim(rtrim(OwnerBrandIdentifier)) = @brandname
			
			if @@ROWCOUNT < 1
				begin
					INSERT INTO [DataTrue_Main].[dbo].[Brands]
							   ([ManufacturerID]
							   ,[BrandName]
							   ,[BrandIdentifier]
							   ,[OwnerEntityID]
							   ,[OwnerBrandIdentifier])
						 VALUES
							   (@manufacturerid
							   ,@brandname
							   ,@brandname
							   ,@supplierid
							   ,@brandname)

				end			
								
		
			
		fetch next from @rec2 into @maintenancerequestid, @upc12, @itemdescription, @chainid, 
		@approved, @requesttypeid, @brandname, @supplierid, @requestsource, @manufactureridentifier
	end
	
close @rec2
deallocate @rec2

return
GO
