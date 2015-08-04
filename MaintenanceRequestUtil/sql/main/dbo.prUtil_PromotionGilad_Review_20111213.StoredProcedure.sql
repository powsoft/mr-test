USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_PromotionGilad_Review_20111213]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_PromotionGilad_Review_20111213]
as



declare @rec cursor
declare @upc nvarchar(50)
declare @productid int
declare @supplierid int
declare @brandid int
declare @mrupc nvarchar(50)
declare @checkdigit char(1)
declare @lenofupc tinyint
declare @maintenancerequestid int
declare @costzone nvarchar(50)
declare @allowance money

set @rec = CURSOR local fast_forward FOR
	select ProductId, supplierid, CostZone, Allowance
	from PromotionsGilad
	where supplierid = 41465
	and BeginDate = '12/12/2011'

/*
	select id, LTRIM(rtrim(upc12digit)) from PromotionsGilad
	where RecordStatus = 0 
	and ProductId is null
	select distinct storeid from supplierssetupdata where pricezone = 'St. Louis'
*/
	
open @rec

fetch next from @rec into @productid, @supplierid, @costzone, @allowance

while @@FETCH_STATUS = 0
	begin
	
	
				SELECT  * from ProductPrices 
				where SupplierID = @supplierid
				and ProductID = @productid
				and ProductPriceTypeID = 8
				and StoreID in 
				(select storeid from supplierssetupdata where Pricezone = @costzone)
				and activeLastDate >= '12/12/2011'

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
						update PromotionsGilad set Productid = @productid
						where ID = @maintenancerequestid
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
						update PromotionsGilad set Productid = @productid
						where ID = @maintenancerequestid
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
						update PromotionsGilad set Productid = @productid
						where ID = @maintenancerequestid
					end			
			end		
		*/
		print @allowance
		fetch next from @rec into @productid, @supplierid, @costzone, @allowance

	end
	
close @rec
deallocate @rec
	
	

return
GO
