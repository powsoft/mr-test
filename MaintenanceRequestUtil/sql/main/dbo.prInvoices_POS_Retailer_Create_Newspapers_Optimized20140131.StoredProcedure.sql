USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoices_POS_Retailer_Create_Newspapers_Optimized20140131]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Batch submitted through debugger: SQLQuery191.sql|7|0|C:\Users\SQLAdmin\AppData\Local\Temp\3\~vsC251.sql
CREATE procedure [dbo].[prInvoices_POS_Retailer_Create_Newspapers_Optimized20140131]
@billingcontrolfrequency nvarchar(50)='Weekly'--,

as

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


set @currentdatetime = GETDATE()

set @rec = CURSOR local fast_forward for
	select BillingControlID, EntityIDToInvoice, BillingControlDay, BillingControlClosingDelay,
		ProductSubGroupType, ProductSubGroupID, NextBillingPeriodRunDateTime, 
		InvoiceSeparation, BillingControlNumberOfPastDaysToRebill, NextBillingPeriodEndDateTime, SeparateCredits
	from billingcontrol c
	inner join systementities s
	on c.EntityIDToInvoice = s.EntityID
	where s.EntityTypeID = 2
	and IsActive = 1
	 and EntityIDToInvoice in (select EntityIDToInclude from ProcessStepEntities where ProcessStepName = 'prGetInboundPOSTransactions_Newspapers')
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

while @@FETCH_STATUS = 0
	begin
	
		begin try


 INSERT INTO [DataTrue_Main].[dbo].[ChainProductFactors]
           ([ChainID]
           ,[ProductID]
           ,[BrandID]
           ,[BaseUnitsCalculationPerNoOfweeks]
           ,[CostFromRetailPercent]
           ,[BillingRuleID]
           ,[IncludeDollarDiffDetails]
           ,[ActiveStartDate]
           ,[ActiveEndDate]
           ,[LastUpdateUserID])
select @EntityIDToInvoice
		,ProductId
		,0
		,17
		,75
		,1
		,1
		,'2000-01-01 00:00:00'
		,'12/31/2025'
		,2
from Products
where ProductID in (select distinct productid from storetransactions where ChainID = @EntityIDToInvoice)
and ProductID not in (select productid from ChainProductFactors where ChainID = @EntityIDToInvoice) 		
		
		
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

if upper(@billingcontrolfrequency) = 'DAILY'
	begin
		set @billingperiodstartdatetime = @nextbillingperiodenddatetime 
		set @billingperiodenddatetime = @nextbillingperiodenddatetime
		set @numberofperiodstorun = @numberofpastdaystorebill 
	end
if upper(@billingcontrolfrequency) = 'WEEKLY'
	begin
		set @daystoincludebeforebillingperiodenddate = -6
		set @billingperiodstartdatetime = dateadd(day,@daystoincludebeforebillingperiodenddate,@nextbillingperiodenddatetime)
		set @billingperiodenddatetime = @nextbillingperiodenddatetime 
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

		begin try
			DROP TABLE #tempStoreSetupProducts
		end try
		begin catch
			set @dummyerrorcatch = 0
		end catch	
		
		select distinct ProductID, BrandID, BillingRuleID--, 
		into #tempStoreSetupProducts 
		from ChainProductFactors
		where ChainID = @EntityIDToInvoice
		
		
		if @@ROWCOUNT < 1
			goto NextBilling	
			
		begin try
			DROP TABLE #tempProductsToInvoice
		end try
		begin catch
			set @dummyerrorcatch = 0
		end catch
		
		select * into #tempProductsToInvoice from #tempStoreSetupProducts
		
	
		if @productsubgrouptype is not null and LEN(@productsubgrouptype) > 0
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
				


	
while @numberofperiodsrun < @numberofperiodstorun
	begin			
		begin transaction
--print '2'									
		
		
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
		if @invoicetype = 0
			begin
				update d set d.RetailerInvoiceID = -1 
				from InvoiceDetails d
				inner join #tempProductsToInvoice t
				on d.ProductID = t.ProductID 
				and d.BrandID = t.BrandID
				where d.ChainID = @EntityIDToInvoice
				and t.BillingRuleID in (1,3)
				and d.InvoiceDetailTypeID in (1, 16) --,7) --change here wait --POS Only
				and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
				and d.RetailerInvoiceID is null
				and LTRIM(rtrim(d.Banner)) <> 'SS'
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
				and d.InvoiceDetailTypeID in (1, 16) --,7) --change here wait ,7) --POS Only
				and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
				and d.RetailerInvoiceID is null
				and LTRIM(rtrim(d.Banner)) <> 'SS'
			end
		if @@rowcount > 0
			begin
				set @needtoinvoice = 1
			end

		--Any Rule 2/SUP + Shrink products detailtypeid 2 or 3
		update d set d.RetailerInvoiceID = -1 
		from InvoiceDetails d
		inner join #tempProductsToInvoice t
		on d.ProductID = t.ProductID 
		and d.BrandID = t.BrandID
		where d.ChainID = @EntityIDToInvoice
		and t.BillingRuleID in (2)
		and d.InvoiceDetailTypeID in (2,3,8,9)
		and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
		and d.RetailerInvoiceID is null
		
		if @@rowcount > 0
			begin
				set @needtoinvoice = 1
			end

		--Any Rule 2/SUP + Shrink products detailtypeid 2 or 3
		update d set d.RetailerInvoiceID = -1 
		from InvoiceDetails d
		inner join #tempProductsToInvoice t
		on d.ProductID = t.ProductID 
		and d.BrandID = t.BrandID
		where d.ChainID = @EntityIDToInvoice
		and t.BillingRuleID in (3)
		and d.InvoiceDetailTypeID in (3,4,9) 
		and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
		and d.RetailerInvoiceID is null
		
		if @@rowcount > 0
			begin
					set @needtoinvoice = 1
			end
			
		if @needtoinvoice = 1
			begin
				if @invoiceseparation = 0
					begin
					
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
										,RecordStatus = 1
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
								,RecordStatus = 1
								from InvoiceDetails d
								where ChainID = @entityidtoinvoice
								and RetailerInvoiceID = -1
								and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
					end
				else
					begin
						if @invoiceseparation = 1 --by store
							begin
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
								and StoreID = @storeid
								and RetailerInvoiceID = -1
								and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
								group by Saledate
								Having Sum(TotalCost) < 0
								
								set @invoiceheaderid = SCOPE_IDENTITY()
								
								update d set RetailerInvoiceID = @invoiceheaderid
								,RecordStatus = 1
								from InvoiceDetails d																		
								inner join 
								(
									select productid, brandid, SaleDate
									from InvoiceDetails
									where ChainID = @entityidtoinvoice
									and StoreID = @storeid
									and RetailerInvoiceID = -1
									and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
									Group by productid, brandid, SaleDate
									having Sum(TotalCost) < 0																							
								) c
								on d.productid = c.productid and d.brandid = c.brandid and d.saledate = c.saledate													
								where ChainID = @entityidtoinvoice
								and StoreID = @storeid
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
						   ,@invoicetype
						   ,SUM(TotalCost)
						   ,@MyID
						   ,1
						from InvoiceDetails
						where ChainID = @entityidtoinvoice
						and StoreID = @storeid
						and RetailerInvoiceID = -1
						and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
						
						set @invoiceheaderid = SCOPE_IDENTITY()
						
						update d set RetailerInvoiceID = @invoiceheaderid
						,RecordStatus = 1
						from InvoiceDetails d
						where ChainID = @entityidtoinvoice
						and StoreID = @storeid
						and RetailerInvoiceID = -1
						and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
						fetch next from @recstore into @storeid
					end
					
				close @recstore
				deallocate @recstore
		end
	if @invoiceseparation = 2 --by store and supplier
		begin
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
									and StoreID = @storeid
									and SupplierID = @supplierid
									and RetailerInvoiceID = -1
									and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
									group by Saledate
									Having Sum(TotalCost) < 0
									
									set @invoiceheaderid = SCOPE_IDENTITY()
																
							update d set RetailerInvoiceID = @invoiceheaderid
							,RecordStatus = 1
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
							and StoreID = @storeid
							and SupplierID = @supplierid
							and RetailerInvoiceID = -1
							and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
							
							set @invoiceheaderid = SCOPE_IDENTITY()
																
											update d set RetailerInvoiceID = @invoiceheaderid
											,RecordStatus = 1
											from InvoiceDetails d
											where ChainID = @entityidtoinvoice
											and StoreID = @storeid
											and SupplierID = @supplierid
											and RetailerInvoiceID = -1
											and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
											
										fetch next from @recsupplier into @supplierid
								end
							
							close @recsupplier
							deallocate @recsupplier
								
						fetch next from @recstore into @storeid
					end
					
				close @recstore
				deallocate @recstore
		end
										
										
	if @invoiceseparation = 3 --by store, supplier, detailtypeid
		begin
			declare @invoicedetailtypeid tinyint
			declare @detailtypeid1 int
			declare @detailtypeid2 int
			declare @recdetailtype cursor
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
								set @invoiceheaderid = null
								if @invoicetype = 0																			
									begin --since original billing combine original and adjustments under one invoiceid
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
										insert #temptypes (detailtypeid) values(@detailtypeid2)	
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
												and InvoiceDetailTypeID in (select detailtypeid from #temptypes)
												Group by productid, brandid, SaleDate
												having Sum(TotalCost) < 0
												
												set @invoiceheaderid = SCOPE_IDENTITY()
											
												update d set RetailerInvoiceID = @invoiceheaderid
												,RecordStatus = 1
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
													and InvoiceDetailTypeID in (select detailtypeid from #temptypes)
													Group by productid, brandid, SaleDate
													having Sum(TotalCost) < 0																							
												) c
												on d.productid = c.productid and d.brandid = c.brandid and d.saledate = c.saledate
												where ChainID = @entityidtoinvoice
												and StoreID = @storeid
												and SupplierID = @supplierid
												and InvoiceDetailTypeID in (select detailtypeid from #temptypes)
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
						and InvoiceDetailTypeID in (select detailtypeid from #temptypes)
						
						set @invoiceheaderid = SCOPE_IDENTITY()
					
						update d set RetailerInvoiceID = @invoiceheaderid
						,RecordStatus = 1
						from InvoiceDetails d
						where ChainID = @entityidtoinvoice
						and StoreID = @storeid
						and SupplierID = @supplierid
						and InvoiceDetailTypeID in (select detailtypeid from #temptypes)
						and RetailerInvoiceID = -1
						and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
						
					--end
				drop table #temptypes
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
								Group by productid, brandid, SaleDate, InvoiceDetailTypeID
								having Sum(TotalCost) < 0
																											
								set @invoiceheaderid = SCOPE_IDENTITY()
									
								update d set RetailerInvoiceID = @invoiceheaderid
								,RecordStatus = 1
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
									Group by productid, brandid, SaleDate
									having Sum(TotalCost) < 0																							
								) c
								on d.productid = c.productid and d.brandid = c.brandid and d.saledate = c.saledate
								where ChainID = @entityidtoinvoice
								and StoreID = @storeid
								and SupplierID = @supplierid
								and InvoiceDetailTypeID = @invoicedetailtypeid
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
																									
						set @invoiceheaderid = SCOPE_IDENTITY()
							
						update d set RetailerInvoiceID = @invoiceheaderid
						,RecordStatus = 1
						from InvoiceDetails d
						where ChainID = @entityidtoinvoice
						and StoreID = @storeid
						and SupplierID = @supplierid
						and InvoiceDetailTypeID = @invoicedetailtypeid
						and RetailerInvoiceID = -1
						and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
						
						
					end
										fetch next from @recdetailtype into @invoicedetailtypeid
											
										end
											
									close @recdetailtype
									deallocate @recdetailtype
											
											
										fetch next from @recsupplier into @supplierid
								end
							
							close @recsupplier
							deallocate @recsupplier
								
						fetch next from @recstore into @storeid
					end
					
				close @recstore
				deallocate @recstore
		end										
		
			end --if @invoiceseparation = 0
			
					
				if @invoiceseparation = 4 --by store, supplier, detailtypeid
					begin
						declare @recpono cursor
						declare @pono nvarchar(50)

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
--*
Set @recsupplier = CURSOR local fast_forward FOR
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
					select distinct PONo
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
								begin --since original billing combine original and adjustments under one invoiceid
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
											and PONo = @PONo
											--and InvoiceDetailTypeID = @invoicedetailtypeid
											--and InvoiceDetailTypeID in (1,7)
											Group by productid, brandid, SaleDate
											having Sum(TotalCost) < 0
											
											set @invoiceheaderid = SCOPE_IDENTITY()
										
											update d set RetailerInvoiceID = @invoiceheaderid
											,RecordStatus = 1
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
												and PONo = @PONo
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
											and PONo = @PONo
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
						and PONo = @PONo
						
						set @invoiceheaderid = SCOPE_IDENTITY()
					
						update d set RetailerInvoiceID = @invoiceheaderid
						,RecordStatus = 1
						from InvoiceDetails d
						where ChainID = @entityidtoinvoice
						and StoreID = @storeid
						and SupplierID = @supplierid
						and InvoiceDetailTypeID in (select detailtypeid from #temptypes2)
						and PONo = @PONo
						and RetailerInvoiceID = -1
						and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
						
					--end
				drop table #temptypes2
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
									and PONo = @PONo
									Group by productid, brandid, SaleDate, InvoiceDetailTypeID
									having Sum(TotalCost) < 0
																												
									set @invoiceheaderid = SCOPE_IDENTITY()
										
									update d set RetailerInvoiceID = @invoiceheaderid
									,RecordStatus = 1
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
										and PONo = @PONo
										Group by productid, brandid, SaleDate
										having Sum(TotalCost) < 0																							
									) c
									on d.productid = c.productid and d.brandid = c.brandid and d.saledate = c.saledate
									where ChainID = @entityidtoinvoice
									and StoreID = @storeid
									and SupplierID = @supplierid
									and InvoiceDetailTypeID = @invoicedetailtypeid
									and PONo = @PONo
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
							and PONo = @PONo
																										
							set @invoiceheaderid = SCOPE_IDENTITY()
								
							update d set RetailerInvoiceID = @invoiceheaderid
							,RecordStatus = 1
							from InvoiceDetails d
							where ChainID = @entityidtoinvoice
							and StoreID = @storeid
							and SupplierID = @supplierid
							and InvoiceDetailTypeID = @invoicedetailtypeid
							and PONo = @PONo
							and RetailerInvoiceID = -1
							and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
							
							
						end
																		
																	fetch next from @recpono into @pono
																end
																
																close @recpono
																deallocate @recpono
																			
																fetch next from @recdetailtype into @invoicedetailtypeid
																
															end
																
														close @recdetailtype
														deallocate @recdetailtype
								
																
															fetch next from @recsupplier into @supplierid
													end
												
												close @recsupplier
												deallocate @recsupplier
													
											fetch next from @recstore into @storeid
										end
										
									close @recstore
									deallocate @recstore
					end --if @invoiceseparation = 4								
					end
					
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
					
					commit transaction
				end
		end try
			
		begin catch
		
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
			@job_name = 'DailyPOSBilling_THIS_IS_CURRENT_ONE'

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Daily Billing Job Stopped'
				,'Retailer and supplier invoicing has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'datatrueit@icontroldsd.com;edi@icontroldsd.com'		
		
end catch

NextBilling:
		
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
	end
	
close @rec
deallocate @rec


delete from DataTrue_Main..InvoicesRetailer where originalamount is null

update d set d.recordstatus = 1
from DataTrue_EDI.dbo.Invoicedetails d
where Banner = 'SYNC'
and RecordStatus = 0
and CAST(saledate as date) < '6/4/2012'

return
GO
