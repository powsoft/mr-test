USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateProductsInStoreTransactions_Working_New_Debug]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Joshua Kiracofe
-- Create date: 8/25/2014
-- Description:	Validates the Products in Store Transactions Working
-- =============================================
CREATE PROCEDURE [dbo].[prValidateProductsInStoreTransactions_Working_New_Debug]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 7417

begin try

DECLARE @ProcessID INT

SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobRunningID = 14


--update w set w.WorkingStatus = 1, ProcessID = @ProcessID
----select *
--from StoreTransactions_Working w
--inner join ProductIdentifiers i
--on ltrim(rtrim(w.UPC)) = ltrim(rtrim(i.IdentifierValue))
--and w.WorkingSource = 'POS'
--and w.WorkingStatus = -2
--and i.ProductIdentifierTypeID = 2
--and ProcessID in (Select ProcessID from JobProcesses where JobRunningID in (9,13))
--and RecordType = 0

--update w set w.WorkingStatus = 1, ProcessID = @ProcessID
----select *
--from StoreTransactions_Working w
--inner join ProductIdentifiers i
--on ltrim(rtrim(w.UPC)) = ltrim(rtrim(i.IdentifierValue))
--and w.WorkingSource = 'POS'
--and w.WorkingStatus = -2
--and i.ProductIdentifierTypeID = 8
--and ProcessID in (Select ProcessID from JobProcesses where JobRunningID in (9,13))
--and RecordType = 2

--update t set t.WorkingStatus = 1, ProcessID = @ProcessID
----Select *
--from [dbo].[StoreTransactions_Working] t
--inner join [dbo].[ProductIdentifiers] p
--on ltrim(rtrim(t.ItemSKUReported)) = ltrim(rtrim(p.Bipad))
--where t.workingstatus = -2
--and p.ProductIdentifierTypeID in (8) --UPC is type 2 bipad UPC is type 8
--and t.ProcessID in (Select ProcessID from JobProcesses where JobRunningID in (9,13))
--and t.RecordType = 2

select distinct StoreTransactionID, UPC, 
ProductCategoryIdentifier, BrandIdentifier, t.ChainID, StoreID, SupplierIdentifier,
c.AllowProductAddFromPOS, ItemSKUReported
into #tempStoreTransaction
--Select *
from [dbo].[StoreTransactions_Working] t join Chains c
on t.ChainID=c.ChainID
where WorkingStatus = 1
and WorkingSource in ('POS')
and t.ProcessID = @ProcessID


begin transaction

set @loadstatus = 2

select * 
from #tempStoreTransaction t
where AllowProductAddFromPOS=1

if(@@ROWCOUNT>0 and 1 = 2)

	Begin


	declare @rec cursor
	declare @UPC nvarchar(50)
	declare @StoreTransactionID int
	declare @productid int
	declare @productcategoryidentifier nvarchar(50)
	declare @brandidentifier nvarchar(50)
	declare @chainid int
	declare @storeidforsetup int
	declare @supplieridentifierforsetup nvarchar(50)
	declare @supplieridforsetup int
	declare @brandid int
	declare @productcategoryid int
	declare @singlerecordstatus smallint
	declare @itemskureported nvarchar(50)

	set @rec = CURSOR local fast_forward for

	select distinct 
	ltrim(rtrim(tmp.UPC)) as UPC, ProductCategoryIdentifier, BrandIdentifier, 
	ChainID, StoreID, SupplierIdentifier, ItemSKUReported--, StoreTransactionID
	from #tempStoreTransaction tmp
	where 1 = 1
	and ltrim(rtrim(tmp.UPC)) not in
	(
		select ltrim(rtrim(IdentifierValue)) 
		from [dbo].[ProductIdentifiers] 
		where ProductIdentifierTypeID in (2, 8)
	)




	--print 'two'

	open @rec

	fetch next from @rec into @UPC, @productcategoryidentifier,
								@brandidentifier,@chainid, @storeidforsetup, @supplieridentifierforsetup, @itemskureported  --,@StoreTransactionID
	if @@FETCH_STATUS = 0
		begin
			exec dbo.prSendEmailNotification_PassEmailAddresses 'Product Added by POS'
			,'Some POS records resulted in new products being added'
			,'DataTrue System', 0, 'datatrueit@icucsolutions.com; gilad.keren@icucsolutions.com'	
		end
		
	while @@FETCH_STATUS = 0
		begin
	--print 'three'
			set @singlerecordstatus = 1

			if LEN(@brandidentifier) > 0
				begin
					select @brandid = BrandID from Brands 
					where BrandIdentifier = @brandidentifier
					
					if @@ROWCOUNT < 1
						begin
							set @singlerecordstatus = -2
						end
				end
			else
				begin
						set @brandid = 0
				end

			if LEN(@productcategoryidentifier) > 0
				begin
					select @productcategoryid = ProductCategoryID
					from ProductCategories
					where ChainID = @chainid 
					and ProductCategoryName = @productcategoryidentifier
					
					if @@ROWCOUNT < 1
						begin
							select @productcategoryid = ProductCategoryID
							from ProductCategories
							where ChainID = 0 --default categories
							and ProductCategoryName = @productcategoryidentifier	
							
							if @@ROWCOUNT < 1
								begin
									set @singlerecordstatus = -2
								end
						end	
				end
			else
				begin
					set @productcategoryid = 0
				end


			if @singlerecordstatus = 1
				begin
				
				select @productid = Productid 
				from ProductIdentifiers 
				where IdentifierValue = @UPC 
				and ProductIdentifierTypeID In (2, 8)
				
				if @@ROWCOUNT < 1
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
			--print 'four'	
			
			--insert default ChainProductFactors record for new product
			--select * from ChainProductFactors where productid = 0
					INSERT INTO [DataTrue_Main].[dbo].[ChainProductFactors]
					   ([ChainID]
					   ,[ProductID]
					   ,[BrandID]
					   ,[BaseUnitsCalculationPerNoOfweeks]
					   ,[CostFromRetailPercent]
					   ,[BillingRuleID]
					   ,[ActiveStartDate]
					   ,[ActiveEndDate]
					   ,[LastUpdateUserID])
					SELECT @chainid
						  ,@productid
						  ,@brandid
						  ,[BaseUnitsCalculationPerNoOfweeks]
						  ,[CostFromRetailPercent]
						  ,[BillingRuleID]
						  ,[ActiveStartDate]
						  ,[ActiveEndDate]
						  ,@MyID
					  FROM [DataTrue_Main].[dbo].[ChainProductFactors]
					  where 1 = 1
					  and ChainID = @chainid
					  and productid = 0
					  
					INSERT INTO [dbo].[ProductIdentifiers]
					   ([ProductID]
					   ,[ProductIdentifierTypeID]
					   ,[OwnerEntityId]
					   ,[IdentifierValue]
					   ,[LastUpdateUserID])
					VALUES
					   (@productid
					   ,2
					   ,0 -- 0 is default entity
					   ,@UPC
					   ,@MyID)

					INSERT INTO [dbo].[ProductIdentifiers]
					   ([ProductID]
					   ,[ProductIdentifierTypeID]
					   ,[OwnerEntityId]
					   ,[IdentifierValue]
					   ,[LastUpdateUserID])
					VALUES
					   (@productid
					   ,8
					   ,0 -- 0 is default entity
					   ,@itemskureported
					   ,@MyID)
			           
					 INSERT INTO [dbo].[ProductBrandAssignments]
							   ([BrandID]
							   ,[ProductID]
							   ,[CustomOwnerEntityID]
							   ,[LastUpdateUserID])
						 VALUES
							   (@brandid
							   ,@productid
							   ,0
							   ,@MyID)

					INSERT INTO [dbo].[ProductCategoryAssignments]
							   ([ProductCategoryID]
							   ,[ProductID]
							   ,[CustomOwnerEntityID]
							   ,[LastUpdateUserID])
						 VALUES
							   (@productcategoryid
							   ,@productid
							   ,0
							   ,@MyID)  				  
					  
				end				  

				set @supplieridforsetup = null

				select @supplieridforsetup = datatruesupplierid 
				from Datatrue_EDI.dbo.EDI_SupplierCrossReference
				where ltrim(rtrim(cast(SupplierIdentifier as nvarchar))) = ltrim(rtrim(cast(@supplieridentifierforsetup as nvarchar)))
				--select @supplieridforsetup = supplierid from Suppliers where cast(SupplierIdentifier as nvarchar) = cast(@supplieridentifierforsetup as nvarchar)

				if @supplieridforsetup is null
					set @supplieridforsetup = 0
								  
				INSERT INTO [DataTrue_Main].[dbo].[StoreSetup]
						   ([ChainID]
						   ,[StoreID]
						   ,[ProductID]
						   ,[SupplierID]
						   ,[BrandID]
						   ,[InventoryRuleID]
						   ,[InventoryCostMethod]
						   ,[SunLimitQty]
						   ,[SunFrequency]
						   ,[MonLimitQty]
						   ,[MonFrequency]
						   ,[TueLimitQty]
						   ,[TueFrequency]
						   ,[WedLimitQty]
						   ,[WedFrequency]
						   ,[ThuLimitQty]
						   ,[ThuFrequency]
						   ,[FriLimitQty]
						   ,[FriFrequency]
						   ,[SatLimitQty]
						   ,[SatFrequency]
						   ,[RetailerShrinkPercent]
						   ,[SupplierShrinkPercent]
						   ,[ManufacturerShrinkPercent]
						   ,[ActiveStartDate]
						   ,[ActiveLastDate]
						   ,[SetupReportedToRetailerDate]
						   ,[FileName]
						   ,[Comments]
						   ,[LastUpdateUserID])
				SELECT @chainid
					  ,@storeidforsetup
					  ,@productid
					  ,@supplieridforsetup
					  ,@brandid
					  ,[InventoryRuleID]
					  ,[InventoryCostMethod]
					  ,[SunLimitQty]
					  ,[SunFrequency]
					  ,[MonLimitQty]
					  ,[MonFrequency]
					  ,[TueLimitQty]
					  ,[TueFrequency]
					  ,[WedLimitQty]
					  ,[WedFrequency]
					  ,[ThuLimitQty]
					  ,[ThuFrequency]
					  ,[FriLimitQty]
					  ,[FriFrequency]
					  ,[SatLimitQty]
					  ,[SatFrequency]
					  ,[RetailerShrinkPercent]
					  ,[SupplierShrinkPercent]
					  ,[ManufacturerShrinkPercent]
					  ,[ActiveStartDate]
					  ,[ActiveLastDate]
					  ,[SetupReportedToRetailerDate]
					  ,[FileName]
					  ,[Comments]
					  ,@MyID
				  FROM [DataTrue_Main].[dbo].[StoreSetup]
					where chainid = @chainid
					and storeid = 0
					and ProductID = 0
					and BrandID = 0
					and SupplierID = 0
								
	     
				end

				fetch next from @rec into @UPC, @productcategoryidentifier,
								@brandidentifier,@chainid, @storeidforsetup, @supplieridentifierforsetup, @itemskureported --,@StoreTransactionID
		end
		
	close @rec
	deallocate @rec

End

update t set t.ProductID = p.ProductID
from [dbo].[StoreTransactions_Working] t
inner join [dbo].[ProductIdentifiers] p
on ltrim(rtrim(t.UPC)) = ltrim(rtrim(p.IdentifierValue))
where t.workingstatus = 1
and p.ProductIdentifierTypeID in (8)
and t.RecordType = 2
and t.ProcessID = @ProcessID

update t set t.ProductID = p.ProductID
from [dbo].[StoreTransactions_Working] t
inner join [dbo].[ProductIdentifiers] p
on ltrim(rtrim(t.ItemSKUReported)) = ltrim(rtrim(p.Bipad))
where t.workingstatus = 1
and p.ProductIdentifierTypeID in (8) --UPC is type 2 bipad UPC is type 8
and t.ProductID is null
and t.ProcessID = @ProcessID
and t.RecordType = 2

update t set t.ProductID = p.ProductID
from [dbo].[StoreTransactions_Working] t
inner join [dbo].[ProductIdentifiers] p
on ltrim(rtrim(t.UPC)) = ltrim(rtrim(p.IdentifierValue))
where t.workingstatus = 1
and p.ProductIdentifierTypeID in (2)
and t.RecordType = 0
and t.ProcessID = @ProcessID

update t set t.WorkingStatus = -2
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.ProductID is null

if @@ROWCOUNT > 0
	begin

		--declare @errormessage varchar(4500)
		--declare @errorlocation varchar(255)

		set @errormessage = 'Unknown Product Identifiers/UPCs Found'
		set @errorlocation = 'prValidateProductsInStoreTransactions_Working'
		set @errorsenderstring = 'prValidateProductsInStoreTransactions_Working'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
	end

--20110930
update t set t.BrandID = p.BrandID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Brands] p
on ltrim(rtrim(t.BrandIdentifier)) = ltrim(rtrim(p.BrandIdentifier))
where t.BrandIdentifier is not null

update t set t.BrandID = 0
from [dbo].[StoreTransactions_Working] t
where t.workingstatus = 1
and t.workingsource = 'POS'
and t.BrandID is null
and (len(t.BrandIdentifier) < 1 or t.BrandIdentifier is null)
and t.ProcessID = @ProcessID


update t set t.WorkingStatus = -2
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.BrandID is null
and LEN(t.BrandIdentifier) > 0

if @@ROWCOUNT > 0
	begin

		--declare @errormessage varchar(4500)
		--declare @errorlocation varchar(255)

		set @errormessage = 'Unknown Brand Identifiers Found'
		set @errorlocation = 'prValidateProductsInStoreTransactions_Working'
		set @errorsenderstring = 'prValidateProductsInStoreTransactions_Working'
		
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
		
		set @loadstatus = -9999

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
			@job_name = 'Daily Move EDI to Main'

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Newspaper Process'
				,'Newspaper processing has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'datatrueit@icucsolutions.com; gilad.keren@icucsolutions.com'		
		
end catch
	


update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID, DateTimeLastUpdate = GETDATE()
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.ProductID is not null
and t.WorkingStatus = 1
and t.WorkingSource = 'POS'


END
GO
