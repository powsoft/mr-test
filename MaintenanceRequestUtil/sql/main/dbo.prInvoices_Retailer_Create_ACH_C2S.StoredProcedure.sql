USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoices_Retailer_Create_ACH_C2S]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Batch submitted through debugger: SQLQuery191.sql|7|0|C:\Users\SQLAdmin\AppData\Local\Temp\3\~vsC251.sql
CREATE procedure [dbo].[prInvoices_Retailer_Create_ACH_C2S]
@billingcontrolfrequency nvarchar(50)='DAILY'--,
--@numberofperiodstorun smallint=1
as
/*

exec [dbo].[prInvoices_Retailer_Create_ACH_C2S]

prInvoices_Retailer_Create_ACH 'DAILY'
update InvoiceDetails set RetailerInvoiceId = null, recordstatus = 0 where Invoicedetailtypeid = 7
truncate table datatrue_EDI.dbo.InvoicesRetailer
truncate table datatrue_EDI.dbo.InvoiceDetails
truncate table datatrue_EDI.dbo.InvoicesSupplier
select * from billingcontrol
drop table #tempStoreSetupProducts
select distinct billingruleid from chainproductfactors where chainid = 44285
update chainproductfactors set billingruleid = 2 where chainid = 44285

*/
--declare @billingcontrolfrequency nvarchar(50) set @billingcontrolfrequency = 'DAILY' 
declare @rec cursor
declare @recstore cursor
declare @recsupplier cursor
declare @storeid int
declare @supplierid int
declare @currentdatetime datetime
declare @billingcontrolid int
declare @entityidtoinvoice int
declare @billingcontrolday tinyint
declare @billingcontrolclosingdelay smallint
declare @productsubgrouptype nvarchar(50)
declare @productsubgroupid int
declare @productcount int
--declare @productsuperset BillPOSProductIDAndBrandIDTable
declare @needtoinvoice bit
declare @invoiceheaderid int
declare @supplierinvoiceheaderid int
declare @invoicetype tinyint --0=original; 1=rebill(adj)
declare @invoiceseparation tinyint
declare @daystoincludebeforebillingperiodenddate smallint
declare @nextbillingperiodenddatetime datetime
declare @billingperiodstartdatetime datetime
declare @billingperiodenddatetime datetime
declare @nextbillingperiodrundatetime datetime
declare @newnextbillingperiodenddatetime datetime
declare @numberofperiodstorun smallint
declare @numberofperiodstoruncalc decimal(8,2)
declare @numberofperiodsrun smallint
declare @numberofpastdaystorebill int
declare @dummycount as int
declare @dummyerrorcatch tinyint
declare @PutCreditsOnSeparateInvoice nvarchar(10)
declare @isadjustmentinvoice tinyint
declare @separatecredits bit

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @MyID int
set @MyID = 24135

DECLARE @rownumb INT
DECLARE @source VARCHAR(255)
SET @source = '[dbo].[prInvoices_Retailer_Create_ACH]'

DECLARE @msgPrint VARCHAR(500)

DECLARE @msg_audit VARCHAR(512)

--===============================
EXEC dbo.[Audit_Log_SP] 'STEP 000 ENTRY POINT =>',@source

/*
UPDATE [DataTrue_Main].[dbo].[BillingControl]
   SET [BillingControlNumberOfPastDaysToRebill] = 30 --DATEDIFF(day,'2/15/2012',getdate())
      ,[InvoiceSeparation] = 4
      ,[LastBillingPeriodEndDateTime] =  cast(DATEADD(day, -2, getdate()) as date)
      ,[NextBillingPeriodEndDateTime] = cast(DATEADD(day, 1, getdate()) as date)
      ,[NextBillingPeriodRunDateTime] =  cast(getdate() as date)
      --select * from  [DataTrue_Main].[dbo].[BillingControl]
 WHERE BillingControlID in (54)
 and BillingControlFrequency = 'DAILY'
*/ 
/*

 select * from [DataTrue_Main].[dbo].[BillingControl] where BillingControlID in (54)
 
*/
--*/

set @currentdatetime = GETDATE()

--- STEP 1
EXEC dbo.[Audit_Log_SP] 'STEP 001 => UPDATE [DataTrue_Main].[dbo].[BillingControl]', @source  

set @rec = CURSOR local fast_forward for
	select BillingControlID, EntityIDToInvoice, BillingControlDay, BillingControlClosingDelay,
		ProductSubGroupType, ProductSubGroupID, NextBillingPeriodRunDateTime, 
		InvoiceSeparation, BillingControlNumberOfPastDaysToRebill, NextBillingPeriodEndDateTime, SeparateCredits
	from 
	billingcontrol c
	inner join 
	systementities s
	on c.EntityIDToInvoice = s.EntityID
	where s.EntityTypeID = 2
	and IsActive = 1
	and ISACH = 1
	--and nextbillingperiodrundatetime <= getdate() --@currentdatetime
	--and billingcontrolfrequency = 'Weekly' --@billingcontrolfrequency
	and nextbillingperiodrundatetime <= @currentdatetime
	and billingcontrolfrequency = @billingcontrolfrequency
	

open @rec

fetch next from @rec 
into @billingcontrolid
,@EntityIDToInvoice
,@billingcontrolday
,@billingcontrolclosingdelay
,@productsubgrouptype
,@productsubgroupid
,@nextbillingperiodrundatetime
,@invoiceseparation
,@numberofpastdaystorebill
,@nextbillingperiodenddatetime
,@separatecredits

WHILE @@FETCH_STATUS = 0
BEGIN
BEGIN TRY
	--=========================================================== BEGIN TRY
	INSERT INTO [DataTrue_Main].[dbo].[ChainProductFactors]
	(
		 [ChainID]
		,[ProductID]
		,[BrandID]
		,[BaseUnitsCalculationPerNoOfweeks]
		,[CostFromRetailPercent]
		,[BillingRuleID]
		,[IncludeDollarDiffDetails]
		,[ActiveStartDate]
		,[ActiveEndDate]
		,[LastUpdateUserID]
	)
	SELECT 
		 @EntityIDToInvoice
		,ProductId
		,0
		,17
		,75
		,2
		,1
		,'2000-01-01 00:00:00'
		,'12/31/2025'
		,2
	FROM 
		Products
	WHERE 
		ProductID IN		(SELECT DISTINCT productid FROM storetransactions WHERE ChainID = @EntityIDToInvoice)
	AND ProductID NOT IN	(SELECT productid FROM ChainProductFactors WHERE ChainID = @EntityIDToInvoice) 		
		
	set @needtoinvoice = 0
	set @numberofperiodsrun = 0

	if @separatecredits = 1
	begin
		set @PutCreditsOnSeparateInvoice = 'YES'				
	end
	else
	begin
		set @PutCreditsOnSeparateInvoice = 'NO'				
	end
		
	--determine billing start date and billing end date
	if upper(@billingcontrolfrequency) = 'DAILY'
	begin
		set @billingperiodstartdatetime = @nextbillingperiodenddatetime 
		set @billingperiodenddatetime	= @nextbillingperiodenddatetime
		set @numberofperiodstorun = @numberofpastdaystorebill 
	end
	
	if upper(@billingcontrolfrequency) = 'WEEKLY'
	begin
		set @daystoincludebeforebillingperiodenddate = -6
		set @billingperiodstartdatetime = dateadd(day,@daystoincludebeforebillingperiodenddate,@nextbillingperiodenddatetime)
		set @billingperiodenddatetime = @nextbillingperiodenddatetime 
					--datediff(day, -1*@billingcontrolclosingdelay, @nextbillingperiodrundatetime)
		set @numberofperiodstoruncalc = @numberofpastdaystorebill/7 
		if @numberofperiodstoruncalc < 1
		begin
			set @numberofperiodstorun = 1
		end
		else
		begin
			set @numberofperiodstorun = CAST(@numberofperiodstoruncalc as int)
		end
	end
	
	if upper(@billingcontrolfrequency) = 'BIWEEKLY'
	begin
		set @daystoincludebeforebillingperiodenddate = -13
		set @billingperiodstartdatetime = dateadd(day,@daystoincludebeforebillingperiodenddate,@nextbillingperiodrundatetime)
		set @billingperiodenddatetime = @nextbillingperiodenddatetime
	end
	
	if upper(@billingcontrolfrequency) = 'MONTHLYCALENDAR' --assumes end date will be last day of the calendar month
	begin
		set @billingperiodstartdatetime = cast(month(@nextbillingperiodenddatetime) as varchar(2)) + '/1/' + cast(year(@nextbillingperiodenddatetime) as varchar(4))
		set @billingperiodenddatetime = @nextbillingperiodenddatetime
	end	
	--*****************************temp for testing******************************
	--set @billingperiodstartdatetime = '6/1/2011'
	--set @billingperiodenddatetime = '7/1/2011'
	--***************************************************************************

	--print @billingperiodstartdatetime
	--print @billingperiodenddatetime
	--print @numberofperiodsrun
	--print @numberofperiodstorun

	--get product and brand and billingrule from storesetup
	--*************************************************************
	--select distinct chainid from storesetup
	--select *  from storesetup where chainid = 7608

	--IF EXISTS (SELECT * FROM sys.tables WHERE name like '%#tempStoreSetupProducts%')
	--	DROP TABLE #tempStoreSetupProducts
	
	--if exists(select null from #tempStoreSetupProducts)
	--	drop table #tempStoreSetupProducts
	begin try
		DROP TABLE #tempStoreSetupProducts
	end try
	begin catch
		set @dummyerrorcatch = 0
	end catch	
	
	SELECT DISTINCT ProductID, BrandID, BillingRuleID--, 
	--RetailerShrinkPercent, SupplierShrinkPercent, ManufacturerShrinkPercent
	INTO 
		#tempStoreSetupProducts 
	FROM 
		ChainProductFactors
	--from StoreSetup
	WHERE 
		ChainID = @EntityIDToInvoice

	IF @@ROWCOUNT < 1
		GOTO NextBilling	
						
	--select * from #tempStoreSetupProducts
	--IF EXISTS (SELECT * FROM sys.tables WHERE name like '%#tempProductsToInvoice%')
	BEGIN TRY
		DROP TABLE #tempProductsToInvoice
	END TRY
	BEGIN CATCH
		set @dummyerrorcatch = 0
	END CATCH
	--if exists(select null from #tempProductsToInvoice)
	--drop table #tempProductsToInvoice				

	SELECT 
		* 
	INTO 
		#tempProductsToInvoice 
	FROM 
		#tempStoreSetupProducts
	--select * into Import.dbo.ztmpInvoiceingResearch  from #tempStoreSetupProducts
	--select * from #tempProductsToInvoice				
	--select * from #tempStoreSetupProducts
	--print @productsubgrouptype					
	--get any subgroup limits and apply
	--*************************************************************
	if (@productsubgrouptype IS NOT NULL) AND (LEN(@productsubgrouptype) > 0)
	begin
		--print '1'
		if @productsubgrouptype IN ('INCLUDEONETOPPRODUCTCATEGORY','EXCLUDEONETOPPRODUCTCATEGORY')
		begin
			--print '2'
			declare @tophierarchyidtostring nvarchar(50)

			select @tophierarchyidtostring = HierarchyID.ToString()
			from ProductCategories
			where ProductCategoryID = @productsubgroupid

			select a.productid into #tempproductsinacategory 
			from ProductCategories c
			inner join ProductCategoryAssignments a
			on c.ProductCategoryID = a.ProductCategoryID
			where left(c.HierarchyID.ToString(),3) = @tophierarchyidtostring
			
			
			if @productsubgrouptype = 'INCLUDEONETOPPRODUCTCATEGORY'
			begin
				--print '3'
				delete 
				from #tempProductsToInvoice
				where ProductID not in
				(select ProductID from #tempproductsinacategory)
			end
			
			if @productsubgrouptype = 'EXCLUDEONETOPPRODUCTCATEGORY'
			begin
			--print '4'
				delete 
				from #tempProductsToInvoice
				where ProductID in
				(select ProductID from #tempproductsinacategory)										
			end
		end							
	end
		
	--else
	--	begin
			--select * into #tempProductsToInvoice 
			--from #tempStoreSetupProducts
	--	end					
	WHILE (@numberofperiodsrun < @numberofperiodstorun)
	BEGIN			
		--begin transaction
		--print '2'									
		SET @msgPrint = 'start:' + CONVERT(varchar(30),@billingperiodstartdatetime) + ' == ' + 'end:' + CONVERT(varchar(30),@billingperiodenddatetime) + ' == '+ 'periodsrun:' + CONVERT(varchar(30),@numberofperiodsrun) + ' == '+ 'periodsrun:' + CONVERT(varchar(30),@numberofperiodstorun)
		PRINT @msgPrint
		EXEC dbo.[Audit_Log_SP] @msgPrint, @source 
		
		--determine if original(0) or rebill(1) for the period
		
		set @invoicetype = 0
		
		select @dummycount = COUNT(RetailerInvoiceID) 
		from InvoicesRetailer
		where ChainID = @entityidtoinvoice
		and cast(InvoicePeriodStart as DATE) = cast(@billingperiodstartdatetime as date)
		and cast(InvoicePeriodEnd as DATE) = cast(@billingperiodenddatetime as date)
		
		
		if @dummycount > 0
			set @invoicetype = 1
		else
			set @invoicetype = 0
		
		--select * from #tempProductsToInvoice				
		--Any Rule 1/POS only products detailtypeid 1
		--select @productcount = COUNT(ProductID) from #tempProductsToInvoice where BillingRuleID = 1 --POS Only
		if @invoicetype = 0
		begin
			update d set d.RetailerInvoiceID = -1 
			from InvoiceDetails d
			inner join #tempProductsToInvoice t
			on d.ProductID = t.ProductID 
			and d.BrandID = t.BrandID
			where d.ChainID = @EntityIDToInvoice
			and t.BillingRuleID in (1,3)
			and d.InvoiceDetailTypeID in (1) --,7) --change here wait --POS Only
			and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
			and d.RetailerInvoiceID is null
			--change here wait
			--and LTRIM(rtrim(d.SupplierIdentifier)) <> '0665638590000'
			and LTRIM(rtrim(d.Banner)) <> 'SS'
			
			--- STEP 2
			--EXEC dbo.[Audit_Log_SP] 'STEP 002 => UPDATE #1 [DataTrue_Main].[dbo].[InvoiceDetails] : RetailerInvoiceID = -1', @source 
		end
		else
		begin
			update d set d.RetailerInvoiceID = -1 
			from InvoiceDetails d
			inner join #tempProductsToInvoice t
			on d.ProductID = t.ProductID 
			and d.BrandID = t.BrandID
			where d.ChainID = @EntityIDToInvoice
			and t.BillingRuleID in (1,3)
			and d.InvoiceDetailTypeID in (1) --,7) --change here wait ,7) --POS Only
			and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
			and d.RetailerInvoiceID is null
			--change here wait
			--and LTRIM(rtrim(d.SupplierIdentifier)) <> '0665638590000'
			and LTRIM(rtrim(d.Banner)) <> 'SS'
			
			--- STEP 3
			--EXEC dbo.[Audit_Log_SP] 'STEP 003 => UPDATE #2 [DataTrue_Main].[dbo].[InvoiceDetails] : RetailerInvoiceID = -1', @source 
			
		end
		if @@rowcount > 0
		begin
			set @needtoinvoice = 1
		end

		--Any Rule 2/SUP + Shrink products detailtypeid 2 or 3
		update 
			d 
		set 
			d.RetailerInvoiceID = -1 
		from 
			InvoiceDetails d
			inner join 
			#tempProductsToInvoice t
				on 
					d.ProductID = t.ProductID 
				and d.BrandID = t.BrandID
		where 
			d.ChainID = @EntityIDToInvoice
		and t.BillingRuleID in (2)
		and d.InvoiceDetailTypeID in (2,3,8,9)
		and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
		and d.RetailerInvoiceID is null
		
		--- STEP 4
		--EXEC dbo.[Audit_Log_SP] 'STEP 004 => UPDATE #3 [DataTrue_Main].[dbo].[InvoiceDetails] : RetailerInvoiceID = -1', @source 

		
		if @@rowcount > 0
		begin
			set @needtoinvoice = 1
		end

		--Any Rule 2/SUP + Shrink products detailtypeid 2 or 3
		update d set d.RetailerInvoiceID = -1 
		from 
			InvoiceDetails d
			-------------	
			inner join 
			-------------
			#tempProductsToInvoice t
				on 
					d.ProductID = t.ProductID 
				and d.BrandID = t.BrandID
		where 
			d.ChainID = @EntityIDToInvoice
		and t.BillingRuleID in (3)
		and d.InvoiceDetailTypeID in (3,4,9) 
		and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
		and d.RetailerInvoiceID is null
		
		--- STEP 5
		--EXEC dbo.[Audit_Log_SP] 'STEP 005 => UPDATE #4 [DataTrue_Main].[dbo].[InvoiceDetails] : RetailerInvoiceID = -1', @source 
		
		if @@rowcount > 0
		begin
			set @needtoinvoice = 1
		end
						
		if @needtoinvoice = 1
		begin
				if @invoiceseparation = 0
				begin --@invoiceseparation = 0
					
						set @invoiceheaderid = null
						
						if upper(@PutCreditsOnSeparateInvoice) = 'YES'
							begin
							
							
								INSERT INTO [DataTrue_Main].[dbo].[InvoicesRetailer]
										   ([ChainID]
										   ,[InvoicePeriodStart]
										   ,[InvoicePeriodEnd]
										   ,[OriginalAmount]
										   ,[InvoiceTypeID]
										   ,[OpenAmount]
										   ,[LastUpdateUserID]
										   ,[InvoiceStatus])
									 select @EntityIDToInvoice
										   ,@billingperiodstartdatetime
										   ,@billingperiodenddatetime
										   ,SUM(TotalCost)
										   ,@invoicetype
										   ,SUM(TotalCost)
										   ,@MyID
										   ,1
										from InvoiceDetails
										where ChainID = @entityidtoinvoice
										and RetailerInvoiceID = -1
										and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
										Group by Saledate
										having Sum(TotalCost) < 0
										
										set @invoiceheaderid = SCOPE_IDENTITY()
										
										update d set RetailerInvoiceID = @invoiceheaderid
										,Recordstatus = 4
										from InvoiceDetails d	
										inner join 
										(
											select productid, brandid, SaleDate
											from InvoiceDetails
											where ChainID = @entityidtoinvoice
											and RetailerInvoiceID = -1
											and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
											Group by productid, brandid, SaleDate
											having Sum(TotalCost) < 0																							
										) c
										on d.productid = c.productid and d.brandid = c.brandid and d.saledate = c.saledate
										where ChainID = @entityidtoinvoice
										and RetailerInvoiceID = -1
										and d.SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
										
										--- STEP 6
										EXEC dbo.[Audit_Log_SP] 'STEP 006 => INSERT [InvoicesRetailer] : UPDATE DETAILs #1', @source 

							end
						
						INSERT INTO [DataTrue_Main].[dbo].[InvoicesRetailer]
								   ([ChainID]
								   ,[InvoicePeriodStart]
								   ,[InvoicePeriodEnd]
								   ,[OriginalAmount]
								   ,[InvoiceTypeID]
								   ,[OpenAmount]
								   ,[LastUpdateUserID]
								   ,[InvoiceStatus])
							 select @EntityIDToInvoice
								   ,@billingperiodstartdatetime
								   ,@billingperiodenddatetime
								   ,SUM(TotalCost)
								   ,@invoicetype
								   ,SUM(TotalCost)
								   ,@MyID
								   ,1
								from InvoiceDetails
								where ChainID = @entityidtoinvoice
								and RetailerInvoiceID = -1
								and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
								
								
								set @invoiceheaderid = SCOPE_IDENTITY()
								
								update d set RetailerInvoiceID = @invoiceheaderid
								,Recordstatus = 4
								from InvoiceDetails d
								where ChainID = @entityidtoinvoice
								and RetailerInvoiceID = -1
								and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
								
								--- STEP 7
								EXEC dbo.[Audit_Log_SP] 'STEP 007 => INSERT [InvoicesRetailer] : UPDATE DETAILs #2', @source 

								
					end
				else
				begin
					if @invoiceseparation = 1 --by store
					begin
						set @recstore = 
						CURSOR local fast_forward FOR
						SELECT 
							DISTINCT StoreID
						FROM 
							InvoiceDetails
						WHERE 
							ChainID = @entityidtoinvoice
						and RetailerInvoiceID = -1
						and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
						
						OPEN @recstore
						
						FETCH NEXT FROM @recstore into @storeid
									
						WHILE @@FETCH_STATUS = 0
						BEGIN
							--**************************************************************************************************													
							set @invoiceheaderid = null
											
							IF UPPER(@PutCreditsOnSeparateInvoice) = 'YES'
							BEGIN
												
								INSERT INTO [DataTrue_Main].[dbo].[InvoicesRetailer]
								(
									 [ChainID]
									,[InvoicePeriodStart]
									,[InvoicePeriodEnd]
									,[OriginalAmount]
									,[InvoiceTypeID]
									,[OpenAmount]
									,[LastUpdateUserID]
									,[InvoiceStatus]
								)
								SELECT 
									 @EntityIDToInvoice
									,@billingperiodstartdatetime
									,@billingperiodenddatetime
									,SUM(TotalCost)
									,@invoicetype
									,SUM(TotalCost)
									,@MyID
									,1
								FROM 
									InvoiceDetails
								WHERE 
									ChainID = @entityidtoinvoice
								and StoreID = @storeid
								and RetailerInvoiceID = -1
								and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
								GROUP BY 
									Saledate
								HAVING 
									SUM(TotalCost) < 0
															
								SET @invoiceheaderid = SCOPE_IDENTITY()
								
								UPDATE d 
								SET 
									 RetailerInvoiceID = @invoiceheaderid
									,Recordstatus = 4
								FROM 
									InvoiceDetails d																		
									------------	
									INNER JOIN 
									------------
									(
										select 
											productid, brandid, SaleDate
										from 
											InvoiceDetails
										where 
											ChainID = @entityidtoinvoice
										and StoreID = @storeid
										and RetailerInvoiceID = -1
										and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
										Group by 
											productid, brandid, SaleDate
										having 
											Sum(TotalCost) < 0																							
									) c
								on d.productid = c.productid and d.brandid = c.brandid and d.saledate = c.saledate													
								where ChainID = @entityidtoinvoice
								and StoreID = @storeid
								and RetailerInvoiceID = -1
								and d.SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
								
							END --UPPER(@PutCreditsOnSeparateInvoice) = 'YES'
												
							INSERT INTO [DataTrue_Main].[dbo].[InvoicesRetailer]
							(
								 [ChainID]
								,[InvoicePeriodStart]
								,[InvoicePeriodEnd]
								,[OriginalAmount]
								,[InvoiceTypeID]
								,[OpenAmount]
								,[LastUpdateUserID]
								,[InvoiceStatus]
							)
							select 
								 @EntityIDToInvoice
								,@billingperiodstartdatetime
								,@billingperiodenddatetime
								,SUM(TotalCost)
								,@invoicetype
								,SUM(TotalCost)
								,@MyID
								,1
							from 
								InvoiceDetails
							where 
								ChainID = @entityidtoinvoice
							and StoreID = @storeid
							and RetailerInvoiceID = -1
							and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
							
													
							set @invoiceheaderid = SCOPE_IDENTITY()
							
							update d 
							set 
								 RetailerInvoiceID = @invoiceheaderid
								,Recordstatus = 4
							from 
								InvoiceDetails d
							where 
								ChainID = @entityidtoinvoice
							and StoreID = @storeid
							and RetailerInvoiceID = -1
							and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
							
							--***************************************************************************************************													
							fetch next from @recstore into @storeid
						END --WHILE
										
						close @recstore
						deallocate @recstore
						
						--- STEP (@invoiceseparation = 1)
						EXEC dbo.[Audit_Log_SP] 'STEP (@invoiceseparation = 1) => INSERT [InvoicesRetailer] : UPDATE DETAILs', @source
						
					end --@invoiceseparation = 1 --by store
							
					------------------------------------------------------------------------------------------------------																				
					IF @invoiceseparation = 2 --by store and supplier
					BEGIN
					--**************************************************************************************************
						set @recstore = CURSOR local fast_forward FOR
						select distinct StoreID
						from InvoiceDetails
						where ChainID = @entityidtoinvoice
						and RetailerInvoiceID = -1
						and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
						
						OPEN @recstore
						
						FETCH NEXT FROM @recstore into @storeid
						WHILE @@FETCH_STATUS = 0
						BEGIN
							--**************************************************************************************************
							set @recsupplier = CURSOR local fast_forward FOR
							select 
								distinct SupplierID
							from 
								InvoiceDetails
							where 
								ChainID = @entityidtoinvoice
							and StoreID = @storeid
							and RetailerInvoiceID = -1
							and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
							
							open @recsupplier
							
							fetch next from @recsupplier into @supplierid
							
							WHILE @@FETCH_STATUS = 0
							BEGIN
								set @invoiceheaderid = null
										
								IF UPPER(@PutCreditsOnSeparateInvoice) = 'YES'
								BEGIN
									INSERT INTO [DataTrue_Main].[dbo].[InvoicesRetailer]
									(
										 [ChainID]
										,[InvoicePeriodStart]
										,[InvoicePeriodEnd]
										,[OriginalAmount]
										,[InvoiceTypeID]
										,[OpenAmount]
										,[LastUpdateUserID]
										,[InvoiceStatus]
									)
									SELECT 
										 @EntityIDToInvoice
										,@billingperiodstartdatetime
										,@billingperiodenddatetime
										,SUM(TotalCost)
										,@invoicetype
										,SUM(TotalCost)
										,@MyID
										,1
									FROM 
										InvoiceDetails
									WHERE 
										ChainID = @entityidtoinvoice
									and StoreID = @storeid
									and SupplierID = @supplierid
									and RetailerInvoiceID = -1
									and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
									GROUP BY 
										Saledate
									HAVING 
										Sum(TotalCost) < 0
																
																
									set @invoiceheaderid = SCOPE_IDENTITY()
									
									update d set RetailerInvoiceID = @invoiceheaderid
									,Recordstatus = 4
									from InvoiceDetails d
									inner join 
									(
										select productid, brandid, SaleDate
										from InvoiceDetails
										where ChainID = @entityidtoinvoice
										and StoreID = @storeid
										and SupplierID = @supplierid
										and RetailerInvoiceID = -1
										and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
										Group by productid, brandid, SaleDate
										having Sum(TotalCost) < 0																							
									) c
									on d.productid = c.productid and d.brandid = c.brandid and d.saledate = c.saledate	
									where ChainID = @entityidtoinvoice
									and StoreID = @storeid
									and SupplierID = @supplierid
									and RetailerInvoiceID = -1
									and d.SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
					
								end --IF UPPER(@PutCreditsOnSeparateInvoice) = 'YES'
															
								INSERT INTO [DataTrue_Main].[dbo].[InvoicesRetailer]
								(
									 [ChainID]
									,[InvoicePeriodStart]
									,[InvoicePeriodEnd]
									,[OriginalAmount]
									,[InvoiceTypeID]
									,[OpenAmount]
									,[LastUpdateUserID]
									,[InvoiceStatus]
								)
								SELECT 
									 @EntityIDToInvoice
									,@billingperiodstartdatetime
									,@billingperiodenddatetime
									,SUM(TotalCost)
									,@invoicetype
									,SUM(TotalCost)
									,@MyID
									,1
								FROM 
									InvoiceDetails
								WHERE 
									ChainID = @entityidtoinvoice
								and StoreID = @storeid
								and SupplierID = @supplierid
								and RetailerInvoiceID = -1
								and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
								
								SET @invoiceheaderid = SCOPE_IDENTITY()
																							
								UPDATE d 
								SET 
									 RetailerInvoiceID = @invoiceheaderid
									,Recordstatus = 4
								FROM 
									InvoiceDetails d
								WHERE 
									ChainID = @entityidtoinvoice
								and StoreID = @storeid
								and SupplierID = @supplierid
								and RetailerInvoiceID = -1
								and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
																
								FETCH NEXT FROM @recsupplier INTO @supplierid
							END
							
							close @recsupplier
							deallocate @recsupplier
													
							--***************************************************************************************************													
							FETCH NEXT FROM @recstore into @storeid
						END --FETCH NEXT FROM @recstore
							
						CLOSE @recstore
						DEALLOCATE @recstore
						--**************************************************************************************************
						--- STEP (@invoiceseparation = 2)
						EXEC dbo.[Audit_Log_SP] 'STEP (@invoiceseparation = 2) => INSERT [InvoicesRetailer] : UPDATE DETAILs', @source
					END ----by store and supplier
							
					------------------------------------------------------------------------------------------------------										
					IF @invoiceseparation = 3 --by store, supplier, detailtypeid
					begin
						declare @invoicedetailtypeid tinyint
						declare @detailtypeid1 int
						declare @detailtypeid2 int
						declare @recdetailtype cursor
						--**************************************************************************************************
						set @recstore = CURSOR local fast_forward FOR
						select 
							distinct StoreID
						from 
							InvoiceDetails
						where 
							ChainID = @entityidtoinvoice
						and RetailerInvoiceID = -1
						and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
						
						open @recstore
						
						FETCH NEXT FROM @recstore into @storeid
						WHILE @@FETCH_STATUS = 0
						BEGIN
							--**************************************************************************************************

							set @recsupplier = CURSOR local fast_forward FOR
							select 
								distinct SupplierID
							from 
								InvoiceDetails
							where 
								ChainID = @entityidtoinvoice
							and StoreID = @storeid
							and RetailerInvoiceID = -1
							and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
							
							open @recsupplier
							fetch next from @recsupplier into @supplierid
											
							WHILE @@FETCH_STATUS = 0
							BEGIN
								---------------------------------------------------------------------------												
								SET @recdetailtype = CURSOR local fast_forward FOR
								SELECT 
									DISTINCT InvoiceDetailTypeID
								FROM 
									InvoiceDetails
								WHERE 
									ChainID = @entityidtoinvoice
								and StoreID = @storeid
								and SupplierID = @supplierid
								and RetailerInvoiceID = -1
								and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
									
								open @recdetailtype
								
								fetch next from @recdetailtype into @invoicedetailtypeid
													
								WHILE @@FETCH_STATUS = 0
								BEGIN
									set @invoiceheaderid = null
									if @invoicetype = 0																			
										-- @invoicedetailtypeid = 1 and @invoicetype = 0
									begin 
										--since original billing combine original and adjustments under one invoiceid
										--if @invoicedetailtypeid in (1,2,3,4)
										--begin
										select @invoicedetailtypeid as detailtypeid into #temptypes
										if @invoicedetailtypeid = 1
										begin
											set @detailtypeid1 = 1
											set @detailtypeid2 = 7
										end
										if @invoicedetailtypeid = 2
										begin
											set @detailtypeid1 = 2
											set @detailtypeid2 = 8
										end
										if @invoicedetailtypeid = 3
										begin
											set @detailtypeid1 = 3
											set @detailtypeid2 = 9
										end
										if @invoicedetailtypeid = 5
										begin
											set @detailtypeid1 = 5
											set @detailtypeid2 = 10
										end
											
										INSERT #temptypes 
											(detailtypeid) 
										VALUES
											(@detailtypeid2)	
											
										IF UPPER(@PutCreditsOnSeparateInvoice) = 'YES'
										BEGIN
											INSERT INTO [DataTrue_Main].[dbo].[InvoicesRetailer]
											(
												 [ChainID]
												,[InvoicePeriodStart]
												,[InvoicePeriodEnd]
												,[OriginalAmount]
												,[InvoiceTypeID]
												,[OpenAmount]
												,[LastUpdateUserID]
												,[InvoiceStatus]
											)
											SELECT 
												 @EntityIDToInvoice
												,@billingperiodstartdatetime
												,@billingperiodenddatetime
												,SUM(TotalCost)
												,case	when @invoicedetailtypeid in (1) then 0
														when @invoicedetailtypeid in (2) then 1
														when @invoicedetailtypeid in (3) then 2
														when @invoicedetailtypeid in (4) then 4
												else 10 end --@invoicetype
												,SUM(TotalCost)
												,@MyID
												,0
											FROM 
												InvoiceDetails
											WHERE 
												ChainID = @entityidtoinvoice
											and StoreID = @storeid
											and SupplierID = @supplierid
											and RetailerInvoiceID = -1
											and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
											and InvoiceDetailTypeID in (select detailtypeid from #temptypes)
											--and InvoiceDetailTypeID = @invoicedetailtypeid
											--and InvoiceDetailTypeID in (1,7)
											GROUP BY 
												productid, brandid, SaleDate
											HAVING 
												SUM(TotalCost) < 0

											SET @invoiceheaderid = SCOPE_IDENTITY()

											UPDATE d 
											SET 
												 RetailerInvoiceID = @invoiceheaderid
												,Recordstatus = 4
											FROM 
												InvoiceDetails d
												---------------	
												INNER JOIN 
												---------------
												(
													select 
														productid, brandid, SaleDate
													from 
														InvoiceDetails
													where 
														ChainID = @entityidtoinvoice
													and StoreID = @storeid
													and SupplierID = @supplierid
													and RetailerInvoiceID = -1
													and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
													and InvoiceDetailTypeID in (select detailtypeid from #temptypes)
													--and InvoiceDetailTypeID = @invoicedetailtypeid
													--and InvoiceDetailTypeID in (1,7)
													Group by productid, brandid, SaleDate
													having Sum(TotalCost) < 0																							
												) c
												on d.productid = c.productid and d.brandid = c.brandid and d.saledate = c.saledate
											where 
												ChainID = @entityidtoinvoice
											and StoreID = @storeid
											and SupplierID = @supplierid
											and InvoiceDetailTypeID in (select detailtypeid from #temptypes)
											--and InvoiceDetailTypeID = @invoicedetailtypeid
											--and InvoiceDetailTypeID in (1,7)
											and RetailerInvoiceID = -1
											and d.SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)


											--Group by SaleDate
											--having Sum(TotalCost) < 0

										END --upper(@PutCreditsOnSeparateInvoice) = 'YES'
																	

										INSERT INTO [DataTrue_Main].[dbo].[InvoicesRetailer]
										(
											 [ChainID]
											,[InvoicePeriodStart]
											,[InvoicePeriodEnd]
											,[OriginalAmount]
											,[InvoiceTypeID]
											,[OpenAmount]
											,[LastUpdateUserID]
											,[InvoiceStatus]
										)
										SELECT 
											@EntityIDToInvoice
											,@billingperiodstartdatetime
											,@billingperiodenddatetime
											,SUM(TotalCost)
											,case	when @invoicedetailtypeid in (1) then 0
													when @invoicedetailtypeid in (2) then 1
													when @invoicedetailtypeid in (3) then 2
													when @invoicedetailtypeid in (4) then 4
											else 10 end --@invoicetype
											,SUM(TotalCost)
											,@MyID
											,0
										from 
											InvoiceDetails
										where 
											ChainID = @entityidtoinvoice
										and StoreID = @storeid
										and SupplierID = @supplierid
										and RetailerInvoiceID = -1
										and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
										and InvoiceDetailTypeID in (select detailtypeid from #temptypes)

										set @invoiceheaderid = SCOPE_IDENTITY()

										update d 
										set 
											 RetailerInvoiceID = @invoiceheaderid
											,Recordstatus = 4
										from 
											InvoiceDetails d
										where 
											ChainID = @entityidtoinvoice
										and StoreID = @storeid
										and SupplierID = @supplierid
										and InvoiceDetailTypeID in (select detailtypeid from #temptypes)
										and RetailerInvoiceID = -1
										and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)

										--end
										drop table #temptypes
										--end --if @invoicedetailtypeid in (1,2,3,4)
									END --@invoicetype = 0	
									ELSE 
									BEGIN
										IF UPPER(@PutCreditsOnSeparateInvoice) = 'YES'
										BEGIN
											INSERT INTO [DataTrue_Main].[dbo].[InvoicesRetailer]
											(
											    [ChainID]
											   ,[InvoicePeriodStart]
											   ,[InvoicePeriodEnd]
											   ,[OriginalAmount]
											   ,[InvoiceTypeID]
											   ,[OpenAmount]
											   ,[LastUpdateUserID]
											   ,[InvoiceStatus]
											)
											SELECT 
												@EntityIDToInvoice
											   ,@billingperiodstartdatetime
											   ,@billingperiodenddatetime
											   ,SUM(TotalCost)
											   ,case	when @invoicedetailtypeid in (1) then 0
													when @invoicedetailtypeid in (2) then 1
													when @invoicedetailtypeid in (3) then 2
													when @invoicedetailtypeid in (4) then 4
													when @invoicedetailtypeid in (7) then 5
													when @invoicedetailtypeid in (8) then 6
													when @invoicedetailtypeid in (9) then 7
													when @invoicedetailtypeid in (10) then 8
												else 10 end --case when InvoiceDetailTypeID in (1,2,3,4,5,6) then 0 else 1 end
											   ,SUM(TotalCost)
											   ,@MyID
											   ,0
											FROM 
												InvoiceDetails
											WHERE 
												ChainID = @entityidtoinvoice
											and StoreID = @storeid
											and SupplierID = @supplierid
											and RetailerInvoiceID = -1
											and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
											and InvoiceDetailTypeID = @invoicedetailtypeid
											GROUP BY 
												productid, brandid, SaleDate, InvoiceDetailTypeID
											HAVING 
												SUM(TotalCost) < 0
											
											SET @invoiceheaderid = SCOPE_IDENTITY()
												
											UPDATE d 
											SET 
												 RetailerInvoiceID = @invoiceheaderid
												,Recordstatus = 4
											FROM 
												InvoiceDetails d
												---------------
												INNER JOIN 
												---------------
												(
													SELECT 
														  productid
														, brandid
														, SaleDate
													FROM 
														InvoiceDetails
													WHERE 
														ChainID = @entityidtoinvoice
													and StoreID = @storeid
													and SupplierID = @supplierid
													and RetailerInvoiceID = -1
													and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
													and InvoiceDetailTypeID  = @invoicedetailtypeid
													GROUP BY productid, brandid, SaleDate
													HAVING SUM(TotalCost) < 0																							
												) c
												on 
														d.productid = c.productid 
													and d.brandid = c.brandid 
													and d.saledate = c.saledate
													
											WHERE
												ChainID = @entityidtoinvoice
											and StoreID = @storeid
											and SupplierID = @supplierid
											and InvoiceDetailTypeID = @invoicedetailtypeid
											and RetailerInvoiceID = -1
											and d.SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
												
										END --UPPER(@PutCreditsOnSeparateInvoice) = 'YES'
																				
										INSERT INTO [DataTrue_Main].[dbo].[InvoicesRetailer]
										(
											[ChainID]
										   ,[InvoicePeriodStart]
										   ,[InvoicePeriodEnd]
										   ,[OriginalAmount]
										   ,[InvoiceTypeID]
										   ,[OpenAmount]
										   ,[LastUpdateUserID]
										   ,[InvoiceStatus]
										)
										SELECT 
											@EntityIDToInvoice
										   ,@billingperiodstartdatetime
										   ,@billingperiodenddatetime
										   ,SUM(TotalCost)
										   ,case	when @invoicedetailtypeid in (1) then 0
														when @invoicedetailtypeid in (2) then 1
														when @invoicedetailtypeid in (3) then 2
														when @invoicedetailtypeid in (4) then 4
														when @invoicedetailtypeid in (7) then 5
														when @invoicedetailtypeid in (8) then 6
														when @invoicedetailtypeid in (9) then 7
														when @invoicedetailtypeid in (10) then 8
													else 10 end --case when @invoicedetailtypeid in (1,2,3,4,5,6) then 0 else 1 end --@isadjustmentinvoice--@invoicetype
										   ,SUM(TotalCost)
										   ,@MyID
										   ,0
										FROM 
											InvoiceDetails
										WHERE 
											ChainID = @entityidtoinvoice
										and StoreID = @storeid
										and SupplierID = @supplierid
										and RetailerInvoiceID = -1
										and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
										and InvoiceDetailTypeID = @invoicedetailtypeid
										SET @invoiceheaderid = SCOPE_IDENTITY()
											
										UPDATE d 
										SET 
											 RetailerInvoiceID = @invoiceheaderid
											,Recordstatus = 4
										FROM 
											InvoiceDetails d
										WHERE 
											ChainID = @entityidtoinvoice
										and StoreID = @storeid
										and SupplierID = @supplierid
										and InvoiceDetailTypeID = @invoicedetailtypeid
										and RetailerInvoiceID = -1
										and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
									END --@invoicetype <> 0	
																
									FETCH NEXT FROM @recdetailtype into @invoicedetailtypeid
								END --WHILE @recdetailtype
															
								CLOSE @recdetailtype
								DEALLOCATE @recdetailtype
								
								FETCH NEXT FROM @recsupplier INTO @supplierid
							END -- WHILE @recsupplier
						
							close @recsupplier
							deallocate @recsupplier
													
							--***************************************************************************************************													
							fetch next from @recstore into @storeid
						end
							
						close @recstore
						deallocate @recstore
						--**************************************************************************************************
						
						--- STEP (@invoiceseparation = 3)
						EXEC dbo.[Audit_Log_SP] 'STEP (@invoiceseparation = 3) => INSERT [InvoicesRetailer] : UPDATE DETAILs', @source		
						
					END --@invoiceseparation = 3 --by store, supplier, detailtypeid										
						
					------------------------------------------------------------------------------------------------------										
				end --if @invoiceseparation <> 0
							
				if @invoiceseparation = 4 --by store, supplier, detailtypeid
				begin
								--declare @invoicedetailtypeid tinyint
								--declare @detailtypeid1 int
								--declare @detailtypeid2 int
								--declare @recdetailtype cursor
								declare @recpono cursor
								declare @pono nvarchar(50)
	--**************************************************************************************************
								set @recstore = CURSOR local fast_forward FOR
									select distinct StoreID
									from InvoiceDetails
									where ChainID = @entityidtoinvoice
									and RetailerInvoiceID = -1
									and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
									
									
									open @recstore
									
									fetch next from @recstore into @storeid
									
									while @@FETCH_STATUS = 0
										begin
	--**************************************************************************************************

											set @recsupplier = CURSOR local fast_forward FOR
												select distinct SupplierID
												from InvoiceDetails
												where ChainID = @entityidtoinvoice
												and StoreID = @storeid
												and RetailerInvoiceID = -1
												and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
												
												open @recsupplier
												
												fetch next from @recsupplier into @supplierid
												
												while @@FETCH_STATUS = 0
													begin
													
														set @recdetailtype = CURSOR local fast_forward FOR
															select distinct InvoiceDetailTypeID
																from InvoiceDetails
																where ChainID = @entityidtoinvoice
																and StoreID = @storeid
																and SupplierID = @supplierid
																and RetailerInvoiceID = -1
																and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
																	
														open @recdetailtype
														
														fetch next from @recdetailtype into @invoicedetailtypeid
														
														while @@FETCH_STATUS = 0
															begin
																set @recpono = CURSOR local fast_forward FOR
																select distinct InvoiceNo
																	from InvoiceDetails
																	where ChainID = @entityidtoinvoice
																	and StoreID = @storeid
																	and SupplierID = @supplierid
																	and InvoiceDetailTypeID = @invoicedetailtypeid
																	and RetailerInvoiceID = -1
																	and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
																	
																open @recpono
																
																fetch next from @recpono into @pono
																
																while @@FETCH_STATUS = 0
																	begin
																		set @invoiceheaderid = null
																		if @invoicetype = 0																			
																		-- @invoicedetailtypeid = 1 and @invoicetype = 0
																			begin --since original billing combine original and adjustments under one invoiceid
																			  --if @invoicedetailtypeid in (1,2,3,4)
																				--begin
																				select @invoicedetailtypeid as detailtypeid into #temptypes2
																				if @invoicedetailtypeid = 1
																					begin
																						set @detailtypeid1 = 1
																						set @detailtypeid2 = 7
																					end
																				if @invoicedetailtypeid = 2
																					begin
																						set @detailtypeid1 = 2
																						set @detailtypeid2 = 8
																					end
																				if @invoicedetailtypeid = 3
																					begin
																						set @detailtypeid1 = 3
																						set @detailtypeid2 = 9
																					end
																				if @invoicedetailtypeid = 5
																					begin
																						set @detailtypeid1 = 5
																						set @detailtypeid2 = 10
																					end
																				insert #temptypes2 (detailtypeid) values(@detailtypeid2)	
																				if upper(@PutCreditsOnSeparateInvoice) = 'YES'
																					begin
																						INSERT INTO [DataTrue_Main].[dbo].[InvoicesRetailer]
																						   ([ChainID]
																						   ,[InvoicePeriodStart]
																						   ,[InvoicePeriodEnd]
																						   ,[OriginalAmount]
																						   ,[InvoiceTypeID]
																						   ,[OpenAmount]
																						   ,[LastUpdateUserID]
																						   ,[InvoiceStatus])
																						select @EntityIDToInvoice
																						   ,@billingperiodstartdatetime
																						   ,@billingperiodenddatetime
																						   ,SUM(TotalCost)
																						   ,case	when @invoicedetailtypeid in (1) then 0
																									when @invoicedetailtypeid in (2) then 1
																									when @invoicedetailtypeid in (3) then 2
																									when @invoicedetailtypeid in (4) then 4
																							else 10 end --@invoicetype
																						   ,SUM(TotalCost)
																						   ,@MyID
																						   ,0
																						from InvoiceDetails
																						where ChainID = @entityidtoinvoice
																						and StoreID = @storeid
																						and SupplierID = @supplierid
																						and RetailerInvoiceID = -1
																						and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
																						and InvoiceDetailTypeID in (select detailtypeid from #temptypes2)
																						and InvoiceNo = @PONo
																						--and InvoiceDetailTypeID = @invoicedetailtypeid
																						--and InvoiceDetailTypeID in (1,7)
																						Group by productid, brandid, SaleDate
																						having Sum(TotalCost) < 0
																						
																						
																						set @invoiceheaderid = SCOPE_IDENTITY()
																					
																						update d set RetailerInvoiceID = @invoiceheaderid
																						,Recordstatus = 4
																						from InvoiceDetails d
																						inner join 
																						(
																							select productid, brandid, SaleDate
																							from InvoiceDetails
																							where ChainID = @entityidtoinvoice
																							and StoreID = @storeid
																							and SupplierID = @supplierid
																							and RetailerInvoiceID = -1
																							and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
																							and InvoiceDetailTypeID in (select detailtypeid from #temptypes2)
																							and InvoiceNo = @PONo
																							--and InvoiceDetailTypeID = @invoicedetailtypeid
																							--and InvoiceDetailTypeID in (1,7)
																							Group by productid, brandid, SaleDate
																							having Sum(TotalCost) < 0																							
																						) c
																						on d.productid = c.productid and d.brandid = c.brandid and d.saledate = c.saledate
																						where ChainID = @entityidtoinvoice
																						and StoreID = @storeid
																						and SupplierID = @supplierid
																						and InvoiceDetailTypeID in (select detailtypeid from #temptypes2)
																						and InvoiceNo = @PONo
																						--and InvoiceDetailTypeID = @invoicedetailtypeid
																						--and InvoiceDetailTypeID in (1,7)
																						and RetailerInvoiceID = -1
																						and d.SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
																						

																						--Group by SaleDate
																						--having Sum(TotalCost) < 0
																					
																					end
																				
																				/*
																				select count(*)
																				from InvoiceDetails
																				where ChainID = @entityidtoinvoice
																				and StoreID = @storeid
																				and SupplierID = @supplierid
																				and RetailerInvoiceID = -1
																				and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
																				and InvoiceDetailTypeID = @invoicedetailtypeid
																				
																				
																				
																				
																				if @@rowcount > 0
																					begin
																				*/
																						INSERT INTO [DataTrue_Main].[dbo].[InvoicesRetailer]
																						   ([ChainID]
																						   ,[InvoicePeriodStart]
																						   ,[InvoicePeriodEnd]
																						   ,[OriginalAmount]
																						   ,[InvoiceTypeID]
																						   ,[OpenAmount]
																						   ,[LastUpdateUserID]
																						   ,[InvoiceStatus])
																						select @EntityIDToInvoice
																						   ,@billingperiodstartdatetime
																						   ,@billingperiodenddatetime
																						   ,SUM(TotalCost)
																						   ,case	when @invoicedetailtypeid in (1) then 0
																									when @invoicedetailtypeid in (2) then 1
																									when @invoicedetailtypeid in (3) then 2
																									when @invoicedetailtypeid in (4) then 4
																							else 10 end --@invoicetype
																						   ,SUM(TotalCost)
																						   ,@MyID
																						   ,0
																						from InvoiceDetails
																						where ChainID = @entityidtoinvoice
																						and StoreID = @storeid
																						and SupplierID = @supplierid
																						and RetailerInvoiceID = -1
																						and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
																						and InvoiceDetailTypeID in (select detailtypeid from #temptypes2)
																						and InvoiceNo = @PONo
																						--and InvoiceDetailTypeID = @invoicedetailtypeid
																						--and InvoiceDetailTypeID in (1,7)
																						--Group by productid, brandid
																						
																						
																						set @invoiceheaderid = SCOPE_IDENTITY()
																					
																						update d set RetailerInvoiceID = @invoiceheaderid
																						,Recordstatus = 4
																						from InvoiceDetails d
																						where ChainID = @entityidtoinvoice
																						and StoreID = @storeid
																						and SupplierID = @supplierid
																						and InvoiceDetailTypeID in (select detailtypeid from #temptypes2)
																						and InvoiceNo = @PONo
																						--and InvoiceDetailTypeID = @invoicedetailtypeid
																						--and InvoiceDetailTypeID in (1,7)
																						and RetailerInvoiceID = -1
																						and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
																						
																					--end
																				drop table #temptypes2
																				--end --if @invoicedetailtypeid in (1,2,3,4)
																			end
																		else

																					begin
																					
																						if upper(@PutCreditsOnSeparateInvoice) = 'YES'
																							begin
																								INSERT INTO [DataTrue_Main].[dbo].[InvoicesRetailer]
																								   ([ChainID]
																								   ,[InvoicePeriodStart]
																								   ,[InvoicePeriodEnd]
																								   ,[OriginalAmount]
																								   ,[InvoiceTypeID]
																								   ,[OpenAmount]
																								   ,[LastUpdateUserID]
																								   ,[InvoiceStatus])
																								select @EntityIDToInvoice
																								   ,@billingperiodstartdatetime
																								   ,@billingperiodenddatetime
																								   ,SUM(TotalCost)
																								   ,case	when @invoicedetailtypeid in (1) then 0
																										when @invoicedetailtypeid in (2) then 1
																										when @invoicedetailtypeid in (3) then 2
																										when @invoicedetailtypeid in (4) then 4
																										when @invoicedetailtypeid in (7) then 5
																										when @invoicedetailtypeid in (8) then 6
																										when @invoicedetailtypeid in (9) then 7
																										when @invoicedetailtypeid in (10) then 8
																									else 10 end --case when InvoiceDetailTypeID in (1,2,3,4,5,6) then 0 else 1 end
																								   ,SUM(TotalCost)
																								   ,@MyID
																								   ,0
																								from InvoiceDetails
																								where ChainID = @entityidtoinvoice
																								and StoreID = @storeid
																								and SupplierID = @supplierid
																								and RetailerInvoiceID = -1
																								and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
																								and InvoiceDetailTypeID = @invoicedetailtypeid
																								and InvoiceNo = @PONo
																								Group by productid, brandid, SaleDate, InvoiceDetailTypeID
																								having Sum(TotalCost) < 0
																								
																																											
																								set @invoiceheaderid = SCOPE_IDENTITY()
																									
																								update d set RetailerInvoiceID = @invoiceheaderid
																								,Recordstatus = 4
																								from InvoiceDetails d
																								inner join 
																								(
																									select productid, brandid, SaleDate
																									from InvoiceDetails
																									where ChainID = @entityidtoinvoice
																									and StoreID = @storeid
																									and SupplierID = @supplierid
																									and RetailerInvoiceID = -1
																									and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
																									and InvoiceDetailTypeID  = @invoicedetailtypeid
																									and InvoiceNo = @PONo
																									Group by productid, brandid, SaleDate
																									having Sum(TotalCost) < 0																							
																								) c
																								on d.productid = c.productid and d.brandid = c.brandid and d.saledate = c.saledate
																								where ChainID = @entityidtoinvoice
																								and StoreID = @storeid
																								and SupplierID = @supplierid
																								and InvoiceDetailTypeID = @invoicedetailtypeid
																								and InvoiceNo = @PONo
																								and RetailerInvoiceID = -1
																								and d.SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
																									
																							end
																							
																						INSERT INTO [DataTrue_Main].[dbo].[InvoicesRetailer]
																						   ([ChainID]
																						   ,[InvoicePeriodStart]
																						   ,[InvoicePeriodEnd]
																						   ,[OriginalAmount]
																						   ,[InvoiceTypeID]
																						   ,[OpenAmount]
																						   ,[LastUpdateUserID]
																						   ,[InvoiceStatus])
																						select @EntityIDToInvoice
																						   ,@billingperiodstartdatetime
																						   ,@billingperiodenddatetime
																						   ,SUM(TotalCost)
																						   ,case	when @invoicedetailtypeid in (1) then 0
																										when @invoicedetailtypeid in (2) then 1
																										when @invoicedetailtypeid in (3) then 2
																										when @invoicedetailtypeid in (4) then 4
																										when @invoicedetailtypeid in (7) then 5
																										when @invoicedetailtypeid in (8) then 6
																										when @invoicedetailtypeid in (9) then 7
																										when @invoicedetailtypeid in (10) then 8
																									else 10 end --case when @invoicedetailtypeid in (1,2,3,4,5,6) then 0 else 1 end --@isadjustmentinvoice--@invoicetype
																						   ,SUM(TotalCost)
																						   ,@MyID
																						   ,0
																						from InvoiceDetails
																						where ChainID = @entityidtoinvoice
																						and StoreID = @storeid
																						and SupplierID = @supplierid
																						and RetailerInvoiceID = -1
																						and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
																						and InvoiceDetailTypeID = @invoicedetailtypeid
																						and InvoiceNo = @PONo
																						
																																									
																						set @invoiceheaderid = SCOPE_IDENTITY()
																							
																						update d set RetailerInvoiceID = @invoiceheaderid
																						,Recordstatus = 4
																						from InvoiceDetails d
																						where ChainID = @entityidtoinvoice
																						and StoreID = @storeid
																						and SupplierID = @supplierid
																						and InvoiceDetailTypeID = @invoicedetailtypeid
																						and InvoiceNo = @PONo
																						and RetailerInvoiceID = -1
																						and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
																						
																						
																					end
	/*								
																		if @invoicedetailtypeid = 7 and @invoicetype = 0
																			begin
																				set @dummycount = 0
																			end
																		else
																			begin																				
																				if @invoicedetailtypeid = 1 and @invoicetype = 0
																					begin
																						update d set RetailerInvoiceID = @invoiceheaderid
																						,Recordstatus = 4
																						from InvoiceDetails d
																						where ChainID = @entityidtoinvoice
																						and StoreID = @storeid
																						and SupplierID = @supplierid
																						and InvoiceDetailTypeID in (1,7)
																						and RetailerInvoiceID = -1
																						and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
																					end
																				else
																					begin
																						update d set RetailerInvoiceID = @invoiceheaderid
																						,Recordstatus = 4
																						from InvoiceDetails d
																						where ChainID = @entityidtoinvoice
																						and StoreID = @storeid
																						and SupplierID = @supplierid
																						and InvoiceDetailTypeID = @invoicedetailtypeid
																						and RetailerInvoiceID = -1
																						and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
																					end
																		end
	*/																			
																	fetch next from @recpono into @pono
																end
																
																close @recpono
																deallocate @recpono
																			
																fetch next from @recdetailtype into @invoicedetailtypeid
																
															end
																
														close @recdetailtype
														deallocate @recdetailtype
								
	--***************************************Supplier Invoice Start*************************************************************	
	/*																		
														set @supplierinvoiceheaderid = null
														
														INSERT INTO [DataTrue_Main].[dbo].[InvoicesSupplier]
																   ([SupplierID]
																   ,[InvoicePeriodStart]
																   ,[InvoicePeriodEnd]
																   ,[OriginalAmount]
																   ,[InvoiceTypeID]
																   ,[OpenAmount]
																   ,[LastUpdateUserID]
																   ,[InvoiceStatus])
															 select @EntityIDToInvoice
																   ,@billingperiodstartdatetime
																   ,@billingperiodenddatetime
																   ,SUM(TotalCost)
																   ,@invoicetype
																   ,SUM(TotalCost)
																   ,@MyID
																   ,1
																from InvoiceDetails
																where ChainID = @entityidtoinvoice
																and StoreID = @storeid
																and SupplierID = @supplierid
																and RetailerInvoiceID = -1
																and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
																
																set @supplierinvoiceheaderid = SCOPE_IDENTITY()
																
																update d set RetailerInvoiceID = @invoiceheaderid
																,SupplierInvoiceID = @supplierinvoiceheaderid
																,Recordstatus = 4
																from InvoiceDetails d
																where ChainID = @entityidtoinvoice
																and StoreID = @storeid
																and SupplierID = @supplierid
																and RetailerInvoiceID = -1
																and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
	*/																																						
	--***************************************Supplier Invoice End*************************************************************																			
																
															fetch next from @recsupplier into @supplierid
													end
												
												close @recsupplier
												deallocate @recsupplier
													
	--***************************************************************************************************													
											fetch next from @recstore into @storeid
										end
										
									close @recstore
									deallocate @recstore
	--**************************************************************************************************	
						--- STEP (@invoiceseparation = 4)
						EXEC dbo.[Audit_Log_SP] 'STEP (@invoiceseparation = 4) => INSERT [InvoicesRetailer] : UPDATE DETAILs', @source																
					end --if @invoiceseparation = 4								
		end --loomy
					
		if @numberofperiodsrun < 1
		begin
		
			set @newnextbillingperiodenddatetime = 
			case 
				when upper(@billingcontrolfrequency) = 'DAILY' then dateadd(day,1,@billingperiodenddatetime)
				when upper(@billingcontrolfrequency) = 'WEEKLY' then dateadd(day,7,@billingperiodenddatetime)
				when upper(@billingcontrolfrequency) = 'BIWEEKLY' then dateadd(day,14,@billingperiodenddatetime)
				when upper(@billingcontrolfrequency) = 'MONTHLYCALENDAR' then dateadd(day,-1,dateadd(month,2,@billingperiodstartdatetime))
			else 
				dateadd(day,7,@billingperiodenddatetime)
			end
		
			update BillingControl
			set LastBillingPeriodEndDateTime = NextBillingPeriodEndDateTime
			,NextBillingPeriodEndDateTime = @newnextbillingperiodenddatetime
			,NextBillingPeriodRunDateTime = dateadd(day,@billingcontrolclosingdelay,@newnextbillingperiodenddatetime)
			,LastUpdateUserID = @MyID
			,DateTimeLastUpdate = @currentdatetime
			where BillingControlID = @billingcontrolid
		end	
						
		set @numberofperiodsrun = @numberofperiodsrun + 1
		
		if upper(@billingcontrolfrequency) = 'DAILY'
		begin
			set @billingperiodstartdatetime = dateadd(day,-1,@billingperiodstartdatetime)
			set @billingperiodenddatetime = dateadd(day,-1,@billingperiodenddatetime)
		end			
		if upper(@billingcontrolfrequency) = 'WEEKLY'
		begin
			set @billingperiodstartdatetime = dateadd(day,-7,@billingperiodstartdatetime)
			set @billingperiodenddatetime =  dateadd(day,-7,@billingperiodenddatetime)
		end
		if upper(@billingcontrolfrequency) = 'BIWEEKLY'
		begin
			set @billingperiodstartdatetime = dateadd(day,-14,@billingperiodstartdatetime)
			set @billingperiodenddatetime =  dateadd(day,-14,@billingperiodenddatetime)
		end
		if upper(@billingcontrolfrequency) = 'MONTHLYCALENDAR'
		begin
			set @billingperiodstartdatetime = dateadd(month, -1, @billingperiodstartdatetime)
			set @billingperiodenddatetime = dateadd(day, -1, @billingperiodstartdatetime)
		end				
		--commit transaction
	END --WHILE (@numberofperiodsrun < @numberofperiodstorun)
END TRY
BEGIN CATCH
	
		rollback transaction
	
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
		,'An exception occurred in prInvoices_Retailer_Create_ACH.  Manual review, resolution, and re-start will be required for the job to continue.'
		,'DataTrue System', 0, 'vince.moore@icontroldsd.com'--'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
	
END CATCH

NextBilling:
		
		--- STEP ZZ
		SET @msg_audit = 'STEP 0ZZ => CHAINID:' + CONVERT(VARCHAR(20), @EntityIDToInvoice)
		EXEC dbo.[Audit_Log_SP] @msg_audit, @source 
		
		fetch next from @rec 
		into @billingcontrolid
		,@EntityIDToInvoice
		,@billingcontrolday
		,@billingcontrolclosingdelay
		,@productsubgrouptype
		,@productsubgroupid
		,@nextbillingperiodrundatetime	
		,@invoiceseparation
		,@numberofpastdaystorebill
		,@nextbillingperiodenddatetime
		,@separatecredits
END --WHILE billingcontrol
	
close @rec
deallocate @rec

--*******************************************************************************************************

delete from DataTrue_Main..InvoicesRetailer where originalamount is null
--- STEP ZZ
EXEC dbo.[Audit_Log_SP] 'STEP 0-DELETE-0 => CHAINID:', @source
		
return
GO
