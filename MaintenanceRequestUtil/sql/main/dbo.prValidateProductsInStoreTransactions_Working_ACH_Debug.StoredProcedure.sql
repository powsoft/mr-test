USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateProductsInStoreTransactions_Working_ACH_Debug]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateProductsInStoreTransactions_Working_ACH_Debug]

as

declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @count smallint
declare @supplierid int
declare @ediname nvarchar(50)
declare @MyID int
set @MyID = 53829

begin try


--update t set t.WorkingStatus = 1
----select *
--from [dbo].[StoreTransactions_Working] t
--inner join [dbo].[ProductIdentifiers] p
--on ltrim(rtrim(t.UPC)) = ltrim(rtrim(p.IdentifierValue))
--where p.ProductIdentifierTypeID = 2 --UPC is type 2
--and t.WorkingStatus = -2
--and t.WorkingSource in ('SUP-S','SUP-U')
--and EDIName in(
--	Select SupplierName 
--	From DataTrue_EDI.dbo.ProcessStatus_ACH 
--	Where BillingIsRunning = 1
--	and BillingComplete = 0)

select distinct StoreTransactionID, ltrim(rtrim(ItemSKUReported)) as ItemNumber, 
ltrim(rtrim(UPC)) as UPC, ItemDescriptionReported, EDIName
into #tempStoreTransaction
--select *
from [dbo].[StoreTransactions_Working]
where WorkingStatus = 1
and WorkingSource in ('SUP-S', 'SUP-U')
--and EDIName in(
--	Select SupplierName 
--	From DataTrue_EDI.dbo.ProcessStatus_ACH 
--	Where BillingIsRunning = 1
--	and BillingComplete = 0)

--begin transaction

set @loadstatus = 2
/*
	select distinct ltrim(rtrim(tmp.ItemNumber)), ltrim(rtrim(tmp.UPC)), ItemDescriptionReported, ltrim(rtrim(tmp.ediname))
	from #tempStoreTransaction tmp
	where ltrim(rtrim(tmp.ItemNumber)) not in
	(select ltrim(rtrim(IdentifierValue)) from [dbo].[ProductIdentifiers] where ProductIdentifierTypeID = 3 and OwnerEntityId = 50729)
*/
declare @rec cursor
declare @UPC nvarchar(50)
declare @itemnumber nvarchar(50)
declare @StoreTransactionID int
declare @productid int
declare @itemdescriptionreported nvarchar(255)

set @rec = CURSOR local fast_forward for
	select distinct ltrim(rtrim(tmp.ItemNumber)), ltrim(rtrim(tmp.UPC)), ItemDescriptionReported, ltrim(rtrim(tmp.ediname))
	from #tempStoreTransaction tmp
	where 1 = 1
	--and ltrim(rtrim(tmp.UPC)) = '999999999998'
	and ltrim(rtrim(tmp.ItemNumber)) not in
	(select ltrim(rtrim(IdentifierValue)) from [dbo].[ProductIdentifiers] 
	where ProductIdentifierTypeID = 3 
	and OwnerEntityId = (Select SupplierID From Suppliers Where UniqueEDIName = tmp.ediname)) --50729

open @rec

fetch next from @rec into @itemnumber, @UPC, @itemdescriptionreported, @Ediname

while @@FETCH_STATUS = 0
	begin
	
		begin transaction
		
		select @supplierid = supplierid
		from Suppliers
		where LTRIM(rtrim([UniqueEDIName])) = @ediname
		
		if LEN(@upc) = 12
			begin
			
				set @productid = null
				select @productid = productid
				from ProductIdentifiers
				where LTRIM(rtrim(identifiervalue)) = @UPC
				and ProductIdentifierTypeID = 2		
			end
			
		if @productid is null
			begin
				INSERT INTO [dbo].[Products]
				   ([ProductName]
				   ,[Description]
				   ,[ActiveStartDate]
				   ,[ActiveLastDate]
				   ,[LastUpdateUserID])
				VALUES
				   ( isnull(@itemdescriptionreported, @UPC)
				   , isnull(@itemdescriptionreported, @UPC)
				   ,GETDATE()
				   ,'12/31/2025'
				   ,@MyID)
				   
				set @productid = Scope_Identity()
			end


	
	
		set @count = 0
		select @count = COUNT(productid) from ProductIdentifiers
		where LTRIM(rtrim(identifiervalue)) = @ItemNumber
		and ProductIdentifierTypeID = 3
		and OwnerEntityId = @supplierid
				
		if @count = 0 and LEN(@ItemNumber) > 0
			begin	
				INSERT INTO [dbo].[ProductIdentifiers]
				   ([ProductID]
				   ,[ProductIdentifierTypeID]
				   ,[OwnerEntityId]
				   ,[IdentifierValue]
				   ,[LastUpdateUserID])
				VALUES
				   (@productid
				   ,3 --VIN is type 3
				   ,@supplierid -- 0 is default entity
				   ,@itemnumber
				   ,@MyID)
			end
 
		if LEN(@upc) = 12
			begin
			
				set @count = 0
				select @count = COUNT(productid) from ProductIdentifiers
				where LTRIM(rtrim(identifiervalue)) = @UPC
				and ProductIdentifierTypeID = 2
				
				if @count = 0
					begin
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
				   end
           end
 
 	--	set @count = 0
		--select @count = COUNT(productid) from [dbo].[ProductBrandAssignments]
		--where productid = @productid
		--and BrandID = 0
		--and CustomOwnerEntityID = 0
				
		--if @count = 0
		--	begin
           
		--		 INSERT INTO [dbo].[ProductBrandAssignments]
		--				   ([BrandID]
		--				   ,[ProductID]
		--				   ,[CustomOwnerEntityID]
		--				   ,[LastUpdateUserID])
		--			 VALUES
		--				   (0
		--				   ,@productid
		--				   ,0
		--				   ,@MyID)
		--	end


 	--	set @count = 0
		--select @count = COUNT(productid) from [dbo].[ProductCategoryAssignments]
		--where productid = @productid
		--and productcategoryid = 0
		--and CustomOwnerEntityID = 0
				
		--if @count = 0
		--	begin
		--		INSERT INTO [dbo].[ProductCategoryAssignments]
		--				   ([ProductCategoryID]
		--				   ,[ProductID]
		--				   ,[CustomOwnerEntityID]
		--				   ,[LastUpdateUserID])
		--			 VALUES
		--				   (0
		--				   ,@productid
		--				   ,0
		--				   ,@MyID)   
		--	end
			    
commit transaction
		fetch next from @rec into @itemnumber, @UPC, @itemdescriptionreported, @Ediname
	end
	
close @rec
deallocate @rec
--*/

--select t.StoreIdentifier, s.StoreIdentifier, s.StoreID, c.ChainID
update t set t.ProductID = p.ProductID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[ProductIdentifiers] p
on ltrim(rtrim(t.ItemSKUReported)) = ltrim(rtrim(p.IdentifierValue))
where p.ProductIdentifierTypeID = 3 --UPC is type 2
and t.ProductID is null

update t set t.ProductID = p.ProductID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[ProductIdentifiers] p
on ltrim(rtrim(t.UPC)) = ltrim(rtrim(p.IdentifierValue))
where p.ProductIdentifierTypeID = 2 --UPC is type 2
and t.ProductID is null

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
	
--commit transaction
	
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
			@job_name = 'Billing_Regulated'
			
		Update 	DataTrue_Main.dbo.JobRunning
		Set JobIsRunningNow = 0
		Where JobName = 'DailyRegulatedBilling'	

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated Job Stopped'
				,'An exception occurred in prValidateProductsInStoreTransactions_Working_ACH.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'vince.moore@icontroldsd.com'--'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
		
end catch
	


update t set WorkingStatus = 3, LastUpdateUserID = @MyID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where workingstatus = 1
--and t.ProductID is not null


	
return
GO
