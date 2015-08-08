USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoices_POS_Supplier_Create_20140806]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Batch submitted through debugger: SQLQuery191.sql|7|0|C:\Users\SQLAdmin\AppData\Local\Temp\3\~vsC251.sql
CREATE procedure [dbo].[prInvoices_POS_Supplier_Create_20140806]

as
/*
*/
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
declare @chainid int
declare @invoicedetailtypeid smallint
declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @MyID int
set @MyID = 24135

declare @billingcontrolfrequency nvarchar(50)


set @currentdatetime = GETDATE()

set @rec = CURSOR local fast_forward for
	select BillingControlID, EntityIDToInvoice, BillingControlDay, BillingControlClosingDelay,
		ProductSubGroupType, ProductSubGroupID, NextBillingPeriodRunDateTime, 
		InvoiceSeparation, BillingControlNumberOfPastDaysToRebill, NextBillingPeriodEndDateTime, SeparateCredits, ChainID, BillingControlFrequency
	from billingcontrol c
	inner join systementities s
	on c.EntityIDToInvoice = s.EntityID
	where s.EntityTypeID = 5
	and nextbillingperiodrundatetime <= getdate() --@currentdatetime
	and billingcontrolfrequency = 'Weekly' --@billingcontrolfrequency
	--and nextbillingperiodrundatetime <= @currentdatetime
	--and billingcontrolfrequency = @billingcontrolfrequency
	and IsActive = 1
	and ChainID = 60624

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
,@chainid
,@billingcontrolfrequency

while @@FETCH_STATUS = 0
	begin
	
		begin try
		
			set @needtoinvoice = 0
			set @numberofperiodsrun = 0
			


	
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
								
					select @numberofpastdaystorebill = DATEDIFF(day,min(saledate), getdate()) + 6
					from InvoiceDetailS
					where chainid = @chainid
					and supplierid = @entityidtoinvoice
					and SupplierInvoiceID is null
					
					if @numberofpastdaystorebill is null
						set @numberofpastdaystorebill = 0
						
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
					

					begin try
						DROP TABLE #tempStoreSetupProducts
					end try
					begin catch
						set @dummyerrorcatch = 0
					end catch	
					
--					select distinct ProductID, BrandID--, BillingRuleID--, 
--					--RetailerShrinkPercent, SupplierShrinkPercent, ManufacturerShrinkPercent
--					into #tempStoreSetupProducts 
--					from ChainProductFactors
--					--from StoreSetup
--					where ChainID = @chainid
					
					
--					if @@ROWCOUNT < 1
--						goto NextBilling	
						
----select * from #tempStoreSetupProducts
--					--IF EXISTS (SELECT * FROM sys.tables WHERE name like '%#tempProductsToInvoice%')
--					begin try
--						DROP TABLE #tempProductsToInvoice
--					end try
--					begin catch
--						set @dummyerrorcatch = 0
--					end catch
--					--if exists(select null from #tempProductsToInvoice)
--					--	drop table #tempProductsToInvoice				
					
--					select * into #tempProductsToInvoice from #tempStoreSetupProducts
				


				
			while @numberofperiodsrun < @numberofperiodstorun
				begin			
					--begin transaction
--print '2'									
					
					--determine if original(0) or rebill(1) for the period
					
					set @invoicetype = 0
					
					select @dummycount = COUNT(SupplierInvoiceID) 
					from InvoicesSupplier
					where SupplierID = @entityidtoinvoice
					and cast(InvoicePeriodStart as DATE) = cast(@billingperiodstartdatetime as date)
					and cast(InvoicePeriodEnd as DATE) = cast(@billingperiodenddatetime as date)
					
					if @dummycount > 0
						set @invoicetype = 1
					else
						set @invoicetype = 0

					if @invoicetype in (0,1)

							--update d set d.SupplierInvoiceID = -1
							select InvoiceDetailID into #InvoicedetailIDsToBill 
							from InvoiceDetails d
							where d.ChainID = @chainid
							and d.supplierid = @EntityIDToInvoice
							--and t.BillingRuleID in (1,3)
							and d.InvoiceDetailTypeID in (1) --,7) --change here wait ,7) --POS Only
							and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
							and d.SupplierInvoiceID is null

					if @@rowcount > 0
						begin
							set @needtoinvoice = 1
						end

						
					if @needtoinvoice = 1
						begin
						
							select CAST(0 as int) as SupplierInvoiceID
							,CAST(0 as int) as Storeid
							into #outputtable						
						
							if @separatecredits = 1
							begin
							
								Select storeid, productid, SupplierID, isnull(PONo, '') as PONo
								,isnull(InvoiceNo, '') as InvoiceNo, SUM(TotalCost) as TotalInvAmount
								,CAST(0 as int) as SupplierInvoiceID
								into #creditinvoices
								from datatrue_main.dbo.InvoiceDetails d
								inner join #InvoicedetailIDsToBill i
								on d.InvoiceDetailID = i.InvoiceDetailID
								group by storeid, productid, SupplierID, isnull(PONo, ''), isnull(InvoiceNo, '')
								having SUM(TotalCost) < 0
								
if @@ROWCOUNT > 0
	print 'herenow'
								
								truncate table #outputtable
							
								INSERT INTO [DataTrue_Main].[dbo].[InvoicesSupplier]
										   ([SupplierID]
										   ,[InvoicePeriodStart]
										   ,[InvoicePeriodEnd]
										   ,[OriginalAmount]
										   ,[InvoiceTypeID]
										   ,[OpenAmount]
										   ,[LastUpdateUserID]
										   ,[InvoiceStatus]
										   ,[TransmissionRef])
								OUTPUT INSERTED.SupplierInvoiceID, cast(inserted.TransmissionRef as int) INTO #outputtable		   
								select @entityidtoinvoice
								,@billingperiodstartdatetime
								,@billingperiodenddatetime
								,SUM(TotalInvAmount) 
								,case	when @invoicedetailtypeid in (1) then 0
										when @invoicedetailtypeid in (7) then 5
									else 0 end --@invoicetype
								,SUM(TotalInvAmount)
								,@MyID
								,0
								,CAST(storeid as varchar(50))
								from #creditinvoices
								group by storeid
							
								update c set c.SupplierInvoiceID = o.SupplierInvoiceID
								from #creditinvoices c
								inner join #outputtable o
								on c.StoreID = o.Storeid
								
								update d set d.SupplierInvoiceID = c.SupplierInvoiceID, d.RecordStatus = 1
								from datatrue_main.dbo.InvoiceDetails d
								inner join #creditinvoices c
								on d.StoreID = c.StoreID
								and d.ProductID = c.ProductID
								and d.SupplierID = c.supplierid
								and isnull(d.PONo, '') = isnull(c.PONo, '')
								and isnull(d.InvoiceNo, '') = isnull(d.InvoiceNo, '')
								and d.invoicedetailid in
								(select InvoiceDetailID from #InvoicedetailIDsToBill)

							
							end
							
						Select storeid, productid, SupplierID, isnull(PONo, '') as PONo
						,isnull(InvoiceNo, '') as InvoiceNo, SUM(TotalCost) as TotalInvAmount
						,CAST(0 as int) as SupplierInvoiceID
						into #regularinvoices
						from datatrue_main.dbo.InvoiceDetails d
						inner join #InvoicedetailIDsToBill i
						on d.InvoiceDetailID = i.InvoiceDetailID
						and d.SupplierInvoiceID is null
						group by storeid, productid, SupplierID, isnull(PONo, ''), isnull(InvoiceNo, '')
						
						truncate table #outputtable
					
						INSERT INTO [DataTrue_Main].[dbo].[InvoicesSupplier]
								   ([SupplierID]
								   ,[InvoicePeriodStart]
								   ,[InvoicePeriodEnd]
								   ,[OriginalAmount]
								   ,[InvoiceTypeID]
								   ,[OpenAmount]
								   ,[LastUpdateUserID]
								   ,[InvoiceStatus]
								   ,[TransmissionRef])
						OUTPUT INSERTED.SupplierInvoiceID, cast(inserted.TransmissionRef as int) INTO #outputtable		   
						select @entityidtoinvoice
						,@billingperiodstartdatetime
						,@billingperiodenddatetime
						,SUM(TotalInvAmount) 
						,case	when @invoicedetailtypeid in (1) then 0
								when @invoicedetailtypeid in (7) then 5
							else 0 end --@invoicetype
						,SUM(TotalInvAmount)
						,@MyID
						,0
						,CAST(storeid as varchar(50))
						from #regularinvoices
						group by storeid
					
						update c set c.SupplierInvoiceID = o.SupplierInvoiceID
						from #regularinvoices c
						inner join #outputtable o
						on c.StoreID = o.Storeid
						
						update d set d.SupplierInvoiceID = c.SupplierInvoiceID, d.RecordStatus = 1
						from datatrue_main.dbo.InvoiceDetails d
						inner join #regularinvoices c
						on d.StoreID = c.StoreID
						and d.ProductID = c.ProductID
						and d.SupplierID = c.supplierid
						and isnull(d.PONo, '') = isnull(c.PONo, '')
						and isnull(d.InvoiceNo, '') = isnull(d.InvoiceNo, '')
						and d.invoicedetailid in
						(select InvoiceDetailID from #InvoicedetailIDsToBill)
						and d.SupplierInvoiceID is null										
end
--end												
	--herenow 20140806										
--**************************************************************************************************																															

					
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
								
					begin try
						drop table #outputtable
					end try
					begin catch
						set @dummyerrorcatch = 0
					end catch

					begin try
						drop table #InvoicedetailIDsToBill
					end try
					begin catch
						set @dummyerrorcatch = 0
					end catch
					
					begin try
						drop table #creditinvoices
					end try
					begin catch
						set @dummyerrorcatch = 0
					end catch
					
					begin try
						drop table #regularinvoices
					end try
					begin catch
						set @dummyerrorcatch = 0
					end catch														
					
					--commit transaction
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
		,@chainid
		,@billingcontrolfrequency
	end
	
close @rec
deallocate @rec


return
GO
