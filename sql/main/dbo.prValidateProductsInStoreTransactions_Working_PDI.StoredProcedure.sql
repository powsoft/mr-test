USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateProductsInStoreTransactions_Working_PDI]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateProductsInStoreTransactions_Working_PDI]

as

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 7417

begin try
/*

select *
from StoreTransactions_Working w
where 1 = 1
and w.WorkingSource = 'POS'
and w.WorkingStatus = 1


*/
update w set w.WorkingStatus = -2
--select *
from StoreTransactions_Working w
where len(ltrim(rtrim(w.UPC))) < 1
and w.WorkingSource = 'POS'
and w.WorkingStatus = 1

update w set w.WorkingStatus = 1
--select *
from StoreTransactions_Working w
inner join ProductIdentifiers i
on ltrim(rtrim(w.UPC)) = ltrim(rtrim(i.IdentifierValue))
and w.WorkingSource = 'POS'
and w.WorkingStatus = -2
and i.ProductIdentifierTypeID = 2
and len(ltrim(rtrim(w.UPC))) = 12

update w set w.WorkingStatus = 1, UPC = ltrim(rtrim(w.RawProductIdentifier))
--select *
from StoreTransactions_Working w
inner join ProductIdentifiers i
on ltrim(rtrim(w.RawProductIdentifier)) = ltrim(rtrim(i.IdentifierValue))
and w.WorkingSource = 'POS'
and w.WorkingStatus = -2
and i.ProductIdentifierTypeID = 13
--and len(ltrim(rtrim(w.RawProductIdentifier))) = 12
and i.OwnerEntityId = w.ChainID

select distinct StoreTransactionID, UPC, 
ProductCategoryIdentifier, BrandIdentifier, t.ChainID, StoreID, SupplierIdentifier,
c.AllowProductAddFromPOS
into #tempStoreTransaction
--select *
--select count(*)
from [dbo].[StoreTransactions_Working] t join Chains c
on t.ChainID=c.ChainID
where WorkingStatus = 1
and WorkingSource in ('POS')
--and ChainID = 40393
--drop table #tempStoreTransaction
order by upc

begin transaction

set @loadstatus = 2

--/*
--select * from datatrue_EDI.dbo.EDI_SupplierCrossReference
--declare @MyID int set @MyID = 7417
/*
exec dbo.prSendEmailNotification_PassEmailAddresses 'StoreSetup Match Failure'
,'Some POS records failed the StoreSetup matching'
,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'

*/
select * 
from #tempStoreTransaction t
where AllowProductAddFromPOS=1

if(@@ROWCOUNT>0) and 1 = 2

	Begin

	declare @recsup cursor
	declare @supplieridentifiertoadd nvarchar(50)
	declare @suppliernametoadd nvarchar(255)
	declare @supplierentitytypeid int
	declare @newsupplierid int
	/*
	set @recsup = CURSOR local fast_forward FOR
		select ltrim(rtrim(supplieridentifier)), ltrim(rtrim(suppliername))
		from datatrue_EDI.dbo.EDI_SupplierCrossReference
		where ltrim(rtrim(supplieridentifier))  not in
		(select ltrim(rtrim(supplieridentifier)) from Suppliers)
		
	open @recsup

	fetch next from @recsup into @supplieridentifiertoadd, @suppliernametoadd

	if @@FETCH_STATUS = 0
		select @supplierentitytypeid = EntityTypeID from EntityTypes where EntityTypeName = 'Supplier'
		
	while @@FETCH_STATUS = 0
		begin
			INSERT INTO [DataTrue_Main].[dbo].[SystemEntities]
					   ([EntityTypeID]
					   ,[LastUpdateUserID])
				 VALUES
					   (@supplierentitytypeid
					   ,@MyID)
		
			set @newsupplierid = SCOPE_IDENTITY()
			
			INSERT INTO [DataTrue_Main].[dbo].[Suppliers]
					   ([SupplierID]
					   ,[SupplierName]
					   ,[SupplierIdentifier]
					   ,[SupplierDescription]
					   ,[ActiveStartDate]
					   ,[ActiveLastDate]
					   ,[LastUpdateUserID])
				 VALUES
					   (@newsupplierid
					   ,@suppliernametoadd
					   ,@supplieridentifiertoadd
					   ,''
					   ,'1/1/2011'
					   ,'12/31/2025'
					   ,@MyID)		
			
			fetch next from @recsup into @supplieridentifiertoadd, @suppliernametoadd	
		end
		
	close @recsup
	deallocate @recsup
	*/
	--select * from StoreTransactions_Working where ProductID is not null
	--select * from StoreTransactions_Working where workingstatus = 1
	--print 'one'

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

	set @rec = CURSOR local fast_forward for
	select distinct 
	ltrim(rtrim(tmp.UPC)), ProductCategoryIdentifier, BrandIdentifier, 
	ChainID, StoreID, SupplierIdentifier--, StoreTransactionID
	from #tempStoreTransaction tmp
	--inner join [dbo].[StoreTransactions_Working] t
	--on tmp.StoreTransactionID = t.StoreTransactionID
	where tmp.AllowProductAddFromPOS=1
	and ltrim(rtrim(tmp.UPC)) not in
	(
		select ltrim(rtrim(IdentifierValue)) 
		from [dbo].[ProductIdentifiers] 
		where ProductIdentifierTypeID = 2
	)




	--print 'two'
	/*
	set @rec = CURSOR local fast_forward for
	select tmp.UPC, tmp.StoreTransactionID
	from #tempStoreTransaction tmp
	inner join [dbo].[StoreTransactions_Working] t
	on tmp.StoreTransactionID = t.StoreTransactionID
	where t.ProductID is null
	*/

	open @rec

	fetch next from @rec into @UPC, @productcategoryidentifier,
								@brandidentifier,@chainid, @storeidforsetup, @supplieridentifierforsetup --,@StoreTransactionID
	if @@FETCH_STATUS = 0
		begin
			exec dbo.prSendEmailNotification_PassEmailAddresses 'Product Added by POS'
			,'Some POS records resulted in new products being added'
			,'DataTrue System', 0, 'charlie.clark@icontroldsd.com; mandeep@amebasoftwares.com'	
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
				and ProductIdentifierTypeID = 2
				
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
					   ,2 --UPC is type 2
					   ,0 -- 0 is default entity
					   ,@UPC
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
	/*
			else
				begin
					--update record with issue
					update [dbo].[StoreTransactions_Working] 
					set Workingstatus = -2 where StoreTransactionID = @StoreTransactionID
					--log exception for invalid brand or category	
					
					set @errormessage = 'Unknown Brand or ProductCategory Identifiers Found'
					set @errorlocation = 'prValidateProductsInStoreTransactions_Working'
					set @errorsenderstring = 'prValidateProductsInStoreTransactions_Working'
					
					exec dbo.prLogExceptionAndNotifySupport
					2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
					,@errorlocation
					,@errormessage
					,@errorsenderstring
					,@MyID			
				end
				*/
				fetch next from @rec into @UPC, @productcategoryidentifier,
								@brandidentifier,@chainid, @storeidforsetup, @supplieridentifierforsetup --,@StoreTransactionID
		end
		
	close @rec
	deallocate @rec

End



--select t.StoreIdentifier, s.StoreIdentifier, s.StoreID, c.ChainID
update t set t.ProductID = p.ProductID, t.brandid = 0, t.WorkingStatus = 2
--from [dbo].[StoreTransactions_Working] t
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[ProductIdentifiers] p
on ltrim(rtrim(t.UPC)) = ltrim(rtrim(p.IdentifierValue))
and p.ProductIdentifierTypeID = 2
and len(ltrim(rtrim(t.UPC))) = 12
------where t.workingstatus = 1
------and t.workingsource = 'POS'
------and p.ProductIdentifierTypeID = 2 --UPC is type 2
--and ltrim(rtrim(t.UPC)) not in
--(
--	select ltrim(rtrim(UPC)) 
--	from dbo.Util_DisqualifiedUPCbySupplier
--	where SupplierID in (41440)
--)

update w set w.ProductID = i.ProductID, w.brandid = 0, w.WorkingStatus = 2
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] w
on tmp.StoreTransactionID = w.StoreTransactionID
inner join ProductIdentifiers i
on ltrim(rtrim(w.RawProductIdentifier)) = ltrim(rtrim(i.IdentifierValue))
--and w.WorkingSource = 'POS'
--and w.WorkingStatus = -2
and i.ProductIdentifierTypeID = 13
--and len(ltrim(rtrim(w.RawProductIdentifier))) = 12
and i.OwnerEntityId = w.ChainID
and w.ProductID is null

----------update t set t.ProductID = p.ProductID, t.brandid = 0, t.WorkingStatus = 2
----------from #tempStoreTransaction tmp
----------inner join [dbo].[StoreTransactions_Working] t
----------on tmp.StoreTransactionID = t.StoreTransactionID
----------inner join [dbo].[ProductIdentifiers] p
----------on ltrim(rtrim(t.UPC)) = ltrim(rtrim(p.IdentifierValue))
------------where t.workingstatus = -2
------------and t.workingsource = 'POS'
----------and p.ProductIdentifierTypeID = 2 --UPC is type 2
------------and ltrim(rtrim(t.UPC)) not in
------------(
------------	select ltrim(rtrim(UPC)) 
------------	from dbo.Util_DisqualifiedUPCbySupplier
------------	where SupplierID in (41440)
------------)


	update t set t.ProductID = null 
	from [dbo].[StoreTransactions_Working] t
	inner join dbo.Util_DisqualifiedUPCbySupplier s
	on ltrim(rtrim(t.UPC)) = ltrim(rtrim(s.UPC))
	and  t.workingstatus = 1
	and t.workingsource = 'POS'
	and t.SupplierID in (41440)

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

/*
update t set t.BrandID = p.BrandID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[ProductBrandAssignments] p
on t.ProductID = p.ProductID
where p.CustomOwnerEntityID = 0
and t.BrandIdentifier is null
*/
--20110930

/*
update t set t.SupplierID = 0
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.SupplierID is null
*/

update t set t.BrandID = 0
from [dbo].[StoreTransactions_Working] t
--from #tempStoreTransaction tmp
--inner join [dbo].[StoreTransactions_Working] t
--on tmp.StoreTransactionID = t.StoreTransactionID
where t.workingstatus = 1
and t.workingsource = 'POS'
and t.BrandID is null
and (len(t.BrandIdentifier) < 1 or t.BrandIdentifier is null)


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

/*20110615
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
/*20110615
update t set UnitCost = ISNULL(ReportedUnitCost, 0.00)
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.UnitCost is null
*/
/*
--update RuleCost with ReportedCost when setupcost is null
update t set t.RuleCost = t.ReportedCost
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.SetupCost is null

--update RuleRetail with ReportedRetail when setupRetail is null
update t set t.RuleRetail = t.ReportedRetail
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.SetupRetail is null
*/

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
			@job_name = 'DailyPOSBilling_THIS_IS_CURRENT_ONE'

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Daily Billing Job Stopped'
				,'Retailer and supplier invoicing has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;edi@icontroldsd.com'		
		
end catch
	


update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID
--from [dbo].[StoreTransactions_Working] t
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
and t.ProductID is not null
--where t.ProductID is not null
--and t.WorkingStatus = 1
--and t.WorkingSource = 'POS'


/*
select * from chains

select *
--update w set w.UPC = '0' + ltrim(rtrim(RawProductIdentifier))
--update w set w.UPC = ltrim(rtrim(RawProductIdentifier))
from storetransactions_working w
where 1 = 1
and len(ltrim(rtrim(RawProductIdentifier))) = 12
and workingstatus = 1
and Banner = 'DG'

select len(rawproductidentifier), count(storetransactionid)
from storetransactions_working w
where workingstatus = 1
group by len(rawproductidentifier)
order by len(rawproductidentifier)

select *
--select count(*)
--update w set w.productid = i.productid, w.brandid = 0, w.workingstatus = 2
from storetransactions_working w
inner join productidentifiers i
on chainid = 63612
and ltrim(rtrim(UPC)) = ltrim(rtrim(i.identifiervalue))
and i.productidentifiertypeid = 2
and len(ltrim(rtrim(UPC))) = 12
and workingstatus = 1
and w.productid is null

select *
--update w set w.upc = '0' + ltrim(rtrim(RawProductIdentifier)), w.productid = i.productid, w.brandid = 0, w.workingstatus = 2
from storetransactions_working w
inner join productidentifiers i
on '0' + ltrim(rtrim(RawProductIdentifier)) = ltrim(rtrim(i.identifiervalue))
and i.productidentifiertypeid = 8
and len(ltrim(rtrim(RawProductIdentifier))) = 11
and workingstatus = 1
and w.productid is null


drop table #tempMatch

select storetransactionid as tid
,ltrim(rtrim(RawProductIdentifier)) + dbo.fngetcheckdigit(ltrim(rtrim(RawProductIdentifier))) as UPC
,cast(null as int) as Productid
into #tempMatch
from storetransactions_working w
where 1 = 1
and len(ltrim(rtrim(RawProductIdentifier))) = 11
and workingstatus = 1
and w.productid is null

select *
--select distinct len(UPC)
--select count(*)
--update w set w.productid = i.productid
--, w.brandid = 0, w.workingstatus = 2
from #tempMatch w
inner join productidentifiers i
on ltrim(rtrim(UPC)) = ltrim(rtrim(i.identifiervalue))
and i.productidentifiertypeid = 2

select *
--update w set w.productid = t.productid, w.upc = t.upc, w.brandid = 0, w.workingstatus = 2
from #tempMatch t
inner join storetransactions_working w
on t.tid = w.storetransactionid
and w.productid is null
and t.productid is not null


select *
--select distinct len(UPC)
--select count(*)
--update w set w.upc = ltrim(rtrim(RawProductIdentifier)) + dbo.fngetcheckdigit(ltrim(rtrim(RawProductIdentifier))), w.productid = i.productid, w.brandid = 0, w.workingstatus = 2
from #tempMatch w
inner join productidentifiers i
on ltrim(rtrim(UPC)) = ltrim(rtrim(i.identifiervalue))
and i.productidentifiertypeid = 8

select *
--update w set w.upc = ltrim(rtrim(RawProductIdentifier)) + dbo.fngetcheckdigit(ltrim(rtrim(RawProductIdentifier))), w.productid = i.productid, w.brandid = 0, w.workingstatus = 2
from storetransactions_working w
inner join productidentifiers i
on ltrim(rtrim(RawProductIdentifier)) + dbo.fngetcheckdigit(ltrim(rtrim(RawProductIdentifier))) = ltrim(rtrim(i.identifiervalue))
and i.productidentifiertypeid = 8
and len(ltrim(rtrim(RawProductIdentifier))) = 11
and workingstatus = 1
and w.productid is null

select *
--select count(*)
--update w set w.upc = '0' + ltrim(rtrim(RawProductIdentifier)), w.productid = i.productid, w.brandid = 0, w.workingstatus = 2
from storetransactions_working w
inner join productidentifiers i
on '0' + ltrim(rtrim(RawProductIdentifier)) = ltrim(rtrim(i.identifiervalue))
and i.productidentifiertypeid = 2
and len(ltrim(rtrim(RawProductIdentifier))) = 11
and workingstatus = 1
and w.productid is null

select count(*)
--select *
--select distinct chainid, chainidentifier, rawproductidentifier
--select chainid, upc, rawproductidentifier, count(storetransactionid)
from storetransactions_working w
where 1 = 1
and workingstatus = 1
and w.productid is null
and chainid <> 40393
group by chainid, upc, rawproductidentifier
order by count(storetransactionid) desc

select *
--update w set w.upc = ltrim(rtrim(RawProductIdentifier)) + dbo.fngetcheckdigit(ltrim(rtrim(RawProductIdentifier))), w.productid = i.productid, w.brandid = 0, w.workingstatus = 2
from storetransactions_working w
inner join productidentifiers i
on ltrim(rtrim(RawProductIdentifier)) + dbo.fngetcheckdigit(ltrim(rtrim(RawProductIdentifier))) = ltrim(rtrim(i.identifiervalue))
and i.productidentifiertypeid = 2
and len(ltrim(rtrim(RawProductIdentifier))) = 11
and workingstatus = 1

select *
--select distinct chainid, chainidentifier, rawproductidentifier
--update w set w.upc = ltrim(rtrim(RawProductIdentifier)) + dbo.fngetcheckdigit(ltrim(rtrim(RawProductIdentifier)))
from storetransactions_working w
where 1 = 1
and workingstatus = 1
and w.productid is null
--and left(ltrim(rtrim(RawProductIdentifier)), 1) = '7'
and len(ltrim(rtrim(RawProductIdentifier))) = 11
and len(upc) < 1

select *
--update w set w.productid = i.productid, w.brandid = 0, w.workingstatus = 2
from storetransactions_working w
inner join productidentifiers i
on ltrim(rtrim(UPC)) = ltrim(rtrim(i.identifiervalue))
and i.productidentifiertypeid = 2
and w.productid is null
and workingstatus = 1

select *
--update w set w.upc = ltrim(rtrim(RawProductIdentifier)), w.productid = i.productid, w.brandid = 0, w.workingstatus = 2
from storetransactions_working w
inner join productidentifiers i
on ltrim(rtrim(RawProductIdentifier))  = ltrim(rtrim(i.identifiervalue))
and i.productidentifiertypeid = 2
and w.productid is null
and workingstatus = 1

select *
--update w set w.upc = ltrim(rtrim(RawProductIdentifier)), w.productid = i.productid, w.brandid = 0, w.workingstatus = 2
from storetransactions_working w
inner join productidentifiers i
on ltrim(rtrim(RawProductIdentifier)) = ltrim(rtrim(i.identifiervalue))
and i.productidentifiertypeid = 8
and w.productid is null
and workingstatus = 1
*/









return
GO
