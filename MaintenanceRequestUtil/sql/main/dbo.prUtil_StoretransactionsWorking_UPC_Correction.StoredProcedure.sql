USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_StoretransactionsWorking_UPC_Correction]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_StoretransactionsWorking_UPC_Correction]
as

declare @rec cursor
declare @rec2 cursor
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
declare @addnewproduct bit=1
declare @productfound bit
declare @approved bit


set @rec = CURSOR local fast_forward FOR
	select storetransactionid, LTRIM(rtrim(upc))
	--select *
	from StoreTransactions_Working
	where 1 = 1
	and WorkingStatus = 1
	
open @rec

fetch next from @rec into @maintenancerequestid, @mrupc

while @@FETCH_STATUS = 0
	begin
	
				set @productfound = 0
				
				set @upc11 = right(@mrupc, 11)
				--set @upc11 = '0' + @mrupc
				
				set @CheckDigit = ''
				exec [dbo].[prUtil_UPC_GetCheckDigit]
					 @upc11,
					 @CheckDigit OUT	
					 
				set @upc12 = @upc11 + @CheckDigit
	
--********************************************************************************
			select @productid = productid from ProductIdentifiers 
			where LTRIM(rtrim(identifiervalue)) = @upc12
			
			if @@ROWCOUNT > 0
				begin
					set @productfound = 1
				end
				

  
		  print @productid
		  if @productfound = 1
			begin
				update StoreTransactions_Working set Productid = @productid, UPC = @upc12
				where StoreTransactionID = @maintenancerequestid
			end
			
			
		fetch next from @rec into @maintenancerequestid, @mrupc
	end
	
close @rec
deallocate @rec
GO
