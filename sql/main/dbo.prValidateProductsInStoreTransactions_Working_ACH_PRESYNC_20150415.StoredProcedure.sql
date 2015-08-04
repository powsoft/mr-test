USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateProductsInStoreTransactions_Working_ACH_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateProductsInStoreTransactions_Working_ACH_PRESYNC_20150415]

as

declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @count smallint
declare @supplierid int
declare @ediname nvarchar(50)
declare @MyID int
set @MyID = 63600

begin try

DECLARE @ProcessID INT

SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobName = 'DailyRegulatedBilling'

DECLARE @tempStoreTransaction TABLE
(
	StoreTransactionID INT,
	ItemNumber VARCHAR(120),
	UPC VARCHAR(50),
	ItemDescriptionReported VARCHAR(240),
	EDIName VARCHAR(50)
);

update t set t.WorkingStatus = 1
--select *
from [dbo].[StoreTransactions_Working] t
inner join [dbo].[ProductIdentifiers] p
on ltrim(rtrim(t.UPC)) = ltrim(rtrim(p.IdentifierValue))
where p.ProductIdentifierTypeID = 2 --UPC is type 2
and t.WorkingStatus = -2
and t.WorkingSource in ('SUP-S','SUP-U')
and ProcessID = @ProcessID

--select distinct StoreTransactionID, ltrim(rtrim(ItemSKUReported)) as ItemNumber, 
--ltrim(rtrim(UPC)) as UPC, ItemDescriptionReported, EDIName
--into @tempStoreTransaction
insert into @tempStoreTransaction (StoreTransactionID, ItemNumber, UPC, ItemDescriptionReported, EDIName)
select distinct StoreTransactionID, ltrim(rtrim(isnull(ItemSKUReported, ''))) as ItemNumber, 
ltrim(rtrim(isnull(UPC, ''))) as UPC, ItemDescriptionReported, EDIName
--select *
from [dbo].[StoreTransactions_Working]
where WorkingStatus = 1
and WorkingSource in ('SUP-S', 'SUP-U')
and ProcessID = @ProcessID

--begin transaction

set @loadstatus = 2
/*
	select distinct ltrim(rtrim(tmp.ItemNumber)), ltrim(rtrim(tmp.UPC)), ItemDescriptionReported, ltrim(rtrim(tmp.ediname))
	from @tempStoreTransaction tmp
	where ltrim(rtrim(tmp.ItemNumber)) not in
	(select ltrim(rtrim(IdentifierValue)) from [dbo].[ProductIdentifiers] where ProductIdentifierTypeID = 3 and OwnerEntityId = 50729)
*/
declare @rec cursor
declare @UPC nvarchar(50)
declare @itemnumber nvarchar(50)
declare @StoreTransactionID int
declare @productid int
declare @productidupc int
declare @productidvin int
declare @itemdescriptionreported nvarchar(255)
declare @upcfound bit
declare @vinfound bit

set @rec = CURSOR local fast_forward for
	select distinct ltrim(rtrim(tmp.ItemNumber)), ltrim(rtrim(tmp.UPC)), ItemDescriptionReported, ltrim(rtrim(tmp.ediname))
	from @tempStoreTransaction tmp
	where 1 = 1
	--and ltrim(rtrim(tmp.UPC)) = '999999999998'
	and ltrim(rtrim(isnull(tmp.ItemNumber, ''))) not in
	(select ltrim(rtrim(IdentifierValue)) from [dbo].[ProductIdentifiers] 
	where ProductIdentifierTypeID = 3 
	and OwnerEntityId = (Select SupplierID From Suppliers Where EDIName = tmp.ediname)) --50729

open @rec

fetch next from @rec into @itemnumber, @UPC, @itemdescriptionreported, @Ediname

while @@FETCH_STATUS = 0
	begin
	
		begin transaction
		
		set @upcfound = 0
		set @vinfound = 0
		set @productid = null
		set @productidupc = null
		set @productidvin = null
		
		select @supplierid = supplierid
		from Suppliers
		where LTRIM(rtrim([EDIName])) = @ediname
		
		IF LEN(@itemnumber) > 0
			BEGIN
				
				SELECT @productidvin = ProductID
				FROM ProductIdentifiers
				WHERE LTRIM(RTRIM(Identifiervalue)) = @itemnumber
				AND OwnerEntityId = @supplierid
				
				IF @productidvin IS NOT NULL
					BEGIN
						SET @vinfound = 1
					END
			END
		
		if LEN(@upc) >= 12
			begin
				set @productidupc = null
				select @productidupc = productid
				from ProductIdentifiers
				where LTRIM(rtrim(identifiervalue)) = @UPC
				and ProductIdentifierTypeID = 2		
				
				IF @productidupc IS NOT NULL
					BEGIN
						SET @upcfound = 1
					END
			end
			
		IF @upcfound = 1 AND @vinfound = 1
			BEGIN
				IF @productidupc <> @productidvin
					BEGIN
						DECLARE @ProductMismatchEmailBody VARCHAR(MAX) = ''
						SET @ProductMismatchEmailBody = 'The following UPC/VIN combination has mismatching ProductIDs.' + CHAR(10) + CHAR(13) +
														'UPC: ' + @UPC + CHAR(10) + CHAR(13) +
														'UPC ProductID: ' + CONVERT(VARCHAR(50), @productidupc) + CHAR(10) + CHAR(13) + 
														'VIN: ' + @itemnumber + CHAR(10) + CHAR(13) +
														'VIN ProductID: ' + CONVERT(VARCHAR(50), @productidvin)
						EXEC dbo.[prSendEmailNotification_PassEmailAddresses_HTML_Logos] 'Product Mismatch Detected During Supplier Invoicing'
							,@ProductMismatchEmailBody
							,'DataTrue System', 0, 'edi@icuclsoultions.com; datatrueit@icucsolutions.com'
						SET @productid = @productidupc
					END
				ELSE
					BEGIN
						SET @productid = @productidupc
					END
			END
		
			
		if @upcfound = 0 and @vinfound = 0 and (LEN(@upc) >= 12 or @itemnumber <> '')
			begin		
				--CREATE NEW PRODUCT
				INSERT INTO [dbo].[Products]
				   ([ProductName]
				   ,[Description]
				   ,[ActiveStartDate]
				   ,[ActiveLastDate]
				   ,[LastUpdateUserID])
				VALUES
				   ( @itemdescriptionreported
				   , @itemdescriptionreported
				   ,GETDATE()
				   ,'12/31/2025'
				   ,@MyID) 
				set @productid = Scope_Identity()
				
				IF LEN(@upc) >= 12
					BEGIN
						--INSERT UPC
						INSERT INTO [dbo].[ProductIdentifiers]
						   ([ProductID]
						   ,[ProductIdentifierTypeID]
						   ,[OwnerEntityId]
						   ,[IdentifierValue]
						   ,[LastUpdateUserID])
						VALUES
						   (@productid
						   ,2 --UPC is type 2
						   ,0 -- 0 for UPCs
						   ,@upc
						   ,@MyID)
					END
				 
				IF @itemnumber <> ''
					BEGIN
						--INSERT VIN
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
					END  
					
		            --INSERT BRAND ASSIGNEMENT
					INSERT INTO [dbo].[ProductBrandAssignments]
						   ([BrandID]
						   ,[ProductID]
						   ,[CustomOwnerEntityID]
						   ,[LastUpdateUserID])
					 VALUES
						   (0
						   ,@productid
						   ,0
						   ,@MyID)
					
					--INSERT CATEGORY ASSIGNMENT
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
			end
			
		if @upcfound = 1 and @vinfound = 0 and @itemnumber <> ''
			begin	
				INSERT INTO [dbo].[ProductIdentifiers]
				   ([ProductID]
				   ,[ProductIdentifierTypeID]
				   ,[OwnerEntityId]
				   ,[IdentifierValue]
				   ,[LastUpdateUserID])
				VALUES
				   (@productidupc
				   ,3 --VIN is type 3
				   ,@supplierid -- 0 is default entity
				   ,@itemnumber
				   ,@MyID)
			end
			
		if @vinfound = 1 and @upcfound = 0 and LEN(@upc) >= 12
			begin	
				INSERT INTO [dbo].[ProductIdentifiers]
				   ([ProductID]
				   ,[ProductIdentifierTypeID]
				   ,[OwnerEntityId]
				   ,[IdentifierValue]
				   ,[LastUpdateUserID])
				VALUES
				   (@productidvin
				   ,2 --UPC is type 2
				   ,0 -- 0 for UPCs
				   ,@upc
				   ,@MyID)
			end
 
 		
			    
commit transaction
		fetch next from @rec into @itemnumber, @UPC, @itemdescriptionreported, @Ediname
	end
	
close @rec
deallocate @rec
--*/

update t set t.ProductID = p.ProductID
from @tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[ProductIdentifiers] p
on ltrim(rtrim(t.UPC)) = ltrim(rtrim(p.IdentifierValue))
where p.ProductIdentifierTypeID = 2 --UPC is type 2
and t.ProductID is null

--select t.StoreIdentifier, s.StoreIdentifier, s.StoreID, c.ChainID
update t set t.ProductID = p.ProductID
from @tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[ProductIdentifiers] p
on ltrim(rtrim(t.ItemSKUReported)) = ltrim(rtrim(p.IdentifierValue))
where p.ProductIdentifierTypeID = 3 --UPC is type 2
and p.OwnerEntityId = (select SupplierID from suppliers where EDIName = t.EDIName)
and t.ProductID is null

update t set t.UPC = p.IdentifierValue
from @tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join ProductIdentifiers p
on t.ProductID = p.ProductID
and p.ProductIdentifierTypeID = 2
where ISNULL(t.UPC, '') = ''

update t set t.ItemSKUReported = p.IdentifierValue
from @tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join ProductIdentifiers p
on t.ProductID = p.ProductID
and p.ProductIdentifierTypeID = 3
where ISNULL(t.ItemSKUReported, '') = ''
and OwnerEntityId = (select SupplierID from suppliers where EDIName = t.EDIName)

update t set t.WorkingStatus = -2
from @tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.ProductID is null

if @@ROWCOUNT > 0
	begin
		set @errormessage = 'Unknown Product Identifiers Found'
		set @errorlocation = 'prValidateProductsInStoreTransactions_Working_ACH'
		set @errorsenderstring = 'prValidateProductsInStoreTransactions_Working_ACH'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
		exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'Billing_Regulated_NewInvoiceData'
		
	end

/*
update t set t.ReportedUnitCost = 0.00
from @tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.ReportedUnitCost is null

update t set t.ReportedUnitPrice = 0.00
from @tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.ReportedUnitPrice is null

update t set UnitCost = 0.00 --ISNULL(c.ProductCost, ReportedUnitCost)
from @tempStoreTransaction tmp
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
from @tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.UnitCost is null

update t set t.UnitSalePrice = ISNULL(p.UnitPrice, ReportedUnitPrice),
t.ProductPriceTypeID = p.ProductPriceTypeID
from @tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[ProductPrices] p
on t.ProductID = p.ProductID and t.StoreID = p.StoreID and t.BrandID = p.BrandID
where t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate


update t set UnitSalePrice = ISNULL(ReportedUnitPrice, 0.00),
t.ProductPriceTypeID = 0
from @tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.UnitSalePrice is null
*/
update t set t.BrandID = 0
from @tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.BrandID is null
and (len(t.BrandIdentifier) < 1 or t.brandidentifier is null)

update t set t.BrandID = b.BrandID
from @tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join Brands b
on t.BrandIdentifier = b.BrandIdentifier
where t.BrandID is null
and len(t.BrandIdentifier) > 0

update t set t.WorkingStatus = -2
from @tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.BrandID is null

if @@ROWCOUNT > 0
	begin
		set @errormessage = 'Unknown Brand Identifiers Found'
		set @errorlocation = 'prValidateProductsInStoreTransactions_Working_ACH'
		set @errorsenderstring = 'prValidateProductsInStoreTransactions_Working_ACH'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
		exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'Billing_Regulated_NewInvoiceData'
		
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
			@job_name = 'Billing_Regulated_NewInvoiceData'
		
		--exec [msdb].[dbo].[sp_stop_job] 
		--	@job_name = 'Billing_Regulated'
			
		--Update 	DataTrue_Main.dbo.JobRunning
		--Set JobIsRunningNow = 0
		--Where JobName = 'DailyRegulatedBilling'	

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated_NewInvoiceData Job Stopped'
				,'An exception occurred in prValidateProductsInStoreTransactions_Working_ACH.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, ''--'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
		
end catch
	


update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID
from @tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where workingstatus = 1
--and t.ProductID is not null


	
return
GO
