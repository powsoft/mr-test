USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prStoreTransactionsWorking_UPC_ProductID_Manage]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prStoreTransactionsWorking_UPC_ProductID_Manage]
as

declare @rec cursor
declare @rec2 cursor
declare @rec3 cursor
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
declare @addnewproduct bit=0
declare @productfound bit
declare @approved bit
/*
select *
FROM storetransactions_working i
WHERE    workingstatus = 1

select top 100 * from dbo.MaintenanceRequests where supplierid = 40567
select * from productidentifiers where productid = 16396 --16640 024126008221
select * from dbo.StoreTransactions_Working where 1 = 1 and WorkingStatus = 1
710101262718 
select * from productidentifiers where charindex('71010126271', identifiervalue) > 0

select p.productid, '0' + ltrim(rtrim(i.ProductIdentifier))
FROM datatrue_edi.dbo.Inbound846Inventory i
inner join productidentifiers p
on '0' + left(ltrim(rtrim(i.ProductIdentifier)), 11) = ltrim(rtrim(p.identifiervalue))
WHERE     (EffectiveDate = '12/1/2011') AND (PurposeCode = 'CNT')

select p.productid, ltrim(rtrim(i.ProductIdentifier))
FROM datatrue_edi.dbo.Inbound846Inventory i
inner join productidentifiers p
on ltrim(rtrim(i.ProductIdentifier)) = ltrim(rtrim(p.identifiervalue))
WHERE     (EffectiveDate = '12/1/2011') AND (PurposeCode = 'CNT')

select * from storetransactions where supplierid = 40561 and productid = 6216

select p.productid, i.productid, ltrim(rtrim(i.upc))
--update i set i.productid = p.productid, i.upc = ltrim(rtrim(p.identifiervalue))
FROM storetransactions_working i
inner join productidentifiers p
on ltrim(rtrim(i.upc)) = ltrim(rtrim(p.identifiervalue))
WHERE    workingstatus = 1
and p.productidentifiertypeid = 2
and i.productid is null

select p.productid, i.productid, '0' + left(ltrim(rtrim(i.upc)), 11)
--update i set i.productid = p.productid, i.upc = ltrim(rtrim(p.identifiervalue))
FROM storetransactions_working i
inner join productidentifiers p
on '0' + left(ltrim(rtrim(i.upc)), 11) = ltrim(rtrim(p.identifiervalue))
--on ltrim(rtrim(i.upc)) = ltrim(rtrim(p.identifiervalue))
WHERE    workingstatus = 1
and i.productid is null
and p.productidentifiertypeid = 2

select *
FROM storetransactions_working i
WHERE    workingstatus = 1
and i.productid is null
*/

set @rec = CURSOR local fast_forward FOR
	select storetransactionid, LTRIM(rtrim(upc))
	from dbo.StoreTransactions_Working
	where 1 = 1
	and WorkingStatus = 1
	and ProductId is null
	and LEN(LTRIM(rtrim(upc))) = 11
	
open @rec

fetch next from @rec into @maintenancerequestid, @mrupc

while @@FETCH_STATUS = 0
	begin
	
				set @productfound = 0
				

				set @upc12 = '0' + @mrupc

--********************************************************************************
			select @productid = productid from ProductIdentifiers 
			where LTRIM(rtrim(identifiervalue)) = @upc12
			
			if @@ROWCOUNT > 0
				begin
					set @productfound = 1
				end
				
			if @productfound = 0
				begin
				
				set @upc11 = @mrupc
				--set @upc11 = '0' + @mrupc
				
				set @CheckDigit = ''
				exec [dbo].[prUtil_UPC_GetCheckDigit]
					 @upc11,
					 @CheckDigit OUT	
					 
				set @upc12 = @upc11 + @CheckDigit				
				
				
					
					select @productid = productid from ProductIdentifiers 
					where LTRIM(rtrim(identifiervalue)) = @upc12
					
					if @@ROWCOUNT > 0
						begin
							set @productfound = 1
						end					

				
				end

		  
		  print @productid
		  if @productfound = 1
			begin
				update StoreTransactions_Working set Productid = @productid, upc = @upc12
				where storetransactionID = @maintenancerequestid
			end
			
		fetch next from @rec into @maintenancerequestid, @mrupc
	end
	
close @rec
deallocate @rec
	
	


set @rec2 = CURSOR local fast_forward FOR
	select storetransactionID, LTRIM(rtrim(upc))
	from dbo.StoreTransactions_Working
	where 1 = 1
	and WorkingStatus = 1
	and ProductId is null
	and LEN(LTRIM(rtrim(upc))) = 12
	
open @rec2

fetch next from @rec2 into @maintenancerequestid, @upc12

while @@FETCH_STATUS = 0
	begin
	
			set @productfound = 0
			
			select @productid = productid from ProductIdentifiers 
			where LTRIM(rtrim(identifiervalue)) = @upc12
			
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
				
				if @@ROWCOUNT > 0
					begin
						set @productfound = 1
					end			
				
				end
				
		  if @productfound = 1
			begin
				update StoreTransactions_Working set Productid = @productid, upc = @upc12
				where storetransactionID = @maintenancerequestid
			end


			
		fetch next from @rec2 into @maintenancerequestid, @upc12
	end
	
close @rec2
deallocate @rec2




return
GO
