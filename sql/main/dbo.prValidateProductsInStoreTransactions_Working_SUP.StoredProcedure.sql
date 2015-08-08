USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateProductsInStoreTransactions_Working_SUP]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateProductsInStoreTransactions_Working_SUP]

as

declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 7583

begin try

/*
--****************************Manage UPC************************************

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
select * from productidentifiers where productid = 16396 --16640 024126008221
*/

set @rec = CURSOR local fast_forward FOR
	select distinct LTRIM(rtrim(upc))
	from dbo.StoreTransactions_Working w
	where 1 = 1
	and workingStatus = 1
	and LEN(upc) = 10
	
open @rec

fetch next from @rec into @mrupc

while @@FETCH_STATUS = 0
	begin
	
				set @productfound = 0
				
			
			if @productfound = 0
				begin
				
				set @upc11 = '0' + @mrupc
				
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

--**************************************************************************

update t set t.WorkingStatus = 1
--select *
from [dbo].[StoreTransactions_Working] t
inner join [dbo].[ProductIdentifiers] p
on ltrim(rtrim(t.UPC)) = ltrim(rtrim(p.IdentifierValue))
where p.ProductIdentifierTypeID = 2 --UPC is type 2
and t.WorkingStatus = -2
and t.WorkingSource in ('SUP-S','SUP-U','SUP-O')


select distinct StoreTransactionID, UPC
into #tempStoreTransaction
--select *
from [dbo].[StoreTransactions_Working]
where WorkingStatus = 1
and WorkingSource in ('SUP-S', 'SUP-U','SUP-O')

begin transaction

set @loadstatus = 2



/*
     select distinct ltrim(rtrim(UPC))
 from StoreTransactions_Working w
  where workingStatus = 1
  and ltrim(rtrim(UPC))
  not in 
(select ltrim(rtrim(identifiervalue)) from ProductIdentifiers)

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
on ltrim(rtrim(t.UPC)) = ltrim(rtrim(p.IdentifierValue))
where p.ProductIdentifierTypeID = 2 --UPC is type 2
and (t.ProductID is null or t.ProductID = 0)
and ltrim(rtrim(t.UPC)) not in
(
	select ltrim(rtrim(UPC)) 
	from dbo.Util_DisqualifiedUPCbySupplier
	where SupplierID in (41440)
)

update t set t.WorkingStatus = -2
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.ProductID is null

if @@ROWCOUNT > 0
	begin
		set @errormessage = 'Unknown Product Identifiers Found'
		set @errorlocation = 'prValidateProductsInStoreTransactions_Working_SUP'
		set @errorsenderstring = 'prValidateProductsInStoreTransactions_Working_SUP'
		
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

update t set UnitCost = 0.00 --ISNULL(c.ProductCost, ReportedUnitCost)
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
*/
/*
inner join [dbo].[ProductCosts] c
on t.ProductID = c.ProductID and t.SupplierID = c.SupplierID 
and t.StoreID = c.storeid and t.BrandID = c.brandid
where t.SaleDateTime between c.ActiveStartDate and c.ActiveLastDate
*/
/*
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
*/
update t set t.BrandID = 0
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.BrandID is null
and (len(t.BrandIdentifier) < 1 or t.brandidentifier is null)

update t set t.BrandID = b.BrandID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join Brands b
on t.BrandIdentifier = b.BrandIdentifier
where t.BrandID is null
and len(t.BrandIdentifier) > 0

update t set t.WorkingStatus = -2
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.BrandID is null

if @@ROWCOUNT > 0
	begin
		set @errormessage = 'Unknown Brand Identifiers Found'
		set @errorlocation = 'prValidateProductsInStoreTransactions_Working_SUP'
		set @errorsenderstring = 'prValidateProductsInStoreTransactions_Working_SUP'
		
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
		
		set @loadstatus = -9998
		
		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
		exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'DailySUPLoadDeliveriesAndPickups_THIS_IS_CURRENT_ONE'

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Load Deliveries and Pickups Job Stopped'
				,'Deliveries and pickup loading has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;edi@icontroldsd.com'	
		
end catch
	
update t set t.WorkingStatus = -11
--select *
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t 
on tmp.StoreTransactionID = t.StoreTransactionID
inner join Util_DisqualifiedUPCbySupplier u
on t.UPC = u.UPC
and t.SupplierID=u.SupplierID
where t.WorkingStatus = -2


update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where workingstatus = 1
--and t.ProductID is not null


	
return
GO
