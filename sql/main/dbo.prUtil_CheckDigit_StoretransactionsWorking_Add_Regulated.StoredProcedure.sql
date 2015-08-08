USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_CheckDigit_StoretransactionsWorking_Add_Regulated]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_CheckDigit_StoretransactionsWorking_Add_Regulated]
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
declare @upc12 nvarchar(50)
declare @upc11 nvarchar(50)
declare @chainid int
declare @addnewproduct bit=0
declare @productfound bit
declare @approved bit
declare @recten cursor
declare @requesttypeid int
declare @transid bigint


set @rec2 = CURSOR local fast_forward FOR
	select distinct storetransactionid, LTRIM(rtrim(upc))
	from StoreTransactions_Working
	where WorkingStatus = 3
	and WorkingSource = 'SUP-S'
	and LEN(LTRIM(rtrim(upc))) = 11
	and upc in ('74136034589','74136034588')

	
	
open @rec2

fetch next from @rec2 into @transid, @upc12

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
					select @productdescription = description from Products where ProductID = @productid
				end
			else
				begin
				
				set @upc11 = @upc12
				
				set @CheckDigit = ''
				exec [dbo].[prUtil_UPC_GetCheckDigit]
					 @upc11,
					 @CheckDigit OUT	
					 
				set @upc12 = @upc11 + @CheckDigit	
				
				select @productid = productid from ProductIdentifiers 
				where LTRIM(rtrim(identifiervalue)) = @upc12
				and ProductIdentifierTypeID = 2
				
				--if @@ROWCOUNT > 0
				--	begin
						update t set t.upc = @upc12
						from StoreTransactions_Working t
						where Storetransactionid = @transid
				--	end
				--else
				--	begin
				--		set @upc12 = @upc
				--	end			
				
				end
				
		
		fetch next from @rec2 into @transid, @upc12
	end
	
close @rec2
deallocate @rec2

return
GO
