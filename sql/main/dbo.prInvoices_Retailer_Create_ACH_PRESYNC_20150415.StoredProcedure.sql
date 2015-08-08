USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoices_Retailer_Create_ACH_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Batch submitted through debugger: SQLQuery191.sql|7|0|C:\Users\SQLAdmin\AppData\Local\Temp\3\~vsC251.sql
CREATE procedure [dbo].[prInvoices_Retailer_Create_ACH_PRESYNC_20150415]
@billingcontrolfrequency nvarchar(50)='DAILY'--,
--@numberofperiodstorun smallint=1
as
/*
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

--select *
--from [DataTrue_Main].[dbo].[ChainProductFactors]
--where chainid = 50730
 
-- INSERT INTO [DataTrue_Main].[dbo].[ChainProductFactors]
--           ([ChainID]
--           ,[ProductID]
--           ,[BrandID]
--           ,[BaseUnitsCalculationPerNoOfweeks]
--           ,[CostFromRetailPercent]
--           ,[BillingRuleID]
--           ,[IncludeDollarDiffDetails]
--           ,[ActiveStartDate]
--           ,[ActiveEndDate]
--           ,[LastUpdateUserID])
--select tp.chainid
--		,p.ProductId
--		,0
--		,17
--		,75
--		,2
--		,1
--		,'2000-01-01 00:00:00'
--		,'12/31/2025'
--		,2
--from Products p
--inner join 
--(
--	select distinct productid, chainid 
--	from storetransactions 
--	where ChainID in
--	(
--		select ChainID 
--		from datatrue_main.dbo.chains c
--		inner join DataTrue_EDI.dbo.ProcessStatus_ACH pr
--		on ltrim(rtrim(pr.ChainName)) = ltrim(rtrim(c.ChainIdentifier))
--		Where BillingIsRunning = 1
--		and BillingComplete = 0
--	)
--) tp
--on tp.productid = p.productid
--where p.ProductID not in 
--(
--	select productid 
--	from ChainProductFactors 
--	where ChainID in
--	(
--		select ChainID 
--		from datatrue_main.dbo.chains c
--		inner join DataTrue_EDI.dbo.ProcessStatus_ACH pr
--		on ltrim(rtrim(pr.ChainName)) = ltrim(rtrim(c.ChainIdentifier))
--		Where BillingIsRunning = 1
--		and BillingComplete = 0
--	)
--) 

--select * from billingcontrol

set @currentdatetime = GETDATE()

DECLARE @ProcessID INT

SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobName = 'DailyRegulatedBilling'

DECLARE @jobLastRan DATETIME

SELECT @jobLastRan = (SELECT JobLastRunDateTime FROM JobRunning WHERE JobName = 'DailyRegulatedBilling')

UPDATE c    SET [BillingControlNumberOfPastDaysToRebill] = 30 
      ,[InvoiceSeparation] = 4
      ,[LastBillingPeriodEndDateTime] =  cast(DATEADD(day, -2, getdate()) as date)
      ,[NextBillingPeriodEndDateTime] = ISNULL((SELECT MAX(SaleDate) FROM DataTrue_Main.dbo.InvoiceDetails WHERE ProcessID = @ProcessID AND ChainID = c.ChainID), GETDATE())
      --,[NextBillingPeriodEndDateTime] = cast(getdate() as date) 
      ,[NextBillingPeriodRunDateTime] =  cast(getdate() as date)
      from [DataTrue_Main].[dbo].[BillingControl] c
      inner join systementities s
      on c.EntityIDToInvoice = s.EntityID
      and s.EntityTypeID = 2 
      and c.IsActive = 1
      and c.BusinessTypeID = 2
      and c.nextbillingperiodrundatetime <> @currentdatetime
      and c.billingcontrolfrequency = @billingcontrolfrequency
      and c.EntityIDToInvoice in (select distinct ChainID from InvoiceDetails as id with (Nolock) where id.ProcessID = @ProcessID AND RetailerInvoiceID IS NULL)




set @rec = CURSOR local fast_forward for
	select BillingControlID, EntityIDToInvoice, BillingControlDay, BillingControlClosingDelay,
		ProductSubGroupType, ProductSubGroupID, NextBillingPeriodRunDateTime, 
		InvoiceSeparation, BillingControlNumberOfPastDaysToRebill, NextBillingPeriodEndDateTime, SeparateCredits
	from billingcontrol c
	inner join systementities s
	on c.EntityIDToInvoice = s.EntityID
	and s.EntityTypeID = 2
	and IsActive = 1
	AND c.ChainID IN (SELECT DISTINCT ChainID FROM InvoiceDetails WHERE ProcessID = @ProcessID)
	--and ISACH = 1
	and nextbillingperiodrundatetime <= @currentdatetime
	and billingcontrolfrequency = @billingcontrolfrequency
	and c.EntityIDToInvoice in (select distinct ChainID from InvoiceDetails as id with (Nolock) where id.ProcessID = @ProcessID AND RetailerInvoiceID IS NULL)
	and c.BusinessTypeID = 2

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
		,2
		,1
		,'2000-01-01 00:00:00'
		,'12/31/2025'
		,2
from Products
where ProductID in (select distinct productid from storetransactions with (nolock) where ChainID = @EntityIDToInvoice)
and ProductID not in (select productid from ChainProductFactors with (nolock) where ChainID = @EntityIDToInvoice) 		

UPDATE [DataTrue_Main].[dbo].[ChainProductFactors]
SET BillingRuleID = 1
WHERE ProductID IN
(
SELECT ProductID FROM [DataTrue_Main].[dbo].[ProductIdentifiers] WHERE ProductIdentifierTypeID = 8
)
AND ChainID = @EntityIDToInvoice

UPDATE [DataTrue_Main].[dbo].[ChainProductFactors]
SET BillingRuleID = 2
WHERE ProductID IN
(
SELECT DISTINCT ProductID FROM [DataTrue_Main].[dbo].[InvoiceDetails] WHERE ProcessID = @ProcessID
)
AND ChainID = @EntityIDToInvoice
AND BillingRuleID <> 2
		
		
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
					
					--SET @numberofperiodstorun = ISNULL(DATEDIFF(d, (SELECT MIN(SaleDate) FROM DataTrue_Main.dbo.InvoiceDetails WHERE ProcessID = @ProcessID AND ChainID = @EntityIDToInvoice), @nextbillingperiodenddatetime), @numberofperiodstorun)
					SET @numberofperiodstorun = ISNULL(DATEDIFF(d, (SELECT MIN(EffectiveDate) FROM DataTrue_EDI.dbo.Inbound846Inventory_ACH_Approval WHERE RecordStatus = 1 AND ApprovalTimeStamp > @jobLastRan AND ChainName = (SELECT ChainIdentifier FROM Chains WHERE ChainID = @EntityIDToInvoice)), @nextbillingperiodenddatetime), @numberofperiodstorun)
					
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
					
--select * from #tempProductsToInvoice				
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
									and left(c.HierarchyID.ToString(),3) = @tophierarchyidtostring
									
									
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
						
			select * from #tempProductsToInvoice where ProductID in
			(
			select distinct ProductID 
			from InvoiceDetails with (index(83))
			where ProcessID = @ProcessID
			and RetailerInvoiceID is null
			)
				
			while @numberofperiodsrun <= @numberofperiodstorun
				begin			
					
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
							from InvoiceDetails AS d WITH (NOLOCK,index(83))
							inner join #tempProductsToInvoice t
							on d.ProductID = t.ProductID 
							and d.BrandID = t.BrandID
							and d.ChainID = @EntityIDToInvoice
							and t.BillingRuleID in (1,3)
							and d.InvoiceDetailTypeID in (1) --,7) --change here wait --POS Only
							and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
							and d.RetailerInvoiceID is null
							and ProcessID = @ProcessID
							--change here wait
							--and LTRIM(rtrim(d.SupplierIdentifier)) <> '0665638590000'
							--and LTRIM(rtrim(d.Banner)) <> 'SS'
							
--0665638590000 1095
--0009269990000 1468 1456 1593
						end
					else
						begin
							update d set d.RetailerInvoiceID = -1 
							from InvoiceDetails AS d WITH (NOLOCK,index(83))
							inner join #tempProductsToInvoice t
							on d.ProductID = t.ProductID 
							and d.BrandID = t.BrandID
							and d.ChainID = @EntityIDToInvoice
							and t.BillingRuleID in (1,3)
							and d.InvoiceDetailTypeID in (1) --,7) --change here wait ,7) --POS Only
							and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
							and d.RetailerInvoiceID is null
							and ProcessID = @ProcessID
							--change here wait
							--and LTRIM(rtrim(d.SupplierIdentifier)) <> '0665638590000'
							--and LTRIM(rtrim(d.Banner)) <> 'SS'
							
						end
					if @@rowcount > 0
						begin
							set @needtoinvoice = 1
						end

					--Any Rule 2/SUP + Shrink products detailtypeid 2 or 3
					update d set d.RetailerInvoiceID = -1 
					from InvoiceDetails AS d WITH (NOLOCK,index(83))
					inner join #tempProductsToInvoice t
					on d.ProductID = t.ProductID 
					and d.BrandID = t.BrandID
					and d.ChainID = @EntityIDToInvoice
					--and t.BillingRuleID in (2)
					and t.BillingRuleID = 2
					and d.InvoiceDetailTypeID in (2,3,8,9)
					and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
					and d.RetailerInvoiceID is null
					and d.RecordType <> 3
					and ProcessID = @ProcessID
					
					if @@rowcount > 0
						begin
							set @needtoinvoice = 1
						end
						
					update d set d.RetailerInvoiceID = -1 
					from InvoiceDetails AS d WITH (NOLOCK,index(83))
					inner join #tempProductsToInvoice t
					on d.ProductID = t.ProductID 
					and d.BrandID = t.BrandID
					and d.ChainID = @EntityIDToInvoice
					--and t.BillingRuleID in (2)
					and t.BillingRuleID in (0, 2)
					and d.InvoiceDetailTypeID in (2,3,8,9)
					and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
					and d.RetailerInvoiceID is null
					and d.RecordType = 3
					and ProcessID = @ProcessID
					
					if @@rowcount > 0
						begin
							set @needtoinvoice = 1
						end

					--Any Rule 2/SUP + Shrink products detailtypeid 2 or 3
					update d set d.RetailerInvoiceID = -1 
					from InvoiceDetails AS d WITH (NOLOCK,index(83))
					inner join #tempProductsToInvoice t
					on d.ProductID = t.ProductID 
					and d.BrandID = t.BrandID
					and d.ChainID = @EntityIDToInvoice
					and t.BillingRuleID in (3)
					and d.InvoiceDetailTypeID in (3,4,9) 
					and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
					and d.RetailerInvoiceID is null
					and ProcessID = @ProcessID
					
					
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
													   ,[InvoiceStatus]
													   ,[ProcessID]
													   ,[RawStoreIdentifier]
													   ,[InvoiceNumber]
													   ,[PaymentDueDate]
													   ,[Route]
													   ,[StoreID]
													   ,[AccountCode]
													   ,[RefIDToOriginalInvNo])
												 select @EntityIDToInvoice
													   ,@billingperiodstartdatetime
													   ,@billingperiodenddatetime
													   ,SUM(TotalCost)
													   ,@invoicetype
													   ,SUM(TotalCost)
													   ,@MyID
													   ,1
													   ,@ProcessID
													   ,MAX(RawStoreIdentifier)
													   ,MAX(InvoiceNo)
													   ,MAX(PaymentDueDate)
													   ,MAX(Route)
													   ,MAX(StoreID)
													   ,MAX(AccountCode)
													   ,MAX(RefIDToOriginalInvNo)
													from InvoiceDetails with (NOLOCK)
													where ChainID = @entityidtoinvoice
													and RetailerInvoiceID = -1
													and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
													and ProcessID = @ProcessID
													Group by Saledate
													having Sum(TotalCost) < 0
													
													
													set @invoiceheaderid = SCOPE_IDENTITY()
													
													update d set RetailerInvoiceID = @invoiceheaderid
													,Recordstatus = 4
													from InvoiceDetails AS d WITH (NOLOCK)	
													inner join 
													(
														select productid, brandid, SaleDate
														from InvoiceDetails with (nolock)
														where ChainID = @entityidtoinvoice
														and RetailerInvoiceID = -1
														and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
														Group by productid, brandid, SaleDate
														having Sum(TotalCost) < 0																							
													) c
													on d.productid = c.productid and d.brandid = c.brandid and d.saledate = c.saledate
													and ChainID = @entityidtoinvoice
													and RetailerInvoiceID = -1
													and d.SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
													and d.ProcessID = @ProcessID
										end
									
									INSERT INTO [DataTrue_Main].[dbo].[InvoicesRetailer]
											   ([ChainID]
											   ,[InvoicePeriodStart]
											   ,[InvoicePeriodEnd]
											   ,[OriginalAmount]
											   ,[InvoiceTypeID]
											   ,[OpenAmount]
											   ,[LastUpdateUserID]
											   ,[InvoiceStatus]
											   ,[ProcessID]
											   ,[RawStoreIdentifier]
											   ,[InvoiceNumber]
											   ,[PaymentDueDate]
											   ,[Route]
											   ,[StoreID]
											   ,[AccountCode]
											   ,[RefIDToOriginalInvNo])
										 select @EntityIDToInvoice
											   ,@billingperiodstartdatetime
											   ,@billingperiodenddatetime
											   ,SUM(TotalCost)
											   ,@invoicetype
											   ,SUM(TotalCost)
											   ,@MyID
											   ,1
											   ,@ProcessID
											   ,MAX(RawStoreIdentifier)
											   ,MAX(InvoiceNo)
											   ,MAX(PaymentDueDate)
											   ,MAX(Route)
											   ,MAX(StoreID)
											   ,MAX(AccountCode)
											   ,MAX(RefIDToOriginalInvNo)
											from InvoiceDetails with (nolock)
											where ChainID = @entityidtoinvoice
											and RetailerInvoiceID = -1
											and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
											and ProcessID = @ProcessID
											
											set @invoiceheaderid = SCOPE_IDENTITY()
											
											update d set RetailerInvoiceID = @invoiceheaderid
											,Recordstatus = 4
											from InvoiceDetails AS d WITH (NOLOCK)
											where ChainID = @entityidtoinvoice
											and RetailerInvoiceID = -1
											and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
											and ProcessID = @ProcessID
								end
							else
								begin
									if @invoiceseparation = 1 --by store
										begin
											set @recstore = CURSOR local fast_forward FOR
												select distinct StoreID
												from InvoiceDetails with (nolock)
												where ChainID = @entityidtoinvoice
												and RetailerInvoiceID = -1
												and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
												and ProcessID = @ProcessID
												
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
																		   ,[InvoiceStatus]
																		   ,[ProcessID]
																		   ,[RawStoreIdentifier]
																		   ,[InvoiceNumber]
																		   ,[PaymentDueDate]
																		   ,[Route]
																		   ,[StoreID]
																		   ,[AccountCode]
																		   ,[RefIDToOriginalInvNo])
																	 select @EntityIDToInvoice
																		   ,@billingperiodstartdatetime
																		   ,@billingperiodenddatetime
																		   ,SUM(TotalCost)
																		   ,@invoicetype
																		   ,SUM(TotalCost)
																		   ,@MyID
																		   ,1
																		   ,@ProcessID
																		   ,MAX(RawStoreIdentifier)
																		   ,MAX(InvoiceNo)
																		   ,MAX(PaymentDueDate)
																		   ,MAX(Route)
																		   ,MAX(StoreID)
																		   ,MAX(AccountCode)
																		   ,MAX(RefIDToOriginalInvNo)
																		from InvoiceDetails with (nolock)
																		where ChainID = @entityidtoinvoice
																		and StoreID = @storeid
																		and RetailerInvoiceID = -1
																		and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
																		and ProcessID = @ProcessID
																		group by Saledate
																		Having Sum(TotalCost) < 0
																		
																		
																		set @invoiceheaderid = SCOPE_IDENTITY()
																		
																		update d set RetailerInvoiceID = @invoiceheaderid
																		,Recordstatus = 4
																		from InvoiceDetails AS d WITH (NOLOCK)																		
																		inner join 
																		(
																			select productid, brandid, SaleDate
																			from InvoiceDetails with (nolock)
																			where ChainID = @entityidtoinvoice
																			and StoreID = @storeid
																			and RetailerInvoiceID = -1
																			and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
																			Group by productid, brandid, SaleDate
																			having Sum(TotalCost) < 0																							
																		) c
																		on d.productid = c.productid and d.brandid = c.brandid and d.saledate = c.saledate													
																		and ChainID = @entityidtoinvoice
																		and StoreID = @storeid
																		and RetailerInvoiceID = -1
																		and d.SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
																		and d.ProcessID = @ProcessID
															end
															
														INSERT INTO [DataTrue_Main].[dbo].[InvoicesRetailer]
																   ([ChainID]
																   ,[InvoicePeriodStart]
																   ,[InvoicePeriodEnd]
																   ,[OriginalAmount]
																   ,[InvoiceTypeID]
																   ,[OpenAmount]
																   ,[LastUpdateUserID]
																   ,[InvoiceStatus]
																   ,[ProcessID]
																   ,[RawStoreIdentifier]
																   ,[InvoiceNumber]
																   ,[PaymentDueDate]
																   ,[Route]
																   ,[StoreID]
																   ,[AccountCode]
																   ,[RefIDToOriginalInvNo])
															 select @EntityIDToInvoice
																   ,@billingperiodstartdatetime
																   ,@billingperiodenddatetime
																   ,SUM(TotalCost)
																   ,@invoicetype
																   ,SUM(TotalCost)
																   ,@MyID
																   ,1
																   ,@ProcessID
																   ,MAX(RawStoreIdentifier)
																   ,MAX(InvoiceNo)
																   ,MAX(PaymentDueDate)
																   ,MAX(Route)
																   ,MAX(StoreID)
																   ,MAX(AccountCode)
																   ,MAX(RefIDToOriginalInvNo)
																from InvoiceDetails with (nolock)
																where ChainID = @entityidtoinvoice
																and StoreID = @storeid
																and RetailerInvoiceID = -1
																and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
																and ProcessID = @ProcessID
																
																set @invoiceheaderid = SCOPE_IDENTITY()
																
																update d set RetailerInvoiceID = @invoiceheaderid
																,Recordstatus = 4
																from InvoiceDetails AS d WITH (NOLOCK)
																where ChainID = @entityidtoinvoice
																and StoreID = @storeid
																and RetailerInvoiceID = -1
																and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
																and ProcessID = @ProcessID
																
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
												from InvoiceDetails with (nolock)
												where ChainID = @entityidtoinvoice
												and RetailerInvoiceID = -1
												and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
												and ProcessID = @ProcessID
												
												open @recstore
												
												fetch next from @recstore into @storeid
												
												while @@FETCH_STATUS = 0
													begin
--**************************************************************************************************

														set @recsupplier = CURSOR local fast_forward FOR
															select distinct SupplierID
															from InvoiceDetails with (nolock)
															where ChainID = @entityidtoinvoice
															and StoreID = @storeid
															and RetailerInvoiceID = -1
															and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
															and ProcessID = @ProcessID
															
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
																			   ,[InvoiceStatus]
																			   ,[ProcessID]
																			   ,[RawStoreIdentifier]
																			   ,[InvoiceNumber]
																			   ,[PaymentDueDate]
																			   ,[Route]
																			   ,[StoreID]
																			   ,[AccountCode]
																			   ,[RefIDToOriginalInvNo])
																		 select @EntityIDToInvoice
																			   ,@billingperiodstartdatetime
																			   ,@billingperiodenddatetime
																			   ,SUM(TotalCost)
																			   ,@invoicetype
																			   ,SUM(TotalCost)
																			   ,@MyID
																			   ,1
																			   ,@ProcessID
																			   ,MAX(RawStoreIdentifier)
																			   ,MAX(InvoiceNo)
																			   ,MAX(PaymentDueDate)
																			   ,MAX(Route)
																			   ,MAX(StoreID)
																			   ,MAX(AccountCode)
																			   ,MAX(RefIDToOriginalInvNo)
																			from InvoiceDetails with (nolock)
																			where ChainID = @entityidtoinvoice
																			and StoreID = @storeid
																			and SupplierID = @supplierid
																			and RetailerInvoiceID = -1
																			and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
																			and ProcessID = @ProcessID
																			group by Saledate
																			Having Sum(TotalCost) < 0
																			
																			
																			set @invoiceheaderid = SCOPE_IDENTITY()
--/*																
																			update d set RetailerInvoiceID = @invoiceheaderid
																			,Recordstatus = 4
																			from InvoiceDetails AS d WITH (NOLOCK)
																			inner join 
																			(
																				select productid, brandid, SaleDate
																				from InvoiceDetails with (nolock)
																				where ChainID = @entityidtoinvoice
																				and StoreID = @storeid
																				and SupplierID = @supplierid
																				and RetailerInvoiceID = -1
																				and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
																				Group by productid, brandid, SaleDate
																				having Sum(TotalCost) < 0																							
																			) c
																			on d.productid = c.productid and d.brandid = c.brandid and d.saledate = c.saledate	
																			and ChainID = @entityidtoinvoice
																			and StoreID = @storeid
																			and SupplierID = @supplierid
																			and RetailerInvoiceID = -1
																			and d.SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
																			and ProcessID = @ProcessID
																		
																		
																		end
																		
																		
																		
																	INSERT INTO [DataTrue_Main].[dbo].[InvoicesRetailer]
																			   ([ChainID]
																			   ,[InvoicePeriodStart]
																			   ,[InvoicePeriodEnd]
																			   ,[OriginalAmount]
																			   ,[InvoiceTypeID]
																			   ,[OpenAmount]
																			   ,[LastUpdateUserID]
																			   ,[InvoiceStatus]
																			   ,[ProcessID]
																			   ,[RawStoreIdentifier]
																			   ,[InvoiceNumber]
																			   ,[PaymentDueDate]
																			   ,[Route]
																			   ,[StoreID]
																			   ,[AccountCode]
																			   ,[RefIDToOriginalInvNo])
																		 select @EntityIDToInvoice
																			   ,@billingperiodstartdatetime
																			   ,@billingperiodenddatetime
																			   ,SUM(TotalCost)
																			   ,@invoicetype
																			   ,SUM(TotalCost)
																			   ,@MyID
																			   ,1
																			   ,@ProcessID
																			   ,MAX(RawStoreIdentifier)
																			   ,MAX(InvoiceNo)
																			   ,MAX(PaymentDueDate)
																			   ,MAX(Route)
																			   ,MAX(StoreID)
																			   ,MAX(AccountCode)
																			   ,MAX(RefIDToOriginalInvNo)
																			from InvoiceDetails with (nolock)
																			where ChainID = @entityidtoinvoice
																			and StoreID = @storeid
																			and SupplierID = @supplierid
																			and RetailerInvoiceID = -1
																			and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
																			and ProcessID = @ProcessID
																			
																			set @invoiceheaderid = SCOPE_IDENTITY()
--/*																
																			update d set RetailerInvoiceID = @invoiceheaderid
																			,Recordstatus = 4
																			from InvoiceDetails AS d WITH (NOLOCK)
																			where ChainID = @entityidtoinvoice
																			and StoreID = @storeid
																			and SupplierID = @supplierid
																			and RetailerInvoiceID = -1
																			and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
																			and ProcessID = @ProcessID
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
																			,Recordstatus = 4
																			from InvoiceDetails AS d WITH (NOLOCK)
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
												from InvoiceDetails with (nolock)
												where ChainID = @entityidtoinvoice
												and RetailerInvoiceID = -1
												and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
												and ProcessID = @ProcessID
												
												open @recstore
												
												fetch next from @recstore into @storeid
												
												while @@FETCH_STATUS = 0
													begin
--**************************************************************************************************

														set @recsupplier = CURSOR local fast_forward FOR
															select distinct SupplierID
															from InvoiceDetails with (nolock)
															where ChainID = @entityidtoinvoice
															and StoreID = @storeid
															and RetailerInvoiceID = -1
															and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
															and ProcessID = @ProcessID
															
															open @recsupplier
															
															fetch next from @recsupplier into @supplierid
															
															while @@FETCH_STATUS = 0
																begin
																
																	set @recdetailtype = CURSOR local fast_forward FOR
																		select distinct InvoiceDetailTypeID
																			from InvoiceDetails with (nolock)
																			where ChainID = @entityidtoinvoice
																			and StoreID = @storeid
																			and SupplierID = @supplierid
																			and RetailerInvoiceID = -1
																			and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
																			and ProcessID = @ProcessID
																			
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
																							   ,[InvoiceStatus]
																							   ,[ProcessID]
																							   ,[RawStoreIdentifier]
																							   ,[InvoiceNumber]
																							   ,[PaymentDueDate]
																							   ,[Route]
																							   ,[StoreID]
																							   ,[AccountCode]
																							   ,[RefIDToOriginalInvNo])
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
																							   ,@ProcessID
																							   ,MAX(RawStoreIdentifier)
																							   ,MAX(InvoiceNo)
																							   ,MAX(PaymentDueDate)
																							   ,MAX(Route)
																							   ,MAX(StoreID)
																							   ,MAX(AccountCode)
																							   ,MAX(RefIDToOriginalInvNo)
																							from InvoiceDetails with (nolock)
																							where ChainID = @entityidtoinvoice
																							and StoreID = @storeid
																							and SupplierID = @supplierid
																							and RetailerInvoiceID = -1
																							and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
																							and InvoiceDetailTypeID in (select detailtypeid from #temptypes)
																							--and InvoiceDetailTypeID = @invoicedetailtypeid
																							--and InvoiceDetailTypeID in (1,7)
																							and ProcessID = @ProcessID
																							Group by productid, brandid, SaleDate
																							having Sum(TotalCost) < 0
																							
																							
																							set @invoiceheaderid = SCOPE_IDENTITY()
																						
																							update d set RetailerInvoiceID = @invoiceheaderid
																							,Recordstatus = 4
																							from InvoiceDetails AS d WITH (NOLOCK)
																							inner join 
																							(
																								select productid, brandid, SaleDate
																								from InvoiceDetails with (nolock)
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
																							and ChainID = @entityidtoinvoice
																							and StoreID = @storeid
																							and SupplierID = @supplierid
																							and InvoiceDetailTypeID in (select detailtypeid from #temptypes)
																							--and InvoiceDetailTypeID = @invoicedetailtypeid
																							--and InvoiceDetailTypeID in (1,7)
																							and RetailerInvoiceID = -1
																							and d.SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
																							and ProcessID = @ProcessID

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
																							   ,[InvoiceStatus]
																							   ,[ProcessID]
																							   ,[RawStoreIdentifier]
																							   ,[InvoiceNumber]
																							   ,[PaymentDueDate]
																							   ,[Route]
																							   ,[StoreID]
																							   ,[AccountCode]
																							   ,[RefIDToOriginalInvNo])
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
																							   ,@ProcessID
																							   ,MAX(RawStoreIdentifier)
																							   ,MAX(InvoiceNo)
																							   ,MAX(PaymentDueDate)
																							   ,MAX(Route)
																							   ,MAX(StoreID)
																							   ,MAX(AccountCode)
																							   ,MAX(RefIDToOriginalInvNo)
																							from InvoiceDetails with (nolock)
																							where ChainID = @entityidtoinvoice
																							and StoreID = @storeid
																							and SupplierID = @supplierid
																							and RetailerInvoiceID = -1
																							and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
																							and InvoiceDetailTypeID in (select detailtypeid from #temptypes)
																							and ProcessID = @ProcessID
																							--and InvoiceDetailTypeID = @invoicedetailtypeid
																							--and InvoiceDetailTypeID in (1,7)
																							--Group by productid, brandid
																							
																							
																							set @invoiceheaderid = SCOPE_IDENTITY()
																						
																							update d set RetailerInvoiceID = @invoiceheaderid
																							,Recordstatus = 4
																							from InvoiceDetails AS d WITH (NOLOCK)
																							where ChainID = @entityidtoinvoice
																							and StoreID = @storeid
																							and SupplierID = @supplierid
																							and InvoiceDetailTypeID in (select detailtypeid from #temptypes)
																							--and InvoiceDetailTypeID = @invoicedetailtypeid
																							--and InvoiceDetailTypeID in (1,7)
																							and RetailerInvoiceID = -1
																							and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
																							and ProcessID = @ProcessID
																							
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
																									   ,[InvoiceStatus]
																									   ,[ProcessID]
																									   ,[RawStoreIdentifier]
																									   ,[InvoiceNumber]
																									   ,[PaymentDueDate]
																									   ,[Route]
																									   ,[StoreID]
																									   ,[AccountCode]
																									   ,[RefIDToOriginalInvNo])
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
																									   ,@ProcessID
																									   ,MAX(RawStoreIdentifier)
																									   ,MAX(InvoiceNo)
																									   ,MAX(PaymentDueDate)
																									   ,MAX(Route)
																									   ,MAX(StoreID)
																									   ,MAX(AccountCode)
																									   ,MAX(RefIDToOriginalInvNo)
																									from InvoiceDetails with (nolock)
																									where ChainID = @entityidtoinvoice
																									and StoreID = @storeid
																									and SupplierID = @supplierid
																									and RetailerInvoiceID = -1
																									and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
																									and InvoiceDetailTypeID = @invoicedetailtypeid
																									and ProcessID = @ProcessID
																									Group by productid, brandid, SaleDate, InvoiceDetailTypeID
																									having Sum(TotalCost) < 0
																									
																																												
																									set @invoiceheaderid = SCOPE_IDENTITY()
																										
																									update d set RetailerInvoiceID = @invoiceheaderid
																									,Recordstatus = 4
																									from InvoiceDetails AS d WITH (NOLOCK)
																									inner join 
																									(
																										select productid, brandid, SaleDate
																										from InvoiceDetails with (nolock)
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
																									and ChainID = @entityidtoinvoice
																									and StoreID = @storeid
																									and SupplierID = @supplierid
																									and InvoiceDetailTypeID = @invoicedetailtypeid
																									and RetailerInvoiceID = -1
																									and d.SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
																									and ProcessID = @ProcessID
																										
																								end
																								
																							INSERT INTO [DataTrue_Main].[dbo].[InvoicesRetailer]
																							   ([ChainID]
																							   ,[InvoicePeriodStart]
																							   ,[InvoicePeriodEnd]
																							   ,[OriginalAmount]
																							   ,[InvoiceTypeID]
																							   ,[OpenAmount]
																							   ,[LastUpdateUserID]
																							   ,[InvoiceStatus]
																							   ,[ProcessID]
																							   ,[RawStoreIdentifier]
																							   ,[InvoiceNumber]
																							   ,[PaymentDueDate]
																							   ,[Route]
																							   ,[StoreID]
																							   ,[AccountCode]
																							   ,[RefIDToOriginalInvNo])
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
																							   ,@ProcessID
																							   ,MAX(RawStoreIdentifier)
																							   ,MAX(InvoiceNo)
																							   ,MAX(PaymentDueDate)
																							   ,MAX(Route)
																							   ,MAX(StoreID)
																							   ,MAX(AccountCode)
																							   ,MAX(RefIDToOriginalInvNo)
																							from InvoiceDetails with (nolock)
																							where ChainID = @entityidtoinvoice
																							and StoreID = @storeid
																							and SupplierID = @supplierid
																							and RetailerInvoiceID = -1
																							and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
																							and InvoiceDetailTypeID = @invoicedetailtypeid
																							and ProcessID = @ProcessID
																																										
																							set @invoiceheaderid = SCOPE_IDENTITY()
																								
																							update d set RetailerInvoiceID = @invoiceheaderid
																							,Recordstatus = 4
																							from InvoiceDetails AS d WITH (NOLOCK)
																							where ChainID = @entityidtoinvoice
																							and StoreID = @storeid
																							and SupplierID = @supplierid
																							and InvoiceDetailTypeID = @invoicedetailtypeid
																							and RetailerInvoiceID = -1
																							and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
																							and ProcessID = @ProcessID
																							
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
																							from InvoiceDetails AS d WITH (NOLOCK)
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
																							from InvoiceDetails AS d WITH (NOLOCK)
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
																			,Recordstatus = 4
																			from InvoiceDetails AS d WITH (NOLOCK)
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
												from InvoiceDetails with (nolock)
												where ChainID = @entityidtoinvoice
												and RetailerInvoiceID = -1
												and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
												and ProcessID = @ProcessID
												
												open @recstore
												
												fetch next from @recstore into @storeid
												
												while @@FETCH_STATUS = 0
													begin
--**************************************************************************************************

														set @recsupplier = CURSOR local fast_forward FOR
															select distinct SupplierID
															from InvoiceDetails with (nolock)
															where ChainID = @entityidtoinvoice
															and StoreID = @storeid
															and RetailerInvoiceID = -1
															and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
															and ProcessID = @ProcessID
															
															open @recsupplier
															
															fetch next from @recsupplier into @supplierid
															
															while @@FETCH_STATUS = 0
																begin
																
																	set @recdetailtype = CURSOR local fast_forward FOR
																		select distinct InvoiceDetailTypeID
																			from InvoiceDetails with (nolock)
																			where ChainID = @entityidtoinvoice
																			and StoreID = @storeid
																			and SupplierID = @supplierid
																			and RetailerInvoiceID = -1
																			and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
																			and ProcessID = @ProcessID
																				
																	open @recdetailtype
																	
																	fetch next from @recdetailtype into @invoicedetailtypeid
																	
																	while @@FETCH_STATUS = 0
																		begin
																			set @recpono = CURSOR local fast_forward FOR
																			select distinct InvoiceNo
																				from InvoiceDetails with (nolock)
																				where ChainID = @entityidtoinvoice
																				and StoreID = @storeid
																				and SupplierID = @supplierid
																				and InvoiceDetailTypeID = @invoicedetailtypeid
																				and RetailerInvoiceID = -1
																				and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
																				and ProcessID = @ProcessID
																				
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
																									   ,[InvoiceStatus]
																									   ,[ProcessID]
																									   ,[RawStoreIdentifier]
																									   ,[InvoiceNumber]
																									   ,[PaymentDueDate]
																									   ,[Route]
																									   ,[StoreID]
																									   ,[AccountCode]
																									   ,[RefIDToOriginalInvNo])
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
																									   ,@ProcessID
																									   ,MAX(RawStoreIdentifier)
																									   ,MAX(InvoiceNo)
																									   ,MAX(PaymentDueDate)
																									   ,MAX(Route)
																									   ,MAX(StoreID)
																									   ,MAX(AccountCode)
																									   ,MAX(RefIDToOriginalInvNo)
																									from InvoiceDetails with (nolock)
																									where ChainID = @entityidtoinvoice
																									and StoreID = @storeid
																									and SupplierID = @supplierid
																									and RetailerInvoiceID = -1
																									and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
																									and InvoiceDetailTypeID in (select detailtypeid from #temptypes2)
																									and InvoiceNo = @PONo
																									and ProcessID = @ProcessID
																									--and InvoiceDetailTypeID = @invoicedetailtypeid
																									--and InvoiceDetailTypeID in (1,7)
																									Group by productid, brandid, SaleDate
																									having Sum(TotalCost) < 0
																									
																									
																									set @invoiceheaderid = SCOPE_IDENTITY()
																								
																									update d set RetailerInvoiceID = @invoiceheaderid
																									,Recordstatus = 4
																									from InvoiceDetails AS d WITH (NOLOCK)
																									inner join 
																									(
																										select productid, brandid, SaleDate
																										from InvoiceDetails with (nolock)
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
																									and ChainID = @entityidtoinvoice
																									and StoreID = @storeid
																									and SupplierID = @supplierid
																									and InvoiceDetailTypeID in (select detailtypeid from #temptypes2)
																									and InvoiceNo = @PONo
																									--and InvoiceDetailTypeID = @invoicedetailtypeid
																									--and InvoiceDetailTypeID in (1,7)
																									and RetailerInvoiceID = -1
																									and d.SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
																									and ProcessID = @ProcessID

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
																									   ,[InvoiceStatus]
																									   ,[ProcessID]
																									   ,[RawStoreIdentifier]
																									   ,[InvoiceNumber]
																									   ,[PaymentDueDate]
																									   ,[Route]
																									   ,[StoreID]
																									   ,[AccountCode]
																									   ,[RefIDToOriginalInvNo])
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
																									   ,@ProcessID
																									   ,MAX(RawStoreIdentifier)
																									   ,MAX(InvoiceNo)
																									   ,MAX(PaymentDueDate)
																									   ,MAX(Route)
																									   ,MAX(StoreID)
																									   ,MAX(AccountCode)
																									   ,MAX(RefIDToOriginalInvNo)
																									from InvoiceDetails with (nolock)
																									where ChainID = @entityidtoinvoice
																									and StoreID = @storeid
																									and SupplierID = @supplierid
																									and RetailerInvoiceID = -1
																									and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
																									and InvoiceDetailTypeID in (select detailtypeid from #temptypes2)
																									and InvoiceNo = @PONo
																									and ProcessID = @ProcessID
																									--and InvoiceDetailTypeID = @invoicedetailtypeid
																									--and InvoiceDetailTypeID in (1,7)
																									--Group by productid, brandid
																									
																									
																									set @invoiceheaderid = SCOPE_IDENTITY()
																								
																									update d set RetailerInvoiceID = @invoiceheaderid
																									,Recordstatus = 4
																									from InvoiceDetails AS d WITH (NOLOCK)
																									where ChainID = @entityidtoinvoice
																									and StoreID = @storeid
																									and SupplierID = @supplierid
																									and InvoiceDetailTypeID in (select detailtypeid from #temptypes2)
																									and InvoiceNo = @PONo
																									--and InvoiceDetailTypeID = @invoicedetailtypeid
																									--and InvoiceDetailTypeID in (1,7)
																									and RetailerInvoiceID = -1
																									and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
																									and ProcessID = @ProcessID
																									
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
																											   ,[InvoiceStatus]
																											   ,[ProcessID]
																											   ,[RawStoreIdentifier]
																											   ,[InvoiceNumber]
																											   ,[PaymentDueDate]
																											   ,[Route]
																											   ,[StoreID]
																											   ,[AccountCode]
																											   ,[RefIDToOriginalInvNo])
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
																											   ,@ProcessID
																											   ,MAX(RawStoreIdentifier)
																											   ,MAX(InvoiceNo)
																											   ,MAX(PaymentDueDate)
																											   ,MAX(Route)
																											   ,MAX(StoreID)
																											   ,MAX(AccountCode)
																											   ,MAX(RefIDToOriginalInvNo)
																											from InvoiceDetails with (nolock)
																											where ChainID = @entityidtoinvoice
																											and StoreID = @storeid
																											and SupplierID = @supplierid
																											and RetailerInvoiceID = -1
																											and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
																											and InvoiceDetailTypeID = @invoicedetailtypeid
																											and InvoiceNo = @PONo
																											and ProcessID = @ProcessID
																											Group by productid, brandid, SaleDate, InvoiceDetailTypeID
																											having Sum(TotalCost) < 0
																											
																																														
																											set @invoiceheaderid = SCOPE_IDENTITY()
																												
																											update d set RetailerInvoiceID = @invoiceheaderid
																											,Recordstatus = 4
																											from InvoiceDetails AS d WITH (NOLOCK)
																											inner join 
																											(
																												select productid, brandid, SaleDate
																												from InvoiceDetails with (nolock)
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
																											and ChainID = @entityidtoinvoice
																											and StoreID = @storeid
																											and SupplierID = @supplierid
																											and InvoiceDetailTypeID = @invoicedetailtypeid
																											and InvoiceNo = @PONo
																											and RetailerInvoiceID = -1
																											and d.SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
																											and ProcessID = @ProcessID
																											
																										end
																										
																									INSERT INTO [DataTrue_Main].[dbo].[InvoicesRetailer]
																									   ([ChainID]
																									   ,[InvoicePeriodStart]
																									   ,[InvoicePeriodEnd]
																									   ,[OriginalAmount]
																									   ,[InvoiceTypeID]
																									   ,[OpenAmount]
																									   ,[LastUpdateUserID]
																									   ,[InvoiceStatus]
																									   ,[ProcessID]
																									   ,[RawStoreIdentifier]
																									   ,[InvoiceNumber]
																									   ,[PaymentDueDate]
																									   ,[Route]
																									   ,[StoreID]
																									   ,[AccountCode]
																									   ,[RefIDToOriginalInvNo])
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
																									   ,@ProcessID
																									   ,MAX(RawStoreIdentifier)
																									   ,MAX(InvoiceNo)
																									   ,MAX(PaymentDueDate)
																									   ,MAX(Route)
																									   ,MAX(StoreID)
																									   ,MAX(AccountCode)
																									   ,MAX(RefIDToOriginalInvNo)
																									from InvoiceDetails with (nolock)
																									where ChainID = @entityidtoinvoice
																									and StoreID = @storeid
																									and SupplierID = @supplierid
																									and RetailerInvoiceID = -1
																									and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)								
																									and InvoiceDetailTypeID = @invoicedetailtypeid
																									and InvoiceNo = @PONo
																									and ProcessID = @ProcessID
																																												
																									set @invoiceheaderid = SCOPE_IDENTITY()
																										
																									update d set RetailerInvoiceID = @invoiceheaderid
																									,Recordstatus = 4
																									from InvoiceDetails AS d WITH (NOLOCK)
																									where ChainID = @entityidtoinvoice
																									and StoreID = @storeid
																									and SupplierID = @supplierid
																									and InvoiceDetailTypeID = @invoicedetailtypeid
																									and InvoiceNo = @PONo
																									and RetailerInvoiceID = -1
																									and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
																									and ProcessID = @ProcessID
																									
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
																									from InvoiceDetails AS d WITH (NOLOCK)
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
																									from InvoiceDetails AS d WITH (NOLOCK)
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
																			from InvoiceDetails AS d WITH (NOLOCK)
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
						
							--update BillingControl
							--set LastBillingPeriodEndDateTime = NextBillingPeriodEndDateTime
							--,NextBillingPeriodEndDateTime = @newnextbillingperiodenddatetime
							--,NextBillingPeriodRunDateTime = @newnextbillingperiodenddatetime
							--,LastUpdateUserID = @MyID
							--,DateTimeLastUpdate = @currentdatetime
							--where BillingControlID = @billingcontrolid
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
					
--					commit transaction
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
			@job_name = 'Billing_Regulated_NewInvoiceData'
			
		--exec [msdb].[dbo].[sp_stop_job] 
		--	@job_name = 'Billing_Regulated'
			
		--Update 	DataTrue_Main.dbo.JobRunning
		--Set JobIsRunningNow = 0
		--Where JobName = 'DailyRegulatedBilling'	

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated_NewInvoiceData Job Stopped'
			,'An exception occurred in prInvoices_Retailer_Create_ACH.  Manual review, resolution, and re-start will be required for the job to continue.'
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

--*******************************************************************************************************

delete from DataTrue_Main..InvoicesRetailer where originalamount is null
--Temporary to populate EDI tables
--drop table DataTrue_EDI..InvoiceDetails
/*
insert into DataTrue_EDI..InvoiceDetails 
select * from DataTrue_Main..InvoiceDetails
where InvoiceDetailID not in (select InvoiceDetailID from DataTrue_EDI..InvoiceDetails)
and RetailerInvoiceID is not null
*/
--declare @lastarchivemaxrowid bigint=0
--select @lastarchivemaxrowid = LastMaxRowIDArchived
----select *
--from dbo.ArchiveControl
--where ArchiveTableName = 'datatrue_edi.dbo.invoicedetails'

--INSERT INTO [DataTrue_EDI].[dbo].[InvoiceDetails]
--           ([InvoiceDetailID]
--           ,[RetailerInvoiceID]
--           ,[SupplierInvoiceID]
--           ,[ChainID]
--           ,[StoreID]
--           ,[ProductID]
--           ,[BrandID]
--           ,[SupplierID]
--           ,[InvoiceDetailTypeID]
--           ,[TotalQty]
--           ,[UnitCost]
--           ,[UnitRetail]
--           ,[TotalCost]
--           ,[TotalRetail]
--           ,[SaleDate]
--           ,[RecordStatus]
--           ,[DateTimeCreated]
--           ,[LastUpdateUserID]
--           ,[DateTimeLastUpdate]
--           ,[BatchID]
--           ,[ChainIdentifier]
--           ,[StoreIdentifier]
--           ,[StoreName]
--           ,[ProductIdentifier]
--           ,[ProductQualifier]
--           ,[RawProductIdentifier]
--           ,[SupplierName]
--           ,[SupplierIdentifier]
--           ,[BrandIdentifier]
--           ,[DivisionIdentifier]
--           ,[UOM]
--           ,[SalePrice]
--           ,[Allowance]
--           ,[InvoiceNo]
--           ,[PONo]
--           ,[CorporateName]
--           ,[CorporateIdentifier]
--           ,[Banner]
--           ,PromoTypeID
--			,PromoAllowance
--			,SBTNumber)
--SELECT [InvoiceDetailID]
--      ,[RetailerInvoiceID]
--      ,[SupplierInvoiceID]
--      ,[ChainID]
--      ,[StoreID]
--      ,[ProductID]
--      ,[BrandID]
--      ,[SupplierID]
--      ,[InvoiceDetailTypeID]
--      ,[TotalQty]
--      ,[UnitCost]
--      ,[UnitRetail]
--      ,[TotalCost]
--      ,[TotalRetail]
--      ,[SaleDate]
--      --change here wait
--      ,case when upper(banner) = 'SS' then 2 else 0 end
--      ,[DateTimeCreated]
--      ,[LastUpdateUserID]
--      ,[DateTimeLastUpdate]
--      ,[BatchID]
--                 ,[ChainIdentifier]
--           ,[StoreIdentifier]
--           ,[StoreName]
--           ,[ProductIdentifier]
--           ,[ProductQualifier]
--           ,[RawProductIdentifier]
--           ,[SupplierName]
--           ,[SupplierIdentifier]
--           ,[BrandIdentifier]
--           ,[DivisionIdentifier]
--           ,[UOM]
--           ,[SalePrice]
--           ,[Allowance]
--           ,[InvoiceNo]
--           ,[PONo]
--           ,[CorporateName]
--           ,[CorporateIdentifier]
--           ,[Banner]
--           ,PromoTypeID
--			,isnull(PromoAllowance, 0)
--			,SBTNumber
--  FROM [DataTrue_Main].[dbo].[InvoiceDetails]
--	where InvoiceDetailID not in (select InvoiceDetailID from DataTrue_EDI..InvoiceDetails)
--	and RetailerInvoiceID is not null
--	and RetailerInvoiceID <> -33
--	and InvoiceDetailID > @lastarchivemaxrowid
--	and InvoiceDetailTypeID <> 11





--/*
--INSERT INTO [DataTrue_EDI].[dbo].[InvoiceDetails]
--           ([InvoiceDetailID]
--           ,[RetailerInvoiceID]
--           ,[SupplierInvoiceID]
--           ,[ChainID]
--           ,[StoreID]
--           ,[ProductID]
--           ,[BrandID]
--           ,[SupplierID]
--           ,[InvoiceDetailTypeID]
--           ,[TotalQty]
--           ,[UnitCost]
--           ,[UnitRetail]
--           ,[TotalCost]
--           ,[TotalRetail]
--           ,[SaleDate]
--           ,[RecordStatus]
--           ,[DateTimeCreated]
--           ,[LastUpdateUserID]
--           ,[DateTimeLastUpdate]
--           ,[BatchID])
--	select [InvoiceDetailID]
--           ,[RetailerInvoiceID]
--           ,[SupplierInvoiceID]
--           ,[ChainID]
--           ,[StoreID]
--           ,[ProductID]
--           ,[BrandID]
--           ,[SupplierID]
--           ,[InvoiceDetailTypeID]
--           ,case when [TotalCost] < 0 and [TotalQty] > 0 then -1 * [TotalQty]
--					when [TotalCost] > 0 and [TotalQty] < 0 then -1 * [TotalQty]
--				else [TotalQty]
--			end
--           ,abs([UnitCost])
--           ,abs([UnitRetail])
--           ,abs([TotalCost])
--           ,abs([TotalRetail])
--           ,[SaleDate]
--           ,[RecordStatus]
--           ,[DateTimeCreated]
--           ,[LastUpdateUserID]
--           ,[DateTimeLastUpdate]
--           ,[BatchID]
--           from DataTrue_Main..InvoiceDetails
--			where InvoiceDetailID not in (select InvoiceDetailID from DataTrue_EDI..InvoiceDetails)
--*/





--update eid set eid.RetailerInvoiceID = did.RetailerInvoiceID
--from DataTrue_Main..InvoiceDetails did
--inner join DataTrue_EDI..InvoiceDetails eid
--on did.InvoiceDetailID = eid.InvoiceDetailID
--where eid.RetailerInvoiceID is null


----drop table DataTrue_EDI..InvoicesRetailer
--insert into DataTrue_EDI..InvoicesRetailer 
--select * from DataTrue_Main..InvoicesRetailer
--where retailerinvoiceid not in (select retailerinvoiceid from DataTrue_EDI..InvoicesRetailer)
----drop table DataTrue_EDI..InvoicesSupplier
----select * into DataTrue_EDI..InvoicesSupplier from InvoicesSupplier

--insert into DataTrue_EDI..InvoicesSupplier 
--select * from DataTrue_Main..InvoicesSupplier
--where Supplierinvoiceid not in (select Supplierinvoiceid from DataTrue_EDI..InvoicesSupplier)
----*******************************************************************************************************


--================================

IF (SELECT COUNT(InvoiceDetailID) FROM DataTrue_Main.dbo.InvoiceDetails WHERE ProcessID = @ProcessID AND RetailerInvoiceID IS NULL) > 0
	BEGIN
		exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'Billing_Regulated_NewInvoiceData'
		exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated_NewInvoiceData Job Stopped'
			,'An exception occurred in [prInvoices_Retailer_Create_ACH].  There are null Retailer Invoices.'
			,'DataTrue System', 0, 'edi@icucsolutions.com'--'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
	END

DELETE ir
FROM DataTrue_Main.dbo.InvoicesRetailer AS ir
WHERE 1 = 1
AND InvoiceTypeID = 1
AND ProcessID = @ProcessID
AND RetailerInvoiceID NOT IN
(
	SELECT DISTINCT RetailerInvoiceID
	FROM DataTrue_Main.dbo.InvoiceDetails AS id WITH (NOLOCK)
	WHERE InvoiceDetailTypeID = 2
	AND ProcessID = @ProcessID
)

update h set h.OriginalAmount = d.IDSum, h.OpenAmount = d.IDSum
 from DataTrue_Main.dbo.InvoicesRetailer h
 inner join
 (
 select retailerinvoiceid, SUM(totalcost) as IDsum
 from datatrue_main.dbo.Invoicedetails nolock
 where 1 = 1
 and InvoiceDetailTypeID = 2
 and ProcessID = @ProcessID
 group by RetailerInvoiceID
 ) d
 on h.RetailerInvoiceID = d.RetailerInvoiceID
 and d.IDSum <> h.OriginalAmount

--================================


UPDATE DataTrue_Main.dbo.ACH_RetailerConfirmations
SET RecordStatus = 1
WHERE (1 = 1)
AND (RecordStatus = 0)
AND (ConfirmationReceived = 1)
AND (ConfirmationDate IS NOT NULL)


return
GO
