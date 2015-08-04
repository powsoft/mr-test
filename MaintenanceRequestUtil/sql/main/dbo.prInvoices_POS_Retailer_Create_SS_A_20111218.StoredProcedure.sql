USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoices_POS_Retailer_Create_SS_A_20111218]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Batch submitted through debugger: SQLQuery191.sql|7|0|C:\Users\SQLAdmin\AppData\Local\Temp\3\~vsC251.sql
CREATE procedure [dbo].[prInvoices_POS_Retailer_Create_SS_A_20111218]
@billingcontrolfrequency nvarchar(50)='DAILY'--,
--@numberofperiodstorun smallint=1
as
/*

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

--Set billingcontrol
--select DATEDIFF(day,'12/1/2011',getdate())

UPDATE [DataTrue_Main].[dbo].[BillingControl]
   SET [BillingControlNumberOfPastDaysToRebill] = 160 --DATEDIFF(day,'12/1/2011',getdate())
      ,[InvoiceSeparation] = 3
      ,[LastBillingPeriodEndDateTime] =  cast(DATEADD(day, -2, getdate()) as date)
      ,[NextBillingPeriodEndDateTime] = cast(DATEADD(day, -1, getdate()) as date)
      ,[NextBillingPeriodRunDateTime] =  cast(getdate() as date)
 WHERE BillingControlID > 14
 and BillingControlFrequency = 'DAILY'
  and EntityIDToInvoice in (40393)
 
 
set @currentdatetime = GETDATE()

set @rec = CURSOR local fast_forward for
	select BillingControlID, EntityIDToInvoice, BillingControlDay, BillingControlClosingDelay,
		ProductSubGroupType, ProductSubGroupID, NextBillingPeriodRunDateTime, 
		InvoiceSeparation, BillingControlNumberOfPastDaysToRebill, NextBillingPeriodEndDateTime, SeparateCredits
	from billingcontrol c
	inner join systementities s
	on c.EntityIDToInvoice = s.EntityID
	where s.EntityTypeID = 2
	--and nextbillingperiodrundatetime <= getdate() --@currentdatetime
	--and billingcontrolfrequency = 'Weekly' --@billingcontrolfrequency
	and nextbillingperiodrundatetime <= @currentdatetime
	and billingcontrolfrequency = @billingcontrolfrequency
	and IsActive = 1
	and EntityIDToInvoice in (40393)

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
		
--print '1'
--print 'invoiceseparation'
--print @invoiceseparation
		
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
			
/*			
			select @PutCreditsOnSeparateInvoice = AttributeValue
			--select *
			from AttributeValues v
			inner join AttributeDefinitions d
			on v.AttributeID = d.AttributeID
			where d.AttributeName = 'PutCreditsOnSeparateInvoice'
			and v.OwnerEntityID = @entityidtoinvoice
			
			if @@ROWCOUNT < 1
				set @PutCreditsOnSeparateInvoice = 'NO'
*/
			
			--determine billing start date and billing end date
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
--print @numberofperiodstorun
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
					
					select distinct ProductID, BrandID, BillingRuleID--, 
					--RetailerShrinkPercent, SupplierShrinkPercent, ManufacturerShrinkPercent
					into #tempStoreSetupProducts 
					from ChainProductFactors
					--from StoreSetup
					where ChainID = @EntityIDToInvoice
					
					
					if @@ROWCOUNT < 1
						goto NextBilling	
						
--select * from #tempStoreSetupProducts
					--IF EXISTS (SELECT * FROM sys.tables WHERE name like '%#tempProductsToInvoice%')
					begin try
						DROP TABLE #tempProductsToInvoice
					end try
					begin catch
						set @dummyerrorcatch = 0
					end catch
					--if exists(select null from #tempProductsToInvoice)
					--	drop table #tempProductsToInvoice				
					
					select * into #tempProductsToInvoice from #tempStoreSetupProducts
					--select * into Import.dbo.ztmpInvoiceingResearch  from #tempStoreSetupProducts
					
				
--select * from #tempStoreSetupProducts
--print @productsubgrouptype					
					--get any subgroup limits and apply
					--*************************************************************
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
									/*
									if @@ROWCOUNT < 1
											begin
												goto NextBilling
											end
										else
											begin
											
											end
									*/									
								end							
							
							

						end
					--else
					--	begin
							--select * into #tempProductsToInvoice 
							--from #tempStoreSetupProducts
					--	end					


				
			while @numberofperiodsrun < @numberofperiodstorun
				begin			
					begin transaction
--print '2'									
					
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
							and LTRIM(rtrim(d.SupplierIdentifier)) <> '0665638590000'
							and LTRIM(rtrim(d.Banner)) = 'SS'
--0665638590000 1095
--0009269990000 1468 1456 1593
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
							and LTRIM(rtrim(d.SupplierIdentifier)) <> '0665638590000'
							and LTRIM(rtrim(d.Banner)) = 'SS'
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
					and LTRIM(rtrim(d.SupplierIdentifier)) <> '0665638590000'
					and LTRIM(rtrim(d.Banner)) = 'SS'
												
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
					and LTRIM(rtrim(d.SupplierIdentifier)) <> '0665638590000'
					and LTRIM(rtrim(d.Banner)) = 'SS'
										
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
--**************************************************************************************************													
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
--***************************************************************************************************													
														fetch next from @recstore into @storeid
													end
													
												close @recstore
												deallocate @recstore
										end
									if @invoiceseparation = 2 --by store and supplier
										begin
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
--/*																
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
--/*																
																			update d set RetailerInvoiceID = @invoiceheaderid
																			,RecordStatus = 1
																			from InvoiceDetails d
																			where ChainID = @entityidtoinvoice
																			and StoreID = @storeid
																			and SupplierID = @supplierid
																			and RetailerInvoiceID = -1
																			and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
--*/												
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
																			,RecordStatus = 1
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
										end
										
------------------------------------------------------------------------------------------------------										
										
									if @invoiceseparation = 3 --by store, supplier, detailtypeid
										begin
											declare @invoicedetailtypeid tinyint
											declare @detailtypeid1 int
											declare @detailtypeid2 int
											declare @recdetailtype cursor
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
																			set @invoiceheaderid = null
																			if @invoicetype = 0																			
																			-- @invoicedetailtypeid = 1 and @invoicetype = 0
																				begin --since original billing combine original and adjustments under one invoiceid
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
																								and InvoiceDetailTypeID in (select detailtypeid from #temptypes)
																								--and InvoiceDetailTypeID = @invoicedetailtypeid
																								--and InvoiceDetailTypeID in (1,7)
																								Group by productid, brandid, SaleDate
																								having Sum(TotalCost) < 0																							
																							) c
																							on d.productid = c.productid and d.brandid = c.brandid and d.saledate = c.saledate
																							where ChainID = @entityidtoinvoice
																							and StoreID = @storeid
																							and SupplierID = @supplierid
																							and InvoiceDetailTypeID in (select detailtypeid from #temptypes)
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
																							and InvoiceDetailTypeID in (select detailtypeid from #temptypes)
																							--and InvoiceDetailTypeID = @invoicedetailtypeid
																							--and InvoiceDetailTypeID in (1,7)
																							--Group by productid, brandid
																							
																							set @invoiceheaderid = SCOPE_IDENTITY()
																						
																							update d set RetailerInvoiceID = @invoiceheaderid
																							,RecordStatus = 1
																							from InvoiceDetails d
																							where ChainID = @entityidtoinvoice
																							and StoreID = @storeid
																							and SupplierID = @supplierid
																							and InvoiceDetailTypeID in (select detailtypeid from #temptypes)
																							--and InvoiceDetailTypeID = @invoicedetailtypeid
																							--and InvoiceDetailTypeID in (1,7)
																							and RetailerInvoiceID = -1
																							and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
																							
																						--end
																					drop table #temptypes
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
																							,RecordStatus = 1
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
																							,RecordStatus = 1
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
																			,RecordStatus = 1
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
										end										
										
										
										
										
------------------------------------------------------------------------------------------------------										
										
								end --if @invoiceseparation = 0
								
										
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
																									and PONo = @PONo
																									--and InvoiceDetailTypeID = @invoicedetailtypeid
																									--and InvoiceDetailTypeID in (1,7)
																									--Group by productid, brandid
																									
																									set @invoiceheaderid = SCOPE_IDENTITY()
																								
																									update d set RetailerInvoiceID = @invoiceheaderid
																									,RecordStatus = 1
																									from InvoiceDetails d
																									where ChainID = @entityidtoinvoice
																									and StoreID = @storeid
																									and SupplierID = @supplierid
																									and InvoiceDetailTypeID in (select detailtypeid from #temptypes2)
																									and PONo = @PONo
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
																									,RecordStatus = 1
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
																									,RecordStatus = 1
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
																			,RecordStatus = 1
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
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;edi@icontroldsd.com'		
		
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

--*******************************************************************************************************

delete from DataTrue_Main..InvoicesRetailer where originalamount is null

----*******************************************************************************************************

return
GO
