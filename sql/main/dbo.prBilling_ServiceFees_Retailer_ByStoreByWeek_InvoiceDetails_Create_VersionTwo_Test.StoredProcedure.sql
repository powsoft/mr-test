USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_ServiceFees_Retailer_ByStoreByWeek_InvoiceDetails_Create_VersionTwo_Test]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prBilling_ServiceFees_Retailer_ByStoreByWeek_InvoiceDetails_Create_VersionTwo_Test]

as
 
declare @paymentduedate date=getdate()
declare @currentdate date
declare @lastmonthdate date
declare @lastmonthyear int
declare @lastmonthmonth tinyint
declare @batchid int
declare @retailerinvoiceid int
declare @myid int = 44278
declare @recchains cursor
declare @recsuppliers cursor
declare @chainid int
declare @supplierid int
declare @invoicecount int
declare @storeid int
declare @recordcount int
DECLARE @ProcessID INT

SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobRunningID = 14

set @currentdate = GETDATE()
set @lastmonthdate = DATEADD(month, -1, @currentdate)
set @lastmonthyear = YEAR(@lastmonthdate)
set @lastmonthmonth = MONTH(@lastmonthdate)

If OBJECT_ID('[datatrue_main].[dbo].[TempSaledate_Control]') Is Not Null Drop Table [datatrue_main].[dbo].[TempSaledate_Control]

	Select Distinct NextBillingPeriodEndDateTime Saledate, 
		DATEADD(d, -6,NextBillingPeriodEndDateTime) mSaledate, 
		C.ChainID 
		Into TempSaledate_Control
	From BillingControl B
		inner join systementities s
		on B.EntityIDToInvoice = s.EntityID
		Inner join Chains C
		on B.ChainID = C.ChainID
		Inner Join DataTrue_EDI..ProcessStatus P
		On P.ChainName = C.ChainIdentifier
	where BusinessTypeID = 1
		and IsActive = 1
		and s.EntityTypeID = 2
		and EntityIDToInvoice in (Select EntityIdToInclude 
									from ProcessStepEntities 
									where ProcessStepName in ('prBilling_ServiceFees_Retailer_ByStoreByWeek_InvoiceDetails_Create_VersionOne'))
		And BillingControlFrequency = 'weekly' 
		And Convert(date,NextBillingPeriodRunDateTime) = cast(GETDATE() as date)
		And P.Date = CONVERT(date, getdate())
		and P.AllFilesReceived = 1
		and P.BillingComplete = 0
		and P.BillingIsRunning = 1
		and P.RecordTypeID = 2


--Select * from TempSaledate_Control



INSERT INTO [DataTrue_Main].[dbo].[Batch]
		   ([ProcessEntityID]
		   ,[DateTimeCreated])
	 VALUES
		   (@myid --<ProcessEntityID, int,>
		   ,GETDATE()) --<DateTimeCreated, datetime,>)

set @batchid = SCOPE_IDENTITY()

print @batchid

				select distinct S.ChainID, S.Storeid, S.SupplierID, ServiceFeeFactorValue as FeePerStorePerSupplier, 
				ActiveStartDate, ActiveLastDate, T.Saledate
				into #tempfees
				from ServiceFees S Inner join TempSaledate_Control T
				on S.ChainID = T.Chainid 
				Inner Join StoreTransactions ST with(nolock)
				On S.ChainID = ST.ChainID
				and S.StoreID = ST.StoreID
				and S.SupplierID = ST.SupplierID
				where ServiceFeeTypeID = 1
				and T.Saledate between ActiveStartDate and ActiveLastDate
				and ST.SaleDateTime between T.mSaledate and T.Saledate
				

						INSERT INTO [DataTrue_Main].[dbo].[InvoiceDetails]
								   ([RetailerInvoiceID]
								   ,[SupplierInvoiceID]
								   ,[ChainID]
								   ,[StoreID]
								   ,[ProductID]
								   ,[BrandID]
								   ,[SupplierID]
								   ,[InvoiceDetailTypeID]
								   ,[TotalQty]
								   ,[UnitCost]
								   ,[UnitRetail]
								   ,[TotalCost]
								   ,[TotalRetail]
								   ,[SaleDate]
								   ,[RecordStatus]
								   ,[DateTimeCreated]
								   ,[LastUpdateUserID]
								   ,[DateTimeLastUpdate]
								   ,[BatchID]
								   ,[ChainIdentifier]
								   ,[StoreIdentifier]
								   ,[StoreName]
								   ,[ProductIdentifier]
								   ,[ProductQualifier]
								   ,[RawProductIdentifier]
								   ,[SupplierName]
								   ,[SupplierIdentifier]
								   ,[BrandIdentifier]
								   ,[DivisionIdentifier]
								   ,[UOM]
								   ,[SalePrice]
								   ,[Allowance]
								   ,[InvoiceNo]
								   ,[PONo]
								   ,[CorporateName]
								   ,[CorporateIdentifier]
								   ,[Banner]
								   ,[PromoTypeID]
								   ,[PromoAllowance]
								   ,[InventorySettlementID]
								   ,[SBTNumber]
								   ,[FinalInvoiceUnitCost]
								   ,[FinalInvoiceUnitPromo]
								   ,[FinalInvoiceTotalCost]
								   ,[FinalInvoiceQty]
								   ,[OriginalShrinkTotalQty]
								   ,[PaymentDueDate]
								   ,[PaymentID]
								   ,[PDIParticipant]
								   ,ProcessID
								   ,RecordType)
						select 
									null
								   ,null --[SupplierInvoiceID]
								   ,f.chainid --[ChainID] 
								   ,storeid --0 --[StoreID]
								   ,3487669 --0 --[ProductID]
								   ,0 --[BrandID]
								   ,supplierid --[SupplierID]
								   ,16 --[InvoiceDetailTypeID]
								   ,1 --InvoiceCountLastMonth --1 --[TotalQty]
								   ,FeePerStorePerSupplier --FeePerInvoice --[UnitCost]
								   ,0 --[UnitRetail]
								   ,FeePerStorePerSupplier --FeeTotalLastMonth --[TotalCost]
								   ,0 --[TotalRetail]
								   ,Saledate --[SaleDate]
								   ,0 --[RecordStatus]
								   ,getdate() --[DateTimeCreated]
								   ,0 --[LastUpdateUserID]
								   ,getdate() --[DateTimeLastUpdate]
								   ,@batchid --[BatchID]
								   ,null --[ChainIdentifier]
								   ,null --[StoreIdentifier]
								   ,null --[StoreName]
								   ,'999999999996' --null --[ProductIdentifier]
								   ,null --[ProductQualifier]
								   ,'999999999996' --[RawProductIdentifier]
								   ,null --[SupplierName]
								   ,null --[SupplierIdentifier]
								   ,null --[BrandIdentifier]
								   ,null --[DivisionIdentifier]
								   ,null --[UOM]
								   ,null --[SalePrice]
								   ,0 --[Allowance]
								   ,'' --null --[InvoiceNo]
								   ,'' --null --[PONo]
								   ,null --[CorporateName]
								   ,null --[CorporateIdentifier]
								   ,null --[Banner]
								   ,null --[PromoTypeID]
								   ,0 --[PromoAllowance]
								   ,null --[InventorySettlementID]
								   ,null --[SBTNumber]
								   ,null --[FinalInvoiceUnitCost]
								   ,null --[FinalInvoiceUnitPromo]
								   ,null --[FinalInvoiceTotalCost]
								   ,null --[FinalInvoiceQty]
								   ,null --[OriginalShrinkTotalQty]
								   ,getdate() --@paymentduedate --'8/9/2013' --[PaymentDueDate]
								   ,null --[PaymentID]
								   ,CASE WHEN ISNULL(ch.PDITradingPartner, 0) = 1 THEN 1 ELSE 0 END --[PDIParticant]
								   ,@ProcessID
								   ,2
						from #tempfees f inner join Chains ch on f.chainid = ch.ChainID
						

				drop table #tempfees
				
				
Set DateFirst 1

If OBJECT_ID('[InvoicedServiceFees]') Is Not Null Drop Table [InvoicedServiceFees]
If OBJECT_ID('[InvoicedPOSRecords]') Is Not Null Drop Table [InvoicedPOSRecords] --MissingDeliveryFees
If OBJECT_ID('[MissingDeliveryFees]') Is Not Null Drop Table [MissingDeliveryFees]


Select Distinct I.Chainid, I.StoreID, I.SupplierID, DATEPART(WEEK, SaleDate) WeekOfYear into InvoicedServiceFees
from InvoiceDetails I with(nolock)
Inner Join Chains C on C.ChainID = I.ChainID
inner join DataTrue_EDI..ProcessStatus P
on P.ChainName = C.ChainIdentifier
where 1=1
and I.InvoiceDetailTypeID = 16
and I.ChainID in (Select EntityIdToInclude 
									from ProcessStepEntities 
									where ProcessStepName in ('prBilling_ServiceFees_Retailer_ByStoreByWeek_InvoiceDetails_Create_VersionOne'))
And P.Date = CONVERT(date, getdate())
and P.AllFilesReceived = 1
and P.BillingComplete = 0
and P.BillingIsRunning = 1

Select Distinct I.Chainid, I.StoreID, I.SupplierID, DATEPART(WEEK, SaleDate) WeekOfYear, max(saledate) Saledate, CAST(Null as int) ServiceFeePresent, S.ServiceFeeFactorValue into InvoicedPOSRecords
from InvoiceDetails I with(nolock)
Inner join ServiceFees S 
on I.StoreID = S.StoreID 
and I.SupplierID = S.SupplierID
and I.ChainID = S.ChainID
Inner Join Chains C 
on C.ChainID = I.ChainID
Inner Join DataTrue_EDI..ProcessStatus P
on P.ChainName = C.ChainIdentifier
where S.ServiceFeeTypeID = 1
and I.InvoiceDetailTypeID = 1
and I.SaleDate between S.ActiveStartDate and S.ActiveLastDate
and I.ChainID in (Select EntityIdToInclude 
									from ProcessStepEntities 
									where ProcessStepName in ('prBilling_ServiceFees_Retailer_ByStoreByWeek_InvoiceDetails_Create_VersionOne'))
And P.Date = CONVERT(date, getdate())
and P.AllFilesReceived = 1
and P.BillingComplete = 0
and P.BillingIsRunning = 1
Group by I.Chainid, I.StoreID, I.SupplierID, I.SaleDate, S.ServiceFeeFactorValue


UPdate R Set ServiceFeePresent = 1
from InvoicedPOSRecords R
Inner join InvoicedServiceFees S
On S.StoreID = R.StoreID
and S.SupplierID = R.SupplierID
and S.WeekOfYear = R.WeekOfYear
and S.ChainID = R.ChainID

UPdate R Set ServiceFeePresent = 1
from InvoicedPOSRecords R
Where WeekOfYear = 53

Select distinct R.ChainID, R.StoreID, R.SupplierID, 
CONVERT(varchar(50), (DATEADD(dd, @@DATEFIRST - DATEPART(dw, MAX(saledate)) + 6, MAX(saledate))), 101) Sale_date, ServiceFeeFactorValue as FeePerStorePerSupplier Into MissingDeliveryFees
from InvoicedPOSRecords R 
Inner Join BillingControl B
on R.ChainID = B.ChainID
and R.SupplierID = B.EntityIDToInvoice
where ServiceFeePresent is null
and convert(date, B.NextBillingPeriodRunDateTime) = CONVERT(date, getdate())
Group by R.ChainID, R.SupplierID, WeekOfYear, StoreID, ServiceFeeFactorValue
Order by Sale_date

Select *
from MissingDeliveryFees

If @@ROWCOUNT > 1

Begin


INSERT INTO [DataTrue_Main].[dbo].[InvoiceDetails]
		   ([RetailerInvoiceID]
		   ,[SupplierInvoiceID]
		   ,[ChainID]
		   ,[StoreID]
		   ,[ProductID]
		   ,[BrandID]
		   ,[SupplierID]
		   ,[InvoiceDetailTypeID]
		   ,[TotalQty]
		   ,[UnitCost]
		   ,[UnitRetail]
		   ,[TotalCost]
		   ,[TotalRetail]
		   ,[SaleDate]
		   ,[RecordStatus]
		   ,[DateTimeCreated]
		   ,[LastUpdateUserID]
		   ,[DateTimeLastUpdate]
		   ,[BatchID]
		   ,[ChainIdentifier]
		   ,[StoreIdentifier]
		   ,[StoreName]
		   ,[ProductIdentifier]
		   ,[ProductQualifier]
		   ,[RawProductIdentifier]
		   ,[SupplierName]
		   ,[SupplierIdentifier]
		   ,[BrandIdentifier]
		   ,[DivisionIdentifier]
		   ,[UOM]
		   ,[SalePrice]
		   ,[Allowance]
		   ,[InvoiceNo]
		   ,[PONo]
		   ,[CorporateName]
		   ,[CorporateIdentifier]
		   ,[Banner]
		   ,[PromoTypeID]
		   ,[PromoAllowance]
		   ,[InventorySettlementID]
		   ,[SBTNumber]
		   ,[FinalInvoiceUnitCost]
		   ,[FinalInvoiceUnitPromo]
		   ,[FinalInvoiceTotalCost]
		   ,[FinalInvoiceQty]
		   ,[OriginalShrinkTotalQty]
		   ,[PaymentDueDate]
		   ,[PaymentID]
		   ,[PDIParticipant]
		   ,ProcessID
		   ,RecordType)

select 
 null
,null --[SupplierInvoiceID]
,ch.ChainID --[ChainID] 
,storeid --0 --[StoreID]
,3487669 --0 --[ProductID]
,0 --[BrandID]
,supplierid --[SupplierID]
,16 --[InvoiceDetailTypeID]
,1 --InvoiceCountLastMonth --1 --[TotalQty]
,FeePerStorePerSupplier --FeePerInvoice --[UnitCost]
,0 --[UnitRetail]
,FeePerStorePerSupplier --FeeTotalLastMonth --[TotalCost]
,0 --[TotalRetail]
,Sale_date --[SaleDate]
,0 --[RecordStatus]
,getdate() --[DateTimeCreated]
,0 --[LastUpdateUserID]
,getdate() --[DateTimeLastUpdate]
,@batchid --[BatchID]
,null --[ChainIdentifier]
,null --[StoreIdentifier]
,null --[StoreName]
,'999999999996' --null --[ProductIdentifier]
,null --[ProductQualifier]
,'999999999996' --[RawProductIdentifier]
,null --[SupplierName]
,null --[SupplierIdentifier]
,null --[BrandIdentifier]
,null --[DivisionIdentifier]
,null --[UOM]
,null --[SalePrice]
,0 --[Allowance]
,'' --null --[InvoiceNo]
,'' --null --[PONo]
,null --[CorporateName]
,null --[CorporateIdentifier]
,null --[Banner]
,null --[PromoTypeID]
,0 --[PromoAllowance]
,null --[InventorySettlementID]
,null --[SBTNumber]
,null --[FinalInvoiceUnitCost]
,null --[FinalInvoiceUnitPromo]
,null --[FinalInvoiceTotalCost]
,null --[FinalInvoiceQty]
,null --[OriginalShrinkTotalQty]
,getdate() --@paymentduedate --'8/9/2013' --[PaymentDueDate]
,null --[PaymentID]
,CASE WHEN ISNULL(ch.PDITradingPartner, 0) = 1 THEN 1 ELSE 0 END --[PDIParticant]
,@ProcessID
,2
From MissingDeliveryFees F
inner join Chains CH
on CH.ChainID = F.ChainID

End

return
GO
