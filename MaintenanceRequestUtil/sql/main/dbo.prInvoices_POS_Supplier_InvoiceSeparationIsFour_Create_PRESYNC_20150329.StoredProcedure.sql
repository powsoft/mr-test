USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoices_POS_Supplier_InvoiceSeparationIsFour_Create_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prInvoices_POS_Supplier_InvoiceSeparationIsFour_Create_PRESYNC_20150329]
as
/*
*/
declare @billingcontrolfrequency nvarchar(50)
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
declare @chainid int
declare @invoicedetailtypeid smallint
declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @MyID int
declare @processid int

set @MyID = 24135

--declare @billingcontrolfrequency nvarchar(50)= 'Weekly'

SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobRunningID = 14

Update I Set ProcessID = @ProcessID
--Select Processid, *
from InvoiceDetails I with(nolock)
inner join Chains CH
on CH.ChainID = I.ChainID
inner join DataTrue_EDI..ProcessStatus C 
On C.ChainName = CH.ChainIdentifier
Inner Join BillingControl B
on B.EntityIDToInvoice = I.SupplierID
where SupplierInvoiceID is null
and ProcessID in (Select ProcessID from JobProcesses where JobRunningID in (14))
and I.SupplierID <> 0
and InvoiceDetailTypeID in (1,16)
--and RetailerInvoiceID is not null
and C.AllFilesReceived = 1
and C.BillingIsRunning = 1
and C.BillingComplete = 0
and C.Date = convert(date, getdate())
--and ProcessID <> @ProcessID
and C.RecordTypeID = 2
--and RecordType = 2

set @currentdatetime = GETDATE()

set @rec = CURSOR local fast_forward for
	select BillingControlID, EntityIDToInvoice, BillingControlDay, BillingControlClosingDelay,
		ProductSubGroupType, ProductSubGroupID, NextBillingPeriodRunDateTime, 
		InvoiceSeparation, BillingControlNumberOfPastDaysToRebill, NextBillingPeriodEndDateTime, SeparateCredits, c.ChainID, BillingControlFrequency
		--select *
	from billingcontrol c
	inner join systementities s
	on c.EntityIDToInvoice = s.EntityID
	Inner Join Chains CH
	on CH.ChainID = c.ChainID
	Inner Join DataTrue_EDI..ProcessStatus P
	On P.ChainName = CH.ChainIdentifier
	where s.EntityTypeID = 5
	and InvoiceSeparation = 4
	and nextbillingperiodrundatetime <= getdate() --@currentdatetime
	and P.AllFilesReceived = 1
	and P.BillingIsRunning = 1
	and P.BillingComplete = 0
	and P.Date = convert(date, getdate())
	and IsActive = 1
	and BusinessTypeID = 1
	and P.RecordTypeID = 2
	order by EntityIDToInvoice



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
			--Begin Transaction
		
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

					--select *
					--from InvoiceDetailS with (nolock)
					--where chainid = @chainid
					--and supplierid = @entityidtoinvoice
					--and InvoiceDetailTypeID in (1,16)
					--and SupplierInvoiceID is null
					--and SaleDate >= DATEADD(month, -6, getdate())
					--and ProcessID = @ProcessID
					--order by SaleDate
													
					select @numberofpastdaystorebill = DATEDIFF(day,dateadd(day, -1, min(saledate)), @nextbillingperiodenddatetime) + 7
					from InvoiceDetailS with (nolock)
					where chainid = @chainid
					and supplierid = @entityidtoinvoice
					and InvoiceDetailTypeID in (1,16)
					and SupplierInvoiceID is null
					and SaleDate >= DATEADD(month, -6, getdate())  --Temporary limit
					and ProcessID = @ProcessID
					
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
						
				end

					begin try
						DROP TABLE #tempStoreSetupProducts
					end try
					begin catch
						set @dummyerrorcatch = 0
					end catch	

				
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
							and d.InvoiceDetailTypeID in (1,16) --,7) --change here wait ,7) --POS Only
							and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
							and d.SupplierInvoiceID is null
							and ProcessID = @ProcessID

					if @@rowcount > 0
						begin
							set @needtoinvoice = 1
						end

						
					if @needtoinvoice = 1
						begin
						
							select CAST(0 as int) as SupplierInvoiceID
							,CAST(0 as int) as Storeid
							,CAST('' as varchar(50)) as PoNo
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
								and d.ProcessID = @ProcessID
								group by storeid, productid, SupplierID, isnull(PONo, ''), isnull(InvoiceNo, '')
								having SUM(TotalCost) < 0
								
								--select * from #creditinvoices
								
if @@ROWCOUNT > 0
	begin
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
										   ,[ProcessID]
										   ,[Storeid]
										   ,[PoNo])
								OUTPUT INSERTED.SupplierInvoiceID, inserted.Storeid, inserted.PoNo INTO #outputtable		   
								select @entityidtoinvoice
								,@billingperiodstartdatetime
								,@billingperiodenddatetime
								,SUM(TotalInvAmount) 
								,case	when @invoicedetailtypeid in (1,16) then 0
										when @invoicedetailtypeid in (7) then 5
									else 0 end --@invoicetype
								,SUM(TotalInvAmount)
								,@MyID
								,0
								,@processid
								,storeid
								,PONo
								from #creditinvoices
								group by storeid, PONo
							
								update c set c.SupplierInvoiceID = o.SupplierInvoiceID
								from #creditinvoices c
								inner join #outputtable o
								on c.StoreID = o.Storeid
								and c.pono = o.pono
								
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
								and d.ProcessID = @processid

							
							end
	end		
	
	
						--Select storeid, productid, SupplierID, isnull(PONo, '') as PONo
						--,isnull(InvoiceNo, '') as InvoiceNo, SUM(TotalCost) as TotalInvAmount
						--,CAST(0 as int) as SupplierInvoiceID
						----into #regularinvoices
						--from datatrue_main.dbo.InvoiceDetails d
						--inner join #InvoicedetailIDsToBill i
						--on d.InvoiceDetailID = i.InvoiceDetailID
						--and d.SupplierInvoiceID is null
						--and d.ProcessID = @ProcessID
						--group by storeid, productid, SupplierID, isnull(PONo, ''), isnull(InvoiceNo, '')	
					
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
								   ,[ProcessID]
								   ,[StoreId]
								   ,[Pono])
						OUTPUT INSERTED.SupplierInvoiceID, inserted.Storeid, inserted.Pono INTO #outputtable		   
						select @entityidtoinvoice
						,@billingperiodstartdatetime
						,@billingperiodenddatetime
						,SUM(TotalInvAmount) 
						,case	when @invoicedetailtypeid in (1,16) then 0
								when @invoicedetailtypeid in (7) then 5
							else 0 end --@invoicetype
						,SUM(TotalInvAmount)
						,@MyID
						,0
						,@processid
						,Storeid
						,PONo
						from #regularinvoices
						group by storeid, PONo
					
						update c set c.SupplierInvoiceID = o.SupplierInvoiceID
						from #regularinvoices c
						inner join #outputtable o
						on c.StoreID = o.Storeid
						and c.PONo = o.PoNo
						
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
						and d.ProcessID = @processid									
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
			--Commit Transaction
		end try
			
		begin catch
		
			--rollback transaction
		
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
