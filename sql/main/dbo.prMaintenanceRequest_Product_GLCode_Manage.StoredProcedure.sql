USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_Product_GLCode_Manage]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_Product_GLCode_Manage]
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
declare @recordid int
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
/*
*/



set @rec2 = CURSOR local fast_forward FOR
	select ID, ltrim(rtrim(ProductIdentifier))
	from datatrue_edi.dbo.ProductsSuppliersItemsConversion
	where 1 = 1
	and ProductID2 is null
	and LEN(LTRIM(rtrim(ProductIdentifier))) = 12

	
	
open @rec2

fetch next from @rec2 into @recordid, @upc12

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
						end
				end
				
		  if @productfound = 1
			begin
				update datatrue_edi.dbo.ProductsSuppliersItemsConversion 
				set ProductID2 = @productid, upc12 = @upc12
				where ID = @recordid
			end

		fetch next from @rec2 into @recordid, @upc12
	end
	
close @rec2
deallocate @rec2


return
GO
