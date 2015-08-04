USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoices_POSAdj_Supplier_InvoiceSeparationIsFour_Create]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prInvoices_POSAdj_Supplier_InvoiceSeparationIsFour_Create]
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

--SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobRunningID = 9

--Update I Set ProcessID = @ProcessID
----Select Processid, *
--from InvoiceDetails I with(nolock)
--inner join Chains CH
--on CH.ChainID = I.ChainID
--inner join DataTrue_EDI..ProcessStatus C 
--On C.ChainName = CH.ChainIdentifier
--where SupplierInvoiceID is null
----and ProcessID in (Select ProcessID from JobProcesses where JobRunningID = 9)
--and SupplierID <> 0
--and InvoiceDetailTypeID in (1,16)
--and RetailerInvoiceID is not null
--and C.AllFilesReceived = 1
--and C.BillingIsRunning = 1
--and C.BillingComplete = 0
--and C.Date = CONVERT(date, getdate())
--and Isnull(ProcessID,0) <> @ProcessID

set @currentdatetime = Cast(GETDATE() as DATE)

set @rec = CURSOR local fast_forward for
	select distinct BillingControlID, EntityIDToInvoice, BillingControlDay, BillingControlClosingDelay,
		ProductSubGroupType, ProductSubGroupID, getdate(), --NextBillingPeriodRunDateTime, 
		InvoiceSeparation, 133, dateadd(day,7,NextBillingPeriodEndDateTime), SeparateCredits, chainid, billingcontrolfrequency
		--InvoiceSeparation, BillingControlNumberOfPastDaysToRebill, NextBillingPeriodEndDateTime, SeparateCredits, billingcontrolfrequency
		--select *
	from billingcontrol c
	inner join systementities s
	on c.EntityIDToInvoice = s.EntityID
	where s.EntityTypeID = 5
	--and InvoiceSeparation = 4
	and IsActive = 1
	and c.BusinessTypeID = 1
	and EntityIDToInvoice in 
	(	
		select distinct supplierid 
		from invoicedetails with (nolock)
		where invoicedetailtypeid = 7
		and SupplierID <> 0
		and supplierinvoiceid is null
		and CAST(datetimecreated as date) = CAST(GETDATE() as date)
		and productid in (select distinct productid from productidentifiers where productidentifiertypeid = 8)
	)	
	and cast(nextbillingperiodrundatetime as date) <= cast(GETDATE() + 7 as date)
	--and ChainID in (60634, 60624, 75230, 42490)
	--and ChainID = 75407

/*
select distinct chainid from invoicedetails where invoicedetailtypeid = 7 and supplierinvoiceid is null and cast(datetimecreated as date) = '11/4/2014'

*/
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
/*
	select distinct BillingControlID, EntityIDToInvoice, BillingControlDay, BillingControlClosingDelay,
		ProductSubGroupType, ProductSubGroupID, NextBillingPeriodRunDateTime, 
		InvoiceSeparation, 140, NextBillingPeriodEndDateTime, SeparateCredits, chainid, billingcontrolfrequency
*/
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

					select *
					from InvoiceDetailS with (nolock)
					where chainid = @chainid
					and supplierid = @entityidtoinvoice
					and InvoiceDetailTypeID in (7)--1,16,7)
					and SupplierInvoiceID is null
					--and SaleDate >= DATEADD(month, -4, getdate())
					and CAST(datetimecreated as date) = CAST(GETDATE() as date)
					----and ProcessID = @ProcessID
					order by SaleDate
													
					--select @numberofpastdaystorebill = DATEDIFF(day,min(saledate), @nextbillingperiodenddatetime) + 7
					--from InvoiceDetailS with (nolock)
					--where chainid = @chainid
					--and supplierid = @entityidtoinvoice
					--and InvoiceDetailTypeID in (7) --1,16,7)
					--and SupplierInvoiceID is null
					--and SaleDate >= DATEADD(month, -4, getdate())  --Temporary limit
					------and ProcessID = @ProcessID
					
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
							and d.InvoiceDetailTypeID in (7) --1,16,7) --,7) --change here wait ,7) --POS Only
							and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
							and CAST(d.datetimecreated as date) = CAST(GETDATE() as date)
							and d.SupplierInvoiceID is null
							----and ProcessID = @ProcessID

					if @@rowcount > 0
						begin
							set @needtoinvoice = 1
						end

						
					if @needtoinvoice = 1
						begin
						
							select CAST(0 as int) as SupplierInvoiceID
							,CAST(0 as int) as Storeid, CAST(null as varchar(50)) as PONO
							into #outputtable						
						
							if @separatecredits = 1
							begin
							
								Select storeid, productid, SupplierID, '' as PONo --isnull(PONo, '') as PONo
								,SUM(TotalCost) as TotalInvAmount
								--,isnull(InvoiceNo, '') as InvoiceNo, SUM(TotalCost) as TotalInvAmount
								,CAST(0 as int) as SupplierInvoiceID
								into #creditinvoices
								from datatrue_main.dbo.InvoiceDetails d
								inner join #InvoicedetailIDsToBill i
								on d.InvoiceDetailID = i.InvoiceDetailID
								--and d.ProcessID = @ProcessID
								group by storeid, productid, SupplierID--, isnull(PONo, '')--, isnull(InvoiceNo, '')
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
										   --,[TransmissionRef]
										   ,[ProcessID]
										   	,StoreID
											,PONO)
								OUTPUT INSERTED.SupplierInvoiceID, inserted.StoreID, inserted.PONO INTO #outputtable		   
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
								--,CAST(storeid as varchar(50))
								,@processid
								,StoreID
								,PONO
								from #creditinvoices
								group by storeid, PONO
							
								update c set c.SupplierInvoiceID = o.SupplierInvoiceID
								from #creditinvoices c
								inner join #outputtable o
								on c.StoreID = o.Storeid
								--and c.PONO = o.PONO
								
								update d set d.SupplierInvoiceID = c.SupplierInvoiceID, d.RecordStatus = 1
								from datatrue_main.dbo.InvoiceDetails d
								inner join #creditinvoices c
								on d.StoreID = c.StoreID
								and d.ProductID = c.ProductID
								and d.SupplierID = c.supplierid
								--and isnull(d.PONo, '') = isnull(c.PONo, '')
								--and isnull(d.InvoiceNo, '') = isnull(d.InvoiceNo, '')
								and d.invoicedetailid in
								(select InvoiceDetailID from #InvoicedetailIDsToBill)
								--and d.ProcessID = @processid

							
							end
	end		
	
	
						Select storeid, productid, SupplierID, '' as PONo --isnull(PONo, '') as PONo
						,SUM(TotalCost) as TotalInvAmount
						--,isnull(InvoiceNo, '') as InvoiceNo, SUM(TotalCost) as TotalInvAmount
						,CAST(0 as int) as SupplierInvoiceID
						--into #regularinvoices
						from datatrue_main.dbo.InvoiceDetails d
						inner join #InvoicedetailIDsToBill i
						on d.InvoiceDetailID = i.InvoiceDetailID
						and d.SupplierInvoiceID is null
						--and d.ProcessID = @ProcessID
						group by storeid, productid, SupplierID--, isnull(PONo, '')--, isnull(InvoiceNo, '')	
					
						Select storeid, productid, SupplierID, '' as PONo --isnull(PONo, '') as PONo
						,SUM(TotalCost) as TotalInvAmount
						--,isnull(InvoiceNo, '') as InvoiceNo, SUM(TotalCost) as TotalInvAmount
						,CAST(0 as int) as SupplierInvoiceID
						into #regularinvoices
						from datatrue_main.dbo.InvoiceDetails d
						inner join #InvoicedetailIDsToBill i
						on d.InvoiceDetailID = i.InvoiceDetailID
						and d.SupplierInvoiceID is null
						group by storeid, productid, SupplierID--, isnull(PONo, '')--, isnull(InvoiceNo, '')
						
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
								   --,[TransmissionRef]
								   ,[ProcessID]
								   ,[StoreID]
								   ,[PONO])
						OUTPUT INSERTED.SupplierInvoiceID, inserted.StoreID, inserted.PONO INTO #outputtable		   
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
						--,CAST(storeid as varchar(50))
						,@processid
						,StoreID
						,PONO
						from #regularinvoices
						group by storeid, PONO
					
						update c set c.SupplierInvoiceID = o.SupplierInvoiceID
						from #regularinvoices c
						inner join #outputtable o
						on c.StoreID = o.Storeid
						--and c.PONo = o.PONO
						
						update d set d.SupplierInvoiceID = c.SupplierInvoiceID, d.RecordStatus = 1
						from datatrue_main.dbo.InvoiceDetails d
						inner join #regularinvoices c
						on d.StoreID = c.StoreID
						and d.ProductID = c.ProductID
						and d.SupplierID = c.supplierid
						--and isnull(d.PONo, '') = isnull(c.PONo, '')
						--and isnull(d.InvoiceNo, '') = isnull(d.InvoiceNo, '')
						and d.invoicedetailid in
						(select InvoiceDetailID from #InvoicedetailIDsToBill)
						and d.SupplierInvoiceID is null	
						--and d.ProcessID = @processid									
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
						
							--update BillingControl
							--set LastBillingPeriodEndDateTime = NextBillingPeriodEndDateTime
							--,NextBillingPeriodEndDateTime = @newnextbillingperiodenddatetime
							--,NextBillingPeriodRunDateTime = dateadd(day,@billingcontrolclosingdelay,@newnextbillingperiodenddatetime)
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

/*

select paymentid, *
--select distinct supplierid
--select * into zztemp_Invoicedetails_KNG_BeforeSupplierBillingTest_20141008
from invoicedetails
where 1 = 1
	and ChainID = 42490
	and supplierid in (41440) --74796)
and invoicedetailtypeid in (1,16)
and supplierinvoiceid is null
order by saledate
order by supplierinvoiceid

59979
41440

select supplierinvoiceid, OriginalAmount, *
from invoicessupplier
where supplierid = 59979 --41440
and cast(datetimecreated as date) = '10/9/2014'

select *
--select sum(unitcost * totalqty)
from invoicedetails d
where supplierinvoiceid in
(1149958)

1149952	2.99
1149953	2.99
1149954	2.99
1149955	2.99
1149956	2.99
1149957	5.98
1149958	17.94
1149959	2.99

1149714	39.66
1149715	12.69
1149716	2.99
1149717	9.57
1149718	9.73
1149719	9.74
1149720	5.59

*/
return
GO
