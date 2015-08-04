USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_Product_Manage_Bipad]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_Product_Manage_Bipad]
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
declare @bipad nvarchar(50)
declare @upc11 nvarchar(50)
declare @chainid int
declare @addnewproduct bit=1
declare @productfound bit
declare @approved bit
declare @recten cursor

declare @requesttypeid int


set @rec2 = CURSOR local fast_forward FOR
	select maintenancerequestid, LTRIM(rtrim(bipad)), LTRIM(rtrim(ItemDescription)) , Chainid, approved--, productid
	,RequestTypeID
	--into import.dbo.tmpMaintenanceRequestRecordsThatGotWrongProductIDs_20111231
	from dbo.MaintenanceRequests
	where 1 = 1
	and RequestStatus in (0, 1, -90, -30, -333, -31, 5, 17)
	and ProductId is null
	and (Approved = 1 or RequestStatus in (-25, -26, -90, -30, -333, -31))
	and upc is null
	and bipad is not null

	
	
open @rec2

fetch next from @rec2 into @maintenancerequestid, @bipad, @itemdescription, @chainid, @approved, @requesttypeid

while @@FETCH_STATUS = 0
	begin
	
			set @productfound = 0
			
			select @productid = productid from ProductIdentifiers 
			where LTRIM(rtrim(Bipad)) = @bipad
			and ProductIdentifierTypeID = 8
			
			if @@ROWCOUNT > 0
				begin
					set @productfound = 1
					select @productdescription = description from Products where ProductID = @productid
				end

		  if @productfound = 1
			begin
				update MaintenanceRequests set Productid = @productid, dtproductdescription = @productdescription
				where MaintenanceRequestID = @maintenancerequestid
			end
																	   	
			
		fetch next from @rec2 into @maintenancerequestid, @bipad, @itemdescription, @chainid, @approved, @requesttypeid
	end
	
close @rec2
deallocate @rec2

return
GO
