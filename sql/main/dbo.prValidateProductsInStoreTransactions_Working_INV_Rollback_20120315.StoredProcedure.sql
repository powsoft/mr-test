USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateProductsInStoreTransactions_Working_INV_Rollback_20120315]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prValidateProductsInStoreTransactions_Working_INV_Rollback_20120315]

as
--*****************Manage UPCs*******************************

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
select top 100 * from dbo.MaintenanceRequests where supplierid = 40567
select * from productidentifiers where productid in
(select distinct productid from productprices where unitprice = 2.87) order by identifiervalue
7341013410
select * from storetransactions where charindex('3410134', productidentifier) > 0

select * from productidentifiers where productid = 16396 --16640 024126008221
select * from productidentifiers where charindex('734101341', identifiervalue) > 0
	select distinct len(LTRIM(rtrim(upc)))
	from dbo.StoreTransactions_Working w
	where 1 = 1
	and workingStatus = 1
*/
/*
set @rec = CURSOR local fast_forward FOR
	select distinct LTRIM(rtrim(upc))
	--select *
	from dbo.StoreTransactions_Working w
	where 1 = 1
	and workingStatus = 1
	and ProductID is null
	and LEN(LTRIM(rtrim(upc))) in (10, 11)
	
open @rec

fetch next from @rec into @mrupc

while @@FETCH_STATUS = 0
	begin
	
				set @productfound = 0
				
			
			if @productfound = 0
				begin
				
				if LEN(@mrupc) = 11
					begin
						set @upc11 = @mrupc
					end
				else
					begin
						set @upc11 = '0' + @mrupc
					end
				
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
				update dbo.StoreTransactions_Working set Productid = @productid, upc = @upc12
				where upc = @mrupc
				and WorkingStatus = 1
			end
			
		fetch next from @rec into @mrupc
	end
	
close @rec
deallocate @rec
	
*/



--***********************************************************
declare @errorsenderstring nvarchar(255)
declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 7595

begin try

select distinct StoreTransactionID, UPC
into #tempStoreTransaction
--select *
from [dbo].[StoreTransactions_Working]
where WorkingStatus = 1
and WorkingSource in ('INV')

begin transaction

set @loadstatus = 2

/*
declare @rec cursor
declare @UPC nvarchar(50)
declare @StoreTransactionID int
declare @productid int

set @rec = CURSOR local fast_forward for
select distinct tmp.UPC
from #tempStoreTransaction tmp
--inner join [dbo].[StoreTransactions_Working] t
--on tmp.StoreTransactionID = t.StoreTransactionID
where tmp.UPC not in
(select IdentifierValue from [dbo].[ProductIdentifiers] where ProductIdentifierTypeID = 2)

/*
set @rec = CURSOR local fast_forward for
select tmp.UPC, tmp.StoreTransactionID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.ProductID is null
*/

open @rec

fetch next from @rec into @UPC--, @StoreTransactionID

while @@FETCH_STATUS = 0
	begin
	
		INSERT INTO [dbo].[Products]
           ([ProductName]
           ,[Description]
           ,[ActiveStartDate]
           ,[ActiveLastDate]
           ,[LastUpdateUserID])
		VALUES
           (@UPC
           ,'UNKNOWN'
           ,GETDATE()
           ,'12/31/2025'
           ,@MyID)

		set @productid = Scope_Identity()
		
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
           ,@UPC
           ,@MyID)
           
 INSERT INTO [dbo].[ProductBrandAsignments]
           ([BrandID]
           ,[ProductID]
           ,[CustomOwnerEntityID]
           ,[LastUpdateUserID])
     VALUES
           (0
           ,@productid
           ,0
           ,@MyID)

INSERT INTO [dbo].[ProductCategoryAssignments]
           ([ProductCategoryID]
           ,[ProductID]
           ,[CustomOwnerEntityID]
           ,[LastUpdateUserID])
     VALUES
           (0
           ,@productid
           ,0
           ,@MyID)       

		fetch next from @rec into @UPC--, @StoreTransactionID	
	end
	
close @rec
deallocate @rec
*/

--select t.StoreIdentifier, s.StoreIdentifier, s.StoreID, c.ChainID
update t set t.ProductID = p.ProductID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[ProductIdentifiers] p
on t.UPC = p.IdentifierValue
where p.ProductIdentifierTypeID = 2 --UPC is type 2
and WorkingStatus = 1
and t.ProductID is null

update t set t.WorkingStatus = -2
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.ProductID is null
and WorkingStatus = 1

if @@ROWCOUNT > 0
	begin
		
--declare @errorsenderstring nvarchar(255)
		set @errormessage = 'UNKNOWN Product Identifiers Found.  Records in the StoreTransactions_Working have been pended to a status of -2.'
		set @errorlocation = 'Invalid EDI data found during execution of prValidateProductsInStoreTransactions_Working_INV'
		set @errorsenderstring = 'prValidateProductsInStoreTransactions_Working_INV'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
	end
	
/*
update t set t.ReportedUnitCost = 0.00
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.ReportedUnitCost is null

update t set t.ReportedUnitPrice = 0.00
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.ReportedUnitPrice is null

update t set UnitCost = ISNULL(c.ProductCost, ReportedUnitCost)
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[ProductCosts] c
on t.ProductID = c.ProductID and t.SupplierID = c.SupplierID 
and t.StoreID = c.storeid and t.BrandID = c.brandid
where t.SaleDateTime between c.ActiveStartDate and c.ActiveLastDate

update t set UnitCost = ISNULL(ReportedUnitCost, 0.00)
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.UnitCost is null

update t set t.UnitSalePrice = ISNULL(p.UnitPrice, ReportedUnitPrice),
t.ProductPriceTypeID = p.ProductPriceTypeID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[ProductPrices] p
on t.ProductID = p.ProductID and t.StoreID = p.StoreID and t.BrandID = p.BrandID
where t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate


update t set UnitSalePrice = ISNULL(ReportedUnitPrice, 0.00),
t.ProductPriceTypeID = 0
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.UnitSalePrice is null

declare @brandid int
select @brandid = BrandID from Brands where BrandName = 'WorldMartBrand'
--select BrandID from Brands where BrandName = 'WorldMartBrand'
update [dbo].[StoreTransactions_Working] set BrandID = @brandid
where ChainID = 7608 --csc here now

*/


update t set BrandID = b.BrandID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Brands] b
on t.BrandIdentifier = b.BrandIdentifier
where LEN(t.BrandIdentifier) > 0 
and t.BrandIdentifier is not null
and t.WorkingStatus = 1


update t set t.BrandID = 0
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where (t.BrandIdentifier is null or LEN(t.BrandIdentifier) = 0)
and t.WorkingStatus = 1


update t set t.WorkingStatus = -2
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.BrandID is null
and WorkingStatus = 1

if @@ROWCOUNT > 0
	begin
		
--declare @errorsenderstring nvarchar(255)
		set @errormessage = 'UNKNOWN Brand Identifiers Found.  Records in the StoreTransactions_Working have been pended to a status of -2.'
		set @errorlocation = 'Invalid EDI data found during execution of prValidateProductsInStoreTransactions_Working_INV'
		set @errorsenderstring = 'prValidateProductsInStoreTransactions_Working_INV'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
	end

		commit transaction
	
end try
	
begin catch

		rollback transaction
		
		set @loadstatus = -9997
		
		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
end catch
	

update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.workingstatus = 1
--and t.ProductID is not null


	
return
GO
