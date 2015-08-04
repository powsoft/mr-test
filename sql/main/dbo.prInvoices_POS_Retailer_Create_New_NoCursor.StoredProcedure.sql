USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoices_POS_Retailer_Create_New_NoCursor]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Joshua Kiracofe
-- Create date: 3/12/2015
-- Description:	Removed all the nested cursors to enhance performance
-- =============================================
CREATE PROCEDURE [dbo].[prInvoices_POS_Retailer_Create_New_NoCursor]
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

set @MyID = 24135


SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobRunningID = 14

Update I Set ProcessID = @ProcessID
--Select Processid, *
from InvoiceDetails I with(nolock)
inner join BillingControl_Expanded_POS P
on I.ChainID = P.ChainID 
and I.StoreID = P.StoreID 
and I.SupplierID = P.EntityIDToInvoice
inner join DataTrue_EDI..ProcessStatus C 
On C.ChainName = P.ChainIdentifier
where SupplierInvoiceID is null
and ProcessID in (Select ProcessID from JobProcesses where JobRunningID in (14))
and I.SupplierID <> 0
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
	select Distinct c.BillingControlID, c.ChainID, BillingControlDay, BillingControlClosingDelay,
		ProductSubGroupType, ProductSubGroupID, NextBillingPeriodRunDateTime, 
		InvoiceSeparation, BillingControlNumberOfPastDaysToRebill, NextBillingPeriodEndDateTime, SeparateCredits, BillingControlFrequency
		--select *
	from billingcontrol c
	Inner Join BillingControl_Expanded_POS E
	On E.BillingControlID = c.BillingControlID
	Inner Join DataTrue_EDI..ProcessStatus P
	On P.ChainName = E.ChainIdentifier
	where E.EntityTypeID in (2, 6)
	and nextbillingperiodrundatetime <= getdate() --@currentdatetime
	and P.AllFilesReceived = 1
	and P.BillingIsRunning = 1
	and P.BillingComplete = 0
	and P.Date = convert(date, getdate())
	and IsActive = 1
	and c.BusinessTypeID in (1, 4)
	and P.RecordTypeID = 0
	order by c.ChainID



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

							--update d set d.SupplierInvoiceID = -1
							select InvoiceDetailID into #InvoicedetailIDsToBill 
							from InvoiceDetails d with(nolock)
							inner join (Select Supplierid, Storeid 
										from BillingControl_Expanded_POS P 
										Where P.EntityIDToInvoice = @entityidtoinvoice) P
							on d.SupplierID = P.Supplierid 
							and P.StoreID = d.StoreID
							where 1=1
							--and d.SupplierID = @entityidtoinvoice
							and d.ChainID = @entityidtoinvoice
							and d.InvoiceDetailTypeID in (1,16) --,7) --change here wait --POS Only
							and SaleDate between cast(@billingperiodstartdatetime as date) and cast(@billingperiodenddatetime as date)
							and d.RetailerInvoiceID is null
							and ProcessID = @ProcessID

					if @@rowcount > 0
						begin
							set @needtoinvoice = 1
						end

						
					if @needtoinvoice = 1
						begin
						
		/*				if @invoiceseparation = 0
								begin
								
								
								
								End
								
								If @invoiceseparation = 1
									Begin
										select CAST(0 as int) as RetailerInvoiceID
											,CAST(0 as int) as Storeid
											,CAST('' as varchar(50)) as PoNo
											into #outputtable1						
										
											if @separatecredits = 1
											begin
											
												Select storeid, SUM(TotalCost) as TotalInvAmount
												,CAST(0 as int) as RetailerInvoiceID
												into #creditinvoices1
												from datatrue_main.dbo.InvoiceDetails d
												inner join #InvoicedetailIDsToBill i
												on d.InvoiceDetailID = i.InvoiceDetailID
												and d.ProcessID = @ProcessID
												group by storeid
												having SUM(TotalCost) < 0
												
												--select * from #creditinvoices
												
											if @@ROWCOUNT > 0
												begin
													print 'herenow'

																			
												truncate table #outputtable1
											
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
														   ,InvoiceNumber )
												OUTPUT INSERTED.RetailerInvoiceID, inserted.Storeid INTO #outputtable1		   
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
												from #creditinvoices1
												group by storeid
											
												update c set c.RetailerInvoiceID = o.RetailerInvoiceID
												from #creditinvoices1 c
												inner join #outputtable1 o
												on c.StoreID = o.Storeid
												and c.pono = o.PoNo
												
												update d set d.RetailerInvoiceID = c.RetailerInvoiceID, d.RecordStatus = 1
												from datatrue_main.dbo.InvoiceDetails d
												inner join #creditinvoices1 c
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
					
					
									
										Select storeid, SUM(TotalCost) as TotalInvAmount
										,CAST(0 as int) as RetailerInvoiceID
										into #regularinvoices1
										from datatrue_main.dbo.InvoiceDetails d
										inner join #InvoicedetailIDsToBill i
										on d.InvoiceDetailID = i.InvoiceDetailID
										and d.RetailerInvoiceID is null
										group by storeid
										
										truncate table #outputtable1
									
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
														   ,InvoiceNumber )
												OUTPUT INSERTED.RetailerInvoiceID, inserted.Storeid INTO #outputtable1		   
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
										from #regularinvoices1
										group by storeid 
									
										update c set c.RetailerInvoiceID = o.RetailerInvoiceID
										from #regularinvoices1 c
										inner join #outputtable1 o
										on c.StoreID = o.Storeid
										and c.PONo = o.PoNo
										
										update d set d.RetailerInvoiceID = c.RetailerInvoiceID, d.RecordStatus = 1
										from datatrue_main.dbo.InvoiceDetails d
										inner join #regularinvoices1 c
										on d.StoreID = c.StoreID
										and d.ProductID = c.ProductID
										and d.SupplierID = c.supplierid
										and isnull(d.PONo, '') = isnull(c.PONo, '')
										and isnull(d.InvoiceNo, '') = isnull(d.InvoiceNo, '')
										and d.invoicedetailid in
										(select InvoiceDetailID from #InvoicedetailIDsToBill)
										and d.RetailerInvoiceID is null	
										and d.ProcessID = @processid									
											end
									
									End
									
									If @invoiceseparation = 2 
										Begin 
											select CAST(0 as int) as RetailerInvoiceID
											,CAST(0 as int) as Storeid
											,CAST('' as varchar(50)) as PoNo
											into #outputtable2						
										
											if @separatecredits = 1
											begin
											
												Select storeid, productid, SupplierID
												,SUM(TotalCost) as TotalInvAmount
												,CAST(0 as int) as RetailerInvoiceID
												into #creditinvoices2
												from datatrue_main.dbo.InvoiceDetails d
												inner join #InvoicedetailIDsToBill i
												on d.InvoiceDetailID = i.InvoiceDetailID
												and d.ProcessID = @ProcessID
												group by storeid, productid, SupplierID 
												having SUM(TotalCost) < 0
												
												--select * from #creditinvoices
												
											if @@ROWCOUNT > 0
												begin
													print 'herenow'

																			
												truncate table #outputtable2
											
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
														   ,[Storeid])
												OUTPUT INSERTED.RetailerInvoiceID, inserted.Storeid INTO #outputtable2		   
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
												from #creditinvoices2
												group by storeid
											
												update c set c.RetailerInvoiceID = o.RetailerInvoiceID
												from #creditinvoices2 c
												inner join #outputtable2 o
												on c.StoreID = o.Storeid
												and c.pono = o.PoNo
												
												update d set d.RetailerInvoiceID = c.RetailerInvoiceID, d.RecordStatus = 1
												from datatrue_main.dbo.InvoiceDetails d
												inner join #creditinvoices2 c
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
					
					
									
										Select storeid, productid, SupplierID 
										,SUM(TotalCost) as TotalInvAmount
										,CAST(0 as int) as RetailerInvoiceID
										into #regularinvoices2
										from datatrue_main.dbo.InvoiceDetails d
										inner join #InvoicedetailIDsToBill i
										on d.InvoiceDetailID = i.InvoiceDetailID
										and d.RetailerInvoiceID is null
										group by storeid, productid, SupplierID
										
										truncate table #outputtable2
									
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
														   ,[Storeid])
												OUTPUT INSERTED.RetailerInvoiceID, inserted.Storeid INTO #outputtable2		   
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
										from #regularinvoices2
										group by storeid 
									
										update c set c.RetailerInvoiceID = o.RetailerInvoiceID
										from #regularinvoices2 c
										inner join #outputtable2 o
										on c.StoreID = o.Storeid
										and c.PONo = o.PoNo
										
										update d set d.RetailerInvoiceID = c.RetailerInvoiceID, d.RecordStatus = 1
										from datatrue_main.dbo.InvoiceDetails d
										inner join #regularinvoices2 c
										on d.StoreID = c.StoreID
										and d.ProductID = c.ProductID
										and d.SupplierID = c.supplierid
										and isnull(d.PONo, '') = isnull(c.PONo, '')
										and isnull(d.InvoiceNo, '') = isnull(d.InvoiceNo, '')
										and d.invoicedetailid in
										(select InvoiceDetailID from #InvoicedetailIDsToBill)
										and d.RetailerInvoiceID is null	
										and d.ProcessID = @processid									
											end
										
										End */
										
										If @invoiceseparation = 3
											Begin
											
											select CAST(0 as int) as RetailerInvoiceID
											,CAST(0 as int) as Storeid
											,CAST(0 as int) as Supplierid
											into #outputtable3						
										
											if @separatecredits = 1
											begin
											
												Select storeid, productid, SupplierID,  SUM(TotalCost) as TotalInvAmount
												,CAST(0 as int) as RetailerInvoiceID
												into #creditinvoices3
												from datatrue_main.dbo.InvoiceDetails d
												inner join #InvoicedetailIDsToBill i
												on d.InvoiceDetailID = i.InvoiceDetailID
												and d.RetailerInvoiceID is null
												group by storeid, productid, SupplierID
												
												--select * from #creditinvoices
												
											if @@ROWCOUNT > 0
												begin
													print 'herenow'

																			
												truncate table #outputtable3
											
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
														   ,Supplier_Id )
												OUTPUT INSERTED.RetailerInvoiceID, inserted.Storeid, inserted.Supplier_Id INTO #outputtable3		   
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
												,SupplierID
												from #creditinvoices3
												group by storeid, SupplierID
											
												update c set c.RetailerInvoiceID = o.RetailerInvoiceID
												from #creditinvoices3 c
												inner join #outputtable3 o
												on c.StoreID = o.Storeid
												and c.SupplierID = o.Supplierid
												
												update d set d.RetailerInvoiceID = c.RetailerInvoiceID, d.RecordStatus = 1
												from datatrue_main.dbo.InvoiceDetails d
												inner join #creditinvoices3 c
												on d.StoreID = c.StoreID
												and d.ProductID = c.ProductID
												and d.SupplierID = c.supplierid
												and d.invoicedetailid in
												(select InvoiceDetailID from #InvoicedetailIDsToBill)
												and d.ProcessID = @processid

											
											end
										end		
					
					
									
										Select storeid, productid, SupplierID, SUM(TotalCost) as TotalInvAmount
										,CAST(0 as int) as RetailerInvoiceID
										into #regularinvoices3
										from datatrue_main.dbo.InvoiceDetails d
										inner join #InvoicedetailIDsToBill i
										on d.InvoiceDetailID = i.InvoiceDetailID
										and d.RetailerInvoiceID is null
										group by storeid, productid, SupplierID
										
										truncate table #outputtable3
									
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
														   ,Supplier_Id )
												OUTPUT INSERTED.RetailerInvoiceID, inserted.Storeid, inserted.Supplier_Id INTO #outputtable3		   
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
												,SupplierID
										from #regularinvoices3
										group by storeid, SupplierID
									
										update c set c.RetailerInvoiceID = o.RetailerInvoiceID
										from #regularinvoices3 c
										inner join #outputtable3 o
										on c.StoreID = o.Storeid
										and c.SupplierID = o.Supplierid
										
										update d set d.RetailerInvoiceID = c.RetailerInvoiceID, d.RecordStatus = 1
										from datatrue_main.dbo.InvoiceDetails d
										inner join #regularinvoices3 c
										on d.StoreID = c.StoreID
										and d.ProductID = c.ProductID
										and d.SupplierID = c.supplierid
										and d.invoicedetailid in
										(select InvoiceDetailID from #InvoicedetailIDsToBill)
										and d.RetailerInvoiceID is null	
										and d.ProcessID = @processid									
											end
											
											End
											
										
											
											If @invoiceseparation = 4
											
											Begin
										
											select CAST(0 as int) as RetailerInvoiceID
											,CAST(0 as int) as Storeid
											,CAST('' as varchar(50)) as PoNo
											,CAST(0 as int) as SupplierId
											into #outputtable4						
										
											if @separatecredits = 1
											begin
											
												Select storeid, productid, SupplierID, isnull(PONo, '') as PONo
												, SUM(TotalCost) as TotalInvAmount
												,CAST(0 as int) as RetailerInvoiceID
												into #creditinvoices4
												from datatrue_main.dbo.InvoiceDetails d
												inner join #InvoicedetailIDsToBill i
												on d.InvoiceDetailID = i.InvoiceDetailID
												and d.ProcessID = @ProcessID
												group by storeid, productid, SupplierID, isnull(PONo, '')
												having SUM(TotalCost) < 0
												
												--select * from #creditinvoices
												
											if @@ROWCOUNT > 0
												begin
													print 'herenow'

																			
												truncate table #outputtable4
											
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
														   ,Supplier_Id )
												OUTPUT INSERTED.RetailerInvoiceID, inserted.Storeid, inserted.Supplier_Id INTO #outputtable4		   
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
												,SupplierID
												from #creditinvoices4
												group by storeid, PONo, SupplierID
											
												update c set c.RetailerInvoiceID = o.RetailerInvoiceID
												from #creditinvoices4 c
												inner join #outputtable4 o
												on c.StoreID = o.Storeid
												and c.pono = o.PoNo
												and c.SupplierID = o.SupplierId
												
												update d set d.RetailerInvoiceID = c.RetailerInvoiceID, d.RecordStatus = 1
												from datatrue_main.dbo.InvoiceDetails d
												inner join #creditinvoices4 c
												on d.StoreID = c.StoreID
												and d.ProductID = c.ProductID
												and d.SupplierID = c.supplierid
												and isnull(d.PONo, '') = isnull(c.PONo, '')
												and d.invoicedetailid in
												(select InvoiceDetailID from #InvoicedetailIDsToBill)
												and d.ProcessID = @processid

											
											end
										end		
					
					
									
										Select storeid, productid, SupplierID, isnull(PONo, '') as PONo
										, SUM(TotalCost) as TotalInvAmount
										,CAST(0 as int) as RetailerInvoiceID
										into #regularinvoices4
										from datatrue_main.dbo.InvoiceDetails d
										inner join #InvoicedetailIDsToBill i
										on d.InvoiceDetailID = i.InvoiceDetailID
										and d.RetailerInvoiceID is null
										group by storeid, productid, SupplierID, isnull(PONo, '')
										
										truncate table #outputtable4
									
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
														   ,Supplier_id )
												OUTPUT INSERTED.RetailerInvoiceID, inserted.Storeid, inserted.Supplier_Id INTO #outputtable4		   
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
												,SupplierID
										from #regularinvoices4
										group by storeid, PONo, SupplierID
									
										update c set c.RetailerInvoiceID = o.RetailerInvoiceID
										from #regularinvoices4 c
										inner join #outputtable4 o
										on c.StoreID = o.Storeid
										and c.PONo = o.PoNo
										and c.SupplierID = o.SupplierId
										
										update d set d.RetailerInvoiceID = c.RetailerInvoiceID, d.RecordStatus = 1
										from datatrue_main.dbo.InvoiceDetails d
										inner join #regularinvoices4 c
										on d.StoreID = c.StoreID
										and d.ProductID = c.ProductID
										and d.SupplierID = c.supplierid
										and isnull(d.PONo, '') = isnull(c.PONo, '')
										and d.invoicedetailid in
										(select InvoiceDetailID from #InvoicedetailIDsToBill)
										and d.RetailerInvoiceID is null	
										and d.ProcessID = @processid									
				end
				--end	
				
									If @invoiceseparation = 5
											
											Begin
										
											select CAST(0 as int) as RetailerInvoiceID
											,CAST(0 as int) as Storeid
											,CAST('' as varchar(50)) as PoNo
											,CAST(0 as int) as Supplierid
											,CAST('00/00/00' as date) as Saledate
											into #outputtable5						
										
											if @separatecredits = 1
											begin
											
												Select storeid, productid, SupplierID, isnull(PONo, '') as PONo
												,SUM(TotalCost) as TotalInvAmount
												,CAST(0 as int) as RetailerInvoiceID, SaleDate
												into #creditinvoices5
												from datatrue_main.dbo.InvoiceDetails d
												inner join #InvoicedetailIDsToBill i
												on d.InvoiceDetailID = i.InvoiceDetailID
												and d.ProcessID = @ProcessID
												group by storeid, productid, SupplierID, isnull(PONo, ''), SaleDate
												having SUM(TotalCost) < 0
												
												--select * from #creditinvoices
												
											if @@ROWCOUNT > 0
												begin
													print 'herenow'

																			
												truncate table #outputtable5
											
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
														   ,Supplier_Id )
												OUTPUT INSERTED.RetailerInvoiceID, inserted.Storeid, inserted.Supplier_Id, inserted.InvoicePeriodEnd INTO #outputtable5		   
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
												,SupplierID
												from #creditinvoices5
												group by storeid, PONo, SupplierID
											
												update c set c.RetailerInvoiceID = o.RetailerInvoiceID
												from #creditinvoices5 c
												inner join #outputtable5 o
												on c.StoreID = o.Storeid
												and c.pono = o.PoNo
												and c.SupplierID = o.Supplierid
												and c.SaleDate = o.Saledate
												
												update d set d.RetailerInvoiceID = c.RetailerInvoiceID, d.RecordStatus = 1
												from datatrue_main.dbo.InvoiceDetails d
												inner join #creditinvoices5 c
												on d.StoreID = c.StoreID
												and d.ProductID = c.ProductID
												and d.SupplierID = c.supplierid
												and isnull(d.PONo, '') = isnull(c.PONo, '')
												and d.SaleDate = c.SaleDate
												and d.invoicedetailid in
												(select InvoiceDetailID from #InvoicedetailIDsToBill)
												and d.ProcessID = @processid

											
											end
										end		
					
					
									
										Select storeid, productid, SupplierID, isnull(PONo, '') as PONo
										,SUM(TotalCost) as TotalInvAmount
										,CAST(0 as int) as RetailerInvoiceID, SaleDate
										into #regularinvoices5
										from datatrue_main.dbo.InvoiceDetails d
										inner join #InvoicedetailIDsToBill i
										on d.InvoiceDetailID = i.InvoiceDetailID
										and d.RetailerInvoiceID is null
										group by storeid, productid, SupplierID, isnull(PONo, ''), SaleDate
										
										truncate table #outputtable5
									
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
														   ,Supplier_Id )
												OUTPUT INSERTED.RetailerInvoiceID, inserted.Storeid, inserted.Supplier_id, inserted.InvoicePeriodEnd INTO #outputtable5		   
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
												,SupplierID
										from #regularinvoices5
										group by storeid, PONo, SupplierID
									
										update c set c.RetailerInvoiceID = o.RetailerInvoiceID
										from #regularinvoices5 c
										inner join #outputtable5 o
										on c.StoreID = o.Storeid
										and c.PONo = o.PoNo
										and c.SupplierID = o.Supplierid
										and c.SaleDate = o.Saledate
										
										update d set d.RetailerInvoiceID = c.RetailerInvoiceID, d.RecordStatus = 1
										from datatrue_main.dbo.InvoiceDetails d
										inner join #regularinvoices5 c
										on d.StoreID = c.StoreID
										and d.ProductID = c.ProductID
										and d.SupplierID = c.supplierid
										and isnull(d.PONo, '') = isnull(c.PONo, '')
										and d.SaleDate = c.SaleDate
										and d.invoicedetailid in
										(select InvoiceDetailID from #InvoicedetailIDsToBill)
										and d.RetailerInvoiceID is null	
										and d.ProcessID = @processid									
				end
				end												
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
										
											update BillingControl
											set LastBillingPeriodEndDateTime = NextBillingPeriodEndDateTime
											,NextBillingPeriodEndDateTime = @newnextbillingperiodenddatetime
											,NextBillingPeriodRunDateTime = Convert(datetime, STUFF(CONVERT(VARCHAR(50),NextBillingPeriodRunDateTime,126) ,1, 10, dateadd(day, @billingcontrolclosingdelay, Convert(date, @newnextbillingperiodenddatetime))))
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
												
									
								IF OBJECT_ID('tempdb..#outputtable3') IS NOT NULL drop table #outputtable3
								IF OBJECT_ID('tempdb..#outputtable4') IS NOT NULL drop table #outputtable4
								IF OBJECT_ID('tempdb..#outputtable5') IS NOT NULL drop table #outputtable5
										
									
								IF OBJECT_ID('tempdb..#InvoicedetailIDsToBill3') Is not null drop table #InvoicedetailIDsToBill3
								IF OBJECT_ID('tempdb..#InvoicedetailIDsToBill4') Is not null drop table #InvoicedetailIDsToBill4
								IF OBJECT_ID('tempdb..#InvoicedetailIDsToBill5') Is not null drop table #InvoicedetailIDsToBill5
									
								IF OBJECT_ID('tempdb..#creditinvoices3') Is not null drop table #creditinvoices3
								IF OBJECT_ID('tempdb..#creditinvoices4') Is not null drop table #creditinvoices4
								IF OBJECT_ID('tempdb..#creditinvoices5') Is not null drop table #creditinvoices5		
										
								IF OBJECT_ID('tempdb..#regularinvoices3') Is not null drop table #regularinvoices3
								IF OBJECT_ID('tempdb..#regularinvoices4') Is not null drop table #regularinvoices4
								IF OBJECT_ID('tempdb..#regularinvoices5') Is not null drop table #regularinvoices5
																						
									
									--commit transaction
							
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
		,@billingcontrolfrequency
	end
	
close @rec
deallocate @rec

END
GO
