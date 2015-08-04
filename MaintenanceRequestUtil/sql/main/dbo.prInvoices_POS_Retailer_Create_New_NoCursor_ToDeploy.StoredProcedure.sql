USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoices_POS_Retailer_Create_New_NoCursor_ToDeploy]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[prInvoices_POS_Retailer_Create_New_NoCursor_ToDeploy]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
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
declare @businesstypeid int

set @MyID = 24135


SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobRunningID = 14

Update I Set ProcessID = @ProcessID
--Select Processid, *
from InvoiceDetails I with(nolock)
inner join BillingControl_Expanded_POS P
on I.ChainID = P.ChainID 
and I.StoreID = P.StoreID 
--and I.SupplierID = P.EntityIDToInvoice
inner join DataTrue_EDI..ProcessStatus C 
On C.ChainName = P.ChainIdentifier
where RetailerInvoiceID is null
--and ProcessID in (Select ProcessID from JobProcesses where JobRunningID in (14))
--and I.SupplierID <> 0
and InvoiceDetailTypeID in (1,16)
and C.AllFilesReceived = 1
and C.BillingIsRunning = 1
and C.BillingComplete = 0
and C.Date = convert(date, getdate())
and P.EntityTypeID in (2, 6)
and C.RecordTypeID = 2
and I.ProcessID <> @processid

set @currentdatetime = GETDATE()

set @rec = CURSOR local fast_forward for
	select Distinct c.EntityIDToInvoice, BillingControlDay, BillingControlClosingDelay,
		ProductSubGroupType, ProductSubGroupID, NextBillingPeriodRunDateTime, 
		InvoiceSeparation, BillingControlNumberOfPastDaysToRebill, NextBillingPeriodEndDateTime, SeparateCredits, c.ChainID, c.BillingControlFrequency, C.BusinessTypeID
		--select *
	from billingcontrol c
	--inner join systementities s
	--on c.EntityIDToInvoice = s.EntityID
	Inner Join BillingControl_Expanded_POS E
	On E.BillingControlID = c.BillingControlID
	Inner Join DataTrue_EDI..ProcessStatus P
	On P.ChainName = E.ChainIdentifier
	where E.EntityTypeID in (2, 6)
	--and InvoiceSeparation = 4
	and nextbillingperiodrundatetime <= getdate() --@currentdatetime
	and P.AllFilesReceived = 1
	and P.BillingIsRunning = 1
	and P.BillingComplete = 0
	and P.Date = convert(date, getdate())
	--and IsActive = 1
	and c.BusinessTypeID in (1, 4)
	and P.RecordTypeID = 2
	order by c.EntityIDToInvoice



open @rec

fetch next from @rec 
into @EntityIDToInvoice
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
,@BusinessTypeID

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
				End
													
					select @numberofpastdaystorebill = DATEDIFF(day,dateadd(day, -1, min(saledate)), @nextbillingperiodenddatetime) + 7
					from InvoiceDetailS with (nolock)
					where chainid = @chainid
					--and supplierid = @entityidtoinvoice
					and InvoiceDetailTypeID in (1,16)
					and RetailerInvoiceID is null
					and SaleDate >= DATEADD(month, -6, getdate())  --Temporary limit
					and ProcessID = @ProcessID
					
					if @numberofpastdaystorebill is null
						set @numberofpastdaystorebill = 0
						
					set @numberofperiodstoruncalc = Case When @billingcontrolfrequency = 'daily' 
														then  @numberofpastdaystorebill/1 
														Else @numberofpastdaystorebill/7 End
					if @numberofperiodstoruncalc < 1
						begin
							set @numberofperiodstorun = 1
						end
					else
						begin
							set @numberofperiodstorun = CAST(@numberofperiodstoruncalc as int)
						end
						
				--end

					begin try
						DROP TABLE #tempStoreSetupProducts
					end try
					begin catch
						set @dummyerrorcatch = 0
					end catch	

				
			while @numberofperiodsrun < @numberofperiodstorun
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

					if @invoicetype in (0,1)

							select InvoiceDetailID into #InvoicedetailIDsToBill 
							from InvoiceDetails d with(nolock)
							inner join (Select Supplierid, Storeid 
										from BillingControl_Expanded_POS P 
										Where P.EntityIDToInvoice = @entityidtoinvoice
										and BusinessTypeID = @Businesstypeid
										and P.BillingControlFrequency = @BillingControlFrequency) P
							on d.SupplierID = P.Supplierid 
							and P.StoreID = d.StoreID
							where 1=1
							and d.ChainID = @chainid
							and d.InvoiceDetailTypeID in (1,7,16) --,7) --change here wait --POS Only
							and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
							and d.RetailerInvoiceID is null
							and ProcessID = @ProcessID

					if @@rowcount > 0
						begin
							set @needtoinvoice = 1
						end

						
					if @needtoinvoice = 1
						begin
		
										
							select CAST(0 as int) as RetailerInvoiceID
							,CAST(0 as int) as Storeid
							,CAST('' as varchar(50)) as PoNo
							,CAST(0 as int) as SupplierId
							,CAST(' ' as date) as Saledate
							,cast(null as int) as InvoiceTypeID
							, CAST(Null as varchar(50)) as InvoiceNo
							into #outputtable		--Drop Table Select * from #outputtable			
						
							if @separatecredits = 1
							begin
											
								Select Cast(null as int) storeid
								, cast(null as int) productid
								, Cast(null as int) SupplierID
								, cast(Null as varchar(50)) as PONo
								, CAST(null as money) as TotalInvAmount
								, CAST(Null as int) as RetailerInvoiceId
								, CAST(' ' as date) as Saledate
								, CAST(null as int) as InvoiceDetailTypeID
								, CAST(Null as varchar(50)) as InvoiceNo
								into #CreditInvoices
								
								Truncate Table #CreditInvoices
								
							If @invoiceseparation = 1
								Begin
								
								Insert into #CreditInvoices(storeid, Productid, TotalInvAmount, RetailerInvoiceId)
								Select storeid, productid
								, SUM(TotalCost) as TotalInvAmount
								,CAST(0 as int) as RetailerInvoiceId
								--into #creditinvoices
								from datatrue_main.dbo.InvoiceDetails d
								inner join #InvoicedetailIDsToBill i
								on d.InvoiceDetailID = i.InvoiceDetailID
								and d.ProcessID = @ProcessID
								group by storeid, productid, SupplierID
								having SUM(TotalCost) < 0
								
								End
							
							If @invoiceseparation = 2
								Begin
								
								Insert into #creditinvoices(storeid, Productid, SupplierID, TotalInvAmount, RetailerInvoiceId)
								Select storeid, productid, SupplierID
								, SUM(TotalCost) as TotalInvAmount
								,CAST(0 as int) as RetailerInvoiceId
								--into #creditinvoices
								from datatrue_main.dbo.InvoiceDetails d
								inner join #InvoicedetailIDsToBill i
								on d.InvoiceDetailID = i.InvoiceDetailID
								and d.ProcessID = @ProcessID
								group by storeid, productid, SupplierID
								having SUM(TotalCost) < 0
								
								End
								
							If @invoiceseparation = 3
								Begin
								
								Insert into #creditinvoices(storeid, Productid, SupplierID, TotalInvAmount, RetailerInvoiceId, InvoiceDetailTypeID)
								Select storeid, productid, SupplierID
								, SUM(TotalCost) as TotalInvAmount
								, CAST(0 as int) as RetailerInvoiceId
								, InvoiceDetailTypeID
								--into #creditinvoices
								from datatrue_main.dbo.InvoiceDetails d
								inner join #InvoicedetailIDsToBill i
								on d.InvoiceDetailID = i.InvoiceDetailID
								and d.ProcessID = @ProcessID
								group by storeid, productid, SupplierID, InvoiceDetailTypeID
								having SUM(TotalCost) < 0
								
								End
							
							If @invoiceseparation = 4
								Begin
								
								Insert into #creditinvoices(storeid, productid, SupplierID, PONo, TotalInvAmount, RetailerInvoiceId, InvoiceDetailTypeID)
								Select storeid, productid, SupplierID, isnull(PONo, '') as PONo
								, SUM(TotalCost) as TotalInvAmount
								,CAST(0 as int) as Retailerinvoiceid
								, InvoiceDetailTypeID
								--into #creditinvoices
								from datatrue_main.dbo.InvoiceDetails d
								inner join #InvoicedetailIDsToBill i
								on d.InvoiceDetailID = i.InvoiceDetailID
								and d.ProcessID = @ProcessID
								group by storeid, productid, SupplierID, isnull(PONo, ''), InvoiceDetailTypeID
								having SUM(TotalCost) < 0
							
							End
							
							If @invoiceseparation = 5
								Begin
								
								Insert into #creditinvoices(storeid, productid, SupplierID, PONo, TotalInvAmount, RetailerInvoiceId, Saledate, InvoiceDetailTypeID)
								Select storeid, productid, SupplierID, isnull(PONo, '') as PONo
								, SUM(TotalCost) as TotalInvAmount
								, CAST(0 as int) as Retailerinvoiceid
								, SaleDate
								, InvoiceDetailTypeID
								--into #creditinvoices
								from datatrue_main.dbo.InvoiceDetails d
								inner join #InvoicedetailIDsToBill i
								on d.InvoiceDetailID = i.InvoiceDetailID
								and d.ProcessID = @ProcessID
								group by storeid, productid, SupplierID, isnull(PONo, ''), saledate, InvoiceDetailTypeID
								having SUM(TotalCost) < 0
							
							End
							
								If @invoiceseparation = 6
								
									Begin
									
									Insert into #creditinvoices(storeid, productid, SupplierID, InvoiceNo, TotalInvAmount, RetailerInvoiceId, InvoiceDetailTypeID)
									Select storeid, productid, SupplierID, isnull(InvoiceNo, '') as InvoiceNo
									,SUM(TotalCost) as TotalInvAmount
									,CAST(0 as int) as RetailerInvoiceID
									, InvoiceDetailTypeID
									from datatrue_main.dbo.InvoiceDetails d
									inner join #InvoicedetailIDsToBill i
									on d.InvoiceDetailID = i.InvoiceDetailID
									group by storeid, productid, SupplierID, isnull(InvoiceNo, ''), InvoiceDetailTypeID
									having SUM(TotalCost) < 0
									
								End
												
												--select * from #creditinvoices
												
											if @@ROWCOUNT > 0
												begin
													print 'herenow'

																			
												truncate table #outputtable
											
												INSERT INTO [DataTrue_Main].[dbo].[InvoicesRetailer] 
														   (ChainID
														   ,[InvoicePeriodStart]
														   ,[InvoicePeriodEnd]
														   ,[OriginalAmount]
														   ,[InvoiceTypeID]
														   ,[OpenAmount]
														   ,[LastUpdateUserID]
														   ,[InvoiceStatus]
														   ,[ProcessID]
														   ,[Storeid]
														   ,PoNo
														   ,Supplier_id
														   ,InvoiceNumber )
												OUTPUT INSERTED.RetailerInvoiceID, inserted.Storeid, inserted.PoNo, inserted.Supplier_id, inserted.InvoicePeriodEnd, inserted.InvoiceTypeID, inserted.InvoiceNumber INTO #outputtable 	
												select @entityidtoinvoice
												,Case when @invoiceseparation = 5 then Saledate Else @billingperiodstartdatetime End
												,Case when @invoiceseparation = 5 Then Saledate Else @billingperiodenddatetime End
												,SUM(TotalInvAmount) 
												,case	when invoicedetailtypeid in (1) then 0
														When invoicedetailtypeid in (16) then 16
														when invoicedetailtypeid in (7) then 5
													else 0 end --@invoicetype
												,SUM(TotalInvAmount)
												,@MyID
												,0
												,@processid
												,storeid
												,PONo
												,SupplierID
												,InvoiceNo
												from #creditinvoices
												group by storeid, PONo, SupplierID, Saledate, InvoiceNo, InvoiceDetailTypeID
											
									If @invoiceseparation = 1
										Begin
											update c set c.RetailerInvoiceID = o.RetailerInvoiceID
											from #CreditInvoices c
											inner join #outputtable o
											on c.StoreID = o.Storeid
											
											update d set d.RetailerInvoiceID = c.RetailerInvoiceID, d.RecordStatus = 1
											from datatrue_main.dbo.InvoiceDetails d
											inner join #CreditInvoices c
											on d.StoreID = c.StoreID
											and d.invoicedetailid in
											(select InvoiceDetailID from #InvoicedetailIDsToBill)
											and d.RetailerInvoiceID is null	
											and d.ProcessID = @processid
										End
										
										If @invoiceseparation = 2
										Begin
											update c set c.RetailerInvoiceID = o.RetailerInvoiceID
											from #CreditInvoices c
											inner join #outputtable o
											on c.StoreID = o.Storeid
											and c.SupplierID = o.SupplierId
											
											update d set d.RetailerInvoiceID = c.RetailerInvoiceID, d.RecordStatus = 1
											from datatrue_main.dbo.InvoiceDetails d
											inner join #CreditInvoices c
											on d.StoreID = c.StoreID
											and d.SupplierID = c.SupplierID
											and d.invoicedetailid in
											(select InvoiceDetailID from #InvoicedetailIDsToBill)
											and d.RetailerInvoiceID is null	
											and d.ProcessID = @processid
										End
										
										If @invoiceseparation = 3
										Begin
											update c set c.RetailerInvoiceID = o.RetailerInvoiceID
											from #CreditInvoices c
											inner join #outputtable o
											on c.StoreID = o.Storeid
											and c.SupplierID = o.SupplierId
											and c.InvoiceDetailTypeID = Case when o.InvoiceTypeID = 5 then 7 else case when o.InvoiceTypeID = 16 then 16 Else 1 End end
											
											update d set d.RetailerInvoiceID = c.RetailerInvoiceID, d.RecordStatus = 1
											from datatrue_main.dbo.InvoiceDetails d
											inner join #CreditInvoices c
											on d.StoreID = c.StoreID
											and d.SupplierID = c.SupplierID
											and d.InvoiceDetailTypeID = c.InvoiceDetailTypeID
											and d.invoicedetailid in
											(select InvoiceDetailID from #InvoicedetailIDsToBill)
											and d.RetailerInvoiceID is null	
											and d.ProcessID = @processid
										End
										
										If @invoiceseparation = 4
										Begin
											update c set c.RetailerInvoiceID = o.RetailerInvoiceID
											from #CreditInvoices c
											inner join #outputtable o
											on c.StoreID = o.Storeid
											and c.SupplierID = o.SupplierId
											and ISNULL(c.PONO, '') = Isnull(o.PONO, '')
											and c.InvoiceDetailTypeID = Case when o.InvoiceTypeID = 5 then 7 else case when o.InvoiceTypeID = 16 then 16 Else 1 End end
											
											update d set d.RetailerInvoiceID = c.RetailerInvoiceID, d.RecordStatus = 1
											from datatrue_main.dbo.InvoiceDetails d
											inner join #CreditInvoices c
											on d.StoreID = c.StoreID
											and d.SupplierID = c.SupplierID
											and isnull(d.pono,'') = isnull(c.pono, '')
											and d.InvoiceDetailTypeID = c.InvoiceDetailTypeID
											and d.invoicedetailid in
											(select InvoiceDetailID from #InvoicedetailIDsToBill)
											and d.RetailerInvoiceID is null	
											and d.ProcessID = @processid
										End
										
										If @invoiceseparation = 5
										Begin
											update c set c.RetailerInvoiceID = o.RetailerInvoiceID
											from #CreditInvoices c
											inner join #outputtable o
											on c.StoreID = o.Storeid
											and c.SupplierID = o.SupplierId
											and ISNULL(c.PONO, '') = Isnull(o.PONO, '')
											and c.saledate = o.Saledate
											and c.InvoiceDetailTypeID = Case when o.InvoiceTypeID = 5 then 7 else case when o.InvoiceTypeID = 16 then 16 Else 1 End end
											
											update d set d.RetailerInvoiceID = c.RetailerInvoiceID, d.RecordStatus = 1
											from datatrue_main.dbo.InvoiceDetails d
											inner join #CreditInvoices c
											on d.StoreID = c.StoreID
											and d.SupplierID = c.SupplierID
											and isnull(d.pono,'') = isnull(c.pono, '')
											and d.InvoiceDetailTypeID = c.InvoiceDetailTypeID
											and d.saledate = c.saledate
											and d.invoicedetailid in
											(select InvoiceDetailID from #InvoicedetailIDsToBill)
											and d.RetailerInvoiceID is null	
											and d.ProcessID = @processid
										End
										
										If @invoiceseparation = 6
										Begin
											update c set c.RetailerInvoiceID = o.RetailerInvoiceID
											from #CreditInvoices c
											inner join #outputtable o
											on c.StoreID = o.Storeid
											and c.SupplierID = o.SupplierId
											and ISNULL(c.InvoiceNo, '') = Isnull(o.InvoiceNo, '')
											and c.InvoiceDetailTypeID = Case when o.InvoiceTypeID = 5 then 7 else case when o.InvoiceTypeID = 16 then 16 Else 1 End end
											
											update d set d.RetailerInvoiceID = c.RetailerInvoiceID, d.RecordStatus = 1
											from datatrue_main.dbo.InvoiceDetails d
											inner join #CreditInvoices c
											on d.StoreID = c.StoreID
											and d.SupplierID = c.SupplierID
											and isnull(d.InvoiceNo,'') = isnull(c.InvoiceNo, '')
											and d.InvoiceDetailTypeID = c.InvoiceDetailTypeID
											and d.invoicedetailid in
											(select InvoiceDetailID from #InvoicedetailIDsToBill)
											and d.RetailerInvoiceID is null	
											and d.ProcessID = @processid
										End
											
											end
										--end		
					
					
									
								Select Cast(null as int) storeid
								, Cast(null as int) SupplierID
								, cast(Null as varchar(50)) as PONo
								, CAST(null as money) as TotalInvAmount
								,CAST(Null as int) as RetailerInvoiceId
								,CAST(' ' as date) as Saledate
								, CAST(null as int) as InvoiceDetailType
								, cast(Null as varchar(50)) as InvoiceNo
								into #RegularInvoices
								
								
						Truncate table #RegularInvoices
						
							If @invoiceseparation = 1
								Begin
								
								Insert into #RegularInvoices(storeid, TotalInvAmount, RetailerInvoiceId)
								Select storeid
								, SUM(TotalCost) as TotalInvAmount
								,CAST(0 as int) as RetailerInvoiceId
								--into #creditinvoices
								from datatrue_main.dbo.InvoiceDetails d
								inner join #InvoicedetailIDsToBill i
								on d.InvoiceDetailID = i.InvoiceDetailID
								and d.ProcessID = @ProcessID
								group by storeid
								having SUM(TotalCost) < 0
								
								End
								
							If @invoiceseparation = 2
								Begin
								
								Insert into #RegularInvoices(storeid, Supplierid, TotalInvAmount, RetailerInvoiceId)
								Select storeid, SupplierID
								, SUM(TotalCost) as TotalInvAmount
								,CAST(0 as int) as RetailerInvoiceId
								--into #creditinvoices
								from datatrue_main.dbo.InvoiceDetails d
								inner join #InvoicedetailIDsToBill i
								on d.InvoiceDetailID = i.InvoiceDetailID
								and d.ProcessID = @ProcessID
								group by storeid, SupplierID
								--having SUM(TotalCost) < 0
								
								End
								
							If @invoiceseparation = 3
								Begin
								
								Insert into #RegularInvoices(storeid, SupplierID,TotalInvAmount, RetailerInvoiceId,  InvoiceDetailType)
								Select storeid, SupplierID
								, SUM(TotalCost) as TotalInvAmount
								,CAST(0 as int) as RetailerInvoiceId
								,InvoiceDetailTypeID
								--into #creditinvoices
								from datatrue_main.dbo.InvoiceDetails d
								inner join #InvoicedetailIDsToBill i
								on d.InvoiceDetailID = i.InvoiceDetailID
								and d.ProcessID = @ProcessID
								group by storeid, SupplierID, InvoiceDetailTypeID
								--having SUM(TotalCost) < 0
								
								End
							
							If @invoiceseparation = 4
								Begin
								
								Insert into #RegularInvoices(storeid, SupplierID, PONo,TotalInvAmount, RetailerInvoiceId, InvoiceDetailType)
								Select storeid, SupplierID, isnull(PONo, '') as PONo
								, SUM(TotalCost) as TotalInvAmount
								,CAST(0 as int) as Retailerinvoiceid
								,InvoiceDetailTypeID
								--into #creditinvoices
								from datatrue_main.dbo.InvoiceDetails d
								inner join #InvoicedetailIDsToBill i
								on d.InvoiceDetailID = i.InvoiceDetailID
								and d.ProcessID = 43
								group by storeid, SupplierID, isnull(PONo, ''), InvoiceDetailTypeID
								--having SUM(TotalCost) < 0
							
							End
							
							If @invoiceseparation = 5
								Begin
								
								Insert into #RegularInvoices(storeid, SupplierID, PONo, TotalInvAmount,RetailerInvoiceId, Saledate,  InvoiceDetailType)
								Select storeid, SupplierID, isnull(PONo, '') as PONo
								, SUM(TotalCost) as TotalInvAmount
								,CAST(0 as int) as Retailerinvoiceid
								,SaleDate
								,InvoiceDetailTypeID
								--into #creditinvoices
								from datatrue_main.dbo.InvoiceDetails d
								inner join #InvoicedetailIDsToBill i
								on d.InvoiceDetailID = i.InvoiceDetailID
								and d.ProcessID = @ProcessID
								group by storeid, SupplierID, isnull(PONo, ''), saledate, InvoiceDetailTypeID
								--having SUM(TotalCost) < 0
							
							End
							
							If @invoiceseparation = 6
								
									Begin
									
									Insert into #RegularInvoices(storeid, SupplierID, InvoiceNo, TotalInvAmount, RetailerInvoiceId, InvoiceDetailType)
									Select storeid, SupplierID, isnull(InvoiceNo, '') as InvoiceNo
									,SUM(TotalCost) as TotalInvAmount
									,CAST(0 as int) as RetailerInvoiceID
									, InvoiceDetailTypeID
									from datatrue_main.dbo.InvoiceDetails d
									inner join #InvoicedetailIDsToBill i
									on d.InvoiceDetailID = i.InvoiceDetailID
									group by storeid, productid, SupplierID, isnull(InvoiceNo, ''), InvoiceDetailTypeID
									--having SUM(TotalCost) < 0
									
								End
	
										truncate table #outputtable 
									
										INSERT INTO [DataTrue_Main].[dbo].[InvoicesRetailer] 
														   (ChainID
														   ,[InvoicePeriodStart]
														   ,[InvoicePeriodEnd]
														   ,[OriginalAmount]
														   ,[InvoiceTypeID]
														   ,[OpenAmount]
														   ,[LastUpdateUserID]
														   ,[InvoiceStatus]
														   ,[ProcessID]
														   ,[Storeid]
														   ,PoNo
														   ,Supplier_id
														   ,InvoiceNumber )
												OUTPUT INSERTED.RetailerInvoiceID, inserted.Storeid, inserted.PoNo, inserted.Supplier_id, inserted.InvoicePeriodEnd, inserted.InvoiceTypeID, inserted.InvoiceNumber INTO #outputtable 	
												select @entityidtoinvoice
												,Case when @invoiceseparation = 5 then Saledate Else @billingperiodstartdatetime End
												,Case when @invoiceseparation = 5 Then Saledate Else @billingperiodenddatetime End
												,SUM(TotalInvAmount) 
												,case	when invoicedetailtype in (1) then 0
														When invoicedetailtype in (16) then 16
														when invoicedetailtype in (7) then 5
													else 0 end --@invoicetype
												,SUM(TotalInvAmount)
												,@MyID
												,0
												,@processid
												,storeid
												,PONo
												,SupplierID
												,InvoiceNo
												from #RegularInvoices
												group by storeid, PONo, SupplierID, Saledate, InvoiceNo, InvoiceDetailType
									
									If @invoiceseparation = 1
										Begin
											update c set c.RetailerInvoiceID = o.RetailerInvoiceID
											from #regularinvoices c
											inner join #outputtable o
											on c.StoreID = o.Storeid
											
											update d set d.RetailerInvoiceID = c.RetailerInvoiceID, d.RecordStatus = 1
											from datatrue_main.dbo.InvoiceDetails d
											inner join #regularinvoices c
											on d.StoreID = c.StoreID
											and d.invoicedetailid in
											(select InvoiceDetailID from #InvoicedetailIDsToBill)
											and d.RetailerInvoiceID is null	
											and d.ProcessID = @processid
										End
										
										If @invoiceseparation = 2
										Begin
											update c set c.RetailerInvoiceID = o.RetailerInvoiceID
											from #regularinvoices c
											inner join #outputtable o
											on c.StoreID = o.Storeid
											and c.SupplierID = o.SupplierId
											
											update d set d.RetailerInvoiceID = c.RetailerInvoiceID, d.RecordStatus = 1
											from datatrue_main.dbo.InvoiceDetails d
											inner join #regularinvoices c
											on d.StoreID = c.StoreID
											and d.SupplierID = c.SupplierID
											and d.invoicedetailid in
											(select InvoiceDetailID from #InvoicedetailIDsToBill)
											and d.RetailerInvoiceID is null	
											and d.ProcessID = @processid
										End
										
										If @invoiceseparation = 3
										Begin
											update c set c.RetailerInvoiceID = o.RetailerInvoiceID
											from #regularinvoices c
											inner join #outputtable o
											on c.StoreID = o.Storeid
											and c.SupplierID = o.SupplierId
											and c.InvoiceDetailType = Case when o.InvoiceTypeID = 5 then 7 else case when o.InvoiceTypeID = 16 then 16 Else 1 End end
											
											update d set d.RetailerInvoiceID = c.RetailerInvoiceID, d.RecordStatus = 1
											from datatrue_main.dbo.InvoiceDetails d
											inner join #regularinvoices c
											on d.StoreID = c.StoreID
											and d.SupplierID = c.SupplierID
											and d.InvoiceDetailTypeID = c.InvoiceDetailType
											and d.invoicedetailid in
											(select InvoiceDetailID from #InvoicedetailIDsToBill)
											and d.RetailerInvoiceID is null	
											and d.ProcessID = @processid
										End
										
										If @invoiceseparation = 4
										Begin
											update c set c.RetailerInvoiceID = o.RetailerInvoiceID
											from #regularinvoices c
											inner join #outputtable o
											on c.StoreID = o.Storeid
											and c.SupplierID = o.SupplierId
											and ISNULL(c.PONO, '') = Isnull(o.PONO, '')
											and c.InvoiceDetailType = Case when o.InvoiceTypeID = 5 then 7 else case when o.InvoiceTypeID = 16 then 16 Else 1 End end
											
											update d set d.RetailerInvoiceID = c.RetailerInvoiceID, d.RecordStatus = 1
											from datatrue_main.dbo.InvoiceDetails d
											inner join #regularinvoices c
											on d.StoreID = c.StoreID
											and d.SupplierID = c.SupplierID
											and isnull(d.pono,'') = isnull(c.pono, '')
											and d.InvoiceDetailTypeID = c.InvoiceDetailType
											and d.invoicedetailid in
											(select InvoiceDetailID from #InvoicedetailIDsToBill)
											and d.RetailerInvoiceID is null	
											and d.ProcessID = @processid
										End
										
										If @invoiceseparation = 5
										Begin
											update c set c.RetailerInvoiceID = o.RetailerInvoiceID
											from #regularinvoices c
											inner join #outputtable o
											on c.StoreID = o.Storeid
											and c.SupplierID = o.SupplierId
											and ISNULL(c.PONO, '') = Isnull(o.PONO, '')
											and c.saledate = o.Saledate
											and c.InvoiceDetailType = Case when o.InvoiceTypeID = 5 then 7 else case when o.InvoiceTypeID = 16 then 16 Else 1 End end
											
											update d set d.RetailerInvoiceID = c.RetailerInvoiceID, d.RecordStatus = 1
											from datatrue_main.dbo.InvoiceDetails d
											inner join #regularinvoices c
											on d.StoreID = c.StoreID
											and d.SupplierID = c.SupplierID
											and isnull(d.pono,'') = isnull(c.pono, '')
											and d.InvoiceDetailTypeID = c.InvoiceDetailType
											and d.saledate = c.saledate
											and d.invoicedetailid in
											(select InvoiceDetailID from #InvoicedetailIDsToBill)
											and d.RetailerInvoiceID is null	
											and d.ProcessID = @processid
										End
										
										If @invoiceseparation = 6
										Begin
											update c set c.RetailerInvoiceID = o.RetailerInvoiceID
											from #RegularInvoices c
											inner join #outputtable o
											on c.StoreID = o.Storeid
											and c.SupplierID = o.SupplierId
											and ISNULL(c.InvoiceNo, '') = Isnull(o.InvoiceNo, '')
											and c.InvoiceDetailType = Case when o.InvoiceTypeID = 5 then 7 else case when o.InvoiceTypeID = 16 then 16 Else 1 End end
											
											update d set d.RetailerInvoiceID = c.RetailerInvoiceID, d.RecordStatus = 1
											from datatrue_main.dbo.InvoiceDetails d
											inner join #RegularInvoices c
											on d.StoreID = c.StoreID
											and d.SupplierID = c.SupplierID
											and isnull(d.InvoiceNo,'') = isnull(c.InvoiceNo, '')
											and d.InvoiceDetailTypeID = c.InvoiceDetailType
											and d.invoicedetailid in
											(select InvoiceDetailID from #InvoicedetailIDsToBill)
											and d.RetailerInvoiceID is null	
											and d.ProcessID = @processid
										End
				end	
				End											
					--herenow 20140806										
				--**************************************************************************************************																															

									
									if @numberofperiodsrun < 1
										begin
										
											set @newnextbillingperiodenddatetime = 
											case 
												when upper(@billingcontrolfrequency) = 'DAILY' then dateadd(day,1,@billingperiodenddatetime)
												when upper(@billingcontrolfrequency) = 'WEEKLY' then dateadd(day,7,@billingperiodenddatetime)
												--when upper(@billingcontrolfrequency) = 'BIWEEKLY' then dateadd(day,14,@billingperiodenddatetime)
												--when upper(@billingcontrolfrequency) = 'MONTHLYCALENDAR' then dateadd(day,-1,dateadd(month,2,@billingperiodstartdatetime))
											else 
												dateadd(day,7,@billingperiodenddatetime)
											end
										
										If @billingcontrolfrequency = 'Weekly'
											Begin
										
												update BillingControl
												set LastBillingPeriodEndDateTime = NextBillingPeriodEndDateTime
												,NextBillingPeriodEndDateTime = @newnextbillingperiodenddatetime
												,NextBillingPeriodRunDateTime = Convert(datetime, STUFF(CONVERT(VARCHAR(50),NextBillingPeriodRunDateTime,126) ,1, 10, dateadd(day, @billingcontrolclosingdelay, Convert(date, @newnextbillingperiodenddatetime))))
												,LastUpdateUserID = @MyID
												,DateTimeLastUpdate = @currentdatetime
												where BillingControlFrequency =@billingcontrolfrequency
												and BusinessTypeID = @businesstypeid
												and entityidtoinvoice = @entityidtoinvoice
												
											End
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
				End			
							--Commit Transaction
			End Try
							
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
		into @EntityIDToInvoice
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
		,@businesstypeid
	end
	
close @rec
deallocate @rec

END
GO
